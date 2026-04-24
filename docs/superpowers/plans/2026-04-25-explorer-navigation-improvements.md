# 탐색(Explorer) 내비게이션 개선 — 구현 플랜

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 탐색 패널에 뒤/앞 이동(⌘[/⌘]), 숨김 파일 토글(⌘.), 현재 폴더 빠른 필터(⌘F)를 추가한다.

**Architecture:** 히스토리와 필터 상태는 `TabState`(탭별), 숨김 토글은 `PanelSideState`(패널별 뷰 환경설정)에 배치한다. `TabState.visibleFiles(showHidden:)` 계산 메서드가 정렬 → 숨김 필터링 → 이름 필터링을 순서대로 적용하며 내부 캐시로 반복 호출을 방지한다. 사용자 내비게이션은 `PanelViewModel.loadFiles`에서 히스토리 기록을 수행하고, `goBack/goForward`는 `recordHistory:false, skipLinkedSync:true`로 히스토리/링크 동기화를 우회한다.

**Tech Stack:** Swift 5.10+, SwiftUI (macOS 14+), `@Observable`, Swift Testing (`@Test` 매크로), XcodeGen, librclone(FFI — 본 플랜은 변경 없음).

**Spec:** [docs/superpowers/specs/2026-04-25-explorer-navigation-improvements-design.md](../specs/2026-04-25-explorer-navigation-improvements-design.md)

---

## 사전 메모: 단축키 충돌 해결

현재 `RcloneGUI/App.swift`는 ⌘F를 전역 검색(`.requestSearch`)에 바인딩하고 있다. 스펙의 "⌘F로 퀵 필터"와 충돌한다. 해결:

- **⌘F** → 퀵 필터(활성 패널 내 현재 폴더 필터) — 브라우저/VS Code 관례와 일치
- **⇧⌘F** → 전역 검색(기존 `.requestSearch`) — 이동

이 결정은 Task 5에서 반영한다.

---

## 파일 구조

| 경로 | 작업 | 책임 |
|------|------|------|
| `RcloneGUI/ViewModels/PanelViewModel.swift` | 수정 | `NavEntry`, `TabState` 히스토리/필터 필드·메서드, `PanelSideState.showHidden`, `PanelViewModel.loadFiles` 시그니처 확장, `goBack/goForward` |
| `RcloneGUI/App.swift` | 수정 | Notification.Name 추가, 메뉴/단축키 재배치 |
| `RcloneGUI/Views/FilePanePathBar.swift` | 수정 | ← / → 버튼, 숨김 토글 눈 아이콘 |
| `RcloneGUI/Views/FilePane.swift` | 수정 | 빠른 필터 바 subview, ⌘F/⌘[/⌘]/⌘. Notification 수신 |
| `RcloneGUI/Views/FileTableView.swift` | 수정 | `tab.visibleFiles(showHidden:)` 사용, 카운트 표시 업데이트, 필터 결과 빈 UI |
| `RcloneGUI/Utilities/L10n.swift` | 수정 | 10개 신규 키 추가(ko/en) |
| `RcloneGUITests/PanelViewModelTests.swift` | 수정 | 히스토리/필터/숨김 테스트 추가 |

---

## Task 1: NavEntry 값타입 + TabState 히스토리 필드

**Files:**
- Modify: `RcloneGUI/ViewModels/PanelViewModel.swift` (NavEntry 정의, TabState 확장)
- Modify: `RcloneGUITests/PanelViewModelTests.swift` (신규 테스트 스위트 추가)

- [ ] **Step 1: 테스트 작성 — 히스토리 push/pop 기본 동작**

`RcloneGUITests/PanelViewModelTests.swift`의 파일 끝(마지막 `}` 다음)에 추가:

