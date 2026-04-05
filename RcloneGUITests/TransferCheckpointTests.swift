import Testing
import Foundation
@testable import RcloneGUI

@Suite("TransferCheckpoint Tests")
struct TransferCheckpointTests {
    private func makeTempURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("cp_test_\(UUID().uuidString).json")
    }

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
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
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

    @Test("Checkpoint attempts increment")
    func attemptsIncrement() {
        var cp = TransferCheckpoint(fileName: "retry.bin", srcFs: "/", srcRemote: "/retry.bin", dstFs: "gdrive:", dstRemote: "/retry.bin", isDir: false, totalSize: 500)
        #expect(cp.attempts == 0)
        cp.attempts += 1
        cp.lastError = "network timeout"
        cp.lastAttempt = Date()
        #expect(cp.attempts == 1)
        #expect(cp.lastError == "network timeout")
        #expect(cp.lastAttempt != nil)
    }

    @Test("Multiple checkpoints independent IDs")
    func uniqueIds() {
        let cp1 = TransferCheckpoint(fileName: "a", srcFs: "/", srcRemote: "/a", dstFs: "s3:", dstRemote: "/a", isDir: false, totalSize: 10)
        let cp2 = TransferCheckpoint(fileName: "b", srcFs: "/", srcRemote: "/b", dstFs: "s3:", dstRemote: "/b", isDir: false, totalSize: 20)
        #expect(cp1.id != cp2.id)
    }

    @Test("Codable preserves attempts and error")
    func codableWithAttempts() throws {
        var cp = TransferCheckpoint(fileName: "fail.dat", srcFs: "gdrive:", srcRemote: "/fail.dat", dstFs: "/", dstRemote: "/fail.dat", isDir: false, totalSize: 1024)
        cp.attempts = 3
        cp.lastError = "server error"
        let data = try JSONEncoder().encode(cp)
        let decoded = try JSONDecoder().decode(TransferCheckpoint.self, from: data)
        #expect(decoded.attempts == 3)
        #expect(decoded.lastError == "server error")
    }
}
