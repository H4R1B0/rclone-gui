import Foundation
import RcloneKit

enum TrashError: LocalizedError {
    case nativeTrashRestore

    var errorDescription: String? {
        switch self {
        case .nativeTrashRestore:
            return L10n.t("trash.nativeRestoreUnavailable")
        }
    }
}

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
    /// true when deleted via provider's native trash (not restorable from app)
    let nativeTrash: Bool

    init(name: String, originalFs: String, originalPath: String, size: Int64, isDir: Bool,
         trashFs: String, trashPath: String, nativeTrash: Bool = false) {
        self.id = UUID()
        self.name = name
        self.originalFs = originalFs
        self.originalPath = originalPath
        self.size = size
        self.trashedAt = Date()
        self.isDir = isDir
        self.trashFs = trashFs
        self.trashPath = trashPath
        self.nativeTrash = nativeTrash
    }

    /// Decode with backward compatibility for older data without nativeTrash field
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        originalFs = try container.decode(String.self, forKey: .originalFs)
        originalPath = try container.decode(String.self, forKey: .originalPath)
        size = try container.decode(Int64.self, forKey: .size)
        trashedAt = try container.decode(Date.self, forKey: .trashedAt)
        isDir = try container.decode(Bool.self, forKey: .isDir)
        trashFs = try container.decode(String.self, forKey: .trashFs)
        trashPath = try container.decode(String.self, forKey: .trashPath)
        nativeTrash = try container.decodeIfPresent(Bool.self, forKey: .nativeTrash) ?? false
    }
}

@Observable
final class TrashViewModel {
    var items: [TrashedFile] = []

    private let configURL: URL
    private let client: RcloneClientProtocol

    /// Provider types that support native trash/recycle bin via rclone delete.
    /// These providers send files to their recycle bin by default when using deletefile/delete.
    private static let nativeTrashProviders: Set<String> = [
        "drive",        // Google Drive — --drive-use-trash (default true)
        "onedrive",     // OneDrive — --onedrive-hard-delete (default false)
        "mega",         // Mega — --mega-hard-delete (default false)
        "jottacloud",   // Jottacloud — --jottacloud-hard-delete (default false)
        "yandex",       // Yandex Disk — --yandex-hard-delete (default false)
        "pikpak",       // PikPak — --pikpak-use-trash (default true)
        "quatrix",      // Quatrix — --quatrix-hard-delete (default false)
        "drime",        // Drime — --drime-hard-delete (default false)
        "sugarsync",    // SugarSync — --sugarsync-hard-delete (default false)
        "b2",           // Backblaze B2 — --b2-hard-delete (default false, hides versions)
    ]

    init(client: RcloneClientProtocol, configURL: URL? = nil) {
        self.client = client
        self.configURL = configURL ?? AppConstants.appSupportDir.appendingPathComponent(AppConstants.trashFile)
        load()
    }

    /// Check if a remote type supports provider-native trash
    static func supportsNativeTrash(remoteType: String) -> Bool {
        nativeTrashProviders.contains(remoteType)
    }

    // MARK: - Move to Trash

    /// - Parameter remoteType: rclone backend type (e.g. "drive", "s3"). Pass "" for local.
    func deleteToTrash(fs: String, path: String, name: String, isDir: Bool, size: Int64, remoteType: String = "") async throws {
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
        } else if Self.supportsNativeTrash(remoteType: remoteType) {
            // Provider supports native trash: delete directly (goes to provider's recycle bin)
            if isDir {
                // purge bypasses trash on some providers (e.g. Google Drive).
                // Use delete (files → recycle bin) + rmdirs (clean empty dirs) instead.
                try await RcloneAPI.deleteDir(using: client, fs: fs, remote: path)
                try? await RcloneAPI.rmdirs(using: client, fs: fs, remote: path)
            } else {
                try await RcloneAPI.deleteFile(using: client, fs: fs, remote: path)
            }
            let item = TrashedFile(name: name, originalFs: fs, originalPath: path, size: size, isDir: isDir,
                                   trashFs: fs, trashPath: path, nativeTrash: true)
            items.insert(item, at: 0)
        } else {
            // No native trash: use .trash directory at remote root
            let trashPath = AppConstants.trashDirName + "/" + path
            if isDir {
                _ = try await RcloneAPI.moveDir(using: client, srcFs: fs, srcRemote: path, dstFs: fs, dstRemote: trashPath, async: false)
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
        if item.nativeTrash {
            // Native trash items can only be restored from the provider's web UI
            throw TrashError.nativeTrashRestore
        }
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
        if item.nativeTrash {
            // Already in provider's trash — just remove from our list
            items.removeAll { $0.id == item.id }
            save()
            return
        }
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
            // Native trash items are already in the provider's recycle bin — skip
            if item.nativeTrash { continue }

            if item.originalFs == "/" && item.trashPath.contains("/.Trash/") {
                // Local: permanently delete from macOS trash
                let url = URL(fileURLWithPath: item.trashPath)
                try? FileManager.default.removeItem(at: url)
            } else {
                // Cloud: delete from .trash dir via rclone
                if item.isDir {
                    try? await RcloneAPI.purge(using: client, fs: item.trashFs, remote: item.trashPath)
                } else {
                    try? await RcloneAPI.deleteFile(using: client, fs: item.trashFs, remote: item.trashPath)
                }
            }
        }

        if let f = fs {
            // Only purge .trash dir if there are non-native items on this remote
            let hasNonNativeItems = targets.contains { !$0.nativeTrash && $0.originalFs != "/" }
            if f != "/" && hasNonNativeItems {
                try? await RcloneAPI.purge(using: client, fs: f, remote: AppConstants.trashDirName)
            }
            // Empty the provider's native trash and wait for completion
            let hasNativeItems = targets.contains { $0.nativeTrash }
            if f != "/" && hasNativeItems {
                try? await RcloneAPI.cleanup(using: client, fs: f)
            }
            items.removeAll { $0.originalFs == f }
        } else {
            // Purge .trash only for remotes that have non-native items
            let cloudRemotes = Set(targets.filter { $0.originalFs != "/" && !$0.nativeTrash }.map(\.trashFs))
            for remote in cloudRemotes {
                try? await RcloneAPI.purge(using: client, fs: remote, remote: AppConstants.trashDirName)
            }
            // Empty native trash for each provider that supports it
            let nativeRemotes = Set(targets.filter { $0.nativeTrash }.map(\.trashFs))
            for remote in nativeRemotes {
                try? await RcloneAPI.cleanup(using: client, fs: remote)
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
