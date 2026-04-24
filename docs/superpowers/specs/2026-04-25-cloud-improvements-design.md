# 클라우드(Cloud/Remote) 개선 — 설계 문서

- **일자**: 2026-04-25
- **브랜치**: `feature/explorer-search-cloud-bookmark-improvements`
- **대상**: Remote 영역 (4/4 사이클 중 3번째)

## 동기

- **연결 확인 수단 부재** — 설정 값만 보이고, 실제로 접근 가능한지는 파일 목록 불러오기 전까지 알 수 없음
- **별칭 부재** — rclone config 이름이 `gdrive-work`, `s3-prod` 같이 기계어. UI에서 "회사 드라이브"처럼 표시할 수단 없음

## 범위

### 포함
- **(a) 연결 테스트** — `RemoteDetailsView`의 "테스트" 버튼. `operations/about` 호출, 성공 시 녹색 체크 + 지연 시간, 실패 시 적색 X + 에러 메시지
- **(b) 리모트 별칭** — 별칭 입력 필드. 별칭이 있으면 UI(사이드바, 선택 화면, 상세 헤더)에 별칭 + 작은 원본 이름을 병행 표시

### 제외
- 그룹핑/태그, 색상 커스터마이즈, 최근 접속 경로, 할당량 임계 알림 — 후속

## 아키텍처

- `RemoteAliasStore`(신규) — UserDefaults `[remoteName: alias]`, 빈 문자열 set = 제거
- `AccountViewModel`에 `aliasStore`, `alias(for:)`, `setAlias(name:alias:)`, `displayName(for:)` 추가. `Remote.displayName`(패키지)은 변경 없이 fallback
- `RemoteDetailsView`: 별칭 TextField + 연결 테스트 버튼 + 결과 상태 뱃지. `@State var testResult: (success: Bool, detail: String)?` + `isTesting`
- `SidebarView`/`RemoteSelectorView`: `accounts.displayName(for: remote.name)` 호출로 별칭 적용

## 영향 파일
- `RcloneGUI/ViewModels/RemoteAliasStore.swift` (신규)
- `RcloneGUI/ViewModels/AccountViewModel.swift` — alias API 추가
- `RcloneGUI/Utilities/AppConstants.swift` — `remoteAliasesKey`
- `RcloneGUI/Views/RemoteDetailsView.swift` — 테스트 버튼, 별칭 필드
- `RcloneGUI/Views/SidebarView.swift` — alias-aware label
- `RcloneGUI/Views/RemoteSelectorView.swift` — alias-aware label
- `RcloneGUI/Utilities/L10n.swift` — 6개 키 내외
- `RcloneGUITests/AccountViewModelTests.swift` — alias 스토어 + VM 통합 테스트

## 검증 기준
- [ ] 빌드 경고 0, 전체 테스트 PASS
- [ ] 별칭 없는 리모트는 기존과 동일 표시
- [ ] 별칭 설정 후 즉시 사이드바/선택화면 반영
- [ ] 연결 테스트 — 로컬/정상 리모트 성공, 잘못된 리모트 실패 + 에러
