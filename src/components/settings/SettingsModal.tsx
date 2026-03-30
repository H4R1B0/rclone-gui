import { useState, useEffect } from 'react';
import { X, RotateCcw } from 'lucide-react';
import { useSettingsStore, defaultSettings, type RcloneSettings } from '../../stores/settingsStore';
import { useT, useI18n, type Locale } from '../../lib/i18n';

interface SettingsModalProps {
  onClose: () => void;
}

interface FieldDef {
  key: keyof RcloneSettings;
  labelKey: string;
  descKey: string;
  type: 'number' | 'text' | 'bool';
  placeholderKey?: string;
  cliFlag: string;
}

const fields: FieldDef[] = [
  { key: 'transfers', labelKey: 'settings.transfers', descKey: 'settings.transfersDesc', type: 'number', cliFlag: '--transfers' },
  { key: 'checkers', labelKey: 'settings.checkers', descKey: 'settings.checkersDesc', type: 'number', cliFlag: '--checkers' },
  { key: 'multiThreadStreams', labelKey: 'settings.multiThread', descKey: 'settings.multiThreadDesc', type: 'number', cliFlag: '--multi-thread-streams' },
  { key: 'bufferSize', labelKey: 'settings.bufferSize', descKey: 'settings.bufferSizeDesc', type: 'text', placeholderKey: '16M', cliFlag: '--buffer-size' },
  { key: 'bwLimit', labelKey: 'settings.bwLimit', descKey: 'settings.bwLimitDesc', type: 'text', placeholderKey: 'settings.unlimited', cliFlag: '--bwlimit' },
  { key: 'retries', labelKey: 'settings.retries', descKey: 'settings.retriesDesc', type: 'number', cliFlag: '--retries' },
  { key: 'lowLevelRetries', labelKey: 'settings.lowLevelRetries', descKey: 'settings.lowLevelRetriesDesc', type: 'number', cliFlag: '--low-level-retries' },
  { key: 'contimeout', labelKey: 'settings.contimeout', descKey: 'settings.contimeoutDesc', type: 'text', placeholderKey: '60s', cliFlag: '--contimeout' },
  { key: 'timeout', labelKey: 'settings.timeout', descKey: 'settings.timeoutDesc', type: 'text', placeholderKey: '300s', cliFlag: '--timeout' },
  { key: 'userAgent', labelKey: 'settings.userAgent', descKey: 'settings.userAgentDesc', type: 'text', placeholderKey: 'rclone/vX.X', cliFlag: '--user-agent' },
  { key: 'noCheckCertificate', labelKey: 'settings.noCheckCert', descKey: 'settings.noCheckCertDesc', type: 'bool', cliFlag: '--no-check-certificate' },
  { key: 'ignoreExisting', labelKey: 'settings.ignoreExisting', descKey: 'settings.ignoreExistingDesc', type: 'bool', cliFlag: '--ignore-existing' },
  { key: 'ignoreSize', labelKey: 'settings.ignoreSize', descKey: 'settings.ignoreSizeDesc', type: 'bool', cliFlag: '--ignore-size' },
  { key: 'noTraverse', labelKey: 'settings.noTraverse', descKey: 'settings.noTraverseDesc', type: 'bool', cliFlag: '--no-traverse' },
  { key: 'noUpdateModTime', labelKey: 'settings.noUpdateModTime', descKey: 'settings.noUpdateModTimeDesc', type: 'bool', cliFlag: '--no-update-modtime' },
];

