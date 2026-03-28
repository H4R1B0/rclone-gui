import { ChevronRight, Home, HardDrive } from 'lucide-react';
import { usePanelStore } from '../../stores/panelStore';
import { usePanelFiles } from '../../hooks/useRclone';

interface BreadcrumbProps {
  side: 'left' | 'right';
}

export function Breadcrumb({ side }: BreadcrumbProps) {
  const panel = usePanelStore((s) => s[side]);
  const setRemote = usePanelStore((s) => s.setRemote);
  const { loadFiles } = usePanelFiles(side);
  const parts = panel.path.split('/').filter(Boolean);

  const goToHome = () => setRemote(side, '');
  const goToRoot = () => loadFiles(panel.remote, '');
  const goToPath = (index: number) => {
    const newPath = parts.slice(0, index + 1).join('/');
    loadFiles(panel.remote, newPath);
  };

  return (
    <div className="flex items-center gap-1 px-3 py-2 bg-surface-raised border-b border-border text-xs overflow-x-auto">
      <button onClick={goToHome} className="text-text-muted hover:text-accent flex-shrink-0">
        <Home size={14} />
      </button>
      <ChevronRight size={12} className="text-text-muted flex-shrink-0" />
      <button
        onClick={goToRoot}
        className="text-text-muted hover:text-accent flex-shrink-0 flex items-center gap-1"
      >
        <HardDrive size={12} />
        {panel.remote}
      </button>
      {parts.map((part, i) => (
        <span key={i} className="flex items-center gap-1 flex-shrink-0">
          <ChevronRight size={12} className="text-text-muted" />
          <button
            onClick={() => goToPath(i)}
            className={`hover:text-accent ${i === parts.length - 1 ? 'text-text' : 'text-text-muted'}`}
          >
            {part}
          </button>
        </span>
      ))}
    </div>
  );
}
