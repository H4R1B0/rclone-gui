import SwiftUI
import RcloneKit

struct RemoteDetailsView: View {
    @Environment(AppState.self) private var appState
    let remoteName: String

    @State private var config: [String: String] = [:]
    @State private var quota: (used: Int64, total: Int64)?
    @State private var isLoading = true

    private var remote: Remote? {
        appState.accounts.remotes.first(where: { $0.name == remoteName })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    ProviderIcon.icon(for: remote?.type ?? "cloud")
                        .font(.system(size: 32))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(remoteName)
                            .font(.title2.bold())
                        Text(remote?.type ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()

                    Button(L10n.t("sidebar.openInExplorer")) {
                        appState.panels.side(.left).addTab(mode: .cloud, remote: "\(remoteName):", label: remoteName)
                        Task { await appState.panels.loadFiles(side: .left) }
                    }
                    .controlSize(.small)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(10)

                // Quota
                if let quota = quota {
                    GroupBox(L10n.t("quota.title")) {
                        VStack(alignment: .leading, spacing: 8) {
                            let fraction = quota.total > 0 ? Double(quota.used) / Double(quota.total) : 0
                            ProgressView(value: fraction)
                                .tint(fraction > 0.9 ? .red : fraction > 0.7 ? .orange : .accentColor)
                            HStack {
                                Text("\(L10n.t("quota.used")): \(FormatUtils.formatBytes(quota.used))")
                                    .font(.caption)
                                Spacer()
                                Text("\(L10n.t("quota.total")): \(FormatUtils.formatBytes(quota.total))")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }

                // Config
                if !config.isEmpty {
                    GroupBox(L10n.t("sidebar.config")) {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(config.keys.sorted()), id: \.self) { key in
                                HStack {
                                    Text(key)
                                        .font(.system(size: 11, weight: .medium))
                                        .frame(width: 120, alignment: .trailing)
                                    Text(key.lowercased().contains("password") || key.lowercased().contains("token") ? "------" : (config[key] ?? ""))
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .textSelection(.enabled)
                                }
                            }
                        }
                    }
                }

                // Actions
                HStack(spacing: 12) {
                    Button(L10n.t("edit")) {
                        appState.showAccountSetup = true
                    }

                    Button(L10n.t("delete"), role: .destructive) {
                        Task { try? await appState.accounts.deleteRemote(name: remoteName) }
                    }
                }
            }
            .padding(20)
        }
        .task {
            isLoading = true
            // Load config
            if let cfg = try? await appState.accounts.getRemoteConfig(name: remoteName) {
                config = cfg
            }
            // Load quota
            if let info = try? await RcloneAPI.about(using: appState.client, fs: "\(remoteName):") {
                if let total = info.total, let used = info.used {
                    quota = (used: used, total: total)
                }
            }
            isLoading = false
        }
    }
}
