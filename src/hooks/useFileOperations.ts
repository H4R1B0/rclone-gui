import { useCallback } from 'react';
import { usePanelStore } from '../stores/panelStore';
import { useClipboardStore } from '../stores/clipboardStore';
import { usePanelFiles } from './useRclone';

const api = () => window.rcloneAPI;

export function useFileOperations(side: 'left' | 'right') {
  const panel = usePanelStore((s) => s[side]);
  const { refresh } = usePanelFiles(side);

  const createFolder = useCallback(async (name: string) => {
    const remotePath = panel.path ? `${panel.path}/${name}` : name;
    await api().mkdir(panel.remote, remotePath);
    await refresh();
  }, [panel.remote, panel.path, refresh]);

  const deleteSelected = useCallback(async () => {
    const selected = Array.from(panel.selectedFiles);
    for (const name of selected) {
      const file = panel.files.find((f) => f.Name === name);
      if (!file) continue;
      const remotePath = panel.path ? `${panel.path}/${name}` : name;
      if (file.IsDir) {
        await api().deleteDir(panel.remote, remotePath);
      } else {
        await api().deleteFile(panel.remote, remotePath);
      }
    }
    usePanelStore.getState().clearSelection(side);
    await refresh();
  }, [side, panel.remote, panel.path, panel.files, panel.selectedFiles, refresh]);

  const rename = useCallback(async (oldName: string, newName: string) => {
    const oldPath = panel.path ? `${panel.path}/${oldName}` : oldName;
    const newPath = panel.path ? `${panel.path}/${newName}` : newName;
    await api().renameFile(panel.remote, oldPath, newPath);
    await refresh();
  }, [panel.remote, panel.path, refresh]);

  const paste = useCallback(async () => {
    const clipboard = useClipboardStore.getState();
    if (!clipboard.action || clipboard.files.length === 0) return;

    const { action, sourceRemote, sourcePath, files } = clipboard;

    for (const file of files) {
      const srcPath = sourcePath ? `${sourcePath}/${file.name}` : file.name;
      const dstPath = panel.path ? `${panel.path}/${file.name}` : file.name;

      if (action === 'cut') {
        if (file.isDir) {
          await api().moveDir(sourceRemote, srcPath, panel.remote, dstPath);
        } else {
          await api().moveFile(sourceRemote, srcPath, panel.remote, dstPath);
        }
      } else {
        if (file.isDir) {
          await api().copyDir(sourceRemote, srcPath, panel.remote, dstPath);
        } else {
          await api().copyFile(sourceRemote, srcPath, panel.remote, dstPath);
        }
      }
    }

    useClipboardStore.getState().clear();
    await refresh();
  }, [panel.remote, panel.path, refresh]);

  const moveToOtherPanel = useCallback(async () => {
    const otherSide = side === 'left' ? 'right' : 'left';
    const other = usePanelStore.getState()[otherSide];
    if (!other.remote) return;

    const selected = Array.from(panel.selectedFiles);
    for (const name of selected) {
      const file = panel.files.find((f) => f.Name === name);
      if (!file) continue;
      const srcPath = panel.path ? `${panel.path}/${name}` : name;
      const dstPath = other.path ? `${other.path}/${name}` : name;
      if (file.IsDir) {
        await api().moveDir(panel.remote, srcPath, other.remote, dstPath);
      } else {
        await api().moveFile(panel.remote, srcPath, other.remote, dstPath);
      }
    }
    usePanelStore.getState().clearSelection(side);
    await refresh();
  }, [side, panel.remote, panel.path, panel.files, panel.selectedFiles, refresh]);

  return { createFolder, deleteSelected, rename, paste, moveToOtherPanel };
}
