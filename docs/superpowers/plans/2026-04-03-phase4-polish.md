# Phase 4: 완성도 구현 계획 (App Store 제외)

**Goal:** 클라우드 마운트, 스토리지 풀링, 대량 이름변경을 구현하여 기능 완성도를 높인다.

**Tech Stack:** Swift, SwiftUI, macOS 14+, librclone (mount/mount, config/create type=union)

---

## Task 1: 클라우드 마운트 (rclone mount)

rclone mount: 클라우드 스토리지를 로컬 드라이브처럼 마운트.
- mount/mount API로 마운트
- mount/unmount로 해제
- 마운트 포인트 선택
- 활성 마운트 목록 표시

**Files:**
- Create: `RcloneGUI/ViewModels/MountViewModel.swift`
- Create: `RcloneGUI/Views/MountView.swift`

## Task 2: 스토리지 풀링 (rclone union)

여러 리모트를 하나로 묶어서 사용.
- config/create type=union으로 union 리모트 생성
- 리모트 여러 개 선택 UI

**Files:**
- Create: `RcloneGUI/Views/UnionSetupSheet.swift`

## Task 3: 대량 이름변경

선택된 여러 파일의 이름을 패턴으로 일괄 변경.
- 프리픽스/서픽스 추가
- 번호 매기기
- 찾기/바꾸기
- 미리보기 후 실행

**Files:**
- Create: `RcloneGUI/Views/BulkRenameSheet.swift`

## Task 4: 통합 빌드 + 자동 테스트
