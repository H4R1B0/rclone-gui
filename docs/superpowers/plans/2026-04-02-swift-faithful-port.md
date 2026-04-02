# Swift 네이티브 충실한 포팅 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 기존 Electron/TypeScript rclone GUI의 동작을 Swift 네이티브로 1:1 재현. 기존 앱에서 작동하던 모든 기능이 동일하게 동작해야 한다.

**Architecture:** librclone FFI(RcloneKit) → 도메인 로직(FileBrowser, TransferEngine) → @Observable ViewModels → SwiftUI Views. 기존 Zustand 스토어 구조를 @Observable로 매핑하고, React 컴포넌트를 SwiftUI 뷰로 1:1 매핑한다.

**Tech Stack:** Swift 5.10, SwiftUI, AppKit, macOS 14+, librclone (C FFI), Swift Testing

**전략:** 기존 스켈레톤 코드를 모두 삭제하고 기존 TypeScript 코드의 동작을 충실히 재현하는 코드로 교체한다. SPM 패키지(RcloneKit, FileBrowser, TransferEngine)의 인터페이스는 유지하되 구현을 보강한다.

**기존 TypeScript 분석 참조:** 이 계획은 대화 내 상세 분석 리포트(9개 섹션, 150+ i18n 키, 5개 Zustand 스토어, 30+ 컴포넌트)를 기반으로 한다.

---

## 기존 코드 → Swift 매핑

| TypeScript | Swift | 비고 |
|------------|-------|------|
| `panelStore` (Zustand) | `PanelViewModel` (@Observable) | 멀티탭, 정렬, 선택 |
| `transferStore` | `TransferViewModel` | 폴링, jobId 추적, 재시작 |
| `searchStore` | `SearchViewModel` | BFS 스트리밍 검색 |
| `clipboardStore` | `ClipboardState` | cut/copy/paste |
| `settingsStore` | `SettingsViewModel` | rclone 옵션, 앱 잠금 |
| `useRclone` hook | `RcloneAPI` 확장 | 이미 구현됨 |
| `useFileOperations` hook | `FileOperations` 확장 | paste, moveToOther 추가 |
| `useTransferPolling` hook | `TransferViewModel.startPolling()` | stats 폴링 |
| `useSearch` hook | `SearchViewModel` | IPC → actor 방식 |
| React components | SwiftUI Views | 1:1 매핑 |

---

## Task 1: RcloneKit API 보강 — 누락 엔드포인트 추가

기존 TypeScript IPC 핸들러에 있지만 현재 Swift에 없는 API들을 추가한다.

**Files:**
- Modify: `Packages/RcloneKit/Sources/RcloneKit/ConvenienceAPI.swift`
- Modify: `Packages/RcloneKit/Sources/RcloneKit/Models.swift`
- Modify: `Packages/RcloneKit/Tests/RcloneKitTests/ConvenienceAPITests.swift`
- Modify: `Packages/RcloneKit/Tests/RcloneKitTests/ModelsTests.swift`

### 누락된 API 목록 (기존 TypeScript에 있는 것)

| TypeScript IPC | Swift 함수 | 상태 |
|----------------|-----------|------|
| `rclone:getProviders` | `getProviders()` | **누락** |
| `rclone:getRemoteConfig` | `getRemoteConfig()` | **누락** |
| `rclone:copyDir` | `copyDir()` | **누락** |
| `rclone:moveDir` | `moveDir()` | **누락** |
| `rclone:renameFile` | 이미 moveFile로 구현 | OK |
| `rclone:hashFile` | `hashFile()` | **누락** |
| `rclone:getStats` | `getStats()` | **누락** |
| `rclone:getJobList` | `getJobList()` | **누락** |
| `rclone:stopJob` | `stopJob()` | **누락** |
| `rclone:getJobStatus` | `getJobStatus()` | **누락** |
| `rclone:setBwLimit` | `setBwLimit()` | **누락** |
| `rclone:getTransferred` | `getTransferred()` | **누락** |
| `rclone:resetStats` | `resetStats()` | **누락** |
| `rclone:searchFiles` | `searchFiles()` | **누락** |

### 누락된 모델 타입

