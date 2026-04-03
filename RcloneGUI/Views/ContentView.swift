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
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text(L10n.t("app.initializing"))
                    .foregroundColor(.secondary)
            }
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
                                .onAppear {
                                    Task {
                                        await appState.panels.navigateTo(side: .left, remote: bookmark.fs, path: bookmark.path)
                                    }
                                }
                                .id("bookmark-\(bookmark.id)")
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    TransferBarView()
                }
            }
            .navigationSplitViewStyle(.balanced)
            .frame(minWidth: 1000, minHeight: 600)
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
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: { appState.panels.linkedBrowsing.toggle() }) {
                        Image(systemName: appState.panels.linkedBrowsing ? "link.circle.fill" : "link.circle")
                    }
                    .help(L10n.t("toolbar.linkedBrowsing"))
                    .foregroundColor(appState.panels.linkedBrowsing ? .accentColor : .secondary)

                    Button(action: { appState.showTransfers.toggle() }) {
                        Image(systemName: appState.transfers.hasActiveTransfers ? "arrow.up.arrow.down.circle.fill" : "arrow.up.arrow.down.circle")
                    }
                    .help(L10n.t("toolbar.transfers"))

                    Button(action: { appState.showSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                    .help(L10n.t("toolbar.settings"))
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .requestSearch)) { _ in
                selectedSidebar = .search
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
