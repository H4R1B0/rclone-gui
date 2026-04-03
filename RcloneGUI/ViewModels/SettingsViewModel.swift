import Foundation
import RcloneKit

struct BwScheduleEntry: Codable, Identifiable {
    let id: UUID
    var startHour: Int   // 0-23
    var endHour: Int     // 0-23
    var rate: String     // e.g., "10M", "off"

    init(startHour: Int = 9, endHour: Int = 18, rate: String = "10M") {
        self.id = UUID()
        self.startHour = startHour
        self.endHour = endHour
        self.rate = rate
    }
}

@Observable
final class SettingsViewModel {
    // Performance
    var transfers: Int = 4
    var checkers: Int = 8
    var multiThreadStreams: Int = 4
    var bufferSize: String = "16M"
    var bwLimit: String = ""

    // Bandwidth schedule
    var bwSchedule: [BwScheduleEntry] = []
    var bwScheduleEnabled: Bool = false

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
    var locale: String = AppConstants.defaultLocale

    private let client: RcloneClientProtocol
    private let settingsURL: URL
    private var saveTask: Task<Void, Never>?
    private var bwScheduleTask: Task<Void, Never>?

    init(client: RcloneClientProtocol) {
        self.client = client
        self.settingsURL = AppConstants.appSupportDir.appendingPathComponent(AppConstants.settingsFile)
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

    /// Schedule a debounced save (2 seconds of inactivity)
    func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .seconds(AppConstants.settingsSaveDebounce))
            guard !Task.isCancelled else { return }
            saveToDisk()
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

    func startBwScheduler() {
        stopBwScheduler()
        bwScheduleTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.applyCurrentBwLimit()
                try? await Task.sleep(for: .seconds(AppConstants.bwSchedulerInterval))
            }
        }
    }

    func stopBwScheduler() {
        bwScheduleTask?.cancel()
        bwScheduleTask = nil
    }

    deinit {
        bwScheduleTask?.cancel()
        saveTask?.cancel()
    }

    @MainActor
    private func applyCurrentBwLimit() async {
        guard bwScheduleEnabled else { return }
        let hour = Calendar.current.component(.hour, from: Date())
        let matchingEntry = bwSchedule.first { entry in
            if entry.startHour <= entry.endHour {
                return hour >= entry.startHour && hour < entry.endHour
            } else {
                return hour >= entry.startHour || hour < entry.endHour
            }
        }
        let rate = matchingEntry?.rate ?? "off"
        try? await RcloneAPI.setBwLimit(using: client, rate: rate)
    }

    func saveToDisk() {
        let scheduleData = (try? JSONEncoder().encode(bwSchedule)) ?? Data()
        let scheduleArray = (try? JSONSerialization.jsonObject(with: scheduleData)) ?? []
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
            "bwSchedule": scheduleArray,
            "bwScheduleEnabled": bwScheduleEnabled,
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
        bwScheduleEnabled = dict["bwScheduleEnabled"] as? Bool ?? false
        if let scheduleArray = dict["bwSchedule"],
           let scheduleData = try? JSONSerialization.data(withJSONObject: scheduleArray),
           let decoded = try? JSONDecoder().decode([BwScheduleEntry].self, from: scheduleData) {
            bwSchedule = decoded
        }
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
