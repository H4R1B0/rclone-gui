import { Plus, ArrowDownUp, RefreshCw, Settings } from 'lucide-react';
import { usePanelStore } from '../../stores/panelStore';
import { usePanelFiles } from '../../hooks/useRclone';
import { useT } from '../../lib/i18n';

interface ToolbarProps {
  onAddAccount: () => void;
  onToggleTransfers: () => void;
  onOpenSettings: () => void;
  showTransfers: boolean;
}

export function Toolbar({ onAddAccount, onToggleTransfers, onOpenSettings, showTransfers }: ToolbarProps) {
  const activePanel = usePanelStore((s) => s.activePanel);
  const { refresh } = usePanelFiles(activePanel);
  const t = useT();

  return (
    <div className="flex items-center gap-2 px-3 py-2 bg-surface-raised border-b border-border">
      <button onClick={onAddAccount} className="flex items-center gap-1.5 px-3 py-1.5 text-xs rounded bg-accent hover:bg-accent-hover text-white transition-colors">
        <Plus size={14} />
        {t('toolbar.addAccount')}
      </button>
      <button onClick={refresh} className="flex items-center gap-1.5 px-3 py-1.5 text-xs rounded bg-surface-overlay hover:bg-border text-text transition-colors">
        <RefreshCw size={14} />
        {t('toolbar.refresh')}
      </button>
      <div className="flex-1" />
      <button onClick={onToggleTransfers} className={`flex items-center gap-1.5 px-3 py-1.5 text-xs rounded transition-colors ${showTransfers ? 'bg-accent-muted text-accent' : 'bg-surface-overlay text-text-muted hover:bg-border'}`}>
        <ArrowDownUp size={14} />
        {t('toolbar.transfer')}
      </button>
      <button onClick={onOpenSettings} className="flex items-center gap-1.5 px-3 py-1.5 text-xs rounded bg-surface-overlay hover:bg-border text-text-muted hover:text-text transition-colors">
        <Settings size={14} />
        {t('toolbar.settings')}
      </button>
    </div>
  );
}
