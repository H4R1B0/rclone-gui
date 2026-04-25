# 원격 리뷰 결과 — 2026-04-25

- **task-id**: `rvcyu0v3j`
- **status**: completed
- **수정 커밋**: `d0ba175 fix: 원격 리뷰 7건 반영`
- **검토 대상**: `feature/explorer-search-cloud-bookmark-improvements` 브랜치 4개 영역(Explorer/Search/Cloud/Bookmark) 변경분

총 **7건** 발견 (normal 5 / nit 2). 모두 수정 완료.

---

## 1. bug_015 [normal] — loadFiles가 await 전에 상태를 변경

- **파일**: `RcloneGUI/ViewModels/PanelViewModel.swift:300-314`
- **요지**: `pushHistory`/`clearForward`/`filterQuery=""` 부수효과가 `RcloneAPI.listFiles` await **이전**에 실행됨. 호출이 throw하면(오프라인/권한 거부/타임아웃) `tab.remote`/`tab.path`는 do 블록 안에서만 갱신되므로 미반영 — 결과적으로 backStack에 현재 위치가 중복 푸시되어 Back이 no-op이 되고 forwardStack은 영구 손실, 사용자가 입력한 filterQuery도 이동 없이 지워짐.
- **기존 테스트가 못 잡은 이유**: `PanelHistoryTests`의 mock이 항상 성공(`responses["operations/list"] = ["list": []]`). 실패 경로 미커버.
- **권장 수정**: `if prev != next` 블록을 do 성공 분기 안, `tab.remote`/`tab.path` 할당 직후로 이동. `errorForMethod`로 회귀 테스트 추가.
- **상태**: ✅ Fixed in d0ba175 (`failurePreservesState` 회귀 테스트 추가)

## 2. bug_010 [normal] — navigateTo가 stale remote/path 혼합으로 히스토리 오염

- **파일**: `RcloneGUI/ViewModels/PanelViewModel.swift:296-311` (loadFiles) + `navigateTo` 호출부
- **요지**: `navigateTo`가 `tab.remote = remote`를 **먼저** 변이한 뒤 `loadFiles(side:, path:)`를 호출(remote 인자 없이). 새로 도입된 히스토리 기록 로직은 `prev = NavEntry(remote: tab.remote, path: tab.path)`를 캡처하는데 이 시점에 `tab.remote`는 NEW, `tab.path`는 OLD라 존재한 적 없는 phantom 엔트리(예: `gdrive:/Users/foo`)가 backStack에 들어감. Back 누르면 잘못된 위치로 이동 → 새 remote에서 invalid path 에러.
- **영향 진입점**: Spotlight 결과(`App.swift:54`), URL 스킴(`URLSchemeHandler.swift:21`), 북마크 클릭(`ContentView.swift:60`, `BookmarkView.swift:29`), 검색 결과 더블클릭(`SearchPanelView.swift:299`).
- **권장 수정**: `navigateTo`에서 eager 변이 제거, `loadFiles(remote: remote, path: path)`로 명시 전달.
- **상태**: ✅ Fixed in d0ba175 (`navigateToCrossRemote` 회귀 테스트 추가)

## 3. bug_001 [normal] — rangeSelect/selectAll이 visibleFiles 우회

- **파일**: `RcloneGUI/ViewModels/PanelViewModel.swift:88-105` (selectAll, rangeSelect)
- **요지**: 본 PR이 `tab.visibleFiles(showHidden:)` 도입하면서 "선택은 보이는 파일만 참조" 불변식을 정립. `selectAdjacentFile`은 마이그레이션됐지만 `selectAll`/`rangeSelect`는 누락 — `tab.files`/`tab.sortedFiles`를 그대로 사용. 결과: 숨김 파일 off + ⌘A → 사용자가 안 보는 dotfile까지 선택 → ⌘⌫로 휴지통 이동 가능. 빠른 필터 활성 + Shift-Click → 필터 밖 파일이 범위에 포함.
- **권장 수정**: 두 메서드 모두 `tab.visibleFiles(showHidden: side(panelSide).showHidden)` 기반으로 라우팅.
- **상태**: ✅ Fixed in d0ba175 (`PanelSelectionVisibilityTests` 3종 추가)

## 4. bug_002 [normal] — ⌘. 단축키가 macOS Cancel과 충돌

- **파일**: `RcloneGUI/App.swift:109-113`
- **요지**: Toggle Hidden Files를 `⌘.`에 바인딩. macOS HIG는 `⌘.`을 시스템 Cancel(알림/시트 취소, 작업 중단)로 예약. macOS Finder는 숨김 파일에 `⇧⌘.`(Shift-Command-Period)를 쓰지 `⌘.` 단독을 쓰지 않음. 본 PR 설계 문서가 "macOS Finder 관례와 동일"이라 적었으나 사실 오류.
- **재현**: `NewFolderSheet`/`ConfirmDeleteSheet` 등 시트 열린 상태에서 `⌘.` 누르면 시트 취소 안 되고 뒤 패널의 숨김 토글이 무성하게 뒤집힘.
- **권장 수정**: `.keyboardShortcut(".", modifiers: [.command, .shift])` + 설계 문서도 정정.
- **상태**: ✅ Fixed in d0ba175 (spec 문서도 함께 갱신)

