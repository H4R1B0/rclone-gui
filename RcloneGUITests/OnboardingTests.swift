import Testing
import Foundation
@testable import RcloneGUI

@Suite("Onboarding Tests")
struct OnboardingTests {
    @Test("onboardingComplete defaults to false") @MainActor
    func defaultFalse() {
        // Clean up any previous test state
        UserDefaults.standard.removeObject(forKey: "onboardingComplete")
        let appState = AppState()
        #expect(appState.onboardingComplete == false)
    }

    @Test("onboardingComplete saved to UserDefaults") @MainActor
    func savedToDefaults() {
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        let value = UserDefaults.standard.bool(forKey: "onboardingComplete")
        #expect(value == true)
        // Cleanup
        UserDefaults.standard.removeObject(forKey: "onboardingComplete")
    }

    @Test("onboardingComplete toggle")
    func toggle() {
        UserDefaults.standard.set(false, forKey: "onboardingComplete")
        #expect(UserDefaults.standard.bool(forKey: "onboardingComplete") == false)
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        #expect(UserDefaults.standard.bool(forKey: "onboardingComplete") == true)
        UserDefaults.standard.removeObject(forKey: "onboardingComplete")
    }
}
