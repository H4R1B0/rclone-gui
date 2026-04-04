import SwiftUI
import RcloneKit

struct FinderUploadSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let urls: [URL]

    @State private var selectedRemote = ""
    @State private var destPath = ""
    @State private var isUploading = false

    var body: some View {
        VStack(spacing: 16) {
            Text(L10n.t("finder.uploadTitle"))
                .font(.headline)

            Text(String(format: L10n.t("finder.fileCount"), urls.count))
                .font(.caption)
                .foregroundColor(.secondary)

            Form {
                Picker(L10n.t("sync.remote"), selection: $selectedRemote) {
                    Text("--").tag("")
                    ForEach(appState.accounts.remotes) { remote in
                        Label(remote.displayName, systemImage: "cloud")
                            .tag("\(remote.name):")
                    }
                }

                TextField(L10n.t("properties.path"), text: $destPath)
            }
            .formStyle(.grouped)

            if isUploading {
                ProgressView(L10n.t("finder.uploading"))
            }

            HStack {
                Button(L10n.t("cancel")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(L10n.t("finder.upload")) { upload() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(selectedRemote.isEmpty || isUploading)
            }
        }
        .padding(20)
        .frame(width: 400)
    }

    private func upload() {
        isUploading = true
        Task {
            let remote = selectedRemote
            let dest = destPath
            let c = appState.client
            let maxConcurrent = appState.settings.transfers
            let mts = appState.settings.multiThreadStreams
            await withTaskGroup(of: Void.self) { group in
                var running = 0
                for url in urls {
                    if running >= maxConcurrent {
                        await group.next()
                        running -= 1
                    }
                    let fileName = url.lastPathComponent
                    let srcPath = url.path
                    let dstRemote = dest.isEmpty ? fileName : "\(dest)/\(fileName)"
                    group.addTask {
                        _ = try? await RcloneAPI.copyFileAsync(
                            using: c,
                            srcFs: "/", srcRemote: srcPath,
                            dstFs: remote, dstRemote: dstRemote,
                            multiThreadStreams: mts
                        )
                    }
                    running += 1
                }
            }
            isUploading = false
            dismiss()
        }
    }
}
