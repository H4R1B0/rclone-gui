import Foundation
import RcloneKit

struct DuplicateGroup: Identifiable {
    let id = UUID()
    let hash: String
    let size: Int64
    var files: [(remote: String, path: String, name: String)]

    var count: Int { files.count }
    var wastedSpace: Int64 { size * Int64(count - 1) }
}

@Observable
final class DuplicateDetector {
    var groups: [DuplicateGroup] = []
    var isScanning: Bool = false
    var progress: String = ""
    var totalWasted: Int64 { groups.reduce(0) { $0 + $1.wastedSpace } }

    private let client: RcloneClientProtocol

    init(client: RcloneClientProtocol) {
        self.client = client
    }

    @MainActor
    func scan(remotes: [String]) async {
        isScanning = true
        groups = []

        // Collect all files with their sizes
        var filesBySize: [Int64: [(remote: String, path: String, name: String)]] = [:]

        for remote in remotes {
            let fs = remote.hasSuffix(":") ? remote : "\(remote):"
            progress = "\(L10n.t("duplicate.scanning")) \(remote)..."

            do {
                let response = try await client.call("operations/list", params: [
                    "fs": fs, "remote": "", "opt": ["recurse": true, "filesOnly": true]
                ])

                if let list = response["list"] as? [[String: Any]] {
                    let data = try JSONSerialization.data(withJSONObject: list)
                    let items = try JSONDecoder.rclone.decode([FileItem].self, from: data)

                    for item in items where !item.isDir && item.size > 0 {
                        filesBySize[item.size, default: []].append((remote: fs, path: item.path, name: item.name))
                    }
                }
            } catch {
                print("[RcloneGUI] Duplicate scan error for \(remote): \(error.localizedDescription)")
            }
        }

        // Filter to only sizes with 2+ files (potential duplicates)
        let candidates = filesBySize.filter { $0.value.count >= 2 }

        progress = L10n.t("duplicate.comparing")

        // For candidates, check by hash
        var duplicateGroups: [DuplicateGroup] = []

        for (size, files) in candidates {
            var hashMap: [String: [(remote: String, path: String, name: String)]] = [:]

            for file in files {
                let hashes = (try? await RcloneAPI.hashFile(using: client, fs: file.remote, remote: file.path, hashTypes: ["md5"])) ?? [:]
                let hash = hashes["md5"] ?? "unknown-\(UUID().uuidString)"
                hashMap[hash, default: []].append(file)
            }

            for (hash, hashFiles) in hashMap where hashFiles.count >= 2 {
                duplicateGroups.append(DuplicateGroup(hash: hash, size: size, files: hashFiles))
            }
        }

        groups = duplicateGroups.sorted { $0.wastedSpace > $1.wastedSpace }
        progress = ""
        isScanning = false
    }

    @MainActor
    func deleteFile(remote: String, path: String) async {
        do {
            try await RcloneAPI.deleteFile(using: client, fs: remote, remote: path)
            // Remove from groups
            for i in groups.indices {
                groups[i].files.removeAll { $0.remote == remote && $0.path == path }
            }
            groups.removeAll { $0.files.count < 2 }
        } catch {
            print("[RcloneGUI] Delete duplicate error: \(error.localizedDescription)")
        }
    }
}
