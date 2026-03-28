import { useState, useEffect } from 'react';
import { X, Loader2, Trash2 } from 'lucide-react';
import { usePanelStore } from '../../stores/panelStore';

interface AccountSetupProps {
  onClose: () => void;
}

interface ProviderOption {
  Name: string;
  Description: string;
  Prefix: string;
}

const POPULAR_PROVIDERS = [
  'drive', 'onedrive', 'dropbox', 's3', 'b2', 'box',
  'mega', 'pcloud', 'sftp', 'ftp', 'webdav', 'nextcloud',
];

export function AccountSetup({ onClose }: AccountSetupProps) {
  const [providers, setProviders] = useState<ProviderOption[]>([]);
  const [loading, setLoading] = useState(true);
  const [step, setStep] = useState<'list' | 'create' | 'manage'>('list');
  const [selectedProvider, setSelectedProvider] = useState<ProviderOption | null>(null);
  const [remoteName, setRemoteName] = useState('');
  const [creating, setCreating] = useState(false);
  const [error, setError] = useState('');
  const remotes = usePanelStore((s) => s.remotes);

  useEffect(() => {
    window.rcloneAPI.getProviders().then((p) => {
      setProviders(p as ProviderOption[]);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, []);

  const handleCreate = async () => {
    if (!remoteName.trim() || !selectedProvider) return;
    setCreating(true);
    setError('');
    try {
      await window.rcloneAPI.createRemote(remoteName.trim(), selectedProvider.Prefix, {});
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create remote');
    } finally {
      setCreating(false);
    }
  };

  const handleDelete = async (name: string) => {
    try {
      await window.rcloneAPI.deleteRemote(name);
      const newRemotes = await window.rcloneAPI.listRemotes();
      usePanelStore.getState().setRemotes(newRemotes);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete remote');
    }
  };

  const popularProviders = providers.filter((p) => POPULAR_PROVIDERS.includes(p.Prefix));
  const otherProviders = providers.filter((p) => !POPULAR_PROVIDERS.includes(p.Prefix));

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50">
      <div className="bg-surface-raised border border-border rounded-xl shadow-2xl w-[600px] max-h-[80vh] flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-border">
          <h2 className="text-sm font-semibold text-text">
            {step === 'list' ? '클라우드 계정 관리' : step === 'create' ? '새 계정 추가' : '계정 관리'}
          </h2>
          <button onClick={onClose} className="text-text-muted hover:text-text">
            <X size={18} />
          </button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto p-5">
          {step === 'list' && (
            <div className="space-y-4">
              {/* Existing remotes */}
              {remotes.length > 0 && (
                <div>
                  <h3 className="text-xs text-text-muted mb-2">연결된 계정</h3>
                  <div className="space-y-1">
                    {remotes.map((name) => (
                      <div key={name} className="flex items-center justify-between px-3 py-2 rounded bg-surface-overlay">
                        <span className="text-sm text-text">{name}</span>
                        <button
                          onClick={() => handleDelete(name)}
                          className="text-text-muted hover:text-danger"
                        >
                          <Trash2 size={14} />
                        </button>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              <button
                onClick={() => setStep('create')}
                className="w-full py-2.5 rounded-lg bg-accent hover:bg-accent-hover text-white text-sm transition-colors"
              >
                + 새 클라우드 추가
              </button>
            </div>
          )}

          {step === 'create' && !selectedProvider && (
            <div>
              {loading ? (
                <div className="flex justify-center py-8">
                  <Loader2 className="animate-spin text-accent" size={24} />
                </div>
              ) : (
                <div className="space-y-4">
                  <div>
                    <h3 className="text-xs text-text-muted mb-2">인기 서비스</h3>
                    <div className="grid grid-cols-3 gap-2">
                      {popularProviders.map((p) => (
                        <button
                          key={p.Prefix}
                          onClick={() => setSelectedProvider(p)}
                          className="p-3 rounded-lg bg-surface-overlay hover:bg-border border border-transparent hover:border-accent/30 text-left transition-colors"
                        >
                          <div className="text-sm text-text font-medium">{p.Name}</div>
                          <div className="text-[10px] text-text-muted mt-0.5 truncate">{p.Description}</div>
                        </button>
                      ))}
                    </div>
                  </div>
                  <div>
                    <h3 className="text-xs text-text-muted mb-2">기타 서비스</h3>
                    <div className="grid grid-cols-3 gap-2 max-h-[200px] overflow-y-auto">
                      {otherProviders.map((p) => (
                        <button
                          key={p.Prefix}
                          onClick={() => setSelectedProvider(p)}
                          className="p-2 rounded bg-surface-overlay hover:bg-border text-left transition-colors"
                        >
                          <div className="text-xs text-text">{p.Name}</div>
                        </button>
                      ))}
                    </div>
                  </div>
                </div>
              )}
            </div>
          )}

          {step === 'create' && selectedProvider && (
            <div className="space-y-4">
              <div>
                <div className="text-sm text-text mb-1">{selectedProvider.Name}</div>
                <div className="text-xs text-text-muted">{selectedProvider.Description}</div>
              </div>
              <div>
                <label className="text-xs text-text-muted block mb-1">리모트 이름</label>
                <input
                  autoFocus
                  className="w-full px-3 py-2 rounded bg-surface-overlay border border-border focus:border-accent text-sm text-text outline-none"
                  placeholder="예: my-gdrive"
                  value={remoteName}
                  onChange={(e) => setRemoteName(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && handleCreate()}
                />
              </div>
              <p className="text-[11px] text-text-muted">
                기본 설정으로 생성됩니다. 상세 설정은 터미널에서 `rclone config`를 실행하세요.
              </p>
              {error && <p className="text-xs text-danger">{error}</p>}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="flex items-center justify-end gap-2 px-5 py-3 border-t border-border">
          {step === 'create' && (
            <button
              onClick={() => { setSelectedProvider(null); setStep('list'); setError(''); }}
              className="px-4 py-2 text-xs text-text-muted hover:text-text"
            >
              뒤로
            </button>
          )}
          {step === 'create' && selectedProvider && (
            <button
              onClick={handleCreate}
              disabled={creating || !remoteName.trim()}
              className="px-4 py-2 text-xs rounded bg-accent hover:bg-accent-hover text-white disabled:opacity-50 transition-colors"
            >
              {creating ? '생성 중...' : '생성'}
            </button>
          )}
          {step === 'list' && (
            <button
              onClick={onClose}
              className="px-4 py-2 text-xs text-text-muted hover:text-text"
            >
              닫기
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
