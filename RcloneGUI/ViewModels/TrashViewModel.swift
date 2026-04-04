import Foundation
import RcloneKit

struct TrashedFile: Identifiable, Codable {
    let id: UUID
    let name: String
    let originalFs: String
    let originalPath: String
    let size: Int64
    let trashedAt: Date
    let isDir: Bool
    // Where the file lives in trash
    let trashFs: String
    let trashPath: String

    init(name: String, originalFs: String, originalPath: String, size: Int64, isDir: Bool,
         trashFs: String, trashPath: String) {
        self.id = UUID()
        self.name = name
        self.originalFs = originalFs
        self.originalPath = originalPath
        self.size = size
        self.trashedAt = Date()
        self.isDir = isDir
        self.trashFs = trashFs
        self.trashPath = trashPath
    }
}

@Observable
final class TrashViewModel {
    var items: [TrashedFile] = []

    private let configURL: URL
    private let client: RcloneClientProtocol

    init(client: RcloneClientProtocol) {
        self.client = client
        configURL = AppConstants.appSupportDir.appendingPathComponent(AppConstants.trashFile)
        load()
    }

    // MARK: - Move to Trash

    func deleteToTrash(fs: String, path: String, name: String, isDir: Bool, size: Int64) async throws {
        if fs == "/" {
            // Local filesystem: use macOS native trash (off main thread)
            let fullPath = path.hasPrefix("/") ? path : "/\(path)"
            let fileURL = URL(fileURLWithPath: fullPath)
            let trashPath: String = try await Task.detached {
                var resultURL: NSURL?
                try FileManager.default.trashItem(at: fileURL, resultingItemURL: &resultURL)
                return resultURL?.path ?? ""
            }.value
            let item = TrashedFile(name: name, originalFs: fs, originalPath: path, size: size, isDir: isDir,
                                   trashFs: "/", trashPath: trashPath)
            items.insert(item, at: 0)
        } else {
            // Cloud remote: use .trash directory at remote root
            let trashPath = AppConstants.trashDirName + "/" + path
            if isDir {
                _ = try await RcloneAPI.moveDir(using: client, srcFs: fs, srcRemote: path, dstFs: fs, dstRemote: trashPath)
            } else {
                try await RcloneAPI.moveFile(using: client, srcFs: fs, srcRemote: path, dstFs: fs, dstRemote: trashPath)
            }
            let item = TrashedFile(name: name, originalFs: fs, originalPath: path, size: size, isDir: isDir,
                                   trashFs: fs, trashPath: trashPath)
            items.insert(item, at: 0)
        }
        if items.count > AppConstants.maxTrashItems { items = Array(items.prefix(AppConstants.maxTrashItems)) }
        save()
    }

    // MARK: - Restore

    func restore(_ item: TrashedFile) async throws {
        if item.originalFs == "/" && item.trashPath.contains("/.Trash/") {
            // Local file in macOS trash: move back via FileManager
            let srcURL = URL(fileURLWithPath: item.trashPath)
            let originalPath = item.originalPath.hasPrefix("/") ? item.originalPath : "/\(item.originalPath)"
            let dstURL = URL(fileURLWithPath: originalPath)
            // Ensure parent directory exists
            try FileManager.default.createDirectory(at: dstURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try FileManager.default.moveItem(at: srcURL, to: dstURL)
        } else {
            if item.isDir {
                _ = try await RcloneAPI.moveDir(using: client, srcFs: item.trashFs, srcRemote: item.trashPath,
                                                dstFs: item.originalFs, dstRemote: item.originalPath)
            } else {
                try await RcloneAPI.moveFile(using: client, srcFs: item.trashFs, srcRemote: item.trashPath,
                                             dstFs: item.originalFs, dstRemote: item.originalPath)
            }
        }
        items.removeAll { $0.id == item.id }
        save()
    }

    // MARK: - Permanent Delete

    func permanentDelete(_ item: TrashedFile) async throws {
        if item.originalFs == "/" && item.trashPath.contains("/.Trash/") {
            // Local file in macOS trash: delete via FileManager
            let url = URL(fileURLWithPath: item.trashPath)
            try FileManager.default.removeItem(at: url)
        } else {
            if item.isDir {
                try await RcloneAPI.purge(using: client, fs: item.trashFs, remote: item.trashPath)
            } else {
                try await RcloneAPI.deleteFile(using: client, fs: item.trashFs, remote: item.trashPath)
            }
        }
        items.removeAll { $0.id == item.id }
        save()
    }

    // MARK: - Empty Trash

    func emptyTrash(fs: String? = nil) async throws {
        let targets = fs.map { f in items.filter { $0.originalFs == f } } ?? items

        for item in targets {
            if item.originalFs == "/" && item.trashPath.contains("/.Trash/") {
                // Local: permanently delete from macOS trash
                let url = URL(fileURLWithPath: item.trashPath)
                try? FileManager.default.removeItem(at: url)
            } else {
                // Cloud: delete via rclone
                if item.isDir {
                    try? await RcloneAPI.purge(using: client, fs: item.trashFs, remote: item.trashPath)
                } else {
                    try? await RcloneAPI.deleteFile(using: client, fs: item.trashFs, remote: item.trashPath)
                }
            }
        }

        if let f = fs {
            if f != "/" {
                // Also purge the whole .trash dir for that cloud remote
                try? await RcloneAPI.purge(using: client, fs: f, remote: AppConstants.trashDirName)
            }
            items.removeAll { $0.originalFs == f }
        } else {
            // Purge .trash for each unique cloud remote
            let cloudRemotes = Set(items.filter { $0.originalFs != "/" }.map(\.trashFs))
            for remote in cloudRemotes {
                try? await RcloneAPI.purge(using: client, fs: remote, remote: AppConstants.trashDirName)
            }
            items.removeAll()
        }
        save()
    }

    // MARK: - Legacy (deprecated)

    @available(*, deprecated, message: "Use deleteToTrash(fs:path:name:isDir:size:) instead")
    func recordDeletion(name: String, fs: String, path: String, size: Int64) {
        let trashPath = AppConstants.trashDirName + "/" + path
        let item = TrashedFile(name: name, originalFs: fs, originalPath: path, size: size, isDir: false,
                               trashFs: fs, trashPath: trashPath)
        items.insert(item, at: 0)
        if items.count > AppConstants.maxTrashItems { items = Array(items.prefix(AppConstants.maxTrashItems)) }
        save()
    }

    func remove(id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    func clearAll() {
        items.removeAll()
        save()
    }

    var totalSize: Int64 { items.reduce(0) { $0 + $1.size } }

    func save() {
        if let data = try? JSONEncoder().encode(items) { try? data.write(to: configURL) }
    }

    func load() {
        guard let data = try? Data(contentsOf: configURL),
              let loaded = try? JSONDecoder().decode([TrashedFile].self, from: data)
        else { return }
        items = loaded
    }
}
