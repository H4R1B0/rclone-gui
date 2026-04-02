import Foundation
import RcloneKit

@Observable
public final class AccountViewModel {
    var remotes: [Remote] = []
    var isLoading: Bool = false
    var error: String?

    private let client: RcloneClientProtocol

    init(client: RcloneClientProtocol) {
        self.client = client
    }

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
    func addRemote(name: String, type: String, parameters: [String: String]) async throws {
        try await RcloneAPI.createRemote(using: client, name: name, type: type, parameters: parameters)
        await loadRemotes()
    }

    @MainActor
    func deleteRemote(name: String) async throws {
        try await RcloneAPI.deleteRemote(using: client, name: name)
        await loadRemotes()
    }
}
