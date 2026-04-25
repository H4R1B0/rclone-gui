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

    /// 클라우드 파일 임시 다운로드 디렉토리 — 앱 종료 시 삭제
    static let tempDownloadDir: URL = {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("RcloneGUI")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    /// Application Support/RcloneGUI 디렉토리 — 생성 보장
    static let appSupportDir: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent(appName)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    /// Caches/RcloneGUI/thumbnails — 영구 썸네일 캐시 (사용자가 수동으로 지움)
    static let thumbnailCacheDir: URL = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = caches.appendingPathComponent(appName).appendingPathComponent("thumbnails")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    /// 썸네일 생성 시 임시 다운로드 디렉토리 — 생성 직후 삭제
    static let thumbnailWorkDir: URL = {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("RcloneGUI-thumbs")
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

    static let trashDirName = ".trash"
    static let maxTransferRetries = 3
    static let maxSchedulerLogs = 500
    static let maxTrashItems = 500
    static let maxErrorHistory = 100
    static let maxCompletedTransfers = 200
    static let maxSearchConcurrency = 5
    static let maxSearchHistory = 10
    static let searchHistoryKey = "com.rclone-gui.searchHistory"
    static let remoteAliasesKey = "com.rclone-gui.remoteAliases"
    static let maxNavigationHistory = 50
    static let renameFocusDelay: Double = 0.05
    static let maxSpotlightItems = 1000
    static let defaultConcurrentTransfers = 4
    static let defaultMultiThreadStreams = 4

    // MARK: - Thumbnails

    /// 이미지 썸네일 생성 대상 최대 크기 — 초과 시 폴백 아이콘
    static let thumbnailMaxImageBytes: Int64 = 25 * 1024 * 1024  // 25 MB

    /// 영상 썸네일 생성 대상 최대 크기 — 첫 프레임 추출 위해 전체 다운로드 필요
    static let thumbnailMaxVideoBytes: Int64 = 200 * 1024 * 1024  // 200 MB

    /// 메모리 LRU 캐시에 보관할 썸네일 수
    static let thumbnailMemoryLimit = 200

    /// 그리드/리스트 셀에서 사용하는 기본 썸네일 픽셀 크기 (논리 픽셀)
    static let thumbnailDefaultSize: CGFloat = 128
}
