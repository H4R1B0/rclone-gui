import { create } from 'zustand';

export type Locale = 'ko' | 'en';

interface I18nStore {
  locale: Locale;
  setLocale: (locale: Locale) => void;
}

export const useI18n = create<I18nStore>((set) => ({
  locale: 'ko',
  setLocale: (locale) => set({ locale }),
}));

const translations: Record<string, Record<Locale, string>> = {
  // Common
  'common.close': { ko: '닫기', en: 'Close' },
  'common.cancel': { ko: '취소', en: 'Cancel' },
  'common.save': { ko: '저장', en: 'Save' },
  'common.saving': { ko: '저장 중...', en: 'Saving...' },
  'common.add': { ko: '추가', en: 'Add' },
  'common.delete': { ko: '삭제', en: 'Delete' },
  'common.edit': { ko: '수정', en: 'Edit' },
  'common.select': { ko: '선택...', en: 'Select...' },
  'common.key': { ko: '키', en: 'Key' },
  'common.value': { ko: '값', en: 'Value' },
  'common.error': { ko: '오류:', en: 'Error:' },
  'common.advanced': { ko: '고급', en: 'Advanced' },
  'common.type': { ko: '타입', en: 'Type' },

  // Panel / Tab
  'panel.myPc': { ko: '내 PC', en: 'My PC' },
  'panel.cloud': { ko: '클라우드', en: 'Cloud' },
  'panel.cloudSelect': { ko: '클라우드 선택', en: 'Select Cloud' },
  'panel.newTab': { ko: '새 탭', en: 'New Tab' },
  'panel.parentFolder': { ko: '상위 폴더', en: 'Parent Folder' },
  'panel.root': { ko: '/ (루트)', en: '/ (Root)' },

  // Toolbar
  'toolbar.addAccount': { ko: '계정 추가', en: 'Add Account' },
  'toolbar.explore': { ko: '탐색', en: 'Explore' },
  'toolbar.accounts': { ko: '계정 관리', en: 'Accounts' },
  'toolbar.refresh': { ko: '새로고침', en: 'Refresh' },
  'toolbar.transfer': { ko: '전송', en: 'Transfers' },
  'toolbar.settings': { ko: '설정', en: 'Settings' },
  'toolbar.search': { ko: '검색', en: 'Search' },

  // File browser
  'file.name': { ko: '이름', en: 'Name' },
  'file.size': { ko: '크기', en: 'Size' },
  'file.modified': { ko: '수정일', en: 'Modified' },
  'file.emptyFolder': { ko: '빈 폴더', en: 'Empty folder' },
  'file.newFolderName': { ko: '새 폴더 이름', en: 'New folder name' },
  'file.dropHint': { ko: '여기에 놓기 — 드롭: 복사 / Option+드롭: 이동', en: 'Drop here — Drop: Copy / Option+Drop: Move' },

  // Context menu
  'ctx.rename': { ko: '이름 변경', en: 'Rename' },
  'ctx.copyToOther': { ko: '반대편에 복사', en: 'Copy to Other Panel' },

  // Remote selector
  'remote.connect': { ko: '클라우드 연결', en: 'Connect Cloud' },
  'remote.noCloud': { ko: '연결된 클라우드가 없습니다', en: 'No connected clouds' },

  // Account
  'account.manage': { ko: '클라우드 계정 관리', en: 'Cloud Account Management' },
  'account.selectService': { ko: '서비스 선택', en: 'Select Service' },
  'account.newAccount': { ko: '새 계정', en: 'New Account' },
  'account.editAccount': { ko: '계정 수정', en: 'Edit Account' },
  'account.noAccounts': { ko: '등록된 계정이 없습니다', en: 'No registered accounts' },
  'account.addCloud': { ko: '+ 새 클라우드 추가', en: '+ Add New Cloud' },
  'account.searchService': { ko: '서비스 검색...', en: 'Search service...' },
  'account.noMatch': { ko: '일치하는 서비스가 없습니다', en: 'No matching services' },
  'account.remoteName': { ko: '리모트 이름', en: 'Remote Name' },
  'account.remoteNamePlaceholder': { ko: '예: my-pikpak', en: 'e.g. my-pikpak' },
  'account.remoteNameDesc': { ko: 'rclone에서 이 계정을 식별하는 이름', en: 'Name to identify this account in rclone' },
  'account.showAdvanced': { ko: '+ 고급 설정 보기', en: '+ Show Advanced' },
  'account.hideAdvanced': { ko: '- 고급 설정 숨기기', en: '- Hide Advanced' },
  'account.noSettings': { ko: '설정 항목이 없습니다 (기본값 사용 중)', en: 'No settings (using defaults)' },
  'account.connecting': { ko: '연결 중...', en: 'Connecting...' },
  'account.connect': { ko: '연결', en: 'Connect' },
  'account.addField': { ko: '+ 설정 항목 추가', en: '+ Add Setting' },
  'account.confirmDelete': { ko: '계정을 삭제하시겠습니까?', en: 'Delete this account?' },

  // Transfer
  'transfer.active': { ko: '진행', en: 'Active' },
  'transfer.completed': { ko: '완료', en: 'Done' },
  'transfer.errors': { ko: '오류', en: 'Errors' },
  'transfer.resumeAll': { ko: '전체 재개', en: 'Resume All' },
  'transfer.pauseAll': { ko: '전체 일시정지', en: 'Pause All' },
  'transfer.stopAll': { ko: '전체 중지', en: 'Stop All' },
  'transfer.clearHistory': { ko: '완료/중지 이력 삭제', en: 'Clear History' },
  'transfer.paused': { ko: '전송이 일시정지되었습니다', en: 'Transfers paused' },
  'transfer.resume': { ko: '재개', en: 'Resume' },
  'transfer.noActive': { ko: '진행 중인 전송이 없습니다', en: 'No active transfers' },
  'transfer.stopped': { ko: '중지됨', en: 'Stopped' },
  'transfer.noCompleted': { ko: '완료된 전송이 없습니다', en: 'No completed transfers' },
  'transfer.noErrors': { ko: '오류가 없습니다', en: 'No errors' },
  'transfer.stop': { ko: '전송 중지', en: 'Stop Transfer' },
  'transfer.restart': { ko: '재시작', en: 'Restart' },
  'transfer.removeFromList': { ko: '목록에서 제거', en: 'Remove from List' },
  'transfer.clearCompleted': { ko: '완료 목록 비우기', en: 'Clear Completed' },
  'transfer.clearErrors': { ko: '오류 목록 비우기', en: 'Clear Errors' },
  'transfer.copyError': { ko: '오류 내용 복사', en: 'Copy Error' },
  'transfer.count': { ko: '개 전송 중', en: ' transferring' },
  'transfer.errorCount': { ko: '개 오류', en: ' errors' },

  // Settings
  'settings.title': { ko: 'rclone 설정', en: 'rclone Settings' },
  'settings.performance': { ko: '성능', en: 'Performance' },
  'settings.reliability': { ko: '안정성', en: 'Reliability' },
  'settings.behavior': { ko: '동작', en: 'Behavior' },
  'settings.restoreDefaults': { ko: '기본값 복원', en: 'Restore Defaults' },
  'settings.applying': { ko: '적용 중...', en: 'Applying...' },
  'settings.apply': { ko: '적용', en: 'Apply' },
  'settings.applied': { ko: '설정이 적용되었습니다', en: 'Settings applied' },
  'settings.language': { ko: '언어', en: 'Language' },
  'settings.languageDesc': { ko: '언어를 변경하면 앱이 재시작됩니다', en: 'App will restart when language is changed' },
  'settings.transfers': { ko: '동시 전송 수', en: 'Concurrent Transfers' },
  'settings.transfersDesc': { ko: '동시에 전송할 파일 수', en: 'Number of files to transfer simultaneously' },
  'settings.checkers': { ko: '동시 체커 수', en: 'Concurrent Checkers' },
  'settings.checkersDesc': { ko: '동시에 체크할 파일 수', en: 'Number of files to check simultaneously' },
  'settings.multiThread': { ko: '멀티스레드 스트림', en: 'Multi-thread Streams' },
  'settings.multiThreadDesc': { ko: '파일당 동시 다운로드 스레드 수', en: 'Concurrent download threads per file' },
  'settings.bufferSize': { ko: '버퍼 크기', en: 'Buffer Size' },
  'settings.bufferSizeDesc': { ko: '각 파일 전송에 사용할 메모리 버퍼', en: 'Memory buffer for each file transfer' },
  'settings.bwLimit': { ko: '대역폭 제한', en: 'Bandwidth Limit' },
  'settings.bwLimitDesc': { ko: '비워두면 무제한. 예: 10M, 1G', en: 'Leave empty for unlimited. e.g. 10M, 1G' },
  'settings.retries': { ko: '재시도 횟수', en: 'Retries' },
  'settings.retriesDesc': { ko: '실패 시 재시도 횟수', en: 'Number of retries on failure' },
  'settings.lowLevelRetries': { ko: '하위 재시도', en: 'Low Level Retries' },
  'settings.lowLevelRetriesDesc': { ko: '저수준 연결 재시도 횟수', en: 'Low-level connection retry count' },
  'settings.contimeout': { ko: '연결 타임아웃', en: 'Connection Timeout' },
  'settings.contimeoutDesc': { ko: '서버 연결 제한 시간', en: 'Server connection time limit' },
  'settings.timeout': { ko: 'IO 타임아웃', en: 'IO Timeout' },
  'settings.timeoutDesc': { ko: 'IO 작업 제한 시간', en: 'IO operation time limit' },
  'settings.userAgent': { ko: 'User-Agent', en: 'User-Agent' },
  'settings.userAgentDesc': { ko: '사용자 에이전트 문자열 (비워두면 기본값)', en: 'User-Agent string (default if empty)' },
  'settings.noCheckCert': { ko: 'SSL 인증서 검증 무시', en: 'Skip SSL Certificate Verification' },
  'settings.noCheckCertDesc': { ko: 'HTTPS 인증서 검증을 건너뜁니다', en: 'Skip HTTPS certificate verification' },
  'settings.ignoreExisting': { ko: '기존 파일 무시', en: 'Ignore Existing' },
  'settings.ignoreExistingDesc': { ko: '이미 존재하는 파일은 건너뜁니다', en: 'Skip existing files' },
  'settings.ignoreSize': { ko: '크기 무시', en: 'Ignore Size' },
  'settings.ignoreSizeDesc': { ko: '파일 크기를 무시하고 전송', en: 'Transfer ignoring file size' },
  'settings.noTraverse': { ko: '디렉터리 탐색 안함', en: 'No Traverse' },
  'settings.noTraverseDesc': { ko: '대상 디렉터리 탐색 건너뛰기', en: 'Skip target directory traversal' },
  'settings.noUpdateModTime': { ko: '수정 시간 유지 안함', en: 'No Update ModTime' },
  'settings.noUpdateModTimeDesc': { ko: '전송 후 수정 시간을 업데이트하지 않음', en: "Don't update modification time after transfer" },
  'settings.unlimited': { ko: '무제한', en: 'Unlimited' },

  // App Lock
  'settings.security': { ko: '보안', en: 'Security' },
  'settings.appLock': { ko: '앱 잠금', en: 'App Lock' },
  'settings.appLockDesc': { ko: '앱 시작 시 인증을 요구합니다', en: 'Require authentication on app start' },
  'settings.appLockPassword': { ko: '잠금 비밀번호', en: 'Lock Password' },
  'settings.setPassword': { ko: '비밀번호 설정', en: 'Set Password' },
  'settings.changePassword': { ko: '비밀번호 변경', en: 'Change Password' },
  'settings.removePassword': { ko: '비밀번호 삭제', en: 'Remove Password' },
  'settings.currentPassword': { ko: '현재 비밀번호', en: 'Current Password' },
  'settings.newPassword': { ko: '새 비밀번호', en: 'New Password' },
  'settings.confirmPassword': { ko: '비밀번호 확인', en: 'Confirm Password' },
  'settings.passwordMismatch': { ko: '비밀번호가 일치하지 않습니다', en: 'Passwords do not match' },
  'settings.passwordTooShort': { ko: '비밀번호는 4자 이상이어야 합니다', en: 'Password must be at least 4 characters' },
  'settings.passwordSet': { ko: '비밀번호가 설정되었습니다', en: 'Password has been set' },
  'settings.passwordChanged': { ko: '비밀번호가 변경되었습니다', en: 'Password has been changed' },
  'settings.passwordRemoved': { ko: '비밀번호가 삭제되었습니다', en: 'Password has been removed' },
  'settings.wrongPassword': { ko: '비밀번호가 올바르지 않습니다', en: 'Incorrect password' },
  'settings.useTouchID': { ko: 'Touch ID 사용', en: 'Use Touch ID' },
  'settings.useTouchIDDesc': { ko: '지문 인식으로 앱 잠금을 해제합니다', en: 'Unlock app with fingerprint' },
  'settings.touchIDNotAvailable': { ko: 'Touch ID를 사용할 수 없는 기기입니다', en: 'Touch ID is not available on this device' },
  'settings.confirmRemovePassword': { ko: '비밀번호를 삭제하면 앱 잠금이 비활성화됩니다. 계속하시겠습니까?', en: 'Removing the password will disable app lock. Continue?' },

  // Lock Screen
  'lock.title': { ko: 'Rclone GUI', en: 'Rclone GUI' },
  'lock.subtitle': { ko: '잠금이 설정되어 있습니다', en: 'App is locked' },
  'lock.enterPassword': { ko: '비밀번호를 입력하세요', en: 'Enter your password' },
  'lock.unlock': { ko: '잠금 해제', en: 'Unlock' },
  'lock.useTouchID': { ko: 'Touch ID로 잠금 해제', en: 'Unlock with Touch ID' },
  'lock.wrongPassword': { ko: '비밀번호가 올바르지 않습니다', en: 'Incorrect password' },
  'lock.touchIDFailed': { ko: 'Touch ID 인증에 실패했습니다', en: 'Touch ID authentication failed' },

  // Search
  'search.placeholder': { ko: '연결된 클라우드에서 파일 검색...', en: 'Search files across connected clouds...' },
  'search.button': { ko: '검색', en: 'Search' },
  'search.filter': { ko: '필터', en: 'Filter' },
  'search.noCloud': { ko: '연결된 클라우드가 없습니다', en: 'No connected clouds' },
  'search.emptyHint': { ko: '검색어를 입력하여 파일을 찾으세요', en: 'Enter a keyword to find files' },
  'search.emptyDesc': { ko: '선택한 클라우드에서 결과를 검색합니다', en: 'Results will be fetched from selected clouds' },
  'search.noResults': { ko: '검색 결과가 없습니다:', en: 'No files found matching' },
  'search.searching': { ko: '클라우드에서 검색 중...', en: 'Searching through clouds...' },
  'search.colName': { ko: '이름', en: 'Name' },
  'search.colCloud': { ko: '클라우드', en: 'Cloud' },
  'search.colSize': { ko: '크기', en: 'Size' },
  'search.colDate': { ko: '날짜', en: 'Date' },
  'search.colFolder': { ko: '폴더 위치', en: 'Folder' },
  'search.resultCount': { ko: '개 결과', en: ' results' },
};

export function t(key: string): string {
  const locale = useI18n.getState().locale;
  return translations[key]?.[locale] ?? key;
}

// Hook version for reactive updates
export function useT() {
  const locale = useI18n((s) => s.locale);
  return (key: string): string => {
    return translations[key]?.[locale] ?? key;
  };
}