```swift
@Suite("TabState History")
struct TabStateHistoryTests {
    @Test("pushHistory appends entry") @MainActor
    func pushAppends() {
        let tab = TabState(label: "t", mode: .cloud, remote: "gdrive:", path: "")
        tab.pushHistory(NavEntry(remote: "gdrive:", path: "A"))
        #expect(tab.backStack.count == 1)
        #expect(tab.backStack.last == NavEntry(remote: "gdrive:", path: "A"))
    }

    @Test("pushHistory ignores empty entry") @MainActor
    func pushIgnoresEmpty() {
        let tab = TabState(label: "t", mode: .cloud, remote: "gdrive:", path: "")
        tab.pushHistory(NavEntry(remote: "", path: ""))
        #expect(tab.backStack.isEmpty)
    }

    @Test("pushHistory caps at maxHistory") @MainActor
    func pushCaps() {
        let tab = TabState(label: "t", mode: .cloud, remote: "gdrive:", path: "")
        for i in 0..<(TabState.maxHistory + 5) {
            tab.pushHistory(NavEntry(remote: "gdrive:", path: "\(i)"))
        }
        #expect(tab.backStack.count == TabState.maxHistory)
        #expect(tab.backStack.first?.path == "5")
    }

    @Test("popBack returns last and pushes current to forward") @MainActor
    func popBackFlow() {
        let tab = TabState(label: "t", mode: .cloud, remote: "gdrive:", path: "B")
        tab.pushHistory(NavEntry(remote: "gdrive:", path: "A"))
        let current = NavEntry(remote: "gdrive:", path: "B")
        let result = tab.popBack(current: current)
        #expect(result == NavEntry(remote: "gdrive:", path: "A"))
        #expect(tab.backStack.isEmpty)
        #expect(tab.forwardStack.last == current)
    }

    @Test("popBack returns nil when empty") @MainActor
    func popBackEmpty() {
        let tab = TabState(label: "t", mode: .cloud, remote: "gdrive:", path: "")
        #expect(tab.popBack(current: NavEntry(remote: "gdrive:", path: "")) == nil)
    }

    @Test("popForward returns last and pushes current to back") @MainActor
    func popForwardFlow() {
        let tab = TabState(label: "t", mode: .cloud, remote: "gdrive:", path: "A")
        tab.forwardStack.append(NavEntry(remote: "gdrive:", path: "B"))
        let current = NavEntry(remote: "gdrive:", path: "A")
        let result = tab.popForward(current: current)
        #expect(result == NavEntry(remote: "gdrive:", path: "B"))
        #expect(tab.forwardStack.isEmpty)
        #expect(tab.backStack.last == current)
    }

    @Test("clearForward empties forwardStack") @MainActor
    func clearForward() {
        let tab = TabState(label: "t", mode: .cloud, remote: "gdrive:", path: "")
        tab.forwardStack.append(NavEntry(remote: "gdrive:", path: "X"))
        tab.clearForward()
        #expect(tab.forwardStack.isEmpty)
    }

    @Test("NavEntry isEmpty true for empty strings") @MainActor
    func navEntryEmpty() {
        #expect(NavEntry(remote: "", path: "").isEmpty == true)
        #expect(NavEntry(remote: "gdrive:", path: "").isEmpty == false)
        #expect(NavEntry(remote: "", path: "A").isEmpty == false)
    }
}
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `xcodebuild -scheme RcloneGUI -destination 'platform=macOS' test -only-testing:RcloneGUITests/TabStateHistoryTests 2>&1 | tail -20`

Expected: 컴파일 에러 — `NavEntry`, `TabState.pushHistory`, `TabState.maxHistory` 미정의.

- [ ] **Step 3: 최소 구현 — `NavEntry` + `TabState` 히스토리 필드 추가**

`RcloneGUI/ViewModels/PanelViewModel.swift`의 `struct DraggedFile` 바로 다음(약 36행 근처)에 추가:

```swift
struct NavEntry: Equatable, Codable {
    let remote: String
    let path: String

