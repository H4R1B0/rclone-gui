# 탐색(Explorer) 내비게이션 개선 — 설계 문서

- **일자**: 2026-04-25
- **브랜치**: `feature/explorer-search-cloud-bookmark-improvements`
- **대상 영역**: Explorer (탐색) — 4개 기능 영역 중 1/4
- **후속 사이클**: 검색(Search), 클라우드(Remote), 북마크(Bookmark)는 별도 스펙으로 분리

## 동기

현재 `FilePanePathBar`에는 "상위 폴더(goUp)"와 경로 브레드크럼만 존재한다. 일상 사용 시 다음 통증이 반복된다.

1. **뒤로/앞으로 이동 부재** — 폴더를 깊이 들어갔다 빠져나오고 다시 들어가려면 매번 브레드크럼/클릭을 반복. macOS Finder(⌘[/⌘]) 및 일반 파일 매니저의 표준 상호작용이 없음.
2. **숨김 파일이 항상 노출** — `.DS_Store`, `.git`, `~` 임시파일이 목록을 오염. 로컬 탐색에서 특히 심하며 현재 필터링 수단 없음.
3. **현재 폴더 내 빠른 필터 부재** — 파일이 200~1000개인 폴더에서 이름 일부로 빠르게 좁히는 수단이 없음. 전역 "Search" 뷰는 BFS 호출 + 결과 뷰 이동 비용이 커서 "현재 위치에서 하나 찾기"용으로는 과함.

## 범위

### 포함 (이번 사이클)

- **(a) 탐색 히스토리 back/forward** — 패널별 뒤/앞 이동, `FilePanePathBar`에 버튼 + 키보드 단축키 ⌘[ / ⌘]
- **(b) 숨김 파일 토글** — 패널별 "숨김 파일 표시" on/off, 경로바에 눈 아이콘 + 키보드 단축키 ⌘.
- **(c) 빠른 필터 바** — 현재 탭 파일 목록을 이름 부분일치로 실시간 축소, ⌘F로 열고 ESC로 닫음

### 제외 (후속 사이클/별도 스펙)

- 컬럼 커스터마이즈, 미리보기 패널, undo/redo, 패턴 선택 — 탐색 영역 내 후보였으나 범위 외
- 검색/클라우드/북마크 영역 — 별도 스펙
- 링크드 브라우징과의 히스토리 연동 (현재 패널 로컬 히스토리만)

## UX 결정

### (a) 히스토리

- **트리거**: 경로가 실제로 바뀌는 내비게이션(하위 폴더 진입, 브레드크럼 클릭, goUp, 검색 결과 이동)에서 `backStack`에 푸시. `refresh()`는 푸시하지 않음.
- **ForwardStack 무효화**: 사용자가 back 중인 상태에서 "새로운" 위치로 이동하면 forwardStack 비움(브라우저 표준).
- **리모트 전환도 기록**: `(remote, path)` 튜플 단위로 저장. 예: `gdrive:/A → gdrive:/A/B → dropbox:/` 세 단계 back 가능.
- **탭 분리**: 히스토리는 `TabState`에 소속. 탭 간 섞이지 않음. 탭 닫힘 = 히스토리 소멸.
- **링크드 브라우징과의 상호작용**: back/forward는 **활성 패널 로컬 동작**이며 반대편 패널을 따라 이동시키지 않는다. 결정 근거: (1) 각 패널 히스토리가 독립적이므로 back을 트리거한 쪽의 이전 위치로만 복귀해야 의미가 있음, (2) linkedBrowsing 동기화가 일어나면 반대편 패널에도 back 엔트리가 쌓여 이후 "앞으로" 의미가 깨짐. 구현: `goBack`/`goForward`는 `loadFiles(recordHistory: false, skipLinkedSync: true)` 형태로 호출하여 히스토리 기록과 링크 동기화 모두 우회. 일반 내비게이션은 기존 동작 유지.
- **UI 위치**: `FilePanePathBar`에서 기존 "goUp" chevron.left 왼쪽에 ← / → 버튼 추가. 비활성 상태(스택 비어있음)는 흐리게.
- **상한**: 패널당 50 항목(큐 앞쪽에서 드롭). 메모리 보호 + 실사용 범위.

### (b) 숨김 파일 토글

- **기준**: 이름이 `.`로 시작하는 파일/폴더 (Unix 관례). `~`, `Icon\r` 같은 플랫폼별 예외는 일단 제외 — 과한 스코프.
- **저장 위치**: `PanelSideState.showHidden`. 탭 전환해도 유지. 양쪽 패널 독립.
- **기본값**: `false` (숨김).
- **UI 위치**: `FilePanePathBar` 별 아이콘 옆에 `eye`/`eye.slash` 토글.
- **단축키**: 활성 패널에 ⌘. (macOS Finder 관례와 동일).
- **설정 영속화**: `SettingsViewModel`이 아닌 세션 한정(Finder와 달리 앱 재시작 시 기본값으로 리셋). 추후 `AppConstants`/설정에 기본값 옵션 추가는 후속 작업. → **범위 외**.

