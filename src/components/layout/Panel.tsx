import { useEffect } from 'react';
import { usePanelStore } from '../../stores/panelStore';
import { usePanelFiles } from '../../hooks/useRclone';
import { RemoteSelector } from '../account/RemoteSelector';
import { AddressBar } from '../file-browser/AddressBar';
import { FileList } from '../file-browser/FileList';
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

  const isActive = activePanel === side;

  // Load files when remote changes (or on mount for local panel)
  useEffect(() => {
    if (panel.remote) {
      loadFiles(panel.remote, panel.path);
    }
  }, [panel.remote]); // eslint-disable-line react-hooks/exhaustive-deps

  // For cloud panel: show remote selector if no remote selected
  if (panel.mode === 'cloud' && !panel.remote) {
    return (
      <div
        className={`h-full flex flex-col bg-surface ${isActive ? 'ring-1 ring-accent/50' : ''}`}
        onClick={() => setActivePanel(side)}
      >
        <div className="p-3 bg-surface-raised border-b border-border">
          <span className="text-xs text-text-muted">클라우드 선택</span>
        </div>
        <RemoteSelector onSelect={(remote) => setRemote(side, remote)} />
      </div>
    );
  }

  return (
    <div
      className={`h-full flex flex-col bg-surface ${isActive ? 'ring-1 ring-accent/50' : ''}`}
      onClick={() => setActivePanel(side)}
    >
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
    </div>
  );
}