    var isEmpty: Bool { remote.isEmpty && path.isEmpty }
}
```

같은 파일 `@Observable @MainActor final class TabState: Identifiable {` 블록 내, 기존 `var selectedFiles: Set<String> = []` 아래에 추가(약 48행 뒤):

```swift
    var backStack: [NavEntry] = []
    var forwardStack: [NavEntry] = []

    static let maxHistory = 50
```

같은 TabState 클래스의 `private func computeSortedFiles()` 선언 **앞**(`private var _cachedSortedFiles: [FileItem]?` 바로 뒤, 약 53행)에 추가:

```swift
    // MARK: - History

    func pushHistory(_ entry: NavEntry) {
        guard !entry.isEmpty else { return }
        backStack.append(entry)
        if backStack.count > Self.maxHistory {
            backStack.removeFirst(backStack.count - Self.maxHistory)
        }
    }

    func popBack(current: NavEntry) -> NavEntry? {
        guard let entry = backStack.popLast() else { return nil }
        if !current.isEmpty {
            forwardStack.append(current)
            if forwardStack.count > Self.maxHistory {
                forwardStack.removeFirst(forwardStack.count - Self.maxHistory)
            }
        }
        return entry
    }

    func popForward(current: NavEntry) -> NavEntry? {
        guard let entry = forwardStack.popLast() else { return nil }
        if !current.isEmpty {
            backStack.append(current)
            if backStack.count > Self.maxHistory {
                backStack.removeFirst(backStack.count - Self.maxHistory)
            }
        }
        return entry
    }

    func clearForward() {
        forwardStack.removeAll()
    }
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `xcodebuild -scheme RcloneGUI -destination 'platform=macOS' test -only-testing:RcloneGUITests/TabStateHistoryTests 2>&1 | tail -10`

Expected: `** TEST SUCCEEDED **` 또는 PanelViewModelTabTests와 함께 모두 PASS.

- [ ] **Step 5: 커밋**

```bash
git add RcloneGUI/ViewModels/PanelViewModel.swift RcloneGUITests/PanelViewModelTests.swift
git commit -m "$(cat <<'EOF'
feat: TabState에 NavEntry 히스토리 스택 추가

탐색 back/forward 이동의 기반. pushHistory/popBack/popForward/clearForward
+ 50개 상한 캡핑. 테스트 스위트 TabStateHistoryTests 8종 추가.
EOF
)"
```

---

## Task 2: 필터/숨김 상태 + visibleFiles(showHidden:) 메서드

**Files:**
- Modify: `RcloneGUI/ViewModels/PanelViewModel.swift`
- Modify: `RcloneGUITests/PanelViewModelTests.swift`

- [ ] **Step 1: 테스트 작성 — visibleFiles 필터링 조합**

`RcloneGUITests/PanelViewModelTests.swift` 파일 끝에 추가:

```swift
@Suite("TabState VisibleFiles")
struct TabStateVisibleFilesTests {
    @MainActor
    private func makeTab() -> TabState {
        let tab = TabState(label: "t", mode: .local, remote: "/", path: "")
        tab.files = [
            FileItem(path: "a.txt", name: "a.txt", size: 10, modTime: Date(timeIntervalSince1970: 1), isDir: false, mimeType: nil),
            FileItem(path: ".hidden", name: ".hidden", size: 0, modTime: Date(timeIntervalSince1970: 2), isDir: false, mimeType: nil),
            FileItem(path: "Report.PDF", name: "Report.PDF", size: 100, modTime: Date(timeIntervalSince1970: 3), isDir: false, mimeType: nil),
            FileItem(path: "folder", name: "folder", size: 0, modTime: Date(timeIntervalSince1970: 4), isDir: true, mimeType: nil)
        ]
        return tab
    }

    @Test("visibleFiles hides dot-prefixed when showHidden=false") @MainActor
    func hidesDotFiles() {
        let tab = makeTab()
        let visible = tab.visibleFiles(showHidden: false)
        #expect(visible.count == 3)
        #expect(!visible.contains { $0.name == ".hidden" })
    }

    @Test("visibleFiles keeps dot-prefixed when showHidden=true") @MainActor
    func showsDotFiles() {
        let tab = makeTab()
        let visible = tab.visibleFiles(showHidden: true)
        #expect(visible.count == 4)
        #expect(visible.contains { $0.name == ".hidden" })
    }

    @Test("visibleFiles applies filterQuery case-insensitive") @MainActor
    func filterCaseInsensitive() {
        let tab = makeTab()
        tab.filterQuery = "report"
        let visible = tab.visibleFiles(showHidden: true)
        #expect(visible.count == 1)
        #expect(visible.first?.name == "Report.PDF")
    }

    @Test("visibleFiles empty filterQuery returns all") @MainActor
    func emptyFilterReturnsAll() {
        let tab = makeTab()
        tab.filterQuery = ""
        let visible = tab.visibleFiles(showHidden: true)
        #expect(visible.count == 4)
    }

    @Test("visibleFiles combines hidden + filter") @MainActor
    func combinedFilters() {
        let tab = makeTab()
        tab.filterQuery = "."
        let visible = tab.visibleFiles(showHidden: false)
        // "." filter matches "a.txt", "Report.PDF"; ".hidden" excluded by showHidden
        #expect(visible.count == 2)
    }

    @Test("visibleFiles cache invalidates on files change") @MainActor
    func cacheInvalidatesOnFiles() {
        let tab = makeTab()
        _ = tab.visibleFiles(showHidden: true)
        tab.files = []
        let visible = tab.visibleFiles(showHidden: true)
        #expect(visible.isEmpty)
    }

    @Test("visibleFiles cache invalidates on filter change") @MainActor
    func cacheInvalidatesOnFilter() {
        let tab = makeTab()
        _ = tab.visibleFiles(showHidden: true)
        tab.filterQuery = "a"
        let visible = tab.visibleFiles(showHidden: true)
        #expect(visible.count == 1)
        #expect(visible.first?.name == "a.txt")
    }

    @Test("visibleFiles differs when showHidden toggles") @MainActor
    func showHiddenBoundary() {
        let tab = makeTab()
        let hidden = tab.visibleFiles(showHidden: false).count
        let shown = tab.visibleFiles(showHidden: true).count
        #expect(shown > hidden)
    }
}

@Suite("PanelSideState ShowHidden")
struct PanelSideStateShowHiddenTests {
    @Test("showHidden defaults to false") @MainActor
    func defaultFalse() {
        let vm = PanelViewModel(client: MockRcloneClient())
        #expect(vm.left.showHidden == false)
        #expect(vm.right.showHidden == false)
    }

    @Test("showHidden is independent per side") @MainActor
    func independentPerSide() {
        let vm = PanelViewModel(client: MockRcloneClient())
        vm.left.showHidden = true
        #expect(vm.left.showHidden == true)
        #expect(vm.right.showHidden == false)
    }
}
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `xcodebuild -scheme RcloneGUI -destination 'platform=macOS' test -only-testing:RcloneGUITests/TabStateVisibleFilesTests 2>&1 | tail -20`

Expected: 컴파일 실패 — `TabState.visibleFiles`, `TabState.filterQuery`, `PanelSideState.showHidden` 미정의.

- [ ] **Step 3: 최소 구현 — TabState.filterQuery, visibleFiles 메서드, PanelSideState.showHidden**

`RcloneGUI/ViewModels/PanelViewModel.swift`의 `TabState` 클래스 내, 기존 `var sortAsc: Bool = true { didSet { _cachedSortedFiles = nil } }` 바로 다음에 추가:

```swift
    var filterQuery: String = "" { didSet { _cachedVisibleFiles = nil } }
```

또한 `files`, `sortBy`, `sortAsc` 프로퍼티의 `didSet`을 다음으로 교체:

```swift
    var files: [FileItem] = [] {
        didSet { _cachedSortedFiles = nil; _cachedVisibleFiles = nil }
    }
    // ...
    var sortBy: SortField = .name {
        didSet { _cachedSortedFiles = nil; _cachedVisibleFiles = nil }
    }
    var sortAsc: Bool = true {
        didSet { _cachedSortedFiles = nil; _cachedVisibleFiles = nil }
    }
```

같은 클래스의 `private var _cachedSortedFiles: [FileItem]?` 바로 다음에 추가:

```swift
    private var _cachedVisibleFiles: [FileItem]?
    private var _cachedVisibleShowHidden: Bool?
```

같은 클래스의 `private func computeSortedFiles() -> [FileItem]` 선언 앞(히스토리 메서드들 사이)에 추가:

```swift
    // MARK: - Visible Files (hidden + filter)

    func visibleFiles(showHidden: Bool) -> [FileItem] {
        if let cached = _cachedVisibleFiles, _cachedVisibleShowHidden == showHidden {
            return cached
        }
        var result = sortedFiles
        if !showHidden {
            result = result.filter { !$0.name.hasPrefix(".") }
        }
        let q = filterQuery.trimmingCharacters(in: .whitespaces)
        if !q.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(q) }
        }
        _cachedVisibleFiles = result
        _cachedVisibleShowHidden = showHidden
        return result
    }
