import Testing
import Foundation
@testable import RcloneGUI
import RcloneKit

@Suite("AccountViewModel Tests")
struct AccountViewModelTests {
    let mock = MockRcloneClient()

    private func makeTempURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("acct_test_\(UUID().uuidString).json")
    }

    @Test("loadRemotes success") @MainActor
    func loadRemotesSuccess() async {
        mock.responses["config/listremotes"] = ["remotes": ["gdrive", "s3"]]
        mock.responses["config/get"] = ["type": "drive"]
        let vm = AccountViewModel(client: mock, remoteOrderURL: makeTempURL())
        await vm.loadRemotes()
        #expect(vm.remotes.count == 2)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("loadRemotes empty") @MainActor
    func loadRemotesEmpty() async {
        mock.responses["config/listremotes"] = ["remotes": [String]()]
        let vm = AccountViewModel(client: mock, remoteOrderURL: makeTempURL())
        await vm.loadRemotes()
        #expect(vm.remotes.isEmpty)
    }

    @Test("loadRemotes error") @MainActor
    func loadRemotesError() async {
        mock.errorForMethod["config/listremotes"] = RcloneError.rpcFailed(method: "config/listremotes", status: 500, message: "fail")
        let vm = AccountViewModel(client: mock, remoteOrderURL: makeTempURL())
        await vm.loadRemotes()
        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
        mock.errorForMethod.removeAll()
    }

    @Test("createRemote calls config/create") @MainActor
    func createRemote() async throws {
        mock.responses["config/create"] = [:]
        mock.responses["config/listremotes"] = ["remotes": ["new"]]
        mock.responses["config/get"] = ["type": "drive"]
        let vm = AccountViewModel(client: mock, remoteOrderURL: makeTempURL())
        try await vm.createRemote(name: "new", type: "drive", parameters: [:])
        #expect(mock.callLog.contains { $0.method == "config/create" })
    }

    @Test("deleteRemote calls config/delete") @MainActor
    func deleteRemote() async throws {
        mock.responses["config/delete"] = [:]
        mock.responses["config/listremotes"] = ["remotes": [String]()]
        let vm = AccountViewModel(client: mock, remoteOrderURL: makeTempURL())
        try await vm.deleteRemote(name: "old")
        #expect(mock.callLog.contains { $0.method == "config/delete" })
    }

    @Test("updateRemote calls delete then create") @MainActor
    func updateRemote() async throws {
        mock.responses["config/delete"] = [:]
        mock.responses["config/create"] = [:]
        mock.responses["config/listremotes"] = ["remotes": ["renamed"]]
        mock.responses["config/get"] = ["type": "s3"]
        let vm = AccountViewModel(client: mock, remoteOrderURL: makeTempURL())
        try await vm.updateRemote(oldName: "old", newName: "renamed", type: "s3", parameters: [:])
        let methods = mock.callLog.map(\.method)
        #expect(methods.contains("config/delete"))
        #expect(methods.contains("config/create"))
    }

    @Test("loadProviders") @MainActor
    func loadProviders() async {
        mock.responses["config/providers"] = ["providers": [
            ["Name": "Google Drive", "Description": "Google cloud storage", "Prefix": "drive", "Options": []]
        ]]
        let vm = AccountViewModel(client: mock, remoteOrderURL: makeTempURL())
        await vm.loadProviders()
        #expect(vm.providers.count == 1)
        #expect(vm.providers[0].name == "Google Drive")
    }

    @Test("getRemoteConfig returns string dict") @MainActor
    func getRemoteConfig() async throws {
        mock.responses["config/get"] = ["type": "drive", "client_id": "abc123"]
        let vm = AccountViewModel(client: mock, remoteOrderURL: makeTempURL())
        let config = try await vm.getRemoteConfig(name: "gdrive")
        #expect(config["type"] == "drive")
        #expect(config["client_id"] == "abc123")
    }

    @Test("displayName falls back to name without alias") @MainActor
    func displayNameFallback() {
        let store = RemoteAliasStore(defaults: UserDefaults(suiteName: "acct-dn-\(UUID().uuidString)")!, key: "a")
        let vm = AccountViewModel(client: mock, remoteOrderURL: makeTempURL(), aliasStore: store)
        #expect(vm.displayName(for: "gdrive") == "gdrive")
    }

    @Test("setAlias + displayName returns alias") @MainActor
    func setAliasReturns() {
        let store = RemoteAliasStore(defaults: UserDefaults(suiteName: "acct-sa-\(UUID().uuidString)")!, key: "a")
        let vm = AccountViewModel(client: mock, remoteOrderURL: makeTempURL(), aliasStore: store)
        vm.setAlias(for: "gdrive", to: "Work Drive")
        #expect(vm.displayName(for: "gdrive") == "Work Drive")
    }

    @Test("setAlias with nil removes") @MainActor
    func setAliasNilRemoves() {
        let store = RemoteAliasStore(defaults: UserDefaults(suiteName: "acct-sanil-\(UUID().uuidString)")!, key: "a")
        let vm = AccountViewModel(client: mock, remoteOrderURL: makeTempURL(), aliasStore: store)
        vm.setAlias(for: "gdrive", to: "Work Drive")
        vm.setAlias(for: "gdrive", to: nil)
        #expect(vm.displayName(for: "gdrive") == "gdrive")
    }
}

@Suite("RemoteAliasStore")
struct RemoteAliasStoreTests {
    private func makeStore() -> RemoteAliasStore {
        let d = UserDefaults(suiteName: "ras-\(UUID().uuidString)")!
        return RemoteAliasStore(defaults: d, key: "k")
    }

    @Test("set + alias returns value")
    func setGet() {
        let store = makeStore()
        store.setAlias(name: "a", alias: "Alpha")
        #expect(store.alias(for: "a") == "Alpha")
    }

    @Test("whitespace alias treated as empty")
    func whitespace() {
        let store = makeStore()
        store.setAlias(name: "a", alias: "   ")
        #expect(store.alias(for: "a") == nil)
    }

    @Test("nil alias removes")
    func nilRemoves() {
        let store = makeStore()
        store.setAlias(name: "a", alias: "X")
        store.setAlias(name: "a", alias: nil)
        #expect(store.alias(for: "a") == nil)
    }

    @Test("persists across instances")
    func persistAcross() {
        let suite = "ras-persist-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: suite)!
        let s1 = RemoteAliasStore(defaults: d, key: "k")
        s1.setAlias(name: "a", alias: "A")
        let s2 = RemoteAliasStore(defaults: d, key: "k")
        #expect(s2.alias(for: "a") == "A")
    }
}
