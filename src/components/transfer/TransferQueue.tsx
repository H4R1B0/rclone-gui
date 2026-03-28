import { useState, useCallback, useEffect, useRef } from 'react';
import { useTransferStore } from '../../stores/transferStore';
import { formatBytes, formatSpeed, formatEta } from '../../lib/utils';
import {
  ArrowDownUp, Pause, Play, XCircle, Trash2, CheckCircle2, AlertCircle,
  RotateCcw, Copy, StopCircle,
} from 'lucide-react';

type Tab = 'active' | 'completed' | 'errors';

interface ContextMenuState {
  x: number;
  y: number;
  tab: Tab;
  index: number;
}

export function TransferQueue() {
  const {
    transfers, completed, jobIds, totalSpeed, totalTransfers, doneTransfers,
    paused, setPaused, clearCompleted,
  } = useTransferStore();
  const [tab, setTab] = useState<Tab>('active');
  const [ctx, setCtx] = useState<ContextMenuState | null>(null);

  const errorList = completed.filter((c) => !c.ok);
  const successList = completed.filter((c) => c.ok);

  const togglePause = useCallback(async () => {
    try {
      if (paused) {
        await window.rcloneAPI.setBwLimit('off');
        setPaused(false);
      } else {
        await window.rcloneAPI.setBwLimit('1');
        setPaused(true);
      }
    } catch (err) {
      console.error('Failed to toggle pause:', err);
    }
  }, [paused, setPaused]);

  const stopAllJobs = useCallback(async () => {
    for (const id of jobIds) {
      try { await window.rcloneAPI.stopJob(id); } catch { /* */ }
    }
  }, [jobIds]);

  const stopJob = useCallback(async (group: string) => {
    for (const id of jobIds) {
      try {
        const status = await window.rcloneAPI.getJobStatus(id);
        if (status.group === group) { await window.rcloneAPI.stopJob(id); return; }
      } catch { /* */ }
    }
  }, [jobIds]);

  const resetStats = useCallback(async () => {
    try { await window.rcloneAPI.resetStats(); clearCompleted(); } catch { /* */ }
  }, [clearCompleted]);

  const copyName = useCallback((name: string) => {
    navigator.clipboard.writeText(name);
  }, []);

  const handleContextMenu = useCallback((e: React.MouseEvent, t: Tab, index: number) => {
    e.preventDefault();
    setCtx({ x: e.clientX, y: e.clientY, tab: t, index });
  }, []);

  const TabBtn = ({ id, label, count, icon: Icon }: { id: Tab; label: string; count: number; icon: typeof ArrowDownUp }) => (
    <button
      onClick={() => setTab(id)}
      className={`flex items-center gap-1 px-2 py-1 text-[11px] rounded transition-colors ${
        tab === id ? 'bg-surface-overlay text-text' : 'text-text-muted hover:text-text'
      }`}
    >
      <Icon size={11} />
      {label}
      {count > 0 && (
        <span className={`ml-0.5 px-1 rounded-full text-[10px] ${
          id === 'errors' ? 'bg-danger/20 text-danger' : id === 'active' ? 'bg-accent/20 text-accent' : 'bg-success/20 text-success'
        }`}>
          {count}
        </span>
      )}
    </button>
  );

  return (
    <div className="h-full bg-surface-raised flex flex-col">
      {/* Header */}
      <div className="flex items-center justify-between px-3 py-1.5 border-b border-border">
        <div className="flex items-center gap-1">
          <TabBtn id="active" label="진행" count={transfers.length} icon={ArrowDownUp} />
          <TabBtn id="completed" label="완료" count={successList.length} icon={CheckCircle2} />
          <TabBtn id="errors" label="오류" count={errorList.length} icon={AlertCircle} />
        </div>
        <div className="flex items-center gap-1">
          {totalTransfers > 0 && (
            <span className="text-[11px] text-text-muted mr-2">{doneTransfers}/{totalTransfers}</span>
          )}
          {totalSpeed > 0 && (
            <span className="text-[11px] text-accent mr-2">{formatSpeed(totalSpeed)}</span>
          )}
          <button onClick={togglePause} className={`p-1 rounded transition-colors ${paused ? 'text-warning hover:bg-warning/20' : 'text-text-muted hover:bg-surface-overlay hover:text-text'}`} title={paused ? '전체 재개' : '전체 일시정지'}>
            {paused ? <Play size={14} /> : <Pause size={14} />}
          </button>
          <button onClick={stopAllJobs} className="p-1 rounded text-text-muted hover:bg-surface-overlay hover:text-danger transition-colors" title="전체 중지">
            <XCircle size={14} />
          </button>
          <button onClick={resetStats} className="p-1 rounded text-text-muted hover:bg-surface-overlay hover:text-text transition-colors" title="이력 초기화">
            <Trash2 size={14} />
          </button>
        </div>
      </div>

      {/* Paused banner */}
      {paused && (
        <div className="px-3 py-1 bg-warning/10 border-b border-warning/30 flex items-center justify-between">
          <span className="text-[11px] text-warning flex items-center gap-1"><Pause size={11} /> 전송이 일시정지되었습니다</span>
          <button onClick={togglePause} className="text-[11px] text-warning hover:text-warning/80 flex items-center gap-1"><Play size={11} /> 재개</button>
        </div>
      )}

      {/* Tab content */}
      <div className="flex-1 overflow-y-auto">
        {tab === 'active' && (
          transfers.length === 0 ? <Empty text="진행 중인 전송이 없습니다" /> : (
            transfers.map((t, i) => (
              <div
                key={`${t.name}-${i}`}
                className="px-3 py-2 border-b border-border/50 group"
                onContextMenu={(e) => handleContextMenu(e, 'active', i)}
              >
                <div className="flex items-center justify-between mb-1">
                  <span className="text-xs text-text truncate flex-1 mr-2">{t.name}</span>
                  <div className="flex items-center gap-2 flex-shrink-0">
                    <span className="text-[11px] text-text-muted">
                      {formatBytes(t.bytes)} / {formatBytes(t.size)} · {formatSpeed(t.speed)} · {formatEta(t.eta)}
                    </span>
                    <button onClick={() => stopJob(t.group)} className="opacity-0 group-hover:opacity-100 p-0.5 rounded text-text-muted hover:text-danger transition-all" title="이 전송 중지">
                      <XCircle size={13} />
                    </button>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <div className="flex-1 h-1.5 bg-surface-overlay rounded-full overflow-hidden">
                    <div className={`h-full rounded-full transition-all duration-300 ${paused ? 'bg-warning' : 'bg-accent'}`} style={{ width: `${t.percentage}%` }} />
                  </div>
                  <span className="text-[10px] text-text-muted w-8 text-right">{t.percentage}%</span>
                </div>
              </div>
            ))
          )
        )}

        {tab === 'completed' && (
          successList.length === 0 ? <Empty text="완료된 전송이 없습니다" /> : (
            successList.map((c, i) => (
              <div
                key={`${c.name}-${i}`}
                className="flex items-center gap-2 px-3 py-1.5 border-b border-border/50"
                onContextMenu={(e) => handleContextMenu(e, 'completed', i)}
              >
                <CheckCircle2 size={13} className="text-success flex-shrink-0" />
                <span className="text-xs text-text truncate flex-1">{c.name}</span>
                <span className="text-[11px] text-text-muted flex-shrink-0">{formatBytes(c.size)}</span>
              </div>
            ))
          )
        )}

        {tab === 'errors' && (
          errorList.length === 0 ? <Empty text="오류가 없습니다" /> : (
            errorList.map((c, i) => (
              <div
                key={`${c.name}-${i}`}
                className="px-3 py-1.5 border-b border-border/50"
                onContextMenu={(e) => handleContextMenu(e, 'errors', i)}
              >
                <div className="flex items-center gap-2">
                  <AlertCircle size={13} className="text-danger flex-shrink-0" />
                  <span className="text-xs text-text truncate flex-1">{c.name}</span>
                  <button className="p-0.5 rounded text-text-muted hover:text-accent transition-colors" title="재시도">
                    <RotateCcw size={12} />
                  </button>
                </div>
                {c.error && <div className="text-[10px] text-danger/80 ml-5 mt-0.5 truncate">{c.error}</div>}
              </div>
            ))
          )
        )}
      </div>

      {/* Context menu */}
      {ctx && (
        <TransferContextMenu
          ctx={ctx}
          transfers={transfers}
          successList={successList}
          errorList={errorList}
          onClose={() => setCtx(null)}
          onStop={stopJob}
          onCopyName={copyName}
          onClearCompleted={clearCompleted}
        />
      )}
    </div>
  );
}

