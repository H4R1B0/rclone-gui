import Testing
import Foundation
@testable import RcloneKit

@Suite("FileItem Model Tests")
struct FileItemModelTests {
    @Test("Decode FileItem from rclone JSON")
    func decodeFromRcloneJSON() throws {
        let json: [String: Any] = [
            "Path": "Documents/report.pdf",
            "Name": "report.pdf",
            "Size": 1048576,
            "MimeType": "application/pdf",
            "ModTime": "2025-12-01T10:30:00.000000000Z",
            "IsDir": false
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let item = try JSONDecoder.rclone.decode(FileItem.self, from: data)

        #expect(item.name == "report.pdf")
        #expect(item.path == "Documents/report.pdf")
        #expect(item.size == 1048576)
        #expect(item.isDir == false)
        #expect(item.mimeType == "application/pdf")
    }

    @Test("Decode directory FileItem")
    func decodeDirItem() throws {
        let json: [String: Any] = [
            "Path": "Photos",
            "Name": "Photos",
            "Size": -1,
            "MimeType": "inode/directory",
            "ModTime": "2025-11-15T08:00:00.000000000Z",
            "IsDir": true
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let item = try JSONDecoder.rclone.decode(FileItem.self, from: data)

        #expect(item.name == "Photos")
        #expect(item.isDir == true)
    }

    @Test("FileItem id is path")
    func idIsPath() throws {
        let json: [String: Any] = [
            "Path": "test/file.txt",
            "Name": "file.txt",
            "Size": 100,
            "MimeType": "text/plain",
            "ModTime": "2025-12-01T00:00:00.000000000Z",
            "IsDir": false
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let item = try JSONDecoder.rclone.decode(FileItem.self, from: data)
        #expect(item.id == "test/file.txt")
    }
}

@Suite("Remote Model Tests")
struct RemoteModelTests {
    @Test("Remote creation")
    func createRemote() {
        let remote = Remote(name: "gdrive", type: "drive")
        #expect(remote.name == "gdrive")
        #expect(remote.type == "drive")
        #expect(remote.displayName == "gdrive")
        #expect(remote.id == "gdrive")
    }
}

@Suite("Location Model Tests")
struct LocationModelTests {
    @Test("Location creation")
    func createLocation() {
        let loc = Location(fs: "gdrive:", path: "/Documents/file.txt")
        #expect(loc.fs == "gdrive:")
        #expect(loc.path == "/Documents/file.txt")
    }

    @Test("Location equality")
    func equality() {
        let a = Location(fs: "gdrive:", path: "/test")
        let b = Location(fs: "gdrive:", path: "/test")
        let c = Location(fs: "dropbox:", path: "/test")
        #expect(a == b)
        #expect(a != c)
    }
}
