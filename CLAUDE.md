# CLAUDE.md — Rclone GUI 프로젝트 가이드

## 프로젝트 개요

rclone 기반 멀티 클라우드 파일 매니저 GUI. Air Explorer의 기능을 rclone 백엔드로 구현하는 데스크톱 앱.

## 기술 스택 및 규칙

- **Electron** + **React** + **TypeScript** + **Vite**
- **UI**: Tailwind CSS + shadcn/ui
- **상태 관리**: Zustand
- **rclone 연동**: `rclone rcd` (Remote Control Daemon)를 HTTP JSON API로 제어

## 프로젝트 구조 (목표)

```
rclone-gui/
├── electron/                  # Electron 메인 프로세스
│   ├── main.ts               # 앱 진입점, BrowserWindow 생성
│   ├── preload.ts            # 컨텍스트 브릿지
│   ├── rclone/
│   │   ├── daemon.ts         # rclone rcd 프로세스 관리 (시작/종료)
│   │   ├── api.ts            # rclone rc API 클라이언트 래퍼
│   │   └── config.ts         # rclone config 파싱/관리
│   ├── scheduler.ts          # 작업 스케줄러
│   └── ipc-handlers.ts       # IPC 핸들러 등록
├── src/                       # React 프론트엔드 (Renderer)
│   ├── main.tsx              # React 진입점
│   ├── App.tsx
│   ├── components/
│   │   ├── layout/
│   │   │   ├── DualPanel.tsx         # 듀얼 패널 레이아웃
│   │   │   ├── Panel.tsx             # 단일 패널 컴포넌트
│   │   │   ├── TabBar.tsx            # 멀티탭 브라우징
│   │   │   ├── Toolbar.tsx           # 상단 도구 모음
│   │   │   └── StatusBar.tsx         # 하단 상태 바
│   │   ├── file-browser/
│   │   │   ├── FileList.tsx          # 파일/폴더 목록
│   │   │   ├── FileItem.tsx          # 개별 파일 항목
│   │   │   ├── Breadcrumb.tsx        # 경로 탐색
│   │   │   ├── ContextMenu.tsx       # 우클릭 메뉴
│   │   │   └── Thumbnail.tsx         # 썸네일 미리보기
│   │   ├── transfer/
│   │   │   ├── TransferQueue.tsx     # 전송 대기열
│   │   │   ├── TransferItem.tsx      # 개별 전송 항목
│   │   │   └── TransferProgress.tsx  # 진행률 표시
│   │   ├── sync/
│   │   │   ├── SyncConfig.tsx        # 동기화 설정
│   │   │   ├── SyncProfile.tsx       # 프로필 관리
│   │   │   └── SyncFilter.tsx        # 필터 규칙 편집
│   │   ├── search/
│   │   │   ├── SearchBar.tsx         # 검색 입력
│   │   │   └── SearchResults.tsx     # 검색 결과
│   │   ├── account/
│   │   │   ├── AccountList.tsx       # 계정 목록
│   │   │   ├── AccountSetup.tsx      # 계정 추가 위자드
│   │   │   └── RemoteSelector.tsx    # 리모트 선택기
│   │   ├── encryption/
│   │   │   └── CryptConfig.tsx       # 암호화 설정
│   │   └── common/
│   │       ├── Modal.tsx
│   │       ├── Button.tsx
│   │       └── ProgressBar.tsx
│   ├── stores/
│   │   ├── panelStore.ts             # 패널 상태
│   │   ├── transferStore.ts          # 전송 큐 상태
│   │   ├── syncStore.ts              # 동기화 상태
│   │   └── accountStore.ts           # 계정 상태
│   ├── hooks/
│   │   ├── useRclone.ts             # rclone API 호출 훅
│   │   ├── useFileOperations.ts     # 파일 조작 훅
│   │   ├── useTransfer.ts           # 전송 관리 훅
│   │   └── useDragDrop.ts           # 드래그앤드롭 훅
│   ├── services/
│   │   ├── rcloneApi.ts             # rclone rc API 호출 함수
│   │   └── rcloneTypes.ts           # rclone 관련 타입 정의
│   └── lib/
│       └── utils.ts
├── package.json
├── tsconfig.json
├── vite.config.ts
├── electron-builder.yml           # 패키징 설정
├── tailwind.config.ts
├── postcss.config.js
├── README.md
└── CLAUDE.md
```

