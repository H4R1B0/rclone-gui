import Foundation

struct Bookmark: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var fs: String
    var path: String
    var createdAt: Date

    init(name: String, fs: String, path: String) {
        self.id = UUID()
        self.name = name
        self.fs = fs
        self.path = path
        self.createdAt = Date()
    }

    var displayPath: String {
        fs == "/" ? "/\(path)" : "\(fs)\(path)"
    }
}

@Observable
final class BookmarkViewModel {
    var bookmarks: [Bookmark] = []

    private let configURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("RcloneGUI")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        configURL = appDir.appendingPathComponent("bookmarks.json")
        load()
    }

    func add(name: String, fs: String, path: String) {
        bookmarks.append(Bookmark(name: name, fs: fs, path: path))
        save()
    }

    func remove(id: UUID) {
        bookmarks.removeAll { $0.id == id }
        save()
    }

    func save() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            try? data.write(to: configURL)
        }
    }

    func load() {
        guard let data = try? Data(contentsOf: configURL),
              let loaded = try? JSONDecoder().decode([Bookmark].self, from: data)
        else { return }
        bookmarks = loaded
    }
}
