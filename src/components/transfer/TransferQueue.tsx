import { useState, useCallback } from 'react';
import { useTransferStore } from '../../stores/transferStore';
import { formatBytes, formatSpeed, formatEta } from '../../lib/utils';
import {
  ArrowDownUp, Pause, Play, XCircle, Trash2, CheckCircle2, AlertCircle, RotateCcw,
} from 'lucide-react';

type Tab = 'active' | 'completed' | 'errors';

export function TransferQueue() {
  const {
    transfers, completed, jobIds, totalSpeed, totalTransfers, doneTransfers,
    paused, setPaused, clearCompleted,
  } = useTransferStore();
  const [tab, setTab] = useState<Tab>('active');

  const errorList = completed.filter((c) => !c.ok);
  const successList = completed.filter((c) => c.ok);

  // Pause/resume all by setting bwlimit to 1 byte (effective pause) or off
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
      try {
        await window.rcloneAPI.stopJob(id);
      } catch {
        // job may have already finished
      }
    }
  }, [jobIds]);

  const stopJob = useCallback(async (group: string) => {
    // Find matching job by group. As a fallback, stop all jobs.
    for (const id of jobIds) {
      try {
        const status = await window.rcloneAPI.getJobStatus(id);
        if (status.group === group) {
          await window.rcloneAPI.stopJob(id);
          return;
        }
      } catch {
        // skip
      }
    }
  }, [jobIds]);

  const resetStats = useCallback(async () => {
    try {
      await window.rcloneAPI.resetStats();
      clearCompleted();
    } catch (err) {
      console.error('Failed to reset stats:', err);
    }
  }, [clearCompleted]);

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
    <div className="h-[200px] flex-shrink-0 border-t border-border bg-surface-raised flex flex-col">
      {/* Header */}
      <div className="flex items-center justify-between px-3 py-1.5 border-b border-border">
        <div className="flex items-center gap-1">
          <TabBtn id="active" label="진행" count={transfers.length} icon={ArrowDownUp} />
          <TabBtn id="completed" label="완료" count={successList.length} icon={CheckCircle2} />
          <TabBtn id="errors" label="오류" count={errorList.length} icon={AlertCircle} />
        </div>

        <div className="flex items-center gap-1">
          {/* Progress summary */}
          {totalTransfers > 0 && (
            <span className="text-[11px] text-text-muted mr-2">
              {doneTransfers}/{totalTransfers}
            </span>
          )}
          {totalSpeed > 0 && (
            <span className="text-[11px] text-accent mr-2">{formatSpeed(totalSpeed)}</span>
          )}

          {/* Control buttons */}
          <button
            onClick={togglePause}
            className={`p-1 rounded transition-colors ${
              paused ? 'text-warning hover:bg-warning/20' : 'text-text-muted hover:bg-surface-overlay hover:text-text'
            }`}
            title={paused ? '전체 재개' : '전체 일시정지'}
          >
            {paused ? <Play size={14} /> : <Pause size={14} />}
          </button>
          <button
            onClick={stopAllJobs}
            className="p-1 rounded text-text-muted hover:bg-surface-overlay hover:text-danger transition-colors"
            title="전체 중지"
          >
            <XCircle size={14} />
          </button>
          <button
            onClick={resetStats}
            className="p-1 rounded text-text-muted hover:bg-surface-overlay hover:text-text transition-colors"
            title="이력 초기화"
          >
            <Trash2 size={14} />
          </button>
        </div>
      </div>

      {/* Paused banner */}
      {paused && (
        <div className="px-3 py-1 bg-warning/10 border-b border-warning/30 flex items-center justify-between">
          <span className="text-[11px] text-warning flex items-center gap-1">
            <Pause size={11} /> 전송이 일시정지되었습니다
          </span>
          <button
            onClick={togglePause}
            className="text-[11px] text-warning hover:text-warning/80 flex items-center gap-1"
          >
            <Play size={11} /> 재개
          </button>
        </div>
      )}

      {/* Tab content */}
      <div className="flex-1 overflow-y-auto">
        {tab === 'active' && (
          transfers.length === 0 ? (
            <Empty text="진행 중인 전송이 없습니다" />
          ) : (
            transfers.map((t, i) => (
              <div key={`${t.name}-${i}`} className="px-3 py-2 border-b border-border/50 group">
                <div className="flex items-center justify-between mb-1">
                  <span className="text-xs text-text truncate flex-1 mr-2">{t.name}</span>
                  <div className="flex items-center gap-2 flex-shrink-0">
                    <span className="text-[11px] text-text-muted">
                      {formatBytes(t.bytes)} / {formatBytes(t.size)} · {formatSpeed(t.speed)} · {formatEta(t.eta)}
                    </span>
                    <button
                      onClick={() => stopJob(t.group)}
                      className="opacity-0 group-hover:opacity-100 p-0.5 rounded text-text-muted hover:text-danger transition-all"
                      title="이 전송 중지"
                    >
                      <XCircle size={13} />
                    </button>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <div className="flex-1 h-1.5 bg-surface-overlay rounded-full overflow-hidden">
                    <div
                      className={`h-full rounded-full transition-all duration-300 ${paused ? 'bg-warning' : 'bg-accent'}`}
                      style={{ width: `${t.percentage}%` }}
                    />
                  </div>
                  <span className="text-[10px] text-text-muted w-8 text-right">{t.percentage}%</span>
                </div>
              </div>
            ))
          )
        )}

        {tab === 'completed' && (
          successList.length === 0 ? (
            <Empty text="완료된 전송이 없습니다" />
          ) : (
            successList.map((c, i) => (
              <div key={`${c.name}-${i}`} className="flex items-center gap-2 px-3 py-1.5 border-b border-border/50">
                <CheckCircle2 size={13} className="text-success flex-shrink-0" />
                <span className="text-xs text-text truncate flex-1">{c.name}</span>
                <span className="text-[11px] text-text-muted flex-shrink-0">{formatBytes(c.size)}</span>
              </div>
            ))
          )
        )}

        {tab === 'errors' && (
          errorList.length === 0 ? (
            <Empty text="오류가 없습니다" />
          ) : (
            errorList.map((c, i) => (
              <div key={`${c.name}-${i}`} className="px-3 py-1.5 border-b border-border/50">
                <div className="flex items-center gap-2">
                  <AlertCircle size={13} className="text-danger flex-shrink-0" />
                  <span className="text-xs text-text truncate flex-1">{c.name}</span>
                  <button
                    className="p-0.5 rounded text-text-muted hover:text-accent transition-colors"
                    title="재시도 (복사 다시 시작)"
                  >
                    <RotateCcw size={12} />
                  </button>
                </div>
                {c.error && (
                  <div className="text-[10px] text-danger/80 ml-5 mt-0.5 truncate">{c.error}</div>
                )}
              </div>
            ))
          )
        )}
      </div>
    </div>
  );
}

function Empty({ text }: { text: string }) {
  return (
    <div className="flex items-center justify-center h-full text-text-muted text-xs">
      {text}
    </div>
  );
}