```

`@Observable @MainActor final class PanelSideState` 블록 내, 기존 `var viewMode: ViewMode = .list` 아래에 추가:

```swift
    var showHidden: Bool = false
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `xcodebuild -scheme RcloneGUI -destination 'platform=macOS' test -only-testing:RcloneGUITests/TabStateVisibleFilesTests -only-testing:RcloneGUITests/PanelSideStateShowHiddenTests 2>&1 | tail -10`

Expected: `** TEST SUCCEEDED **` 10개 PASS.

- [ ] **Step 5: 기존 테스트 회귀 없음 확인**

Run: `xcodebuild -scheme RcloneGUI -destination 'platform=macOS' test -only-testing:RcloneGUITests/PanelViewModelTabTests 2>&1 | tail -10`

Expected: 기존 PanelViewModelTabTests 전체 PASS.

- [ ] **Step 6: 커밋**

```bash
git add RcloneGUI/ViewModels/PanelViewModel.swift RcloneGUITests/PanelViewModelTests.swift
git commit -m "$(cat <<'EOF'
feat: TabState.visibleFiles + PanelSideState.showHidden

숨김 필터(.으로 시작하는 이름 제거)와 이름 쿼리 필터를 정렬 결과 위에
컴포즈. 내부 캐시 _cachedVisibleFiles로 반복 호출 방지. 숨김 토글은
패널별(PanelSideState) 뷰 환경설정.
EOF
)"
```

---

## Task 3: PanelViewModel.loadFiles 히스토리 훅 + goBack/goForward

**Files:**
- Modify: `RcloneGUI/ViewModels/PanelViewModel.swift`
- Modify: `RcloneGUITests/PanelViewModelTests.swift`

- [ ] **Step 1: 테스트 작성 — goBack/goForward 플로우**

`RcloneGUITests/PanelViewModelTests.swift` 파일 끝에 추가:

