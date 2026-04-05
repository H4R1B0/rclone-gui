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
}
