import Foundation
import AppKit
import QuickLookThumbnailing
import CryptoKit
import RcloneKit

/// 이미지/동영상 썸네일을 메모리·디스크 LRU 캐시로 관리.
/// 로컬 파일은 QLThumbnailGenerator로 즉시 생성하고,
/// 클라우드 파일은 임시 다운로드 후 동일 경로로 생성한다.
@MainActor
@Observable
final class ThumbnailCache {
    static let shared = ThumbnailCache()

    private var memoryCache: [String: NSImage] = [:]
    private var memoryOrder: [String] = []
    private var inflight: [String: Task<NSImage?, Never>] = [:]

    private init() {}

    // MARK: - Public API

    /// 썸네일을 비동기로 반환. 캐시 히트 시 즉시 반환.
    func thumbnail(
        for file: FileItem,
        fs: String,
        client: RcloneClient,
        size: CGFloat = AppConstants.thumbnailDefaultSize
    ) async -> NSImage? {
        let key = cacheKey(file: file, fs: fs, size: size)

        if let img = memoryCache[key] {
            touchLRU(key)
            return img
        }

        if let existing = inflight[key] {
            return await existing.value
        }

        let task = Task<NSImage?, Never> { [file, fs, size, key] in
            // 디스크 캐시 확인
            let url = ThumbnailCache.diskURL(for: key)
            if FileManager.default.fileExists(atPath: url.path),
               let img = NSImage(contentsOf: url) {
                self.storeMemory(key: key, image: img)
                self.inflight[key] = nil
                return img
            }

            // 새로 생성
            guard let img = await self.generate(file: file, fs: fs, client: client, size: size) else {
                self.inflight[key] = nil
                return nil
            }

            self.saveDisk(image: img, url: url)
            self.storeMemory(key: key, image: img)
            self.inflight[key] = nil
            return img
        }

        inflight[key] = task
        return await task.value
    }

    /// 메모리 + 디스크 캐시 전체 삭제
    func clearAll() {
        memoryCache.removeAll()
        memoryOrder.removeAll()
        for task in inflight.values { task.cancel() }
        inflight.removeAll()

        let dir = AppConstants.thumbnailCacheDir
        if let items = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
            for url in items {
                try? FileManager.default.removeItem(at: url)
            }
        }
        // 작업 디렉토리도 청소
        if let items = try? FileManager.default.contentsOfDirectory(at: AppConstants.thumbnailWorkDir, includingPropertiesForKeys: nil) {
            for url in items {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    /// 디스크에 저장된 썸네일 합산 크기 (바이트)
    nonisolated func diskSizeBytes() -> Int64 {
        let dir = AppConstants.thumbnailCacheDir
        guard let enumerator = FileManager.default.enumerator(
            at: dir,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var total: Int64 = 0
        for case let url as URL in enumerator {
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            total += Int64(size)
        }
        return total
    }

    // MARK: - Generation

    private func generate(
        file: FileItem,
        fs: String,
        client: RcloneClient,
        size: CGFloat
    ) async -> NSImage? {
        // 로컬 파일: 직접 QL
        if fs == "/" {
            let path = file.path.hasPrefix("/") ? file.path : "/\(file.path)"
            return await Self.generateThumbnail(url: URL(fileURLWithPath: path), size: size)
        }

        // 클라우드 파일: 미디어 종류별 크기 제한 검사 후 임시 다운로드
        let cap = Self.maxSourceBytes(for: file.name)
        guard file.size > 0, file.size <= cap else {
            return nil
        }

        let tempName = UUID().uuidString + "-" + file.name
        let tempFile = AppConstants.thumbnailWorkDir.appendingPathComponent(tempName)
        try? FileManager.default.createDirectory(
            at: AppConstants.thumbnailWorkDir,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: tempFile) }

        do {
            let jobId = try await RcloneAPI.copyFileAsync(
                using: client,
                srcFs: fs, srcRemote: file.path,
                dstFs: "/", dstRemote: tempFile.path
            )
            try await RcloneAPI.waitForJob(
                using: client,
                jobid: jobId,
                pollInterval: 0.3,
                timeout: 60
            )
            return await Self.generateThumbnail(url: tempFile, size: size)
        } catch {
            return nil
        }
    }

    /// 확장자 기반으로 다운로드 허용 크기 결정 — 영상은 첫 프레임 추출 위해 더 큰 캡 적용
    private static func maxSourceBytes(for name: String) -> Int64 {
        let ext = (name as NSString).pathExtension.lowercased()
        let videoExts: Set<String> = ["mp4", "mkv", "avi", "mov", "webm", "flv", "wmv", "m4v"]
        return videoExts.contains(ext)
            ? AppConstants.thumbnailMaxVideoBytes
            : AppConstants.thumbnailMaxImageBytes
    }

    private static func generateThumbnail(url: URL, size: CGFloat) async -> NSImage? {
        let scale = await MainActor.run { NSScreen.main?.backingScaleFactor ?? 2.0 }
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: CGSize(width: size, height: size),
            scale: scale,
            representationTypes: [.thumbnail, .lowQualityThumbnail]
        )
        return await withCheckedContinuation { (cont: CheckedContinuation<NSImage?, Never>) in
            QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { rep, _ in
                cont.resume(returning: rep?.nsImage)
            }
        }
    }

    // MARK: - Cache key & storage

    private func cacheKey(file: FileItem, fs: String, size: CGFloat) -> String {
        let raw = "\(fs)|\(file.path)|\(file.size)|\(Int(file.modTime.timeIntervalSince1970))|\(Int(size))"
        let digest = SHA256.hash(data: Data(raw.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func diskURL(for key: String) -> URL {
        AppConstants.thumbnailCacheDir.appendingPathComponent("\(key).png")
    }

    private func storeMemory(key: String, image: NSImage) {
        if memoryCache[key] == nil {
            memoryOrder.append(key)
            while memoryOrder.count > AppConstants.thumbnailMemoryLimit {
                let evict = memoryOrder.removeFirst()
                memoryCache.removeValue(forKey: evict)
            }
        }
        memoryCache[key] = image
    }

    private func touchLRU(_ key: String) {
        if let idx = memoryOrder.firstIndex(of: key) {
            memoryOrder.remove(at: idx)
            memoryOrder.append(key)
        }
    }

    private func saveDisk(image: NSImage, url: URL) {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:])
        else { return }
        try? FileManager.default.createDirectory(
            at: AppConstants.thumbnailCacheDir,
            withIntermediateDirectories: true
        )
        try? png.write(to: url)
    }
}
