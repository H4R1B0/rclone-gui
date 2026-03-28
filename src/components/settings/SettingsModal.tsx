import { useState, useEffect } from 'react';
import { X, RotateCcw } from 'lucide-react';
import { useSettingsStore, defaultSettings, type RcloneSettings } from '../../stores/settingsStore';

interface SettingsModalProps {
  onClose: () => void;
}

interface FieldDef {
  key: keyof RcloneSettings;
  label: string;
  desc: string;
  type: 'number' | 'text' | 'bool';
  placeholder?: string;
  cliFlag: string;
}

const fields: FieldDef[] = [
  // Performance
  { key: 'transfers', label: '동시 전송 수', desc: '동시에 전송할 파일 수', type: 'number', cliFlag: '--transfers' },
  { key: 'checkers', label: '동시 체커 수', desc: '동시에 체크할 파일 수', type: 'number', cliFlag: '--checkers' },
  { key: 'multiThreadStreams', label: '멀티스레드 스트림', desc: '파일당 동시 다운로드 스레드 수', type: 'number', cliFlag: '--multi-thread-streams' },
  { key: 'bufferSize', label: '버퍼 크기', desc: '각 파일 전송에 사용할 메모리 버퍼', type: 'text', placeholder: '16M', cliFlag: '--buffer-size' },
  { key: 'bwLimit', label: '대역폭 제한', desc: '비워두면 무제한. 예: 10M, 1G', type: 'text', placeholder: '무제한', cliFlag: '--bwlimit' },

  // Reliability
  { key: 'retries', label: '재시도 횟수', desc: '실패 시 재시도 횟수', type: 'number', cliFlag: '--retries' },
  { key: 'lowLevelRetries', label: '하위 재시도', desc: '저수준 연결 재시도 횟수', type: 'number', cliFlag: '--low-level-retries' },
  { key: 'contimeout', label: '연결 타임아웃', desc: '서버 연결 제한 시간', type: 'text', placeholder: '60s', cliFlag: '--contimeout' },
  { key: 'timeout', label: 'IO 타임아웃', desc: 'IO 작업 제한 시간', type: 'text', placeholder: '300s', cliFlag: '--timeout' },

  // Behavior
  { key: 'userAgent', label: 'User-Agent', desc: '사용자 에이전트 문자열 (비워두면 기본값)', type: 'text', placeholder: 'rclone/vX.X', cliFlag: '--user-agent' },
  { key: 'noCheckCertificate', label: 'SSL 인증서 검증 무시', desc: 'HTTPS 인증서 검증을 건너뜁니다', type: 'bool', cliFlag: '--no-check-certificate' },
  { key: 'ignoreExisting', label: '기존 파일 무시', desc: '이미 존재하는 파일은 건너뜁니다', type: 'bool', cliFlag: '--ignore-existing' },
  { key: 'ignoreSize', label: '크기 무시', desc: '파일 크기를 무시하고 전송', type: 'bool', cliFlag: '--ignore-size' },
  { key: 'noTraverse', label: '디렉터리 탐색 안함', desc: '대상 디렉터리 탐색 건너뛰기', type: 'bool', cliFlag: '--no-traverse' },
  { key: 'noUpdateModTime', label: '수정 시간 유지 안함', desc: '전송 후 수정 시간을 업데이트하지 않음', type: 'bool', cliFlag: '--no-update-modtime' },
];