```swift
// 기존 TypeScript RcloneStats
public struct RcloneStats: Decodable {
    public let bytes: Int64
    public let speed: Double
    public let totalBytes: Int64
    public let totalTransfers: Int
    public let transfers: Int
    public let errors: Int
    public let lastError: String?
    public let eta: Double?
    public let transferring: [RcloneTransferring]?
}

public struct RcloneTransferring: Decodable, Identifiable {
    public var id: String { name }
    public let name: String
    public let size: Int64
    public let bytes: Int64
    public let percentage: Int
    public let speed: Double
    public let speedAvg: Double
    public let eta: Double
    public let group: String
}

public struct RcloneCompletedTransfer: Decodable {
    public let name: String
    public let size: Int64
    public let bytes: Int64
    public let error: String
    public let group: String
    public let completed_at: String  // swiftlint:disable:this identifier_name
}

public struct RcloneJobStatus: Decodable {
    public let id: Int
    public let group: String
    public let finished: Bool
    public let success: Bool
    public let error: String
    public let duration: Double
    public let startTime: String
    public let endTime: String
}

public struct RcloneProvider: Decodable, Identifiable {
    public var id: String { Prefix }
    public let Name: String          // swiftlint:disable:this identifier_name
    public let Description: String   // swiftlint:disable:this identifier_name
    public let Prefix: String        // swiftlint:disable:this identifier_name
    public let Options: [ProviderOption]?  // swiftlint:disable:this identifier_name
}

public struct ProviderOption: Decodable {
    public let Name: String          // swiftlint:disable:this identifier_name
    public let Help: String          // swiftlint:disable:this identifier_name
    public let Default: AnyCodable?  // swiftlint:disable:this identifier_name
    public let Required: Bool        // swiftlint:disable:this identifier_name
    public let IsPassword: Bool      // swiftlint:disable:this identifier_name
    public let Hide: Int             // swiftlint:disable:this identifier_name
    public let Advanced: Bool        // swiftlint:disable:this identifier_name
}
```

- [ ] **Step 1: Models.swift에 누락된 타입 추가**

위 모델 타입들을 `Packages/RcloneKit/Sources/RcloneKit/Models.swift`에 추가한다. `RcloneStats`, `RcloneTransferring`, `RcloneCompletedTransfer`, `RcloneJobStatus`, `RcloneProvider`, `ProviderOption`. CodingKeys는 rclone JSON 필드명과 일치시킨다.

- [ ] **Step 2: 모델 테스트 추가**

`ModelsTests.swift`에 `RcloneStats`, `RcloneProvider` 디코딩 테스트 추가.

- [ ] **Step 3: ConvenienceAPI.swift에 누락된 함수 추가**

각 함수는 기존 TypeScript IPC 핸들러의 동작을 그대로 재현:

```swift
// 프로바이더
static func getProviders(using:) async throws -> [RcloneProvider]
static func getRemoteConfig(using:, name:) async throws -> [String: Any]

// 디렉토리 복사/이동 (sync/copy, sync/move — _async: true)
static func copyDir(using:, srcFs:, srcRemote:, dstFs:, dstRemote:) async throws -> Int  // returns jobid
static func moveDir(using:, srcFs:, srcRemote:, dstFs:, dstRemote:) async throws -> Int

// 비동기 파일 복사/이동 (기존 copyFile/moveFile을 _async:true로 변경)
static func copyFileAsync(using:, srcFs:, srcRemote:, dstFs:, dstRemote:) async throws -> Int
static func moveFileAsync(using:, srcFs:, srcRemote:, dstFs:, dstRemote:) async throws -> Int

// 전송 모니터링
static func getStats(using:) async throws -> RcloneStats
static func getTransferred(using:) async throws -> [RcloneCompletedTransfer]
static func resetStats(using:) async throws
static func getJobList(using:) async throws -> [Int]  // jobids
static func stopJob(using:, jobid:) async throws
static func getJobStatus(using:, jobid:) async throws -> RcloneJobStatus

// 설정
static func setBwLimit(using:, rate:) async throws
static func hashFile(using:, fs:, remote:, hashTypes:) async throws -> [String: String]
```

핵심: `_async: true` 파라미터가 있는 호출은 rclone이 jobid를 반환한다. 응답에서 `jobid` 필드를 추출해야 한다.

- [ ] **Step 4: API 테스트 추가**

Mock 기반으로 각 새 함수가 올바른 rclone 엔드포인트와 파라미터를 사용하는지 테스트.

- [ ] **Step 5: 커밋**

