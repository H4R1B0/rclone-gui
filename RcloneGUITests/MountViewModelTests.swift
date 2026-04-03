import Testing
@testable import RcloneGUI
import RcloneKit

@Suite("MountViewModel Tests")
struct MountViewModelTests {
    let mock = MockRcloneClient()

    @Test("loadMounts success") @MainActor
    func loadMountsSuccess() async {
        mock.responses["mount/listmounts"] = ["mountPoints": [
            ["Fs": "gdrive:", "MountPoint": "/mnt/gdrive"]
        ]]
        let vm = MountViewModel(client: mock)
        await vm.loadMounts()
        #expect(vm.mounts.count == 1)
        #expect(vm.mounts[0].fs == "gdrive:")
        #expect(vm.mounts[0].mountPoint == "/mnt/gdrive")
    }

    @Test("loadMounts empty") @MainActor
    func loadMountsEmpty() async {
        mock.responses["mount/listmounts"] = ["mountPoints": [[String: Any]]()]
        let vm = MountViewModel(client: mock)
        await vm.loadMounts()
        #expect(vm.mounts.isEmpty)
    }

    @Test("loadMounts error") @MainActor
    func loadMountsError() async {
        mock.errorForMethod["mount/listmounts"] = RcloneError.rpcFailed(method: "mount/listmounts", status: 500, message: "fail")
        let vm = MountViewModel(client: mock)
        await vm.loadMounts()
        #expect(vm.error != nil)
        mock.errorForMethod.removeAll()
    }

    @Test("mount calls API and reloads") @MainActor
    func mountCallsAPI() async throws {
        mock.responses["mount/mount"] = [:]
        mock.responses["mount/listmounts"] = ["mountPoints": [[String: Any]]()]
        let vm = MountViewModel(client: mock)
        try await vm.mount(fs: "gdrive:", mountPoint: "/mnt/test")
        #expect(mock.callLog.contains { $0.method == "mount/mount" })
    }

    @Test("unmount calls API and reloads") @MainActor
    func unmountCallsAPI() async throws {
        mock.responses["mount/unmount"] = [:]
        mock.responses["mount/listmounts"] = ["mountPoints": [[String: Any]]()]
        let vm = MountViewModel(client: mock)
        try await vm.unmount(mountPoint: "/mnt/test")
        #expect(mock.callLog.contains { $0.method == "mount/unmount" })
    }
}
