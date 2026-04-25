import SwiftUI
import RcloneKit

/// 이미지·동영상 파일의 썸네일을 lazy-load 하는 재사용 뷰.
/// 캐시 히트 시 즉시, 미스 시 SF Symbol 폴백 후 비동기로 교체.
struct ThumbnailImageView: View {
    let file: FileItem
    let fs: String
    let size: CGFloat
    let cornerRadius: CGFloat

    @Environment(AppState.self) private var appState
    @State private var image: NSImage?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                Image(systemName: FormatUtils.fileIcon(name: file.name, isDir: file.isDir))
                    .font(.system(size: size * 0.5))
                    .foregroundColor(.secondary)
                    .frame(width: size, height: size)
            }
        }
        .task(id: cacheTaskID) {
            guard image == nil, !loadFailed else { return }
            let result = await ThumbnailCache.shared.thumbnail(
                for: file,
                fs: fs,
                client: appState.client,
                size: size
            )
            if let result {
                image = result
            } else {
                loadFailed = true
            }
        }
    }

    /// 파일이 바뀌면 다시 로딩
    private var cacheTaskID: String {
        "\(fs)|\(file.path)|\(file.size)|\(Int(file.modTime.timeIntervalSince1970))"
    }
}
