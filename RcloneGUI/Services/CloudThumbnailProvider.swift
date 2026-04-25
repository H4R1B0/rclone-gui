import Foundation
import AppKit
import RcloneKit

/// 클라우드 백엔드의 네이티브 썸네일 API를 통해 NSImage를 반환하는 추상 인터페이스.
/// rclone이 노출하지 않는 thumbnail URL을 직접 호출해 전체 파일 다운로드 없이 미리보기를 얻는다.
@MainActor
protocol CloudThumbnailProvider: AnyObject {
    /// 이 프로바이더가 처리할 수 있는 rclone 백엔드 타입 (예: "pikpak", "drive")
    static var supportedTypes: Set<String> { get }

    /// 지정 파일의 썸네일 이미지. 실패 시 nil — caller가 다운로드 폴백.
    func thumbnailImage(
        for file: FileItem,
        remoteName: String,
        size: CGFloat,
        client: RcloneClient
    ) async -> NSImage?
}

/// 등록된 프로바이더 중 백엔드 타입에 맞는 것을 찾아 반환.
/// 새 프로바이더 추가 시 `providers` 배열에만 등록하면 ThumbnailCache가 자동으로 사용.
@MainActor
enum CloudThumbnailRegistry {
    private static let providers: [CloudThumbnailProvider] = [
        PikPakAPI.shared
    ]

    static func provider(for remoteType: String) -> CloudThumbnailProvider? {
        providers.first { type(of: $0).supportedTypes.contains(remoteType) }
    }
}
