import { useEffect, useRef } from 'react';
import { useTransferStore } from '../stores/transferStore';

export function useTransferPolling(interval = 1000) {
  const { setStats, setJobIds, addCompleted, setPolling } = useTransferStore();
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const seenRef = useRef<Set<string>>(new Set());

  useEffect(() => {
    setPolling(true);
    const poll = async () => {
      try {
        const stats = await window.rcloneAPI.getStats();
        setStats(stats);

        // Fetch job list
        try {
          const jobs = await window.rcloneAPI.getJobList();
          setJobIds(jobs.jobids ?? []);
        } catch {
          // job/list may not be available
        }

        // Fetch completed transfers
        try {
          const result = await window.rcloneAPI.getTransferred();
          const items = result.transferred ?? [];
          const newItems = items
            .filter((t) => {
              const key = `${t.name}-${t.completed_at}`;
              if (seenRef.current.has(key)) return false;
              seenRef.current.add(key);
              return true;
            })
            .map((t) => ({
              name: t.name,
              size: t.size,
              error: t.error ?? '',
              completedAt: t.completed_at,
              ok: !t.error,
            }));
          if (newItems.length > 0) addCompleted(newItems);
        } catch {
          // core/transferred may not be available
        }
      } catch {
        // daemon might not be ready
      }
    };
    poll();
    timerRef.current = setInterval(poll, interval);
    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
      setPolling(false);
    };
  }, [interval, setStats, setJobIds, addCompleted, setPolling]);
}
