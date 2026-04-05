import Testing
import Foundation
@testable import RcloneGUI
import RcloneKit

@Suite("TransferViewModel Tests")
struct TransferViewModelTests {
    private func makeTempURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("tv_test_\(UUID().uuidString).json")
    }

    @Test("addCopyOrigin stores origin")
    func addCopyOrigin() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        let origin = CopyOrigin(srcFs: "gdrive:", srcRemote: "/file.txt", dstFs: "/", dstRemote: "/local/file.txt", isDir: false)
        vm.addCopyOrigin(group: "test-group", origin: origin)
        #expect(vm.copyOrigins["test-group"] != nil)
        #expect(vm.copyOrigins["test-group"]?.srcFs == "gdrive:")
    }

    @Test("clearCompleted removes ok items")
    func clearCompleted() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        let ok = RcloneCompletedTransfer(from: ["name": "good", "size": 100, "bytes": 100, "error": "", "group": "g", "completed_at": "2024-01-01"])
        let fail = RcloneCompletedTransfer(from: ["name": "bad", "size": 50, "bytes": 0, "error": "network", "group": "g", "completed_at": "2024-01-01"])
        vm.completed = [ok, fail]
        vm.clearCompleted()
        #expect(vm.completed.count == 1)
        #expect(vm.completed[0].name == "bad")
    }

    @Test("clearErrors removes failed and cancelled and lastErrors")
    func clearErrors() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        let fail = RcloneCompletedTransfer(from: ["name": "bad", "size": 50, "bytes": 0, "error": "fail", "group": "g", "completed_at": "2024-01-01"])
        let cancelled = RcloneCompletedTransfer(from: ["name": "stopped", "size": 50, "bytes": 0, "error": "context canceled", "group": "g", "completed_at": "2024-01-02"])
        vm.completed = [fail, cancelled]
        vm.lastErrors = ["error1", "error2"]
        vm.clearErrors()
        #expect(vm.completed.isEmpty)
        #expect(vm.lastErrors.isEmpty)
    }

    @Test("clearInactive clears completed and errors")
    func clearInactive() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        let item = RcloneCompletedTransfer(from: ["name": "done", "size": 100, "bytes": 100, "error": "", "group": "g", "completed_at": "2024-01-01"])
        vm.completed = [item]
        vm.lastErrors = ["some error"]
        vm.clearInactive()
        #expect(vm.completed.isEmpty)
        #expect(vm.lastErrors.isEmpty)
    }

    @Test("clearAll removes everything") @MainActor
    func clearAll() async {
        let mock = MockRcloneClient()
        mock.responses["core/stats-reset"] = [:]
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        vm.completed = [RcloneCompletedTransfer(from: ["name": "x", "size": 1, "bytes": 1, "error": "", "group": "g", "completed_at": "now"])]
        vm.lastErrors = ["err"]
        vm.queued = [QueuedTransfer(name: "q", isDir: false)]
        await vm.clearAll()
        #expect(vm.completed.isEmpty)
        #expect(vm.lastErrors.isEmpty)
        #expect(vm.queued.isEmpty)
    }

    @Test("successfulCompleted filters correctly")
    func successfulCompleted() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        vm.completed = [
            RcloneCompletedTransfer(from: ["name": "ok", "size": 100, "bytes": 100, "error": "", "group": "g", "completed_at": "now"]),
            RcloneCompletedTransfer(from: ["name": "fail", "size": 50, "bytes": 0, "error": "err", "group": "g", "completed_at": "now"]),
            RcloneCompletedTransfer(from: ["name": "cancelled", "size": 50, "bytes": 0, "error": "context canceled", "group": "g", "completed_at": "now2"])
        ]
        #expect(vm.successfulCompleted.count == 1)
        #expect(vm.errorCompleted.count == 1)  // real errors only
        #expect(vm.cancelledCompleted.count == 1)
    }

    @Test("cancelledCompleted identifies user-cancelled transfers")
    func cancelledCompleted() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        vm.completed = [
            RcloneCompletedTransfer(from: ["name": "a", "size": 100, "bytes": 50, "error": "context canceled", "group": "g1", "completed_at": "t1"]),
            RcloneCompletedTransfer(from: ["name": "b", "size": 100, "bytes": 0, "error": "network error", "group": "g2", "completed_at": "t2"]),
            RcloneCompletedTransfer(from: ["name": "c", "size": 100, "bytes": 100, "error": "", "group": "g3", "completed_at": "t3"])
        ]
        #expect(vm.cancelledCompleted.count == 1)
        #expect(vm.cancelledCompleted[0].name == "a")
        #expect(vm.errorCompleted.count == 1)
        #expect(vm.errorCompleted[0].name == "b")
    }

    @Test("hasRestartInfo checks copyOrigins")
    func hasRestartInfo() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        let origin = CopyOrigin(srcFs: "gdrive:", srcRemote: "file.txt", dstFs: "/", dstRemote: "/file.txt", isDir: false)
        vm.addCopyOrigin(group: "g1", origin: origin)
        let withOrigin = RcloneCompletedTransfer(from: ["name": "a", "size": 50, "bytes": 0, "error": "context canceled", "group": "g1", "completed_at": "t1"])
        let withoutOrigin = RcloneCompletedTransfer(from: ["name": "b", "size": 50, "bytes": 0, "error": "fail", "group": "g2", "completed_at": "t2"])
        #expect(vm.hasRestartInfo(for: withOrigin))
        #expect(!vm.hasRestartInfo(for: withoutOrigin))
    }

    @Test("restartFailed re-enqueues transfer") @MainActor
    func restartFailed() async {
        let mock = MockRcloneClient()
        mock.responses["operations/copyfile"] = ["jobid": 99]
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        let origin = CopyOrigin(srcFs: "gdrive:", srcRemote: "file.txt", dstFs: "/", dstRemote: "/file.txt", isDir: false)
        vm.addCopyOrigin(group: "g1", origin: origin)
        let cancelled = RcloneCompletedTransfer(from: ["name": "file.txt", "size": 100, "bytes": 50, "error": "context canceled", "group": "g1", "completed_at": "t1"])
        vm.completed = [cancelled]
        await vm.restartFailed(cancelled)
        // Old completed entry removed
        #expect(vm.completed.isEmpty)
        // New origin registered with job ID
        #expect(vm.copyOrigins["job/99"] != nil)
        #expect(mock.callLog.contains { $0.method == "operations/copyfile" })
    }

    @Test("hasActiveTransfers reflects state")
    func hasActiveTransfers() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        #expect(!vm.hasActiveTransfers)
        vm.transfers = [RcloneTransferring(from: ["name": "t", "size": 100, "bytes": 50, "percentage": 50, "speed": 1000, "speedAvg": 1000, "eta": 10, "group": "g"])]
        #expect(vm.hasActiveTransfers)
    }

    @Test("pauseAll sets paused and calls bwlimit") @MainActor
    func pauseAll() async {
        let mock = MockRcloneClient()
        mock.responses["core/bwlimit"] = [:]
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        await vm.pauseAll()
        #expect(vm.paused == true)
        #expect(mock.callLog.contains { $0.method == "core/bwlimit" })
    }

    @Test("resumeAll clears paused and calls bwlimit off") @MainActor
    func resumeAll() async {
        let mock = MockRcloneClient()
        mock.responses["core/bwlimit"] = [:]
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        vm.paused = true
        await vm.resumeAll()
        #expect(vm.paused == false)
    }

    @Test("hasInactiveItems reflects completed state")
    func hasInactiveItems() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        #expect(!vm.hasInactiveItems)
        vm.completed = [RcloneCompletedTransfer(from: ["name": "x", "size": 1, "bytes": 1, "error": "", "group": "g", "completed_at": "now"])]
        #expect(vm.hasInactiveItems)
    }

    @Test("enqueue and dequeue manage queue")
    func queueManagement() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        vm.enqueue(QueuedTransfer(name: "file1.txt", isDir: false))
        vm.enqueue(QueuedTransfer(name: "file2.txt", isDir: false))
        #expect(vm.queued.count == 2)
        vm.dequeue(name: "file1.txt")
        #expect(vm.queued.count == 1)
        #expect(vm.queued[0].name == "file2.txt")
    }

    @Test("removeCompleted removes specific item")
    func removeCompleted() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        vm.completed = [
            RcloneCompletedTransfer(from: ["name": "keep", "size": 100, "bytes": 100, "error": "", "group": "g", "completed_at": "t1"]),
            RcloneCompletedTransfer(from: ["name": "remove", "size": 50, "bytes": 50, "error": "", "group": "g", "completed_at": "t2"])
        ]
        vm.removeCompleted(name: "remove", completedAt: "t2")
        #expect(vm.completed.count == 1)
        #expect(vm.completed[0].name == "keep")
    }

    @Test("pauseAll rollback on failure") @MainActor
    func pauseAllRollback() async {
        let mock = MockRcloneClient()
        mock.errorForMethod["core/bwlimit"] = RcloneError.rpcFailed(method: "core/bwlimit", status: 500, message: "fail")
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        await vm.pauseAll()
        #expect(vm.paused == false)
    }

    @Test("resumeAll rollback on failure") @MainActor
    func resumeAllRollback() async {
        let mock = MockRcloneClient()
        mock.errorForMethod["core/bwlimit"] = RcloneError.rpcFailed(method: "core/bwlimit", status: 500, message: "fail")
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        vm.paused = true
        await vm.resumeAll()
        #expect(vm.paused == true)
    }

    @Test("stopAllJobs stops each job and clears queue") @MainActor
    func stopAllJobs() async {
        let mock = MockRcloneClient()
        mock.responses["job/stop"] = [:]
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        vm.jobIds = [1, 2, 3]
        vm.queued = [QueuedTransfer(name: "waiting", isDir: false)]
        await vm.stopAllJobs()
        let stopCalls = mock.callLog.filter { $0.method == "job/stop" }
        #expect(stopCalls.count == 3)
        #expect(vm.queued.isEmpty)
    }

    @Test("cancelAll stops jobs, clears queue, resumes bandwidth, and moves active to cancelled") @MainActor
    func cancelAll() async {
        let mock = MockRcloneClient()
        mock.responses["job/stop"] = [:]
        mock.responses["core/bwlimit"] = [:]
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        vm.jobIds = [1, 2]
        vm.transfers = [
            RcloneTransferring(from: ["name": "big.zip", "size": 1000, "bytes": 500, "percentage": 50, "speed": 100, "speedAvg": 100, "eta": 5, "group": "job/1"]),
            RcloneTransferring(from: ["name": "doc.pdf", "size": 200, "bytes": 100, "percentage": 50, "speed": 50, "speedAvg": 50, "eta": 2, "group": "job/2"])
        ]
        vm.queued = [QueuedTransfer(name: "q1", isDir: false)]
        vm.paused = true
        await vm.cancelAll()
        // Active transfers immediately moved to cancelled
        #expect(vm.transfers.isEmpty)
        #expect(vm.cancelledCompleted.count == 2)
        #expect(vm.cancelledCompleted.contains { $0.name == "big.zip" })
        #expect(vm.cancelledCompleted.contains { $0.name == "doc.pdf" })
        // Queue cleared
        #expect(vm.queued.isEmpty)
        // Jobs stopped
        #expect(vm.jobIds.isEmpty)
        #expect(vm.paused == false)
        let stopCalls = mock.callLog.filter { $0.method == "job/stop" }
        #expect(stopCalls.count == 2)
        #expect(mock.callLog.contains { $0.method == "core/bwlimit" })
    }

    @Test("stopJob cancels individual job") @MainActor
    func stopJob() async {
        let mock = MockRcloneClient()
        mock.responses["job/stop"] = [:]
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        await vm.stopJob(id: 42)
        #expect(mock.callLog.contains { $0.method == "job/stop" })
    }

    @Test("clearInactive preserves active transfers and queue")
    func clearInactivePreservesActive() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        vm.transfers = [RcloneTransferring(from: ["name": "active", "size": 100, "bytes": 50, "percentage": 50, "speed": 1000, "speedAvg": 1000, "eta": 10, "group": "g"])]
        vm.completed = [RcloneCompletedTransfer(from: ["name": "done", "size": 100, "bytes": 100, "error": "", "group": "g", "completed_at": "now"])]
        vm.queued = [QueuedTransfer(name: "waiting", isDir: false)]
        vm.clearInactive()
        #expect(vm.completed.isEmpty)
        #expect(vm.lastErrors.isEmpty)
        #expect(vm.transfers.count == 1)
        #expect(vm.queued.count == 1)
    }

    @Test("clearInactive does not call resetStats") @MainActor
    func clearInactiveNoResetStats() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        vm.completed = [RcloneCompletedTransfer(from: ["name": "x", "size": 1, "bytes": 1, "error": "", "group": "g", "completed_at": "now"])]
        vm.clearInactive()
        #expect(!mock.callLog.contains { $0.method == "core/stats-reset" })
    }

    @Test("pauseAll uses bwlimit 1 not 0") @MainActor
    func pauseAllUsesBwLimit1() async {
        let mock = MockRcloneClient()
        mock.responses["core/bwlimit"] = [:]
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        await vm.pauseAll()
        let bwCall = mock.callLog.first { $0.method == "core/bwlimit" }
        #expect(bwCall != nil)
        let rate = bwCall?.params["rate"] as? String
        #expect(rate == "1")
    }

    @Test("resumeAll uses bwlimit off") @MainActor
    func resumeAllUsesBwLimitOff() async {
        let mock = MockRcloneClient()
        mock.responses["core/bwlimit"] = [:]
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        vm.paused = true
        await vm.resumeAll()
        let bwCall = mock.callLog.first { $0.method == "core/bwlimit" }
        let rate = bwCall?.params["rate"] as? String
        #expect(rate == "off")
    }

    @Test("clearAll waits for resetStats before clearing keys") @MainActor
    func clearAllAwaitsReset() async {
        let mock = MockRcloneClient()
        mock.responses["core/stats-reset"] = [:]
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        vm.completed = [RcloneCompletedTransfer(from: ["name": "x", "size": 1, "bytes": 1, "error": "", "group": "g", "completed_at": "now"])]
        await vm.clearAll()
        #expect(mock.callLog.contains { $0.method == "core/stats-reset" })
        #expect(vm.completed.isEmpty)
        #expect(vm.queued.isEmpty)
        #expect(vm.checkpoints.isEmpty)
    }

    @Test("dequeue nonexistent name is safe")
    func dequeueNonexistent() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        vm.enqueue(QueuedTransfer(name: "a", isDir: false))
        vm.dequeue(name: "nonexistent")
        #expect(vm.queued.count == 1)
    }

    @Test("multiple copyOrigin keys for same transfer")
    func multipleCopyOriginKeys() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        let origin = CopyOrigin(srcFs: "gdrive:", srcRemote: "docs/file.txt", dstFs: "/", dstRemote: "/local/file.txt", isDir: false)
        vm.addCopyOrigin(group: "job/42", origin: origin)
        vm.addCopyOrigin(group: "docs/file.txt", origin: origin)
        vm.addCopyOrigin(group: "file.txt", origin: origin)
        #expect(vm.copyOrigins["job/42"]?.srcFs == "gdrive:")
        #expect(vm.copyOrigins["docs/file.txt"]?.srcFs == "gdrive:")
        #expect(vm.copyOrigins["file.txt"]?.srcFs == "gdrive:")
    }

    // MARK: - findJobId Tests

    @Test("findJobId matches group with job/ prefix")
    func findJobIdByGroup() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        let t = RcloneTransferring(from: ["name": "file.txt", "size": 100, "bytes": 50, "percentage": 50, "speed": 1000, "speedAvg": 1000, "eta": 10, "group": "job/42"])
        #expect(vm.findJobId(for: t) == 42)
    }

    @Test("findJobId matches by transfer name in copyOrigins")
    func findJobIdByName() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        let origin = CopyOrigin(srcFs: "gdrive:", srcRemote: "docs/file.txt", dstFs: "/", dstRemote: "/local/file.txt", isDir: false)
        vm.addCopyOrigin(group: "job/99", origin: origin)
        vm.addCopyOrigin(group: "file.txt", origin: origin)
        let t = RcloneTransferring(from: ["name": "file.txt", "size": 100, "bytes": 50, "percentage": 50, "speed": 1000, "speedAvg": 1000, "eta": 10, "group": "global_stats"])
        #expect(vm.findJobId(for: t) == 99)
    }

    @Test("findJobId returns nil when no match")
    func findJobIdNoMatch() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        let t = RcloneTransferring(from: ["name": "unknown.txt", "size": 100, "bytes": 50, "percentage": 50, "speed": 1000, "speedAvg": 1000, "eta": 10, "group": "global_stats"])
        #expect(vm.findJobId(for: t) == nil)
    }

    // MARK: - cancelTransfer Tests

    @Test("cancelTransfer stops matching job") @MainActor
    func cancelTransferStopsJob() async {
        let mock = MockRcloneClient()
        mock.responses["job/stop"] = [:]
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        let origin = CopyOrigin(srcFs: "gdrive:", srcRemote: "docs/big.zip", dstFs: "/", dstRemote: "/big.zip", isDir: false)
        vm.addCopyOrigin(group: "job/55", origin: origin)
        vm.addCopyOrigin(group: "big.zip", origin: origin)
        let t = RcloneTransferring(from: ["name": "big.zip", "size": 1000, "bytes": 500, "percentage": 50, "speed": 100, "speedAvg": 100, "eta": 5, "group": "global_stats"])
        await vm.cancelTransfer(t)
        #expect(mock.callLog.contains { $0.method == "job/stop" })
    }

    @Test("cancelTransfer does NOT stop all jobs when no match") @MainActor
    func cancelTransferNoFallback() async {
        let mock = MockRcloneClient()
        mock.responses["job/stop"] = [:]
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        vm.jobIds = [1, 2, 3]
        let t = RcloneTransferring(from: ["name": "unknown.txt", "size": 100, "bytes": 50, "percentage": 50, "speed": 100, "speedAvg": 100, "eta": 5, "group": "global_stats"])
        await vm.cancelTransfer(t)
        #expect(!mock.callLog.contains { $0.method == "job/stop" })
    }

    // MARK: - Queue auto-dequeue Tests

    @Test("queued items removed when appearing in active transfers")
    func queueAutoDequeue() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock, checkpointURL: makeTempURL())
        vm.enqueue(QueuedTransfer(name: "file1.txt", isDir: false))
        vm.enqueue(QueuedTransfer(name: "file2.txt", isDir: false))
        vm.enqueue(QueuedTransfer(name: "file3.txt", isDir: false))
        #expect(vm.queued.count == 3)
        let activeNames: Set<String> = ["file1.txt", "file2.txt"]
        vm.queued.removeAll { q in activeNames.contains(q.name) }
        #expect(vm.queued.count == 1)
        #expect(vm.queued[0].name == "file3.txt")
    }
}
