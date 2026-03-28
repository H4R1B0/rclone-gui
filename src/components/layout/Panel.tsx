import { useEffect } from 'react';
import { usePanelStore } from '../../stores/panelStore';
import { usePanelFiles } from '../../hooks/useRclone';
import { RemoteSelector } from '../account/RemoteSelector';
import { Breadcrumb } from '../file-browser/Breadcrumb';
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

  useEffect(() => {
    if (panel.remote) {
      loadFiles(panel.remote, panel.path);
    }
  }, [panel.remote]); // eslint-disable-line react-hooks/exhaustive-deps

  const handleSelectRemote = (remote: string) => {
    setRemote(side, remote);
  };

  if (!panel.remote) {
    return (
      <div
        className={`h-full flex flex-col bg-surface ${isActive ? 'ring-1 ring-accent/50' : ''}`}
        onClick={() => setActivePanel(side)}
      >
        <div className="p-3 bg-surface-raised border-b border-border">
          <span className="text-xs text-text-muted">리모트 선택</span>
        </div>
        <RemoteSelector onSelect={handleSelectRemote} />
      </div>
    );
  }

  return (
    <div
      className={`h-full flex flex-col bg-surface ${isActive ? 'ring-1 ring-accent/50' : ''}`}
      onClick={() => setActivePanel(side)}
    >
      <Breadcrumb side={side} />
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
