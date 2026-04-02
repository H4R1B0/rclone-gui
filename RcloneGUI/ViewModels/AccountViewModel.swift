import Foundation
import RcloneKit

@Observable
final class AccountViewModel {
    var remotes: [Remote] = []
    var providers: [RcloneProvider] = []
    var isLoading: Bool = false
    var error: String?

    private let client: RcloneClientProtocol

    init(client: RcloneClientProtocol) {
        self.client = client
    }

    // MARK: - Remote Management

    @MainActor
    func loadRemotes() async {
        isLoading = true
        error = nil
        do {
            let names = try await RcloneAPI.listRemotes(using: client)
            var loaded: [Remote] = []
            for name in names {
                let type = try await RcloneAPI.getRemoteType(using: client, name: name)
                loaded.append(Remote(name: name, type: type))
            }
            remotes = loaded
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func createRemote(name: String, type: String, parameters: [String: String]) async throws {
        try await RcloneAPI.createRemote(using: client, name: name, type: type, parameters: parameters)
        await loadRemotes()
    }

    /// Update remote: delete old, create new (TypeScript pattern: allows name change)
    @MainActor
    func updateRemote(oldName: String, newName: String, type: String, parameters: [String: String]) async throws {
        try await RcloneAPI.deleteRemote(using: client, name: oldName)
        try await RcloneAPI.createRemote(using: client, name: newName, type: type, parameters: parameters)
        await loadRemotes()
    }

    @MainActor
    func deleteRemote(name: String) async throws {
        try await RcloneAPI.deleteRemote(using: client, name: name)
        await loadRemotes()
    }

    // MARK: - Provider Management

    @MainActor
    func loadProviders() async {
        do {
            providers = try await RcloneAPI.getProviders(using: client)
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Get current config values for a remote (for editing)
    func getRemoteConfig(name: String) async throws -> [String: String] {
        let dict = try await RcloneAPI.getRemoteConfig(using: client, name: name)
        // Convert all values to strings for form display
        var config: [String: String] = [:]
        for (key, value) in dict {
            config[key] = "\(value)"
        }
        return config
    }
}
