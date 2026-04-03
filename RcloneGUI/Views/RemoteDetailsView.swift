import SwiftUI
import RcloneKit

struct RemoteDetailsView: View {
    @Environment(AppState.self) private var appState
    let remoteName: String

    @State private var config: [String: String] = [:]
    @State private var quota: (used: Int64, total: Int64)?
    @State private var isLoading = true
    @State private var showDeleteConfirm = false
    @State private var editingRemote: Remote?

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
                        if let r = remote { editingRemote = r }
                    }

                    Button(L10n.t("delete"), role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
            }
            .padding(20)
        }
        .task(id: remoteName) {
            await loadData()
        }
        .alert(L10n.t("confirm.delete.title"), isPresented: $showDeleteConfirm) {
            Button(L10n.t("cancel"), role: .cancel) {}
            Button(L10n.t("delete"), role: .destructive) {
                Task { try? await appState.accounts.deleteRemote(name: remoteName) }
            }
        } message: {
            Text(L10n.t("confirm.delete.message", remoteName))
        }
        .sheet(item: $editingRemote) { remote in
            RemoteEditSheet(remote: remote)
                .frame(minWidth: 550, minHeight: 450)
        }
    }

    private func loadData() async {
        isLoading = true
        config = [:]
        quota = nil
        if let cfg = try? await appState.accounts.getRemoteConfig(name: remoteName) {
            config = cfg
        }
        if let info = try? await RcloneAPI.about(using: appState.client, fs: "\(remoteName):") {
            if let total = info.total, let used = info.used {
                quota = (used: used, total: total)
            }
        }
        isLoading = false
    }
}

// MARK: - Edit Sheet (wraps RemoteFormView for a specific remote)

struct RemoteEditSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let remote: Remote

    var body: some View {
        Group {
            if let provider = appState.accounts.providers.first(where: { $0.prefix == remote.type }) {
                RemoteFormView(
                    title: "\(L10n.t("edit")) \(remote.displayName)",
                    provider: provider,
                    initialName: remote.name,
                    initialParams: [:],
                    loadExisting: remote.name,
                    onBack: { dismiss() },
                    onSave: { name, params in
                        try await appState.accounts.updateRemote(
                            oldName: remote.name, newName: name,
                            type: provider.prefix, parameters: params
                        )
                        dismiss()
                    }
                )
            } else {
                VStack(spacing: 12) {
                    Text("\(L10n.t("account.providerNotFound")): \(remote.type)")
                        .foregroundColor(.red)
                    Button(L10n.t("close")) { dismiss() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
