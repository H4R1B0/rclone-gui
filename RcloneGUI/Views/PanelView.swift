import SwiftUI

struct PanelView: View {
    @Environment(AppState.self) private var appState
    let side: PanelSide

    private var sideState: PanelSideState {
        appState.panels.side(side)
    }

    private var tab: TabState {
        sideState.activeTab
    }

    var body: some View {
        VStack(spacing: 0) {
            // Cloud mode with no remote selected → show RemoteSelector
            if tab.mode == .cloud && tab.remote.isEmpty {
                RemoteSelectorView(side: side)
            } else {
                // Tab bar
                TabBarView(side: side)

                Divider()

                // Address bar
                AddressBarView(side: side)

                Divider()

                // File content
                ZStack {
                    if tab.loading {
                        VStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.large)
                            Text("Loading...")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    } else if let error = tab.error {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            Text(error)
                                .foregroundColor(.secondary)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                Task { await appState.panels.refresh(side: side) }
                            }
                        }
                        .padding()
                    } else {
                        FileTableView(side: side)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onTapGesture {
            appState.panels.activePanel = side
        }
        .background(
            appState.panels.activePanel == side
                ? Color.clear
                : Color(nsColor: .windowBackgroundColor).opacity(0.3)
        )
    }
}
