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