```swift
@Suite("PanelViewModel History Navigation")
struct PanelHistoryTests {
    @MainActor
    private func makeVM() -> (PanelViewModel, MockRcloneClient) {
        let client = MockRcloneClient()
        let vm = PanelViewModel(client: client)
        // Set up left panel as local with a known path
        vm.left.activeTab.mode = .local
        vm.left.activeTab.remote = "/"
        vm.left.activeTab.path = ""
        // Mock operations/list returns empty list for any path
        client.responses["operations/list"] = ["list": []]
        return (vm, client)
    }

    @Test("loadFiles pushes previous entry to history") @MainActor
    func loadPushesHistory() async {
        let (vm, _) = makeVM()
        vm.left.activeTab.path = "A"
        await vm.loadFiles(side: .left, path: "A/B")
        #expect(vm.left.activeTab.backStack.last == NavEntry(remote: "/", path: "A"))
        #expect(vm.left.activeTab.path == "A/B")
    }

    @Test("loadFiles clears forwardStack") @MainActor
    func loadClearsForward() async {
        let (vm, _) = makeVM()
        vm.left.activeTab.forwardStack.append(NavEntry(remote: "/", path: "X"))
        await vm.loadFiles(side: .left, path: "A")
        #expect(vm.left.activeTab.forwardStack.isEmpty)
    }

    @Test("loadFiles with recordHistory:false does not push") @MainActor
    func loadSkipHistory() async {
        let (vm, _) = makeVM()
        vm.left.activeTab.path = "A"
        await vm.loadFiles(side: .left, path: "B", recordHistory: false)
        #expect(vm.left.activeTab.backStack.isEmpty)
    }

    @Test("loadFiles clears filter on path change") @MainActor
    func loadClearsFilter() async {
        let (vm, _) = makeVM()
        vm.left.activeTab.filterQuery = "test"
        await vm.loadFiles(side: .left, path: "A")
        #expect(vm.left.activeTab.filterQuery == "")
    }

    @Test("goBack navigates to previous entry") @MainActor
    func goBackPrevious() async {
        let (vm, _) = makeVM()
        await vm.loadFiles(side: .left, path: "A")
        await vm.loadFiles(side: .left, path: "A/B")
        await vm.goBack(side: .left)
        #expect(vm.left.activeTab.path == "A")
        #expect(vm.left.activeTab.forwardStack.last == NavEntry(remote: "/", path: "A/B"))
    }

    @Test("goForward restores forward entry") @MainActor
    func goForwardRestores() async {
        let (vm, _) = makeVM()
        await vm.loadFiles(side: .left, path: "A")
        await vm.loadFiles(side: .left, path: "A/B")
        await vm.goBack(side: .left)
        await vm.goForward(side: .left)
        #expect(vm.left.activeTab.path == "A/B")
    }

    @Test("goBack is no-op when backStack empty") @MainActor
    func goBackNoOp() async {
        let (vm, _) = makeVM()
        let initialPath = vm.left.activeTab.path
        await vm.goBack(side: .left)
        #expect(vm.left.activeTab.path == initialPath)
    }

    @Test("new navigation after goBack clears forwardStack") @MainActor
    func newNavClearsForward() async {
        let (vm, _) = makeVM()
        await vm.loadFiles(side: .left, path: "A")
        await vm.loadFiles(side: .left, path: "A/B")
        await vm.goBack(side: .left)
        await vm.loadFiles(side: .left, path: "C")
        #expect(vm.left.activeTab.forwardStack.isEmpty)
    }
}
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `xcodebuild -scheme RcloneGUI -destination 'platform=macOS' test -only-testing:RcloneGUITests/PanelHistoryTests 2>&1 | tail -20`

Expected: 컴파일 실패 — `loadFiles`에 `recordHistory` 파라미터 없음, `goBack`/`goForward` 미정의.

- [ ] **Step 3: 구현 — loadFiles 시그니처 확장 + 히스토리 훅 + goBack/goForward**

`RcloneGUI/ViewModels/PanelViewModel.swift`의 현재 `func loadFiles(side panelSide: PanelSide, remote: String? = nil, path: String? = nil) async {` 함수를 통째로 다음으로 교체:

```swift
    func loadFiles(side panelSide: PanelSide, remote: String? = nil, path: String? = nil,
                   recordHistory: Bool = true, skipLinkedSync: Bool = false) async {
        let tab = side(panelSide).activeTab
        let fs = remote ?? tab.remote
        let dir = path ?? tab.path
        let prev = NavEntry(remote: tab.remote, path: tab.path)
        let next = NavEntry(remote: fs, path: dir)

        if prev != next {
            if recordHistory && !prev.isEmpty {
                tab.pushHistory(prev)
                tab.clearForward()
            }
            // Clear quick filter on path/remote change
            tab.filterQuery = ""
        }

        tab.loading = true
        tab.error = nil

        do {
            let items = try await RcloneAPI.listFiles(using: client, fs: fs, remote: dir)
            tab.files = items
            if let r = remote { tab.remote = r }
            if let p = path { tab.path = p }
            // Index for Spotlight (background, non-blocking)
            Task.detached(priority: .background) {
                SpotlightIndexer.shared.indexFiles(remote: fs, path: dir, files: items)
            }
        } catch {
            tab.error = error.localizedDescription
        }

        tab.loading = false

        // Linked browsing: sync other panel to same path
        if linkedBrowsing && !isSyncingLinked && !skipLinkedSync {
            isSyncingLinked = true
            let otherSide: PanelSide = panelSide == .left ? .right : .left
            let targetPath = path ?? tab.path
            let otherTab = side(otherSide).activeTab
            if otherTab.path != targetPath {
                await loadFiles(side: otherSide, path: targetPath)
            }
            isSyncingLinked = false
        }
    }

    func goBack(side panelSide: PanelSide) async {
        let tab = side(panelSide).activeTab
        let current = NavEntry(remote: tab.remote, path: tab.path)
        guard let target = tab.popBack(current: current) else { return }
        tab.selectedFiles = []
        await loadFiles(side: panelSide, remote: target.remote, path: target.path,
                        recordHistory: false, skipLinkedSync: true)
    }

    func goForward(side panelSide: PanelSide) async {
        let tab = side(panelSide).activeTab
        let current = NavEntry(remote: tab.remote, path: tab.path)
        guard let target = tab.popForward(current: current) else { return }
        tab.selectedFiles = []
        await loadFiles(side: panelSide, remote: target.remote, path: target.path,
                        recordHistory: false, skipLinkedSync: true)
    }
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `xcodebuild -scheme RcloneGUI -destination 'platform=macOS' test -only-testing:RcloneGUITests/PanelHistoryTests 2>&1 | tail -10`

Expected: `** TEST SUCCEEDED **` 8 PASS.

- [ ] **Step 5: 기존 테스트 회귀 없음 전체 확인**

Run: `xcodebuild -scheme RcloneGUI -destination 'platform=macOS' test -only-testing:RcloneGUITests/PanelViewModelTabTests -only-testing:RcloneGUITests/TabStateHistoryTests -only-testing:RcloneGUITests/TabStateVisibleFilesTests 2>&1 | tail -10`

Expected: 모두 PASS.

- [ ] **Step 6: 커밋**

```bash
git add RcloneGUI/ViewModels/PanelViewModel.swift RcloneGUITests/PanelViewModelTests.swift
git commit -m "$(cat <<'EOF'
feat: PanelViewModel goBack/goForward + loadFiles 히스토리 훅

loadFiles에 recordHistory/skipLinkedSync 옵션 추가. 경로 변경 시 이전
엔트리 히스토리 푸시, forwardStack 무효화, filterQuery 클리어. back/forward는
로컬 동작으로 링크드 브라우징 동기화 우회.
EOF
)"
```

---

## Task 4: Notification.Name 추가 + 메뉴/단축키 재배치

**Files:**
- Modify: `RcloneGUI/App.swift`

- [ ] **Step 1: Notification.Name에 4개 신규 추가**

`RcloneGUI/App.swift`의 `extension Notification.Name { ... }` 블록(6~17행 근처)에 다음 4줄을 `requestExplorer` 다음에 추가:

```swift
    static let requestBack = Notification.Name("requestBack")
    static let requestForward = Notification.Name("requestForward")
    static let requestToggleHidden = Notification.Name("requestToggleHidden")
    static let requestQuickFilter = Notification.Name("requestQuickFilter")
```

- [ ] **Step 2: 메뉴 단축키 재배치**

`RcloneGUI/App.swift` 83~98행 근처의 `CommandGroup(after: .toolbar) { ... }` 블록을 다음으로 교체:

```swift
            CommandGroup(after: .toolbar) {
                Button("Back") {
                    NotificationCenter.default.post(name: .requestBack, object: nil)
                }
                .keyboardShortcut("[", modifiers: .command)

                Button("Forward") {
                    NotificationCenter.default.post(name: .requestForward, object: nil)
                }
                .keyboardShortcut("]", modifiers: .command)

                Divider()

                Button("Quick Filter") {
                    NotificationCenter.default.post(name: .requestQuickFilter, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)

                Button("Search") {
                    NotificationCenter.default.post(name: .requestSearch, object: nil)
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])

                Button("Toggle Hidden Files") {
                    NotificationCenter.default.post(name: .requestToggleHidden, object: nil)
                }
                .keyboardShortcut(".", modifiers: .command)

                Divider()

                Button("Quick Look") {
                    NotificationCenter.default.post(name: .requestQuickLook, object: nil)
                }
                .keyboardShortcut(" ", modifiers: [])

                Button("Bookmark") {
                    NotificationCenter.default.post(name: .requestBookmark, object: nil)
                }
                .keyboardShortcut("d", modifiers: .command)
            }
```

- [ ] **Step 3: 빌드 확인**

Run: `xcodebuild -scheme RcloneGUI -configuration Debug build 2>&1 | grep "warning:\|error:" | grep -v "export\|Run script" | sort -u`

Expected: 출력 없음(경고 0).

- [ ] **Step 4: 커밋**

```bash
git add RcloneGUI/App.swift
git commit -m "$(cat <<'EOF'
feat: 탐색 단축키 추가 (⌘[/⌘]/⌘F/⌘./⇧⌘F)

Back/Forward/Quick Filter/Toggle Hidden 메뉴 항목 추가. 기존 ⌘F
전역 검색은 ⇧⌘F로 재배치(VS Code/브라우저 관례와 일치). Notification.Name
4종(requestBack, requestForward, requestToggleHidden, requestQuickFilter)
추가.
EOF
)"
```

---

## Task 5: FilePanePathBar — back/forward 버튼 + 숨김 토글

**Files:**
- Modify: `RcloneGUI/Views/FilePanePathBar.swift`

- [ ] **Step 1: back/forward 버튼 추가 (경로바 최좌측)**

`RcloneGUI/Views/FilePanePathBar.swift`의 `var body: some View { HStack(spacing: 6) { ... } }` 블록 내부, 기존 "Up button" 주석이 있는 Button 바로 **앞**에 다음 두 버튼 추가:

```swift
            // Back button
            Button(action: { Task { await appState.panels.goBack(side: side) } }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundColor(tab.backStack.isEmpty ? .secondary.opacity(0.3) : .secondary)
            .disabled(tab.backStack.isEmpty)
            .help(L10n.t("panel.back"))

            // Forward button
            Button(action: { Task { await appState.panels.goForward(side: side) } }) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundColor(tab.forwardStack.isEmpty ? .secondary.opacity(0.3) : .secondary)
            .disabled(tab.forwardStack.isEmpty)
            .help(L10n.t("panel.forward"))
```

- [ ] **Step 2: 숨김 토글 버튼 추가 (기존 View mode 토글 앞)**

같은 파일의 "View mode toggle" 주석이 있는 Button 바로 **앞**에 추가(약 94행 근처):

```swift
            // Show hidden toggle
            Button(action: {
                appState.panels.side(side).showHidden.toggle()
            }) {
                Image(systemName: appState.panels.side(side).showHidden ? "eye.fill" : "eye.slash")
                    .font(.system(size: 11))
                    .foregroundColor(appState.panels.side(side).showHidden ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .help(appState.panels.side(side).showHidden
                  ? L10n.t("panel.hideHidden") : L10n.t("panel.showHidden"))
```

- [ ] **Step 3: 빌드 확인**

Run: `xcodebuild -scheme RcloneGUI -configuration Debug build 2>&1 | grep "warning:\|error:" | grep -v "export\|Run script" | sort -u`

Expected: 출력 없음.

- [ ] **Step 4: 커밋**

```bash
git add RcloneGUI/Views/FilePanePathBar.swift
git commit -m "$(cat <<'EOF'
feat: FilePanePathBar back/forward 버튼 + 숨김 토글

경로바 최좌측에 ←/→ 버튼(스택 비어있을 때 비활성/흐림), 별 아이콘과
뷰모드 토글 사이에 eye/eye.slash 버튼. L10n 키는 다음 커밋에서 추가.
EOF
)"
```

---

## Task 6: FilePane — 빠른 필터 바 + Notification 수신

**Files:**
- Modify: `RcloneGUI/Views/FilePane.swift`

- [ ] **Step 1: FilePane에 @State 및 필터 바 서브뷰 추가**

`RcloneGUI/Views/FilePane.swift`의 `struct FilePane: View { ... }` 내부, 기존 프로퍼티 `private var tab: TabState { sideState.activeTab }` 다음에 추가:

```swift
    @State private var showQuickFilter: Bool = false
    @FocusState private var quickFilterFocused: Bool
```

같은 struct의 `var body: some View { VStack(spacing: 0) { ... } }` 내부, 기존 `FilePaneTabBar(side: side)` 바로 다음, `FilePanePathBar(side: side)` 바로 앞 위치를 찾아 그대로 두고, 대신 `FilePanePathBar(side: side)` **다음**(기존 `Divider()` 앞)에 다음을 삽입:

```swift
            if showQuickFilter {
                quickFilterBar
                Divider()
            }
```

그리고 struct 하단(`}` 직전)에 private computed property로 다음을 추가:

```swift
    private var quickFilterBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            TextField(
                L10n.t("panel.quickFilter.placeholder"),
                text: Binding(
                    get: { appState.panels.side(side).activeTab.filterQuery },
                    set: { appState.panels.side(side).activeTab.filterQuery = $0 }
                )
            )
            .textFieldStyle(.plain)
            .font(.system(size: 12))
            .focused($quickFilterFocused)
            .onSubmit { quickFilterFocused = false }
            .onExitCommand {
                if appState.panels.side(side).activeTab.filterQuery.isEmpty {
                    showQuickFilter = false
                } else {
                    appState.panels.side(side).activeTab.filterQuery = ""
                }
            }

            if !appState.panels.side(side).activeTab.filterQuery.isEmpty {
                Button(action: {
                    appState.panels.side(side).activeTab.filterQuery = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help(L10n.t("panel.quickFilter.clear"))
            }

            Button(action: {
                appState.panels.side(side).activeTab.filterQuery = ""
                showQuickFilter = false
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help(L10n.t("close"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }
```

- [ ] **Step 2: Notification 수신 — 활성 패널 가드 포함**

같은 파일의 `var body` 반환 View의 `.simultaneousGesture(...)` 체인 바로 **앞**에 다음 modifier들을 추가:

```swift
        .onReceive(NotificationCenter.default.publisher(for: .requestBack)) { _ in
            guard appState.panels.activePanel == side else { return }
            Task { await appState.panels.goBack(side: side) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .requestForward)) { _ in
            guard appState.panels.activePanel == side else { return }
            Task { await appState.panels.goForward(side: side) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .requestToggleHidden)) { _ in
            guard appState.panels.activePanel == side else { return }
            appState.panels.side(side).showHidden.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .requestQuickFilter)) { _ in
            guard appState.panels.activePanel == side else { return }
            showQuickFilter = true
            quickFilterFocused = true
        }
```

- [ ] **Step 3: 빌드 확인**

Run: `xcodebuild -scheme RcloneGUI -configuration Debug build 2>&1 | grep "warning:\|error:" | grep -v "export\|Run script" | sort -u`

Expected: 출력 없음.

- [ ] **Step 4: 커밋**

```bash
git add RcloneGUI/Views/FilePane.swift
git commit -m "$(cat <<'EOF'
feat: FilePane 빠른 필터 바 + 탐색 Notification 수신

⌘F로 필터 바 오픈(토글), ESC로 쿼리 클리어→재ESC로 바 닫힘, ✕ 버튼으로
즉시 닫기. requestBack/requestForward/requestToggleHidden/requestQuickFilter
4종 모두 활성 패널 가드 포함.
EOF
)"
```

---

## Task 7: FileTableView — visibleFiles 연결 + 카운트/빈 결과 UI

**Files:**
- Modify: `RcloneGUI/Views/FileTableView.swift`

- [ ] **Step 1: 필터 결과 참조를 sortedFiles → visibleFiles로 교체**

`RcloneGUI/Views/FileTableView.swift`의 `var body` 내에서 `tab.sortedFiles`를 사용하는 모든 지점(현재 5곳)을 `visibleFiles`로 교체한다. 먼저 body 최상단, `VStack(spacing: 0) {` 직후에 로컬 상수 추가:

```swift
        let showHidden = appState.panels.side(side).showHidden
        let visibleFiles = tab.visibleFiles(showHidden: showHidden)
        let hasFilter = !tab.filterQuery.isEmpty
```

그다음 body 내 다음 지점을 교체:

1. `if tab.sortedFiles.isEmpty && !tab.loading {` → `if visibleFiles.isEmpty && !tab.loading {`
2. `Text(String(format: L10n.t("performance.fileCount"), tab.sortedFiles.count))` → 다음과 같이 교체:

```swift
                Text(hasFilter
                     ? L10n.t("panel.quickFilter.count",
                              String(visibleFiles.count),
                              String(tab.files.count))
                     : String(format: L10n.t("performance.fileCount"), visibleFiles.count))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
```

3. `if tab.sortedFiles.count > 1000 {` → `if visibleFiles.count > 1000 {`
4. `ForEach(tab.sortedFiles) { file in gridCell(file) }` → `ForEach(visibleFiles) { file in gridCell(file) }`
5. `ForEach(tab.sortedFiles) { file in fileRow(file) }` → `ForEach(visibleFiles) { file in fileRow(file) }`

- [ ] **Step 2: 빈 결과(필터 매치 없음) UI 분기**

Step 1의 교체한 `if visibleFiles.isEmpty && !tab.loading {` 분기 본문을 다음으로 교체:

```swift
            if visibleFiles.isEmpty && !tab.loading {
                if hasFilter {
                    VStack(spacing: 8) {
                        ContentUnavailableView(
                            L10n.t("panel.quickFilter.noMatch"),
                            systemImage: "line.3.horizontal.decrease.circle"
                        )
                        Button(L10n.t("panel.quickFilter.clear")) {
                            tab.filterQuery = ""
                        }
                        .controlSize(.small)
                    }
                    .contentShape(Rectangle())
                    .contextMenu { emptyAreaMenu }
                } else {
                    ContentUnavailableView(L10n.t("panel.noFiles"), systemImage: "folder")
                        .contentShape(Rectangle())
                        .contextMenu { emptyAreaMenu }
                }
            } else {
                // ... (기존 else 블록 그대로 유지)
            }
```

- [ ] **Step 3: selectAdjacentFile이 visibleFiles 기반으로 동작하도록 업데이트**

같은 파일의 `private func selectAdjacentFile(direction: Int)` 함수를 통째로 교체:

```swift
    private func selectAdjacentFile(direction: Int) {
        let showHidden = appState.panels.side(side).showHidden
        let visible = tab.visibleFiles(showHidden: showHidden)
        guard !visible.isEmpty else { return }

        if let currentName = tab.selectedFiles.first,
           let currentIndex = visible.firstIndex(where: { $0.name == currentName }) {
            let newIndex = max(0, min(visible.count - 1, currentIndex + direction))
            appState.panels.clearSelection(side: side)
            appState.panels.toggleSelect(side: side, name: visible[newIndex].name)
        } else {
            appState.panels.toggleSelect(side: side, name: visible[0].name)
        }
    }
```

- [ ] **Step 4: 빌드 확인**

Run: `xcodebuild -scheme RcloneGUI -configuration Debug build 2>&1 | grep "warning:\|error:" | grep -v "export\|Run script" | sort -u`

Expected: 출력 없음.

- [ ] **Step 5: 커밋**

```bash
git add RcloneGUI/Views/FileTableView.swift
git commit -m "$(cat <<'EOF'
feat: FileTableView visibleFiles 사용 + 필터 카운트/빈 결과 UI

tab.sortedFiles 참조 5곳을 visibleFiles(showHidden:)로 교체. 필터 활성 시
'X/Y 필터됨' 카운트, 매치 없음 시 '필터 지우기' 버튼이 있는 빈 상태.
selectAdjacentFile(↑↓)도 visibleFiles 기반으로 동작.
EOF
)"
```

---

## Task 8: L10n 키 추가 + 최종 빌드/테스트 전체 통과 확인

**Files:**
- Modify: `RcloneGUI/Utilities/L10n.swift`

- [ ] **Step 1: 새 번역 키 10종 추가**

`RcloneGUI/Utilities/L10n.swift`의 `translations` 딕셔너리에서 `"panel.goUp"` 라인(약 67행)을 찾는다. 그 다음 줄부터 다음 10개 엔트리를 삽입:

```swift
        "panel.back":                  ["ko": "뒤로", "en": "Back"],
        "panel.forward":               ["ko": "앞으로", "en": "Forward"],
        "panel.showHidden":            ["ko": "숨김 파일 표시", "en": "Show Hidden Files"],
        "panel.hideHidden":            ["ko": "숨김 파일 숨기기", "en": "Hide Hidden Files"],
        "panel.quickFilter.placeholder": ["ko": "이 폴더에서 빠른 필터…", "en": "Quick filter in this folder…"],
        "panel.quickFilter.clear":     ["ko": "필터 지우기", "en": "Clear filter"],
        "panel.quickFilter.noMatch":   ["ko": "필터와 일치하는 파일 없음", "en": "No files match filter"],
        "panel.quickFilter.count":     ["ko": "{0} / {1}개 (필터됨)", "en": "{0} / {1} (filtered)"],
```

(8개만 추가 — `close`는 이미 존재, `panel.goUp`도 기존 재사용.)

- [ ] **Step 2: 빌드 경고/에러 0개 확인**

Run: `xcodebuild -scheme RcloneGUI -configuration Debug build 2>&1 | grep "warning:\|error:" | grep -v "export\|Run script" | sort -u`

Expected: 출력 없음.

- [ ] **Step 3: 전체 테스트 통과 확인**

Run: `xcodebuild -scheme RcloneGUI -destination 'platform=macOS' test 2>&1 | tail -30`

Expected: 최종 라인 `** TEST SUCCEEDED **`. 실패한 스위트가 있으면 해당 케이스를 열어 확인 후 수정.

- [ ] **Step 4: 수동 스모크 테스트(사용자 수행)**

다음 시나리오를 앱 실행하여 직접 확인:

1. 좌측 로컬 패널에서 폴더 진입 → 상위 폴더로 이동 → `⌘[` 재진입 → `⌘]` 상위 이동
2. `⌘.`로 숨김 파일(`.DS_Store`, `.git/` 등) 표시 토글
3. `⌘F`로 빠른 필터 오픈 → 이름 일부 입력 → 목록 축소 확인 → ESC → 입력 클리어 → 재ESC → 바 닫힘
4. 링크드 브라우징 ON 상태에서 좌측 패널 `⌘[` 눌러도 우측 패널이 따라 이동하지 않음을 확인
5. 필터 적용 상태에서 폴더 진입 → 새 폴더에서 필터가 자동 비워짐 확인
6. 🇰🇷/🇺🇸 언어 전환 시 새 문자열이 올바르게 표시

- [ ] **Step 5: 커밋**

```bash
git add RcloneGUI/Utilities/L10n.swift
git commit -m "$(cat <<'EOF'
feat: 탐색 내비게이션 L10n 키 추가 (ko/en)

panel.back, panel.forward, panel.showHidden, panel.hideHidden,
panel.quickFilter.placeholder, panel.quickFilter.clear,
panel.quickFilter.noMatch, panel.quickFilter.count 8종 추가.
EOF
)"
```

---

## 자체 리뷰

- **스펙 커버리지**:
  - (a) back/forward → Task 1, 3, 5, 6 (상태, VM, UI, 단축키)
  - (b) 숨김 토글 → Task 2, 5, 6 (상태, UI, 단축키)
  - (c) 빠른 필터 → Task 2, 4, 6, 7 (상태, 단축키, 바 UI, 리스트 연결)
  - L10n → Task 8
  - 테스트 전략(TabState/PanelViewModel 유닛) → Task 1, 2, 3에 각각 포함
  - 단축키 충돌(⌘F) → 플랜 상단 메모 + Task 4에서 해결
  - 검증 기준(빌드 경고 0, 전체 테스트 통과, ko/en) → Task 8 Step 2/3/5
- **Placeholder 검사**: "TBD"/"TODO"/"적절한 처리"/"필요시" 문구 없음 확인.
- **타입 일관성**: `NavEntry(remote:, path:)`/`TabState.pushHistory/popBack/popForward/clearForward`/`TabState.visibleFiles(showHidden:)`/`TabState.filterQuery`/`PanelSideState.showHidden`/`PanelViewModel.loadFiles(recordHistory:skipLinkedSync:)`/`PanelViewModel.goBack/goForward(side:)` — 모든 Task에서 동일한 이름과 시그니처 사용 확인.
- **Notification 이름**: `.requestBack`/`.requestForward`/`.requestToggleHidden`/`.requestQuickFilter` — Task 4 선언, Task 6에서 동일 이름으로 수신.

---

## 실행 방식 선택

- **1. Subagent-Driven(추천)** — 태스크당 새 subagent 디스패치, 태스크 사이 리뷰 체크포인트
- **2. Inline Execution** — 현재 세션에서 일괄 실행, 배치 체크포인트

어느 쪽으로 진행할까요?