```
feat: RcloneKit API 보강 — 전송 모니터링, 프로바이더, 비동기 전송 등

- RcloneStats, RcloneTransferring 등 모델 타입 추가
- getStats, getJobList, stopJob 등 전송 관리 API
- getProviders, getRemoteConfig 프로바이더 API
- copyDir/moveDir 디렉토리 전송 (sync/copy, sync/move)
- copyFileAsync/moveFileAsync 비동기 전송 (_async: true)
- hashFile, setBwLimit 유틸리티 API
```

---

## Task 2: 클립보드 상태 + FileOperations 보강

기존 TypeScript의 `clipboardStore`와 `useFileOperations` hook의 paste/moveToOther 기능 구현.

**Files:**
- Create: `RcloneGUI/ViewModels/ClipboardState.swift`
- Modify: `Packages/FileBrowser/Sources/FileBrowser/FileOperations.swift`

- [ ] **Step 1: ClipboardState 작성**

```swift
// RcloneGUI/ViewModels/ClipboardState.swift
import Foundation
import RcloneKit

@Observable
final class ClipboardState {
    enum Action { case copy, cut }

    var action: Action?
    var sourceFs: String = ""
    var sourcePath: String = ""
    var files: [(name: String, isDir: Bool)] = []

    var hasData: Bool { action != nil && !files.isEmpty }

    func copy(fs: String, path: String, files: [(name: String, isDir: Bool)]) {
        self.action = .copy
        self.sourceFs = fs
        self.sourcePath = path
        self.files = files
    }

    func cut(fs: String, path: String, files: [(name: String, isDir: Bool)]) {
        self.action = .cut
        self.sourceFs = fs
        self.sourcePath = path
        self.files = files
    }

    func clear() {
        action = nil
        files = []
    }
}
```

기존 TypeScript `clipboardStore`와 동일한 구조.

- [ ] **Step 2: FileOperations에 paste, copyToPanel 추가**

```swift
// FileOperations에 추가
public func paste(
    clipboard: (action: String, sourceFs: String, sourcePath: String, files: [(name: String, isDir: Bool)]),
    dstFs: String,
    dstPath: String
) async throws {
    for file in clipboard.files {
        let srcRemote = clipboard.sourcePath.isEmpty ? file.name : "\(clipboard.sourcePath)/\(file.name)"
        let dstRemote = dstPath.isEmpty ? file.name : "\(dstPath)/\(file.name)"

        if clipboard.action == "cut" {
            if file.isDir {
                _ = try await RcloneAPI.moveDir(using: client, srcFs: clipboard.sourceFs, srcRemote: srcRemote, dstFs: dstFs, dstRemote: dstRemote)
            } else {
                _ = try await RcloneAPI.moveFileAsync(using: client, srcFs: clipboard.sourceFs, srcRemote: srcRemote, dstFs: dstFs, dstRemote: dstRemote)
            }
        } else {
            if file.isDir {
                _ = try await RcloneAPI.copyDir(using: client, srcFs: clipboard.sourceFs, srcRemote: srcRemote, dstFs: dstFs, dstRemote: dstRemote)
            } else {
                _ = try await RcloneAPI.copyFileAsync(using: client, srcFs: clipboard.sourceFs, srcRemote: srcRemote, dstFs: dstFs, dstRemote: dstRemote)
            }
        }
    }
}
```

- [ ] **Step 3: 커밋**

```
feat: 클립보드 상태 + FileOperations paste 구현

- ClipboardState: copy/cut/paste 상태 관리 (@Observable)
- FileOperations.paste(): 파일/폴더 붙여넣기 (비동기 전송)
```

---

## Task 3: PanelViewModel 전면 재작성 — 멀티탭 + 기존 동작 재현

기존 TypeScript `panelStore`의 `TabState`, `SideState` 구조를 그대로 재현.

**Files:**
- Rewrite: `RcloneGUI/ViewModels/PanelViewModel.swift`

- [ ] **Step 1: TabState + PanelSideState + PanelViewModel 재작성**

기존 TypeScript 구조:
```typescript
TabState: { id, label, mode:'local'|'cloud', remote, path, files, loading, error, selectedFiles, sortBy, sortAsc }
SideState: { tabs[], activeTabId }
DualPanelStore: { leftSide, rightSide, activePanel, remotes }
```

Swift 매핑:

