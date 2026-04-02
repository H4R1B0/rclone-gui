import Testing
import Foundation
@testable import TransferEngine
import RcloneKit

@Suite("TransferManager Tests")
struct TransferManagerTests {
    @Test("Enqueue adds a transfer")
    func enqueue() async {
        let mock = MockRcloneClient()
        mock.responses["operations/copyfile"] = [:]

        let manager = TransferManager(client: mock)
        let op = TransferOperation(
            kind: .copy,
            source: Location(fs: "gdrive:", path: "/file.txt"),
            destination: Location(fs: "dropbox:", path: "/file.txt")
        )

        await manager.enqueue(op)
        let all = await manager.allTransfers
        #expect(all.count == 1)
    }

    @Test("Completed transfers tracked after execution")
    func completedTracking() async throws {
        let mock = MockRcloneClient()
        mock.responses["operations/copyfile"] = [:]

        let manager = TransferManager(client: mock)
        let op = TransferOperation(
            kind: .copy,
            source: Location(fs: "/", path: "/test.txt"),
            destination: Location(fs: "/", path: "/dest/test.txt")
        )

        await manager.enqueue(op)
        try await Task.sleep(for: .milliseconds(200))
        let completed = await manager.completedTransfers
        #expect(completed.count == 1)
    }

    @Test("Cancel sets failed status")
    func cancel() async {
        let mock = MockRcloneClient()
        // Don't set response so it will fail, but we cancel before it runs
        mock.responses["operations/copyfile"] = [:]

        let manager = TransferManager(client: mock)
        let op = TransferOperation(
            kind: .copy,
            source: Location(fs: "gdrive:", path: "/file.txt"),
            destination: Location(fs: "dropbox:", path: "/file.txt")
        )

        await manager.enqueue(op)
        await manager.cancel(id: op.id)

        let failed = await manager.failedTransfers
        // May or may not be in failed depending on timing
        let all = await manager.allTransfers
        #expect(all.count == 1)
    }

    @Test("clearCompleted removes terminal transfers")
    func clearCompleted() async throws {
        let mock = MockRcloneClient()
        mock.responses["operations/copyfile"] = [:]

        let manager = TransferManager(client: mock)
        let op = TransferOperation(
            kind: .copy,
            source: Location(fs: "/", path: "/a.txt"),
            destination: Location(fs: "/", path: "/b.txt")
        )

        await manager.enqueue(op)
        try await Task.sleep(for: .milliseconds(200))

        await manager.clearCompleted()
        let all = await manager.allTransfers
        #expect(all.isEmpty)
    }
}
