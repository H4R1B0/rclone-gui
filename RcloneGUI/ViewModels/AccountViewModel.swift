import Foundation
import RcloneKit

@Observable
final class AccountViewModel {
    var remotes: [Remote] = []
    var providers: [RcloneProvider] = []
    var isLoading: Bool = false
    var error: String?
    private(set) var remoteOrder: [String] = []

    private let client: RcloneClientProtocol

    /// remotes sorted by user-defined order
    var orderedRemotes: [Remote] {
        let orderMap = Dictionary(uniqueKeysWithValues: remoteOrder.enumerated().map { ($1, $0) })
        return remotes.sorted { a, b in
            let ia = orderMap[a.name] ?? Int.max
            let ib = orderMap[b.name] ?? Int.max
            if ia == ib { return a.name < b.name }
            return ia < ib
        }
    }

    init(client: RcloneClientProtocol) {
        self.client = client
        loadRemoteOrder()
    }

    // MARK: - Remote Order Persistence

    private var remoteOrderURL: URL {
        AppConstants.appSupportDir.appendingPathComponent(AppConstants.remoteOrderFile)
    }

    private func loadRemoteOrder() {
        guard let data = try? Data(contentsOf: remoteOrderURL),
              let order = try? JSONDecoder().decode([String].self, from: data) else { return }
        remoteOrder = order
    }

    private func saveRemoteOrder() {
        guard let data = try? JSONEncoder().encode(remoteOrder) else { return }
        try? data.write(to: remoteOrderURL)
    }

    /// Sync order list with current remotes (remove stale, append new)
    private func syncRemoteOrder() {
        let names = Set(remotes.map(\.name))
        remoteOrder = remoteOrder.filter { names.contains($0) }
        for remote in remotes where !remoteOrder.contains(remote.name) {
            remoteOrder.append(remote.name)
        }
        saveRemoteOrder()
    }

    func moveRemote(fromName: String, toName: String) {
        guard let fromIdx = remoteOrder.firstIndex(of: fromName),
              let toIdx = remoteOrder.firstIndex(of: toName),
              fromIdx != toIdx else { return }
        remoteOrder.move(fromOffsets: IndexSet(integer: fromIdx),
                         toOffset: toIdx > fromIdx ? toIdx + 1 : toIdx)
        saveRemoteOrder()
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
            syncRemoteOrder()
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