## rclone rc API 활용 가이드

앱은 `rclone rcd --rc-no-auth` 로 데몬을 시작하고, HTTP JSON API를 통해 모든 작업을 수행한다.

### 핵심 API 엔드포인트

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
| 검색 | `operations/list` + 필터 | 파일 검색 |
| 암호화 | `config/create` (type=crypt) | crypt 리모트 생성 |
| 대역폭 | `core/bwlimit` | 속도 제한 설정 |

### rclone rc 호출 예시

```typescript
// POST http://localhost:5572/operations/list
const response = await fetch('http://localhost:5572/operations/list', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    fs: 'gdrive:',
    remote: '/Documents',
    opt: { recurse: false }
  })
});
```

## 개발 규칙

### 코드 스타일
- TypeScript strict 모드 사용
- 함수형 컴포넌트 + React hooks
- 파일명: 컴포넌트는 PascalCase, 유틸/훅은 camelCase
- 한 파일에 하나의 export default 컴포넌트

### rclone 연동 원칙
- rclone 바이너리 경로는 시스템 PATH에서 자동 탐지 (`which rclone`)
- rclone이 없으면 앱 시작 시 안내 메시지 표시
- rclone rcd 데몬은 앱 시작 시 자동으로 시작, 종료 시 정리
- 모든 rclone 작업은 rc API를 통해 수행 (CLI 직접 호출 최소화)
- API 에러는 사용자에게 명확한 메시지로 표시

### 보안
- rclone rc 서버는 localhost에서만 접근 (`--rc-addr localhost:5572`)
- 자격 증명은 rclone config에 위임 (앱에서 별도 저장하지 않음)
- 앱 잠금 비밀번호는 로컬에 암호화하여 저장

### 성능
- 파일 목록은 가상 스크롤(virtualized list) 적용 — 수천 개 파일도 부드럽게
- 썸네일은 lazy loading
- 전송 상태 폴링 간격: 1초
- 대량 파일 작업 시 배치 처리

## 구현 우선순위

### Phase 1 — 핵심 (MVP)
1. Electron + React + Vite 프로젝트 셋업
2. rclone 데몬 관리 (시작/종료/상태 확인)
3. 계정 관리 (리모트 목록, 추가, 삭제)
4. 듀얼 패널 파일 브라우저
5. 기본 파일 작업 (복사, 이동, 삭제, 이름 변경, 폴더 생성)
6. 전송 큐 및 진행률 표시

### Phase 2 — 동기화 & 전송
7. 드래그 앤 드롭
8. 동기화 설정 (모드 선택, 필터)
9. 동기화 프로필 저장/불러오기
10. 클라우드 간 직접 전송 (server-side copy)
11. 전송 일시 정지/재개
12. 대역폭 제한

### Phase 3 — 고급 기능
13. 멀티탭 브라우징
14. 통합 검색 (멀티 클라우드)
15. 암호화 리모트 설정 (crypt)
16. 작업 스케줄러
17. 북마크
18. 해시 비교

### Phase 4 — 완성도
19. 썸네일 미리보기
20. 대량 이름 변경
21. 클라우드 마운트
22. 스토리지 풀링 (union)
23. 미디어 스트리밍
24. 설정 가져오기/내보내기
25. 앱 잠금 비밀번호
26. 연결 탐색(Linked Browsing)

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

## 자주 사용하는 명령

```bash
npm run dev          # 개발 서버
npm run build        # 프로덕션 빌드
npm run package      # Electron 패키징
npm run lint         # ESLint
npm run typecheck    # TypeScript 타입 체크
rclone rcd --rc-no-auth --rc-addr localhost:5572   # rclone 데몬 수동 시작
```
