import { useState, useEffect, useMemo } from 'react';
import { X, Loader2, Trash2, Pencil, Search, ChevronLeft, Save, Eye, EyeOff } from 'lucide-react';
import { usePanelStore } from '../../stores/panelStore';
import { ProviderIconSvg } from '../common/ProviderIconSvg';

interface AccountSetupProps {
  onClose: () => void;
}

interface ProviderOptionField {
  Name: string;
  Help: string;
  Default: unknown;
  Required: boolean;
  IsPassword: boolean;
  Advanced: boolean;
  Hide: number;
  Examples?: { Value: string; Help: string }[];
}

interface ProviderDef {
  Name: string;
  Description: string;
  Prefix: string;
  Options?: ProviderOptionField[];
}

type Step = 'list' | 'pick-provider' | 'create' | 'edit';

export function AccountSetup({ onClose }: AccountSetupProps) {
  const [providers, setProviders] = useState<ProviderDef[]>([]);
  const [loading, setLoading] = useState(true);
  const [step, setStep] = useState<Step>('list');
  const [selectedProvider, setSelectedProvider] = useState<ProviderDef | null>(null);
  const [remoteName, setRemoteName] = useState('');
  const [createParams, setCreateParams] = useState<Record<string, string>>({});
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [showAdvanced, setShowAdvanced] = useState(false);

  // For edit mode
  const [editingRemote, setEditingRemote] = useState<string | null>(null);
  const [editName, setEditName] = useState('');
  const [editConfig, setEditConfig] = useState<Record<string, string>>({});
  const [editType, setEditType] = useState('');

  const remotes = usePanelStore((s) => s.remotes);

  useEffect(() => {
    window.rcloneAPI.getProviders().then((p) => {
      setProviders(p as ProviderDef[]);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, []);

  const filteredProviders = useMemo(() => {
    if (!search.trim()) return providers;
    const q = search.toLowerCase();
    return providers.filter(
      (p) => p.Name.toLowerCase().includes(q) || p.Description.toLowerCase().includes(q) || p.Prefix.toLowerCase().includes(q),
    );
  }, [providers, search]);

  // Get important fields for the selected provider
  const providerFields = useMemo(() => {
    if (!selectedProvider?.Options) return [];
    return selectedProvider.Options.filter((o) => {
      if (o.Hide > 0) return false;
      if (showAdvanced) return true;
      // Show required, non-advanced, and common auth fields
      if (o.Required) return true;
      if (!o.Advanced) return true;
      return false;
    });
  }, [selectedProvider, showAdvanced]);

  const hasAdvancedFields = useMemo(() => {
    return (selectedProvider?.Options ?? []).some((o) => o.Advanced && o.Hide === 0);
  }, [selectedProvider]);

  const handleCreate = async () => {
    if (!remoteName.trim() || !selectedProvider) return;
    setSaving(true);
    setError('');
    try {
      // Filter out empty values
      const params: Record<string, string> = {};
      for (const [k, v] of Object.entries(createParams)) {
        if (v.trim()) params[k] = v.trim();
      }
      await window.rcloneAPI.createRemote(remoteName.trim(), selectedProvider.Prefix, params);
      const newRemotes = await window.rcloneAPI.listRemotes();
      usePanelStore.getState().setRemotes(newRemotes);
      goBack();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create remote');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (name: string) => {
    if (!confirm(`"${name}" 계정을 삭제하시겠습니까?`)) return;
    try {
      await window.rcloneAPI.deleteRemote(name);
      const newRemotes = await window.rcloneAPI.listRemotes();
      usePanelStore.getState().setRemotes(newRemotes);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete remote');
    }
  };

  const startEdit = async (name: string) => {
    setError('');
    try {
      const config = await window.rcloneAPI.getRemoteConfig(name) as Record<string, string>;
      setEditingRemote(name);
      setEditName(name);
      setEditType(config.type ?? '');
      const { type: _type, ...rest } = config;
      setEditConfig(rest);
      setStep('edit');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load config');
    }
  };

  const handleSaveEdit = async () => {
    if (!editingRemote || !editName.trim()) return;
    setSaving(true);
    setError('');
    try {
      await window.rcloneAPI.deleteRemote(editingRemote);
      await window.rcloneAPI.createRemote(editName.trim(), editType, editConfig);
      const newRemotes = await window.rcloneAPI.listRemotes();
      usePanelStore.getState().setRemotes(newRemotes);
      goBack();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save config');
    } finally {
      setSaving(false);
    }
  };

  const selectProvider = (p: ProviderDef) => {
    setSelectedProvider(p);
    setCreateParams({});
    setShowAdvanced(false);
    setStep('create');
  };

  const goBack = () => {
    setStep('list');
    setSelectedProvider(null);
    setRemoteName('');
    setCreateParams({});
    setEditingRemote(null);
    setEditName('');
    setEditConfig({});
    setSearch('');
    setError('');
    setShowAdvanced(false);
  };

  const title = (() => {
    switch (step) {
      case 'list': return '클라우드 계정 관리';
      case 'pick-provider': return '서비스 선택';
      case 'create': return `새 계정 — ${selectedProvider?.Name ?? ''}`;
      case 'edit': return `계정 수정 — ${editingRemote ?? ''}`;
    }
  })();

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50">
      <div className="bg-surface-raised border border-border rounded-xl shadow-2xl w-[640px] max-h-[85vh] flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-border flex-shrink-0">
          <div className="flex items-center gap-2">
            {step !== 'list' && (
              <button onClick={goBack} className="text-text-muted hover:text-text">
                <ChevronLeft size={18} />
              </button>
            )}
            <h2 className="text-sm font-semibold text-text">{title}</h2>
          </div>
          <button onClick={onClose} className="text-text-muted hover:text-text">
            <X size={18} />
          </button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto p-5">
          {/* ---- LIST ---- */}
          {step === 'list' && (
            <div className="space-y-4">
              {remotes.length > 0 ? (
                <div className="space-y-1">
                  {remotes.map((name) => (
                    <RemoteRow key={name} name={name} providers={providers} onEdit={() => startEdit(name)} onDelete={() => handleDelete(name)} />
                  ))}
                </div>
              ) : (
                <div className="text-center py-8 text-text-muted text-sm">등록된 계정이 없습니다</div>
              )}
              {error && <p className="text-xs text-danger">{error}</p>}
              <button onClick={() => setStep('pick-provider')} className="w-full py-2.5 rounded-lg bg-accent hover:bg-accent-hover text-white text-sm transition-colors">
                + 새 클라우드 추가
              </button>
            </div>
          )}

          {/* ---- PICK PROVIDER ---- */}
          {step === 'pick-provider' && (
            <div className="space-y-3">
              <div className="relative">
                <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-text-muted" />
                <input
                  autoFocus
                  className="w-full pl-9 pr-3 py-2 rounded-lg bg-surface-overlay border border-border focus:border-accent text-xs text-text outline-none"
                  placeholder="서비스 검색..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                />
              </div>
              {loading ? (
                <div className="flex justify-center py-8"><Loader2 className="animate-spin text-accent" size={24} /></div>
              ) : filteredProviders.length === 0 ? (
                <div className="text-center py-8 text-text-muted text-sm">일치하는 서비스가 없습니다</div>
              ) : (
                <div className="grid grid-cols-2 gap-1.5 max-h-[50vh] overflow-y-auto">
                  {filteredProviders.map((p) => (
                    <button
                      key={p.Prefix}
                      onClick={() => selectProvider(p)}
                      className="flex items-center gap-3 px-3 py-2.5 rounded-lg bg-surface-overlay hover:bg-border border border-transparent hover:border-accent/30 text-left transition-colors"
                    >
                      <ProviderIconSvg prefix={p.Prefix} size={20} className="flex-shrink-0" />
                      <div className="min-w-0">
                        <div className="text-xs text-text font-medium truncate">{p.Name}</div>
                        <div className="text-[10px] text-text-muted truncate">{p.Description}</div>
                      </div>
                    </button>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* ---- CREATE ---- */}
          {step === 'create' && selectedProvider && (
            <div className="space-y-4">
              <ProviderHeader provider={selectedProvider} />

              <div>
                <label className="text-xs text-text block mb-1">
                  리모트 이름 <span className="text-danger">*</span>
                </label>
                <input
                  autoFocus
                  className="w-full px-3 py-2 rounded bg-surface-overlay border border-border focus:border-accent text-sm text-text outline-none"
                  placeholder="예: my-pikpak"
                  value={remoteName}
                  onChange={(e) => setRemoteName(e.target.value)}
                />
                <p className="text-[10px] text-text-muted mt-1">rclone에서 이 계정을 식별하는 이름</p>
              </div>

              {/* Provider-specific fields */}
              {providerFields.length > 0 && (
                <div className="space-y-3">
                  {providerFields.map((field) => (
                    <OptionField
                      key={field.Name}
                      field={field}
                      value={createParams[field.Name] ?? ''}
                      onChange={(v) => setCreateParams((prev) => ({ ...prev, [field.Name]: v }))}
                    />
                  ))}
                </div>
              )}

              {hasAdvancedFields && (
                <button
                  onClick={() => setShowAdvanced((v) => !v)}
                  className="text-xs text-accent hover:text-accent-hover"
                >
                  {showAdvanced ? '- 고급 설정 숨기기' : '+ 고급 설정 보기'}
                </button>
              )}

              {error && <p className="text-xs text-danger">{error}</p>}
            </div>
          )}

          {/* ---- EDIT ---- */}
          {step === 'edit' && editingRemote && (
            <div className="space-y-4">
              <div className="flex items-center gap-3 px-3 py-2 rounded bg-surface-overlay">
                <ProviderIconSvg prefix={editType} size={22} />
                <div className="text-[10px] text-text-muted">타입: {editType}</div>
              </div>

              <div>
                <label className="text-xs text-text block mb-1">리모트 이름</label>
                <input
                  className="w-full px-3 py-1.5 rounded bg-surface-overlay border border-border focus:border-accent text-sm text-text outline-none"
                  value={editName}
                  onChange={(e) => setEditName(e.target.value)}
                />
              </div>

              <div className="space-y-3">
                {Object.entries(editConfig).map(([key, value]) => {
                  // Find field definition to check if it's a password
                  const provDef = providers.find((p) => p.Prefix === editType);
                  const fieldDef = provDef?.Options?.find((o) => o.Name === key);
                  const isPassword = fieldDef?.IsPassword ?? false;
                  return (
                    <EditField
                      key={key}
                      name={key}
                      value={value}
                      help={fieldDef?.Help}
                      isPassword={isPassword}
                      onChange={(v) => setEditConfig((prev) => ({ ...prev, [key]: v }))}
                    />
                  );
                })}

                {Object.keys(editConfig).length === 0 && (
                  <div className="text-xs text-text-muted text-center py-4">설정 항목이 없습니다 (기본값 사용 중)</div>
                )}

                <AddConfigField onAdd={(key, val) => setEditConfig((prev) => ({ ...prev, [key]: val }))} />
              </div>

              {error && <p className="text-xs text-danger">{error}</p>}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="flex items-center justify-end gap-2 px-5 py-3 border-t border-border flex-shrink-0">
          {step === 'create' && (
            <button
              onClick={handleCreate}
              disabled={saving || !remoteName.trim()}
              className="flex items-center gap-1.5 px-4 py-2 text-xs rounded bg-accent hover:bg-accent-hover text-white disabled:opacity-50 transition-colors"
            >
              {saving ? <Loader2 size={12} className="animate-spin" /> : null}
              {saving ? '연결 중...' : '연결'}
            </button>
          )}
          {step === 'edit' && (
            <button
              onClick={handleSaveEdit}
              disabled={saving || !editName.trim()}
              className="flex items-center gap-1.5 px-4 py-2 text-xs rounded bg-accent hover:bg-accent-hover text-white disabled:opacity-50 transition-colors"
            >
              <Save size={12} />
              {saving ? '저장 중...' : '저장'}
            </button>
          )}
          {step === 'list' && (
            <button onClick={onClose} className="px-4 py-2 text-xs text-text-muted hover:text-text">닫기</button>
          )}
        </div>
      </div>
    </div>
  );
}

// --- Option field for create ---
function OptionField({ field, value, onChange }: { field: ProviderOptionField; value: string; onChange: (v: string) => void }) {
  const [showPassword, setShowPassword] = useState(false);

  // If field has examples as an enum-like list, show a select
  const hasExamples = field.Examples && field.Examples.length > 0 && field.Examples.length <= 20;

  return (
    <div>
      <label className="text-xs text-text block mb-1">
        {field.Name}
        {field.Required && <span className="text-danger ml-0.5">*</span>}
        {field.Advanced && <span className="text-text-muted ml-1 text-[10px]">(고급)</span>}
      </label>

      {hasExamples && !field.IsPassword ? (
        <select
          className="w-full px-3 py-1.5 rounded bg-surface-overlay border border-border focus:border-accent text-xs text-text outline-none"
          value={value}
          onChange={(e) => onChange(e.target.value)}
        >
          <option value="">선택...</option>
          {field.Examples!.map((ex) => (
            <option key={ex.Value} value={ex.Value}>
              {ex.Value}{ex.Help ? ` — ${ex.Help}` : ''}
            </option>
          ))}
        </select>
      ) : (
        <div className="relative">
          <input
            type={field.IsPassword && !showPassword ? 'password' : 'text'}
            className="w-full px-3 py-1.5 rounded bg-surface-overlay border border-border focus:border-accent text-xs text-text outline-none font-mono pr-8"
            placeholder={field.Default != null && field.Default !== '' ? String(field.Default) : undefined}
            value={value}
            onChange={(e) => onChange(e.target.value)}
          />
          {field.IsPassword && (
            <button
              type="button"
              onClick={() => setShowPassword((v) => !v)}
              className="absolute right-2 top-1/2 -translate-y-1/2 text-text-muted hover:text-text"
            >
              {showPassword ? <EyeOff size={13} /> : <Eye size={13} />}
            </button>
          )}
        </div>
      )}

      {field.Help && (
        <p className="text-[10px] text-text-muted mt-0.5 line-clamp-2">{field.Help}</p>
      )}
    </div>
  );
}

// --- Edit field with password toggle ---
function EditField({ name, value, help, isPassword, onChange }: { name: string; value: string; help?: string; isPassword: boolean; onChange: (v: string) => void }) {
  const [show, setShow] = useState(false);

  return (
    <div>
      <label className="text-xs text-text-muted block mb-1">{name}</label>
      <div className="relative">
        <input
          type={isPassword && !show ? 'password' : 'text'}
          className="w-full px-3 py-1.5 rounded bg-surface-overlay border border-border focus:border-accent text-xs text-text outline-none font-mono pr-8"
          value={value}
          onChange={(e) => onChange(e.target.value)}
        />
        {isPassword && (
          <button
            type="button"
            onClick={() => setShow((v) => !v)}
            className="absolute right-2 top-1/2 -translate-y-1/2 text-text-muted hover:text-text"
          >
            {show ? <EyeOff size={13} /> : <Eye size={13} />}
          </button>
        )}
      </div>
      {help && <p className="text-[10px] text-text-muted mt-0.5 line-clamp-2">{help}</p>}
    </div>
  );
}

// --- Sub-components ---

function RemoteRow({ name, providers, onEdit, onDelete }: { name: string; providers: ProviderDef[]; onEdit: () => void; onDelete: () => void }) {
  const [type, setType] = useState('');

  useEffect(() => {
    window.rcloneAPI.getRemoteConfig(name).then((cfg) => {
      setType((cfg as Record<string, string>).type ?? '');
    }).catch(() => {});
  }, [name]);

  const providerName = providers.find((p) => p.Prefix === type)?.Name ?? type;

  return (
    <div className="flex items-center gap-3 px-3 py-2.5 rounded-lg bg-surface-overlay group">
      <ProviderIconSvg prefix={type} size={22} className="flex-shrink-0" />
      <div className="flex-1 min-w-0">
        <div className="text-sm text-text truncate">{name}</div>
        <div className="text-[10px] text-text-muted">{providerName}</div>
      </div>
      <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
        <button onClick={onEdit} className="p-1.5 rounded hover:bg-border text-text-muted hover:text-accent transition-colors" title="수정">
          <Pencil size={13} />
        </button>
        <button onClick={onDelete} className="p-1.5 rounded hover:bg-border text-text-muted hover:text-danger transition-colors" title="삭제">
          <Trash2 size={13} />
        </button>
      </div>
    </div>
  );
}

function ProviderHeader({ provider }: { provider: ProviderDef }) {
  return (
    <div className="flex items-center gap-3 px-3 py-2 rounded bg-surface-overlay">
      <ProviderIconSvg prefix={provider.Prefix} size={24} />
      <div>
        <div className="text-sm text-text font-medium">{provider.Name}</div>
        <div className="text-[10px] text-text-muted">{provider.Description}</div>
      </div>
    </div>
  );
}

function AddConfigField({ onAdd }: { onAdd: (key: string, val: string) => void }) {
  const [open, setOpen] = useState(false);
  const [key, setKey] = useState('');
  const [val, setVal] = useState('');

  const submit = () => {
    if (key.trim()) { onAdd(key.trim(), val); setKey(''); setVal(''); setOpen(false); }
  };

  if (!open) {
    return <button onClick={() => setOpen(true)} className="text-xs text-accent hover:text-accent-hover">+ 설정 항목 추가</button>;
  }

  return (
    <div className="flex items-end gap-2">
      <div className="flex-1">
        <label className="text-[10px] text-text-muted block mb-0.5">키</label>
        <input autoFocus className="w-full px-2 py-1 rounded bg-surface-overlay border border-border focus:border-accent text-xs text-text outline-none font-mono" placeholder="token" value={key} onChange={(e) => setKey(e.target.value)} />
      </div>
      <div className="flex-1">
        <label className="text-[10px] text-text-muted block mb-0.5">값</label>
        <input className="w-full px-2 py-1 rounded bg-surface-overlay border border-border focus:border-accent text-xs text-text outline-none font-mono" value={val} onChange={(e) => setVal(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && submit()} />
      </div>
      <button onClick={submit} className="px-2 py-1 text-xs rounded bg-accent text-white hover:bg-accent-hover">추가</button>
      <button onClick={() => setOpen(false)} className="px-2 py-1 text-xs text-text-muted hover:text-text">취소</button>
    </div>
  );
}
