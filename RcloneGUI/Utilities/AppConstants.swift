import Foundation

enum AppConstants {
    // MARK: - App Identity

    static let appName = "RcloneGUI"

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    static let defaultLocale = "ko"

    // MARK: - Keychain

    static let keychainService = "com.rclone-gui.applock"
    static let keychainAccount = "password"
    static let spotlightDomainID = "com.rclone-gui.files"

    // MARK: - Data Files

    static let settingsFile = "settings.json"
    static let bookmarksFile = "bookmarks.json"
    static let schedulerFile = "scheduler.json"
    static let schedulerLogsFile = "scheduler-logs.json"
    static let syncProfilesFile = "sync-profiles.json"
    static let trashFile = "trash.json"
    static let transferCheckpointsFile = "transfer-checkpoints.json"
    static let appLockConfigFile = "app-lock-config.json"
    static let remoteOrderFile = "remote-order.json"

    /// Application Support/RcloneGUI 디렉토리 — 생성 보장
    static let appSupportDir: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent(appName)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    // MARK: - Polling & Timing (seconds)

    static let transferPollingInterval: Double = 1
    static let schedulerMonitoringInterval: Double = 60
    static let settingsSaveDebounce: Double = 2
    static let bwSchedulerInterval: Double = 60
    static let remoteCacheTTL: TimeInterval = 30

    // MARK: - Limits

    static let maxTransferRetries = 3
    static let maxSchedulerLogs = 500
    static let maxTrashItems = 500
    static let maxErrorHistory = 100
    static let maxCompletedTransfers = 200
    static let maxSearchConcurrency = 5
    static let maxSpotlightItems = 1000
    static let defaultConcurrentTransfers = 4
    static let defaultMultiThreadStreams = 4
}
