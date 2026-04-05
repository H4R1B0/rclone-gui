import SwiftUI

struct BookmarkPopover: View {
    @Environment(AppState.self) private var appState
    let side: PanelSide
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("bookmark.title")).font(.caption.bold())

            Divider()

            if appState.bookmarks.bookmarks.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "star")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(L10n.t("bookmark.emptyHint"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
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
        .frame(width: 260)
    }
}
