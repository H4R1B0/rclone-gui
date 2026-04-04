import SwiftUI

struct TrashView: View {
    @Environment(AppState.self) private var appState

    private var trash: TrashViewModel { appState.trash }

    @State private var showEmptyConfirm = false
    @State private var errorMessage: String?

    private var groupedItems: [(String, [TrashedFile])] {
        let groups = Dictionary(grouping: trash.items, by: \.originalFs)
        return groups.sorted { $0.key < $1.key }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L10n.t("trash.title")).font(.headline)
                Spacer()
                Text(L10n.t("trash.itemCount", String(trash.items.count)))
                    .font(.caption).foregroundColor(.secondary)
                if !trash.items.isEmpty {
                    Button(L10n.t("trash.empty"), role: .destructive) {
                        showEmptyConfirm = true
                    }
                    .controlSize(.small)
                }
            }
            .padding()

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }

            Divider()

            if trash.items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "trash")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text(L10n.t("trash.emptyState"))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(groupedItems, id: \.0) { fs, items in
                        Section(fs) {
                            ForEach(items) { item in
                                TrashItemRow(item: item) { action in
                                    handleAction(action, item: item)
                                }
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .alert(L10n.t("trash.empty"), isPresented: $showEmptyConfirm) {
            Button(L10n.t("trash.empty"), role: .destructive) {
                Task {
                    do {
                        try await trash.emptyTrash()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
            Button(L10n.t("cancel"), role: .cancel) {}
        } message: {
            Text(L10n.t("trash.confirmEmpty"))
        }
    }

    private func handleAction(_ action: TrashItemAction, item: TrashedFile) {
        Task {
            do {
                switch action {
                case .restore:
                    try await trash.restore(item)
                case .permanentDelete:
                    try await trash.permanentDelete(item)
                }
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

enum TrashItemAction {
    case restore
    case permanentDelete
}

struct TrashItemRow: View {
    let item: TrashedFile
    let onAction: (TrashItemAction) -> Void

    @State private var showDeleteConfirm = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: item.isDir ? "folder.fill" : "doc")
                .foregroundColor(item.isDir ? .yellow : .secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.body).lineLimit(1)
                Text(item.originalPath)
                    .font(.caption).foregroundColor(.secondary).lineLimit(1)
                Text(FormatUtils.formatDate(item.trashedAt))
                    .font(.system(size: 10)).foregroundColor(.secondary)
            }

            Spacer()

            Text(FormatUtils.formatBytes(item.size))
                .font(.caption).foregroundColor(.secondary)

            Button {
                onAction(.restore)
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .buttonStyle(.plain)
            .help(L10n.t("trash.restore"))

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash.slash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .help(L10n.t("trash.permanentDelete"))
        }
        .alert(L10n.t("trash.permanentDelete"), isPresented: $showDeleteConfirm) {
            Button(L10n.t("trash.permanentDelete"), role: .destructive) {
                onAction(.permanentDelete)
            }
            Button(L10n.t("cancel"), role: .cancel) {}
        } message: {
            Text(L10n.t("confirm.delete.message", item.name))
        }
    }
}
