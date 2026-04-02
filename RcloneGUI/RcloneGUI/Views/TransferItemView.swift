import SwiftUI
import TransferEngine

struct TransferItemView: View {
    let transfer: TransferOperation
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: transfer.kind == .copy ? "doc.on.doc" : "arrow.right.doc.on.clipboard")
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(transfer.fileName)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text("\(transfer.source.fs) → \(transfer.destination.fs)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if !transfer.speed.isEmpty {
                        Text("·").foregroundColor(.secondary)
                        Text(transfer.speed).font(.caption).monospacedDigit()
                    }

                    if !transfer.eta.isEmpty {
                        Text("·").foregroundColor(.secondary)
                        Text(transfer.eta).font(.caption).monospacedDigit()
                    }
                }
            }

            Spacer()

            statusView

            if !transfer.status.isTerminal {
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private var statusView: some View {
        switch transfer.status {
        case .pending:
            Text("Waiting").font(.caption).foregroundColor(.secondary)
        case .transferring:
            ProgressView(value: transfer.progress).frame(width: 100)
        case .paused:
            Image(systemName: "pause.circle.fill").foregroundColor(.orange)
        case .completed:
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
        case .failed(let message):
            Image(systemName: "exclamationmark.circle.fill").foregroundColor(.red).help(message)
        }
    }
}
