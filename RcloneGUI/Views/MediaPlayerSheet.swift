import SwiftUI
import AVKit
import RcloneKit

struct MediaPlayerSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let file: FileItem
    let fs: String

    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(file.name).font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            if isLoading {
                VStack(spacing: 8) {
                    ProgressView()
                    Text(L10n.t("media.loading"))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = error {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text(error)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let player = player {
                VideoPlayer(player: player)
            }
        }
        .frame(width: 700, height: 500)
        .task { await loadMedia() }
        .onDisappear { player?.pause() }
    }

    private func loadMedia() async {
        if fs == "/" {
            // Local file — play directly
            let path = "/\(file.path)"
            let url = URL(fileURLWithPath: path)
            player = AVPlayer(url: url)
            isLoading = false
            player?.play()
        } else {
            // Cloud file — download to temp, then play
            let tempDir = FileManager.default.temporaryDirectory
            let tempFile = tempDir.appendingPathComponent(file.name)

            do {
                // Use rclone to copy to local temp
                try await RcloneAPI.copyFile(
                    using: appState.client,
                    srcFs: fs, srcRemote: file.path,
                    dstFs: "/", dstRemote: tempFile.path
                )

                player = AVPlayer(url: tempFile)
                isLoading = false
                player?.play()
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }
}
