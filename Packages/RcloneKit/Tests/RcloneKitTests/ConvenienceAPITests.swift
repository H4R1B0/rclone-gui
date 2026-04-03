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

    @Test("getProviders returns parsed providers")
    func getProviders() async throws {
        let mock = MockRcloneClient()
        mock.responses["config/providers"] = [
            "providers": [
                [
                    "Name": "Google Drive",
                    "Description": "Google Drive",
                    "Prefix": "drive",
                    "Options": [
                        ["Name": "client_id", "Help": "OAuth Client Id", "Default": "", "Required": false, "IsPassword": false, "Hide": 0, "Advanced": false]
                    ]
                ]
            ]
        ]

        let providers = try await RcloneAPI.getProviders(using: mock)
        #expect(providers.count == 1)
        #expect(providers[0].name == "Google Drive")
        #expect(providers[0].prefix == "drive")
        #expect(providers[0].options.count == 1)
        #expect(providers[0].options[0].name == "client_id")
    }

    @Test("getRemoteConfig returns dict")
    func getRemoteConfig() async throws {
        let mock = MockRcloneClient()
        mock.responses["config/get"] = ["type": "drive", "client_id": "abc123"]

        let config = try await RcloneAPI.getRemoteConfig(using: mock, name: "gdrive")
        #expect(config["type"] as? String == "drive")
        #expect(mock.callLog[0].method == "config/get")
        #expect(mock.callLog[0].params["name"] as? String == "gdrive")
    }

    @Test("copyFileAsync returns jobid and passes _async: true")
    func copyFileAsync() async throws {
        let mock = MockRcloneClient()
        mock.responses["operations/copyfile"] = ["jobid": 42]

        let jobid = try await RcloneAPI.copyFileAsync(
            using: mock,
            srcFs: "gdrive:", srcRemote: "/a.txt",
            dstFs: "dropbox:", dstRemote: "/a.txt"
        )
        #expect(jobid == 42)
        #expect(mock.callLog[0].params["_async"] as? Bool == true)
    }

    @Test("moveDir uses sync/move with combined path")
    func moveDir() async throws {
        let mock = MockRcloneClient()
        mock.responses["sync/move"] = ["jobid": 7]

        let jobid = try await RcloneAPI.moveDir(
            using: mock,
            srcFs: "gdrive:", srcRemote: "/Folder",
            dstFs: "dropbox:", dstRemote: "/Folder"
        )
        #expect(jobid == 7)
        #expect(mock.callLog[0].method == "sync/move")
        #expect(mock.callLog[0].params["srcFs"] as? String == "gdrive:/Folder")
        #expect(mock.callLog[0].params["dstFs"] as? String == "dropbox:/Folder")
    }

    @Test("getStats returns parsed RcloneStats")
    func getStats() async throws {
        let mock = MockRcloneClient()
        mock.responses["core/stats"] = [
            "bytes": Int64(1024),
            "speed": 512.0,
            "totalBytes": Int64(2048),
            "totalTransfers": 5,
            "transfers": 2,
            "errors": 0
        ]

        let stats = try await RcloneAPI.getStats(using: mock)
        #expect(stats.bytes == 1024)
        #expect(stats.speed == 512.0)
        #expect(stats.totalTransfers == 5)
        #expect(stats.errors == 0)
    }

    @Test("getTransferred returns parsed array")
    func getTransferred() async throws {
        let mock = MockRcloneClient()
        mock.responses["core/transferred"] = [
            "transferred": [
                [
                    "name": "file.txt",
                    "size": Int64(100),
                    "bytes": Int64(100),
                    "error": "",
                    "group": "job/1",
                    "completed_at": "2025-12-01T10:30:00Z"
                ]
            ]
        ]

        let transfers = try await RcloneAPI.getTransferred(using: mock)
        #expect(transfers.count == 1)
        #expect(transfers[0].name == "file.txt")
        #expect(transfers[0].ok == true)
    }

    @Test("getJobList returns jobids")
    func getJobList() async throws {
        let mock = MockRcloneClient()
        mock.responses["job/list"] = ["jobids": [1, 2, 3]]

        let jobids = try await RcloneAPI.getJobList(using: mock)
        #expect(jobids == [1, 2, 3])
        #expect(mock.callLog[0].method == "job/list")
    }

    @Test("stopJob calls correct endpoint")
    func stopJob() async throws {
        let mock = MockRcloneClient()
        mock.responses["job/stop"] = [:]

        try await RcloneAPI.stopJob(using: mock, jobid: 5)
        #expect(mock.callLog[0].method == "job/stop")
        #expect(mock.callLog[0].params["jobid"] as? Int == 5)
    }

    @Test("setBwLimit calls with rate param")
    func setBwLimit() async throws {
        let mock = MockRcloneClient()
        mock.responses["core/bwlimit"] = [:]

        try await RcloneAPI.setBwLimit(using: mock, rate: "1M")
        #expect(mock.callLog[0].method == "core/bwlimit")
        #expect(mock.callLog[0].params["rate"] as? String == "1M")
    }

    @Test("hashFile returns hash dict")
    func hashFile() async throws {
        let mock = MockRcloneClient()
        mock.responses["operations/hashfile"] = ["hash": "abc123def456"]

        let hashes = try await RcloneAPI.hashFile(
            using: mock,
            fs: "gdrive:", remote: "/file.txt",
            hashTypes: ["md5"]
        )
        #expect(hashes["md5"] == "abc123def456")
        #expect(mock.callLog[0].method == "operations/hashfile")
        #expect(mock.callLog[0].params["hashType"] as? String == "md5")
    }
}