```swift
@Observable
final class TabState: Identifiable {
    let id: UUID
    var label: String
    var mode: PanelMode  // .local, .cloud
    var remote: String   // "gdrive:" or "/"
    var path: String
    var files: [FileItem] = []
    var loading: Bool = false
    var error: String?
    var selectedFiles: Set<String> = []  // 파일 이름 Set (TypeScript와 동일)
    var sortBy: SortField = .name
    var sortAsc: Bool = true
}

enum PanelMode { case local, cloud }
enum SortField: String { case name, size, date }

@Observable
final class PanelSideState {
    var tabs: [TabState] = []
    var activeTabId: UUID

    var activeTab: TabState { tabs.first { $0.id == activeTabId }! }

    func addTab(mode:, remote:, path:, label:) -> TabState
    func closeTab(id:)  // 최소 1개 유지
    func switchTab(id:)
}

@Observable
final class PanelViewModel {
    let left: PanelSideState
    let right: PanelSideState
    var activePanel: PanelSide = .left
    var remotes: [String] = []
    var remotesLoading: Bool = false

    private let client: RcloneClientProtocol
    private let fileOps: FileOperations

    // 기존 TypeScript와 동일한 액션들
    func setRemote(side:, remote:)  // 리모트 전환 → 경로/파일/선택 초기화
    func loadFiles(side:, remote:, path:)  // listFiles 호출
    func navigate(side:, dirName:)  // 현재 경로 + dirName
    func goUp(side:)  // 마지막 경로 세그먼트 제거
    func refresh(side:)  // 현재 경로로 재로드
    func toggleSelect(side:, name:)
    func selectAll(side:)
    func setSort(side:, field:)  // 같은 필드면 방향 토글
    func navigateTo(side:, remote:, path:)
    func loadRemotes()  // config/listremotes
}
```

- [ ] **Step 2: 정렬 로직 구현**

기존 TypeScript:
```typescript
const sortedFiles = useMemo(() => {
    const sorted = [...files].sort((a, b) => {
        // 디렉토리 항상 먼저
        if (a.IsDir !== b.IsDir) return a.IsDir ? -1 : 1;
        // 필드별 비교
        switch (sortBy) {
            case 'name': cmp = a.Name.localeCompare(b.Name); break;
            case 'size': cmp = a.Size - b.Size; break;
            case 'date': cmp = new Date(a.ModTime) - new Date(b.ModTime); break;
        }
        return sortAsc ? cmp : -cmp;
    });
    return sorted;
}, [files, sortBy, sortAsc]);
```

Swift에서 동일하게 구현. `TabState`에 `sortedFiles` computed property 추가.

- [ ] **Step 3: 커밋**

```
feat: PanelViewModel 전면 재작성 — 멀티탭 + 기존 동작 재현

- TabState: 탭별 파일 목록/선택/정렬 상태
- PanelSideState: 탭 관리 (추가/삭제/전환)
- PanelViewModel: 듀얼 패널 + 리모트 관리
- 기존 TypeScript panelStore 1:1 매핑
```

---

## Task 4: TransferViewModel 재작성 — 전송 모니터링 + 재시작

기존 TypeScript의 `transferStore` + `useTransferPolling` hook 동작을 재현.

**Files:**
- Rewrite: `RcloneGUI/ViewModels/TransferViewModel.swift`
- Modify: `Packages/TransferEngine/Sources/TransferEngine/TransferManager.swift`

- [ ] **Step 1: TransferViewModel 재작성**

기존 TypeScript 상태:
```typescript
transfers[], completed[], stopped[], copyOrigins{}
jobIds[], totalSpeed, totalBytes, totalSize
totalTransfers, doneTransfers, errors, lastErrors[]
paused
```

Swift 매핑:

```swift
@Observable
final class TransferViewModel {
    // 활성 전송 (rclone stats.transferring에서 가져옴)
    var transfers: [RcloneTransferring] = []
    // 완료된 전송 (core/transferred에서 가져옴)
    var completed: [RcloneCompletedTransfer] = []
    // 수동 중지된 전송 (재시작 가능)
    var stopped: [StoppedTransfer] = []
    // 집계 통계
    var totalSpeed: Double = 0
    var totalBytes: Int64 = 0
    var totalSize: Int64 = 0
    var totalTransfers: Int = 0
    var doneTransfers: Int = 0
    var errors: Int = 0
    var lastErrors: [String] = []
    // 일시정지 상태
    var paused: Bool = false
    // 활성 job ID 목록
    var jobIds: [Int] = []
    // 복사 원본 정보 (재시작용)
    var copyOrigins: [String: CopyOrigin] = [:]

    private var completedKeys: Set<String> = []  // 중복 방지

    // 1초 폴링 — 기존 useTransferPolling과 동일
    func startPolling()
    func stopPolling()

    // 전송 제어
    func pauseAll()   // setBwLimit("1")
    func resumeAll()  // setBwLimit("off")
    func stopAll()    // 각 jobId에 stopJob
    func stopJob(id:)
    func restartTransfer(stopped:)

    // 이력 관리
    func clearCompleted()
    func clearErrors()
    func clearStopped()
}

struct StoppedTransfer: Identifiable {
    let id = UUID()
    let name: String
    let group: String
    let size: Int64
    let srcFs: String?
    let srcRemote: String?
    let dstFs: String?
    let dstRemote: String?
    let isDir: Bool
}

struct CopyOrigin {
    let srcFs: String
    let srcRemote: String
    let dstFs: String
    let dstRemote: String
    let isDir: Bool
}
```

