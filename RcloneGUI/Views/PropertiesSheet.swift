import SwiftUI
import RcloneKit

struct PropertiesSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let file: FileItem
    let side: PanelSide

    @State private var hashes: [String: String] = [:]
    @State private var hashLoading = false

    private var tab: TabState {
        appState.panels.side(side).activeTab
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: FormatUtils.fileIcon(name: file.name, isDir: file.isDir))
                    .font(.system(size: 24))
                    .foregroundColor(file.isDir ? .accentColor : .secondary)
                Text(file.name)
                    .font(.headline)
                Spacer()
            }

            Divider()

            // Basic info
            VStack(alignment: .leading, spacing: 8) {
                infoRow("Name", file.name)
                infoRow("Type", file.isDir ? "Folder" : (file.mimeType ?? "File"))
                if !file.isDir {
                    infoRow("Size", FormatUtils.formatBytes(file.size))
                }
                infoRow("Modified", FormatUtils.formatDate(file.modTime))
                infoRow("Path", file.path)
                infoRow("Remote", tab.remote)
            }

            // Hash section (file only)
            if !file.isDir {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Hash")
                        .font(.subheadline.bold())

                    if hashLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        infoRow("MD5", hashes["md5"] ?? "\u{2014}")
                        infoRow("SHA1", hashes["sha1"] ?? "\u{2014}")
                    }
                }
            }

            Divider()

            HStack {
                Spacer()
                Button("Close") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(20)
        .frame(width: 450)
        .task {
            if !file.isDir {
                hashLoading = true
                hashes = (try? await RcloneAPI.hashFile(
                    using: appState.client,
                    fs: tab.remote,
                    remote: file.path
                )) ?? [:]
                hashLoading = false
            }
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .trailing)
            Text(value)
                .font(.caption)
                .textSelection(.enabled)
        }
    }
}
