import SwiftUI

enum SidebarItem: Hashable {
    case explorer
    case search
    case sync
    case scheduler
    case mount
    case trash
    case duplicates
    case remote(String)
    case bookmark(Bookmark)
}

struct FinderUploadData: Identifiable {
    let id = UUID()
    let urls: [URL]
}

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedSidebar: SidebarItem? = .explorer
    @State private var finderUploadURLs: [URL]?

    var body: some View {
        if !appState.ready {
            AppStartupSkeleton()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .task { await appState.startup() }
        } else if !appState.onboardingComplete {
            OnboardingView()
                .environment(appState)
        } else {
            NavigationSplitView {
                SidebarView(selection: $selectedSidebar)
            } detail: {
                VStack(spacing: 0) {
                    Group {
                        switch selectedSidebar {
                        case .explorer, .none:
                            ExplorerView()
                        case .search:
                            SearchPanelView()
                        case .sync:
                            SyncView()
                        case .scheduler:
                            SchedulerView()
                        case .mount:
                            MountView()
                        case .trash:
                            TrashView()
                        case .duplicates:
                            DuplicateFinderView()
                        case .remote(let name):
                            RemoteDetailsView(remoteName: name)
                        case .bookmark(let bookmark):
                            ExplorerView()
                                .task(id: bookmark.id) {
                                    let targetSide = appState.panels.activePanel
                                    await appState.panels.navigateTo(side: targetSide, remote: bookmark.fs, path: bookmark.path)
                                }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    TransferBarView()
                }
            }
            .navigationSplitViewStyle(.balanced)
            .animation(.easeInOut(duration: 0.25), value: selectedSidebar)
            .frame(minWidth: 1024, minHeight: 640)
            .overlay {
                if appState.appLock.isLocked == true {
                    LockScreenView()
                        .transition(.opacity)
                }
            }
            .sheet(isPresented: Bindable(appState).showSettings) {
                SettingsSheet()
            }
            .sheet(isPresented: Bindable(appState).showAccountSetup) {
                AccountSetupView()
                    .frame(minWidth: 650, minHeight: 550)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { appState.showTransfers.toggle() }) {
                        Label(L10n.t("toolbar.transfers"), systemImage: appState.transfers.hasActiveTransfers ? "arrow.up.arrow.down.circle.fill" : "arrow.up.arrow.down.circle")
                    }
                    .quickTooltip(L10n.t("toolbar.transfers"))
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(action: { appState.showSettings = true }) {
                        Label(L10n.t("toolbar.settings"), systemImage: "gearshape")
                    }
                    .quickTooltip(L10n.t("toolbar.settings"))
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .requestSearch)) { _ in
                selectedSidebar = .search
            }
            .onReceive(NotificationCenter.default.publisher(for: .requestExplorer)) { _ in
                selectedSidebar = .explorer
            }
            .onReceive(NotificationCenter.default.publisher(for: .finderUploadRequested)) { notification in
                if let urls = notification.object as? [URL] {
                    finderUploadURLs = urls
                }
            }
            .sheet(item: Binding(
                get: { finderUploadURLs.map { FinderUploadData(urls: $0) } },
                set: { _ in finderUploadURLs = nil }
            )) { data in
                FinderUploadSheet(urls: data.urls)
            }
        }
    }
}