- [ ] **Step 2: 폴링 로직 구현**

기존 TypeScript `useTransferPolling`:
1. 매 1초: `getStats()` → transfers 업데이트, lastError 추출
2. `getTransferred()` → 중복 제거 후 completed에 추가
3. `getJobList()` → jobIds 업데이트
4. "context canceled" 에러는 stopped로 분류

- [ ] **Step 3: 커밋**

```
feat: TransferViewModel 재작성 — 전송 모니터링 + 폴링 + 재시작

- rclone stats 1초 폴링으로 실시간 전송 추적
- 완료/오류/중지 이력 관리
- 일시정지/재개 (bwlimit), 개별/전체 중지
- 중지된 전송 재시작 (copyOrigins)
```

---

## Task 5: AccountViewModel 재작성 — 프로바이더 필드 + 편집

기존 TypeScript `AccountSetup`의 프로바이더 동적 필드 로딩을 재현.

**Files:**
- Rewrite: `RcloneGUI/ViewModels/AccountViewModel.swift`

- [ ] **Step 1: AccountViewModel 재작성**

```swift
@Observable
final class AccountViewModel {
    var remotes: [Remote] = []
    var providers: [RcloneProvider] = []
    var isLoading: Bool = false
    var error: String?

    // 기존 TypeScript와 동일
    func loadRemotes()
    func loadProviders()  // config/providers
    func getRemoteConfig(name:) -> [String: String]
    func createRemote(name:, type:, params:)
    func updateRemote(oldName:, newName:, type:, params:)  // delete + create
    func deleteRemote(name:)
}
```

- [ ] **Step 2: 커밋**

```
feat: AccountViewModel 재작성 — 프로바이더 로딩 + 리모트 편집
```

---

## Task 6: AppState + 유틸리티 재작성

**Files:**
- Rewrite: `RcloneGUI/AppState.swift`
- Create: `RcloneGUI/Utilities/FormatUtils.swift`
- Create: `RcloneGUI/Utilities/PathUtils.swift`

- [ ] **Step 1: FormatUtils — 기존 TypeScript utils.ts 포팅**

```swift
enum FormatUtils {
    static func formatBytes(_ bytes: Int64) -> String
    static func formatSpeed(_ bytesPerSec: Double) -> String
    static func formatEta(_ seconds: Double) -> String
    static func formatDate(_ isoString: String) -> String
    static func fileIcon(name: String, isDir: Bool) -> String  // SF Symbol name
}
```

기존 TypeScript의 `formatBytes`, `formatSpeed`, `formatEta`, `formatDate`, `getFileIcon`을 그대로 포팅.

- [ ] **Step 2: PathUtils**

```swift
enum PathUtils {
    static func join(_ parts: String...) -> String
    static func parent(_ path: String) -> String
    static func fileName(_ path: String) -> String
}
```

- [ ] **Step 3: AppState 재작성**

```swift
@Observable
final class AppState {
    let client: RcloneClient
    let panels: PanelViewModel
    let transfers: TransferViewModel
    let accounts: AccountViewModel
    let clipboard: ClipboardState
    // Phase 2: let search: SearchViewModel
    // Phase 2: let settings: SettingsViewModel

    var activeView: ActiveView = .explore  // .explore, .account, .search
    var showSettings: Bool = false
    var showTransfers: Bool = true

    func startup()  // initialize + loadRemotes + 초기 경로 설정 + 폴링 시작
    func shutdown()
}
```

- [ ] **Step 4: 커밋**

