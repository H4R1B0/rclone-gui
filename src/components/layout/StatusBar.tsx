import { useEffect, useState, useRef } from 'react';
import { useTransferStore } from '../../stores/transferStore';
import { formatSpeed } from '../../lib/utils';
import { useT } from '../../lib/i18n';
import { Bell, X } from 'lucide-react';

export function StatusBar() {
  const { transfers, totalSpeed, errors, completed, lastErrors } = useTransferStore();
  const t = useT();
  const [rcloneInfo, setRcloneInfo] = useState<{ version: string; source: string } | null>(null);
  const [showErrors, setShowErrors] = useState(false);
  const popRef = useRef<HTMLDivElement>(null);

  const errorList = completed.filter((c) => !c.ok);

  useEffect(() => {
    window.rcloneAPI.getRcloneVersion().then(setRcloneInfo).catch(() => {});
  }, []);

  // Close popover on outside click
  useEffect(() => {
    if (!showErrors) return;
    const handler = (e: MouseEvent) => {
      if (popRef.current && !popRef.current.contains(e.target as Node)) {
        setShowErrors(false);
      }
    };
    const id = setTimeout(() => document.addEventListener('mousedown', handler), 0);
    return () => { clearTimeout(id); document.removeEventListener('mousedown', handler); };
  }, [showErrors]);

  return (
    <div className="flex items-center justify-between px-3 py-1 bg-surface-raised border-t border-border text-[11px] text-text-muted relative">
      <div className="flex items-center gap-4">
        {rcloneInfo && (
          <span>rclone v{rcloneInfo.version} ({rcloneInfo.source})</span>
        )}
      </div>
      <div className="flex items-center gap-3">
        {transfers.length > 0 && (
          <span className="text-accent">
            {transfers.length}{t('transfer.count')} · {formatSpeed(totalSpeed)}
          </span>
        )}
        {(errors > 0 || errorList.length > 0) && (
          <button
            onClick={() => setShowErrors((v) => !v)}
            className="flex items-center gap-1 text-danger hover:text-danger/80 transition-colors relative"
          >
            <Bell size={12} />
            <span>{Math.max(errors, errorList.length)}{t('transfer.errorCount')}</span>
            <span className="absolute -top-1 -right-1 w-2 h-2 bg-danger rounded-full animate-pulse" />
          </button>
        )}
      </div>

      {/* Error popover */}
      {showErrors && (
        <div
          ref={popRef}
          className="absolute bottom-full right-2 mb-1 w-[400px] max-h-[300px] bg-surface-raised border border-border rounded-lg shadow-2xl flex flex-col z-50"
        >
          <div className="flex items-center justify-between px-3 py-2 border-b border-border">
            <span className="text-xs text-text font-medium flex items-center gap-1.5">
              <Bell size={12} className="text-danger" />
              {t('transfer.errors')} ({errorList.length})
            </span>
            <button onClick={() => setShowErrors(false)} className="text-text-muted hover:text-text">
              <X size={13} />
            </button>
          </div>
          <div className="flex-1 overflow-y-auto">
            {errorList.length === 0 && lastErrors.length === 0 ? (
              <div className="px-3 py-4 text-xs text-text-muted text-center">
                {t('transfer.noErrors')}
              </div>
            ) : (
              <>
                {/* Transfer errors with file names */}
                {errorList.map((e, i) => (
                  <div key={`file-${i}`} className="px-3 py-2 border-b border-border/50">
                    <div className="text-xs text-text truncate">{e.name}</div>
                    {e.error && (
                      <div className="text-[10px] text-danger/80 mt-0.5 break-all">{e.error}</div>
                    )}
                  </div>
                ))}
                {/* rclone lastError logs */}
                {lastErrors.map((err, i) => (
                  <div key={`log-${i}`} className="px-3 py-2 border-b border-border/50">
                    <div className="text-[11px] text-danger/90 break-all">{err}</div>
                  </div>
                ))}
              </>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
