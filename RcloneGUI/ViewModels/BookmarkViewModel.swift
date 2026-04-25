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

    func rename(id: UUID, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let idx = bookmarks.firstIndex(where: { $0.id == id }) else { return }
        bookmarks[idx].name = trimmed
        save()
    }

    func move(fromIndex: Int, toIndex: Int) {
        guard fromIndex >= 0, fromIndex < bookmarks.count,
              toIndex >= 0, toIndex <= bookmarks.count,
              fromIndex != toIndex else { return }
        let item = bookmarks.remove(at: fromIndex)
        let insertIndex = fromIndex < toIndex ? toIndex - 1 : toIndex
        bookmarks.insert(item, at: min(insertIndex, bookmarks.count))
        save()
    }

    func moveFromOffsets(_ offsets: IndexSet, to destination: Int) {
        // Manual implementation to avoid SwiftUI dependency
        let items = offsets.map { bookmarks[$0] }
        let remaining: [Bookmark]
        var adjustedDest = destination
        do {
            var tmp = bookmarks
            for idx in offsets.sorted(by: >) {
                tmp.remove(at: idx)
                if idx < destination { adjustedDest -= 1 }
            }
            remaining = tmp
        }
        var result = remaining
        result.insert(contentsOf: items, at: min(max(adjustedDest, 0), result.count))
        bookmarks = result
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
