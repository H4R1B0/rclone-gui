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

    init(configURL: URL? = nil) {
        self.configURL = configURL ?? AppConstants.appSupportDir.appendingPathComponent(AppConstants.bookmarksFile)
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

    func isBookmarked(fs: String, path: String) -> Bool {
        bookmarks.contains { $0.fs == fs && $0.path == path }
    }

    func toggle(fs: String, path: String) {
        if let existing = bookmarks.first(where: { $0.fs == fs && $0.path == path }) {
            remove(id: existing.id)
        } else {
            let name = PathUtils.fileName(path).isEmpty ? fs : PathUtils.fileName(path)
            add(name: name, fs: fs, path: path)
        }
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
