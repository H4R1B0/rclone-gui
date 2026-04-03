import Testing
import Foundation
@testable import RcloneGUI

@Suite("TransferCheckpoint Tests")
struct TransferCheckpointTests {
    @Test("Checkpoint creation")
    func creation() {
        let cp = TransferCheckpoint(fileName: "test.zip", srcFs: "gdrive:", srcRemote: "/test.zip", dstFs: "/", dstRemote: "/local/test.zip", isDir: false, totalSize: 1_000_000)
        #expect(cp.fileName == "test.zip")
        #expect(cp.attempts == 0)
        #expect(cp.lastError == nil)
        #expect(cp.bytesTransferred == 0)
    }

    @Test("Checkpoint add and remove")
    func addRemove() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock)
        vm.checkpoints = []
        let cp = TransferCheckpoint(fileName: "a.txt", srcFs: "/", srcRemote: "/a.txt", dstFs: "gdrive:", dstRemote: "/a.txt", isDir: false, totalSize: 100)
        vm.addCheckpoint(cp)
        #expect(vm.checkpoints.count == 1)
        vm.removeCheckpoint(id: cp.id)
        #expect(vm.checkpoints.isEmpty)
    }

    @Test("Checkpoint persists fileName and paths")
    func persistence() {
        let cp = TransferCheckpoint(fileName: "backup.tar", srcFs: "s3:", srcRemote: "/bucket/backup.tar", dstFs: "/", dstRemote: "/local/backup.tar", isDir: false, totalSize: 5_000_000)
        #expect(cp.srcFs == "s3:")
        #expect(cp.dstFs == "/")
        #expect(cp.isDir == false)
    }

    @Test("Checkpoint Codable round-trip")
    func codable() throws {
        let cp = TransferCheckpoint(fileName: "data.csv", srcFs: "gdrive:", srcRemote: "/data.csv", dstFs: "/", dstRemote: "/data.csv", isDir: false, totalSize: 256)
        let data = try JSONEncoder().encode(cp)
        let decoded = try JSONDecoder().decode(TransferCheckpoint.self, from: data)
        #expect(decoded.fileName == "data.csv")
        #expect(decoded.totalSize == 256)
    }

    @Test("Checkpoint directory flag")
    func directoryFlag() {
        let cp = TransferCheckpoint(fileName: "photos", srcFs: "gdrive:", srcRemote: "/photos", dstFs: "/", dstRemote: "/local/photos", isDir: true, totalSize: 0)
        #expect(cp.isDir == true)
    }
}
