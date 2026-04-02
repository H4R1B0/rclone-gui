import SwiftUI

struct BookmarkPopover: View {
    @Environment(AppState.self) private var appState
    let side: PanelSide
    @Binding var isPresented: Bool
    @State private var newName = ""
    @State private var showAdd = false

    private var tab: TabState { appState.panels.side(side).activeTab }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L10n.t("bookmark.title")).font(.caption.bold())
                Spacer()
                Button(action: {
                    newName = PathUtils.fileName(tab.path).isEmpty ? tab.remote : PathUtils.fileName(tab.path)
                    showAdd = true
                }) {
                    Image(systemName: "plus").font(.caption)
                }
                .buttonStyle(.borderless)
                .help(L10n.t("bookmark.add"))
            }

            if showAdd {
                HStack {
                    TextField(L10n.t("properties.name"), text: $newName)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                    Button(L10n.t("save")) {
                        appState.bookmarks.add(name: newName, fs: tab.remote, path: tab.path)
                        showAdd = false
                    }
                    .controlSize(.mini)
                    .disabled(newName.isEmpty)
                }
            }

            Divider()

            if appState.bookmarks.bookmarks.isEmpty {
                Text(L10n.t("bookmark.empty"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(appState.bookmarks.bookmarks) { bookmark in
                    HStack {
                        Button(action: {
                            Task {
                                await appState.panels.navigateTo(side: side, remote: bookmark.fs, path: bookmark.path)
                            }
                            isPresented = false
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: bookmark.fs == "/" ? "folder" : "cloud")
                                    .font(.system(size: 10))
                                VStack(alignment: .leading) {
                                    Text(bookmark.name).font(.caption)
                                    Text(bookmark.displayPath)
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button(action: { appState.bookmarks.remove(id: bookmark.id) }) {
                            Image(systemName: "xmark").font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(12)
        .frame(width: 280)
    }
}
