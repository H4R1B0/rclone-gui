import { useEffect, useState } from 'react';
import { Toolbar } from './components/layout/Toolbar';
import { DualPanel } from './components/layout/DualPanel';
import { StatusBar } from './components/layout/StatusBar';
import { TransferQueue } from './components/transfer/TransferQueue';
import { AccountSetup } from './components/account/AccountSetup';
import { useRclone } from './hooks/useRclone';
import { useTransferPolling } from './hooks/useTransferPolling';
import { usePanelStore } from './stores/panelStore';
import { usePanelFiles } from './hooks/useRclone';

export default function App() {
  const [showAccountSetup, setShowAccountSetup] = useState(false);
  const [showTransfers, setShowTransfers] = useState(true);
  const { loadRemotes } = useRclone();
  const setPath = usePanelStore((s) => s.setPath);
  const { loadFiles: loadLeftFiles } = usePanelFiles('left');
  useTransferPolling();

  useEffect(() => {
    loadRemotes();
    // Set left panel to user's home directory
    window.rcloneAPI.getHomeDir().then((home) => {
      const cleanPath = home.replace(/^\/+/, '');
      setPath('left', cleanPath);
      loadLeftFiles('/', cleanPath);
    });
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <div className="flex flex-col h-screen bg-surface">
      {/* Drag region for macOS titlebar */}
      <div className="h-12 flex-shrink-0 flex items-center px-20 bg-surface-raised border-b border-border" style={{ WebkitAppRegion: 'drag' } as React.CSSProperties}>
        <span className="text-sm font-semibold text-text-muted" style={{ WebkitAppRegion: 'no-drag' } as React.CSSProperties}>
          Rclone GUI
        </span>
      </div>

      <Toolbar
        onAddAccount={() => setShowAccountSetup(true)}
        onToggleTransfers={() => setShowTransfers((v) => !v)}
        showTransfers={showTransfers}
      />

      <div className="flex-1 flex flex-col min-h-0">
        <DualPanel />
        {showTransfers && <TransferQueue />}
      </div>

      <StatusBar />

      {showAccountSetup && (
        <AccountSetup onClose={() => { setShowAccountSetup(false); loadRemotes(); }} />
      )}
    </div>
  );
}