### (c) 빠른 필터

- **트리거**: ⌘F (활성 패널). 기존 SidebarItem.search와는 **다른** 동작. 경로바 하단에 TextField가 슬라이드-다운.
- **동작**: 입력 시 즉시 필터링, 대소문자 무시, `localizedCaseInsensitiveContains`. 정규식/글롭은 이번 스코프 외.
- **저장 위치**: `TabState.filterQuery`. 탭별 독립. 탭 전환 시 유지.
- **리셋**: 경로 이동(navigate/goUp/back/forward/브레드크럼) 시 필터 자동 비움. 사용자 의도 명확.
- **빈 결과 UI**: "필터와 일치하는 파일 없음" + "필터 지우기" 버튼.
- **파일 카운트 바**: 기존 `performance.fileCount` 표시에 `(X/Y 필터됨)` 추가.
- **ESC로 닫기**: 입력이 비어있으면 바가 닫히고 포커스가 파일 리스트로 복귀. 입력이 있으면 먼저 입력만 지움.

## 아키텍처

### 상태 배치 결정

| 기능 | 저장 위치 | 이유 |
|------|-----------|------|
| 히스토리 (a) | `TabState.backStack`, `TabState.forwardStack` | 탭별 "내가 어디 있었는지" 컨텍스트 |
| 숨김 토글 (b) | `PanelSideState.showHidden` | 패널의 "뷰 환경설정" 성격, 탭 바뀌어도 유지 |
| 빠른 필터 (c) | `TabState.filterQuery` | 탭별 "지금 뭘 찾고 있는지" 작업 컨텍스트 |

세 가지를 `TabState` 한 곳으로 몰 수도 있지만, 숨김은 탭 전환 시 유지되는 편이 자연스러움(사용자 기대).

### 데이터 흐름

```
FileTableView
  └─ tab.visibleFiles           ← 새 computed property
       = applyFilter(            ← TabState.filterQuery 반영
            applyHidden(         ← PanelSideState.showHidden 반영
              tab.sortedFiles)) ← 기존 캐시된 정렬 결과
```

`_cachedSortedFiles`와 동일 패턴으로 `_cachedVisibleFiles` 캐시. invalidate 트리거: `files`, `sortBy`, `sortAsc`, `filterQuery`, 그리고 상위 `PanelSideState.showHidden` 변경.

**캐시 도전과제**: `showHidden`은 `TabState` 밖(`PanelSideState`). `TabState`가 자신을 담은 `PanelSideState`를 참조하면 순환. 해결:
- `visibleFiles(showHidden:)` 메서드 방식(캐시 key에 bool 포함) — 간결
- 혹은 `TabState`가 직접 `showHidden`을 읽지 않고 `FileTableView`에서 후처리 후 LazyVStack에 전달 — SwiftUI diff가 뷰 레벨에서 처리
- **채택**: `TabState`에 `visibleFiles(showHidden:)` 메서드. 내부 캐시 key = `(sortBy, sortAsc, filterQuery, showHidden)`. 단순 무효화는 `_cachedVisibleKey`와 비교.

### 히스토리 푸시 지점

`PanelViewModel`의 경로 변경 경로는 현재 모두 `loadFiles(side:remote:path:)`로 수렴. 여기서 "실제로 변경되었는지" 판별 후 푸시.

```swift
func loadFiles(..., recordHistory: Bool = true) async {
    let tab = side(panelSide).activeTab
    let prev = NavEntry(remote: tab.remote, path: tab.path)
    let next = NavEntry(remote: remote ?? tab.remote, path: path ?? tab.path)
    if recordHistory && prev != next && !prev.isEmpty {
        tab.pushHistory(prev)
        tab.clearForward()
    }
    // ... existing logic
}
```

`goBack`/`goForward`는 `loadFiles(recordHistory: false)`로 호출 + `forwardStack`/`backStack`에 현재 위치를 푸시.

### 빠른 필터 토글 메커니즘

새 NotificationCenter 이벤트 `.requestQuickFilter`를 브로드캐스트. `FilePane`/`FileTableView`가 활성 패널 가드 후 처리. 기존 `requestCopy`/`requestPaste` 패턴 재사용.

메인 메뉴 바인딩은 본 스펙 범위 외(후속 설정/메뉴 통합에서 처리). 이번엔 경로바 버튼 + `onKeyPress`로 ⌘F 수신.

## 영향받는 파일

