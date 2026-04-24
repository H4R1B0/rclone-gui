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
    @State private var aliasDraft: String = ""
    @State private var isTesting: Bool = false
    @State private var testResult: TestResult?

    private struct TestResult: Identifiable {
        let id = UUID()
        let success: Bool
        let detail: String
        let latencyMs: Int?
    }

    private var remote: Remote? {
        appState.accounts.remotes.first(where: { $0.name == remoteName })
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header — consistent with other tool views
            HStack(spacing: 10) {
                ProviderIcon.icon(for: remote?.type ?? "cloud")
                    .font(.system(size: 18))
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.accounts.displayName(for: remoteName)).font(.headline)
                    if appState.accounts.aliasStore.alias(for: remoteName) != nil {
                        Text(remoteName)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                Text(remote?.type ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { Task { await runConnectionTest() } }) {
                    if isTesting {
                        ProgressView().controlSize(.mini)
                    } else {
                        Text(L10n.t("remote.test"))
                    }
                }
                .controlSize(.small)
                .disabled(isTesting)
                Button(L10n.t("edit")) {
                    if let r = remote { editingRemote = r }
                }
                .controlSize(.small)
                Button(L10n.t("delete"), role: .destructive) {
                    showDeleteConfirm = true
                }
                .controlSize(.small)
            }
            .padding()

            if let result = testResult {
                HStack(spacing: 8) {
                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.success ? .green : .red)
                    Text(result.success
                         ? (result.latencyMs.map { "\(L10n.t("remote.test.ok")) (\($0) ms)" } ?? L10n.t("remote.test.ok"))
                         : "\(L10n.t("remote.test.fail")): \(result.detail)")
                        .font(.system(size: 12))
                        .foregroundColor(result.success ? .green : .red)
                        .lineLimit(2)
                    Spacer()
                    Button(action: { testResult = nil }) {
                        Image(systemName: "xmark").font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background((result.success ? Color.green : Color.red).opacity(0.1))
            }

            Divider()

            if isLoading {
                DetailSkeleton()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section(L10n.t("remote.alias.section")) {
                        HStack {
                            TextField(L10n.t("remote.alias.placeholder"), text: $aliasDraft)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit { commitAlias() }
                            Button(L10n.t("save")) { commitAlias() }
                                .controlSize(.small)
                                .disabled(aliasDraft.trimmingCharacters(in: .whitespaces)
                                          == (appState.accounts.aliasStore.alias(for: remoteName) ?? ""))
                            if appState.accounts.aliasStore.alias(for: remoteName) != nil {
                                Button(L10n.t("remote.alias.remove"), role: .destructive) {
                                    appState.accounts.setAlias(for: remoteName, to: nil)
                                    aliasDraft = ""
                                }
                                .controlSize(.small)
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    // Quota section
                    if let quota = quota {
                        Section(L10n.t("quota.title")) {
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
                            .padding(.vertical, 4)
                        }
                    }

                    // Config section
                    if !config.isEmpty {
                        Section(L10n.t("sidebar.config")) {
                            ForEach(Array(config.keys.sorted()), id: \.self) { key in
                                let maskedValue = key.lowercased().contains("password") || key.lowercased().contains("token") ? "------" : (config[key] ?? "")
                                LabeledContent(key) {
                                    Text(maskedValue)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .textSelection(.enabled)
                                }
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task(id: remoteName) {
            await loadData()
        }
        .confirmationDialog(L10n.t("confirm.delete.title"), isPresented: $showDeleteConfirm) {
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
        aliasDraft = appState.accounts.aliasStore.alias(for: remoteName) ?? ""
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

    private func commitAlias() {
        let trimmed = aliasDraft.trimmingCharacters(in: .whitespaces)
        appState.accounts.setAlias(for: remoteName, to: trimmed.isEmpty ? nil : trimmed)
    }

    @MainActor
    private func runConnectionTest() async {
        isTesting = true
        testResult = nil
        let start = Date()
        do {
            _ = try await RcloneAPI.about(using: appState.client, fs: "\(remoteName):")
            let ms = Int(Date().timeIntervalSince(start) * 1000)
            testResult = TestResult(success: true, detail: "", latencyMs: ms)
        } catch {
            testResult = TestResult(success: false, detail: error.localizedDescription, latencyMs: nil)
        }
        isTesting = false
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
