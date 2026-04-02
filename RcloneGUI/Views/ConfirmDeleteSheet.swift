import SwiftUI
import RcloneKit

struct ConfirmDeleteSheet: View {
    @Bindable var viewModel: PanelViewModel
    let filesToDelete: [FileItem]
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trash")
                .font(.system(size: 40))
                .foregroundColor(.red)

            if filesToDelete.count == 1, let file = filesToDelete.first {
                Text("Delete \"\(file.name)\"?")
                    .font(.headline)
            } else {
                Text("Delete \(filesToDelete.count) items?")
                    .font(.headline)
            }

            Text("This action cannot be undone.")
                .foregroundColor(.secondary)
                .font(.caption)

            if filesToDelete.count <= 10 {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(filesToDelete) { file in
                        HStack(spacing: 4) {
                            Image(systemName: file.isDir ? "folder.fill" : "doc")
                                .font(.caption)
                            Text(file.name)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(4)
            }

            if let error = errorMessage {
                Text(error).foregroundColor(.red).font(.caption)
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Button("Delete", role: .destructive) { performDelete() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 350)
    }

    private func performDelete() {
        Task {
            do {
                try await viewModel.deleteSelected()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
