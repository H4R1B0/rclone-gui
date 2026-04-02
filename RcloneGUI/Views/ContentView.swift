import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if !appState.ready {
            // Loading screen
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text(L10n.t("app.initializing"))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 0) {
                // Toolbar
                ToolbarView()

                Divider()

                // Main content area
                switch appState.activeView {
                case .explore:
                    DualPanelView()
                case .account:
                    AccountSetupView()
                case .search:
                    SearchPanelView()
                case .sync:
                    SyncView()
                case .scheduler:
                    SchedulerView()
                case .mount:
                    MountView()
                }

                // Transfer area (resizable)
                if appState.showTransfers {
                    // Resizable divider
                    transferDivider

                    TransferPanelView()
                        .frame(height: appState.transferHeight)
                }

                // Status bar
                StatusBarView()
            }
            .frame(minWidth: 900, minHeight: 600)
            .overlay {
                if appState.appLock.isLocked == true {
                    LockScreenView()
                        .transition(.opacity)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .requestSearch)) { _ in
                appState.activeView = .search
            }
            .sheet(isPresented: Bindable(appState).showSettings) {
                SettingsSheet()
            }
        }
    }

    private var transferDivider: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor))
            .frame(height: 1)
            .overlay(
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 8)
                    .contentShape(Rectangle())
                    .cursor(.resizeUpDown)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let delta = -value.translation.height
                                let newHeight = appState.transferHeight + delta
                                appState.transferHeight = min(max(newHeight, 80), 600)
                            }
                    )
            )
    }
}
