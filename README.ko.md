# Rclone GUI — Cloud Explorer

한국어 | **[English](README.md)**

rclone 기반의 멀티 클라우드 파일 매니저 GUI 애플리케이션.
Air Explorer의 모든 기능을 무료로 제공하는 오픈소스 대안입니다.

## 개요

[rclone](https://rclone.org/)의 librclone을 직접 연동하여, 여러 클라우드 스토리지를 하나의 인터페이스에서 관리할 수 있는 macOS 네이티브 데스크톱 애플리케이션입니다. Swift와 SwiftUI로 구현되어 진정한 Mac 네이티브 경험을 제공합니다.

## 설치

### 사용자

1. Releases 페이지에서 `RcloneGUI-x.x.x.dmg` 다운로드
2. `.dmg`를 열고 앱을 Applications 폴더로 드래그
3. 실행 — 끝!

> macOS 14 (Sonoma) 이상이 필요합니다.

### 개발자

- **macOS 14+** (Sonoma)
- **Xcode 15+**
- **Go 1.21+** (librclone 빌드용)

## 아키텍처

```
┌──────────────────────────────────────────────────┐
│              RcloneGUI.app (.dmg)                 │
│  ┌────────────────────────────────────────────┐  │
│  │        SwiftUI + AppKit 프론트엔드         │  │
│  │  ┌──────────┐      ┌──────────┐           │  │
│  │  │ 좌측     │      │ 우측     │           │  │
│  │  │ 패널     │      │ 패널     │           │  │
│  │  └──────────┘      └──────────┘           │  │
│  │  ┌──────────────────────────────┐         │  │
│  │  │  전송 큐 / 진행률             │         │  │
│  │  └──────────────────────────────┘         │  │
│  └────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────┐  │
│  │         Swift 패키지                       │  │
│  │  ┌─────────────┐  ┌───────────────┐       │  │
│  │  │ FileBrowser  │  │ TransferEngine│       │  │
│  │  └──────┬──────┘  └──────┬────────┘       │  │
│  │  ┌──────┴─────────────────┴────────┐       │  │
│  │  │         RcloneKit (FFI)         │       │  │
│  │  └──────────────┬──────────────────┘       │  │
│  └─────────────────┼──────────────────────────┘  │
│  ┌─────────────────┴──────────────────────────┐  │
│  │  Frameworks/librclone.dylib                │  │
│  │  (Go C 공유 라이브러리 — FFI 직접 호출)    │  │
│  └────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘
```

**v0.x와의 주요 차이점:** HTTP API 서버나 별도의 rclone 프로세스가 더 이상 필요 없습니다. librclone을 앱에 직접 링크하여 C FFI로 rclone 함수를 호출합니다. 더 낮은 지연시간과 간단한 배포가 가능합니다.

## 주요 기능

### 1. 듀얼 패널 파일 브라우저

- [ ] 좌우 분할 패널 동시 탐색
- [ ] 주소 바 — 경로 직접 입력 가능
- [ ] 정렬 가능한 파일 테이블 (이름, 크기, 수정일)
- [ ] 컨텍스트 메뉴 (복사, 잘라내기, 붙여넣기, 이름 변경, 삭제, 새 폴더)
- [ ] 키보드 단축키 (Cmd+C, Cmd+V, Cmd+Delete 등)

### 2. 지원 클라우드 서비스

- [ ] rclone이 지원하는 70+ 클라우드 스토리지 모두 사용 가능

> Google Drive, OneDrive, Dropbox, Box, Mega, pCloud, Amazon S3, Azure Blob, Backblaze B2, Wasabi, DigitalOcean Spaces, Nextcloud, Owncloud, FTP, SFTP, WebDAV 등

### 3. 파일 관리

- [ ] 복사 / 이동 / 삭제 / 이름 변경
- [ ] 폴더 생성
- [ ] 우클릭 컨텍스트 메뉴

### 4. 전송 기능

- [ ] 전송 큐 및 진행률 추적
- [ ] 전송 이력 (완료 / 실패 탭)
- [ ] 활성 전송 취소

### 5. 계정 관리

- [ ] 클라우드 계정 추가 / 삭제
- [ ] 서비스당 다중 계정 지원
- [ ] 프로바이더 타입 선택

### 6. 다국어 지원

- [ ] 한국어 / English

## 기술 스택

- **언어**: Swift
- **UI**: SwiftUI + AppKit
- **상태 관리**: @Observable (macOS 14+)
- **rclone 연동**: librclone (C 공유 라이브러리, FFI)
- **프로젝트 구조**: Swift Package Manager
- **최소 OS**: macOS 14 (Sonoma)

## 개발 시작

```bash
# librclone 빌드
./scripts/build-librclone.sh

# Xcode에서 열기
open RcloneGUI/RcloneGUI.xcodeproj

# 빌드 및 실행
# Xcode에서 Cmd+R

# 패키지 테스트
cd Packages/RcloneKit && swift test
cd Packages/FileBrowser && swift test
cd Packages/TransferEngine && swift test
```

## 라이선스

MIT License