export function SettingsModal({ onClose }: SettingsModalProps) {
  const { settings, setSettings, resetSettings } = useSettingsStore();
  const [local, setLocal] = useState<RcloneSettings>({ ...settings });
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');

  useEffect(() => {
    // Load saved settings on mount
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
      // Build rclone options object
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

      if (local.contimeout) {
        opts.ConnectTimeout = parseDuration(local.contimeout);
      }
      if (local.timeout) {
        opts.Timeout = parseDuration(local.timeout);
      }
      if (local.userAgent) {
        opts.UserAgent = local.userAgent;
      }

      await window.rcloneAPI.applyOptions(opts);

      // Apply bwlimit separately
      if (local.bwLimit) {
        await window.rcloneAPI.setBwLimit(local.bwLimit);
      } else {
        await window.rcloneAPI.setBwLimit('off');
      }

      // Save to disk & store
      setSettings(local);
      await window.rcloneAPI.saveSettings(local as unknown as Record<string, unknown>);
      setMessage('설정이 적용되었습니다');
    } catch (err) {
      setMessage(`오류: ${err instanceof Error ? err.message : String(err)}`);
    } finally {
      setSaving(false);
    }
  };

  const handleReset = () => {
    setLocal({ ...defaultSettings });
    resetSettings();
    setMessage('');
  };

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50">
      <div className="bg-surface-raised border border-border rounded-xl shadow-2xl w-[560px] max-h-[85vh] flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-border flex-shrink-0">
          <h2 className="text-sm font-semibold text-text">rclone 설정</h2>
          <button onClick={onClose} className="text-text-muted hover:text-text">
            <X size={18} />
          </button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto p-5 space-y-5">
          {/* Performance section */}
          <Section title="성능">
            {fields.filter((f) => ['transfers', 'checkers', 'multiThreadStreams', 'bufferSize', 'bwLimit'].includes(f.key)).map((f) => (
              <Field key={f.key} field={f} value={local[f.key]} onChange={(v) => updateField(f.key, v)} />
            ))}
          </Section>

          {/* Reliability section */}
          <Section title="안정성">
            {fields.filter((f) => ['retries', 'lowLevelRetries', 'contimeout', 'timeout'].includes(f.key)).map((f) => (
              <Field key={f.key} field={f} value={local[f.key]} onChange={(v) => updateField(f.key, v)} />
            ))}
          </Section>

          {/* Behavior section */}
          <Section title="동작">
            {fields.filter((f) => ['userAgent', 'noCheckCertificate', 'ignoreExisting', 'ignoreSize', 'noTraverse', 'noUpdateModTime'].includes(f.key)).map((f) => (
              <Field key={f.key} field={f} value={local[f.key]} onChange={(v) => updateField(f.key, v)} />
            ))}
          </Section>
        </div>

        {/* Footer */}
        <div className="flex items-center justify-between px-5 py-3 border-t border-border flex-shrink-0">
          <button
            onClick={handleReset}
            className="flex items-center gap-1.5 px-3 py-1.5 text-xs text-text-muted hover:text-text"
          >
            <RotateCcw size={12} />
            기본값 복원
          </button>
          <div className="flex items-center gap-3">
            {message && (
              <span className={`text-xs ${message.startsWith('오류') ? 'text-danger' : 'text-success'}`}>
                {message}
              </span>
            )}
            <button
              onClick={onClose}
              className="px-4 py-1.5 text-xs text-text-muted hover:text-text"
            >
              닫기
            </button>
            <button
              onClick={handleApply}
              disabled={saving}
              className="px-4 py-1.5 text-xs rounded bg-accent hover:bg-accent-hover text-white disabled:opacity-50 transition-colors"
            >
              {saving ? '적용 중...' : '적용'}
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

function Field({ field, value, onChange }: { field: FieldDef; value: unknown; onChange: (v: unknown) => void }) {
  if (field.type === 'bool') {
    return (
      <label className="flex items-center justify-between py-1.5 cursor-pointer group">
        <div>
          <div className="text-xs text-text group-hover:text-accent transition-colors">{field.label}</div>
          <div className="text-[10px] text-text-muted">{field.desc} <code className="text-accent/60">{field.cliFlag}</code></div>
        </div>
        <input
          type="checkbox"
          checked={value as boolean}
          onChange={(e) => onChange(e.target.checked)}
          className="w-4 h-4 rounded accent-accent"
        />
      </label>
    );
  }

  return (
    <div className="space-y-1">
      <div className="flex items-baseline justify-between">
        <label className="text-xs text-text">{field.label}</label>
        <code className="text-[10px] text-accent/60">{field.cliFlag}</code>
      </div>
      <input
        type={field.type === 'number' ? 'number' : 'text'}
        className="w-full px-3 py-1.5 rounded bg-surface-overlay border border-border focus:border-accent text-xs text-text outline-none"
        value={String(value ?? '')}
        placeholder={field.placeholder ?? String(defaultSettings[field.key])}
        min={field.type === 'number' ? 1 : undefined}
        onChange={(e) => {
          onChange(field.type === 'number' ? Number(e.target.value) || 0 : e.target.value);
        }}
      />
      <div className="text-[10px] text-text-muted">{field.desc}</div>
    </div>
  );
}

// Parse "16M" → bytes for rclone SizeSuffix
function parseSizeToBits(s: string): number {
  const match = s.match(/^(\d+(?:\.\d+)?)\s*([KMGTP]?)i?$/i);
  if (!match) return 16 * 1024 * 1024;
  const num = parseFloat(match[1]);
  const unit = (match[2] || '').toUpperCase();
  const multipliers: Record<string, number> = { '': 1, K: 1024, M: 1024 ** 2, G: 1024 ** 3, T: 1024 ** 4, P: 1024 ** 5 };
  return num * (multipliers[unit] ?? 1);
}

// Parse "60s" → nanoseconds for rclone Duration
function parseDuration(s: string): number {
  const match = s.match(/^(\d+(?:\.\d+)?)\s*([smhd]?)$/i);
  if (!match) return 60e9;
  const num = parseFloat(match[1]);
  const unit = match[2].toLowerCase();
  const multipliers: Record<string, number> = { '': 1e9, s: 1e9, m: 60e9, h: 3600e9, d: 86400e9 };
  return num * (multipliers[unit] ?? 1e9);
}
