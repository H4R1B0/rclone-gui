# 북마크(Bookmark) 개선 — 설계 문서

- **일자**: 2026-04-25
- **브랜치**: `feature/explorer-search-cloud-bookmark-improvements`
- **대상**: Bookmark 영역 (4/4 사이클 중 4번째 — 마지막)

## 동기

- **순서 변경 불가** — 추가된 순서대로 고정, 중요 북마크를 상단으로 올릴 수 없음
- **이름 편집 불가** — 추가 시 폴더명이 그대로 저장, 나중에 "프로젝트/build/release" 같은 경로 폴더가 불명료한 라벨로 남음
- **단축키 없음** — 자주 쓰는 위치조차 메뉴/사이드바 클릭 필요

## 범위

### 포함
- **(a) 북마크 순서 변경** — 사이드바에서 드래그로 재배치
- **(b) 북마크 이름 편집** — 우클릭 메뉴 "이름 변경" → 인라인 편집
- **(c) 단축키 ⌘1~9** — 상위 9개 북마크를 활성 패널 현재 탭에 로드

### 제외
- 폴더/카테고리, 아이콘 커스텀, 내보내기/가져오기 — 후속

## 아키텍처

- `BookmarkViewModel`에 `move(fromIndex:toIndex:)`, `rename(id:newName:)` 추가
- `SidebarView`의 북마크 섹션에 `.onMove` + 우클릭 "이름 변경" 메뉴 아이템 + 편집 상태
- `App.swift`: `CommandGroup`에 `Bookmark \(n)` 9개 Button, 단축키 `⌘1..⌘9`, `.requestBookmarkJump(index:)` Notification(userInfo 사용)
- ExplorerView 계열(혹은 AppState 라우터) — Notification 수신해 `panels.navigateTo(side: active, ...)` 호출

## 영향 파일
- `RcloneGUI/ViewModels/BookmarkViewModel.swift` — move/rename
- `RcloneGUI/Views/SidebarView.swift` — 드래그 이동, 인라인 rename
- `RcloneGUI/App.swift` — requestBookmarkJump + ⌘1~9 메뉴
- `RcloneGUI/Views/FilePane.swift` — jump notification 수신
- `RcloneGUI/Utilities/L10n.swift` — rename 키
- `RcloneGUITests/BookmarkViewModelTests.swift` — move/rename 테스트

## 검증 기준
- [ ] 빌드 경고 0, 전체 테스트 PASS
- [ ] 드래그 재배치 즉시 영속화, 재시작 후 유지
- [ ] 이름 변경이 jsonl 파일에 반영
- [ ] ⌘1~9 누르면 활성 패널에서 해당 북마크로 이동, 범위 밖 인덱스는 no-op
