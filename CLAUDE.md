# CLAUDE.md — Rclone GUI 프로젝트 가이드

## 프로젝트 개요

rclone 기반 멀티 클라우드 파일 매니저 GUI. Air Explorer의 기능을 rclone 백엔드로 구현하는 macOS 네이티브 데스크톱 앱.

## 기술 스택 및 규칙

- **언어**: Swift
- **UI**: SwiftUI (주) + AppKit (보조)
- **최소 지원**: macOS 14 (Sonoma)
- **상태 관리**: @Observable 매크로 (macOS 14+)
- **rclone 연동**: librclone C 라이브러리 직접 링크 (FFI)
- **프로젝트 구조**: Swift Package Manager 기반 모듈러 구조
- **프로젝트 생성**: XcodeGen (`project.yml` → `xcodegen generate`)
- **상수 관리**: `AppConstants.swift` — 버전/경로/타이밍/제한값 중앙 관리
- **다국어**: `L10n.swift` — `L10n.t("key")` / `L10n.t("key", arg)` 포맷 인자 지원
- **배포**: .dmg 직접 배포 (추후 App Store 가능)

## 프로젝트 구조

```
RcloneGUI/
├── RcloneGUI.xcodeproj
├── project.yml                   # XcodeGen 설정
├── RcloneGUI/                    # 메인 앱 타겟
│   ├── App.swift                 # @main 진입점
│   ├── AppState.swift            # 전역 앱 상태 (@Observable)
│   ├── Views/                    # SwiftUI 뷰 (41개 파일)
│   │   ├── ContentView.swift         # 루트 레이아웃
│   │   ├── SidebarView.swift         # 사이드바 네비게이션
│   │   ├── ExplorerView.swift        # 듀얼 패널 파일 탐색기
│   │   ├── FilePane.swift            # 단일 파일 패널 컨테이너
│   │   ├── FileTableView.swift       # 파일 목록 테이블
│   │   ├── FilePanePathBar.swift     # 경로 바 (브레드크럼)
│   │   ├── FilePaneTabBar.swift      # 멀티 탭 바
│   │   ├── RemoteSelectorView.swift  # 클라우드 서비스 선택
│   │   ├── RemoteDetailsView.swift   # 리모트 상세 정보
│   │   ├── AccountSetupView.swift    # 계정 추가 위자드
│   │   ├── TransferBarView.swift     # 전송 큐 진행률
│   │   ├── TransferReportSheet.swift # 전송 리포트
│   │   ├── SearchPanelView.swift     # 멀티 클라우드 검색
│   │   ├── SyncView.swift            # 동기화/백업 설정
│   │   ├── SyncProfileSheet.swift    # 동기화 프로필
│   │   ├── MountView.swift           # 클라우드 마운트 관리
│   │   ├── SchedulerView.swift       # 작업 스케줄러
│   │   ├── BookmarkView.swift        # 북마크 즐겨찾기
│   │   ├── TrashView.swift           # 삭제 이력 관리
│   │   ├── DuplicateFinderView.swift # 중복 파일 탐지
│   │   ├── SettingsSheet.swift       # 앱 설정
│   │   ├── LockScreenView.swift      # 앱 잠금 화면
│   │   ├── OnboardingView.swift      # 첫 실행 가이드
│   │   ├── MenuBarView.swift         # 메뉴바 앱 아이콘
│   │   ├── ErrorBannerView.swift     # 인라인 에러 알림
│   │   ├── NewFolderSheet.swift      # 폴더 생성
│   │   ├── ConfirmDeleteSheet.swift  # 삭제 확인
│   │   ├── PropertiesSheet.swift     # 파일/폴더 속성
│   │   ├── HashCompareSheet.swift    # 해시 비교
│   │   ├── BulkRenameSheet.swift     # 대량 이름변경
│   │   ├── CompressUploadSheet.swift # 압축 업로드
│   │   ├── FinderUploadSheet.swift   # Finder 업로드
│   │   ├── CryptSetupSheet.swift     # rclone crypt 설정
│   │   ├── UnionSetupSheet.swift     # 스토리지 풀링 설정
│   │   ├── SetPasswordSheet.swift    # 앱 잠금 비밀번호
│   │   ├── VersionHistorySheet.swift # 파일 버전 이력
│   │   ├── QuotaSheet.swift          # 스토리지 용량
│   │   ├── MediaPlayerSheet.swift    # 미디어 재생
│   │   ├── ProviderIcon.swift        # 프로바이더 아이콘
│   │   └── QuickLookBridge.swift     # QuickLook 연동
│   ├── ViewModels/               # @Observable 뷰모델 (14개 파일)
│   │   ├── PanelViewModel.swift      # 파일 패널 상태
│   │   ├── TransferViewModel.swift   # 전송 큐 상태
│   │   ├── TransferCheckpoint.swift  # 전송 재개 체크포인트
│   │   ├── AccountViewModel.swift    # 계정 관리
│   │   ├── SearchViewModel.swift     # 검색 쿼리/결과
│   │   ├── SyncViewModel.swift       # 동기화 작업
│   │   ├── MountViewModel.swift      # 마운트 상태
│   │   ├── SchedulerViewModel.swift  # 스케줄러 상태
│   │   ├── BookmarkViewModel.swift   # 북마크 상태
│   │   ├── TrashViewModel.swift      # 휴지통 상태
│   │   ├── SettingsViewModel.swift   # 사용자 설정
│   │   ├── AppLockViewModel.swift    # 앱 잠금 상태
│   │   ├── ClipboardState.swift      # 복사/붙여넣기
│   │   └── DuplicateDetector.swift   # 중복 파일 탐지
│   ├── Services/                 # 시스템 연동 서비스 (4개 파일)
│   │   ├── FinderService.swift       # Finder 우클릭 연동
│   │   ├── ShortcutsIntents.swift    # Siri Shortcuts 연동
│   │   ├── SpotlightIndexer.swift    # Spotlight 검색 연동
│   │   └── URLSchemeHandler.swift    # URL 스킴 (rclonegui://)
│   ├── Utilities/                # 유틸리티 (6개 파일)
│   │   ├── AppConstants.swift        # 앱 상수 (버전/경로/타이밍/제한값)
│   │   ├── ErrorClassifier.swift     # 에러 분류 및 복구
│   │   ├── FormatUtils.swift         # 숫자/크기/날짜 포맷
│   │   ├── L10n.swift                # 다국어 번역
│   │   ├── PathUtils.swift           # 경로 유틸
│   │   └── ProviderIconLoader.swift  # 프로바이더 아이콘 다운로드/캐시
│   ├── CLI/                      # 커맨드라인 인터페이스
│   │   └── CLIHandler.swift          # CLI 모드 지원
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   └── Localizable.xcstrings
│   └── Info.plist
│
├── RcloneGUITests/               # 유닛 테스트 (22개 파일, 160+ 테스트)
│
├── Packages/
│   ├── RcloneKit/                # librclone FFI 래핑
│   │   ├── Package.swift
│   │   ├── Sources/
│   │   │   ├── CRclone/         # C 헤더 + modulemap
│   │   │   └── RcloneKit/       # Swift API 래퍼 (6개 파일)
│   │   └── Tests/               # 4개 테스트 파일
│   │
│   ├── FileBrowser/              # 파일 브라우징/조작 도메인 로직
│   │   ├── Package.swift
│   │   ├── Sources/             # 2개 소스 파일
│   │   └── Tests/               # 3개 테스트 파일
│   │
│   └── TransferEngine/           # 전송/동기화 관리
│       ├── Package.swift
│       ├── Sources/             # 3개 소스 파일
│       └── Tests/               # 3개 테스트 파일
│
├── Resources/
│   └── lib/
│       ├── librclone.dylib       # 빌드된 rclone C 라이브러리
│       └── librclone.h           # C 헤더
│
└── scripts/
    ├── build-librclone.sh        # librclone 빌드 스크립트
    └── run-tests.sh              # 테스트 실행 스크립트
```

