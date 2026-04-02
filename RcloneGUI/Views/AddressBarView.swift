import SwiftUI

struct AddressBarView: View {
    @Bindable var viewModel: PanelViewModel
    @State private var editingPath: String = ""
    @State private var isEditing: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Button(action: { Task { await viewModel.navigateUp() } }) {
                Image(systemName: "chevron.up")
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.currentPath.isEmpty)

            Button(action: { Task { await viewModel.refresh() } }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)

            if isEditing {
                TextField("Path", text: $editingPath)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        Task { await viewModel.navigate(to: editingPath) }
                        isEditing = false
                    }
            } else {
                Text(viewModel.displayPath)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(4)
                    .onTapGesture {
                        editingPath = viewModel.currentPath
                        isEditing = true
                    }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}
