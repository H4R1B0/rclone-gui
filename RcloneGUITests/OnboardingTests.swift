import Testing
import Foundation
@testable import RcloneGUI

@Suite("Onboarding Tests")
struct OnboardingTests {
    private static let testKey = "onboardingComplete"

    private func makeTestDefaults() -> UserDefaults {
        let suiteName = "com.test.RcloneGUI.\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName)!
    }

    @Test("onboardingComplete defaults to false")
    func defaultFalse() {
        let defaults = makeTestDefaults()
        #expect(defaults.bool(forKey: Self.testKey) == false)
    }

    @Test("onboardingComplete saved to UserDefaults")
    func savedToDefaults() {
        let defaults = makeTestDefaults()
        defaults.set(true, forKey: Self.testKey)
        #expect(defaults.bool(forKey: Self.testKey) == true)
    }

    @Test("onboardingComplete toggle")
    func toggle() {
        let defaults = makeTestDefaults()
        defaults.set(false, forKey: Self.testKey)
        #expect(defaults.bool(forKey: Self.testKey) == false)
        defaults.set(true, forKey: Self.testKey)
        #expect(defaults.bool(forKey: Self.testKey) == true)
    }
}
