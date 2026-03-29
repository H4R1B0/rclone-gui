import { useState, useEffect } from 'react';
import { usePanelStore } from '../../stores/panelStore';
import { Loader2, Plus } from 'lucide-react';
import { ProviderIconSvg } from '../common/ProviderIconSvg';
import { useT } from '../../lib/i18n';

interface RemoteSelectorProps {
  onSelect: (remote: string) => void;
  onAddAccount?: () => void;
}

export function RemoteSelector({ onSelect, onAddAccount }: RemoteSelectorProps) {
  const remotes = usePanelStore((s) => s.remotes);
  const loading = usePanelStore((s) => s.remotesLoading);
  const t = useT();
  const [types, setTypes] = useState<Record<string, string>>({});

  useEffect(() => {
    const loadTypes = async () => {
      const result: Record<string, string> = {};
      for (const name of remotes) {
        try {
          const cfg = await window.rcloneAPI.getRemoteConfig(name) as Record<string, string>;
          result[name] = cfg.type ?? '';
        } catch {
          result[name] = '';
        }
      }
      setTypes(result);
    };
    if (remotes.length > 0) loadTypes();
  }, [remotes]);

  if (loading) {
    return (
      <div className="flex-1 flex items-center justify-center">
        <Loader2 className="animate-spin text-accent" size={24} />
      </div>
    );
  }

  return (
    <div className="flex-1 overflow-y-auto p-3">
      <div className="grid grid-cols-2 gap-2">
        {remotes.map((name) => {
          const type = types[name] ?? '';
          return (
            <button
              key={name}
              onClick={() => onSelect(`${name}:`)}
              className="flex items-center gap-3 p-3 rounded-lg bg-surface-overlay hover:bg-border border border-transparent hover:border-accent/30 transition-colors text-left"
            >
              <ProviderIconSvg prefix={type} size={24} className="flex-shrink-0" />
              <div className="min-w-0">
                <span className="text-sm text-text block truncate">{name}</span>
                {type && <span className="text-[10px] text-text-muted">{type}</span>}
              </div>
            </button>
          );
        })}

        {/* Add account button */}
        {onAddAccount && (
          <button
            onClick={onAddAccount}
            className="flex items-center gap-3 p-3 rounded-lg border border-dashed border-border hover:border-accent/50 hover:bg-accent/5 transition-colors text-left"
          >
            <div className="w-6 h-6 rounded-full bg-accent/15 flex items-center justify-center flex-shrink-0">
              <Plus size={14} className="text-accent" />
            </div>
            <span className="text-sm text-text-muted">{t('remote.connect')}</span>
          </button>
        )}
      </div>

      {remotes.length === 0 && (
        <div className="text-center py-6 text-text-muted text-xs">
          {t('remote.noCloud')}
        </div>
      )}
    </div>
  );
}
