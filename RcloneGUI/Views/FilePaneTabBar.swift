import SwiftUI

struct FilePaneTabBar: View {
    @Environment(AppState.self) private var appState
    let side: PanelSide

    private var sideState: PanelSideState { appState.panels.side(side) }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(sideState.tabs) { tab in
                tabItem(tab)
                if tab.id != sideState.tabs.last?.id {
                    Divider().frame(height: 14)
                }
            }

            Spacer()

            Menu {
                Button(L10n.t("panel.local")) {
                    sideState.addTab(mode: .local, remote: "/", path: NSHomeDirectory(), label: L10n.t("panel.local"))
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
                    .font(.system(size: 10, weight: .medium))
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .frame(width: 26)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.ultraThinMaterial)
    }

    private func tabItem(_ tab: TabState) -> some View {
        HStack(spacing: 4) {
            if tab.mode == .local {
                Image(systemName: "internaldrive")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            } else {
                ProviderIcon.icon(for: tabRemoteType(tab))
                    .font(.system(size: 9))
            }

            Text(tab.label)
                .font(.system(size: 11))
                .lineLimit(1)

            if sideState.tabs.count > 1 {
                Button(action: { sideState.closeTab(id: tab.id) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
                .opacity(sideState.activeTabId == tab.id ? 1 : 0)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(sideState.activeTabId == tab.id ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture { sideState.switchTab(id: tab.id) }
    }

    private func tabRemoteType(_ tab: TabState) -> String {
        let remoteName = tab.remote.replacingOccurrences(of: ":", with: "")
        return appState.accounts.remotes.first(where: { $0.name == remoteName })?.type ?? "cloud"
    }
}
