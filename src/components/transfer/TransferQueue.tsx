import { useTransferStore } from '../../stores/transferStore';
import { formatBytes, formatSpeed, formatEta } from '../../lib/utils';
import { ArrowDownUp } from 'lucide-react';

export function TransferQueue() {
  const { transfers, totalSpeed } = useTransferStore();

  return (
    <div className="h-[180px] flex-shrink-0 border-t border-border bg-surface-raised flex flex-col">
      <div className="flex items-center justify-between px-3 py-1.5 border-b border-border">
        <span className="text-xs text-text-muted flex items-center gap-1.5">
          <ArrowDownUp size={12} />
          전송 ({transfers.length})
        </span>
        {totalSpeed > 0 && (
          <span className="text-xs text-accent">{formatSpeed(totalSpeed)}</span>
        )}
      </div>
      <div className="flex-1 overflow-y-auto">
        {transfers.length === 0 ? (
          <div className="flex items-center justify-center h-full text-text-muted text-xs">
            전송 대기열이 비어 있습니다
          </div>
        ) : (
          transfers.map((t, i) => (
            <div key={`${t.name}-${i}`} className="px-3 py-2 border-b border-border/50">
              <div className="flex items-center justify-between mb-1">
                <span className="text-xs text-text truncate flex-1 mr-4">{t.name}</span>
                <span className="text-[11px] text-text-muted flex-shrink-0">
                  {formatBytes(t.bytes)} / {formatBytes(t.size)} · {formatSpeed(t.speed)} · {formatEta(t.eta)}
                </span>
              </div>
              <div className="h-1.5 bg-surface-overlay rounded-full overflow-hidden">
                <div
                  className="h-full bg-accent rounded-full transition-all duration-300"
                  style={{ width: `${t.percentage}%` }}
                />
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
