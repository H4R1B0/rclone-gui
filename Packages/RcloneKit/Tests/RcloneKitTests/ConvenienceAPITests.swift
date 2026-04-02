import Testing
import Foundation
@testable import RcloneKit

@Suite("RcloneAPI Convenience Tests")
struct ConvenienceAPITests {
    @Test("listRemotes returns remote names")
    func listRemotes() async throws {
        let mock = MockRcloneClient()
        mock.responses["config/listremotes"] = ["remotes": ["gdrive", "dropbox"]]

        let remotes = try await RcloneAPI.listRemotes(using: mock)
        #expect(remotes == ["gdrive", "dropbox"])
    }

    @Test("listRemotes returns empty for no remotes")
    func listRemotesEmpty() async throws {
        let mock = MockRcloneClient()
        mock.responses["config/listremotes"] = ["remotes": [String]()]

        let remotes = try await RcloneAPI.listRemotes(using: mock)
        #expect(remotes.isEmpty)
    }

    @Test("listFiles returns FileItem array")
    func listFiles() async throws {
        let mock = MockRcloneClient()
        mock.responses["operations/list"] = [
            "list": [
                [
                    "Path": "file.txt",
                    "Name": "file.txt",
                    "Size": 100,
                    "ModTime": "2025-12-01T10:30:00.000000000Z",
                    "IsDir": false,
                    "MimeType": "text/plain"
                ]
            ]
        ]

        let files = try await RcloneAPI.listFiles(using: mock, fs: "gdrive:", remote: "/")
        #expect(files.count == 1)
        #expect(files[0].name == "file.txt")
    }

    @Test("listFiles returns empty when no list key")
    func listFilesEmpty() async throws {
        let mock = MockRcloneClient()
        mock.responses["operations/list"] = [:]

        let files = try await RcloneAPI.listFiles(using: mock, fs: "gdrive:", remote: "/")
        #expect(files.isEmpty)
    }

    @Test("mkdir calls operations/mkdir")
    func mkdir() async throws {
        let mock = MockRcloneClient()
        mock.responses["operations/mkdir"] = [:]

        try await RcloneAPI.mkdir(using: mock, fs: "gdrive:", remote: "/NewFolder")
        #expect(mock.callLog.count == 1)
        #expect(mock.callLog[0].method == "operations/mkdir")
    }

    @Test("deleteFile calls operations/deletefile")
    func deleteFile() async throws {
        let mock = MockRcloneClient()
        mock.responses["operations/deletefile"] = [:]

        try await RcloneAPI.deleteFile(using: mock, fs: "gdrive:", remote: "/file.txt")
        #expect(mock.callLog[0].method == "operations/deletefile")
    }

    @Test("purge calls operations/purge")
    func purge() async throws {
        let mock = MockRcloneClient()
        mock.responses["operations/purge"] = [:]

        try await RcloneAPI.purge(using: mock, fs: "gdrive:", remote: "/OldFolder")
        #expect(mock.callLog[0].method == "operations/purge")
    }

    @Test("copyFile calls operations/copyfile with correct params")
    func copyFile() async throws {
        let mock = MockRcloneClient()
        mock.responses["operations/copyfile"] = [:]

        try await RcloneAPI.copyFile(using: mock, srcFs: "gdrive:", srcRemote: "/a.txt", dstFs: "dropbox:", dstRemote: "/a.txt")
        #expect(mock.callLog[0].method == "operations/copyfile")
    }

    @Test("moveFile calls operations/movefile")
    func moveFile() async throws {
        let mock = MockRcloneClient()
        mock.responses["operations/movefile"] = [:]

        try await RcloneAPI.moveFile(using: mock, srcFs: "gdrive:", srcRemote: "/a.txt", dstFs: "dropbox:", dstRemote: "/b.txt")
        #expect(mock.callLog[0].method == "operations/movefile")
    }

    @Test("createRemote calls config/create")
    func createRemote() async throws {
        let mock = MockRcloneClient()
        mock.responses["config/create"] = [:]

        try await RcloneAPI.createRemote(using: mock, name: "test", type: "drive", parameters: [:])
        #expect(mock.callLog[0].method == "config/create")
    }

    @Test("deleteRemote calls config/delete")
    func deleteRemote() async throws {
        let mock = MockRcloneClient()
        mock.responses["config/delete"] = [:]

        try await RcloneAPI.deleteRemote(using: mock, name: "test")
        #expect(mock.callLog[0].method == "config/delete")
    }
}
