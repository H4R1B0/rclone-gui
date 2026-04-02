import SwiftUI
import RcloneKit

struct PanelView: View {
    @Bindable var viewModel: PanelViewModel
    let side: PanelSide

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                RemoteSelectorView(viewModel: viewModel)
                AddressBarView(viewModel: viewModel)
            }
            .padding(.vertical, 4)

            Divider()

            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.error {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text(error)
                            .foregroundColor(.secondary)
                        Button("Retry") { Task { await viewModel.refresh() } }
                    }
                } else {
                    FileTableView(viewModel: viewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task {
            await viewModel.navigate(to: viewModel.currentPath)
        }
    }
}
