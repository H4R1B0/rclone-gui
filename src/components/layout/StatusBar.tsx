import { useEffect, useState } from 'react';
import { useTransferStore } from '../../stores/transferStore';
import { formatSpeed } from '../../lib/utils';
import { useT } from '../../lib/i18n';

export function StatusBar() {
  const { transfers, totalSpeed, errors } = useTransferStore();
  const t = useT();
  const [rcloneInfo, setRcloneInfo] = useState<{ version: string; source: string } | null>(null);

  useEffect(() => {
    window.rcloneAPI.getRcloneVersion().then(setRcloneInfo).catch(() => {});
  }, []);

  return (
    <div className="flex items-center justify-between px-3 py-1 bg-surface-raised border-t border-border text-[11px] text-text-muted">
      <div className="flex items-center gap-4">
        {rcloneInfo && (
          <span>
            rclone v{rcloneInfo.version} ({rcloneInfo.source})
          </span>
        )}
      </div>
      <div className="flex items-center gap-4">
        {transfers.length > 0 && (
          <span className="text-accent">
            {transfers.length}{t('transfer.count')} · {formatSpeed(totalSpeed)}
          </span>
        )}
        {errors > 0 && <span className="text-danger">{errors}{t('transfer.errorCount')}</span>}
      </div>
    </div>
  );
}