```
feat: AppState + 유틸리티 재작성

- FormatUtils: 바이트/속도/ETA/날짜 포맷 (TypeScript utils.ts 포팅)
- PathUtils: 경로 결합/부모 경로
- AppState: 클립보드, 뷰 모드 추가
```

---

## Task 7: ContentView + Toolbar + DualPanelView 재작성

기존 TypeScript의 `App.tsx`, `Toolbar.tsx`, `DualPanel.tsx` 동작 재현.

**Files:**
- Rewrite: `RcloneGUI/App.swift`
- Rewrite: `RcloneGUI/Views/ContentView.swift`
- Create: `RcloneGUI/Views/ToolbarView.swift`
- Rewrite: `RcloneGUI/Views/DualPanelView.swift`

- [ ] **Step 1: App.swift — 윈도우 설정**

기존 TypeScript: 1400×900, min 900×600, 다크 테마.
Swift: `WindowGroup` + `defaultSize(width: 1400, height: 900)` + `.windowStyle(.titleBar)`

- [ ] **Step 2: ContentView — 레이아웃 구조**

기존 TypeScript `App.tsx` 레이아웃:
```
├── Toolbar
├── Main Content (activeView에 따라 전환)
│   ├── .explore → DualPanel
│   ├── .account → AccountSetup
│   └── .search → SearchPanel
├── Divider (리사이즈 가능)
├── TransferQueue (showTransfers일 때, 높이 조절 가능)
└── StatusBar
```

전송 영역 리사이즈: 드래그로 높이 조절 (min 80, max 600).

- [ ] **Step 3: ToolbarView**

기존 TypeScript `Toolbar.tsx`:
- 왼쪽: Explore / Accounts / Search 탭 버튼 (activeView 하이라이트)
- 오른쪽: Refresh / Transfers 토글 / Settings 버튼

- [ ] **Step 4: DualPanelView — 리사이즈 가능 분할**

기존 TypeScript: 마우스 드래그로 좌우 비율 조절 (min 20%, max 80%).
Swift: `GeometryReader` + `onDrag` 또는 `HSplitView`.

- [ ] **Step 5: 커밋**

```
feat: ContentView + Toolbar + DualPanelView 재작성

- 뷰 모드 전환 (Explore/Accounts/Search)
- 리사이즈 가능한 전송 영역
- 리사이즈 가능한 듀얼 패널 분할
- 기존 TypeScript App.tsx/Toolbar.tsx 동작 재현
```

---

## Task 8: Panel + TabBar + AddressBar 재작성

기존 TypeScript의 `Panel.tsx`, `TabBar.tsx`, `AddressBar.tsx` 동작 재현.

**Files:**
- Rewrite: `RcloneGUI/Views/PanelView.swift`
- Create: `RcloneGUI/Views/TabBarView.swift`
- Rewrite: `RcloneGUI/Views/AddressBarView.swift`
- Rewrite: `RcloneGUI/Views/RemoteSelectorView.swift`

- [ ] **Step 1: TabBarView**

기존 TypeScript `TabBar.tsx`:
- 탭 목록 (active 하이라이트, 닫기 버튼 — 마지막 1개면 숨김)
- Plus 버튼 → 드롭다운 (Local / 각 리모트)
- 탭 클릭 → switchTab

- [ ] **Step 2: PanelView**

기존 TypeScript `Panel.tsx`:
1. 리모트 미선택(클라우드) → RemoteSelector 표시
2. 로딩 → 스피너
3. 에러 → 에러 메시지
4. 정상 → TabBar + AddressBar + FileList

- [ ] **Step 3: AddressBar — 브레드크럼 모드**

기존 TypeScript `AddressBar.tsx`:
- **기본:** 클릭 가능한 경로 세그먼트 (브레드크럼)
  - 루트 버튼 (로컬=폴더, 클라우드=구름 아이콘)
  - 셰브론(>) 구분자
  - 각 세그먼트 클릭 → 해당 경로로 이동
- **편집:** 전체 경로 텍스트 입력 (클릭 시 전환)
- **상위 버튼:** 위쪽 화살표

- [ ] **Step 4: RemoteSelectorView**

기존 TypeScript `RemoteSelector.tsx`:
- 리모트 그리드 (2열)
- 각 리모트: 아이콘 + 이름 + 타입 배지
- "Add account" 버튼

- [ ] **Step 5: 커밋**

