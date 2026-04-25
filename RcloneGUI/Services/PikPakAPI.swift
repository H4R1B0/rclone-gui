import Foundation
import AppKit
import CryptoKit
import RcloneKit

/// PikPak 네이티브 HTTP API로 thumbnail_link / web_content_link를 받아오는 프로바이더.
///
/// rclone PikPak 백엔드와 동일한 호출 형식을 따른다 (필수):
/// - `x-captcha-token`: `/v1/shield/captcha/init`로 사전 발급 (15회 MD5 sign)
/// - `x-client-id`, `x-client-version`, `x-device-id`, `Referer`, `User-Agent`
/// - root 폴더는 `parent_id` 파라미터를 완전히 생략
///
/// 폴더 단위 캐시 (5분 TTL): 같은 폴더 안 여러 파일 썸네일 요청이 들어와도 PikPak API는 폴더당 1번 호출.
@MainActor
@Observable
final class PikPakAPI: CloudThumbnailProvider, CloudStreamingProvider {
    static let shared = PikPakAPI()

    static let supportedTypes: Set<String> = ["pikpak"]

    // rclone backend/pikpak에서 가져온 클라이언트 식별자 (helper.go:67-70)
    private let clientID = "YUMx5nI8ZU8Ap8pm"
    private let clientVersion = "2.0.0"
    private let packageName = "mypikpak.com"
    private let userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:129.0) Gecko/20100101 Firefox/129.0"
    private let referer = "https://mypikpak.com/"

    // 15회 MD5 체인용 salt — rclone helper.go:457-488과 동일
    private let captchaSalts: [String] = [
        "C9qPpZLN8ucRTaTiUMWYS9cQvWOE", "+r6CQVxjzJV6LCV", "F", "pFJRC",
        "9WXYIDGrwTCz2OiVlgZa90qpECPD6olt", "/750aCr4lm/Sly/c", "RB+DT/gZCrbV",
        "", "CyLsf7hdkIRxRm215hl", "7xHvLi2tOYP0Y92b", "ZGTXXxu8E/MIWaEDB+Sm/",
        "1UI3", "E7fP5Pfijd+7K+t6Tg/NhuLq0eEUVChpJSkrKxpO",
        "ihtqpG6FMt65+Xk+tWUH2", "NhXXU9rg4XXdzo7u5o"
    ]

    private let apiBase = URL(string: "https://api-drive.mypikpak.com")!
    private let userBase = URL(string: "https://user.mypikpak.com")!
    private let deviceIDKey = "com.rclone-gui.pikpak.deviceID"

    private struct FolderEntry {
        let files: [String: PikPakFile]
        let timestamp: Date
        var isExpired: Bool { Date().timeIntervalSince(timestamp) > 300 }
    }

    private struct PikPakFile {
        let id: String
        let name: String
        let thumbnailLink: String?
        let webContentLink: String?
        let mediaThumbnailLink: String?
    }

    private struct CaptchaEntry {
        let token: String
        let expiresAt: Date
        var isExpired: Bool { Date() >= expiresAt }
    }

    private var folderCaches: [String: FolderEntry] = [:]
    private var tokenCache: [String: String] = [:]               // remoteName → access_token
    private var userIdCache: [String: String] = [:]              // remoteName → JWT sub
    private var captchaCache: [String: CaptchaEntry] = [:]       // "remoteName|action" → entry

    private init() {}

    // MARK: - CloudThumbnailProvider

    func thumbnailImage(
        for file: FileItem,
        remoteName: String,
        size: CGFloat,
        client: RcloneClient
    ) async -> NSImage? {
        guard let f = await fetchFile(remoteName: remoteName, filePath: file.path, fileName: file.name, client: client) else {
            return nil
        }
        for s in [f.thumbnailLink, f.mediaThumbnailLink].compactMap({ $0 }) {
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
        guard let f = await fetchFile(remoteName: remoteName, filePath: file.path, fileName: file.name, client: client),
              let s = f.webContentLink, let url = URL(string: s) else {
            return nil
        }
        return url
    }

    // MARK: - File lookup

    private func fetchFile(remoteName: String, filePath: String, fileName: String, client: RcloneClient) async -> PikPakFile? {
        let parentPath = (filePath as NSString).deletingLastPathComponent
        let cacheKey = "\(remoteName)/\(parentPath)"

        if let entry = folderCaches[cacheKey], !entry.isExpired, let f = entry.files[fileName] {
            return f
        }

        guard let access = await accessToken(remoteName: remoteName, client: client) else {
            log("access_token 추출 실패 (\(remoteName))")
            return nil
        }
        guard let parentId = await resolveFolderId(remoteName: remoteName, path: parentPath, accessToken: access) else {
            log("폴더 ID 해석 실패: \"\(parentPath)\"")
            return nil
        }
        guard let files = await listAllFiles(remoteName: remoteName, parentId: parentId, accessToken: access) else {
            log("listAllFiles 실패 (parent_id: \(parentId))")
            return nil
        }

        var map: [String: PikPakFile] = [:]
        for f in files { map[f.name] = f }
        folderCaches[cacheKey] = FolderEntry(files: map, timestamp: Date())

        if map[fileName] == nil {
            log("파일 매칭 실패 — \"\(fileName)\" not in \"\(parentPath)\" (\(files.count)개)")
        }
        return map[fileName]
    }

    private func log(_ msg: String) {
        #if DEBUG
        print("[PikPakAPI] \(msg)")
        #endif
    }

    // MARK: - Device ID (앱 설치 시 1회 생성, UserDefaults에 영구 저장)

    private func deviceID() -> String {
        if let existing = UserDefaults.standard.string(forKey: deviceIDKey), !existing.isEmpty {
            return existing
        }
        // 32자 hex (rclone과 동일 형식)
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let hex = bytes.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(hex, forKey: deviceIDKey)
        return hex
    }

    // MARK: - OAuth token + JWT user_id

    private func accessToken(remoteName: String, client: RcloneClient) async -> String? {
        if let cached = tokenCache[remoteName] {
            return cached
        }
        do {
            let config = try await RcloneAPI.getRemoteConfig(using: client, name: remoteName)
            guard let tokenStr = config["token"] as? String else {
                log("config에 token 필드 없음")
                return nil
            }
            guard let data = tokenStr.data(using: .utf8),
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let access = json["access_token"] as? String else {
                log("token JSON 파싱 실패")
                return nil
            }
            tokenCache[remoteName] = access
            if let sub = decodeJwtSub(access) {
                userIdCache[remoteName] = sub
            }
            return access
        } catch {
            log("config/get 실패: \(error.localizedDescription)")
            return nil
        }
    }

    /// JWT의 payload에서 `sub` 클레임을 추출. captcha meta.user_id에 사용.
    private func decodeJwtSub(_ jwt: String) -> String? {
        let parts = jwt.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var payload = String(parts[1])
        // base64url → base64
        payload = payload.replacingOccurrences(of: "-", with: "+")
                         .replacingOccurrences(of: "_", with: "/")
        while payload.count % 4 != 0 { payload += "=" }
        guard let data = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sub = json["sub"] as? String else {
            return nil
        }
        return sub
    }

    // MARK: - Captcha

    private func captchaToken(remoteName: String, action: String, accessToken: String) async -> String? {
        let key = "\(remoteName)|\(action)"
        if let entry = captchaCache[key], !entry.isExpired {
            return entry.token
        }

        let did = deviceID()
        let timestamp = String(Int64(Date().timeIntervalSince1970 * 1000))
        let sign = computeCaptchaSign(deviceID: did, timestamp: timestamp)
        let userId = userIdCache[remoteName] ?? ""

        let body: [String: Any] = [
            "action": action,
            "captcha_token": "",
            "client_id": clientID,
            "device_id": did,
            "meta": [
                "captcha_sign": sign,
                "client_version": clientVersion,
                "package_name": packageName,
                "timestamp": timestamp,
                "user_id": userId
            ]
        ]

        guard let url = URL(string: "/v1/shield/captcha/init", relativeTo: userBase),
              let payload = try? JSONSerialization.data(withJSONObject: body) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        applyDefaultHeaders(&request, accessToken: accessToken, captchaToken: nil)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = payload

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return nil }
            guard (200..<300).contains(http.statusCode) else {
                let bodyStr = String(data: data, encoding: .utf8)?.prefix(300) ?? ""
                log("captcha/init HTTP \(http.statusCode): \(bodyStr)")
                return nil
            }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let token = json["captcha_token"] as? String else {
                log("captcha/init 응답 파싱 실패")
                return nil
            }
            // expires_in은 number 또는 string으로 올 수 있음 — 안전한 캐스트
            let expires: Double
            if let n = json["expires_in"] as? Double { expires = n }
            else if let s = json["expires_in"] as? String, let v = Double(s) { expires = v }
            else { expires = 300 }
            // 안전 마진 30초
            let entry = CaptchaEntry(token: token, expiresAt: Date().addingTimeInterval(max(60, expires - 30)))
            captchaCache[key] = entry
            return token
        } catch {
            log("captcha/init 예외: \(error.localizedDescription)")
            return nil
        }
    }

    /// rclone helper.go:457-488과 동일: clientID+version+package+deviceID+timestamp 시드를 15개 salt로 반복 MD5 → "1."+hex
    private func computeCaptchaSign(deviceID: String, timestamp: String) -> String {
        var str = clientID + clientVersion + packageName + deviceID + timestamp
        for salt in captchaSalts {
            str = md5Hex(str + salt)
        }
        return "1." + str
    }

    private func md5Hex(_ s: String) -> String {
        let digest = Insecure.MD5.hash(data: Data(s.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Folder ID resolution

    private func resolveFolderId(remoteName: String, path: String, accessToken: String) async -> String? {
        let segments = path.split(separator: "/").map(String.init).filter { !$0.isEmpty }
        guard !segments.isEmpty else { return "" }   // root는 빈 문자열 (PikPak 기본값) — listing 시 파라미터 생략

        var currentId = ""   // root에서 시작
        for segment in segments {
            guard let children = await listAllFiles(remoteName: remoteName, parentId: currentId, accessToken: accessToken),
                  let match = children.first(where: { $0.name == segment }) else {
                return nil
            }
            currentId = match.id
        }
        return currentId
    }

    // MARK: - HTTP — file listing

    private func listAllFiles(remoteName: String, parentId: String, accessToken: String) async -> [PikPakFile]? {
        var all: [PikPakFile] = []
        var pageToken: String? = nil
        var iterations = 0
        let maxPages = 20

        repeat {
            guard let result = await listFilesPage(
                remoteName: remoteName,
                parentId: parentId,
                accessToken: accessToken,
                pageToken: pageToken
            ) else {
                return all.isEmpty ? nil : all
            }
            all.append(contentsOf: result.files)
            pageToken = (result.nextPageToken?.isEmpty == false) ? result.nextPageToken : nil
            iterations += 1
        } while pageToken != nil && iterations < maxPages

        return all
    }

    private func listFilesPage(
        remoteName: String,
        parentId: String,
        accessToken: String,
        pageToken: String?
    ) async -> (files: [PikPakFile], nextPageToken: String?)? {
        let action = "GET:/drive/v1/files"
        guard let captcha = await captchaToken(remoteName: remoteName, action: action, accessToken: accessToken) else {
            log("captcha 토큰 발급 실패")
            return nil
        }

        var components = URLComponents(url: apiBase.appendingPathComponent("/drive/v1/files"), resolvingAgainstBaseURL: false)!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "thumbnail_size", value: "SIZE_MEDIUM"),
            URLQueryItem(name: "with_audit", value: "true"),
            URLQueryItem(name: "limit", value: "500"),
            URLQueryItem(name: "filters", value: #"{"phase":{"eq":"PHASE_TYPE_COMPLETE"},"trashed":{"eq":"false"}}"#)
        ]
        // root는 parent_id 파라미터 자체를 생략 (rclone 동작)
        if !parentId.isEmpty {
            items.insert(URLQueryItem(name: "parent_id", value: parentId), at: 0)
        }
        if let pageToken, !pageToken.isEmpty {
            items.append(URLQueryItem(name: "page_token", value: pageToken))
        }
        components.queryItems = items
        guard let url = components.url else { return nil }

        log("GET \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        applyDefaultHeaders(&request, accessToken: accessToken, captchaToken: captcha)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return nil }
            if http.statusCode == 401 {
                log("401 — access_token 만료, 캐시 비움")
                tokenCache.removeAll()
                return nil
            }
            if http.statusCode == 403 || http.statusCode == 9 || http.statusCode == 4002 {
                // captcha 만료/무효 — 캐시 비우고 재시도 가능 (호출자가 다음 호출 시 재발급)
                log("\(http.statusCode) — captcha 무효, 캐시 비움")
                captchaCache.removeAll()
                return nil
            }
            guard (200..<300).contains(http.statusCode) else {
                let body = String(data: data, encoding: .utf8)?.prefix(300) ?? ""
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
                           let u = link["url"] as? String, !u.isEmpty {
                            mediaThumb = u
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

    private func applyDefaultHeaders(_ request: inout URLRequest, accessToken: String, captchaToken: String?) {
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(clientID, forHTTPHeaderField: "x-client-id")
        request.setValue(clientVersion, forHTTPHeaderField: "x-client-version")
        request.setValue(deviceID(), forHTTPHeaderField: "x-device-id")
        request.setValue(referer, forHTTPHeaderField: "Referer")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        if let captchaToken {
            request.setValue(captchaToken, forHTTPHeaderField: "x-captcha-token")
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
