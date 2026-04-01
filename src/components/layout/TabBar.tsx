import { useState, useRef, useEffect } from 'react';
import { usePanelStore } from '../../stores/panelStore';
import { Plus, X, Monitor, Cloud } from 'lucide-react';
import { useT } from '../../lib/i18n';

interface TabBarProps {
  side: 'left' | 'right';
}

export function TabBar({ side }: TabBarProps) {
  const sideState = usePanelStore((s) => side === 'left' ? s.leftSide : s.rightSide);
  const switchTab = usePanelStore((s) => s.switchTab);
  const closeTab = usePanelStore((s) => s.closeTab);
  const addTab = usePanelStore((s) => s.addTab);
  const remotes = usePanelStore((s) => s.remotes);
  const t = useT();

  const [showMenu, setShowMenu] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);
  const btnRef = useRef<HTMLButtonElement>(null);

  // Close menu on outside click
  useEffect(() => {
    if (!showMenu) return;
    const handler = (e: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(e.target as Node) &&
          btnRef.current && !btnRef.current.contains(e.target as Node)) {
        setShowMenu(false);
      }
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, [showMenu]);

  const displayLabel = (label: string) => {
    if (label === 'local') return t('panel.myPc');
    if (label === 'cloud') return t('panel.cloud');
    return label;
  };

  const handleAddLocal = () => {
    addTab(side, 'local', '/', '', 'local');
    setShowMenu(false);
  };

  const handleAddCloud = (remote?: string) => {
    if (remote) {
      addTab(side, 'cloud', `${remote}:`, '', remote);
    } else {
      addTab(side, 'cloud', '', '', 'cloud');
    }
    setShowMenu(false);
  };

  const addButton = (
    <div className="relative flex-shrink-0">
      <button
        ref={btnRef}
        onClick={() => setShowMenu((v) => !v)}
        className="px-2 py-1.5 text-text-muted hover:text-accent hover:bg-surface-overlay transition-colors"
        title={t('panel.newTab')}
      >
        <Plus size={12} />
      </button>
      {showMenu && (
        <div
          ref={menuRef}
          className={`absolute top-full z-50 mt-1 min-w-[180px] bg-surface-raised border border-border rounded-lg shadow-lg py-1 overflow-hidden ${side === 'right' ? 'right-0' : 'left-0'}`}
        >
          <button
            onClick={handleAddLocal}
            className="w-full flex items-center gap-2 px-3 py-2 text-[12px] text-text hover:bg-surface-overlay transition-colors"
          >
            <Monitor size={14} className="text-text-muted flex-shrink-0" />
            {t('panel.myPc')}
          </button>
          {remotes.length > 0 && (
            <div className="border-t border-border my-1" />
          )}
          {remotes.map((name) => (
            <button
              key={name}
              onClick={() => handleAddCloud(name)}
              className="w-full flex items-center gap-2 px-3 py-2 text-[12px] text-text hover:bg-surface-overlay transition-colors"
            >
              <Cloud size={14} className="text-accent flex-shrink-0" />
              <span className="truncate">{name}</span>
            </button>
          ))}
          {remotes.length === 0 && (
            <div className="px-3 py-2 text-[11px] text-text-muted">
              {t('remote.noCloud')}
            </div>
          )}
        </div>
      )}
    </div>
  );

  return (
    <div className="flex items-center bg-surface border-b border-border">
      {sideState.tabs.map((tab) => {
        const isActive = tab.id === sideState.activeTabId;
        const label = tab.mode === 'local'
          ? t('panel.myPc')
          : tab.remote
            ? (tab.path ? tab.path.split('/').pop() : tab.remote)
            : displayLabel(tab.label);

        return (
          <div
            key={tab.id}
            className={`flex items-center gap-1 px-3 py-1.5 text-[11px] cursor-pointer border-r border-border min-w-0 flex-1 transition-colors ${
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
      {addButton}
    </div>
  );
}