```
feat: Panel + TabBar + AddressBar 재작성

- TabBarView: 멀티탭 (추가/삭제/전환)
- PanelView: 상태별 조건부 렌더링
- AddressBar: 브레드크럼 + 편집 모드
- RemoteSelectorView: 리모트 그리드 선택
```

---

## Task 9: FileList + FileItem + 컨텍스트 메뉴 재작성

기존 TypeScript의 `FileList.tsx`, `FileItem.tsx`, `ContextMenu.tsx` 동작 재현. 가장 복잡한 컴포넌트.

**Files:**
- Rewrite: `RcloneGUI/Views/FileTableView.swift`
- Create: `RcloneGUI/Views/FileRowView.swift`
- Rewrite: `RcloneGUI/Views/ContextMenuBuilder.swift`
- Rewrite: `RcloneGUI/Views/NewFolderSheet.swift`
- Rewrite: `RcloneGUI/Views/ConfirmDeleteSheet.swift`
- Create: `RcloneGUI/Views/RenameSheet.swift`
- Create: `RcloneGUI/Views/PropertiesSheet.swift`

- [ ] **Step 1: FileTableView — 정렬 + 선택 + 더블클릭**

기존 TypeScript `FileList.tsx`:
- 컬럼 헤더: Name(↑↓) / Size(↑↓) / Modified(↑↓) 정렬 토글
- 더블클릭 폴더 → navigate
- 싱글클릭 → select (Cmd/Ctrl = 토글)
- 우클릭 → 컨텍스트 메뉴
- 드래그 시작 → `{ side, fileName, isDir }` JSON
- 드롭 수신 → Alt키=이동, 그외=복사
- 새 폴더 모드: 인라인 텍스트 필드

- [ ] **Step 2: FileRowView — 아이콘 + 이름 + 크기 + 날짜**

기존 TypeScript `FileItem.tsx`:
- 아이콘 (폴더/이미지/비디오/오디오/문서/압축/코드/기본)
- 이름 (리네이밍 중이면 텍스트 필드)
- 크기 (디렉토리면 '-')
- 수정일 (YYYY-MM-DD HH:MM)
- draggable

- [ ] **Step 3: ContextMenuBuilder — 파일/빈영역 메뉴**

기존 TypeScript `ContextMenu.tsx`:
- **파일 메뉴:** Open(폴더만) / 구분선 / Cut / Copy / 구분선 / Rename / Delete(danger) / 구분선 / Properties
- **빈 영역 메뉴:** Paste(클립보드 없으면 disabled) / 구분선 / New Folder

- [ ] **Step 4: PropertiesSheet**

기존 TypeScript `PropertiesModal.tsx`:
- 기본 정보: Name, Type, Size, Modified, Path
- Remote 정보
- Hash (파일만): MD5, SHA1 — `hashFile` API 호출

- [ ] **Step 5: RenameSheet — 인라인 리네이밍**

- [ ] **Step 6: 커밋**

```
feat: FileList + 컨텍스트 메뉴 전면 재작성

- FileTableView: 정렬/선택/더블클릭/드래그앤드롭
- FileRowView: 확장자별 아이콘, 인라인 리네이밍
- ContextMenuBuilder: 파일/빈영역 메뉴 (TypeScript 1:1)
- PropertiesSheet: 파일 속성 + 해시
```

---

## Task 10: TransferQueue UI 재작성

기존 TypeScript `TransferQueue.tsx` 동작 재현.

**Files:**
- Rewrite: `RcloneGUI/Views/TransferPanelView.swift`
- Rewrite: `RcloneGUI/Views/TransferItemView.swift`

- [ ] **Step 1: TransferPanelView — 3탭 + 컨텍스트 메뉴**

기존 TypeScript:
- 탭: Active / Completed / Errors
- Active: 실행 중 전송 + 중지된 전송(재시작 가능)
- Completed: 성공한 전송만
- Errors: 실패한 전송 (에러 메시지 표시)
- 컨텍스트 메뉴: Stop / Restart / Remove / Clear
- 툴바: Pause All / Resume / Stop All / Clear History
- 일시정지 배너: paused=true일 때 표시

- [ ] **Step 2: TransferItemView — 진행률 바**

기존 TypeScript:
- Active: 파일명, bytes/total, 속도, ETA, 퍼센트 바
- Completed: 파일명, 크기
- Error: 파일명, 에러 메시지 (아래)

- [ ] **Step 3: 커밋**