- `RcloneGUI/ViewModels/PanelViewModel.swift` — `NavEntry` 구조체, `TabState` 히스토리/필터 필드 + 메서드, `PanelSideState.showHidden`, `PanelViewModel.goBack/goForward`, `loadFiles(recordHistory:)`
- `RcloneGUI/Views/FilePanePathBar.swift` — ← / → 버튼, 눈 아이콘 토글, ⌘F 키 바인딩
- `RcloneGUI/Views/FilePane.swift` — 퀵 필터 바 렌더링(경로바 아래, FileTableView 위)
- `RcloneGUI/Views/FileTableView.swift` — `tab.visibleFiles(showHidden:)` 사용, 카운트 바 "필터됨" 표기, 빈 결과 UI
- `RcloneGUI/Utilities/L10n.swift` — 새 키 10개 내외
- `RcloneGUI/AppState.swift` 또는 Notification 정의 파일 — `requestQuickFilter`, `requestBack`, `requestForward`, `requestToggleHidden` Notification.Name
- `RcloneGUITests/PanelViewModelTests.swift`(신규 또는 기존 확장) — 히스토리 푸시/팝, 필터, 숨김 테스트

## 빌드 순서 (커밋 단위)

각 단위는 독립 빌드·테스트 가능해야 함.

1. **기반: TabState/PanelSideState 상태 추가 + 유닛 테스트**
   - `NavEntry`, 히스토리 필드, `pushHistory`/`popBack`/`popForward`, `showHidden`, `filterQuery`, `visibleFiles(showHidden:)` 순수 로직
   - 테스트: 히스토리 푸시/팝 시나리오, 50개 상한, 필터+숨김 조합 결과
2. **ViewModel 통합: PanelViewModel 히스토리 훅 + goBack/goForward**
   - `loadFiles(recordHistory:)` 시그니처 확장
   - `goBack(side:)`, `goForward(side:)` 메서드
   - 링크드 브라우징 경로에서 `recordHistory: false` (역류 방지)
3. **UI (a): 경로바 back/forward 버튼 + 키 바인딩**
4. **UI (b): 숨김 파일 토글 UI + ⌘. 바인딩 + FileTableView 연결**
5. **UI (c): 빠른 필터 바 + ⌘F 바인딩 + 카운트/빈 결과 UI**
6. **L10n 키 추가 + 다국어 문자열 정리**
7. **최종: 빌드 경고 0개 확인, 전체 테스트 통과**

각 커밋은 한국어 메시지, `feat:` 또는 `test:` 접두사.

## 에러/경계 케이스

- **빈 히스토리에서 back**: 버튼 비활성화(`backStack.isEmpty`). 키 바인딩 누름은 no-op.
- **리모트 선택 화면(`remote.isEmpty`)에서 back**: 이전 유효 위치로 복귀. `NavEntry.isEmpty` 정의(remote=="" && path=="")로 가드.
- **탭 리셋(`resetTab`)**: 히스토리, 필터 모두 비움.
- **필터 적용 중 navigate**: 필터 자동 비움(위에서 정의).
- **숨김 off → on 전환 중 선택된 숨김 파일**: 선택 유지. 다음 내비게이션 시 자연히 정리.
- **대용량 디렉터리(1000+ 파일) + 필터**: `visibleFiles` 캐시로 반복 계산 회피. SwiftUI LazyVStack은 viewport만 렌더 → 문제 없음.

## 테스트 전략

- **유닛 (TabState/PanelSideState)**
  - 히스토리 푸시/팝, forward 무효화, 50개 상한
  - `visibleFiles(showHidden: false)`가 `.` 시작 파일 제거 확인
  - `filterQuery` 대소문자 무시, 빈 쿼리 = 원본
  - 경로 이동 시 `filterQuery` 클리어
- **유닛 (PanelViewModel, Mock client)**
  - `loadFiles` → `goBack` → 이전 경로 복구
  - `loadFiles` → `goBack` → `loadFiles(new)` → forward 소멸
  - `recordHistory: false` 경로가 히스토리 오염하지 않음
- **수동 UI 검증**
  - ⌘[ / ⌘] / ⌘. / ⌘F 단축키
  - 링크드 브라우징 on/off 상태에서 back/forward 동작
  - 빠른 필터 입력 중 파일 선택/복사/이동이 "필터된 집합" 기준으로 동작하는지

## 검증 기준

- [ ] `xcodebuild ... build 2>&1 | grep "warning:\|error:"` 0건
- [ ] `./scripts/run-tests.sh` 및 `xcodebuild ... test` 모두 통과
- [ ] 빈 상태(히스토리 없음, 필터 없음, 숨김 off)에서 기존 탐색 동작 완전 동일
- [ ] 활성/비활성 패널 구분: 단축키가 활성 패널에만 작용
- [ ] ko/en 양쪽 문자열 모두 대응

## 후속 사이클(비범위) 참고

이 설계는 이후 다음 작업의 토대를 제공한다.
- 히스토리 UI: 드롭다운으로 과거 N개 표시 (이번 스코프 외)
- 숨김 기본값 설정: `SettingsSheet` 통합 (이번 스코프 외)
- 고급 필터: 정규식, 확장자 멀티셀렉트 (이번 스코프 외)
