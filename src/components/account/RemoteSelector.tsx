import { usePanelStore } from '../../stores/panelStore';
import { HardDrive, Loader2 } from 'lucide-react';

interface RemoteSelectorProps {
  onSelect: (remote: string) => void;
}

export function RemoteSelector({ onSelect }: RemoteSelectorProps) {
  const remotes = usePanelStore((s) => s.remotes);
  const loading = usePanelStore((s) => s.remotesLoading);

  if (loading) {
    return (
      <div className="flex-1 flex items-center justify-center">
        <Loader2 className="animate-spin text-accent" size={24} />
      </div>
    );
  }

  if (remotes.length === 0) {
    return (
      <div className="flex-1 flex items-center justify-center text-text-muted text-sm">
        연결된 클라우드가 없습니다. "계정 추가"를 클릭하세요.
      </div>
    );
  }

  return (
    <div className="flex-1 overflow-y-auto p-3">
      <div className="grid grid-cols-2 gap-2">
        {remotes.map((name) => (
          <button
            key={name}
            onClick={() => onSelect(`${name}:`)}
            className="flex items-center gap-3 p-3 rounded-lg bg-surface-overlay hover:bg-border border border-transparent hover:border-accent/30 transition-colors text-left"
          >
            <HardDrive size={20} className="text-accent flex-shrink-0" />
            <span className="text-sm text-text truncate">{name}</span>
          </button>
        ))}
      </div>
    </div>
  );
}