### 모듈 의존 관계

```
RcloneGUI (App)
  ├── FileBrowser → RcloneKit
  ├── TransferEngine → RcloneKit
  └── RcloneKit → CRclone (librclone FFI)
```

- **RcloneKit**: librclone C 함수를 Swift async/await API로 래핑. 다른 모듈은 C를 직접 접근하지 않음
- **FileBrowser**: 파일 목록 조회, 생성/삭제/이름변경/복사/이동 등 도메인 로직
- **TransferEngine**: 전송 큐 관리, 진행률 추적, 일시정지/재개

## librclone 연동 (RcloneKit)

### C 인터페이스

librclone은 Go로 작성된 C 라이브러리로 다음 함수를 노출한다:

```c
struct RcloneRPCResult {
    char* Output;
    int Status;
};

extern void RcloneInitialize(void);
extern void RcloneFinalize(void);
extern struct RcloneRPCResult RcloneRPC(char* method, char* input);
extern void RcloneFreeString(char* str);
```

### Swift 래퍼 사용 예시

```swift
let client = RcloneClient()
client.initialize()
defer { client.finalize() }

let result = try await client.call("operations/list", params: [
    "fs": "gdrive:",
    "remote": "/Documents",
    "opt": ["recurse": false]
])
```

### rclone rc API 엔드포인트

