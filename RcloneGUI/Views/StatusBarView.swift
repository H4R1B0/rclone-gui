import SwiftUI
import RcloneKit

struct StatusBarView: View {
    @Environment(AppState.self) private var appState
    @State private var showErrorPopover = false
    @State private var quota: (used: Int64, total: Int64)?

    private var activeTab: TabState {
        appState.panels.side(appState.panels.activePanel).activeTab
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left: rclone info
            Text("rclone (librclone)")
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            // Quota for active panel's remote
            if activeTab.remote != "/" {
                if let quota = quota {
                    let usedStr = FormatUtils.formatBytes(quota.used)
                    let totalStr = FormatUtils.formatBytes(quota.total)
                    Text("  \(usedStr) / \(totalStr)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Center: transfer stats
            if appState.transfers.hasActiveTransfers {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.mini)
                    Text(String(format: L10n.t("status.active"), appState.transfers.transfers.count))
                        .font(.system(size: 10))
                    Text(FormatUtils.formatSpeed(appState.transfers.totalSpeed))
                        .font(.system(size: 10))
                        .monospacedDigit()
                }
                .foregroundColor(.secondary)
            }

            Spacer()

            // Right: error indicator
            if appState.transfers.errors > 0 || !appState.transfers.lastErrors.isEmpty {
                Button(action: { showErrorPopover.toggle() }) {
                    HStack(spacing: 2) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 10))
                        Text("\(appState.transfers.errors)")
                            .font(.system(size: 10))
                            .foregroundColor(.red)
                    }
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showErrorPopover) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.t("status.recentErrors"))
                            .font(.caption.bold())
                            .padding(.bottom, 4)

                        ScrollView {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(Array(appState.transfers.lastErrors.prefix(20).enumerated()), id: \.offset) { _, error in
                                    Text(error)
                                        .font(.system(size: 10))
                                        .foregroundColor(.red)
                                        .textSelection(.enabled)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding(12)
                    .frame(width: 350)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 3)
        .background(Color(nsColor: .windowBackgroundColor))
        .task(id: activeTab.remote) {
            if activeTab.remote != "/" {
                if let info = try? await RcloneAPI.about(using: appState.client, fs: activeTab.remote) {
                    if let total = info.total, let used = info.used {
                        quota = (used: used, total: total)
                    } else {
                        quota = nil
                    }
                } else {
                    quota = nil
                }
            } else {
                quota = nil
            }
        }
    }
}
