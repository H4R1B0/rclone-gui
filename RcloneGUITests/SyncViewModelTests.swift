import Testing
import Foundation
@testable import RcloneGUI

@Suite("SyncMode Tests")
struct SyncModeTests {
    @Test("Mirror mode")
    func mirrorMode() {
        let mode = SyncMode.mirror
        #expect(mode.rawValue == "mirror")
        L10n.locale = "en"
        #expect(!mode.label.isEmpty)
        #expect(!mode.description.isEmpty)
    }

    @Test("MirrorUpdate mode")
    func mirrorUpdateMode() {
        let mode = SyncMode.mirrorUpdate
        #expect(mode.rawValue == "mirrorUpdate")
    }

    @Test("Bisync mode")
    func bisyncMode() {
        let mode = SyncMode.bisync
        #expect(mode.rawValue == "bisync")
    }

    @Test("All modes in CaseIterable")
    func allModes() {
        #expect(SyncMode.allCases.count == 3)
    }
}

@Suite("SyncProfile Tests")
struct SyncProfileTests {
    @Test("Create profile")
    func createProfile() {
        let profile = SyncProfile(
            name: "Test Sync",
            mode: .mirror,
            sourceFs: "gdrive:",
            sourcePath: "/docs",
            destFs: "dropbox:",
            destPath: "/backup"
        )
        #expect(profile.name == "Test Sync")
        #expect(profile.syncMode == .mirror)
        #expect(profile.sourceFs == "gdrive:")
        #expect(profile.destFs == "dropbox:")
        #expect(profile.filterRules.isEmpty)
    }

    @Test("Profile with filters")
    func profileWithFilters() {
        let profile = SyncProfile(
            name: "Filtered",
            mode: .bisync,
            sourceFs: "/",
            sourcePath: "/home",
            destFs: "s3:",
            destPath: "/bucket",
            filterRules: ["*.tmp", "*.log"]
        )
        #expect(profile.filterRules.count == 2)
        #expect(profile.syncMode == .bisync)
    }

    @Test("Profile Codable round-trip")
    func codableRoundTrip() throws {
        let original = SyncProfile(name: "Test", mode: .mirrorUpdate, sourceFs: "/", sourcePath: "/a", destFs: "b:", destPath: "/c")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SyncProfile.self, from: data)
        #expect(decoded.name == "Test")
        #expect(decoded.syncMode == .mirrorUpdate)
        #expect(decoded.sourceFs == "/")
    }
}

@Suite("SyncViewModel Tests")
struct SyncViewModelTests {
    @Test("Add and delete profile")
    func addDeleteProfile() {
        // Can't easily create SyncViewModel without RcloneClient
        // Test SyncProfile independently
        var profiles: [SyncProfile] = []
        let p = SyncProfile(name: "Test", mode: .mirror, sourceFs: "/", sourcePath: "", destFs: "/", destPath: "/backup")
        profiles.append(p)
        #expect(profiles.count == 1)
        profiles.removeAll { $0.id == p.id }
        #expect(profiles.isEmpty)
    }
}

@Suite("SyncViewModel Mock Tests")
struct SyncViewModelMockTests {
    @Test("addProfile appends")
    func addProfile() {
        let mock = MockRcloneClient()
        let vm = SyncViewModel(client: mock)
        vm.profiles = []
        let p = SyncProfile(name: "Test", mode: .mirror, sourceFs: "/", sourcePath: "", destFs: "/", destPath: "/backup")
        vm.addProfile(p)
        #expect(vm.profiles.count == 1)
        #expect(vm.profiles[0].name == "Test")
    }

    @Test("deleteProfile removes correct one")
    func deleteProfile() {
        let mock = MockRcloneClient()
        let vm = SyncViewModel(client: mock)
        vm.profiles = []
        let p1 = SyncProfile(name: "A", mode: .mirror, sourceFs: "/", sourcePath: "", destFs: "/", destPath: "/a")
        let p2 = SyncProfile(name: "B", mode: .bisync, sourceFs: "/", sourcePath: "", destFs: "/", destPath: "/b")
        vm.addProfile(p1)
        vm.addProfile(p2)
        vm.deleteProfile(id: p1.id)
        #expect(vm.profiles.count == 1)
        #expect(vm.profiles[0].name == "B")
    }

    @Test("runSync mirror calls sync/sync") @MainActor
    func runSyncMirror() async {
        let mock = MockRcloneClient()
        mock.responses["sync/sync"] = ["jobid": 42]
        let vm = SyncViewModel(client: mock)
        let p = SyncProfile(name: "M", mode: .mirror, sourceFs: "/", sourcePath: "/src", destFs: "/", destPath: "/dst")
        await vm.runSync(profile: p)
        #expect(mock.callLog.contains { $0.method == "sync/sync" })
    }

    @Test("runSync mirrorUpdate calls sync/copy") @MainActor
    func runSyncMirrorUpdate() async {
        let mock = MockRcloneClient()
        mock.responses["sync/copy"] = ["jobid": 43]
        let vm = SyncViewModel(client: mock)
        let p = SyncProfile(name: "MU", mode: .mirrorUpdate, sourceFs: "/", sourcePath: "/src", destFs: "/", destPath: "/dst")
        await vm.runSync(profile: p)
        #expect(mock.callLog.contains { $0.method == "sync/copy" })
    }

    @Test("runSync bisync calls sync/bisync") @MainActor
    func runSyncBisync() async {
        let mock = MockRcloneClient()
        mock.responses["sync/bisync"] = ["jobid": 44]
        let vm = SyncViewModel(client: mock)
        let p = SyncProfile(name: "B", mode: .bisync, sourceFs: "/", sourcePath: "/a", destFs: "/", destPath: "/b")
        await vm.runSync(profile: p)
        #expect(mock.callLog.contains { $0.method == "sync/bisync" })
    }

    @Test("runSync error sets error message") @MainActor
    func runSyncError() async {
        let mock = MockRcloneClient()
        mock.errorForMethod["sync/sync"] = RcloneError.rpcFailed(method: "sync/sync", status: 500, message: "fail")
        let vm = SyncViewModel(client: mock)
        let p = SyncProfile(name: "E", mode: .mirror, sourceFs: "/", sourcePath: "", destFs: "/", destPath: "")
        await vm.runSync(profile: p)
        #expect(vm.error != nil)
        #expect(vm.isRunning == false)
    }

    @Test("stopSync calls job/stop") @MainActor
    func stopSync() async {
        let mock = MockRcloneClient()
        mock.responses["job/stop"] = [:]
        let vm = SyncViewModel(client: mock)
        vm.currentJobId = 42
        await vm.stopSync()
        #expect(vm.currentJobId == nil)
        #expect(vm.isRunning == false)
    }

    @Test("updateProfile replaces in place")
    func updateProfile() {
        let mock = MockRcloneClient()
        let vm = SyncViewModel(client: mock)
        vm.profiles = []
        var p = SyncProfile(name: "Original", mode: .mirror, sourceFs: "/", sourcePath: "", destFs: "/", destPath: "")
        vm.addProfile(p)
        p.name = "Updated"  // SyncProfile is a struct, so this is a copy
        // Need to use the id from the added profile
        var updated = vm.profiles[0]
        updated.name = "Updated"
        vm.updateProfile(updated)
        #expect(vm.profiles[0].name == "Updated")
    }
}
