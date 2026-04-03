import Foundation
import RcloneKit

struct TrashedFile: Identifiable, Codable {
    let id: UUID
    let name: String
    let originalFs: String
    let originalPath: String
    let size: Int64
    let trashedAt: Date

    init(name: String, originalFs: String, originalPath: String, size: Int64) {
        self.id = UUID()
        self.name = name
        self.originalFs = originalFs
        self.originalPath = originalPath
        self.size = size
        self.trashedAt = Date()
    }
}

@Observable
final class TrashViewModel {
    var items: [TrashedFile] = []

    private let configURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("RcloneGUI")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        configURL = appDir.appendingPathComponent("trash.json")
        load()
    }

    /// Record a deleted file (the actual delete is done by the caller)
    func recordDeletion(name: String, fs: String, path: String, size: Int64) {
        let item = TrashedFile(name: name, originalFs: fs, originalPath: path, size: size)
        items.insert(item, at: 0)
        if items.count > 500 { items = Array(items.prefix(500)) }
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
