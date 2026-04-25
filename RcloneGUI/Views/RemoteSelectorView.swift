import SwiftUI
import RcloneKit

struct RemoteSelectorView: View {
    @Environment(AppState.self) private var appState
    let side: PanelSide

    @State private var draggingRemoteName: String?

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(appState.accounts.orderedRemotes) { remote in
                    Button(action: {
                        appState.panels.setRemote(side: side, remote: "\(remote.name):")
                        Task { await appState.panels.loadFiles(side: side) }
                    }) {
                        remoteCard(remote)
                    }
                    .buttonStyle(.plain)
                    .opacity(draggingRemoteName == remote.name ? 0.4 : 1)
                    .onDrag {
                        draggingRemoteName = remote.name
                        return NSItemProvider(object: remote.name as NSString)
                    }
                    .onDrop(of: [.text], delegate: RemoteDropDelegate(
                        remoteName: remote.name,
                        accounts: appState.accounts,
                        draggingRemoteName: $draggingRemoteName
                    ))
                }

                remoteAddButton
            }
            .padding(20)
        }
    }

    @ViewBuilder
    private func remoteCard(_ remote: Remote) -> some View {
        let hasAlias = appState.accounts.aliasStore.alias(for: remote.name) != nil
        VStack(spacing: 6) {
            ProviderIcon.icon(for: remote.type, size: 24)
            Text(appState.accounts.displayName(for: remote.name))
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
            Text(hasAlias ? remote.name : remote.type)
                .font(.system(size: hasAlias ? 10 : 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    private var remoteAddButton: some View {
        Group {
            Button(action: { appState.showAccountSetup = true }) {
                    VStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                        Text(L10n.t("panel.addAccount"))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundColor(.secondary.opacity(0.3))
                    )
                }
                .buttonStyle(.plain)
        }
    }
}
