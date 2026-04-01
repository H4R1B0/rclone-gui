import { usePanelStore } from '../../stores/panelStore';
import { Plus, X } from 'lucide-react';
import { useT } from '../../lib/i18n';

interface TabBarProps {
  side: 'left' | 'right';
}

export function TabBar({ side }: TabBarProps) {
  const sideState = usePanelStore((s) => side === 'left' ? s.leftSide : s.rightSide);
  const switchTab = usePanelStore((s) => s.switchTab);
  const closeTab = usePanelStore((s) => s.closeTab);
  const addTab = usePanelStore((s) => s.addTab);
  const panel = usePanelStore((s) => s[side]);
  const t = useT();

  const displayLabel = (label: string) => {
    if (label === 'local') return t('panel.myPc');
    if (label === 'cloud') return t('panel.cloud');
    return label;
  };

  const handleAddTab = () => {
    // New tab inherits current panel mode
    if (panel.mode === 'local') {
      addTab(side, 'local', '/', '', 'local');
    } else {
      addTab(side, 'cloud', '', '', 'cloud');
    }
  };

  // Single tab: show current cloud name + add button
  if (sideState.tabs.length <= 1) {
    const activeTab = sideState.tabs[0];
    const label = activeTab?.remote
      ? activeTab.remote.replace(/:$/, '')
      : displayLabel(activeTab?.label ?? '');

    return (
      <div className="flex items-center bg-surface border-b border-border">
        {activeTab?.remote ? (
          <span className="px-3 py-1 text-[11px] font-medium text-accent truncate max-w-[160px]">
            {label}
          </span>
        ) : null}
        <div className="flex-1" />
        <button
          onClick={handleAddTab}
          className="px-2 py-1 text-text-muted hover:text-accent hover:bg-surface-overlay transition-colors"
          title={t('panel.newTab')}
        >
          <Plus size={12} />
        </button>
      </div>
    );
  }

  return (
    <div className="flex items-center bg-surface border-b border-border overflow-x-auto">
      {sideState.tabs.map((tab) => {
        const isActive = tab.id === sideState.activeTabId;
        const label = tab.remote
          ? (tab.path ? tab.path.split('/').pop() : tab.remote)
          : displayLabel(tab.label);

        return (
          <div
            key={tab.id}
            className={`flex items-center gap-1 px-3 py-1.5 text-[11px] cursor-pointer border-r border-border min-w-0 max-w-[160px] transition-colors ${
              isActive
                ? 'bg-surface-raised text-text'
                : 'text-text-muted hover:text-text hover:bg-surface-overlay'
            }`}
            onClick={() => switchTab(side, tab.id)}
          >
            <span className="truncate flex-1">{label}</span>
            {sideState.tabs.length > 1 && (
              <button
                onClick={(e) => { e.stopPropagation(); closeTab(side, tab.id); }}
                className="flex-shrink-0 p-0.5 rounded hover:bg-border hover:text-danger transition-colors"
              >
                <X size={10} />
              </button>
            )}
          </div>
        );
      })}
      <button
        onClick={handleAddTab}
        className="px-2 py-1.5 text-text-muted hover:text-accent hover:bg-surface-overlay transition-colors flex-shrink-0"
        title={t('panel.newTab')}
      >
        <Plus size={12} />
      </button>
    </div>
  );
}
