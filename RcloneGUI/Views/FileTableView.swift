import SwiftUI
import RcloneKit

// NOTE: Full rewrite coming in Task 9 (FileList + ContextMenu + Properties)
// This is a compile-compatible stub that renders the file list from the new PanelViewModel structure.

struct FileTableView: View {
    @Environment(AppState.self) private var appState
    let side: PanelSide

    private var tab: TabState {
        appState.panels.side(side).activeTab
    }

    var body: some View {
        Table(tab.sortedFiles) {
            TableColumn("Name") { file in
                HStack(spacing: 6) {
                    Image(systemName: file.isDir ? "folder.fill" : fileIcon(for: file))
                        .foregroundColor(file.isDir ? .accentColor : .secondary)
                    Text(file.name)
                        .lineLimit(1)
                }
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    guard file.isDir else { return }
                    Task { await appState.panels.navigate(side: side, dirName: file.name) }
                }
            }
            .width(min: 200)

            TableColumn("Size") { file in
                Text(file.isDir ? "--" : formatBytes(file.size))
                    .monospacedDigit()
            }
            .width(min: 80, ideal: 100)

            TableColumn("Modified") { file in
                Text(file.modTime, style: .date)
            }
            .width(min: 100, ideal: 140)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
    }

    private func fileIcon(for file: FileItem) -> String {
        guard let mime = file.mimeType else { return "doc" }
        if mime.hasPrefix("image/") { return "photo" }
        if mime.hasPrefix("video/") { return "film" }
        if mime.hasPrefix("audio/") { return "music.note" }
        if mime.contains("pdf") { return "doc.richtext" }
        if mime.contains("zip") || mime.contains("compressed") { return "doc.zipper" }
        return "doc"
    }

    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
