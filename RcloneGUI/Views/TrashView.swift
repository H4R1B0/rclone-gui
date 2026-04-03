import SwiftUI

struct TrashView: View {
    @Environment(AppState.self) private var appState

    private var trash: TrashViewModel { appState.trash }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L10n.t("trash.title")).font(.headline)
                Spacer()
                Text("\(trash.items.count) \(L10n.t("trash.items")) · \(FormatUtils.formatBytes(trash.totalSize))")
                    .font(.caption).foregroundColor(.secondary)
                if !trash.items.isEmpty {
                    Button(L10n.t("trash.emptyAll"), role: .destructive) { trash.clearAll() }
                        .controlSize(.small)
                }
            }
            .padding()

            Divider()

            if trash.items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "trash").font(.system(size: 32)).foregroundColor(.secondary)
                    Text(L10n.t("trash.empty")).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(trash.items) { item in
                        HStack {
                            Image(systemName: "doc").foregroundColor(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name).font(.body)
                                Text("\(item.originalFs)\(item.originalPath)")
                                    .font(.caption).foregroundColor(.secondary)
                                Text(FormatUtils.formatDate(item.trashedAt))
                                    .font(.system(size: 10)).foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(FormatUtils.formatBytes(item.size))
                                .font(.caption).foregroundColor(.secondary)
                            Button(action: { trash.remove(id: item.id) }) {
                                Image(systemName: "xmark.circle").foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
    }
}
