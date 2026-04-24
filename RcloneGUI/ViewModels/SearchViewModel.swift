import Foundation
import RcloneKit

struct SearchResult: Identifiable {
    var id: String { "\(remoteFs)/\(path)" }
    let name: String
    let path: String
    let size: Int64
    let modTime: Date
    let isDir: Bool
    let mimeType: String?
    let remoteFs: String
}

enum SearchSortField: String, CaseIterable {
    case name
    case size
    case date
    case remote
}

@Observable
final class SearchViewModel {
    var query: String = ""
    var isSearching: Bool = false
    var hasSearched: Bool = false
    var results: [SearchResult] = []
    var error: String?
    var selectedClouds: Set<String> = []
    var sortField: SearchSortField = .name
    var sortAsc: Bool = true

    let history: SearchHistoryStore

    private let client: RcloneClientProtocol
    private var searchTask: Task<Void, Never>?
    private let maxConcurrency = AppConstants.maxSearchConcurrency

    init(client: RcloneClientProtocol, history: SearchHistoryStore = SearchHistoryStore()) {
        self.client = client
        self.history = history
    }

    func setSort(_ field: SearchSortField) {
        if sortField == field {
            sortAsc.toggle()
        } else {
            sortField = field
            sortAsc = true
        }
    }

    func sortedResults(_ input: [SearchResult]) -> [SearchResult] {
        input.sorted { a, b in
            let cmp: Bool
            switch sortField {
            case .name:
                cmp = a.name.localizedStandardCompare(b.name) == .orderedAscending
            case .size:
                cmp = a.size < b.size
            case .date:
                cmp = a.modTime < b.modTime
            case .remote:
                cmp = a.remoteFs < b.remoteFs
            }
            return sortAsc ? cmp : !cmp
        }
    }

    func initializeClouds(remotes: [String]) {
        selectedClouds = Set(remotes.map { "\($0):" })
    }

    func toggleCloud(_ cloud: String) {
        if selectedClouds.contains(cloud) {
            selectedClouds.remove(cloud)
        } else {
            selectedClouds.insert(cloud)
        }
    }

    @MainActor
    func performSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        history.record(trimmed)

        abortSearch()
        isSearching = true
        hasSearched = true
        results = []
        error = nil

        searchTask = Task {
            for cloud in selectedClouds {
                if Task.isCancelled { break }
                await searchRemoteBFS(cloud: cloud, query: trimmed)
            }
            await MainActor.run { self.isSearching = false }
        }
    }

    /// BFS search: traverse directories level by level with concurrency control
    private func searchRemoteBFS(cloud: String, query: String) async {
        var queue: [String] = [""]  // start from root

        while !queue.isEmpty && !Task.isCancelled {
            // Take up to maxConcurrency directories from queue
            let batch = Array(queue.prefix(maxConcurrency))
            queue.removeFirst(min(maxConcurrency, queue.count))

            var batchSubdirs: [String] = []

            // Process batch concurrently
            await withTaskGroup(of: (matches: [SearchResult], subdirs: [String]).self) { group in
                for dir in batch {
                    group.addTask { [weak self] in
                        guard let self = self else { return ([], []) }
                        do {
                            let response = try await self.client.call("operations/list", params: [
                                "fs": cloud,
                                "remote": dir,
                                "opt": ["recurse": false]
                            ])

                            guard let list = response["list"] as? [[String: Any]] else {
                                return ([], [])
                            }

                            let data = try JSONSerialization.data(withJSONObject: list)
                            let items = try JSONDecoder.rclone.decode([FileItem].self, from: data)

                            var matches: [SearchResult] = []
                            var subdirs: [String] = []

                            for item in items {
                                if item.isDir {
                                    subdirs.append(item.path)
                                }
                                if item.name.localizedCaseInsensitiveContains(query) {
                                    matches.append(SearchResult(
                                        name: item.name, path: item.path, size: item.size,
                                        modTime: item.modTime, isDir: item.isDir,
                                        mimeType: item.mimeType, remoteFs: cloud
                                    ))
                                }
                            }

                            return (matches, subdirs)
                        } catch {
                            print("[RcloneGUI] Search list error for \(cloud)\(dir): \(error.localizedDescription)")
                            return ([], [])
                        }
                    }
                }

                for await result in group {
                    if !result.matches.isEmpty {
                        await MainActor.run {
                            self.results.append(contentsOf: result.matches)
                        }
                    }
                    batchSubdirs.append(contentsOf: result.subdirs)
                }
            }

            queue.append(contentsOf: batchSubdirs)
        }
    }

    func abortSearch() {
        searchTask?.cancel()
        searchTask = nil
        isSearching = false
    }
}
