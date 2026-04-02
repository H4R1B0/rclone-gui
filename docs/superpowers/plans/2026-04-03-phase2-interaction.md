# Phase 2: 상호작용 기능 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 드래그앤드롭, 앱 잠금(비밀번호+Touch ID), 키보드 단축키를 구현하여 기존 TypeScript 앱과 동일한 상호작용 경험을 제공한다.

**Architecture:** 기존 Phase 1 구조(AppState → ViewModels → Views) 위에 기능을 추가. 드래그앤드롭은 SwiftUI의 `draggable`/`dropDestination` 활용. 앱 잠금은 `LocalAuthentication.framework` + Keychain. 키보드 단축키는 `.onKeyPress` + NotificationCenter 연동.

**Tech Stack:** Swift, SwiftUI, LocalAuthentication, Security.framework (Keychain), macOS 14+

---

## Task 1: 드래그앤드롭 — 패널 간 파일 전송

기존 TypeScript 동작:
- 파일 행을 드래그 시작 → `{ side, fileName, isDir }` JSON
- 반대편 패널에 드롭 → Alt키=이동, 일반=복사
- Finder에서 파일을 패널에 드롭 → 복사

**Files:**
- Modify: `RcloneGUI/Views/FileTableView.swift`
- Modify: `RcloneGUI/Views/PanelView.swift`
- Modify: `RcloneGUI/ViewModels/PanelViewModel.swift` — `handleDrop` 메서드 추가

- [ ] **Step 1: 드래그 데이터 모델 정의**

`RcloneGUI/ViewModels/PanelViewModel.swift`에 추가:

```swift
struct DraggedFile: Codable, Transferable {
    let side: String  // "left" or "right"
    let fileName: String
    let isDir: Bool
    let sourceFs: String
    let sourcePath: String
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }
}
```

- [ ] **Step 2: PanelViewModel에 handleDrop 추가**

```swift
@MainActor
func handleDrop(targetSide: PanelSide, draggedFiles: [DraggedFile], isMove: Bool) async {
    let targetTab = side(targetSide).activeTab
    for file in draggedFiles {
        let srcRemote = file.sourcePath.isEmpty ? file.fileName : "\(file.sourcePath)/\(file.fileName)"
        let dstRemote = targetTab.path.isEmpty ? file.fileName : "\(targetTab.path)/\(file.fileName)"
        if isMove {
            if file.isDir {
                _ = try? await RcloneAPI.moveDir(using: client, srcFs: file.sourceFs, srcRemote: srcRemote, dstFs: targetTab.remote, dstRemote: dstRemote)
            } else {
                _ = try? await RcloneAPI.moveFileAsync(using: client, srcFs: file.sourceFs, srcRemote: srcRemote, dstFs: targetTab.remote, dstRemote: dstRemote)
            }
        } else {
            if file.isDir {
                _ = try? await RcloneAPI.copyDir(using: client, srcFs: file.sourceFs, srcRemote: srcRemote, dstFs: targetTab.remote, dstRemote: dstRemote)
            } else {
                _ = try? await RcloneAPI.copyFileAsync(using: client, srcFs: file.sourceFs, srcRemote: srcRemote, dstFs: targetTab.remote, dstRemote: dstRemote)
            }
        }
    }
    await refresh(side: targetSide)
}
```

- [ ] **Step 3: FileTableView 행에 .draggable 추가**

파일 행에 `.draggable` 모디파이어 추가. `DraggedFile`을 전달.

- [ ] **Step 4: PanelView에 .dropDestination 추가**

파일 목록 영역에 `.dropDestination(for: DraggedFile.self)` 추가. NSEvent의 option 키 감지로 이동/복사 판별.

- [ ] **Step 5: 커밋**

```
feat: 드래그앤드롭 — 패널 간 파일 복사/이동

- DraggedFile: Transferable 모델 (JSON 코딩)
- 파일 행 .draggable + 패널 .dropDestination
- Option 키 = 이동, 일반 = 복사
```

---

## Task 2: 앱 잠금 — 비밀번호 + Touch ID

기존 TypeScript 동작:
- 설정에서 앱 잠금 활성화 + 비밀번호 설정
- Touch ID 사용 여부 토글
- 앱 시작 시 잠금 화면 표시
- 비밀번호 입력 또는 Touch ID로 해제
- 비밀번호는 Electron safeStorage로 암호화 → Swift에서는 Keychain

**Files:**
- Create: `RcloneGUI/ViewModels/AppLockViewModel.swift`
- Create: `RcloneGUI/Views/LockScreenView.swift`
- Modify: `RcloneGUI/Views/SettingsSheet.swift` — 보안 섹션 추가
- Modify: `RcloneGUI/Views/ContentView.swift` — 잠금 화면 오버레이
- Modify: `RcloneGUI/AppState.swift` — appLock 추가
- Modify: `RcloneGUI/Utilities/L10n.swift` — 잠금 관련 문자열

- [ ] **Step 1: AppLockViewModel 작성**