| 기능 | rclone rc 명령 | 용도 |
|------|---------------|------|
| 리모트 목록 | `config/listremotes` | 계정 목록 조회 |
| 리모트 추가 | `config/create` | 새 클라우드 계정 등록 |
| 리모트 삭제 | `config/delete` | 계정 제거 |
| 파일 목록 | `operations/list` | 디렉터리 내용 조회 |
| 파일 정보 | `operations/stat` | 파일 메타데이터 |
| 복사 | `operations/copyfile`, `sync/copy` | 파일/폴더 복사 |
| 이동 | `operations/movefile`, `sync/move` | 파일/폴더 이동 |
| 삭제 | `operations/deletefile`, `operations/purge` | 파일/폴더 삭제 |
| 디렉터리 생성 | `operations/mkdir` | 폴더 생성 |
| 동기화 | `sync/sync`, `sync/bisync` | 단방향/양방향 동기화 |
| 마운트 | `mount/mount` | 클라우드를 로컬 드라이브로 마운트 |
| 전송 상태 | `core/stats`, `core/transferred` | 진행 중인 전송 모니터링 |
| 전송 제어 | `job/list`, `job/stop` | 작업 관리 |
| 공간 확인 | `operations/about` | 스토리지 용량 조회 |
| 공유 링크 | `operations/publiclink` | 공유 URL 생성 |
| 해시 | `operations/hashfile` | 파일 해시 조회 |
| 암호화 | `config/create` (type=crypt) | crypt 리모트 생성 |
| 대역폭 | `core/bwlimit` | 속도 제한 설정 |

## 개발 규칙

### 코드 스타일
- Swift strict concurrency 사용
- SwiftUI 뷰는 작고 집중된 단위로 분리
- 파일명: PascalCase (Swift 표준)
- @Observable 뷰모델 패턴 (macOS 14+)
- 프로토콜 기반 의존성 주입 (테스트 가능 구조)

### 하드코딩 금지 — AppConstants 사용
- 버전: `AppConstants.appVersion` (Info.plist에서 자동 추출)
- 앱 이름: `AppConstants.appName`
- 파일 경로: `AppConstants.appSupportDir`, `AppConstants.xxxFile`
- 식별자: `AppConstants.keychainService`, `AppConstants.spotlightDomainID`
- 타이밍/제한: `AppConstants.transferPollingInterval`, `AppConstants.maxTransferRetries` 등
- 로케일: `AppConstants.defaultLocale`
- 새 상수 추가 시 반드시 `AppConstants.swift`에 정의

### 다국어 (L10n)
- 모든 사용자 표시 문자열은 `L10n.t("key")` 사용
- 포맷 인자: `L10n.t("key", arg1, arg2)` → `{0}`, `{1}` 치환
- 번역 테이블: `L10n.swift`의 `translations` 딕셔너리에 `["ko": ..., "en": ...]` 추가
- 테스트에서 locale 변경 시 `.serialized` + `defer`로 복원

