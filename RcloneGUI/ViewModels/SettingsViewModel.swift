import Foundation
import RcloneKit

@Observable
final class SettingsViewModel {
    // Performance
    var transfers: Int = 4
    var checkers: Int = 8
    var multiThreadStreams: Int = 4
    var bufferSize: String = "16M"
    var bwLimit: String = ""

    // Reliability
    var retries: Int = 3
    var lowLevelRetries: Int = 10
    var contimeout: String = "60s"
    var timeout: String = "300s"

    // Behavior
    var userAgent: String = ""
    var noCheckCertificate: Bool = false
    var ignoreExisting: Bool = false
    var ignoreSize: Bool = false
    var noTraverse: Bool = false
    var noUpdateModTime: Bool = false

    // Language — 한국어 기본
    var locale: String = "ko"

    private let client: RcloneClientProtocol
    private let settingsURL: URL

    init(client: RcloneClientProtocol) {
        self.client = client
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("RcloneGUI")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        self.settingsURL = appDir.appendingPathComponent("settings.json")
        loadFromDisk()
    }

    func applyToRclone() async {
        let opts: [String: Any] = [
            "main": [
                "Transfers": transfers,
                "Checkers": checkers,
                "MultiThreadStreams": multiThreadStreams,
                "BufferSize": parseSizeToBytes(bufferSize),
                "Retries": retries,
                "LowLevelRetries": lowLevelRetries,
                "Timeout": parseDurationToNs(timeout),
                "ConnectTimeout": parseDurationToNs(contimeout),
                "UserAgent": userAgent,
                "InsecureSkipVerify": noCheckCertificate,
                "IgnoreExisting": ignoreExisting,
                "IgnoreSize": ignoreSize,
                "NoTraverse": noTraverse,
                "NoUpdateModTime": noUpdateModTime,
            ]
        ]
        _ = try? await client.call("options/set", params: opts)

        if !bwLimit.isEmpty {
            try? await RcloneAPI.setBwLimit(using: client, rate: bwLimit)
        }
    }

    func resetToDefaults() {
        transfers = 4; checkers = 8; multiThreadStreams = 4
        bufferSize = "16M"; bwLimit = ""
        retries = 3; lowLevelRetries = 10
        contimeout = "60s"; timeout = "300s"
        userAgent = ""; noCheckCertificate = false
        ignoreExisting = false; ignoreSize = false
        noTraverse = false; noUpdateModTime = false
    }

    func saveToDisk() {
        let dict: [String: Any] = [
            "transfers": transfers, "checkers": checkers,
            "multiThreadStreams": multiThreadStreams,
            "bufferSize": bufferSize, "bwLimit": bwLimit,
            "retries": retries, "lowLevelRetries": lowLevelRetries,
            "contimeout": contimeout, "timeout": timeout,
            "userAgent": userAgent, "noCheckCertificate": noCheckCertificate,
            "ignoreExisting": ignoreExisting, "ignoreSize": ignoreSize,
            "noTraverse": noTraverse, "noUpdateModTime": noUpdateModTime,
            "locale": locale,
        ]
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
            try? data.write(to: settingsURL)
        }
    }

    func loadFromDisk() {
        guard let data = try? Data(contentsOf: settingsURL),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }

        transfers = dict["transfers"] as? Int ?? 4
        checkers = dict["checkers"] as? Int ?? 8
        multiThreadStreams = dict["multiThreadStreams"] as? Int ?? 4
        bufferSize = dict["bufferSize"] as? String ?? "16M"
        bwLimit = dict["bwLimit"] as? String ?? ""
        retries = dict["retries"] as? Int ?? 3
        lowLevelRetries = dict["lowLevelRetries"] as? Int ?? 10
        contimeout = dict["contimeout"] as? String ?? "60s"
        timeout = dict["timeout"] as? String ?? "300s"
        userAgent = dict["userAgent"] as? String ?? ""
        noCheckCertificate = dict["noCheckCertificate"] as? Bool ?? false
        ignoreExisting = dict["ignoreExisting"] as? Bool ?? false
        ignoreSize = dict["ignoreSize"] as? Bool ?? false
        noTraverse = dict["noTraverse"] as? Bool ?? false
        noUpdateModTime = dict["noUpdateModTime"] as? Bool ?? false
        locale = dict["locale"] as? String ?? "ko"
    }

    private func parseSizeToBytes(_ s: String) -> Int64 {
        let str = s.trimmingCharacters(in: .whitespaces).uppercased()
        let mults: [Character: Int64] = ["K": 1024, "M": 1024*1024, "G": 1024*1024*1024]
        guard let last = str.last, let m = mults[last] else { return Int64(str) ?? 0 }
        return (Int64(String(str.dropLast())) ?? 0) * m
    }

    private func parseDurationToNs(_ s: String) -> Int64 {
        let str = s.trimmingCharacters(in: .whitespaces).lowercased()
        if str.hasSuffix("m") { return (Int64(Double(String(str.dropLast())) ?? 0)) * 60_000_000_000 }
        if str.hasSuffix("s") { return (Int64(Double(String(str.dropLast())) ?? 0)) * 1_000_000_000 }
        return (Int64(str) ?? 0) * 1_000_000_000
    }
}