## 5. merged_bug_003 [normal] — 연결 테스트의 false negative + 상태 누수

`RemoteDetailsView.swift:191-204` 두 가지 문제가 결합:

### Issue 1: About 미지원 백엔드에서 false negative
- 연결 테스트가 `RcloneAPI.about`만 사용. 그러나 About는 옵셔널 백엔드 기능 — **SFTP/FTP/HTTP/alias/crypt/combine/chunker** 등은 `"Fs does not support About"` 반환.
- 결과: 정상 동작하는 SFTP 리모트도 빨간 "연결 실패"로 표시.
- 같은 파일 `loadData`(line 178)는 이미 `try?`로 graceful하게 처리 — 패턴 인식 부재가 원인.

### Issue 2: remoteName 경계 누락 + state 잔존
- `ContentView.swift:55`의 `case .remote(let name): RemoteDetailsView(remoteName: name)`은 SwiftUI 구조적 동일성으로 같은 view 인스턴스 유지. `.task(id:)`는 config/quota/aliasDraft만 리셋하고 `testResult`/`isTesting`은 미리셋.
- `runConnectionTest`는 호출 시점 `remoteName` 캡처 후 await — await 도중 사용자가 다른 리모트로 전환하면 A의 결과가 B 헤더 아래에 "연결됨" 그린 뱃지로 표시.

- **권장 수정**:
  1. About 실패 시 `operations/list` 폴백 또는 "not supported" 패턴을 success-without-quota로 분류
  2. `target = remoteName` 캡처 + await 후 `guard target == remoteName`
  3. `loadData`에서 `testResult = nil`, `isTesting = false` 리셋
- **상태**: ✅ Fixed in d0ba175 (모든 3개 권장 수정 적용)

## 6. bug_005 [nit] — ⌘F 첫 누름 포커스 레이스

- **파일**: `RcloneGUI/Views/FilePane.swift:119-123`
- **요지**: `.requestQuickFilter` 핸들러가 같은 tick에 `showQuickFilter = true`와 `quickFilterFocused = true`를 동기 설정. TextField는 `if showQuickFilter`로 조건부 렌더 → 첫 누름 시 focus 대상 view가 아직 트리에 없어 binding 무시. 사용자가 클릭해야 입력 가능.
- **본 PR이 같은 패턴 다른 곳에서 이미 해결**: 북마크 rename(`SidebarView.swift:185-191`)은 `AppConstants.renameFocusDelay`로 `asyncAfter` 처리 — 퀵 필터에는 미적용.
- **권장 수정**: `.onChange(of: showQuickFilter) { _, isShown in if isShown { quickFilterFocused = true } }`로 view mount 라이프사이클에 결합 (asyncAfter 매직넘버보다 idiomatic).
- **상태**: ✅ Fixed in d0ba175 (onChange 방식 채택)

## 7. bug_008 [nit] — bookmarkRow의 미사용 index 파라미터

- **파일**: `RcloneGUI/Views/SidebarView.swift:142-144`
- **요지**: `bookmarkRow(bookmark:index:)`의 `index: Int`가 본문 어디서도 참조되지 않음. 커밋 `3fb06bd`(⌘1~9 점프 기능 제거)의 잔재. 호출부도 `Array(...).enumerated()` 불필요 래핑.
- **권장 수정**: 파라미터 제거 + `ForEach(appState.bookmarks.bookmarks) { bookmark in bookmarkRow(bookmark: bookmark) }`.
- **상태**: ✅ Fixed in d0ba175

---

## 요약

| ID | 심각도 | 영역 | 상태 |
|---|---|---|---|
| bug_015 | normal | loadFiles 실패 시 상태 corruption | ✅ |
| bug_010 | normal | navigateTo phantom 히스토리 | ✅ |
| bug_001 | normal | selection이 보이지 않는 파일 포함 | ✅ |
| bug_002 | normal | ⌘. macOS Cancel 충돌 | ✅ |
| merged_bug_003 | normal | connection test About fallback + 경계 | ✅ |
| bug_005 | nit | ⌘F 포커스 레이스 | ✅ |
| bug_008 | nit | bookmarkRow 미사용 파라미터 | ✅ |

회귀 테스트 추가:
- `failurePreservesState` (bug_015)
- `navigateToCrossRemote` (bug_010)
- `PanelSelectionVisibilityTests` 3종 (bug_001)

전체 282 테스트 PASS, 빌드 경고 0.
