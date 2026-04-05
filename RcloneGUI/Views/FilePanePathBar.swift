import SwiftUI

struct FilePanePathBar: View {
    @Environment(AppState.self) private var appState
    let side: PanelSide
    @State private var isEditing = false
    @State private var editPath = ""
    @FocusState private var isFieldFocused: Bool

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
                    .focused($isFieldFocused)
                    .onSubmit {
                        Task { await appState.panels.loadFiles(side: side, path: editPath) }
                        isEditing = false
                    }
                    .onExitCommand { isEditing = false }
                    .onChange(of: isFieldFocused) {
                        if !isFieldFocused { isEditing = false }
                    }
                    .onAppear { isFieldFocused = true }
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

                        let isAbsolute = tab.path.hasPrefix("/")
                        let segments = PathUtils.segments(tab.path)
                        ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.secondary.opacity(0.4))

                            Button(segment) {
                                let targetPath = PathUtils.pathUpTo(segments: segments, index: index, absolute: isAbsolute)
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
                    editPath = tab.mode == .local && !tab.path.hasPrefix("/") && !tab.path.isEmpty
                        ? "/\(tab.path)" : tab.path
                    isEditing = true
                }
            }

            // Bookmark star (one-click toggle)
            Button(action: {
                appState.bookmarks.toggle(fs: tab.remote, path: tab.path)
            }) {
                Image(systemName: appState.bookmarks.isBookmarked(fs: tab.remote, path: tab.path) ? "star.fill" : "star")
                    .font(.system(size: 11))
                    .foregroundColor(appState.bookmarks.isBookmarked(fs: tab.remote, path: tab.path) ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
            .help(appState.bookmarks.isBookmarked(fs: tab.remote, path: tab.path)
                  ? L10n.t("bookmark.remove") : L10n.t("bookmark.add"))

            // View mode toggle
            Button(action: {
                let sideState = appState.panels.side(side)
                sideState.viewMode = sideState.viewMode == .list ? .grid : .list
            }) {
                Image(systemName: appState.panels.side(side).viewMode == .list ? "list.bullet" : "square.grid.2x2")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help(appState.panels.side(side).viewMode == .list ? L10n.t("viewMode.grid") : L10n.t("viewMode.list"))

            // Refresh
            Button(action: { Task { await appState.panels.refresh(side: side) } }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help(L10n.t("retry"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .onChange(of: tab.path) {
            isEditing = false
        }
        .onChange(of: appState.panels.activePanel) {
            isEditing = false
        }
    }
}
