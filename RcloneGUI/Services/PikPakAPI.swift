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
final class PikPakAPI: CloudThumbnailProvider, CloudStreamingProvider {
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
        /// 영상의 미디어 스트림 정보 (스트리밍 URL 추출용)
        let webContentLink: String?
        /// 영상 등에 채워지는 보조 썸네일 — medias[].link.url 또는 첫 번째 미디어
        let mediaThumbnailLink: String?
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
        guard let pikPakFile = await fetchFile(
            remoteName: remoteName,
            filePath: file.path,
            fileName: file.name,
            client: client
        ) else {
            return nil
        }

        // 1순위: 정식 thumbnail_link (이미지 + 일부 영상)
        // 2순위: medias[].link.url (영상 스크린샷 — PikPak이 thumbnail_link 미생성 시)
        let candidates = [pikPakFile.thumbnailLink, pikPakFile.mediaThumbnailLink].compactMap { $0 }
        for s in candidates {
            if let url = URL(string: s), let img = await downloadImage(url: url) {
                return img
            }
        }
        return nil
    }

    // MARK: - CloudStreamingProvider

    func streamingURL(
        for file: FileItem,
        remoteName: String,
        client: RcloneClient
    ) async -> URL? {
        guard let pikPakFile = await fetchFile(
            remoteName: remoteName,
            filePath: file.path,
            fileName: file.name,
            client: client
        ),
        let link = pikPakFile.webContentLink,
        let url = URL(string: link) else {
            return nil
        }
        return url
    }

    // MARK: - File lookup

    /// 폴더 캐시에서 파일 메타데이터를 조회하고, 미스 시 PikPak API로 폴더 전체를 가져와 캐싱.
    private func fetchFile(
        remoteName: String,
        filePath: String,
        fileName: String,
        client: RcloneClient
    ) async -> PikPakFile? {
        let parentPath = (filePath as NSString).deletingLastPathComponent
        let cacheKey = "\(remoteName)/\(parentPath)"

        if let entry = folderCaches[cacheKey], !entry.isExpired,
           let f = entry.files[fileName] {
            return f
        }

        guard let token = await accessToken(remoteName: remoteName, client: client) else {
            log("토큰 추출 실패 — config/get에서 access_token 파싱 못함 (remote: \(remoteName))")
            return nil
        }
        guard let parentId = await resolveFolderId(path: parentPath, token: token) else {
            log("폴더 ID 해석 실패 — path \"\(parentPath)\"의 segment 매칭 실패")
            return nil
        }
        guard let files = await listAllFiles(parentId: parentId, token: token) else {
            log("listAllFiles 실패 (parent_id: \(parentId))")
            return nil
        }

        var map: [String: PikPakFile] = [:]
        for f in files { map[f.name] = f }
        folderCaches[cacheKey] = FolderEntry(files: map, timestamp: Date())

        if map[fileName] == nil {
            log("파일 매칭 실패 — \"\(fileName)\" not in PikPak listing of \"\(parentPath)\" (\(files.count)개)")
        }
        return map[fileName]
    }

    private func log(_ msg: String) {
        #if DEBUG
        print("[PikPakAPI] \(msg)")
        #endif
    }

    // MARK: - OAuth token

    private func accessToken(remoteName: String, client: RcloneClient) async -> String? {
        if let cached = tokenCache[remoteName] {
            return cached
        }
        do {
            let config = try await RcloneAPI.getRemoteConfig(using: client, name: remoteName)
            guard let tokenStr = config["token"] as? String else {
                log("config에 token 필드 없음 (keys: \(config.keys.sorted().joined(separator: ", ")))")
                return nil
            }
            guard let data = tokenStr.data(using: .utf8),
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                log("token 필드가 JSON이 아님")
                return nil
            }
            guard let access = json["access_token"] as? String else {
                log("token JSON에 access_token 없음 (keys: \(json.keys.sorted().joined(separator: ", ")))")
                return nil
            }
            tokenCache[remoteName] = access
            return access
        } catch {
            log("config/get 실패: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Folder ID resolution

    /// 빈 path는 root("*"). 그 외엔 segment별로 listFiles 호출하며 ID 트리 워킹.
    /// PikPak `name eq` filter가 한글·특수문자(대괄호·공백 2개·점 등) 폴더명에서 HTTP 400을
    /// 반환하므로 name filter는 사용하지 않고 클라이언트 측에서 매칭한다.
    private func resolveFolderId(path: String, token: String) async -> String? {
        let segments = path.split(separator: "/").map(String.init).filter { !$0.isEmpty }
        guard !segments.isEmpty else { return "*" }

        var currentId = "*"
        for segment in segments {
            guard let children = await listAllFiles(parentId: currentId, token: token),
                  let match = children.first(where: { $0.name == segment }) else {
                return nil
            }
            currentId = match.id
        }
        return currentId
    }

    // MARK: - HTTP

    /// 폴더 전체를 page_token으로 순회 — 큰 폴더(200+ 항목)도 모두 가져옴.
    private func listAllFiles(parentId: String, token: String) async -> [PikPakFile]? {
        var all: [PikPakFile] = []
        var pageToken: String? = nil
        var iterations = 0
        let maxPages = 20  // 폭주 방지 (page당 500 → 최대 10000개)

        repeat {
            guard let result = await listFilesPage(
                parentId: parentId,
                token: token,
                pageToken: pageToken
            ) else {
                return all.isEmpty ? nil : all
            }
            all.append(contentsOf: result.files)
            pageToken = result.nextPageToken?.isEmpty == false ? result.nextPageToken : nil
            iterations += 1
        } while pageToken != nil && iterations < maxPages

        return all
    }

    private func listFilesPage(
        parentId: String,
        token: String,
        pageToken: String?
    ) async -> (files: [PikPakFile], nextPageToken: String?)? {
        var components = URLComponents(url: baseURL.appendingPathComponent("/drive/v1/files"), resolvingAgainstBaseURL: false)!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "parent_id", value: parentId),
            URLQueryItem(name: "thumbnail_size", value: "SIZE_MEDIUM"),
            URLQueryItem(name: "limit", value: "500"),
            URLQueryItem(name: "filters", value: #"{"trashed":{"eq":false}}"#)
        ]
        if let pageToken, !pageToken.isEmpty {
            items.append(URLQueryItem(name: "page_token", value: pageToken))
        }
        components.queryItems = items
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return nil }
            if http.statusCode == 401 {
                log("401 — access_token 만료/무효, 캐시 비움")
                tokenCache.removeAll()
                return nil
            }
            guard (200..<300).contains(http.statusCode) else {
                let body = String(data: data, encoding: .utf8)?.prefix(200) ?? ""
                log("HTTP \(http.statusCode): \(body)")
                return nil
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let arr = json["files"] as? [[String: Any]] else {
                return nil
            }
            let files: [PikPakFile] = arr.map { dict in
                var mediaThumb: String? = nil
                if let medias = dict["medias"] as? [[String: Any]] {
                    for m in medias {
                        if let link = m["link"] as? [String: Any],
                           let url = link["url"] as? String,
                           !url.isEmpty {
                            mediaThumb = url
                            break
                        }
                    }
                }
                return PikPakFile(
                    id: dict["id"] as? String ?? "",
                    name: dict["name"] as? String ?? "",
                    thumbnailLink: dict["thumbnail_link"] as? String,
                    webContentLink: dict["web_content_link"] as? String,
                    mediaThumbnailLink: mediaThumb
                )
            }
            let next = json["next_page_token"] as? String
            return (files, next)
        } catch {
            log("listFilesPage 예외: \(error.localizedDescription)")
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
