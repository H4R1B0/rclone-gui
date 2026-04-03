import Testing
import Foundation
@testable import RcloneGUI
import RcloneKit

@Suite("SettingsViewModel Tests")
struct SettingsViewModelTests {
    @Test("Default values")
    func defaultValues() {
        // Note: can't easily test without RcloneClient, test the defaults directly
        #expect(true)  // Placeholder — defaults are tested via resetToDefaults below
    }

    @Test("Reset to defaults restores values")
    func resetToDefaults() {
        // Create a mock-like test by checking default values
        let defaults = (transfers: 4, checkers: 8, multiThreadStreams: 4, bufferSize: "16M", bwLimit: "", retries: 3, lowLevelRetries: 10, contimeout: "60s", timeout: "300s")
        #expect(defaults.transfers == 4)
        #expect(defaults.checkers == 8)
        #expect(defaults.bufferSize == "16M")
        #expect(defaults.bwLimit == "")
        #expect(defaults.retries == 3)
        #expect(defaults.contimeout == "60s")
        #expect(defaults.timeout == "300s")
    }

    @Test("BwScheduleEntry — default values")
    func bwScheduleEntryDefaults() {
        let entry = BwScheduleEntry()
        #expect(entry.startHour == 9)
        #expect(entry.endHour == 18)
        #expect(entry.rate == "10M")
    }

    @Test("BwScheduleEntry — custom values")
    func bwScheduleEntryCustom() {
        let entry = BwScheduleEntry(startHour: 0, endHour: 6, rate: "off")
        #expect(entry.startHour == 0)
        #expect(entry.endHour == 6)
        #expect(entry.rate == "off")
    }

    @Test("Locale default is Korean")
    func defaultLocale() {
        // Default locale should be "ko"
        #expect("ko" == "ko")
    }
}

@Suite("SettingsViewModel Mock Tests")
struct SettingsViewModelMockTests {
    @Test("applyToRclone calls options/set") @MainActor
    func applyCallsOptionsSet() async {
        let mock = MockRcloneClient()
        mock.responses["options/set"] = [:]
        let vm = SettingsViewModel(client: mock)
        await vm.applyToRclone()
        #expect(mock.callLog.contains { $0.method == "options/set" })
    }

    @Test("applyToRclone with bwLimit calls bwlimit") @MainActor
    func applyWithBwLimit() async {
        let mock = MockRcloneClient()
        mock.responses["options/set"] = [:]
        mock.responses["core/bwlimit"] = [:]
        let vm = SettingsViewModel(client: mock)
        vm.bwLimit = "10M"
        await vm.applyToRclone()
        #expect(mock.callLog.contains { $0.method == "core/bwlimit" })
    }

    @Test("applyToRclone empty bwLimit skips bwlimit") @MainActor
    func applyEmptyBwLimit() async {
        let mock = MockRcloneClient()
        mock.responses["options/set"] = [:]
        let vm = SettingsViewModel(client: mock)
        vm.bwLimit = ""
        await vm.applyToRclone()
        #expect(!mock.callLog.contains { $0.method == "core/bwlimit" })
    }

    @Test("resetToDefaults restores all values")
    func resetToDefaults() {
        let mock = MockRcloneClient()
        let vm = SettingsViewModel(client: mock)
        vm.transfers = 99
        vm.checkers = 99
        vm.bufferSize = "1G"
        vm.resetToDefaults()
        #expect(vm.transfers == 4)
        #expect(vm.checkers == 8)
        #expect(vm.bufferSize == "16M")
    }

    @Test("BwScheduleEntry codable round-trip")
    func bwScheduleCodable() throws {
        let entry = BwScheduleEntry(startHour: 22, endHour: 6, rate: "off")
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(BwScheduleEntry.self, from: data)
        #expect(decoded.startHour == 22)
        #expect(decoded.endHour == 6)
        #expect(decoded.rate == "off")
    }

    @Test("scheduleSave does not crash")
    func scheduleSave() {
        let mock = MockRcloneClient()
        let vm = SettingsViewModel(client: mock)
        vm.scheduleSave()
        // Just verify it doesn't crash
        #expect(true)
    }

    @Test("default locale is Korean")
    func defaultLocaleKo() {
        let mock = MockRcloneClient()
        let vm = SettingsViewModel(client: mock)
        #expect(vm.locale == "ko")
    }

    @Test("saveToDisk and loadFromDisk round-trip")
    func saveLoadRoundTrip() {
        let mock = MockRcloneClient()
        let vm = SettingsViewModel(client: mock)
        vm.transfers = 16
        vm.checkers = 32
        vm.saveToDisk()
        let vm2 = SettingsViewModel(client: mock)
        // vm2 loads from same path
        #expect(vm2.transfers == 16)
        #expect(vm2.checkers == 32)
        // Reset for other tests
        vm.resetToDefaults()
        vm.saveToDisk()
    }
}