### UX 패턴
- **삭제 시 반드시 확인 다이얼로그** (`alert` + destructive 버튼)
- **파일 클릭**: 단일 클릭 = `singleSelect`, Cmd+클릭 = `toggleSelect`
- **더블클릭**: 폴더 → 진입, 이미지/영상 → `NSWorkspace.shared.open()` (시스템 기본 앱)
- **탭 닫기**: 마지막 탭 닫기 → `resetTab` (클라우드 선택 화면으로 리셋)
- **전송 바**: 항상 하단에 컴팩트 바 표시, 토글로 확장/축소 (전송 중에도 닫기 가능)
- **편집**: 클라우드 편집 → 해당 remote의 `RemoteEditSheet` (계정 추가 모달이 아님)
- **프로바이더 아이콘**: `ProviderIconLoader`로 favicon 다운로드/캐시, 없으면 SF Symbol 폴백
- **데이터 갱신**: 파라미터가 바뀌는 뷰는 `.task(id:)` 사용 (`.task`만 쓰면 초기 1회만 실행)

### librclone 연동 원칙
- `RcloneRPC` 호출은 동기 블로킹이므로 별도 직렬 `DispatchQueue`에서 실행 후 async/await로 브릿지
- JSON 인코딩/디코딩은 Swift `Codable` 활용
- C 문자열 메모리는 `RcloneFreeString`으로 해제 (`defer` 패턴)
- 에러는 `RcloneError` enum으로 통일

### 보안
- 자격 증명은 rclone config에 위임 (앱에서 별도 저장하지 않음)
- 앱 잠금 비밀번호는 Keychain에 저장
- librclone은 프로세스 내에서 직접 실행 (네트워크 포트 불필요)

### 성능
- 파일 목록은 SwiftUI Table로 대량 데이터 처리
- 전송 상태 폴링 간격: `AppConstants.transferPollingInterval` (1초)
- 대량 파일 작업 시 배치 처리

### Swift Concurrency 규칙
- `Task.detached` 내에서 `self` 참조 시 로컬 변수로 캡처 (`let loader = self`)
- `[weak self]` 대신 로컬 변수 캡처로 Swift 6 sendable 경고 방지
- `MainActor.run` 반환값 사용하지 않을 때 `_ = await MainActor.run { }` 패턴
- API 상태 변경 (pause/resume): optimistic update → 실패 시 롤백

### 빌드 규칙
- **빌드 후 경고/에러 반드시 확인**: `xcodebuild build 2>&1 | grep "warning:\|error:"` 으로 0개 확인
- **XcodeGen**: 새 파일 추가 후 `xcodegen generate` 실행 (자동 프로젝트 파일 갱신)
- **Package.swift**: linkerSettings에서 `#file` 기반 절대 경로 사용 (상대 경로 금지 → search path 경고 발생)
- **librclone.dylib**: minos가 deployment target과 일치해야 함 (`vtool -set-build-version`으로 패치)

### SwiftUI vs AppKit 역할 분담

| 영역 | 프레임워크 | 이유 |
|------|-----------|------|
| 파일 목록 | SwiftUI (VStack + ForEach) | 선언적 + 커스텀 선택 로직 |
| 듀얼 패널 분할 | HStack + GeometryReader | coordinateSpace 기반 드래그 |
| 사이드바 | NavigationSplitView | macOS 표준 |
| 설정/시트 | SwiftUI .sheet | 모달 다이얼로그 |
| 파일 열기 | NSWorkspace.shared.open() | 시스템 기본 앱 |
| 전송 바 | VStack (카드 스타일) | 컴팩트/확장 토글 |

## 구현 현황

### Phase 1 — 핵심 (MVP) — v1.0.0 ✅
1. Xcode 프로젝트 + Swift Package 구조 셋업
2. librclone 빌드 및 RcloneKit FFI 래핑
3. 계정 관리 (리모트 목록, 추가, 삭제)
4. 듀얼 패널 파일 브라우저
5. 기본 파일 작업 (복사, 이동, 삭제, 이름 변경, 폴더 생성)
6. 전송 큐 및 진행률 표시
7. 다국어 지원 (한국어 / English)

### Phase 2 — 상호작용 — v1.1.x ✅
8. 멀티탭 브라우징
9. 드래그 앤 드롭 (패널 간 + Finder 연동)
10. 검색 (통합 검색, 멀티 클라우드)
11. 앱 잠금 (비밀번호 + Touch ID)
12. 키보드 단축키

