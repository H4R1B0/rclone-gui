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
                infoRow(L10n.t("properties.name"), file.name)
                infoRow(L10n.t("properties.type"), file.isDir ? L10n.t("properties.folder") : (file.mimeType ?? L10n.t("properties.file")))
                if !file.isDir {
                    infoRow(L10n.t("properties.size"), FormatUtils.formatBytes(file.size))
                }
                infoRow(L10n.t("properties.modified"), FormatUtils.formatDate(file.modTime))
                infoRow(L10n.t("properties.path"), file.path)
                infoRow(L10n.t("properties.remote"), tab.remote)
            }

            // Hash section (file only)
            if !file.isDir {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t("properties.hash"))
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
                Button(L10n.t("close")) { dismiss() }
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
        LabeledContent(label) {
            Text(value)
                .textSelection(.enabled)
        }
    }
}
