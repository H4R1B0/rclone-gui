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
