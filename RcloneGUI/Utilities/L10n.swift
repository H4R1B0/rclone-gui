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
        "settings.noModTime":   ["ko": "수정시간 업데이트 안함", "en": "Don't Update Mod Time"],
        "settings.resetDefaults": ["ko": "기본값 복원", "en": "Restore Defaults"],
        "settings.disabled":    ["ko": "비활성화", "en": "Disabled"],
        "settings.default":     ["ko": "기본값", "en": "Default"],

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
    ]
}
