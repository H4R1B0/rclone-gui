import SwiftUI
import RcloneKit

struct SyncView: View {
    @Environment(AppState.self) private var appState
    @State private var showCreateProfile = false

    private var sync: SyncViewModel { appState.sync }

    var body: some View {
        HSplitView {
            // Left: Profile list
            profileList
                .frame(minWidth: 250, maxWidth: 350)

            // Right: Logs
            logPanel
        }
    }

    private var profileList: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L10n.t("sync.profiles"))
                    .font(.headline)
                Spacer()
                Button(action: { showCreateProfile = true }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
            }
            .padding()

            Divider()

            if sync.profiles.isEmpty {
                ContentUnavailableView {
                    Label(L10n.t("sync.noProfiles"), systemImage: "arrow.triangle.2.circlepath")
                } description: {
                    EmptyView()
                } actions: {
                    Button(L10n.t("sync.createProfile")) {
                        showCreateProfile = true
                    }
                }
            } else {
                List {
                    ForEach(sync.profiles) { profile in
                        profileRow(profile)
                    }
                }
                .listStyle(.inset)
            }
        }
        .sheet(isPresented: $showCreateProfile) {
            SyncProfileSheet(remotes: appState.panels.remotes)
        }
    }

    private func profileRow(_ profile: SyncProfile) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.accentColor)
                Text(profile.name)
                    .font(.body.bold())
                Spacer()

                Text(profile.syncMode.label)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(4)
            }

            HStack(spacing: 4) {
                Text(profile.sourceFs + profile.sourcePath)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Image(systemName: "arrow.right")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                Text(profile.destFs + profile.destPath)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Button(L10n.t("sync.run")) {
                    Task { await sync.runSync(profile: profile) }
                }
                .controlSize(.small)
                .disabled(sync.isRunning)

                if sync.isRunning && sync.currentJobId != nil {
                    Button(L10n.t("sync.stop")) {
                        Task { await sync.stopSync() }
                    }
                    .controlSize(.small)
                }

                Spacer()

                Button(role: .destructive, action: {
                    sync.deleteProfile(id: profile.id)
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }

    private var logPanel: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L10n.t("sync.logs"))
                    .font(.headline)
                Spacer()
                if !sync.logs.isEmpty {
                    Button(L10n.t("transfer.clear")) {
                        sync.logs.removeAll()
                    }
                    .controlSize(.small)
                }
            }
            .padding()

            Divider()

            if sync.logs.isEmpty {
                Text(L10n.t("sync.noLogs"))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(sync.logs.enumerated()), id: \.offset) { _, log in
                            Text(log)
                                .font(.system(size: 11, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                    .padding(8)
                }
            }
        }
    }
}
