import Foundation
import LocalAuthentication
import Security
import CryptoKit

@Observable
final class AppLockViewModel {
    var isLocked: Bool? = nil  // nil=checking, true=locked, false=unlocked
    var isEnabled: Bool = false
    var useTouchID: Bool = false
    var canUseTouchID: Bool = false
    var errorMessage: String?

    private let keychainService = AppConstants.keychainService
    private let keychainAccount = AppConstants.keychainAccount
    private let configURL: URL

    init() {
        configURL = AppConstants.appSupportDir.appendingPathComponent(AppConstants.appLockConfigFile)
        loadConfig()
        checkTouchIDAvailability()
    }

    // MARK: - Keychain

    private func sha256Hash(_ input: String) -> String {
        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    func setPassword(_ password: String) -> Bool {
        removePassword()
        let hashString = sha256Hash(password)
        guard let data = hashString.data(using: .utf8) else { return false }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    func verifyPassword(_ input: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let stored = String(data: data, encoding: .utf8)
        else { return false }
        return stored == sha256Hash(input)
    }

    func removePassword() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }

    func hasPassword() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    // MARK: - Touch ID

    func checkTouchIDAvailability() {
        let context = LAContext()
        var error: NSError?
        canUseTouchID = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    @MainActor
    func promptTouchID() async -> Bool {
        let context = LAContext()
        do {
            let result = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: L10n.t("lock.unlock")
            )
            if result {
                isLocked = false
                errorMessage = nil
            }
            return result
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Config

    func saveConfig() {
        let dict: [String: Any] = [
            "appLockEnabled": isEnabled,
            "useTouchID": useTouchID
        ]
        if let data = try? JSONSerialization.data(withJSONObject: dict) {
            try? data.write(to: configURL)
        }
    }

    func loadConfig() {
        guard let data = try? Data(contentsOf: configURL),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }
        isEnabled = dict["appLockEnabled"] as? Bool ?? false
        useTouchID = dict["useTouchID"] as? Bool ?? false
    }

    // MARK: - Lock Status

    func checkLockStatus() {
        if isEnabled && hasPassword() {
            isLocked = true
        } else {
            isLocked = false
        }
    }

    func unlock() {
        isLocked = false
        errorMessage = nil
    }
}
