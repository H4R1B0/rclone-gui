import { useState, useCallback, useEffect, useRef } from 'react';
import { useTransferStore, type TransferItem, type StoppedTransfer } from '../../stores/transferStore';
import { formatBytes, formatSpeed, formatEta } from '../../lib/utils';
import {
  ArrowDownUp, Pause, Play, XCircle, Trash2, CheckCircle2, AlertCircle,
  RotateCcw, StopCircle,
} from 'lucide-react';
import type { LucideIcon } from 'lucide-react';

type Tab = 'active' | 'completed' | 'errors';

export function TransferQueue() {
  const {
    transfers, completed, stopped, jobIds, totalSpeed, totalTransfers, doneTransfers,
    paused, setPaused, clearCompleted, clearStopped, addStopped, removeStopped,
  } = useTransferStore();
  const [tab, setTab] = useState<Tab>('active');
  const [selectedIdx, setSelectedIdx] = useState<number | null>(null);
  const [ctxPos, setCtxPos] = useState<{ x: number; y: number } | null>(null);
  const ctxRef = useRef<HTMLDivElement>(null);

  const errorList = completed.filter((c) => !c.ok);
  const successList = completed.filter((c) => c.ok);
  const activeCount = transfers.length + stopped.length;

  // Close context menu on outside click
  useEffect(() => {
    if (!ctxPos) return;
    const handler = (e: MouseEvent) => {
      if (ctxRef.current && !ctxRef.current.contains(e.target as Node)) {
        setCtxPos(null);
      }
    };
    // Use timeout so the current mousedown that opened the menu doesn't immediately close it
    const id = setTimeout(() => document.addEventListener('mousedown', handler), 0);
    return () => { clearTimeout(id); document.removeEventListener('mousedown', handler); };
  }, [ctxPos]);

  const togglePause = useCallback(async () => {
    try {
      if (paused) { await window.rcloneAPI.setBwLimit('off'); setPaused(false); }
      else { await window.rcloneAPI.setBwLimit('1'); setPaused(true); }
    } catch { /* */ }
  }, [paused, setPaused]);

  const stopAllJobs = useCallback(async () => {
    for (const t of transfers) {
      addStopped({ name: t.name, group: t.group, size: t.size });
    }
    for (const id of jobIds) {
      try { await window.rcloneAPI.stopJob(id); } catch { /* */ }
    }
  }, [jobIds, transfers, addStopped]);

  const stopSingleJob = useCallback(async (transfer: TransferItem) => {
    addStopped({ name: transfer.name, group: transfer.group, size: transfer.size });

    // rclone group format is typically "job/<jobid>" — extract jobid
    const jobIdMatch = transfer.group.match(/^job\/(\d+)$/);
    if (jobIdMatch) {
      const targetId = parseInt(jobIdMatch[1], 10);
      try { await window.rcloneAPI.stopJob(targetId); } catch { /* */ }
      return;
    }

    // Fallback: match group via job/status
    for (const id of jobIds) {
      try {
        const status = await window.rcloneAPI.getJobStatus(id);
        if (status.group === transfer.group) {
          await window.rcloneAPI.stopJob(id);
          return;
        }
      } catch { /* */ }
    }
  }, [jobIds, addStopped]);

  const restartTransfer = useCallback(async (item: StoppedTransfer) => {
    removeStopped(item.group);
    try {
      await window.rcloneAPI.copyDir(
        item.group.split(':')[0] + ':',
        '', item.group, '',
      );
    } catch {
      console.warn('Could not restart transfer:', item.group);
    }
  }, [removeStopped]);

  const clearHistory = useCallback(() => {
    clearCompleted();
    clearStopped();
  }, [clearCompleted, clearStopped]);

  // --- Click & context menu ---
  const handleRowClick = useCallback((index: number) => {
    setSelectedIdx(index);
    setCtxPos(null);
  }, []);

  const handleContextMenu = useCallback((e: React.MouseEvent, index: number) => {
    e.preventDefault();
    setSelectedIdx(index);
    setCtxPos({ x: e.clientX, y: e.clientY });
  }, []);

  const closeCtx = useCallback(() => setCtxPos(null), []);

  // --- Context menu actions based on current tab + selected index ---
  const ctxActions = useCallback(() => {
    if (selectedIdx === null) return null;
    if (tab === 'active') {
      if (selectedIdx < transfers.length) {
        const t = transfers[selectedIdx];
        return { type: 'running' as const, item: t };
      }
      const sIdx = selectedIdx - transfers.length;
      if (sIdx < stopped.length) {
        return { type: 'stopped' as const, item: stopped[sIdx] };
      }
    }
    if (tab === 'completed') return { type: 'completed' as const };
    if (tab === 'errors') return { type: 'errors' as const };
    return null;
  }, [tab, selectedIdx, transfers, stopped]);

  const TabBtn = ({ id, label, count, icon: Icon }: { id: Tab; label: string; count: number; icon: LucideIcon }) => (
    <button
      onClick={() => { setTab(id); setSelectedIdx(null); setCtxPos(null); }}
      className={`flex items-center gap-1 px-2 py-1 text-[11px] rounded transition-colors ${
        tab === id ? 'bg-surface-overlay text-text' : 'text-text-muted hover:text-text'
      }`}
    >
      <Icon size={11} />
      {label}
      {count > 0 && (
        <span className={`ml-0.5 px-1 rounded-full text-[10px] ${
          id === 'errors' ? 'bg-danger/20 text-danger' : id === 'active' ? 'bg-accent/20 text-accent' : 'bg-success/20 text-success'
        }`}>{count}</span>
      )}
    </button>
  );

  const actions = ctxPos ? ctxActions() : null;

  return (
    <div className="h-full bg-surface-raised flex flex-col">
      {/* Header */}
      <div className="flex items-center justify-between px-3 py-1.5 border-b border-border">
        <div className="flex items-center gap-1">
          <TabBtn id="active" label="진행" count={activeCount} icon={ArrowDownUp} />
          <TabBtn id="completed" label="완료" count={successList.length} icon={CheckCircle2} />
          <TabBtn id="errors" label="오류" count={errorList.length} icon={AlertCircle} />
        </div>
        <div className="flex items-center gap-1">
          {totalTransfers > 0 && <span className="text-[11px] text-text-muted mr-2">{doneTransfers}/{totalTransfers}</span>}
          {totalSpeed > 0 && <span className="text-[11px] text-accent mr-2">{formatSpeed(totalSpeed)}</span>}
          <button onClick={togglePause} className={`p-1 rounded transition-colors ${paused ? 'text-warning hover:bg-warning/20' : 'text-text-muted hover:bg-surface-overlay hover:text-text'}`} title={paused ? '전체 재개' : '전체 일시정지'}>
            {paused ? <Play size={14} /> : <Pause size={14} />}
          </button>
          <button onClick={stopAllJobs} className="p-1 rounded text-text-muted hover:bg-surface-overlay hover:text-danger transition-colors" title="전체 중지">
            <XCircle size={14} />
          </button>
          <button onClick={clearHistory} className="p-1 rounded text-text-muted hover:bg-surface-overlay hover:text-text transition-colors" title="완료/중지 이력 삭제">
            <Trash2 size={14} />
          </button>
        </div>
      </div>

      {paused && (
        <div className="px-3 py-1 bg-warning/10 border-b border-warning/30 flex items-center justify-between">
          <span className="text-[11px] text-warning flex items-center gap-1"><Pause size={11} /> 전송이 일시정지되었습니다</span>
          <button onClick={togglePause} className="text-[11px] text-warning hover:text-warning/80 flex items-center gap-1"><Play size={11} /> 재개</button>
        </div>
      )}

      {/* Content */}
      <div className="flex-1 overflow-y-auto min-h-0" onClick={() => { setSelectedIdx(null); setCtxPos(null); }}>
        {/* Active tab */}
        {tab === 'active' && (
          activeCount === 0 ? <Empty text="진행 중인 전송이 없습니다" /> : (
            <>
              {transfers.map((t, i) => (
                <div
                  key={`run-${i}`}
                  className={`px-3 py-2 border-b border-border/50 cursor-pointer transition-colors ${selectedIdx === i ? 'bg-accent-muted' : 'hover:bg-surface-overlay'}`}
                  onClick={(e) => { e.stopPropagation(); handleRowClick(i); }}
                  onContextMenu={(e) => { e.stopPropagation(); handleContextMenu(e, i); }}
                >
                  <div className="flex items-center justify-between mb-1">
                    <span className="text-xs text-text truncate flex-1 mr-2">{t.name}</span>
                    <span className="text-[11px] text-text-muted flex-shrink-0">
                      {formatBytes(t.bytes)} / {formatBytes(t.size)} · {formatSpeed(t.speed)} · {formatEta(t.eta)}
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="flex-1 h-1.5 bg-surface-overlay rounded-full overflow-hidden">
                      <div className={`h-full rounded-full transition-all duration-300 ${paused ? 'bg-warning' : 'bg-accent'}`} style={{ width: `${t.percentage}%` }} />
                    </div>
                    <span className="text-[10px] text-text-muted w-8 text-right">{t.percentage}%</span>
                  </div>
                </div>
              ))}
              {stopped.map((s, i) => {
                const idx = transfers.length + i;
                return (
                  <div
                    key={`stop-${i}`}
                    className={`px-3 py-2 border-b border-border/50 cursor-pointer transition-colors ${selectedIdx === idx ? 'bg-accent-muted' : 'hover:bg-surface-overlay'}`}
                    onClick={(e) => { e.stopPropagation(); handleRowClick(idx); }}
                    onContextMenu={(e) => { e.stopPropagation(); handleContextMenu(e, idx); }}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2 flex-1 min-w-0">
                        <StopCircle size={13} className="text-text-muted flex-shrink-0" />
                        <span className="text-xs text-text-muted truncate">{s.name}</span>
                      </div>
                      <span className="text-[11px] text-text-muted flex-shrink-0">{formatBytes(s.size)} · 중지됨</span>
                    </div>
                  </div>
                );
              })}
            </>
          )
        )}

        {/* Completed tab */}
        {tab === 'completed' && (
          successList.length === 0 ? <Empty text="완료된 전송이 없습니다" /> : (
            successList.map((c, i) => (
              <div
                key={`${c.name}-${i}`}
                className={`flex items-center gap-2 px-3 py-1.5 border-b border-border/50 cursor-pointer transition-colors ${selectedIdx === i ? 'bg-accent-muted' : 'hover:bg-surface-overlay'}`}
                onClick={(e) => { e.stopPropagation(); handleRowClick(i); }}
                onContextMenu={(e) => { e.stopPropagation(); handleContextMenu(e, i); }}
              >
                <CheckCircle2 size={13} className="text-success flex-shrink-0" />
                <span className="text-xs text-text truncate flex-1">{c.name}</span>
                <span className="text-[11px] text-text-muted flex-shrink-0">{formatBytes(c.size)}</span>
              </div>
            ))
          )
        )}

        {/* Errors tab */}
        {tab === 'errors' && (
          errorList.length === 0 ? <Empty text="오류가 없습니다" /> : (
            errorList.map((c, i) => (
              <div
                key={`${c.name}-${i}`}
                className={`px-3 py-1.5 border-b border-border/50 cursor-pointer transition-colors ${selectedIdx === i ? 'bg-accent-muted' : 'hover:bg-surface-overlay'}`}
                onClick={(e) => { e.stopPropagation(); handleRowClick(i); }}
                onContextMenu={(e) => { e.stopPropagation(); handleContextMenu(e, i); }}
              >
                <div className="flex items-center gap-2">
                  <AlertCircle size={13} className="text-danger flex-shrink-0" />
                  <span className="text-xs text-text truncate flex-1">{c.name}</span>
                </div>
                {c.error && <div className="text-[10px] text-danger/80 ml-5 mt-0.5 truncate">{c.error}</div>}
              </div>
            ))
          )
        )}
      </div>

      {/* Context menu */}
      {ctxPos && actions && (
        <div
          ref={ctxRef}
          style={{ position: 'fixed', left: ctxPos.x, top: ctxPos.y, zIndex: 100 }}
          className="bg-surface-raised border border-border rounded-lg shadow-xl py-1 min-w-[160px]"
        >
          {actions.type === 'running' && (
            <CtxItem icon={StopCircle} label="전송 중지" danger onClick={() => { stopSingleJob(actions.item); closeCtx(); }} />
          )}
          {actions.type === 'stopped' && (
            <>
              <CtxItem icon={RotateCcw} label="재시작" onClick={() => { restartTransfer(actions.item); closeCtx(); }} />
              <CtxItem icon={Trash2} label="목록에서 제거" danger onClick={() => { removeStopped(actions.item.group); closeCtx(); }} />
            </>
          )}
          {actions.type === 'completed' && (
            <CtxItem icon={Trash2} label="완료 목록 비우기" onClick={() => { clearCompleted(); closeCtx(); }} />
          )}
          {actions.type === 'errors' && (
            <CtxItem icon={Trash2} label="오류 목록 비우기" onClick={() => { clearCompleted(); closeCtx(); }} />
          )}
        </div>
      )}
    </div>
  );
}

function CtxItem({ icon: Icon, label, onClick, danger }: { icon: LucideIcon; label: string; onClick: () => void; danger?: boolean }) {
  return (
    <button
      className={`flex items-center gap-2 w-full px-3 py-1.5 text-xs text-left hover:bg-surface-overlay transition-colors ${danger ? 'text-danger' : 'text-text'}`}
      onClick={onClick}
    >
      <Icon size={13} />
      {label}
    </button>
  );
}

function Empty({ text }: { text: string }) {
  return <div className="flex items-center justify-center h-full text-text-muted text-xs">{text}</div>;
}
