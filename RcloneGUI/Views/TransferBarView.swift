import SwiftUI
import RcloneKit

struct TransferBarView: View {
    @Environment(AppState.self) private var appState
    @State private var showReport = false

    private var isExpanded: Bool { appState.showTransfers }

    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedView
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }

            // Compact status bar — always visible
            compactBar
        }
    }

    // MARK: - Compact Bar

    private var compactBar: some View {
        HStack(spacing: 10) {
            if appState.transfers.hasActiveTransfers {
                Circle()
                    .fill(appState.transfers.paused ? Color.orange : Color.green)
                    .frame(width: 6, height: 6)

                ProgressView(value: overallProgress)
                    .frame(width: 100)

                Text("\(appState.transfers.transfers.count) \(L10n.t("menubar.activeTransfers"))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Text(FormatUtils.formatSpeed(appState.transfers.totalSpeed))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.accentColor)

                if appState.transfers.paused {
                    Text(L10n.t("transfer.paused"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.orange)
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 10))
                Text(L10n.t("menubar.noTransfers"))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Error badge
            if appState.transfers.errors > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 9))
                    Text("\(appState.transfers.errors)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.red.opacity(0.1))
                .cornerRadius(4)
            }

            // Completed count (when collapsed)
            if !appState.transfers.completed.isEmpty && !isExpanded {
                Text("\(appState.transfers.completed.count) \(L10n.t("transfer.completed"))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { appState.showTransfers.toggle() } }) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(L10n.t("toolbar.transfers"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.bar)
    }

    // MARK: - Expanded View (card style)

    private var expandedView: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Text(L10n.t("toolbar.transfers"))
                    .font(.system(size: 12, weight: .semibold))

                if appState.transfers.hasActiveTransfers {
                    Text("\(appState.transfers.transfers.count)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.accentColor))
                }

                Spacer()

                if appState.transfers.hasActiveTransfers {
                    HStack(spacing: 2) {
                        Button(action: { Task { await appState.transfers.pauseAll() } }) {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 9))
                                .frame(width: 24, height: 22)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(appState.transfers.paused)
                        .help(L10n.t("transfer.pause"))

                        Button(action: { Task { await appState.transfers.resumeAll() } }) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 9))
                                .frame(width: 24, height: 22)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!appState.transfers.paused)
                        .help(L10n.t("transfer.resume"))

                        Button(action: { Task { await appState.transfers.stopAllJobs() } }) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 9))
                                .frame(width: 24, height: 22)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help(L10n.t("transfer.stopAll"))
                    }
                    .padding(.horizontal, 4)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
                }

                Button(action: { showReport = true }) {
                    Label(L10n.t("report.title"), systemImage: "doc.text")
                        .font(.system(size: 10))
                }
                .controlSize(.mini)

                if !appState.transfers.completed.isEmpty || !appState.transfers.checkpoints.isEmpty {
                    Button(action: { appState.transfers.clearAll() }) {
                        Label(L10n.t("transfer.clear"), systemImage: "trash")
                            .font(.system(size: 10))
                    }
                    .controlSize(.mini)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            Divider().padding(.horizontal, 8)

            // Transfer list
            ScrollView {
                LazyVStack(spacing: 2) {
                    // Active transfers
                    ForEach(appState.transfers.transfers) { t in
                        activeTransferRow(t)
                    }

                    // Completed transfers
                    if !appState.transfers.completed.isEmpty {
                        ForEach(appState.transfers.completed.prefix(30)) { t in
                            completedTransferRow(t)
                        }
                    }

                    // Resumable checkpoints
                    if !appState.transfers.checkpoints.isEmpty {
                        ForEach(appState.transfers.checkpoints) { cp in
                            checkpointRow(cp)
                        }
                    }

                    if appState.transfers.transfers.isEmpty
                        && appState.transfers.completed.isEmpty
                        && appState.transfers.checkpoints.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: "arrow.up.arrow.down.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary.opacity(0.4))
                            Text(L10n.t("menubar.noTransfers"))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
            }
        }
        .frame(height: 250)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 0.5)
        )
        .sheet(isPresented: $showReport) {
            TransferReportSheet()
        }
    }

    // MARK: - Row Views

    private func activeTransferRow(_ t: RcloneTransferring) -> some View {
        HStack(spacing: 10) {
            ProgressView(value: Double(t.percentage), total: 100)
                .frame(width: 50)
                .tint(.accentColor)

            Text(t.name)
                .font(.system(size: 11))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(t.percentage)%")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.accentColor)
                .frame(width: 35, alignment: .trailing)

            Text(FormatUtils.formatSpeed(t.speed))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor.opacity(0.06))
        )
    }

    private func completedTransferRow(_ t: RcloneCompletedTransfer) -> some View {
        HStack(spacing: 10) {
            Image(systemName: t.ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(t.ok ? .green : .red)
                .font(.system(size: 11))

            Text(t.name)
                .font(.system(size: 11))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(FormatUtils.formatBytes(t.size))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
    }

    private func checkpointRow(_ cp: TransferCheckpoint) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 11))

            VStack(alignment: .leading, spacing: 1) {
                Text(cp.fileName)
                    .font(.system(size: 11))
                    .lineLimit(1)
                if let error = cp.lastError {
                    Text(error)
                        .font(.system(size: 9))
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(cp.attempts)/\(AppConstants.maxTransferRetries)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.secondary)

            if cp.attempts < AppConstants.maxTransferRetries {
                Button(L10n.t("transfer.restart")) {
                    Task { await appState.transfers.retryCheckpoint(cp) }
                }
                .controlSize(.mini)
            }

            Button(action: { appState.transfers.removeCheckpoint(id: cp.id) }) {
                Image(systemName: "xmark")
                    .font(.system(size: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.orange.opacity(0.06))
        )
    }

    // MARK: - Helpers

    private var overallProgress: Double {
        guard appState.transfers.totalSize > 0 else { return 0 }
        return min(Double(appState.transfers.totalBytes) / Double(appState.transfers.totalSize), 1.0)
    }
}
