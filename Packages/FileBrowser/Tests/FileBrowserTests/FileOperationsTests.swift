import Testing
import Foundation
@testable import FileBrowser
import RcloneKit

@Suite("FileOperations Tests")
struct FileOperationsTests {
    @Test("list returns file items")
    func list() async throws {
        let mock = MockRcloneClient()
        mock.responses["operations/list"] = [
            "list": [
                ["Path": "doc.txt", "Name": "doc.txt", "Size": 50, "ModTime": "2025-12-01T00:00:00.000000000Z", "IsDir": false, "MimeType": "text/plain"]
            ]
        ]
        let ops = FileOperations(client: mock)
        let files = try await ops.list(fs: "gdrive:", path: "/")
        #expect(files.count == 1)
        #expect(files[0].name == "doc.txt")
    }

    @Test("rename calls movefile")
    func rename() async throws {
        let mock = MockRcloneClient()
        mock.responses["operations/movefile"] = [:]
        let ops = FileOperations(client: mock)

        try await ops.rename(fs: "gdrive:", path: "/docs", from: "old.txt", to: "new.txt")
        #expect(mock.callLog[0].method == "operations/movefile")
    }

    @Test("delete file calls deletefile")
    func deleteFile() async throws {
        let mock = MockRcloneClient()
        mock.responses["operations/deletefile"] = [:]
        let ops = FileOperations(client: mock)

        try await ops.delete(fs: "gdrive:", remote: "/file.txt", isDir: false)
        #expect(mock.callLog[0].method == "operations/deletefile")
    }

    @Test("delete directory calls purge")
    func deleteDir() async throws {
        let mock = MockRcloneClient()
        mock.responses["operations/purge"] = [:]
        let ops = FileOperations(client: mock)

        try await ops.delete(fs: "gdrive:", remote: "/folder", isDir: true)
        #expect(mock.callLog[0].method == "operations/purge")
    }

    @Test("mkdir calls operations/mkdir")
    func mkdir() async throws {
        let mock = MockRcloneClient()
        mock.responses["operations/mkdir"] = [:]
        let ops = FileOperations(client: mock)

        try await ops.mkdir(fs: "gdrive:", path: "/NewFolder")
        #expect(mock.callLog[0].method == "operations/mkdir")
    }
}