```swift
import Foundation
import LocalAuthentication
import Security

@Observable
final class AppLockViewModel {
    var isLocked: Bool? = nil  // nil=확인 중, true=잠김, false=해제
    var isEnabled: Bool = false
    var useTouchID: Bool = false
    var canUseTouchID: Bool = false
    var errorMessage: String?
    
    private let keychainService = "com.rclone-gui.applock"
    private let keychainAccount = "password"
    private let configURL: URL
    
    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("RcloneGUI")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        configURL = appDir.appendingPathComponent("app-lock-config.json")
        loadConfig()
        checkTouchIDAvailability()
    }
    
    // Keychain: 비밀번호 저장/조회/삭제
    func setPassword(_ password: String) -> Bool { ... }
    func verifyPassword(_ password: String) -> Bool { ... }
    func removePassword() { ... }
    func hasPassword() -> Bool { ... }
    
    // Touch ID
    func checkTouchIDAvailability() { ... }
    func promptTouchID() async -> Bool { ... }
    
    // Config 저장/로드
    func saveConfig() { ... }
    func loadConfig() { ... }
    
    // 잠금 확인
    func checkLockStatus() { ... }
    func unlock() { isLocked = false }
}
```

Keychain 구현: `SecItemAdd`, `SecItemCopyMatching`, `SecItemDelete` 사용.
Touch ID: `LAContext().evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)`.

- [ ] **Step 2: LockScreenView 작성**

기존 TypeScript LockScreen.tsx 재현:
- 잠금 아이콘
- 비밀번호 입력 필드 (SecureField)
- Touch ID 버튼 (가능할 때)
- 틀린 비밀번호 시 흔들림 애니메이션
- 해제 시 페이드아웃

- [ ] **Step 3: SettingsSheet에 보안 섹션 추가**

- 앱 잠금 토글
- 비밀번호 설정/변경/제거
- Touch ID 토글

- [ ] **Step 4: ContentView에 잠금 화면 오버레이 추가**

```swift
.overlay {
    if appState.appLock.isLocked == true {
        LockScreenView()
    }
}
```

- [ ] **Step 5: L10n에 잠금 관련 문자열 추가**

lock.title, lock.password, lock.touchid, lock.unlock, lock.wrongPassword, lock.setPassword, lock.changePassword, lock.removePassword 등

- [ ] **Step 6: 테스트 — AppLockViewModel 유닛 테스트**

Keychain CRUD, 비밀번호 검증, config 저장/로드 테스트.

- [ ] **Step 7: 커밋**

```
feat: 앱 잠금 — 비밀번호 + Touch ID

- AppLockViewModel: Keychain 비밀번호 관리 + LAContext Touch ID
- LockScreenView: 비밀번호 입력 + Touch ID 버튼 + 흔들림 애니메이션
- SettingsSheet 보안 섹션: 잠금 토글 + 비밀번호 관리 + Touch ID
- ContentView 잠금 오버레이
```

---

## Task 3: 키보드 단축키 강화

기존 TypeScript 동작:
- Cmd+C/X/V → 실제 클립보드 연동 (현재는 메뉴바에만 있고 뷰에서 직접 처리 안됨)
- Cmd+Delete → 선택된 파일 삭제
- Cmd+A → 전체 선택
- Cmd+Shift+N → 새 폴더
- Cmd+F → 검색으로 전환
- Cmd+R → 새로고침
- Enter → 이름 변경
- Backspace → 상위 폴더

**Files:**
- Modify: `RcloneGUI/Views/FileTableView.swift` — `.onKeyPress` 핸들러
- Modify: `RcloneGUI/Views/ContentView.swift` — 전역 단축키
- Modify: `RcloneGUI/Utilities/L10n.swift` — 단축키 관련 문자열

- [ ] **Step 1: FileTableView에 키보드 핸들러 추가**

`.focusable()` + `.onKeyPress` 조합으로:
- Enter → 선택된 파일이 1개이면 이름 변경 모드
- Delete/Backspace+Cmd → 삭제 확인
- Backspace (단독) → 상위 폴더

- [ ] **Step 2: ContentView에 전역 단축키 추가**

Cmd+F → `appState.activeView = .search`
Cmd+R → refresh active panel

NotificationCenter로 발행된 이벤트를 PanelView에서 수신하여 처리:
- `.requestCopy` → clipboard.copy
- `.requestCut` → clipboard.cut
- `.requestPaste` → panels.paste
- `.requestDelete` → 삭제 확인
- `.requestSelectAll` → panels.selectAll
- `.requestNewFolder` → 새 폴더 시트

- [ ] **Step 3: PanelView에 NotificationCenter 수신 추가**

`.onReceive(NotificationCenter.default.publisher(for: .requestCopy))` 등으로 각 이벤트 처리.

- [ ] **Step 4: 커밋**

```
feat: 키보드 단축키 강화

- FileTableView: Enter(이름변경), Backspace(상위폴더)
- 전역: Cmd+F(검색), Cmd+R(새로고침)
- NotificationCenter 연동: Cmd+C/X/V/Delete/A/Shift+N이 활성 패널에서 동작
```

---

## Task 4: 통합 빌드 + 자동 테스트

- [ ] **Step 1: xcodegen 재생성 + 빌드 확인**
- [ ] **Step 2: ./scripts/run-tests.sh 실행**
- [ ] **Step 3: 발견된 이슈 수정**
- [ ] **Step 4: 커밋**

---

## 의존 관계

```
Task 1 (드래그앤드롭) — 독립
Task 2 (앱 잠금) — 독립
Task 3 (키보드 단축키) — 독립
Task 4 (통합) — Task 1, 2, 3 완료 후
```

Task 1, 2, 3은 병렬 가능.
