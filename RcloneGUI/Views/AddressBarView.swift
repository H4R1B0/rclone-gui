import SwiftUI

struct AddressBarView: View {
    @Environment(AppState.self) private var appState
    let side: PanelSide
    @State private var isEditing = false
    @State private var editPath = ""
    @State private var showBookmarks = false

    private var tab: TabState {
        appState.panels.side(side).activeTab
    }

    var body: some View {
        HStack(spacing: 4) {
            // Up button
            Button(action: { Task { await appState.panels.goUp(side: side) } }) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 11))
            }
            .buttonStyle(.borderless)
            .disabled(tab.path.isEmpty)

            // Refresh button
            Button(action: { Task { await appState.panels.refresh(side: side) } }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11))
            }
            .buttonStyle(.borderless)

            // Bookmark button
            Button(action: { showBookmarks.toggle() }) {
                Image(systemName: "bookmark")
                    .font(.system(size: 11))
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $showBookmarks) {
                BookmarkPopover(side: side, isPresented: $showBookmarks)
            }

            // Path display / edit
            if isEditing {
                TextField("Path", text: $editPath)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
                    .onSubmit {
                        Task { await appState.panels.loadFiles(side: side, path: editPath) }
                        isEditing = false
                    }
                    .onExitCommand { isEditing = false }
            } else {
                // Breadcrumb path
                breadcrumbPath
                    .onTapGesture {
                        editPath = tab.path
                        isEditing = true
                    }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private var breadcrumbPath: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                // Root button
                Button(action: {
                    Task { await appState.panels.loadFiles(side: side, path: "") }
                }) {
                    Image(systemName: tab.mode == .local ? "house" : "cloud")
                        .font(.system(size: 11))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)

                let segments = PathUtils.segments(tab.path)
                ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)

                    Button(segment) {
                        let targetPath = PathUtils.pathUpTo(segments: segments, index: index)
                        Task { await appState.panels.loadFiles(side: side, path: targetPath) }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(index == segments.count - 1 ? .primary : .accentColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(4)
        }
    }
}
