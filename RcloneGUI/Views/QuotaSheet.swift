import SwiftUI
import RcloneKit

struct QuotaSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var quotas: [(remote: String, type: String, total: Int64?, used: Int64?, free: Int64?)] = []
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L10n.t("quota.title")).font(.title2.bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if quotas.isEmpty {
                Text(L10n.t("quota.noData"))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(quotas, id: \.remote) { quota in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "cloud.fill")
                                    .foregroundColor(.accentColor)
                                Text(quota.remote)
                                    .font(.body.bold())
                                Text(quota.type)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }

                            if let total = quota.total, total > 0 {
                                let used = quota.used ?? 0
                                let fraction = Double(used) / Double(total)

                                ProgressView(value: fraction)
                                    .tint(fraction > 0.9 ? .red : fraction > 0.7 ? .orange : .accentColor)

                                HStack {
                                    Text("\(L10n.t("quota.used")): \(FormatUtils.formatBytes(used))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    if let free = quota.free {
                                        Text("\(L10n.t("quota.free")): \(FormatUtils.formatBytes(free))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("\(L10n.t("quota.total")): \(FormatUtils.formatBytes(total))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text(L10n.t("quota.notAvailable"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(width: 500, height: 400)
        .task {
            await loadAllQuotas()
        }
    }

    private func loadAllQuotas() async {
        isLoading = true
        var results: [(remote: String, type: String, total: Int64?, used: Int64?, free: Int64?)] = []

        for remote in appState.accounts.remotes {
            let info = try? await RcloneAPI.about(using: appState.client, fs: "\(remote.name):")
            results.append((
                remote: remote.name,
                type: remote.type,
                total: info?.total,
                used: info?.used,
                free: info?.free
            ))
        }

        quotas = results
        isLoading = false
    }
}
