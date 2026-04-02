import SwiftUI
import RcloneKit

struct FileTableView: View {
    @Bindable var viewModel: PanelViewModel

    var body: some View {
        Table(viewModel.files, selection: $viewModel.selectedFileIDs) {
            TableColumn("Name") { file in
                HStack(spacing: 6) {
                    Image(systemName: file.isDir ? "folder.fill" : fileIcon(for: file))
                        .foregroundColor(file.isDir ? .accentColor : .secondary)
                    Text(file.name)
                        .lineLimit(1)
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
        .contextMenu(forSelectionType: String.self) { ids in
            // Context menu will be implemented in Task 10
            Button("Open") {
                guard let id = ids.first,
                      let file = viewModel.files.first(where: { $0.id == id }),
                      file.isDir else { return }
                Task { await viewModel.navigateInto(file) }
            }
            Divider()
            Button("Delete", role: .destructive) {
                viewModel.selectedFileIDs = ids
            }
        } primaryAction: { ids in
            guard let id = ids.first,
                  let file = viewModel.files.first(where: { $0.id == id }),
                  file.isDir else { return }
            Task { await viewModel.navigateInto(file) }
        }
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
