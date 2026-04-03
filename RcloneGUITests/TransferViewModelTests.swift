import Testing
@testable import RcloneGUI
import RcloneKit

@Suite("TransferViewModel Tests")
struct TransferViewModelTests {
    @Test("addCopyOrigin stores origin")
    func addCopyOrigin() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock)
        let origin = CopyOrigin(srcFs: "gdrive:", srcRemote: "/file.txt", dstFs: "/", dstRemote: "/local/file.txt", isDir: false)
        vm.addCopyOrigin(group: "test-group", origin: origin)
        #expect(vm.copyOrigins["test-group"] != nil)
        #expect(vm.copyOrigins["test-group"]?.srcFs == "gdrive:")
    }

    @Test("addStopped inserts at front")
    func addStopped() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock)
        let s1 = StoppedTransfer(name: "first", group: "g1", size: 100, srcFs: nil, srcRemote: nil, dstFs: nil, dstRemote: nil, isDir: false)
        let s2 = StoppedTransfer(name: "second", group: "g2", size: 200, srcFs: nil, srcRemote: nil, dstFs: nil, dstRemote: nil, isDir: false)
        vm.addStopped(s1)
        vm.addStopped(s2)
        #expect(vm.stopped[0].name == "second")
        #expect(vm.stopped[1].name == "first")
    }

    @Test("removeStopped removes by ID")
    func removeStopped() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock)
        let s = StoppedTransfer(name: "test", group: "g", size: 50, srcFs: nil, srcRemote: nil, dstFs: nil, dstRemote: nil, isDir: false)
        vm.addStopped(s)
        vm.removeStopped(id: s.id)
        #expect(vm.stopped.isEmpty)
    }

    @Test("clearCompleted removes ok items")
    func clearCompleted() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock)
        let ok = RcloneCompletedTransfer(from: ["name": "good", "size": 100, "bytes": 100, "error": "", "group": "g", "completed_at": "2024-01-01"])
        let fail = RcloneCompletedTransfer(from: ["name": "bad", "size": 50, "bytes": 0, "error": "network", "group": "g", "completed_at": "2024-01-01"])
        vm.completed = [ok, fail]
        vm.clearCompleted()
        #expect(vm.completed.count == 1)
        #expect(vm.completed[0].name == "bad")
    }

    @Test("clearErrors removes failed and lastErrors")
    func clearErrors() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock)
        let fail = RcloneCompletedTransfer(from: ["name": "bad", "size": 50, "bytes": 0, "error": "fail", "group": "g", "completed_at": "2024-01-01"])
        vm.completed = [fail]
        vm.lastErrors = ["error1", "error2"]
        vm.clearErrors()
        #expect(vm.completed.isEmpty)
        #expect(vm.lastErrors.isEmpty)
    }

    @Test("clearAll removes everything")
    func clearAll() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock)
        vm.completed = [RcloneCompletedTransfer(from: ["name": "x", "size": 1, "bytes": 1, "error": "", "group": "g", "completed_at": "now"])]
        vm.stopped = [StoppedTransfer(name: "s", group: "g", size: 1, srcFs: nil, srcRemote: nil, dstFs: nil, dstRemote: nil, isDir: false)]
        vm.lastErrors = ["err"]
        vm.clearAll()
        #expect(vm.completed.isEmpty)
        #expect(vm.stopped.isEmpty)
        #expect(vm.lastErrors.isEmpty)
    }

    @Test("successfulCompleted filters correctly")
    func successfulCompleted() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock)
        vm.completed = [
            RcloneCompletedTransfer(from: ["name": "ok", "size": 100, "bytes": 100, "error": "", "group": "g", "completed_at": "now"]),
            RcloneCompletedTransfer(from: ["name": "fail", "size": 50, "bytes": 0, "error": "err", "group": "g", "completed_at": "now"])
        ]
        #expect(vm.successfulCompleted.count == 1)
        #expect(vm.errorCompleted.count == 1)
    }

    @Test("hasActiveTransfers reflects state")
    func hasActiveTransfers() {
        let mock = MockRcloneClient()
        let vm = TransferViewModel(client: mock)
        #expect(!vm.hasActiveTransfers)
        vm.transfers = [RcloneTransferring(from: ["name": "t", "size": 100, "bytes": 50, "percentage": 50, "speed": 1000, "speedAvg": 1000, "eta": 10, "group": "g"])]
        #expect(vm.hasActiveTransfers)
    }

    @Test("pauseAll sets paused and calls bwlimit") @MainActor
    func pauseAll() async {
        let mock = MockRcloneClient()
        mock.responses["core/bwlimit"] = [:]
        let vm = TransferViewModel(client: mock)
        await vm.pauseAll()
        #expect(vm.paused == true)
        #expect(mock.callLog.contains { $0.method == "core/bwlimit" })
    }

    @Test("resumeAll clears paused and calls bwlimit off") @MainActor
    func resumeAll() async {
        let mock = MockRcloneClient()
        mock.responses["core/bwlimit"] = [:]
        let vm = TransferViewModel(client: mock)
        vm.paused = true
        await vm.resumeAll()
        #expect(vm.paused == false)
    }
}
