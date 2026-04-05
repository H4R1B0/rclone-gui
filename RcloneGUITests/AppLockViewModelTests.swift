import Testing
import Foundation
@testable import RcloneGUI

@Suite("AppLockViewModel Tests")
struct AppLockViewModelTests {
    private func makeTempURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("lock_test_\(UUID().uuidString).json")
    }

    @Test("initial isLocked is nil")
    func initialIsLockedNil() {
        let vm = AppLockViewModel(configURL: makeTempURL())
        #expect(vm.isLocked == nil)
    }

    @Test("initial isEnabled is false")
    func initialIsEnabledFalse() {
        let vm = AppLockViewModel(configURL: makeTempURL())
        #expect(vm.isEnabled == false)
    }

    @Test("unlock sets isLocked false and clears error")
    func unlock() {
        let vm = AppLockViewModel(configURL: makeTempURL())
        vm.isLocked = true
        vm.errorMessage = "wrong password"
        vm.unlock()
        #expect(vm.isLocked == false)
        #expect(vm.errorMessage == nil)
    }

    @Test("checkLockStatus when not enabled sets false")
    func checkLockStatusNotEnabled() {
        let vm = AppLockViewModel(configURL: makeTempURL())
        vm.isEnabled = false
        vm.checkLockStatus()
        #expect(vm.isLocked == false)
    }

    @Test("initial errorMessage is nil")
    func initialErrorNil() {
        let vm = AppLockViewModel(configURL: makeTempURL())
        #expect(vm.errorMessage == nil)
    }
}
