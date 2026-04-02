# Phase 3: 고급 기능 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 동기화/백업, 암호화, 작업 스케줄러, Quick Look, 북마크를 구현하여 Air Explorer 수준의 기능 완성도를 달성한다.

**Architecture:** 기존 구조 위에 기능 추가. 동기화는 `sync/sync`, `sync/bisync` API 활용. 암호화는 `config/create type=crypt`. 스케줄러는 Timer 기반. Quick Look은 QLPreviewPanel. 북마크는 UserDefaults.

**Tech Stack:** Swift, SwiftUI, QuickLook.framework, macOS 14+

---

## Task 1: 동기화/백업

기존 TypeScript 스펙:
- Mirror: 소스 → 타겟 완전 복제 (sync/sync)
- Mirror Updated: 변경된 파일만 복사 (sync/copy)
- Updated: 새롭거나 변경된 파일만 전송
- Bisync: 양방향 동기화
- 동기화 프로필 저장/불러오기
- 필터 규칙 (확장자, 크기, 날짜)

**Files:**
- Create: `RcloneGUI/ViewModels/SyncViewModel.swift`
- Create: `RcloneGUI/Views/SyncView.swift`
- Create: `RcloneGUI/Views/SyncProfileSheet.swift`
- Modify: `Packages/RcloneKit/Sources/RcloneKit/ConvenienceAPI.swift` — sync API 추가
- Modify: `RcloneGUI/Utilities/L10n.swift` — 동기화 문자열
- Modify: `RcloneGUI/Views/ToolbarView.swift` — 동기화 탭 추가
- Modify: `RcloneGUI/AppState.swift` — ActiveView.sync 추가
- Modify: `RcloneGUI/Views/ContentView.swift` — SyncView 연결

---

## Task 2: 암호화 (rclone crypt)

rclone crypt: 기존 리모트를 암호화하는 래퍼 리모트.
- `config/create` with `type=crypt`, `remote=existing:path`, `password`, `password2`

**Files:**
- Create: `RcloneGUI/Views/CryptSetupSheet.swift`
- Modify: `RcloneGUI/Views/AccountSetupView.swift` — crypt 생성 옵션 추가

---

## Task 3: 작업 스케줄러

주기적으로 동기화 프로필을 실행하는 스케줄러.
- 일일/주간/커스텀 간격
- 프로필 선택
- 로그 기록
- 백그라운드 실행

**Files:**
- Create: `RcloneGUI/ViewModels/SchedulerViewModel.swift`
- Create: `RcloneGUI/Views/SchedulerView.swift`

---

## Task 4: Quick Look 미리보기

파일 선택 후 스페이스바 → Quick Look 패널 표시.
- 로컬 파일: 직접 QLPreviewPanel
- 클라우드 파일: 임시 다운로드 후 미리보기

**Files:**
- Create: `RcloneGUI/Views/QuickLookBridge.swift`
- Modify: `RcloneGUI/Views/FileTableView.swift` — 스페이스바 핸들러

---

## Task 5: 북마크

자주 가는 경로를 저장하고 빠르게 이동.
- 현재 경로 북마크 추가 (Cmd+D)
- 북마크 목록 사이드바 또는 드롭다운
- 북마크 삭제
- UserDefaults 저장

**Files:**
- Create: `RcloneGUI/ViewModels/BookmarkViewModel.swift`
- Create: `RcloneGUI/Views/BookmarkView.swift`
- Modify: `RcloneGUI/Views/AddressBarView.swift` — 북마크 버튼

---

## Task 6: 통합 빌드 + 자동 테스트
