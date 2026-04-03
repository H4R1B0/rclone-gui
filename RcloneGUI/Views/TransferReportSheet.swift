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

            // Failed files
            if !failed.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.t("report.failedFiles")).font(.caption.bold())
                    ScrollView {
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
                    .frame(maxHeight: 150)
                }
            }

            // Successful files
            if !successful.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.t("report.successFiles")).font(.caption.bold())
                    ScrollView {
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
                    .frame(maxHeight: 200)
                }
            }

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
        .frame(width: 550, height: 500)
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
        var lines = ["=== Transfer Report ==="]
        lines.append("Total: \(completed.count), Success: \(successful.count), Failed: \(failed.count)")
        lines.append("Total Size: \(FormatUtils.formatBytes(totalBytes))")
        if !failed.isEmpty {
            lines.append("\n--- Failed ---")
            for t in failed { lines.append("x \(t.name): \(t.error)") }
        }
        lines.append("\n--- Completed ---")
        for t in successful { lines.append("o \(t.name) (\(FormatUtils.formatBytes(t.size)))") }
        return lines.joined(separator: "\n")
    }
}
