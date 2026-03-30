import { useEffect, useRef } from 'react';
import { useTransferStore } from '../stores/transferStore';

export function useTransferPolling(interval = 1000) {
  const { setStats, setJobIds, addCompleted, addLastError, setPolling } = useTransferStore();
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const seenRef = useRef<Set<string>>(new Set());
  const lastErrorRef = useRef<string>('');

  useEffect(() => {
    setPolling(true);
    const poll = async () => {
      try {
        const stats = await window.rcloneAPI.getStats();
        setStats(stats);

        // Collect lastError from rclone stats
        if (stats.lastError && stats.lastError !== lastErrorRef.current) {
          lastErrorRef.current = stats.lastError;
          addLastError(stats.lastError);
        }

        try {
          const jobs = await window.rcloneAPI.getJobList();
          setJobIds(jobs.jobids ?? []);
        } catch { /* */ }

        try {
          const result = await window.rcloneAPI.getTransferred();
          const items = result.transferred ?? [];
          const stoppedNames = new Set(
            useTransferStore.getState().stopped.map((s) => s.name),
          );

          const newItems = items
            .filter((t) => {
              const key = `${t.name}-${t.completed_at}`;
              if (seenRef.current.has(key)) return false;
              seenRef.current.add(key);
              // Skip "context canceled" errors for items we manually stopped
              if (t.error && t.error.includes('context canceled') && stoppedNames.has(t.name)) {
                return false;
              }
              return true;
            })
            .map((t) => ({
              name: t.name,
              size: t.size,
              error: t.error ?? '',
              completedAt: t.completed_at,
              ok: !t.error,
              group: t.group ?? '',
            }));
          if (newItems.length > 0) addCompleted(newItems);
        } catch { /* */ }
      } catch { /* */ }
    };
    poll();
    timerRef.current = setInterval(poll, interval);
    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
      setPolling(false);
    };
  }, [interval, setStats, setJobIds, addCompleted, setPolling]);
}
