import Foundation
import RcloneKit

enum ActiveView {
    case explore
    case account
    case search
    case sync
    case scheduler
    case mount
    case trash
}

@Observable @MainActor
final class AppState {
    let client: RcloneClient
    let panels: PanelViewModel
    let transfers: TransferViewModel
    let accounts: AccountViewModel
    let clipboard: ClipboardState
    let search: SearchViewModel
    let settings: SettingsViewModel
    let appLock: AppLockViewModel
    let sync: SyncViewModel
    let scheduler: SchedulerViewModel
    let bookmarks: BookmarkViewModel
    let mount: MountViewModel
    let trash: TrashViewModel

    var activeView: ActiveView = .explore
    var showSettings: Bool = false
    var showTransfers: Bool = false
    var showAccountSetup: Bool = false
    var transferHeight: Double = 200
    var ready: Bool = false
    var onboardingComplete: Bool = false

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
        self.sync = SyncViewModel(client: client)
        self.scheduler = SchedulerViewModel()
        self.bookmarks = BookmarkViewModel()
        self.mount = MountViewModel(client: client)
        self.trash = TrashViewModel(client: client)
    }

    @MainActor
    func startup() async {
        L10n.locale = settings.locale
        appLock.checkLockStatus()
        client.initialize()
        panels.setTransferVM(transfers)
        panels.setTrashVM(trash)

        await panels.loadRemotes()
        await accounts.loadRemotes()
        await accounts.loadProviders()

        // 검색 클라우드 필터 초기화
        search.initializeClouds(remotes: panels.remotes)

        // 저장된 rclone 옵션 적용
        panels.maxConcurrentTransfers = settings.transfers
        panels.multiThreadStreams = settings.multiThreadStreams
        await settings.applyToRclone()

        let homePath = NSHomeDirectory()
        await panels.loadFiles(side: .left, remote: "/", path: homePath)

        FinderService.shared.registerServices()

        // Auto-refresh destination panel when transfer completes
        let p = panels
        transfers.onTransferComplete = { dstFs in
            Task { @MainActor in
                // Refresh any tab matching the destination remote
                for tab in p.left.tabs + p.right.tabs {
                    if tab.remote == dstFs {
                        let side: PanelSide = p.left.tabs.contains(where: { $0.id == tab.id }) ? .left : .right
                        await p.loadFiles(side: side)
                        break
                    }
                }
            }
        }
        transfers.startPolling()
        scheduler.startMonitoring()
        settings.startBwScheduler()
        ready = true
        onboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")
    }

    func shutdown() {
        transfers.stopPolling()
        scheduler.stopMonitoring()
        settings.stopBwScheduler()
        client.finalize()
    }
}
