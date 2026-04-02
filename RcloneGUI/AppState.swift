import Foundation
import RcloneKit

enum ActiveView {
    case explore
    case account
    case search
}

@Observable
final class AppState {
    let client: RcloneClient
    let panels: PanelViewModel
    let transfers: TransferViewModel
    let accounts: AccountViewModel
    let clipboard: ClipboardState

    var activeView: ActiveView = .explore
    var showSettings: Bool = false
    var showTransfers: Bool = true
    var transferHeight: Double = 200  // min 80, max 600
    var ready: Bool = false

    init() {
        let client = RcloneClient()
        self.client = client
        self.panels = PanelViewModel(client: client)
        self.transfers = TransferViewModel(client: client)
        self.accounts = AccountViewModel(client: client)
        self.clipboard = ClipboardState()
    }

    @MainActor
    func startup() async {
        // 1. Initialize librclone
        client.initialize()

        // 2. Load remotes
        await panels.loadRemotes()
        await accounts.loadRemotes()
        await accounts.loadProviders()

        // 3. Set initial path to home directory for both panels
        let homePath = NSHomeDirectory()
        await panels.loadFiles(side: .left, remote: "/", path: homePath)
        await panels.loadFiles(side: .right, remote: "/", path: homePath)

        // 4. Start transfer polling
        transfers.startPolling()

        ready = true
    }

    func shutdown() {
        transfers.stopPolling()
        client.finalize()
    }
}
