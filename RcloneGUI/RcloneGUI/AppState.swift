import Foundation
import RcloneKit
import FileBrowser
import TransferEngine

@Observable
public final class AppState {
    let rcloneClient: RcloneClient
    let leftPanel: PanelViewModel
    let rightPanel: PanelViewModel
    let transfers: TransferViewModel
    let accounts: AccountViewModel

    init() {
        let client = RcloneClient()
        self.rcloneClient = client
        self.leftPanel = PanelViewModel(client: client)
        self.rightPanel = PanelViewModel(client: client)
        self.transfers = TransferViewModel(client: client)
        self.accounts = AccountViewModel(client: client)
    }

    func startup() {
        rcloneClient.initialize()
        Task {
            await accounts.loadRemotes()
            await leftPanel.navigate(to: "")
            await rightPanel.navigate(to: "")
        }
        transfers.startPolling()
    }

    func shutdown() {
        transfers.stopPolling()
        rcloneClient.finalize()
    }
}
