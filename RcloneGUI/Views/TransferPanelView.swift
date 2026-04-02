import SwiftUI
import TransferEngine

struct TransferPanelView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: TransferTab = .active

    enum TransferTab: String, CaseIterable {
        case active = "Active"
        case completed = "Completed"
        case failed = "Failed"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("", selection: $selectedTab) {
                    ForEach(TransferTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)

                Spacer()

                if selectedTab != .active {
                    Button("Clear") {
                        Task { await appState.transfers.clearCompleted() }
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            Divider()

            List {
                ForEach(currentTransfers) { transfer in
                    TransferItemView(transfer: transfer) {
                        Task { await appState.transfers.cancel(id: transfer.id) }
                    }
                }
            }
            .listStyle(.plain)
            .overlay {
                if currentTransfers.isEmpty {
                    Text("No transfers")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var currentTransfers: [TransferOperation] {
        switch selectedTab {
        case .active: return appState.transfers.activeTransfers
        case .completed: return appState.transfers.completedTransfers
        case .failed: return appState.transfers.failedTransfers
        }
    }
}
