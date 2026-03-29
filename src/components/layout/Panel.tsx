import { useEffect, useState } from 'react';
import { usePanelStore } from '../../stores/panelStore';
import { usePanelFiles, useRclone } from '../../hooks/useRclone';
import { RemoteSelector } from '../account/RemoteSelector';
import { AccountSetup } from '../account/AccountSetup';
import { AddressBar } from '../file-browser/AddressBar';
import { FileList } from '../file-browser/FileList';
import { TabBar } from './TabBar';
import { Loader2 } from 'lucide-react';

interface PanelProps {
  side: 'left' | 'right';
}

export function Panel({ side }: PanelProps) {
  const panel = usePanelStore((s) => s[side]);
  const activePanel = usePanelStore((s) => s.activePanel);
  const setActivePanel = usePanelStore((s) => s.setActivePanel);
  const setRemote = usePanelStore((s) => s.setRemote);
  const { loadFiles } = usePanelFiles(side);
  const { loadRemotes } = useRclone();
  const [showAccountSetup, setShowAccountSetup] = useState(false);

  const isActive = activePanel === side;

  // Reload files when active tab's remote changes
  useEffect(() => {
    if (panel.remote) {
      loadFiles(panel.remote, panel.path);
    }
  }, [panel.remote, panel.id]); // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <div
      className={`h-full flex flex-col min-h-0 bg-surface ${isActive ? 'ring-1 ring-accent/50' : ''}`}
      onClick={() => setActivePanel(side)}
    >
      <TabBar side={side} />

      {/* Cloud panel: show remote selector if no remote selected */}
      {panel.mode === 'cloud' && !panel.remote ? (
        <>
          <RemoteSelector
            onSelect={(remote) => setRemote(side, remote)}
            onAddAccount={() => setShowAccountSetup(true)}
          />
          {showAccountSetup && (
            <AccountSetup onClose={() => { setShowAccountSetup(false); loadRemotes(); }} />
          )}
        </>
      ) : (
        <>
          <AddressBar side={side} />
          {panel.loading ? (
            <div className="flex-1 flex items-center justify-center">
              <Loader2 className="animate-spin text-accent" size={24} />
            </div>
          ) : panel.error ? (
            <div className="flex-1 flex items-center justify-center text-danger text-sm px-4 text-center">
              {panel.error}
            </div>
          ) : (
            <FileList side={side} />
          )}
        </>
      )}
    </div>
  );
}
