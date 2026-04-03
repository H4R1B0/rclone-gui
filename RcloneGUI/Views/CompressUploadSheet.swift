import SwiftUI

struct CompressUploadSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let side: PanelSide

    @State private var archiveName = "archive"
    @State private var isCompressing = false
    @State private var error: String?

    private var tab: TabState { appState.panels.side(side).activeTab }
    private var selectedFiles: [FileItem] { tab.files.filter { tab.selectedFiles.contains($0.name) } }

    var body: some View {
        VStack(spacing: 16) {
            Text(L10n.t("compress.title")).font(.headline)

            HStack {
                TextField(L10n.t("compress.archiveName"), text: $archiveName)
                    .textFieldStyle(.roundedBorder)
                Text(".zip")
                    .foregroundColor(.secondary)
            }

            Text(String(format: L10n.t("compress.fileCount"), selectedFiles.count))
                .font(.caption).foregroundColor(.secondary)

            if isCompressing {
                ProgressView(L10n.t("compress.compressing"))
            }

            if let error = error {
                Text(error).foregroundColor(.red).font(.caption)
            }

            HStack {
                Button(L10n.t("cancel")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(L10n.t("compress.compressUpload")) { compress() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(archiveName.isEmpty || isCompressing || tab.remote != "/")
            }

            if tab.remote != "/" {
                Text(L10n.t("compress.localOnly"))
                    .font(.caption).foregroundColor(.orange)
            }
        }
        .padding(20)
        .frame(width: 350)
    }

    private func compress() {
        guard tab.remote == "/" else { return }  // Only local files
        isCompressing = true
        error = nil

        Task {
            do {
                let basePath = tab.path.isEmpty ? "" : "/\(tab.path)"
                let zipPath = "\(basePath)/\(archiveName).zip"
                _ = zipPath  // computed for reference; zip writes to cwd

                // Use Process to run zip command
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
                process.currentDirectoryURL = URL(fileURLWithPath: basePath.isEmpty ? "/" : basePath)
                process.arguments = ["-r", "\(archiveName).zip"] + selectedFiles.map(\.name)

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe

                try process.run()
                process.waitUntilExit()

                if process.terminationStatus == 0 {
                    await appState.panels.refresh(side: side)
                    dismiss()
                } else {
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    error = String(data: data, encoding: .utf8) ?? "Compression failed"
                }
            } catch {
                self.error = error.localizedDescription
            }
            isCompressing = false
        }
    }
}
