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
            // 로컬 파일 — 즉시 재생
            let path = "/\(file.path)"
            player = AVPlayer(url: URL(fileURLWithPath: path))
            isLoading = false
            player?.play()
            return
        }

        // 클라우드 — 1순위: 백엔드 네이티브 스트리밍 URL (PikPak web_content_link 등)
        let remoteName = fs.hasSuffix(":") ? String(fs.dropLast()) : fs
        if !remoteName.isEmpty,
           let remoteType = try? await RcloneAPI.getRemoteType(using: appState.client, name: remoteName),
           let provider = CloudStreamingRegistry.provider(for: remoteType),
           let url = await provider.streamingURL(for: file, remoteName: remoteName, client: appState.client) {
            player = AVPlayer(url: url)
            isLoading = false
            player?.play()
            return
        }

        // 2순위: rclone publicLink — share URL을 반환하는 백엔드들 (interstitial이면 AVPlayer가 실패하고 사용자에게 에러 표시)
        if let link = try? await RcloneAPI.publicLink(using: appState.client, fs: fs, remote: file.path),
           !link.isEmpty,
           let url = URL(string: link) {
            player = AVPlayer(url: url)
            isLoading = false
            player?.play()
            return
        }

        // 3순위 폴백: 임시 다운로드 후 재생 (스트리밍 불가능한 백엔드용)
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent(file.name)
        do {
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
