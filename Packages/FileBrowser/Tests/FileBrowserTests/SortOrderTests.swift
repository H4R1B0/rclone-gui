import Testing
import Foundation
@testable import FileBrowser
import RcloneKit

@Suite("SortOrder Tests")
struct SortOrderTests {
    let files: [FileItem] = {
        let decoder = JSONDecoder.rclone
        let items: [[String: Any]] = [
            ["Path": "b.txt", "Name": "b.txt", "Size": 200, "ModTime": "2025-12-02T00:00:00.000000000Z", "IsDir": false, "MimeType": "text/plain"],
            ["Path": "a.txt", "Name": "a.txt", "Size": 100, "ModTime": "2025-12-01T00:00:00.000000000Z", "IsDir": false, "MimeType": "text/plain"],
            ["Path": "Photos", "Name": "Photos", "Size": -1, "ModTime": "2025-11-01T00:00:00.000000000Z", "IsDir": true, "MimeType": "inode/directory"],
            ["Path": "c.txt", "Name": "c.txt", "Size": 50, "ModTime": "2025-12-03T00:00:00.000000000Z", "IsDir": false, "MimeType": "text/plain"],
        ]
        return items.compactMap { dict in
            guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
            return try? decoder.decode(FileItem.self, from: data)
        }
    }()

    @Test("Sort by name — folders always first")
    func sortByName() {
        let sorted = SortOrder.name.sorted(files, ascending: true)
        #expect(sorted[0].name == "Photos")
        #expect(sorted[1].name == "a.txt")
        #expect(sorted[2].name == "b.txt")
        #expect(sorted[3].name == "c.txt")
    }

    @Test("Sort by size")
    func sortBySize() {
        let sorted = SortOrder.size.sorted(files, ascending: true)
        #expect(sorted[0].isDir == true)
        #expect(sorted[1].name == "c.txt")
        #expect(sorted[2].name == "a.txt")
        #expect(sorted[3].name == "b.txt")
    }

    @Test("Sort descending — folders still first")
    func sortDescending() {
        let sorted = SortOrder.name.sorted(files, ascending: false)
        #expect(sorted[0].name == "Photos")
        #expect(sorted[1].name == "c.txt")
        #expect(sorted[2].name == "b.txt")
        #expect(sorted[3].name == "a.txt")
    }
}