### Phase 3 — 고급 기능 — v1.2.x~v1.3.x ✅
13. 동기화/백업 (Mirror, Bisync)
14. 암호화 (rclone crypt)
15. 작업 스케줄러
16. Quick Look 미리보기
17. 북마크
18. Finder Services 연동
19. 전송 재개 (체크포인트 + 자동 재시도)
20. 온보딩 가이드
21. 스마트 에러 복구
22. URL 스킴 (rclonegui://)
23. Shortcuts 연동
24. 키보드 네비게이션

### Phase 4 — 완성도 — v1.4.x ✅
25. 클라우드 마운트 (rclone mount)
26. 스토리지 풀링 (union)
27. 대량 이름변경
28. Spotlight 연동
29. 중복 파일 탐지
30. 파일 버전 이력
31. 대용량 디렉토리 성능 최적화

### Phase 5 — 향후 계획
- AI 기반 파일 정리/검색
- 로컬 폴더 ↔ 클라우드 실시간 동기화 (Dropbox 방식)
- 협업 기능 (팀 폴더, 권한)
- Mac App Store 배포 준비 (샌드박싱)

## 커밋 컨벤션

```
feat: 새 기능 추가
fix: 버그 수정
refactor: 리팩토링
style: 스타일/UI 변경
docs: 문서 변경
chore: 빌드/설정 변경
test: 테스트 추가/수정
```

## 릴리즈 노트 형식

GitHub Release 생성 시 한국어/영어 이중 표기 + 번호 리스트 형식을 사용한다:

```markdown
<details>
<summary>🇰🇷 한국어</summary>

## vX.Y.Z — 한줄 요약

1. **기능명** — 설명
2. **기능명** — 설명

</details>

<details>
<summary>🇺🇸 English</summary>

## vX.Y.Z — One-line summary

1. **Feature name** — description
2. **Feature name** — description

</details>
```

## 개발 워크플로우

- 기능 구현/버그 수정 단위로 **단계적으로 git commit**을 남긴다
- 하나의 커밋에 여러 변경을 섞지 않고, 논리적 단위로 분리한다
- 커밋 메시지는 한글로 작성하며 본문에 변경 사항을 상세히 기술한다
- **빌드 후 경고 0개 확인** 후 커밋한다
- **테스트 전체 통과** 확인 후 커밋한다
- 새 Swift 파일 추가 시 `xcodegen generate` 실행한다
- push는 사용자 요청 시에만 수행한다

## 자주 사용하는 명령

```bash
# Xcode 빌드
xcodebuild -scheme RcloneGUI -configuration Debug build

# 빌드 경고/에러 확인 (0개여야 함)
xcodebuild -scheme RcloneGUI -configuration Debug build 2>&1 | grep "warning:\|error:" | grep -v "export\|Run script" | sort -u

# XcodeGen 프로젝트 재생성 (새 파일 추가 후)
xcodegen generate

# 테스트 실행 (160+ 테스트)
xcodebuild -scheme RcloneGUI -destination 'platform=macOS' test

# SPM 패키지 테스트 (독립 실행)
./scripts/run-tests.sh

# librclone 빌드
./scripts/build-librclone.sh

# .dmg 패키징
xcodebuild -scheme RcloneGUI -configuration Release archive
```

## 테스트 전략

| 모듈 | 테스트 종류 | 대상 |
|------|-----------|------|
| RcloneKit | 유닛 테스트 | JSON 인코딩/디코딩, 에러 매핑 |
| RcloneKit | 통합 테스트 | 실제 librclone 호출 (로컬 파일시스템) |
| FileBrowser | 유닛 테스트 | 파일 조작 로직, 정렬, 필터링 |
| TransferEngine | 유닛 테스트 | 큐 관리, 상태 전이 |
| RcloneGUITests | 유닛 테스트 | ViewModel, Utility, Service, CLI 테스트 (22개 파일) |
| UI | 수동 테스트 | 뷰 동작 확인 |

`RcloneClientProtocol`에 의존하는 모듈은 Mock 주입으로 독립 테스트.

### 테스트 작성 규칙
- 전역 상태 변경 테스트 (예: `L10n.locale`)는 `@Suite(.serialized)` + `defer`로 복원
- `@MainActor` 필요한 테스트는 함수에 `@MainActor` 어노테이션 추가
- Mock은 `MockRcloneClient` 사용 — `responses` 딕셔너리에 메서드별 응답 설정
