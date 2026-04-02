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

@Suite("RcloneStats Model Tests")
struct RcloneStatsModelTests {
    @Test("RcloneStats init from dict")
    func initFromDict() {
        let dict: [String: Any] = [
            "bytes": Int64(2048),
            "speed": 1024.5,
            "totalBytes": Int64(4096),
            "totalTransfers": 10,
            "transfers": 3,
            "errors": 1,
            "lastError": "some error",
            "eta": 30.0,
            "transferring": [
                [
                    "name": "file.txt",
                    "size": Int64(100),
                    "bytes": Int64(50),
                    "percentage": 50,
                    "speed": 512.0,
                    "speedAvg": 480.0,
                    "eta": 0.1,
                    "group": "job/1"
                ]
            ]
        ]
        let stats = RcloneStats(from: dict)
        #expect(stats.bytes == 2048)
        #expect(stats.speed == 1024.5)
        #expect(stats.totalBytes == 4096)
        #expect(stats.totalTransfers == 10)
        #expect(stats.transfers == 3)
        #expect(stats.errors == 1)
        #expect(stats.lastError == "some error")
        #expect(stats.eta == 30.0)
        #expect(stats.transferring?.count == 1)
        #expect(stats.transferring?[0].name == "file.txt")
        #expect(stats.transferring?[0].percentage == 50)
    }

    @Test("RcloneStats defaults to zero for missing keys")
    func defaultsForMissingKeys() {
        let stats = RcloneStats(from: [:])
        #expect(stats.bytes == 0)
        #expect(stats.speed == 0)
        #expect(stats.errors == 0)
        #expect(stats.lastError == nil)
        #expect(stats.eta == nil)
        #expect(stats.transferring == nil)
    }
}

@Suite("RcloneProvider Model Tests")
struct RcloneProviderModelTests {
    @Test("RcloneProvider init from dict with options")
    func initFromDict() {
        let dict: [String: Any] = [
            "Name": "Google Drive",
            "Description": "Google Drive storage",
            "Prefix": "drive",
            "Options": [
                [
                    "Name": "client_id",
                    "Help": "OAuth Client Id",
                    "Default": "",
                    "Required": false,
                    "IsPassword": false,
                    "Hide": 0,
                    "Advanced": false
                ],
                [
                    "Name": "client_secret",
                    "Help": "OAuth Client Secret",
                    "Default": "",
                    "Required": false,
                    "IsPassword": true,
                    "Hide": 2,
                    "Advanced": false
                ]
            ]
        ]
        let provider = RcloneProvider(from: dict)
        #expect(provider.name == "Google Drive")
        #expect(provider.description == "Google Drive storage")
        #expect(provider.prefix == "drive")
        #expect(provider.id == "drive")
        #expect(provider.options.count == 2)
        #expect(provider.options[0].name == "client_id")
        #expect(provider.options[0].isPassword == false)
        #expect(provider.options[0].isVisible == true)
        #expect(provider.options[1].name == "client_secret")
        #expect(provider.options[1].isPassword == true)
        #expect(provider.options[1].isVisible == false)
    }

    @Test("RcloneProvider with no options")
    func noOptions() {
        let provider = RcloneProvider(from: ["Name": "S3", "Prefix": "s3", "Description": "Amazon S3"])
        #expect(provider.options.isEmpty)
    }
}

@Suite("RcloneCompletedTransfer Model Tests")
struct RcloneCompletedTransferModelTests {
    @Test("ok is true when error is empty")
    func okWhenNoError() {
        let transfer = RcloneCompletedTransfer(from: [
            "name": "file.txt",
            "size": Int64(100),
            "bytes": Int64(100),
            "error": "",
            "group": "job/1",
            "completed_at": "2025-12-01T10:00:00Z"
        ])
        #expect(transfer.ok == true)
        #expect(transfer.name == "file.txt")
    }

    @Test("ok is false when error is non-empty")
    func notOkWhenError() {
        let transfer = RcloneCompletedTransfer(from: [
            "name": "broken.txt",
            "size": Int64(100),
            "bytes": Int64(0),
            "error": "permission denied",
            "group": "job/2",
            "completed_at": "2025-12-01T11:00:00Z"
        ])
        #expect(transfer.ok == false)
        #expect(transfer.error == "permission denied")
    }
}