function Empty({ text }: { text: string }) {
  return <div className="flex items-center justify-center h-full text-text-muted text-xs">{text}</div>;
}

// --- Context menu ---
interface TransferContextMenuProps {
  ctx: ContextMenuState;
  transfers: ReturnType<typeof useTransferStore.getState>['transfers'];
  successList: ReturnType<typeof useTransferStore.getState>['completed'];
  errorList: ReturnType<typeof useTransferStore.getState>['completed'];
  onClose: () => void;
  onStop: (group: string) => void;
  onCopyName: (name: string) => void;
  onClearCompleted: () => void;
}

function TransferContextMenu({ ctx, transfers, successList, errorList, onClose, onStop, onCopyName, onClearCompleted }: TransferContextMenuProps) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) onClose();
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, [onClose]);

  const item = (() => {
    if (ctx.tab === 'active') return transfers[ctx.index];
    if (ctx.tab === 'completed') return successList[ctx.index];
    return errorList[ctx.index];
  })();

  if (!item) { onClose(); return null; }

  const name = item.name;

  const MenuItem = ({ icon: Icon, label, onClick, danger }: { icon: typeof Copy; label: string; onClick: () => void; danger?: boolean }) => (
    <button
      className={`flex items-center gap-2 w-full px-3 py-1.5 text-xs text-left hover:bg-surface-overlay transition-colors ${danger ? 'text-danger' : 'text-text'}`}
      onClick={() => { onClick(); onClose(); }}
    >
      <Icon size={13} />
      {label}
    </button>
  );

  return (
    <div
      ref={ref}
      style={{ position: 'fixed', left: ctx.x, top: ctx.y, zIndex: 100 }}
      className="bg-surface-raised border border-border rounded-lg shadow-xl py-1 min-w-[180px]"
    >
      <MenuItem icon={Copy} label="파일명 복사" onClick={() => onCopyName(name)} />

      {ctx.tab === 'active' && 'group' in item && (
        <MenuItem icon={StopCircle} label="이 전송 중지" onClick={() => onStop((item as { group: string }).group)} danger />
      )}

      {ctx.tab === 'completed' && (
        <MenuItem icon={Trash2} label="완료 목록 비우기" onClick={onClearCompleted} />
      )}

      {ctx.tab === 'errors' && (
        <>
          <MenuItem icon={RotateCcw} label="재시도" onClick={() => { /* TODO */ }} />
          <MenuItem icon={Trash2} label="오류 목록 비우기" onClick={onClearCompleted} />
        </>
      )}
    </div>
  );
}
