import { useEffect, useState, useCallback } from 'react';
import { Toolbar } from './components/layout/Toolbar';
import { DualPanel } from './components/layout/DualPanel';
import { StatusBar } from './components/layout/StatusBar';
import { TransferQueue } from './components/transfer/TransferQueue';
import { AccountSetup } from './components/account/AccountSetup';
import { SettingsModal } from './components/settings/SettingsModal';
import { LockScreen } from './components/lock/LockScreen';
import { SearchPanel } from './components/search/SearchPanel';
import { useRclone, usePanelFiles } from './hooks/useRclone';
import { useTransferPolling } from './hooks/useTransferPolling';
import { usePanelStore } from './stores/panelStore';
import { useI18n, type Locale } from './lib/i18n';
import { GripHorizontal } from 'lucide-react';

export default function App() {
  const [ready, setReady] = useState(false);
  const [activeView, setActiveView] = useState<'explore' | 'account' | 'search'>('explore');
  const [showSettings, setShowSettings] = useState(false);
  const [showTransfers, setShowTransfers] = useState(true);
  const [transferHeight, setTransferHeight] = useState(200);
  const [resizing, setResizing] = useState(false);
  const [locked, setLocked] = useState<boolean | null>(null); // null = loading
  const [lockCanTouchID, setLockCanTouchID] = useState(false);
  const [lockUseTouchID, setLockUseTouchID] = useState(false);
  const { loadRemotes } = useRclone();
  const setPath = usePanelStore((s) => s.setPath);
  const { loadFiles: loadLeftFiles } = usePanelFiles('left');
  useTransferPolling();

  const onResizeStart = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    setResizing(true);
    const startY = e.clientY;
    const startH = transferHeight;
    const onMove = (ev: MouseEvent) => {
      const delta = startY - ev.clientY;
      setTransferHeight(Math.max(80, Math.min(600, startH + delta)));
    };
    const onUp = () => {
      setResizing(false);
      window.removeEventListener('mousemove', onMove);
      window.removeEventListener('mouseup', onUp);
    };
    window.addEventListener('mousemove', onMove);
    window.addEventListener('mouseup', onUp);
  }, [transferHeight]);

  useEffect(() => {
    // Load saved locale
    window.rcloneAPI.loadSettings().then((saved) => {
      if (saved && saved.locale) {
        useI18n.getState().setLocale(saved.locale as Locale);
      }
    });

    // Check app lock
    const checkLock = async () => {
      try {
        const config = await window.rcloneAPI.appLockGetConfig();
        const hasPw = await window.rcloneAPI.appLockHasPassword();
        if (config.appLockEnabled && hasPw) {
          const canTouch = await window.rcloneAPI.appLockCanUseTouchID();
          setLockCanTouchID(canTouch);
          setLockUseTouchID(config.useTouchID);
          setLocked(true);
        } else {
          setLocked(false);
        }
      } catch {
        setLocked(false);
      }
    };
    checkLock();

    // Wait for rclone daemon to be ready before rendering panels
    const waitAndLoad = async () => {
      for (let i = 0; i < 30; i++) {
        try {
          await window.rcloneAPI.listRemotes();
          break;
        } catch {
          await new Promise((r) => setTimeout(r, 500));
        }
      }
      await loadRemotes();
      const home = await window.rcloneAPI.getHomeDir();
      const cleanPath = home.replace(/^\/+/, '');
      setPath('left', cleanPath);
      await loadLeftFiles('/', cleanPath);
      setReady(true);
    };
    waitAndLoad();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  // Don't render anything until lock check completes
  if (locked === null) {
    return (
      <div className="flex items-center justify-center h-screen bg-surface">
        <div className="w-6 h-6 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="flex flex-col h-screen bg-surface">
      {/* Lock Screen */}
      {locked && (
        <LockScreen
          onUnlock={() => setLocked(false)}
          canUseTouchID={lockCanTouchID}
          useTouchID={lockUseTouchID}
        />
      )}

      {/* Drag region for macOS titlebar */}
      <div className="h-12 flex-shrink-0 flex items-center px-20 bg-surface-raised border-b border-border" style={{ WebkitAppRegion: 'drag' } as React.CSSProperties}>
        <span className="text-sm font-semibold text-text-muted" style={{ WebkitAppRegion: 'no-drag' } as React.CSSProperties}>
          Rclone GUI
        </span>
      </div>

      <Toolbar
        onExplore={() => setActiveView('explore')}
        onAddAccount={() => setActiveView('account')}
        onToggleTransfers={() => setShowTransfers((v) => !v)}
        onOpenSettings={() => setShowSettings(true)}
        onOpenSearch={() => setActiveView('search')}
        showTransfers={showTransfers}
        activeMode={activeView}
      />

      <div className="flex-1 flex flex-col min-h-0" style={{ cursor: resizing ? 'row-resize' : undefined }}>
        <div className="flex-1 min-h-0 h-full">
          {!ready ? (
            <div className="flex items-center justify-center h-full text-text-muted text-sm">
              rclone 데몬 연결 중...
            </div>
          ) : activeView === 'account' ? (
            <AccountSetup onClose={() => { setActiveView('explore'); loadRemotes(); }} />
          ) : activeView === 'search' ? (
            <SearchPanel />
          ) : (
            <DualPanel />
          )}
        </div>
        {showTransfers && (
          <>
            <div
              className="h-1 bg-border hover:bg-accent cursor-row-resize flex items-center justify-center flex-shrink-0 transition-colors"
              onMouseDown={onResizeStart}
            >
              <GripHorizontal size={12} className="text-text-muted" />
            </div>
            <div style={{ height: transferHeight }} className="flex-shrink-0">
              <TransferQueue />
            </div>
          </>
        )}
      </div>

      <StatusBar />

      {showSettings && (
        <SettingsModal onClose={() => setShowSettings(false)} />
      )}

    </div>
  );
}
