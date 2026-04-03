# CLAUDE.md — Rclone GUI 프로젝트 가이드

## 프로젝트 개요

rclone 기반 멀티 클라우드 파일 매니저 GUI. Air Explorer의 기능을 rclone 백엔드로 구현하는 macOS 네이티브 데스크톱 앱.

## 기술 스택 및 규칙

- **언어**: Swift
- **UI**: SwiftUI (주) + AppKit (보조, NSTableView/NSSplitView/NSToolbar)
- **최소 지원**: macOS 14 (Sonoma)
- **상태 관리**: @Observable 매크로 (macOS 14+)
- **rclone 연동**: librclone C 라이브러리 직접 링크 (FFI)
- **프로젝트 구조**: Swift Package Manager 기반 모듈러 구조
- **배포**: .dmg 직접 배포 (추후 App Store 가능)

## 프로젝트 구조

```
RcloneGUI/
├── RcloneGUI.xcodeproj
├── RcloneGUI/                    # 메인 앱 타겟
│   ├── App.swift                 # @main 진입점
│   ├── AppState.swift            # 전역 앱 상태 (@Observable)
│   ├── Views/                    # SwiftUI 뷰
│   │   ├── ContentView.swift
│   │   ├── DualPanelView.swift
│   │   ├── PanelView.swift
│   │   ├── FileTableView.swift
│   │   ├── AddressBarView.swift
│   │   ├── RemoteSelectorView.swift
│   │   ├── ToolbarView.swift
│   │   ├── StatusBarView.swift
│   │   ├── TransferPanelView.swift
│   │   ├── TransferItemView.swift
│   │   ├── AccountListView.swift
│   │   ├── AccountSetupView.swift
│   │   ├── ContextMenuBuilder.swift
│   │   ├── NewFolderSheet.swift
│   │   └── ConfirmDeleteSheet.swift
│   ├── ViewModels/               # @Observable 뷰모델
│   │   ├── PanelViewModel.swift
│   │   ├── TransferViewModel.swift
│   │   └── AccountViewModel.swift
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   └── Localizable.xcstrings
│   └── Info.plist
│
├── Packages/
│   ├── RcloneKit/                # librclone FFI 래핑
│   │   ├── Package.swift
│   │   ├── Sources/
│   │   │   ├── CRclone/         # C 헤더 + modulemap
│   │   │   └── RcloneKit/       # Swift API 래퍼
│   │   └── Tests/
│   │
│   ├── FileBrowser/              # 파일 브라우징/조작 도메인 로직
│   │   ├── Package.swift
│   │   ├── Sources/
│   │   └── Tests/
│   │
│   └── TransferEngine/           # 전송/동기화 관리
│       ├── Package.swift
│       ├── Sources/
│       └── Tests/
│
├── Resources/
│   └── lib/
│       └── librclone.dylib       # 빌드된 rclone C 라이브러리
│
└── scripts/
    └── build-librclone.sh        # librclone 빌드 스크립트
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
- 파일 목록은 SwiftUI Table / NSTableView로 대량 데이터 처리
- 전송 상태 폴링 간격: 1초
- 대량 파일 작업 시 배치 처리

### SwiftUI vs AppKit 역할 분담

| 영역 | 프레임워크 | 이유 |
|------|-----------|------|
| 파일 목록 (Table) | SwiftUI Table (macOS 14) | 충분한 성능 + 선언적 |
| 듀얼 패널 분할 | HSplitView | SwiftUI 네이티브 |
| 툴바 | NSToolbar | macOS 표준 경험 |
| 계정 추가 위자드 | SwiftUI | 폼 기반 UI에 적합 |
| 설정 화면 | SwiftUI Settings | macOS 표준 설정 뷰 |
| 컨텍스트 메뉴 | SwiftUI .contextMenu | 간결한 선언 |
| 전송 패널 | SwiftUI List | 실시간 업데이트 바인딩 |

## 구현 우선순위

### Phase 1 — 핵심 (MVP) — v1.0.0
1. Xcode 프로젝트 + Swift Package 구조 셋업
2. librclone 빌드 및 RcloneKit FFI 래핑
3. 계정 관리 (리모트 목록, 추가, 삭제)
4. 듀얼 패널 파일 브라우저
5. 기본 파일 작업 (복사, 이동, 삭제, 이름 변경, 폴더 생성)
6. 전송 큐 및 진행률 표시
7. 다국어 지원 (한국어 / English)

### Phase 2 — 상호작용
8. 멀티탭 브라우징
9. 드래그 앤 드롭 (패널 간 + Finder 연동)
10. 검색 (통합 검색, 멀티 클라우드)
11. 앱 잠금 (비밀번호 + Touch ID)
12. 키보드 단축키

### Phase 3 — 고급 기능
13. 동기화/백업 (Mirror, Bisync)
14. 암호화 (rclone crypt)
15. 작업 스케줄러
16. Quick Look 미리보기
17. 북마크

### Phase 4 — 완성도
18. 클라우드 마운트 (rclone mount → FUSE)
19. 스토리지 풀링 (union)
20. 대량 이름변경
21. Mac App Store 배포 준비 (샌드박싱)

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

## 개발 워크플로우

- 기능 구현/버그 수정 단위로 **단계적으로 git commit**을 남긴다
- 하나의 커밋에 여러 변경을 섞지 않고, 논리적 단위로 분리한다
- 커밋 메시지는 한글로 작성하며 본문에 변경 사항을 상세히 기술한다
- Xcode 빌드(Cmd+B)가 통과한 후 커밋한다
- Swift 패키지 테스트(`swift test`)가 통과한 후 커밋한다
- push는 사용자 요청 시에만 수행한다

## 자주 사용하는 명령

```bash
# Xcode 빌드
xcodebuild -scheme RcloneGUI -configuration Debug build

# Swift 패키지 테스트
cd Packages/RcloneKit && swift test
cd Packages/FileBrowser && swift test
cd Packages/TransferEngine && swift test

# librclone 빌드
./scripts/build-librclone.sh

# .dmg 패키징 (추후)
xcodebuild -scheme RcloneGUI -configuration Release archive
```

## 테스트 전략

| 모듈 | 테스트 종류 | 대상 |
|------|-----------|------|
| RcloneKit | 유닛 테스트 | JSON 인코딩/디코딩, 에러 매핑 |
| RcloneKit | 통합 테스트 | 실제 librclone 호출 (로컬 파일시스템) |
| FileBrowser | 유닛 테스트 | 파일 조작 로직, 정렬, 필터링 |
| TransferEngine | 유닛 테스트 | 큐 관리, 상태 전이 |
| UI | 수동 테스트 | 뷰 동작 확인 |

`RcloneClientProtocol`에 의존하는 모듈은 Mock 주입으로 독립 테스트.
