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

@Observable
final class SearchViewModel {
    var query: String = ""
    var isSearching: Bool = false
    var hasSearched: Bool = false
    var results: [SearchResult] = []
    var error: String?
    var selectedClouds: Set<String> = []

    private let client: RcloneClientProtocol
    private var searchTask: Task<Void, Never>?

    init(client: RcloneClientProtocol) {
        self.client = client
    }

    func initializeClouds(remotes: [String]) {
        selectedClouds = Set(remotes.map { "\($0):" })
        selectedClouds.insert("/")
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

        abortSearch()
        isSearching = true
        hasSearched = true
        results = []
        error = nil

        searchTask = Task {
            var allResults: [SearchResult] = []

            for cloud in selectedClouds {
                if Task.isCancelled { break }

                do {
                    let response = try await client.call("operations/list", params: [
                        "fs": cloud,
                        "remote": "",
                        "opt": ["recurse": true, "filesOnly": false]
                    ])

                    if let list = response["list"] as? [[String: Any]] {
                        let data = try JSONSerialization.data(withJSONObject: list)
                        let items = try JSONDecoder.rclone.decode([FileItem].self, from: data)

                        let matched = items.filter {
                            $0.name.localizedCaseInsensitiveContains(trimmed)
                        }.map {
                            SearchResult(
                                name: $0.name, path: $0.path, size: $0.size,
                                modTime: $0.modTime, isDir: $0.isDir,
                                mimeType: $0.mimeType, remoteFs: cloud
                            )
                        }

                        allResults.append(contentsOf: matched)
                        await MainActor.run { self.results = allResults }
                    }
                } catch {
                    // Skip failed remotes
                }
            }

            await MainActor.run { self.isSearching = false }
        }
    }

    func abortSearch() {
        searchTask?.cancel()
        searchTask = nil
        isSearching = false
    }
}
