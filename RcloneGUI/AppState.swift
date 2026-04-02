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
    let search: SearchViewModel
    let settings: SettingsViewModel
    let appLock: AppLockViewModel

    var activeView: ActiveView = .explore
    var showSettings: Bool = false
    var showTransfers: Bool = true
    var transferHeight: Double = 200
    var ready: Bool = false

    init() {
        let client = RcloneClient()
        self.client = client
        self.panels = PanelViewModel(client: client)
        self.transfers = TransferViewModel(client: client)
        self.accounts = AccountViewModel(client: client)
        self.clipboard = ClipboardState()
        self.search = SearchViewModel(client: client)
        self.settings = SettingsViewModel(client: client)
        self.appLock = AppLockViewModel()
    }

    @MainActor
    func startup() async {
        L10n.locale = settings.locale
        appLock.checkLockStatus()
        client.initialize()

        await panels.loadRemotes()
        await accounts.loadRemotes()
        await accounts.loadProviders()

        // 검색 클라우드 필터 초기화
        search.initializeClouds(remotes: panels.remotes)

        // 저장된 rclone 옵션 적용
        await settings.applyToRclone()

        let homePath = NSHomeDirectory()
        await panels.loadFiles(side: .left, remote: "/", path: homePath)
        await panels.loadFiles(side: .right, remote: "/", path: homePath)

        transfers.startPolling()
        ready = true
    }

    func shutdown() {
        transfers.stopPolling()
        client.finalize()
    }
}