export function SettingsModal({ onClose }: SettingsModalProps) {
  const t = useT();
  const currentLocale = useI18n((s) => s.locale);
  const { settings, setSettings, resetSettings } = useSettingsStore();
  const [local, setLocal] = useState<RcloneSettings>({ ...settings });
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');

  useEffect(() => {
    window.rcloneAPI.loadSettings().then((saved) => {
      if (saved) {
        const merged = { ...defaultSettings, ...saved } as RcloneSettings;
        setLocal(merged);
        setSettings(merged);
      }
    });
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  const updateField = (key: keyof RcloneSettings, value: unknown) => {
    setLocal((prev) => ({ ...prev, [key]: value }));
  };

  const handleApply = async () => {
    setSaving(true);
    setMessage('');
    try {
      const opts: Record<string, unknown> = {
        Transfers: local.transfers,
        Checkers: local.checkers,
        MultiThreadStreams: local.multiThreadStreams,
        BufferSize: parseSizeToBits(local.bufferSize),
        Retries: local.retries,
        LowLevelRetries: local.lowLevelRetries,
        NoCheckCertificate: local.noCheckCertificate,
        IgnoreExisting: local.ignoreExisting,
        IgnoreSize: local.ignoreSize,
        NoTraverse: local.noTraverse,
        NoUpdateModTime: local.noUpdateModTime,
      };

      if (local.contimeout) opts.ConnectTimeout = parseDuration(local.contimeout);
      if (local.timeout) opts.Timeout = parseDuration(local.timeout);
      if (local.userAgent) opts.UserAgent = local.userAgent;

      await window.rcloneAPI.applyOptions(opts);

      if (local.bwLimit) {
        await window.rcloneAPI.setBwLimit(local.bwLimit);
      } else {
        await window.rcloneAPI.setBwLimit('off');
      }

      setSettings(local);
      await window.rcloneAPI.saveSettings(local as unknown as Record<string, unknown>);
      setMessage(t('settings.applied'));
    } catch (err) {
      setMessage(`${t('common.error')} ${err instanceof Error ? err.message : String(err)}`);
    } finally {
      setSaving(false);
    }
  };

  const handleReset = () => {
    setLocal({ ...defaultSettings });
    resetSettings();
    setMessage('');
  };

  const handleLanguageChange = async (locale: Locale) => {
    if (locale === currentLocale) return;
    const msg = locale === 'ko'
      ? '언어를 변경하면 앱이 재시작됩니다. 계속하시겠습니까?'
      : 'The app will restart to change the language. Continue?';
    if (!confirm(msg)) return;
    try {
      const saved = await window.rcloneAPI.loadSettings() ?? {};
      await window.rcloneAPI.saveSettings({ ...saved, locale });
      window.rcloneAPI.restartApp();
    } catch (err) {
      console.error('Failed to change language:', err);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50">
      <div className="bg-surface-raised border border-border rounded-xl shadow-2xl w-[560px] max-h-[85vh] flex flex-col">
        <div className="flex items-center justify-between px-5 py-4 border-b border-border flex-shrink-0">
          <h2 className="text-sm font-semibold text-text">{t('settings.title')}</h2>
          <button onClick={onClose} className="text-text-muted hover:text-text">
            <X size={18} />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-5 space-y-5">
          {/* Language */}
          <Section title={t('settings.language')}>
            <div>
              <p className="text-[10px] text-text-muted mb-2">{t('settings.languageDesc')}</p>
              <div className="flex gap-2">
                <button
                  onClick={() => handleLanguageChange('ko')}
                  className={`px-3 py-1.5 text-xs rounded transition-colors ${currentLocale === 'ko' ? 'bg-accent text-white' : 'bg-surface-overlay text-text hover:bg-border'}`}
                >
                  한국어
                </button>
                <button
                  onClick={() => handleLanguageChange('en')}
                  className={`px-3 py-1.5 text-xs rounded transition-colors ${currentLocale === 'en' ? 'bg-accent text-white' : 'bg-surface-overlay text-text hover:bg-border'}`}
                >
                  English
                </button>
              </div>
            </div>
          </Section>

          {/* Performance */}
          <Section title={t('settings.performance')}>
            {fields.filter((f) => ['transfers', 'checkers', 'multiThreadStreams', 'bufferSize', 'bwLimit'].includes(f.key)).map((f) => (
              <Field key={f.key} field={f} value={local[f.key]} onChange={(v) => updateField(f.key, v)} t={t} />
            ))}
          </Section>

          {/* Reliability */}
          <Section title={t('settings.reliability')}>
            {fields.filter((f) => ['retries', 'lowLevelRetries', 'contimeout', 'timeout'].includes(f.key)).map((f) => (
              <Field key={f.key} field={f} value={local[f.key]} onChange={(v) => updateField(f.key, v)} t={t} />
            ))}
          </Section>

          {/* Behavior */}
          <Section title={t('settings.behavior')}>
            {fields.filter((f) => ['userAgent', 'noCheckCertificate', 'ignoreExisting', 'ignoreSize', 'noTraverse', 'noUpdateModTime'].includes(f.key)).map((f) => (
              <Field key={f.key} field={f} value={local[f.key]} onChange={(v) => updateField(f.key, v)} t={t} />
            ))}
          </Section>
        </div>

        <div className="flex items-center justify-between px-5 py-3 border-t border-border flex-shrink-0">
          <button onClick={handleReset} className="flex items-center gap-1.5 px-3 py-1.5 text-xs text-text-muted hover:text-text">
            <RotateCcw size={12} />
            {t('settings.restoreDefaults')}
          </button>
          <div className="flex items-center gap-3">
            {message && (
              <span className={`text-xs ${message.startsWith(t('common.error')) ? 'text-danger' : 'text-success'}`}>
                {message}
              </span>
            )}
            <button onClick={onClose} className="px-4 py-1.5 text-xs text-text-muted hover:text-text">
              {t('common.close')}
            </button>
            <button
              onClick={handleApply}
              disabled={saving}
              className="px-4 py-1.5 text-xs rounded bg-accent hover:bg-accent-hover text-white disabled:opacity-50 transition-colors"
            >
              {saving ? t('settings.applying') : t('settings.apply')}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <h3 className="text-xs font-semibold text-text-muted mb-3 uppercase tracking-wide">{title}</h3>
      <div className="space-y-3">{children}</div>
    </div>
  );
}

function Field({ field, value, onChange, t }: { field: FieldDef; value: unknown; onChange: (v: unknown) => void; t: (key: string) => string }) {
  const label = t(field.labelKey);
  const desc = t(field.descKey);
  const placeholder = field.placeholderKey ? t(field.placeholderKey) : String(defaultSettings[field.key]);

  if (field.type === 'bool') {
    return (
      <label className="flex items-center justify-between py-1.5 cursor-pointer group">
        <div>
          <div className="text-xs text-text group-hover:text-accent transition-colors">{label}</div>
          <div className="text-[10px] text-text-muted">{desc} <code className="text-accent/60">{field.cliFlag}</code></div>
        </div>
        <input type="checkbox" checked={value as boolean} onChange={(e) => onChange(e.target.checked)} className="w-4 h-4 rounded accent-accent" />
      </label>
    );
  }

  return (
    <div className="space-y-1">
      <div className="flex items-baseline justify-between">
        <label className="text-xs text-text">{label}</label>
        <code className="text-[10px] text-accent/60">{field.cliFlag}</code>
      </div>
      <input
        type={field.type === 'number' ? 'number' : 'text'}
        className="w-full px-3 py-1.5 rounded bg-surface-overlay border border-border focus:border-accent text-xs text-text outline-none"
        value={String(value ?? '')}
        placeholder={placeholder}
        min={field.type === 'number' ? 1 : undefined}
        onChange={(e) => onChange(field.type === 'number' ? Number(e.target.value) || 0 : e.target.value)}
      />
      <div className="text-[10px] text-text-muted">{desc}</div>
    </div>
  );
}

function parseSizeToBits(s: string): number {
  const match = s.match(/^(\d+(?:\.\d+)?)\s*([KMGTP]?)i?$/i);
  if (!match) return 16 * 1024 * 1024;
  const num = parseFloat(match[1]);
  const unit = (match[2] || '').toUpperCase();
  const multipliers: Record<string, number> = { '': 1, K: 1024, M: 1024 ** 2, G: 1024 ** 3, T: 1024 ** 4, P: 1024 ** 5 };
  return num * (multipliers[unit] ?? 1);
}

function parseDuration(s: string): number {
  const match = s.match(/^(\d+(?:\.\d+)?)\s*([smhd]?)$/i);
  if (!match) return 60e9;
  const num = parseFloat(match[1]);
  const unit = match[2].toLowerCase();
  const multipliers: Record<string, number> = { '': 1e9, s: 1e9, m: 60e9, h: 3600e9, d: 86400e9 };
  return num * (multipliers[unit] ?? 1e9);
}
