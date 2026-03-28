import { useCallback } from 'react';
import { usePanelStore } from '../stores/panelStore';

const api = () => window.rcloneAPI;

export function useRclone() {
  const { setRemotes, setRemotesLoading } = usePanelStore();

  const loadRemotes = useCallback(async () => {
    setRemotesLoading(true);
    try {
      const remotes = await api().listRemotes();
      setRemotes(remotes);
    } catch (err) {
      console.error('Failed to load remotes:', err);
    } finally {
      setRemotesLoading(false);
    }
  }, [setRemotes, setRemotesLoading]);

  return { loadRemotes };
}

export function usePanelFiles(side: 'left' | 'right') {
  const { setFiles, setLoading, setError, setPath } = usePanelStore();
  const panel = usePanelStore((s) => s[side]);

  const loadFiles = useCallback(async (remote?: string, path?: string) => {
    const r = remote ?? panel.remote;
    const p = path ?? panel.path;
    if (!r) return;
    setLoading(side, true);
    try {
      const files = await api().listFiles(r, p);
      setFiles(side, files);
      if (path !== undefined) setPath(side, p);
    } catch (err) {
      setError(side, err instanceof Error ? err.message : 'Failed to list files');
    }
  }, [side, panel.remote, panel.path, setFiles, setLoading, setError, setPath]);

  const navigate = useCallback(async (dirName: string) => {
    const newPath = panel.path ? `${panel.path}/${dirName}` : dirName;
    await loadFiles(undefined, newPath);
  }, [panel.path, loadFiles]);

  const goUp = useCallback(async () => {
    const parts = panel.path.split('/').filter(Boolean);
    parts.pop();
    await loadFiles(undefined, parts.join('/'));
  }, [panel.path, loadFiles]);

  const refresh = useCallback(() => loadFiles(), [loadFiles]);

  return { loadFiles, navigate, goUp, refresh };
}
