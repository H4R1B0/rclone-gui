# Rclone GUI — Cloud Explorer

rclone 기반의 멀티 클라우드 파일 매니저 GUI 애플리케이션.
Air Explorer의 모든 기능을 무료로 제공하는 오픈소스 대안입니다.

## 개요

[rclone](https://rclone.org/)을 백엔드로 활용하여, 여러 클라우드 스토리지를 하나의 인터페이스에서 관리할 수 있는 macOS 데스크톱 애플리케이션입니다. `.dmg` 하나로 설치하면 바로 사용할 수 있습니다.

## 설치

### 사용자

1. Releases 페이지에서 `Rclone-GUI-x.x.x-arm64.dmg` (Apple Silicon) 또는 `Rclone-GUI-x.x.x-x64.dmg` (Intel) 다운로드
2. `.dmg`를 열고 앱을 Applications 폴더로 드래그
3. 실행 — 끝!

> rclone이 시스템에 설치되어 있으면 해당 버전을 사용하고, 없으면 앱에 내장된 rclone을 자동으로 사용합니다.

### 개발자

- **macOS** (초기 지원 플랫폼)
- **Node.js** 18+ / npm
- **rclone** (선택) — `brew install rclone`

## rclone 바이너리 전략

앱은 다음 우선순위로 rclone 바이너리를 탐지합니다:

1. **시스템 rclone** — `PATH`에서 탐지 (`which rclone`). 사용자가 직접 관리하는 버전 우선 사용
2. **내장 rclone (Fallback)** — 시스템에 rclone이 없으면 앱 번들에 포함된 바이너리 사용

```
Rclone GUI.app/
  └── Contents/
      └── Resources/
          └── bin/
              └── rclone          ← 내장 바이너리 (fallback)
```

| 상황 | 동작 |
|------|------|
| 시스템에 rclone 있음 | 시스템 rclone 사용, 내장 바이너리 무시 |
| 시스템에 rclone 없음 | 내장 rclone 자동 사용 |
| 시스템 rclone 버전이 너무 낮음 | 경고 표시 후 내장 rclone 사용 제안 |

설정에서 사용자가 수동으로 rclone 경로를 지정할 수도 있습니다.

## 주요 기능

### 1. 듀얼 패널 파일 브라우저

- [x] 좌우 분할 패널 (로컬 PC + 클라우드) 동시 탐색
- [x] 드래그 앤 드롭으로 패널 간 파일 전송
- [x] 리사이즈 가능한 패널 경계선
- [x] 주소 바 — 경로 표시 및 직접 입력 가능
- [x] 멀티 탭 브라우징 — 여러 위치를 동시에 열어 작업
- [ ] 파일/폴더 썸네일 미리보기
- [ ] 북마크 — 자주 사용하는 경로 즐겨찾기
- [ ] 연결 탐색(Linked Browsing) — 양쪽 패널 폴더 구조 동기화 탐색

### 2. 지원 클라우드 서비스

- [x] rclone이 지원하는 70+ 클라우드 스토리지 모두 사용 가능
- [x] 실제 브랜드 SVG 아이콘 표시

> Google Drive, OneDrive, Dropbox, Box, Mega, pCloud, Amazon S3, Azure Blob, Backblaze B2, Wasabi, DigitalOcean Spaces, Nextcloud, Owncloud, FTP, SFTP, WebDAV 등

### 3. 파일 관리

- [x] 복사 / 이동 / 삭제 / 이름 변경
- [x] 폴더 생성
- [x] 우클릭 컨텍스트 메뉴 (이름 변경, 반대편에 복사, 삭제)
- [x] 폴더 싱글클릭 이동
- [ ] 대량 이름 변경(Bulk Rename)
- [ ] 파일 압축 후 업로드
- [ ] 공유 링크 생성
- [ ] 원본 날짜 유지 전송
- [ ] 휴지통 관리
- [ ] 해시 비교(MD5, SHA1 등)

### 4. 전송 기능

- [x] 클라우드 간 직접 전송 (server-side copy)
- [x] 일시 정지 / 재개
- [x] 전송 중지 / 재시작
- [x] 전송 진행 상황 모니터링 (진행률, 속도, ETA)
- [x] 전송 이력 (완료 / 오류 탭)
- [x] 전송 목록 우클릭 컨텍스트 메뉴
- [x] 리사이즈 가능한 전송 영역
- [ ] 멀티스레드 전송 속도 최적화
- [ ] 대역폭 제한 시간대별 스케줄링
- [ ] 상세 전송 리포트

### 5. 동기화 및 백업

- [ ] Mirror — 소스를 타겟에 완전 복제
- [ ] Mirror Updated — 변경된 파일만 소스→타겟 복사
- [ ] Updated — 새롭거나 변경된 파일만 전송
- [ ] 양방향 동기화(Bisync)
- [ ] 커스텀 동기화 — 사용자 정의 규칙
- [ ] 동기화 프로필 저장/불러오기
- [ ] 필터 규칙 (확장자, 파일 크기, 수정일, 정규표현식)

### 6. 스케줄링 및 자동화

- [ ] 작업 스케줄러 (매일, 매주 등)
- [ ] 백그라운드 실행
- [ ] CLI 모드 지원
- [ ] 스케줄 로깅

### 7. 암호화

- [ ] rclone crypt 기반 클라이언트 측 암호화
- [ ] 파일 내용 암호화
- [ ] 파일/폴더 이름 암호화
- [ ] 암호화된 상태로 클라우드 간 전송

### 8. 검색

- [ ] 연결된 모든 클라우드에서 통합 검색
- [ ] 다중 클라우드 동시 검색
- [ ] 필터링: 파일 타입, 날짜 범위, 파일 크기, 경로

### 9. 계정 관리

- [x] 서비스당 무제한 계정 연결
- [x] 동일 서비스 다중 계정 지원
- [x] 계정 추가 — 프로바이더별 설정 필드 동적 표시 (아이디/비밀번호 등)
- [x] 계정 수정 — 리모트 이름 변경 및 설정값 편집
- [x] 계정 삭제 (확인 다이얼로그)
- [x] 프로바이더 검색
- [x] 자격 증명 로컬 저장 (rclone config 활용)
- [ ] 계정 설정 가져오기/내보내기
- [ ] 앱 시작 비밀번호 보호

### 10. 설정

- [x] rclone 옵션 GUI (transfers, checkers, multi-thread-streams, buffer-size 등)
- [x] 대역폭 제한 (bwlimit)
- [x] 설정 영구 저장 및 자동 로드
- [x] 기본값 복원

### 11. 추가 기능

- [ ] 클라우드 스토리지 용량 확인 (쿼터)
- [ ] 클라우드 마운트 (`rclone mount`)
- [ ] 스토리지 풀링 (`rclone union`)
- [ ] 온라인 미디어 재생 (스트리밍)

## 기술 스택

- **프레임워크**: Electron
- **프론트엔드**: React + TypeScript
- **상태 관리**: Zustand
- **UI 컴포넌트**: Tailwind CSS + shadcn/ui
- **백엔드**: rclone (시스템 설치 우선, 내장 바이너리 fallback)
- **rclone 연동**: rclone rc (Remote Control) API — HTTP JSON API
- **빌드**: Vite
- **패키징**: electron-builder → `.dmg` (macOS)

## 아키텍처

```
┌──────────────────────────────────────────────────┐
│              Rclone GUI.app (.dmg)                │
│  ┌────────────────────────────────────────────┐  │
│  │        React Frontend (Renderer)           │  │
│  │  ┌──────────┐      ┌──────────┐           │  │
│  │  │ Left     │      │ Right    │           │  │
│  │  │ Panel    │      │ Panel    │           │  │
│  │  └──────────┘      └──────────┘           │  │
│  │  ┌──────────────────────────────┐         │  │
│  │  │  Transfer Queue / Progress   │         │  │
│  │  └──────────────────────────────┘         │  │
│  └────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────┐  │
│  │         Main Process (Node.js)             │  │
│  │  ┌─────────────┐  ┌───────────────┐       │  │
│  │  │ Rclone RC   │  │  Scheduler    │       │  │
│  │  │ API Client  │  │  Engine       │       │  │
│  │  └──────┬──────┘  └───────────────┘       │  │
│  │  ┌──────┴──────┐                          │  │
│  │  │ Binary      │                          │  │
│  │  │ Resolver    │ ← 시스템 rclone 우선     │  │
│  │  │             │   없으면 내장 fallback    │  │
│  │  └──────┬──────┘                          │  │
│  └─────────┼──────────────────────────────────┘  │
│            │                                      │
│  ┌─────────┴──────────────────────────────────┐  │
│  │  Contents/Resources/bin/rclone (내장)      │  │
│  └────────────────────────────────────────────┘  │
└────────────┼──────────────────────────────────────┘
             │ HTTP JSON API (localhost:5572)
┌────────────┴──────────────────────────────────────┐
│     rclone rcd (시스템 or 내장 바이너리)            │
│         Remote Control API Server                  │
└───────────────────────────────────────────────────┘
```

## 개발 시작

```bash
# 의존성 설치
npm install

# 개발 서버 실행
npm run dev

# 빌드
npm run build

# macOS .dmg 패키징
npm run package
```

## 배포

```bash
# macOS용 .dmg 생성
npm run package

# 출력 위치
# dist/Rclone-GUI-x.x.x-arm64.dmg  (Apple Silicon)
# dist/Rclone-GUI-x.x.x-x64.dmg    (Intel)
```

electron-builder가 `.app` 번들을 생성하고 `.dmg`로 래핑합니다. 앱 번들 안에 rclone 바이너리가 자동으로 포함됩니다.

## 라이선스

MIT License
