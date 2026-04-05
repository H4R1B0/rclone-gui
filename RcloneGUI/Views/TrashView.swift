import SwiftUI

struct TrashView: View {
    @Environment(AppState.self) private var appState

    private var trash: TrashViewModel { appState.trash }

    @State private var showEmptyConfirm = false
    @State private var emptyTarget: String? // nil = all, "/" = local, "remote:" = specific cloud
    @State private var errorMessage: String?

    private var localItems: [TrashedFile] {
        trash.items.filter { $0.originalFs == "/" }
    }

    private var cloudGrouped: [(String, [TrashedFile])] {
        let cloudItems = trash.items.filter { $0.originalFs != "/" }
        let groups = Dictionary(grouping: cloudItems, by: \.originalFs)
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
                    Button(L10n.t("trash.emptyAll"), role: .destructive) {
                        emptyTarget = nil
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
                ContentUnavailableView(
                    L10n.t("trash.emptyState"),
                    systemImage: "trash"
                )
            } else {
                List {
                    // Local trash section
                    if !localItems.isEmpty {
                        Section {
                            ForEach(localItems) { item in
                                TrashItemRow(item: item) { action in
                                    handleAction(action, item: item)
                                }
                            }
                        } header: {
                            HStack {
                                Image(systemName: "laptopcomputer")
                                Text(L10n.t("trash.local"))
                                    .font(.system(size: 12, weight: .semibold))
                                Text("(\(localItems.count))")
                                    .font(.caption).foregroundColor(.secondary)
                                Spacer()
                                Button(L10n.t("trash.emptySection"), role: .destructive) {
                                    emptyTarget = "/"
                                    showEmptyConfirm = true
                                }
                                .font(.caption)
                                .controlSize(.mini)
                            }
                        }
                    }

                    // Cloud trash sections (grouped by remote)
                    if !cloudGrouped.isEmpty {
                        ForEach(cloudGrouped, id: \.0) { fs, items in
                            Section {
                                ForEach(items) { item in
                                    TrashItemRow(item: item) { action in
                                        handleAction(action, item: item)
                                    }
                                }
                            } header: {
                                HStack {
                                    Image(systemName: "cloud")
                                    Text(fs.replacingOccurrences(of: ":", with: ""))
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("(\(items.count))")
                                        .font(.caption).foregroundColor(.secondary)
                                    Spacer()
                                    Button(L10n.t("trash.emptySection"), role: .destructive) {
                                        emptyTarget = fs
                                        showEmptyConfirm = true
                                    }
                                    .font(.caption)
                                    .controlSize(.mini)
                                }
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .confirmationDialog(L10n.t("trash.emptyAll"), isPresented: $showEmptyConfirm) {
            Button(L10n.t("trash.emptyAll"), role: .destructive) {
                Task {
                    do {
                        try await trash.emptyTrash(fs: emptyTarget)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
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
        .confirmationDialog(L10n.t("trash.permanentDelete"), isPresented: $showDeleteConfirm) {
            Button(L10n.t("trash.permanentDelete"), role: .destructive) {
                onAction(.permanentDelete)
            }
        } message: {
            Text(L10n.t("confirm.delete.message", item.name))
        }
    }
}
