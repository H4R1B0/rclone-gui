import SwiftUI
import RcloneKit

struct TransferReportSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    private var completed: [RcloneCompletedTransfer] {
        appState.transfers.completed
    }

    private var successful: [RcloneCompletedTransfer] {
        completed.filter { $0.ok }
    }

    private var failed: [RcloneCompletedTransfer] {
        completed.filter { !$0.ok }
    }

    private var totalBytes: Int64 {
        successful.reduce(0) { $0 + $1.size }
    }

    private var lastErrors: [String] {
        appState.transfers.lastErrors
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(L10n.t("report.title")).font(.headline)

            // Summary
            HStack(spacing: 24) {
                statBox(L10n.t("report.total"), "\(completed.count)")
                statBox(L10n.t("report.success"), "\(successful.count)", color: .green)
                statBox(L10n.t("report.failed"), "\(failed.count)", color: failed.isEmpty ? .secondary : .red)
                statBox(L10n.t("report.totalSize"), FormatUtils.formatBytes(totalBytes))
            }

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Error details section
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.t("transfer.errorDetails"))
                            .font(.caption.bold())
                        if lastErrors.isEmpty {
                            Text(L10n.t("transfer.noErrors"))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 2)
                        } else {
                            ForEach(lastErrors, id: \.self) { err in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    Text(err)
                                        .font(.system(size: 11))
                                        .foregroundColor(.primary)
                                        .textSelection(.enabled)
                                }
                            }
                        }
                    }

                    Divider()

                    // Failed files
                    if !failed.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(L10n.t("report.failedFiles")).font(.caption.bold())
                                Text("(\(failed.count))")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            LazyVStack(alignment: .leading, spacing: 2) {
                                ForEach(failed) { t in
                                    HStack {
                                        Image(systemName: "xmark.circle").foregroundColor(.red).font(.caption)
                                        Text(t.name).font(.system(size: 11)).lineLimit(1)
                                        Spacer()
                                        Text(t.error).font(.system(size: 10)).foregroundColor(.red).lineLimit(1)
                                    }
                                }
                            }
                        }

                        Divider()
                    }

                    // Successful files
                    if !successful.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(L10n.t("report.successFiles")).font(.caption.bold())
                                Text("(\(successful.count))")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            LazyVStack(alignment: .leading, spacing: 2) {
                                ForEach(successful.prefix(50)) { t in
                                    HStack {
                                        Image(systemName: "checkmark.circle").foregroundColor(.green).font(.caption)
                                        Text(t.name).font(.system(size: 11)).lineLimit(1)
                                        Spacer()
                                        Text(FormatUtils.formatBytes(t.size)).font(.system(size: 10)).foregroundColor(.secondary)
                                    }
                                }
                                if successful.count > 50 {
                                    Text("... \(L10n.t("report.andMore")) \(successful.count - 50)")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 320)

            HStack {
                Button(L10n.t("report.copyToClipboard")) {
                    let text = generateReportText()
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                }
                Spacer()
                Button(L10n.t("close")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(20)
        .frame(width: 550, height: 520)
    }

    private func statBox(_ label: String, _ value: String, color: Color = .primary) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func generateReportText() -> String {
        var lines = ["=== \(L10n.t("report.title")) ==="]
        lines.append("\(L10n.t("report.total")): \(completed.count), \(L10n.t("report.success")): \(successful.count), \(L10n.t("report.failed")): \(failed.count)")
        lines.append("\(L10n.t("report.totalSize")): \(FormatUtils.formatBytes(totalBytes))")
        if !lastErrors.isEmpty {
            lines.append("\n--- \(L10n.t("transfer.errorDetails")) ---")
            for err in lastErrors { lines.append("! \(err)") }
        }
        if !failed.isEmpty {
            lines.append("\n--- \(L10n.t("report.failedFiles")) ---")
            for t in failed { lines.append("x \(t.name): \(t.error)") }
        }
        lines.append("\n--- \(L10n.t("report.successFiles")) ---")
        for t in successful { lines.append("o \(t.name) (\(FormatUtils.formatBytes(t.size)))") }
        return lines.joined(separator: "\n")
    }
}
