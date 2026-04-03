import SwiftUI
import RcloneKit

struct TransferBarView: View {
    @Environment(AppState.self) private var appState
    @State private var isExpanded = false
    @State private var showReport = false

    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedView
                    .frame(height: 250)
                    .transition(.move(edge: .bottom))
            }

            // Compact bar
            HStack(spacing: 12) {
                if appState.transfers.hasActiveTransfers {
                    ProgressView(value: overallProgress)
                        .frame(width: 120)

                    Text("\(appState.transfers.transfers.count) \(L10n.t("menubar.activeTransfers"))")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Text(FormatUtils.formatSpeed(appState.transfers.totalSpeed))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                        .font(.system(size: 11))
                    Text(L10n.t("menubar.noTransfers"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if appState.transfers.paused {
                    Label(L10n.t("transfer.paused"), systemImage: "pause.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                }

                // Error indicator
                if appState.transfers.errors > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 10))
                        Text("\(appState.transfers.errors)")
                            .font(.system(size: 10))
                            .foregroundColor(.red)
                    }
                }

                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
    }

    private var overallProgress: Double {
        guard appState.transfers.totalSize > 0 else { return 0 }
        return Double(appState.transfers.totalBytes) / Double(appState.transfers.totalSize)
    }

    private var expandedView: some View {
        VStack(spacing: 0) {
            Divider()

            // Header with actions
            HStack(spacing: 8) {
                Text(L10n.t("toolbar.transfers"))
                    .font(.system(size: 12, weight: .semibold))

                Spacer()

                if appState.transfers.hasActiveTransfers {
                    Button(action: { Task { await appState.transfers.pauseAll() } }) {
                        Image(systemName: "pause")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .disabled(appState.transfers.paused)

                    Button(action: { Task { await appState.transfers.resumeAll() } }) {
                        Image(systemName: "play")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .disabled(!appState.transfers.paused)

                    Button(action: { Task { await appState.transfers.stopAllJobs() } }) {
                        Image(systemName: "stop")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                }

                Button(L10n.t("report.title")) { showReport = true }
                    .font(.system(size: 10))
                    .controlSize(.mini)

                if !appState.transfers.completed.isEmpty {
                    Button(L10n.t("transfer.clear")) {
                        appState.transfers.clearAll()
                    }
                    .font(.system(size: 10))
                    .controlSize(.mini)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)

            Divider()

            // Transfer list
            List {
                ForEach(appState.transfers.transfers) { t in
                    HStack(spacing: 8) {
                        ProgressView(value: Double(t.percentage), total: 100)
                            .frame(width: 60)
                        Text(t.name)
                            .font(.system(size: 11))
                            .lineLimit(1)
                        Spacer()
                        Text("\(t.percentage)%")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                        Text(FormatUtils.formatSpeed(t.speed))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }

                ForEach(appState.transfers.completed.prefix(10)) { t in
                    HStack(spacing: 8) {
                        Image(systemName: t.ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(t.ok ? .green : .red)
                            .font(.system(size: 11))
                        Text(t.name)
                            .font(.system(size: 11))
                            .lineLimit(1)
                        Spacer()
                        Text(FormatUtils.formatBytes(t.size))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }

                // Failed checkpoints (resumable)
                if !appState.transfers.checkpoints.isEmpty {
                    Section {
                        ForEach(appState.transfers.checkpoints) { cp in
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise.circle")
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
                                Spacer()
                                Text("\(cp.attempts)/\(3)")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.secondary)
                                Button(L10n.t("transfer.restart")) {
                                    Task { await appState.transfers.retryCheckpoint(cp) }
                                }
                                .controlSize(.mini)
                                Button(action: { appState.transfers.removeCheckpoint(id: cp.id) }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } header: {
                        HStack {
                            Text(L10n.t("transfer.resumable"))
                                .font(.system(size: 10, weight: .semibold))
                            Spacer()
                            if appState.transfers.checkpoints.count > 1 {
                                Button(L10n.t("transfer.retryAll")) {
                                    Task { await appState.transfers.retryAllFailed() }
                                }
                                .font(.system(size: 10))
                                .controlSize(.mini)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .background(.ultraThinMaterial)
        .sheet(isPresented: $showReport) {
            TransferReportSheet()
        }
    }
}
