import { ArrowDownUp, RefreshCw, Settings, Search, LayoutGrid, Cloud } from 'lucide-react';
import { usePanelStore } from '../../stores/panelStore';
import { usePanelFiles } from '../../hooks/useRclone';
import { useT } from '../../lib/i18n';

interface ToolbarProps {
  onAddAccount: () => void;
  onExplore: () => void;
  onToggleTransfers: () => void;
  onOpenSettings: () => void;
  onOpenSearch: () => void;
  showTransfers: boolean;
  activeMode: 'explore' | 'account' | 'search';
}

export function Toolbar({ onAddAccount, onExplore, onToggleTransfers, onOpenSettings, onOpenSearch, showTransfers, activeMode }: ToolbarProps) {
  const activePanel = usePanelStore((s) => s.activePanel);
  const { refresh } = usePanelFiles(activePanel);
  const t = useT();

  return (
    <div className="flex items-center gap-1 px-4 py-2 bg-surface-raised border-b border-border shadow-sm">
      
      {/* Main Navigation (Left) */}
      <div className="flex items-center gap-2 mr-6">
        <button onClick={onExplore} className={`flex items-center gap-2 px-4 py-2 text-sm font-semibold rounded-lg transition-colors
          ${activeMode === 'explore' ? 'bg-accent/10 text-accent dark:bg-accent/20 dark:text-accent-hover' : 'hover:bg-surface-overlay text-text-muted hover:text-text'}`}>
          <LayoutGrid className="w-5 h-5" />
          {t('toolbar.explore')}
        </button>
        <button onClick={onAddAccount} className={`flex items-center gap-2 px-4 py-2 text-sm font-semibold rounded-lg transition-colors
          ${activeMode === 'account' ? 'bg-accent/10 text-accent dark:bg-accent/20 dark:text-accent-hover' : 'hover:bg-surface-overlay text-text-muted hover:text-text'}`}>
          <Cloud className="w-5 h-5" />
          {t('toolbar.accounts')}
        </button>
        <button onClick={onOpenSearch} className={`flex items-center gap-2 px-4 py-2 text-sm font-semibold rounded-lg transition-colors
          ${activeMode === 'search' ? 'bg-accent/10 text-accent dark:bg-accent/20 dark:text-accent-hover' : 'hover:bg-surface-overlay text-text-muted hover:text-text'}`}>
          <Search className="w-5 h-5" />
          {t('toolbar.search')}
        </button>
      </div>

      <div className="w-px h-6 bg-border mx-2" />

      {/* Action Navigation (Right aligned) */}
      <div className="flex items-center gap-2 ml-auto">
        <button onClick={refresh} className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-md hover:bg-surface-overlay text-text-muted hover:text-text transition-colors" title={t('toolbar.refresh')}>
          <RefreshCw className="w-4 h-4" />
          <span className="hidden sm:inline">{t('toolbar.refresh')}</span>
        </button>
        <button onClick={onToggleTransfers} className={`flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-md transition-colors ${showTransfers ? 'bg-accent/10 text-accent dark:bg-accent/20' : 'hover:bg-surface-overlay text-text-muted hover:text-text'}`}>
          <ArrowDownUp className="w-4 h-4" />
          <span className="hidden sm:inline">{t('toolbar.transfer')}</span>
        </button>
        <button onClick={onOpenSettings} className="flex flex-col items-center justify-center p-2 rounded-md hover:bg-surface-overlay text-text-muted hover:text-text transition-colors" title={t('toolbar.settings')}>
          <Settings className="w-5 h-5" />
        </button>
      </div>
    </div>
  );
}