```
feat: TransferQueue UI 재작성

- 3탭 (Active/Completed/Errors) + 컨텍스트 메뉴
- 실시간 진행률 바, 속도, ETA
- Pause/Resume/Stop All 기능
- 중지된 전송 재시작
```

---

## Task 11: AccountSetup UI 재작성

기존 TypeScript `AccountSetup.tsx` 동작 재현 — 프로바이더 동적 필드.

**Files:**
- Rewrite: `RcloneGUI/Views/AccountListView.swift`
- Rewrite: `RcloneGUI/Views/AccountSetupView.swift`

- [ ] **Step 1: AccountSetupView — 프로바이더 동적 필드**

기존 TypeScript 단계:
1. 기존 리모트 카드 목록 (편집/삭제 버튼)
2. Pick Provider: 프로바이더 목록에서 선택
3. Create: 이름 입력 + 프로바이더별 필드 (Required + Advanced 토글)
4. Edit: 기존 설정 로드 → 필드 수정 → 저장 (delete + create)

필드 필터링 규칙:
- `Hide > 0` → 숨김
- `Advanced && !showAdvanced` → 숨김
- `Required` → 항상 표시
- 비밀번호 필드 → SecureField

- [ ] **Step 2: 커밋**

```
feat: AccountSetup 재작성 — 프로바이더 동적 필드 + 편집
```

---

## Task 12: StatusBar 재작성

**Files:**
- Rewrite: `RcloneGUI/Views/StatusBarView.swift`

- [ ] **Step 1: StatusBarView**

기존 TypeScript `StatusBar.tsx`:
- 왼쪽: rclone 버전 정보
- 중앙: 활성 전송 수 + 전체 속도
- 오른쪽: 에러 표시기 (팝오버로 에러 목록)

- [ ] **Step 2: 커밋**

```
feat: StatusBar 재작성 — 버전/전송 속도/에러 표시
```

---

## Task 13: i18n 보강 — 기존 150+ 키 모두 포팅

기존 TypeScript `i18n.ts`의 모든 번역 키를 `Localizable.xcstrings`에 추가.

**Files:**
- Rewrite: `RcloneGUI/Resources/Localizable.xcstrings`

- [ ] **Step 1: 기존 TypeScript i18n 키 전체 포팅**

기존에 37개만 있었으나, TypeScript에는 150+ 키가 있음. 모두 추가.

- [ ] **Step 2: 커밋**

```
feat: i18n 보강 — 기존 150+ 번역 키 모두 포팅
```

---

## Task 14: 통합 빌드 + 수동 테스트

- [ ] **Step 1: Xcode 빌드 확인**
- [ ] **Step 2: xcodegen 재생성 (새 파일 반영)**
- [ ] **Step 3: 앱 실행 + 기능 테스트 체크리스트**

체크리스트:
1. 앱 시작 → librclone 초기화
2. 로컬 파일시스템 탐색
3. 폴더 더블클릭 진입
4. 상위 폴더 이동
5. 브레드크럼 네비게이션
6. 파일 정렬 (이름/크기/날짜)
7. 파일 선택 (단일/다중)
8. 컨텍스트 메뉴 (복사/잘라내기/붙여넣기/삭제/새폴더/속성)
9. 새 폴더 생성
10. 파일/폴더 삭제
11. 파일 이름 변경
12. 전송 큐 (Active/Completed/Errors)
13. 계정 추가 (프로바이더 필드)
14. 계정 삭제
15. 탭 추가/전환/삭제
16. 패널 리사이즈
17. 전송 영역 리사이즈
18. 한국어/영어 전환

- [ ] **Step 4: 발견된 이슈 수정 + 커밋**

---

## 의존 관계 요약

```
Task 1 (API 보강) ←── Task 2 (클립보드) ←── Task 3 (PanelVM)
                  ←── Task 4 (TransferVM)
                  ←── Task 5 (AccountVM)
                                              ↓
Task 6 (AppState + Utils) ←── Task 7 (ContentView + Toolbar)
                           ←── Task 8 (Panel + TabBar)
                           ←── Task 9 (FileList)
                           ←── Task 10 (TransferQueue)
                           ←── Task 11 (AccountSetup)
                           ←── Task 12 (StatusBar)
                           ←── Task 13 (i18n)
                                              ↓
                              Task 14 (통합 테스트)
```

**병렬 가능:**
- Task 2 + Task 4 + Task 5 (모두 Task 1에만 의존)
- Task 8 + Task 9 + Task 10 + Task 11 + Task 12 (모두 Task 7에만 의존)
