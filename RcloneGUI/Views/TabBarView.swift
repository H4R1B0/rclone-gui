import SwiftUI

struct TabBarView: View {
    @Environment(AppState.self) private var appState
    let side: PanelSide

    private var sideState: PanelSideState {
        appState.panels.side(side)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Tab list
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(sideState.tabs) { tab in
                        tabItem(tab)
                    }
                }
            }

            Spacer()

            // Add tab button
            Menu {
                Button("Local") {
                    sideState.addTab(mode: .local, remote: "/", path: NSHomeDirectory(), label: "Local")
                    Task { await appState.panels.loadFiles(side: side) }
                }

                if !appState.panels.remotes.isEmpty {
                    Divider()
                    ForEach(appState.panels.remotes, id: \.self) { remote in
                        Button(remote) {
                            sideState.addTab(mode: .cloud, remote: "\(remote):", path: "", label: remote)
                            Task { await appState.panels.loadFiles(side: side) }
                        }
                    }
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11))
                    .frame(width: 24, height: 24)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 28)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func tabItem(_ tab: TabState) -> some View {
        HStack(spacing: 4) {
            Image(systemName: tab.mode == .local ? "folder" : "cloud")
                .font(.system(size: 10))

            Text(tab.label)
                .font(.system(size: 11))
                .lineLimit(1)

            // Close button (hidden if last tab)
            if sideState.tabs.count > 1 {
                Button(action: { sideState.closeTab(id: tab.id) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(sideState.activeTabId == tab.id ? Color.accentColor.opacity(0.15) : Color.clear)
        .cornerRadius(4)
        .onTapGesture {
            sideState.switchTab(id: tab.id)
        }
    }
}
