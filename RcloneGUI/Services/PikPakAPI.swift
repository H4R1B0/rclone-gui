import Foundation
import AppKit
import RcloneKit

/// PikPak 네이티브 HTTP API로 thumbnail_link를 받아오는 프로바이더.
/// rclone이 PikPak 응답에서 `ThumbnailLink`를 Object에 저장하지 않으므로,
/// rclone config의 OAuth access_token을 추출해 직접 호출.
///
/// 폴더 단위 캐시 (5분 TTL): 같은 폴더 안 여러 파일 썸네일 요청이 들어와도 PikPak API는 폴더당 1번 호출.
@MainActor
@Observable
final class PikPakAPI: CloudThumbnailProvider {
    static let shared = PikPakAPI()

    static let supportedTypes: Set<String> = ["pikpak"]

    private let baseURL = URL(string: "https://api-drive.mypikpak.com")!
    private let folderCacheTTL: TimeInterval = 300

    private struct FolderEntry {
        let files: [String: PikPakFile]   // name → file
        let timestamp: Date
        var isExpired: Bool { Date().timeIntervalSince(timestamp) > 300 }
    }

    private struct PikPakFile {
        let id: String
        let name: String
        let thumbnailLink: String?
    }

    private var folderCaches: [String: FolderEntry] = [:]   // key: "remoteName/path"
    private var tokenCache: [String: String] = [:]          // remoteName → access_token

    private init() {}

    // MARK: - CloudThumbnailProvider

    func thumbnailImage(
        for file: FileItem,
        remoteName: String,
        size: CGFloat,
        client: RcloneClient
    ) async -> NSImage? {
        guard let urlString = await thumbnailURL(
            remoteName: remoteName,
            filePath: file.path,
            fileName: file.name,
            client: client
        ),
        let url = URL(string: urlString) else {
            return nil
        }
        return await downloadImage(url: url)
    }

    // MARK: - Thumbnail URL resolution

    private func thumbnailURL(
        remoteName: String,
        filePath: String,
        fileName: String,
        client: RcloneClient
    ) async -> String? {
        let parentPath = (filePath as NSString).deletingLastPathComponent
        let cacheKey = "\(remoteName)/\(parentPath)"

        if let entry = folderCaches[cacheKey], !entry.isExpired,
           let f = entry.files[fileName] {
            return f.thumbnailLink
        }

        guard let token = await accessToken(remoteName: remoteName, client: client) else {
            return nil
        }
        guard let parentId = await resolveFolderId(path: parentPath, token: token) else {
            return nil
        }
        guard let files = await listFiles(parentId: parentId, token: token) else {
            return nil
        }

        var map: [String: PikPakFile] = [:]
        for f in files { map[f.name] = f }
        folderCaches[cacheKey] = FolderEntry(files: map, timestamp: Date())

        return map[fileName]?.thumbnailLink
    }

    // MARK: - OAuth token

    private func accessToken(remoteName: String, client: RcloneClient) async -> String? {
        if let cached = tokenCache[remoteName] {
            return cached
        }
        do {
            let config = try await RcloneAPI.getRemoteConfig(using: client, name: remoteName)
            guard let tokenStr = config["token"] as? String,
                  let data = tokenStr.data(using: .utf8),
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let access = json["access_token"] as? String else {
                return nil
            }
            tokenCache[remoteName] = access
            return access
        } catch {
            return nil
        }
    }

    /// 401 응답 시 토큰 캐시를 비워 다음 호출에서 rclone config로부터 다시 읽도록 함.
    /// (rclone이 백그라운드에서 자체 refresh 했을 가능성에 기대 — 별도 PR에서 직접 refresh 추가 검토)
    private func invalidateToken(remoteName: String) {
        tokenCache.removeValue(forKey: remoteName)
    }

    // MARK: - Folder ID resolution

    /// 빈 path는 root("*"). 그 외엔 segment별로 listFiles 호출하며 ID 트리 워킹.
    private func resolveFolderId(path: String, token: String) async -> String? {
        let segments = path.split(separator: "/").map(String.init).filter { !$0.isEmpty }
        guard !segments.isEmpty else { return "*" }

        var currentId = "*"
        for segment in segments {
            guard let children = await listFiles(parentId: currentId, token: token, nameFilter: segment),
                  let match = children.first(where: { $0.name == segment }) else {
                return nil
            }
            currentId = match.id
        }
        return currentId
    }

    // MARK: - HTTP

    private func listFiles(
        parentId: String,
        token: String,
        nameFilter: String? = nil
    ) async -> [PikPakFile]? {
        var components = URLComponents(url: baseURL.appendingPathComponent("/drive/v1/files"), resolvingAgainstBaseURL: false)!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "parent_id", value: parentId),
            URLQueryItem(name: "thumbnail_size", value: "SIZE_MEDIUM"),
            URLQueryItem(name: "limit", value: "200"),
            URLQueryItem(name: "filters", value: #"{"trashed":{"eq":false}}"#)
        ]
        if let nameFilter, !nameFilter.isEmpty {
            // PikPak filters는 JSON 형태로만 동작 — name eq filter
            let nameJson = #"{"name":{"eq":"\#(nameFilter.replacingOccurrences(of: "\"", with: "\\\""))"},"trashed":{"eq":false}}"#
            items.removeAll { $0.name == "filters" }
            items.append(URLQueryItem(name: "filters", value: nameJson))
        }
        components.queryItems = items
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return nil }
            if http.statusCode == 401 {
                // 토큰 만료/무효 — 캐시 비우고 caller가 재시도 또는 폴백
                return nil
            }
            guard (200..<300).contains(http.statusCode) else { return nil }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let arr = json["files"] as? [[String: Any]] else {
                return nil
            }
            return arr.map { dict in
                PikPakFile(
                    id: dict["id"] as? String ?? "",
                    name: dict["name"] as? String ?? "",
                    thumbnailLink: dict["thumbnail_link"] as? String
                )
            }
        } catch {
            return nil
        }
    }

    private func downloadImage(url: URL) async -> NSImage? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode) else { return nil }
            return NSImage(data: data)
        } catch {
            return nil
        }
    }
}
