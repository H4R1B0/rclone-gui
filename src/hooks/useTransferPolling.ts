import { useEffect, useRef } from 'react';
import { useTransferStore } from '../stores/transferStore';

export function useTransferPolling(interval = 1000) {
  const { setStats, setPolling } = useTransferStore();
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    setPolling(true);
    const poll = async () => {
      try {
        const stats = await window.rcloneAPI.getStats();
        setStats(stats);
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
  }, [interval, setStats, setPolling]);
}
