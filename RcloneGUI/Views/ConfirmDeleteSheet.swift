import SwiftUI
import RcloneKit

struct ConfirmDeleteSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let side: PanelSide
    @State private var errorMessage: String?

    private var filesToDelete: [FileItem] {
        let tab = appState.panels.side(side).activeTab
        return tab.files.filter { tab.selectedFiles.contains($0.name) }
    }

    private var isLocal: Bool {
        appState.panels.side(side).activeTab.remote == "/"
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trash")
                .font(.system(size: 40))
                .foregroundColor(.red)

            if filesToDelete.count == 1, let file = filesToDelete.first {
                Text(String(format: L10n.t("delete.title.single"), file.name)).font(.headline)
            } else {
                Text(String(format: L10n.t("delete.title.multi"), filesToDelete.count)).font(.headline)
            }

            Text(isLocal ? L10n.t("delete.moveToTrash") : L10n.t("delete.moveToCloudTrash"))
                .foregroundColor(.secondary).font(.caption)

            if filesToDelete.count <= 10 {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(filesToDelete) { file in
                        HStack(spacing: 4) {
                            Image(systemName: file.isDir ? "folder.fill" : "doc")
                                .font(.caption)
                            Text(file.name).font(.caption).lineLimit(1)
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
                Button(L10n.t("cancel")) { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Button(L10n.t("delete"), role: .destructive) {
                    Task {
                        do {
                            try await appState.panels.deleteSelected(side: side)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 350)
    }
}
