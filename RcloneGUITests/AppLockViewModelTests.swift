import Testing
@testable import RcloneGUI

@Suite("AppLockViewModel Tests")
struct AppLockViewModelTests {
    @Test("initial isLocked is nil")
    func initialIsLockedNil() {
        let vm = AppLockViewModel()
        #expect(vm.isLocked == nil)
    }

    @Test("initial isEnabled is false")
    func initialIsEnabledFalse() {
        let vm = AppLockViewModel()
        #expect(vm.isEnabled == false)
    }

    @Test("unlock sets isLocked false and clears error")
    func unlock() {
        let vm = AppLockViewModel()
        vm.isLocked = true
        vm.errorMessage = "wrong password"
        vm.unlock()
        #expect(vm.isLocked == false)
        #expect(vm.errorMessage == nil)
    }

    @Test("checkLockStatus when not enabled sets false")
    func checkLockStatusNotEnabled() {
        let vm = AppLockViewModel()
        vm.isEnabled = false
        vm.checkLockStatus()
        #expect(vm.isLocked == false)
    }

    @Test("initial errorMessage is nil")
    func initialErrorNil() {
        let vm = AppLockViewModel()
        #expect(vm.errorMessage == nil)
    }
}
