import SwiftUI

struct RemoteSelectorView: View {
    @Environment(AppState.self) private var appState
    let side: PanelSide

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(appState.accounts.remotes) { remote in
                    Button(action: {
                        appState.panels.setRemote(side: side, remote: "\(remote.name):")
                        Task { await appState.panels.loadFiles(side: side) }
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: "cloud.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.accentColor)
                            Text(remote.displayName)
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)
                            Text(remote.type)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }

                // Add account button
                Button(action: { appState.activeView = .account }) {
                    VStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                        Text("Add Account")
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
            .padding(20)
        }
    }
}
