import Foundation

/// 경량 i18n 시스템 — 기존 TypeScript i18n.ts 포팅
/// SettingsViewModel.locale ("ko" | "en") 기반으로 문자열 반환
enum L10n {
    static var locale: String = "ko"

    static func t(_ key: String) -> String {
        translations[key]?[locale] ?? translations[key]?["en"] ?? key
    }

    // MARK: - 번역 테이블 (TypeScript i18n.ts에서 포팅)

    static let translations: [String: [String: String]] = [
        // Common
        "close":                ["ko": "닫기", "en": "Close"],
        "cancel":               ["ko": "취소", "en": "Cancel"],
        "save":                 ["ko": "저장", "en": "Save"],
        "delete":               ["ko": "삭제", "en": "Delete"],
        "edit":                 ["ko": "편집", "en": "Edit"],
        "create":               ["ko": "생성", "en": "Create"],
        "connect":              ["ko": "연결", "en": "Connect"],
        "back":                 ["ko": "뒤로", "en": "Back"],
        "retry":                ["ko": "재시도", "en": "Retry"],
        "confirm":              ["ko": "확인", "en": "Confirm"],
        "yes":                  ["ko": "예", "en": "Yes"],
        "no":                   ["ko": "아니오", "en": "No"],
        "ok":                   ["ko": "확인", "en": "OK"],
        "loading":              ["ko": "로딩 중...", "en": "Loading..."],
        "saving":               ["ko": "저장 중...", "en": "Saving..."],

        // App
        "app.initializing":     ["ko": "rclone 초기화 중...", "en": "Initializing rclone..."],
        "app.restart.title":    ["ko": "앱 재시작", "en": "Restart App"],
        "app.restart.message":  ["ko": "언어를 변경하려면 앱을 재시작해야 합니다. 재시작하시겠습니까?", "en": "The app needs to restart to change language. Restart now?"],
        "app.restart":          ["ko": "재시작", "en": "Restart"],

        // Sidebar
        "sidebar.favorites":    ["ko": "즐겨찾기", "en": "Favorites"],
        "sidebar.remotes":      ["ko": "클라우드", "en": "Cloud"],
        "sidebar.tools":        ["ko": "도구", "en": "Tools"],
        "sidebar.quickUpload":  ["ko": "빠른 업로드", "en": "Quick Upload"],
        "sidebar.openInExplorer": ["ko": "탐색기에서 열기", "en": "Open in Explorer"],
        "sidebar.config":         ["ko": "설정 정보", "en": "Configuration"],

        // Toolbar
        "toolbar.explore":      ["ko": "탐색", "en": "Explore"],
        "toolbar.accounts":     ["ko": "계정", "en": "Accounts"],
        "toolbar.search":       ["ko": "검색", "en": "Search"],
        "toolbar.transfers":    ["ko": "전송", "en": "Transfers"],
        "toolbar.settings":     ["ko": "설정", "en": "Settings"],

        // Panel
        "panel.local":          ["ko": "로컬", "en": "Local"],
        "panel.noFiles":        ["ko": "파일 없음", "en": "No files"],
        "panel.addAccount":     ["ko": "계정 추가", "en": "Add Account"],

        // Address bar
        "addressbar.path":      ["ko": "경로", "en": "Path"],

        // File operations
        "file.open":            ["ko": "열기", "en": "Open"],
        "file.cut":             ["ko": "잘라내기", "en": "Cut"],
        "file.copy":            ["ko": "복사", "en": "Copy"],
        "file.paste":           ["ko": "붙여넣기", "en": "Paste"],
        "file.rename":          ["ko": "이름 변경...", "en": "Rename..."],
        "file.delete":          ["ko": "삭제", "en": "Delete"],
        "file.properties":      ["ko": "속성", "en": "Properties"],
        "file.newFolder":       ["ko": "새 폴더", "en": "New Folder"],
        "file.newFolder.title": ["ko": "새 폴더", "en": "New Folder"],
        "file.newFolder.placeholder": ["ko": "폴더 이름", "en": "Folder name"],
        "file.selectAll":       ["ko": "전체 선택", "en": "Select All"],

        // Column headers
        "column.name":          ["ko": "이름", "en": "Name"],
        "column.size":          ["ko": "크기", "en": "Size"],
        "column.modified":      ["ko": "수정일", "en": "Modified"],

        // Delete confirmation
        "delete.title.single":  ["ko": "\"%@\" 삭제?", "en": "Delete \"%@\"?"],
        "delete.title.multi":   ["ko": "%d개 항목 삭제?", "en": "Delete %d items?"],
        "delete.warning":       ["ko": "이 작업은 되돌릴 수 없습니다.", "en": "This action cannot be undone."],

        // Properties
        "properties.name":      ["ko": "이름", "en": "Name"],
        "properties.type":      ["ko": "유형", "en": "Type"],
        "properties.size":      ["ko": "크기", "en": "Size"],
        "properties.modified":  ["ko": "수정일", "en": "Modified"],
        "properties.path":      ["ko": "경로", "en": "Path"],
        "properties.remote":    ["ko": "리모트", "en": "Remote"],
        "properties.hash":      ["ko": "해시", "en": "Hash"],
        "properties.folder":    ["ko": "폴더", "en": "Folder"],
        "properties.file":      ["ko": "파일", "en": "File"],

        // Transfer
        "transfer.active":      ["ko": "진행 중", "en": "Active"],
        "transfer.completed":   ["ko": "완료", "en": "Completed"],
        "transfer.errors":      ["ko": "오류", "en": "Errors"],
        "transfer.noTransfers": ["ko": "전송 없음", "en": "No transfers"],
        "transfer.paused":      ["ko": "일시정지됨", "en": "Paused"],
        "transfer.resume":      ["ko": "재개", "en": "Resume"],
        "transfer.pauseAll":    ["ko": "모두 일시정지", "en": "Pause All"],
        "transfer.stopAll":     ["ko": "모두 중지", "en": "Stop All"],
        "transfer.stop":        ["ko": "중지", "en": "Stop"],
        "transfer.restart":     ["ko": "재시작", "en": "Restart"],
        "transfer.remove":      ["ko": "제거", "en": "Remove"],
        "transfer.clear":       ["ko": "지우기", "en": "Clear"],
        "transfer.stopped":     ["ko": "중지됨", "en": "Stopped"],

        // Account
        "account.title":        ["ko": "계정", "en": "Accounts"],
        "account.add":          ["ko": "계정 추가", "en": "Add Account"],
        "account.noAccounts":   ["ko": "설정된 계정이 없습니다", "en": "No accounts configured"],
        "account.chooseProvider": ["ko": "프로바이더 선택", "en": "Choose Provider"],
        "account.remoteName":   ["ko": "리모트 이름", "en": "Remote name"],
        "account.providerNotFound": ["ko": "프로바이더를 찾을 수 없습니다", "en": "Provider not found"],
        "account.showAdvanced": ["ko": "고급 옵션 표시", "en": "Show Advanced Options"],

        // Search
        "search.placeholder":   ["ko": "파일 검색...", "en": "Search files..."],
        "search.button":        ["ko": "검색", "en": "Search"],
        "search.cancel":        ["ko": "취소", "en": "Cancel"],
        "search.hint":          ["ko": "검색어를 입력하고 Enter를 누르세요", "en": "Enter a query and press Enter"],
        "search.noResults":     ["ko": "검색 결과가 없습니다", "en": "No results found"],
        "search.searching":     ["ko": "검색 중...", "en": "Searching..."],
        "search.results":       ["ko": "%d개 결과", "en": "%d results"],
        "search.cloud":         ["ko": "클라우드", "en": "Cloud"],

        // Settings
        "settings.title":       ["ko": "설정", "en": "Settings"],
        "settings.language":    ["ko": "언어", "en": "Language"],
        "settings.appLanguage": ["ko": "앱 언어", "en": "App Language"],
        "settings.performance": ["ko": "성능", "en": "Performance"],
        "settings.transfers":   ["ko": "동시 전송 수 (Transfers)", "en": "Concurrent Transfers"],
        "settings.checkers":    ["ko": "동시 체크 수 (Checkers)", "en": "Concurrent Checkers"],
        "settings.multiThread": ["ko": "멀티스레드 스트림", "en": "Multi-thread Streams"],
        "settings.bufferSize":  ["ko": "버퍼 크기", "en": "Buffer Size"],
        "settings.bwLimit":     ["ko": "대역폭 제한", "en": "Bandwidth Limit"],
        "settings.reliability": ["ko": "안정성", "en": "Reliability"],
        "settings.retries":     ["ko": "재시도 횟수", "en": "Retries"],
        "settings.lowRetries":  ["ko": "저수준 재시도", "en": "Low-level Retries"],
        "settings.connTimeout": ["ko": "연결 타임아웃", "en": "Connect Timeout"],
        "settings.ioTimeout":   ["ko": "IO 타임아웃", "en": "IO Timeout"],
        "settings.behavior":    ["ko": "동작", "en": "Behavior"],
        "settings.userAgent":   ["ko": "User-Agent", "en": "User-Agent"],
        "settings.skipSSL":     ["ko": "SSL 인증서 검증 건너뛰기", "en": "Skip SSL Certificate Verification"],
        "settings.ignoreExist": ["ko": "기존 파일 무시", "en": "Ignore Existing Files"],
        "settings.ignoreSize":  ["ko": "크기 무시", "en": "Ignore Size"],
        "settings.noTraverse":  ["ko": "디렉토리 순회 건너뛰기", "en": "Skip Directory Traversal"],
        "settings.noModTime":   ["ko": "수정시간 업데이트 안함 (원본 날짜 유지)", "en": "Don't Update Mod Time (preserve original dates)"],
        "settings.resetDefaults": ["ko": "기본값 복원", "en": "Restore Defaults"],
        "settings.disabled":    ["ko": "비활성화", "en": "Disabled"],
        "settings.default":     ["ko": "기본값", "en": "Default"],
        "settings.multiThreadHelp": ["ko": "큰 파일 전송 시 여러 스레드로 분할하여 속도를 높입니다. 0 = 비활성화.", "en": "Splits large file transfers across multiple threads for speed. 0 = disabled."],
        "settings.bwSchedule":  ["ko": "시간대별 대역폭 제한", "en": "Time-based Bandwidth Limit"],
        "settings.addSchedule": ["ko": "시간대 추가", "en": "Add Time Slot"],

        // Status bar
        "status.active":        ["ko": "%d개 전송 중", "en": "%d active"],
        "status.recentErrors":  ["ko": "최근 오류", "en": "Recent Errors"],

        // Lock
        "lock.security":        ["ko": "보안", "en": "Security"],
        "lock.enable":          ["ko": "앱 잠금 활성화", "en": "Enable App Lock"],
        "lock.useTouchID":      ["ko": "Touch ID 사용", "en": "Use Touch ID"],
        "lock.password":        ["ko": "비밀번호", "en": "Password"],
        "lock.confirmPassword": ["ko": "비밀번호 확인", "en": "Confirm Password"],
        "lock.unlock":          ["ko": "잠금 해제", "en": "Unlock"],
        "lock.wrongPassword":   ["ko": "비밀번호가 틀렸습니다", "en": "Wrong password"],
        "lock.setPassword":     ["ko": "비밀번호 설정", "en": "Set Password"],
        "lock.changePassword":  ["ko": "비밀번호 변경", "en": "Change Password"],
        "lock.removePassword":  ["ko": "비밀번호 제거", "en": "Remove Password"],
        "lock.passwordMismatch": ["ko": "비밀번호가 일치하지 않습니다", "en": "Passwords don't match"],
        "lock.passwordTooShort": ["ko": "비밀번호는 4자 이상이어야 합니다", "en": "Password must be at least 4 characters"],
        "lock.passwordSaveFailed": ["ko": "비밀번호 저장에 실패했습니다", "en": "Failed to save password"],

        // Bookmarks
        "bookmark.title":  ["ko": "북마크", "en": "Bookmarks"],
        "bookmark.add":    ["ko": "현재 경로 북마크", "en": "Bookmark Current Path"],
        "bookmark.empty":  ["ko": "북마크가 없습니다", "en": "No bookmarks"],
        "bookmark.emptyHint": ["ko": "주소 바의 ☆ 버튼으로 현재 경로를 북마크하세요.", "en": "Use the ☆ button in the address bar to bookmark the current path."],

        // Scheduler
        "toolbar.scheduler":     ["ko": "스케줄러", "en": "Scheduler"],
        "scheduler.title":       ["ko": "작업 스케줄러", "en": "Task Scheduler"],
        "scheduler.noTasks":     ["ko": "예약된 작업이 없습니다", "en": "No scheduled tasks"],
        "scheduler.addTask":     ["ko": "작업 추가", "en": "Add Task"],
        "scheduler.interval":    ["ko": "실행 간격", "en": "Interval"],
        "scheduler.minutes":     ["ko": "분", "en": "min"],
        "scheduler.hours":       ["ko": "시간", "en": "hr"],
        "scheduler.days":        ["ko": "일", "en": "day"],
        "scheduler.lastRun":     ["ko": "마지막 실행", "en": "Last run"],
        "scheduler.running":     ["ko": "실행 중", "en": "Running"],
        "scheduler.logs":        ["ko": "로그", "en": "Logs"],
        "scheduler.noLogs":      ["ko": "로그가 없습니다", "en": "No logs"],
        "scheduler.exportLogs":  ["ko": "로그 내보내기", "en": "Export Logs"],
        "scheduler.clearLogs":   ["ko": "지우기", "en": "Clear"],

        // Crypt
        "crypt.title":         ["ko": "암호화 리모트", "en": "Encrypted Remote"],
        "crypt.name":          ["ko": "암호화 리모트 이름", "en": "Encrypted Remote Name"],
        "crypt.baseRemote":    ["ko": "기본 리모트", "en": "Base Remote"],
        "crypt.passwords":     ["ko": "비밀번호", "en": "Passwords"],
        "crypt.password":      ["ko": "암호화 비밀번호", "en": "Encryption Password"],
        "crypt.password2":     ["ko": "솔트 비밀번호 (선택)", "en": "Salt Password (optional)"],
        "crypt.password2Help": ["ko": "추가 보안을 위한 두 번째 비밀번호", "en": "Second password for additional security"],
        "crypt.options":       ["ko": "암호화 옵션", "en": "Encryption Options"],
        "crypt.filenameEnc":   ["ko": "파일명 암호화", "en": "Filename Encryption"],
        "crypt.off":           ["ko": "끄기", "en": "Off"],
        "crypt.dirNameEnc":    ["ko": "디렉토리명 암호화", "en": "Directory Name Encryption"],

        // Union
        "union.title":           ["ko": "스토리지 풀링", "en": "Storage Pooling"],
        "union.name":            ["ko": "유니온 리모트 이름", "en": "Union Remote Name"],
        "union.selectRemotes":   ["ko": "풀링할 리모트 선택 (2개 이상)", "en": "Select remotes to pool (2+)"],

        // Bulk Rename
        "bulkRename.title":      ["ko": "대량 이름변경", "en": "Bulk Rename"],
        "bulkRename.pattern":    ["ko": "패턴", "en": "Pattern"],
        "bulkRename.prefix":     ["ko": "접두사", "en": "Prefix"],
        "bulkRename.suffix":     ["ko": "접미사", "en": "Suffix"],
        "bulkRename.number":     ["ko": "번호", "en": "Number"],
        "bulkRename.findReplace": ["ko": "찾기/바꾸기", "en": "Find/Replace"],
        "bulkRename.prefixText": ["ko": "접두사 입력", "en": "Enter prefix"],
        "bulkRename.suffixText": ["ko": "접미사 입력", "en": "Enter suffix"],
        "bulkRename.startNum":   ["ko": "시작 번호", "en": "Start number"],
        "bulkRename.find":       ["ko": "찾기", "en": "Find"],
        "bulkRename.replace":    ["ko": "바꾸기", "en": "Replace"],
        "bulkRename.preview":    ["ko": "미리보기", "en": "Preview"],
        "bulkRename.apply":      ["ko": "이름변경 실행", "en": "Apply Rename"],
        "bulkRename.renaming":   ["ko": "변경 중...", "en": "Renaming..."],
        "bulkRename.filesSelected": ["ko": "개 파일 선택됨", "en": " files selected"],

        // Mount
        "toolbar.mount":        ["ko": "마운트", "en": "Mount"],
        "mount.title":          ["ko": "클라우드 마운트", "en": "Cloud Mount"],
        "mount.new":            ["ko": "새 마운트", "en": "New Mount"],
        "mount.noMounts":       ["ko": "활성 마운트가 없습니다", "en": "No active mounts"],
        "mount.mount":          ["ko": "마운트", "en": "Mount"],
        "mount.unmount":        ["ko": "마운트 해제", "en": "Unmount"],
        "mount.mountPoint":     ["ko": "마운트 경로", "en": "Mount Point"],
        "mount.mountPointHint": ["ko": "예: /tmp/mycloud", "en": "e.g., /tmp/mycloud"],

        // Sync
        "toolbar.sync":          ["ko": "동기화", "en": "Sync"],
        "sync.profiles":         ["ko": "동기화 프로필", "en": "Sync Profiles"],
        "sync.noProfiles":       ["ko": "동기화 프로필이 없습니다", "en": "No sync profiles"],
        "sync.createProfile":    ["ko": "프로필 생성", "en": "Create Profile"],
        "sync.mode":             ["ko": "동기화 모드", "en": "Sync Mode"],
        "sync.source":           ["ko": "소스", "en": "Source"],
        "sync.destination":      ["ko": "대상", "en": "Destination"],
        "sync.remote":           ["ko": "리모트", "en": "Remote"],
        "sync.filters":          ["ko": "필터", "en": "Filters"],
        "sync.filterHint":       ["ko": "제외 패턴 (쉼표 구분: *.tmp, *.log)", "en": "Exclude patterns (comma-separated: *.tmp, *.log)"],
        "sync.rules":            ["ko": "동기화 규칙", "en": "Sync Rules"],
        "sync.rule.exclude":     ["ko": "제외", "en": "Exclude"],
        "sync.rule.include":     ["ko": "포함", "en": "Include"],
        "sync.rule.minSize":     ["ko": "최소 크기", "en": "Min Size"],
        "sync.rule.maxSize":     ["ko": "최대 크기", "en": "Max Size"],
        "sync.rule.minAge":      ["ko": "최소 기간", "en": "Min Age"],
        "sync.rule.maxAge":      ["ko": "최대 기간", "en": "Max Age"],
        "sync.rule.pattern":     ["ko": "패턴 (예: *.tmp, 10M, 7d)", "en": "Pattern (e.g., *.tmp, 10M, 7d)"],
        "sync.rule.add":         ["ko": "규칙 추가", "en": "Add Rule"],
        "sync.rule.help":        ["ko": "제외/포함: 글로브 패턴 (*.log), 크기: 10M, 기간: 7d/1w/30d", "en": "Exclude/Include: glob (*.log), Size: 10M, Age: 7d/1w/30d"],
        "sync.run":              ["ko": "실행", "en": "Run"],
        "sync.stop":             ["ko": "중지", "en": "Stop"],
        "sync.logs":             ["ko": "로그", "en": "Logs"],
        "sync.noLogs":           ["ko": "로그가 없습니다", "en": "No logs"],
        "sync.started":          ["ko": "동기화 시작", "en": "Sync started"],
        "sync.stopped":          ["ko": "동기화 중지됨", "en": "Sync stopped"],
        "sync.failed":           ["ko": "동기화 실패", "en": "Sync failed"],
        "sync.mirror":           ["ko": "미러", "en": "Mirror"],
        "sync.mirrorUpdate":     ["ko": "미러 (변경분만)", "en": "Mirror Updated"],
        "sync.bisync":           ["ko": "양방향 동기화", "en": "Bidirectional Sync"],
        "sync.mirror.desc":      ["ko": "소스를 타겟에 완전 복제합니다. 타겟의 불필요한 파일은 삭제됩니다.", "en": "Makes destination identical to source. Extra files in destination are deleted."],
        "sync.mirrorUpdate.desc": ["ko": "변경된 파일만 소스에서 타겟으로 복사합니다.", "en": "Copies only changed files from source to destination."],
        "sync.bisync.desc":      ["ko": "양쪽 모두 변경 사항을 동기화합니다.", "en": "Synchronizes changes in both directions."],

        // Share Link
        "file.shareLink":        ["ko": "공유 링크 복사", "en": "Copy Share Link"],

        // Quota
        "status.quota":          ["ko": "용량", "en": "Quota"],
        "quota.title":           ["ko": "스토리지 용량", "en": "Storage Quota"],
        "quota.used":            ["ko": "사용", "en": "Used"],
        "quota.free":            ["ko": "여유", "en": "Free"],
        "quota.total":           ["ko": "전체", "en": "Total"],
        "quota.noData":          ["ko": "용량 정보가 없습니다", "en": "No quota data"],
        "quota.notAvailable":    ["ko": "용량 정보를 사용할 수 없음", "en": "Quota not available"],

        // Search Filters
        "search.filterType":     ["ko": "파일 타입", "en": "File Type"],
        "search.allTypes":       ["ko": "전체", "en": "All"],
        "search.images":         ["ko": "이미지", "en": "Images"],
        "search.videos":         ["ko": "동영상", "en": "Videos"],
        "search.audio":          ["ko": "오디오", "en": "Audio"],
        "search.documents":      ["ko": "문서", "en": "Documents"],
        "search.archives":       ["ko": "압축파일", "en": "Archives"],
        "search.minSize":        ["ko": "최소(KB)", "en": "Min(KB)"],
        "search.maxSize":        ["ko": "최대(KB)", "en": "Max(KB)"],
        "search.dateFilter":     ["ko": "날짜 필터", "en": "Date Filter"],
        "search.pathFilter":     ["ko": "경로 필터...", "en": "Path filter..."],

        // Account Import/Export
        "account.export":        ["ko": "계정 내보내기", "en": "Export Accounts"],
        "account.import":        ["ko": "계정 가져오기", "en": "Import Accounts"],

        // Hash Compare
        "hash.compare":          ["ko": "해시 비교", "en": "Compare Hash"],
        "hash.compareTitle":     ["ko": "파일 해시 비교", "en": "File Hash Comparison"],
        "hash.match":            ["ko": "파일이 동일합니다", "en": "Files are identical"],
        "hash.mismatch":         ["ko": "파일이 다릅니다", "en": "Files differ"],

        // Provider Search
        "account.searchProvider": ["ko": "프로바이더 검색...", "en": "Search providers..."],

        // Linked Browsing
        "toolbar.linkedBrowsing": ["ko": "연결 탐색", "en": "Linked Browsing"],

        // Compress
        "compress.title":          ["ko": "압축", "en": "Compress"],
        "compress.archiveName":    ["ko": "압축 파일 이름", "en": "Archive Name"],
        "compress.fileCount":      ["ko": "%d개 파일 선택됨", "en": "%d files selected"],
        "compress.compressing":    ["ko": "압축 중...", "en": "Compressing..."],
        "compress.compressUpload": ["ko": "압축", "en": "Compress"],
        "compress.localOnly":      ["ko": "로컬 파일만 압축 가능합니다", "en": "Only local files can be compressed"],

        // Media Playback
        "media.play":            ["ko": "재생", "en": "Play"],
        "media.loading":         ["ko": "미디어 로딩 중...", "en": "Loading media..."],

        // Trash
        "toolbar.trash":          ["ko": "휴지통", "en": "Trash"],
        "trash.title":            ["ko": "휴지통", "en": "Trash"],
        "trash.items":            ["ko": "개 항목", "en": "items"],
        "trash.empty":            ["ko": "휴지통이 비어있습니다", "en": "Trash is empty"],
        "trash.emptyAll":         ["ko": "비우기", "en": "Empty Trash"],

        // Menu Bar
        "menubar.activeTransfers": ["ko": "개 전송 중", "en": "active transfers"],
        "menubar.noTransfers":     ["ko": "전송 없음", "en": "No active transfers"],
        "menubar.openWindow":      ["ko": "창 열기", "en": "Open Window"],
        "menubar.quit":            ["ko": "종료", "en": "Quit"],

        // Transfer Report
        "report.title":           ["ko": "전송 리포트", "en": "Transfer Report"],
        "report.total":           ["ko": "전체", "en": "Total"],
        "report.success":         ["ko": "성공", "en": "Success"],
        "report.failed":          ["ko": "실패", "en": "Failed"],
        "report.totalSize":       ["ko": "전체 크기", "en": "Total Size"],
        "report.failedFiles":     ["ko": "실패한 파일", "en": "Failed Files"],
        "report.successFiles":    ["ko": "완료된 파일", "en": "Completed Files"],
        "report.andMore":         ["ko": "외", "en": "and more"],
        "report.copyToClipboard": ["ko": "클립보드에 복사", "en": "Copy to Clipboard"],

        // Finder Service
        "finder.uploadTitle":  ["ko": "클라우드에 업로드", "en": "Upload to Cloud"],
        "finder.fileCount":    ["ko": "%d개 파일 선택됨", "en": "%d files selected"],
        "finder.uploading":    ["ko": "업로드 중...", "en": "Uploading..."],
        "finder.upload":       ["ko": "업로드", "en": "Upload"],

        // Duplicate Finder
        "duplicate.title":         ["ko": "중복 파일 찾기", "en": "Find Duplicates"],
        "duplicate.desc":          ["ko": "여러 클라우드에서 중복 파일을 찾아 공간을 절약하세요.", "en": "Find duplicate files across clouds to save space."],
        "duplicate.selectRemotes": ["ko": "검색할 리모트 선택", "en": "Select remotes to scan"],
        "duplicate.scan":          ["ko": "중복 검색 시작", "en": "Start Scan"],
        "duplicate.scanning":      ["ko": "검색 중", "en": "Scanning"],
        "duplicate.comparing":     ["ko": "해시 비교 중...", "en": "Comparing hashes..."],
        "duplicate.groups":        ["ko": "개 중복 그룹", "en": "duplicate groups"],
        "duplicate.wasted":        ["ko": "낭비", "en": "wasted"],
        "duplicate.copies":        ["ko": "개 사본", "en": "copies"],
        "duplicate.keep":          ["ko": "유지", "en": "Keep"],

        // Transfer Resume
        "transfer.resumable":  ["ko": "재시도 가능", "en": "Resumable"],
        "transfer.retryAll":   ["ko": "모두 재시도", "en": "Retry All"],

        // Onboarding
        "onboarding.subtitle":   ["ko": "70+ 클라우드를 하나의 앱에서 관리하세요", "en": "Manage 70+ cloud services in one app"],
        "onboarding.feature1":   ["ko": "듀얼 패널 파일 브라우저", "en": "Dual-panel file browser"],
        "onboarding.feature2":   ["ko": "70+ 클라우드 스토리지 지원", "en": "70+ cloud storage services"],
        "onboarding.feature3":   ["ko": "암호화 및 앱 잠금", "en": "Encryption & app lock"],
        "onboarding.feature4":   ["ko": "동기화 및 스케줄링", "en": "Sync & scheduling"],
        "onboarding.getStarted": ["ko": "시작하기", "en": "Get Started"],
        "onboarding.skip":       ["ko": "건너뛰기", "en": "Skip"],
        "onboarding.ready":      ["ko": "준비 완료!", "en": "All Set!"],
        "onboarding.readyDesc":  ["ko": "사이드바에서 클라우드를 선택하여 파일을 탐색하세요.", "en": "Select a cloud from the sidebar to start browsing."],
        "onboarding.start":      ["ko": "앱 시작", "en": "Start App"],

        // Version History
        "version.title":        ["ko": "버전 기록", "en": "Version History"],
        "version.current":      ["ko": "현재", "en": "Current"],
        "version.noVersions":   ["ko": "버전 기록이 없습니다", "en": "No version history"],
        "version.notSupported": ["ko": "이 리모트는 파일 버전을 지원하지 않을 수 있습니다.", "en": "This remote may not support file versioning."],

        // Large Directory Performance
        "performance.fileCount": ["ko": "%d개 파일", "en": "%d files"],
        "performance.largeDir":  ["ko": "대용량 디렉토리", "en": "Large directory"],

        // Error Recovery
        "error.authFailed":         ["ko": "인증에 실패했습니다", "en": "Authentication failed"],
        "error.authSuggestion":     ["ko": "계정을 다시 연결하거나 토큰을 갱신하세요.", "en": "Reconnect the account or refresh the token."],
        "error.reauth":             ["ko": "재인증", "en": "Reauthenticate"],
        "error.quotaFull":          ["ko": "저장 공간이 부족합니다", "en": "Storage quota exceeded"],
        "error.quotaSuggestion":    ["ko": "불필요한 파일을 삭제하거나 요금제를 업그레이드하세요.", "en": "Delete unnecessary files or upgrade your plan."],
        "error.network":            ["ko": "네트워크 연결에 실패했습니다", "en": "Network connection failed"],
        "error.networkSuggestion":  ["ko": "인터넷 연결을 확인하고 다시 시도하세요.", "en": "Check your internet connection and try again."],
        "error.notFound":           ["ko": "파일 또는 경로를 찾을 수 없습니다", "en": "File or path not found"],
        "error.notFoundSuggestion": ["ko": "경로가 올바른지 확인하거나 파일이 이동/삭제되었을 수 있습니다.", "en": "Check the path or the file may have been moved/deleted."],
        "error.rateLimit":          ["ko": "요청이 너무 많습니다", "en": "Too many requests"],
        "error.rateLimitSuggestion": ["ko": "잠시 후 다시 시도하세요. 자동으로 재시도됩니다.", "en": "Wait a moment and try again. Auto-retry will resume."],
        "error.conflict":           ["ko": "파일이 이미 존재합니다", "en": "File already exists"],
        "error.conflictSuggestion": ["ko": "이름을 변경하거나 덮어쓰기를 선택하세요.", "en": "Rename the file or choose to overwrite."],
        "error.genericSuggestion":  ["ko": "문제가 지속되면 설정에서 계정을 확인하세요.", "en": "If the problem persists, check the account in Settings."],
    ]
}
