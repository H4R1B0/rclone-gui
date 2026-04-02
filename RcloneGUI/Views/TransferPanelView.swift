import SwiftUI
import RcloneKit

enum TransferTab: CaseIterable {
    case active, completed, errors
    var label: String {
        switch self {
        case .active: return L10n.t("transfer.active")
        case .completed: return L10n.t("transfer.completed")
        case .errors: return L10n.t("transfer.errors")
        }
    }
}

struct TransferPanelView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: TransferTab = .active
    @State private var showReport = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Picker("", selection: $selectedTab) {
                    ForEach(TransferTab.allCases, id: \.self) { tab in
                        Text(tab.label).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 280)

                Spacer()

                // Pause banner
                if appState.transfers.paused {
                    HStack(spacing: 4) {
                        Image(systemName: "pause.circle.fill")
                            .foregroundColor(.orange)
                        Text(L10n.t("transfer.paused"))
                            .font(.caption)
                            .foregroundColor(.orange)
                        Button(L10n.t("transfer.resume")) {
                            Task { await appState.transfers.resumeAll() }
                        }
                        .controlSize(.small)
                    }
                }

                // Action buttons
                HStack(spacing: 4) {
                    if selectedTab == .active {
                        Button(action: { Task { await appState.transfers.pauseAll() } }) {
                            Image(systemName: "pause")
                        }
                        .buttonStyle(.borderless)
                        .help(L10n.t("transfer.pauseAll"))
                        .disabled(appState.transfers.paused)

                        Button(action: { Task { await appState.transfers.stopAllJobs() } }) {
                            Image(systemName: "stop")
                        }
                        .buttonStyle(.borderless)
                        .help(L10n.t("transfer.stopAll"))
                    }

                    Button(L10n.t("report.title")) { showReport = true }
                        .controlSize(.small)

                    if selectedTab == .completed {
                        Button(L10n.t("transfer.clear")) { appState.transfers.clearCompleted() }
                            .controlSize(.small)
                    }
                    if selectedTab == .errors {
                        Button(L10n.t("transfer.clear")) { appState.transfers.clearErrors() }
                            .controlSize(.small)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            Divider()

            // Content
            List {
                switch selectedTab {
                case .active:
                    // Running transfers
                    ForEach(appState.transfers.transfers) { transfer in
                        ActiveTransferRow(transfer: transfer)
                            .contextMenu {
                                Button(L10n.t("transfer.stop")) {
                                    Task { await appState.transfers.stopAllJobs() }
                                }
                            }
                    }
                    // Stopped transfers (restartable)
                    ForEach(appState.transfers.stopped) { stopped in
                        StoppedTransferRow(stopped: stopped) {
                            Task { await appState.transfers.restartTransfer(stopped) }
                        }
                        .contextMenu {
                            Button(L10n.t("transfer.restart")) {
                                Task { await appState.transfers.restartTransfer(stopped) }
                            }
                            Button(L10n.t("transfer.remove")) {
                                appState.transfers.removeStopped(id: stopped.id)
                            }
                        }
                    }

                case .completed:
                    ForEach(appState.transfers.successfulCompleted) { transfer in
                        CompletedTransferRow(transfer: transfer)
                    }

                case .errors:
                    ForEach(appState.transfers.errorCompleted) { transfer in
                        ErrorTransferRow(transfer: transfer)
                    }
                }
            }
            .listStyle(.plain)
            .overlay {
                if currentListEmpty {
                    Text(L10n.t("transfer.noTransfers"))
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
        .sheet(isPresented: $showReport) {
            TransferReportSheet()
        }
    }

    private var currentListEmpty: Bool {
        switch selectedTab {
        case .active: return appState.transfers.transfers.isEmpty && appState.transfers.stopped.isEmpty
        case .completed: return appState.transfers.successfulCompleted.isEmpty
        case .errors: return appState.transfers.errorCompleted.isEmpty
        }
    }
}

// MARK: - Row Views

struct ActiveTransferRow: View {
    let transfer: RcloneTransferring

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(transfer.name)
                    .font(.system(size: 12))
                    .lineLimit(1)
                Spacer()
                Text("\(transfer.percentage)%")
                    .font(.system(size: 11))
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }

            ProgressView(value: Double(transfer.percentage), total: 100)
                .progressViewStyle(.linear)

            HStack {
                Text("\(FormatUtils.formatBytes(transfer.bytes)) / \(FormatUtils.formatBytes(transfer.size))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
                Text(FormatUtils.formatSpeed(transfer.speed))
                    .font(.system(size: 10))
                    .monospacedDigit()
                    .foregroundColor(.secondary)
                Text("ETA \(FormatUtils.formatEta(transfer.eta))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct StoppedTransferRow: View {
    let stopped: StoppedTransfer
    let onRestart: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "stop.circle")
                .foregroundColor(.orange)
            VStack(alignment: .leading) {
                Text(stopped.name)
                    .font(.system(size: 12))
                    .lineLimit(1)
                Text(L10n.t("transfer.stopped"))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(L10n.t("transfer.restart")) { onRestart() }
                .controlSize(.small)
        }
    }
}

struct CompletedTransferRow: View {
    let transfer: RcloneCompletedTransfer

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 12))
            Text(transfer.name)
                .font(.system(size: 12))
                .lineLimit(1)
            Spacer()
            Text(FormatUtils.formatBytes(transfer.size))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
}

struct ErrorTransferRow: View {
    let transfer: RcloneCompletedTransfer

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 12))
                Text(transfer.name)
                    .font(.system(size: 12))
                    .lineLimit(1)
            }
            Text(transfer.error)
                .font(.system(size: 10))
                .foregroundColor(.red.opacity(0.8))
                .lineLimit(2)
                .padding(.leading, 20)
        }
    }
}
