import SwiftUI

struct StatusBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack {
            Text("\(appState.leftPanel.files.count) items")
                .font(.caption)
                .foregroundColor(.secondary)

            if !appState.leftPanel.selectedFileIDs.isEmpty {
                Text("(\(appState.leftPanel.selectedFileIDs.count) selected)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            let activeCount = appState.transfers.activeTransfers.count
            if activeCount > 0 {
                HStack(spacing: 4) {
                    ProgressView().controlSize(.small)
                    Text("\(activeCount) transfer(s)")
                        .font(.caption)
                }
            }

            Spacer()

            Text("\(appState.rightPanel.files.count) items")
                .font(.caption)
                .foregroundColor(.secondary)

            if !appState.rightPanel.selectedFileIDs.isEmpty {
                Text("(\(appState.rightPanel.selectedFileIDs.count) selected)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
