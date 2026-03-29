import { useMemo, useState, useCallback } from 'react';
import { usePanelStore } from '../../stores/panelStore';
import { usePanelFiles } from '../../hooks/useRclone';
import { useFileOperations } from '../../hooks/useFileOperations';
import { FileItem } from './FileItem';
import { ContextMenu } from './ContextMenu';
import { ArrowUp } from 'lucide-react';
import { useT } from '../../lib/i18n';

interface FileListProps {
  side: 'left' | 'right';
}

export function FileList({ side }: FileListProps) {
  const panel = usePanelStore((s) => s[side]);
  const setSort = usePanelStore((s) => s.setSort);
  const toggleSelect = usePanelStore((s) => s.toggleSelect);
  const clearSelection = usePanelStore((s) => s.clearSelection);
  const { navigate, goUp, refresh } = usePanelFiles(side);
  const { createFolder, rename } = useFileOperations(side);
  const t = useT();

  const [contextMenu, setContextMenu] = useState<{ x: number; y: number; file: RcloneFile } | null>(null);
  const [renamingFile, setRenamingFile] = useState<string | null>(null);
  const [newFolderMode, setNewFolderMode] = useState(false);
  const [dragOver, setDragOver] = useState(false);

  const sorted = useMemo(() => {
    const files = [...panel.files];
    files.sort((a, b) => {
      if (a.IsDir !== b.IsDir) return a.IsDir ? -1 : 1;
      let cmp = 0;
      switch (panel.sortBy) {
        case 'name': cmp = a.Name.localeCompare(b.Name); break;
        case 'size': cmp = a.Size - b.Size; break;
        case 'date': cmp = new Date(a.ModTime).getTime() - new Date(b.ModTime).getTime(); break;
      }
      return panel.sortAsc ? cmp : -cmp;
    });
    return files;
  }, [panel.files, panel.sortBy, panel.sortAsc]);

  const handleContextMenu = useCallback((e: React.MouseEvent, file: RcloneFile) => {
    e.preventDefault();
    setContextMenu({ x: e.clientX, y: e.clientY, file });
  }, []);

  const handleClick = useCallback((file: RcloneFile, e: React.MouseEvent) => {
    if (file.IsDir) {
      navigate(file.Name);
    } else {
      if (e.metaKey || e.ctrlKey) {
        toggleSelect(side, file.Name);
      } else {
        clearSelection(side);
        toggleSelect(side, file.Name);
      }
    }
  }, [side, navigate, toggleSelect, clearSelection]);

  const handleRename = useCallback(async (oldName: string, newName: string) => {
    if (newName && newName !== oldName) {
      await rename(oldName, newName);
    }
    setRenamingFile(null);
  }, [rename]);

  const handleNewFolder = useCallback(async (name: string) => {
    if (name) await createFolder(name);
    setNewFolderMode(false);
  }, [createFolder]);

  const deleteSingle = useCallback(async (fileName: string) => {
    const file = panel.files.find((f) => f.Name === fileName);
    if (!file) return;
    const remotePath = panel.path ? `${panel.path}/${fileName}` : fileName;
    if (file.IsDir) {
      await window.rcloneAPI.deleteDir(panel.remote, remotePath);
    } else {
      await window.rcloneAPI.deleteFile(panel.remote, remotePath);
    }
    refresh();
  }, [panel.remote, panel.path, panel.files, refresh]);

  const copySingleToOther = useCallback(async (fileName: string) => {
    const otherSide = side === 'left' ? 'right' : 'left';
    const other = usePanelStore.getState()[otherSide];
    if (!other.remote) return;
    const file = panel.files.find((f) => f.Name === fileName);
    if (!file) return;
    const srcPath = panel.path ? `${panel.path}/${fileName}` : fileName;
    const dstPath = other.path ? `${other.path}/${fileName}` : fileName;
    if (file.IsDir) {
      await window.rcloneAPI.copyDir(panel.remote, srcPath, other.remote, dstPath);
    } else {
      await window.rcloneAPI.copyFile(panel.remote, srcPath, other.remote, dstPath);
    }
  }, [side, panel.remote, panel.path, panel.files]);

  // --- Drag & Drop ---
  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    const data = e.dataTransfer.types.includes('application/json');
    if (data) {
      e.dataTransfer.dropEffect = e.altKey ? 'move' : 'copy';
      setDragOver(true);
    }
  }, []);

  const handleDragLeave = useCallback(() => {
    setDragOver(false);
  }, []);

  const handleDrop = useCallback(async (e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(false);

    try {
      const raw = e.dataTransfer.getData('application/json');
      if (!raw) return;
      const data = JSON.parse(raw) as { side: string; fileName: string; isDir: boolean };

      // Only accept drops from the other panel
      if (data.side === side) return;

      const srcSide = data.side as 'left' | 'right';
      const srcPanel = usePanelStore.getState()[srcSide];
      const dstPanel = panel;

      if (!srcPanel.remote || !dstPanel.remote) return;

      const srcPath = srcPanel.path ? `${srcPanel.path}/${data.fileName}` : data.fileName;
      const dstPath = dstPanel.path ? `${dstPanel.path}/${data.fileName}` : data.fileName;

      const isMove = e.altKey;
      const api = window.rcloneAPI;

      if (data.isDir) {
        if (isMove) {
          await api.moveDir(srcPanel.remote, srcPath, dstPanel.remote, dstPath);
        } else {
          await api.copyDir(srcPanel.remote, srcPath, dstPanel.remote, dstPath);
        }
      } else {
        if (isMove) {
          await api.moveFile(srcPanel.remote, srcPath, dstPanel.remote, dstPath);
        } else {
          await api.copyFile(srcPanel.remote, srcPath, dstPanel.remote, dstPath);
        }
      }

      // Refresh both panels
      refresh();
      const otherSide = side === 'left' ? 'right' : 'left';
      // Trigger refresh of source panel via store
      const otherPanel = usePanelStore.getState()[otherSide];
      if (otherPanel.remote) {
        window.rcloneAPI.listFiles(otherPanel.remote, otherPanel.path).then((files) => {
          usePanelStore.getState().setFiles(otherSide, files);
        });
      }
    } catch (err) {
      console.error('Drop failed:', err);
    }
  }, [side, panel, refresh]);

  const SortHeader = ({ label, field }: { label: string; field: 'name' | 'size' | 'date' }) => (
    <button
      className={`text-left text-[11px] hover:text-text ${panel.sortBy === field ? 'text-accent' : 'text-text-muted'}`}
      onClick={() => setSort(side, field)}
    >
      {label} {panel.sortBy === field && (panel.sortAsc ? '↑' : '↓')}
    </button>
  );

  return (
    <div
      className={`flex-1 flex flex-col min-h-0 transition-colors ${dragOver ? 'bg-accent/10 ring-2 ring-accent/40 ring-inset' : ''}`}
      onContextMenu={(e) => e.preventDefault()}
      onClick={() => clearSelection(side)}
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
    >
      {/* Column headers */}
      <div className="grid grid-cols-[1fr_100px_160px] gap-2 px-3 py-1.5 border-b border-border bg-surface-raised">
        <SortHeader label={t('file.name')} field="name" />
        <SortHeader label={t('file.size')} field="size" />
        <SortHeader label={t('file.modified')} field="date" />
      </div>

      {/* Drag hint */}
      {dragOver && (
        <div className="px-3 py-1 bg-accent/20 text-accent text-[11px] text-center border-b border-accent/30">
          {t('file.dropHint')}
        </div>
      )}

      {/* File list */}
      <div className="flex-1 overflow-y-auto min-h-0">
        {panel.path && (
          <div
            className="grid grid-cols-[1fr_100px_160px] gap-2 px-3 py-1.5 hover:bg-surface-overlay cursor-pointer text-text-muted text-xs"
            onClick={(e) => { e.stopPropagation(); goUp(); }}
          >
            <span className="flex items-center gap-2">
              <ArrowUp size={14} /> ..
            </span>
            <span />
            <span />
          </div>
        )}

        {newFolderMode && (
          <div className="px-3 py-1.5">
            <input
              autoFocus
              className="bg-surface-overlay border border-accent rounded px-2 py-1 text-xs text-text w-60 outline-none"
              placeholder={t('file.newFolderName')}
              onKeyDown={(e) => {
                if (e.key === 'Enter') handleNewFolder((e.target as HTMLInputElement).value);
                if (e.key === 'Escape') setNewFolderMode(false);
              }}
              onBlur={(e) => handleNewFolder(e.target.value)}
            />
          </div>
        )}

        {sorted.map((file) => (
          <FileItem
            key={file.Name}
            file={file}
            selected={panel.selectedFiles.has(file.Name)}
            renaming={renamingFile === file.Name}
            side={side}
            onClick={(e) => { e.stopPropagation(); handleClick(file, e); }}
            onContextMenu={(e) => { e.stopPropagation(); handleContextMenu(e, file); }}
            onRename={handleRename}
          />
        ))}

        {sorted.length === 0 && !panel.loading && (
          <div className="flex items-center justify-center h-32 text-text-muted text-sm">
            {t('file.emptyFolder')}
          </div>
        )}
      </div>

      {contextMenu && (
        <ContextMenu
          x={contextMenu.x}
          y={contextMenu.y}
          file={contextMenu.file}
          onClose={() => setContextMenu(null)}
          onRename={(name) => { setContextMenu(null); setRenamingFile(name); }}
          onDelete={(name) => { setContextMenu(null); deleteSingle(name); }}
          onCopy={(name) => { setContextMenu(null); copySingleToOther(name); }}
        />
      )}
    </div>
  );
}
