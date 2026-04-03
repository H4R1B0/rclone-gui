import SwiftUI

struct FilePanePathBar: View {
    @Environment(AppState.self) private var appState
    let side: PanelSide
    @State private var isEditing = false
    @State private var editPath = ""
    @State private var showBookmarks = false

    private var tab: TabState { appState.panels.side(side).activeTab }

    var body: some View {
        HStack(spacing: 6) {
            // Up button
            Button(action: { Task { await appState.panels.goUp(side: side) } }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundColor(tab.path.isEmpty ? .secondary.opacity(0.3) : .secondary)
            .disabled(tab.path.isEmpty)
            .help(L10n.t("panel.goUp"))

            // Path
            if isEditing {
                TextField(L10n.t("addressbar.path"), text: $editPath)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(4)
                    .onSubmit {
                        Task { await appState.panels.loadFiles(side: side, path: editPath) }
                        isEditing = false
                    }
                    .onExitCommand { isEditing = false }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        // Root
                        Button(action: {
                            Task { await appState.panels.loadFiles(side: side, path: "") }
                        }) {
                            Image(systemName: tab.mode == .local ? "internaldrive" : "cloud")
                                .font(.system(size: 10))
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)

                        let segments = PathUtils.segments(tab.path)
                        ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                            Image(systemName: "chevron.right")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.secondary.opacity(0.4))

                            Button(segment) {
                                let targetPath = PathUtils.pathUpTo(segments: segments, index: index)
                                Task { await appState.panels.loadFiles(side: side, path: targetPath) }
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 12))
                            .foregroundColor(index == segments.count - 1 ? .primary : .secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    editPath = tab.path
                    isEditing = true
                }
            }

            // Bookmark
            Button(action: { showBookmarks.toggle() }) {
                Image(systemName: "bookmark")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help(L10n.t("bookmark.title"))
            .popover(isPresented: $showBookmarks) {
                BookmarkPopover(side: side, isPresented: $showBookmarks)
            }

            // Refresh
            Button(action: { Task { await appState.panels.refresh(side: side) } }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help(L10n.t("retry"))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial)
    }
}
