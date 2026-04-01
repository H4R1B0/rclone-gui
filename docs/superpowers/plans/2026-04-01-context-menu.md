# Context Menu Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the minimal 3-item context menu with a full context menu system supporting open, cut, copy, paste, rename, delete, play (disabled), new folder, and properties, with a clipboard store for cross-panel operations.

**Architecture:** New `clipboardStore` (Zustand) holds cut/copy state globally. `ContextMenu.tsx` is rewritten to render two menu variants (file-menu and empty-area-menu) based on a `type` prop. A new `PropertiesModal.tsx` shows file metadata including rclone hash. A new `hashFile` IPC endpoint is added for hash retrieval.

**Tech Stack:** React, TypeScript, Zustand, Tailwind CSS, Electron IPC, rclone rc API

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `src/stores/clipboardStore.ts` | Global clipboard state (cut/copy/paste) |
| Create | `src/components/file-browser/PropertiesModal.tsx` | File/folder properties modal with hash |
| Modify | `src/components/file-browser/ContextMenu.tsx` | Two menu variants: file and empty-area |
| Modify | `src/components/file-browser/FileList.tsx` | Wire new context menu handlers, empty-area right-click |
| Modify | `src/hooks/useFileOperations.ts` | Add paste(), remove copyToOtherPanel |
| Modify | `src/lib/i18n.ts` | Add new i18n keys |
| Modify | `src/vite-env.d.ts` | Add hashFile type to RcloneAPI |
| Modify | `electron/preload.ts` | Expose hashFile IPC |
| Modify | `electron/ipc-handlers.ts` | Add rclone:hashFile handler |

---

### Task 1: Add i18n keys

**Files:**
- Modify: `src/lib/i18n.ts:56-58` (context menu section)

- [ ] **Step 1: Add all new i18n keys**

In `src/lib/i18n.ts`, replace the existing context menu section and add properties keys. Find the lines:

```ts
  // Context menu
  'ctx.rename': { ko: '이름 변경', en: 'Rename' },
  'ctx.copyToOther': { ko: '반대편에 복사', en: 'Copy to Other Panel' },
```

Replace with:

```ts
  // Context menu
  'ctx.open': { ko: '열기', en: 'Open' },
  'ctx.cut': { ko: '잘라내기', en: 'Cut' },
  'ctx.copy': { ko: '복사', en: 'Copy' },
  'ctx.paste': { ko: '붙여넣기', en: 'Paste' },
  'ctx.rename': { ko: '이름 변경', en: 'Rename' },
  'ctx.play': { ko: '재생', en: 'Play' },
  'ctx.properties': { ko: '속성', en: 'Properties' },
  'ctx.newFolder': { ko: '새 폴더', en: 'New Folder' },

  // Properties modal
  'properties.title': { ko: '속성', en: 'Properties' },
  'properties.name': { ko: '이름', en: 'Name' },
  'properties.type': { ko: '유형', en: 'Type' },
  'properties.size': { ko: '크기', en: 'Size' },
  'properties.modified': { ko: '수정일', en: 'Modified' },
  'properties.path': { ko: '경로', en: 'Path' },
  'properties.remote': { ko: '리모트', en: 'Remote' },
  'properties.hash': { ko: '해시', en: 'Hash' },
  'properties.file': { ko: '파일', en: 'File' },
  'properties.folder': { ko: '폴더', en: 'Folder' },
  'properties.loading': { ko: '로딩 중...', en: 'Loading...' },
```

- [ ] **Step 2: Verify no TypeScript errors**

Run: `npm run typecheck`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add src/lib/i18n.ts
git commit -m "feat: 컨텍스트 메뉴 및 속성 모달 i18n 키 추가"
```

---

### Task 2: Create clipboard store

**Files:**
- Create: `src/stores/clipboardStore.ts`

- [ ] **Step 1: Create the clipboard store**

Create `src/stores/clipboardStore.ts`:

```ts
import { create } from 'zustand';

interface ClipboardFile {
  name: string;
  isDir: boolean;
}

interface ClipboardStore {
  action: 'copy' | 'cut' | null;
  sourceRemote: string;
  sourcePath: string;
  files: ClipboardFile[];

  copy: (sourceRemote: string, sourcePath: string, files: ClipboardFile[]) => void;
  cut: (sourceRemote: string, sourcePath: string, files: ClipboardFile[]) => void;
  clear: () => void;
  hasData: () => boolean;
}

export const useClipboardStore = create<ClipboardStore>((set, get) => ({
  action: null,
  sourceRemote: '',
  sourcePath: '',
  files: [],

  copy: (sourceRemote, sourcePath, files) =>
    set({ action: 'copy', sourceRemote, sourcePath, files }),

  cut: (sourceRemote, sourcePath, files) =>
    set({ action: 'cut', sourceRemote, sourcePath, files }),

  clear: () =>
    set({ action: null, sourceRemote: '', sourcePath: '', files: [] }),

  hasData: () => get().action !== null && get().files.length > 0,
}));
```

- [ ] **Step 2: Verify no TypeScript errors**

Run: `npm run typecheck`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add src/stores/clipboardStore.ts
git commit -m "feat: 클립보드 스토어 추가 (잘라내기/복사/붙여넣기)"
```

---

### Task 3: Add hashFile IPC endpoint

**Files:**
- Modify: `src/vite-env.d.ts:32` (add to RcloneAPI interface)
- Modify: `electron/preload.ts:48` (add preload exposure)
- Modify: `electron/ipc-handlers.ts:177` (add IPC handler)

- [ ] **Step 1: Add type to RcloneAPI interface**

In `src/vite-env.d.ts`, after the `renameFile` line (line 32), add:

```ts
  hashFile: (fs: string, remote: string) => Promise<Record<string, string>>;
```

- [ ] **Step 2: Add preload exposure**

In `electron/preload.ts`, after the `renameFile` line (line 47), add:

```ts
  hashFile: (fs: string, remote: string) => ipcRenderer.invoke('rclone:hashFile', fs, remote),
```

- [ ] **Step 3: Add IPC handler**

In `electron/ipc-handlers.ts`, after the `rclone:renameFile` handler (after line 176), add:

```ts
  ipcMain.handle('rclone:hashFile', async (_e, fs: string, remote: string) => {
    try {
      return await api.call('operations/hashfile', { fs, remote, hashTypes: ['md5', 'sha1'] });
    } catch {
      return {};
    }
  });
```

- [ ] **Step 4: Verify no TypeScript errors**

Run: `npm run typecheck`
Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add src/vite-env.d.ts electron/preload.ts electron/ipc-handlers.ts
git commit -m "feat: hashFile IPC 엔드포인트 추가 (속성 모달용)"
```

---

### Task 4: Create PropertiesModal

**Files:**
- Create: `src/components/file-browser/PropertiesModal.tsx`

- [ ] **Step 1: Create the properties modal component**

Create `src/components/file-browser/PropertiesModal.tsx`:

```tsx
import { useEffect, useState } from 'react';
import { X, Loader2 } from 'lucide-react';
import { useT } from '../../lib/i18n';
import { formatBytes, formatDate } from '../../lib/utils';

interface PropertiesModalProps {
  file: RcloneFile;
  remote: string;
  path: string;
  onClose: () => void;
}

export function PropertiesModal({ file, remote, path, onClose }: PropertiesModalProps) {
  const t = useT();
  const [hashes, setHashes] = useState<Record<string, string> | null>(null);
  const [hashLoading, setHashLoading] = useState(false);

  const fullPath = path ? `${path}/${file.Name}` : file.Name;

  useEffect(() => {
    if (file.IsDir) return;
    setHashLoading(true);
    window.rcloneAPI.hashFile(remote, fullPath)
      .then((result) => setHashes(result))
      .catch(() => setHashes({}))
      .finally(() => setHashLoading(false));
  }, [remote, fullPath, file.IsDir]);

  const Row = ({ label, value }: { label: string; value: string }) => (
    <div className="grid grid-cols-[100px_1fr] gap-2 py-1.5 border-b border-border last:border-b-0">
      <span className="text-text-muted text-xs">{label}</span>
      <span className="text-text text-xs break-all">{value}</span>
    </div>
  );

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50" onClick={onClose}>
      <div
        className="bg-surface-raised border border-border rounded-lg shadow-xl w-[400px] max-h-[80vh] overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-4 py-3 border-b border-border">
          <h3 className="text-sm font-medium text-text">{t('properties.title')}</h3>
          <button onClick={onClose} className="text-text-muted hover:text-text transition-colors">
            <X size={16} />
          </button>
        </div>

        {/* Content */}
        <div className="px-4 py-3">
          {/* Basic Info */}
          <Row label={t('properties.name')} value={file.Name} />
          <Row label={t('properties.type')} value={file.IsDir ? t('properties.folder') : t('properties.file')} />
          {!file.IsDir && <Row label={t('properties.size')} value={formatBytes(file.Size)} />}
          <Row label={t('properties.modified')} value={formatDate(file.ModTime)} />
          <Row label={t('properties.path')} value={fullPath} />

          {/* Cloud Info */}
          <div className="mt-3 pt-2 border-t border-border">
            <Row label={t('properties.remote')} value={remote} />
          </div>

          {/* Hash (files only) */}
          {!file.IsDir && (
            <div className="mt-3 pt-2 border-t border-border">
              <div className="text-xs text-text-muted mb-1">{t('properties.hash')}</div>
              {hashLoading ? (
                <div className="flex items-center gap-2 py-2">
                  <Loader2 size={14} className="animate-spin text-accent" />
                  <span className="text-xs text-text-muted">{t('properties.loading')}</span>
                </div>
              ) : hashes && Object.keys(hashes).length > 0 ? (
                Object.entries(hashes).map(([type, value]) => (
                  <Row key={type} label={type.toUpperCase()} value={value} />
                ))
              ) : (
                <span className="text-xs text-text-muted">-</span>
              )}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="flex justify-end px-4 py-3 border-t border-border">
          <button
            onClick={onClose}
            className="px-4 py-1.5 text-xs bg-surface-overlay hover:bg-border rounded transition-colors text-text"
          >
            {t('common.close')}
          </button>
        </div>
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Verify no TypeScript errors**

Run: `npm run typecheck`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add src/components/file-browser/PropertiesModal.tsx
git commit -m "feat: 파일/폴더 속성 모달 컴포넌트 추가"
```

---

### Task 5: Rewrite ContextMenu component

**Files:**
- Modify: `src/components/file-browser/ContextMenu.tsx` (full rewrite)

- [ ] **Step 1: Rewrite ContextMenu with two menu types**

Replace the entire content of `src/components/file-browser/ContextMenu.tsx`:

```tsx
import { useEffect, useRef } from 'react';
import type { LucideIcon } from 'lucide-react';
import { FolderOpen, Scissors, Copy, ClipboardPaste, Edit3, Trash2, Play, Info } from 'lucide-react';
import { FolderPlus } from 'lucide-react';
import { useT } from '../../lib/i18n';
import { useClipboardStore } from '../../stores/clipboardStore';

interface MenuItemDef {
  icon: LucideIcon;
  labelKey: string;
  onClick: () => void;
  danger?: boolean;
  disabled?: boolean;
  hidden?: boolean;
}

interface FileContextMenuProps {
  type: 'file';
  x: number;
  y: number;
  file: RcloneFile;
  onClose: () => void;
  onOpen: () => void;
  onCut: () => void;
  onCopy: () => void;
  onRename: () => void;
  onDelete: () => void;
  onProperties: () => void;
}

interface EmptyContextMenuProps {
  type: 'empty';
  x: number;
  y: number;
  onClose: () => void;
  onPaste: () => void;
  onNewFolder: () => void;
}

export type ContextMenuProps = FileContextMenuProps | EmptyContextMenuProps;

export function ContextMenu(props: ContextMenuProps) {
  const ref = useRef<HTMLDivElement>(null);
  const t = useT();
  const hasClipboard = useClipboardStore((s) => s.action !== null && s.files.length > 0);

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        props.onClose();
      }
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, [props.onClose]);

  let items: (MenuItemDef | 'separator')[];

  if (props.type === 'file') {
    const { file, onOpen, onCut, onCopy, onRename, onDelete, onProperties } = props;
    items = [
      { icon: FolderOpen, labelKey: 'ctx.open', onClick: onOpen, hidden: !file.IsDir },
      'separator',
      { icon: Scissors, labelKey: 'ctx.cut', onClick: onCut },
      { icon: Copy, labelKey: 'ctx.copy', onClick: onCopy },
      'separator',
      { icon: Edit3, labelKey: 'ctx.rename', onClick: onRename },
      { icon: Trash2, labelKey: 'common.delete', onClick: onDelete, danger: true },
      'separator',
      { icon: Play, labelKey: 'ctx.play', onClick: () => {}, disabled: true, hidden: file.IsDir },
      'separator',
      { icon: Info, labelKey: 'ctx.properties', onClick: onProperties },
    ];
  } else {
    const { onPaste, onNewFolder } = props;
    items = [
      { icon: ClipboardPaste, labelKey: 'ctx.paste', onClick: onPaste, disabled: !hasClipboard },
      { icon: FolderPlus, labelKey: 'ctx.newFolder', onClick: onNewFolder },
    ];
  }

  // Filter hidden items and collapse consecutive/leading/trailing separators
  const visible = items.filter((item) => item === 'separator' || !item.hidden);
  const cleaned: typeof visible = [];
  for (const item of visible) {
    if (item === 'separator') {
      if (cleaned.length > 0 && cleaned[cleaned.length - 1] !== 'separator') {
        cleaned.push(item);
      }
    } else {
      cleaned.push(item);
    }
  }
  // Remove trailing separator
  if (cleaned.length > 0 && cleaned[cleaned.length - 1] === 'separator') {
    cleaned.pop();
  }

  // Adjust position to prevent overflow off-screen
  const style: React.CSSProperties = {
    position: 'fixed',
    left: props.x,
    top: props.y,
    zIndex: 100,
  };

  return (
    <div ref={ref} style={style} className="bg-surface-raised border border-border rounded-lg shadow-xl py-1 min-w-[180px]">
      {cleaned.map((item, i) => {
        if (item === 'separator') {
          return <div key={`sep-${i}`} className="border-t border-border my-1" />;
        }
        const { icon: Icon, labelKey, onClick, danger, disabled } = item;
        return (
          <button
            key={labelKey}
            className={`flex items-center gap-2 w-full px-3 py-1.5 text-xs text-left transition-colors ${
              disabled
                ? 'text-text-muted/40 cursor-not-allowed'
                : danger
                  ? 'text-danger hover:bg-surface-overlay'
                  : 'text-text hover:bg-surface-overlay'
            }`}
            onClick={() => { if (!disabled) { onClick(); props.onClose(); } }}
            disabled={disabled}
          >
            <Icon size={14} />
            {t(labelKey)}
          </button>
        );
      })}
    </div>
  );
}
```

- [ ] **Step 2: Verify no TypeScript errors**

Run: `npm run typecheck`
Expected: Errors in `FileList.tsx` (expected — it still uses old ContextMenu props). We'll fix that in Task 6.

- [ ] **Step 3: Commit**

```bash
git add src/components/file-browser/ContextMenu.tsx
git commit -m "feat: 컨텍스트 메뉴 리디자인 (파일/빈영역 메뉴 분리)"
```

---

### Task 6: Update useFileOperations with paste

**Files:**
- Modify: `src/hooks/useFileOperations.ts`

- [ ] **Step 1: Add paste, remove copyToOtherPanel**

Replace the entire content of `src/hooks/useFileOperations.ts`:

```ts
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
```

- [ ] **Step 2: Verify no TypeScript errors**

Run: `npm run typecheck`
Expected: Errors in `FileList.tsx` still (it references old `copyToOtherPanel`). Fixed in Task 7.

- [ ] **Step 3: Commit**

```bash
git add src/hooks/useFileOperations.ts
git commit -m "feat: useFileOperations에 paste 추가, copyToOtherPanel 제거"
```

---

### Task 7: Wire everything in FileList

**Files:**
- Modify: `src/components/file-browser/FileList.tsx`

- [ ] **Step 1: Rewrite FileList to use new context menu system**

Replace the entire content of `src/components/file-browser/FileList.tsx`:

```tsx
import { useMemo, useState, useCallback } from 'react';
import { usePanelStore } from '../../stores/panelStore';
import { useClipboardStore } from '../../stores/clipboardStore';
import { usePanelFiles } from '../../hooks/useRclone';
import { useFileOperations } from '../../hooks/useFileOperations';
import { FileItem } from './FileItem';
import { ContextMenu } from './ContextMenu';
import type { ContextMenuProps } from './ContextMenu';
import { PropertiesModal } from './PropertiesModal';
import { ArrowUp } from 'lucide-react';
import { useT } from '../../lib/i18n';
import { useTransferStore } from '../../stores/transferStore';

interface FileListProps {
  side: 'left' | 'right';
}

export function FileList({ side }: FileListProps) {
  const panel = usePanelStore((s) => s[side]);
  const setSort = usePanelStore((s) => s.setSort);
  const toggleSelect = usePanelStore((s) => s.toggleSelect);
  const clearSelection = usePanelStore((s) => s.clearSelection);
  const { navigate, goUp, refresh } = usePanelFiles(side);
  const { createFolder, rename, paste } = useFileOperations(side);
  const clipboardCopy = useClipboardStore((s) => s.copy);
  const clipboardCut = useClipboardStore((s) => s.cut);
  const t = useT();

  const [contextMenu, setContextMenu] = useState<ContextMenuProps | null>(null);
  const [renamingFile, setRenamingFile] = useState<string | null>(null);
  const [newFolderMode, setNewFolderMode] = useState(false);
  const [propertiesFile, setPropertiesFile] = useState<RcloneFile | null>(null);
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

  // --- Context menu handlers ---
  const handleFileContextMenu = useCallback((e: React.MouseEvent, file: RcloneFile) => {
    e.preventDefault();
    setContextMenu({
      type: 'file',
      x: e.clientX,
      y: e.clientY,
      file,
      onClose: () => setContextMenu(null),
      onOpen: () => { setContextMenu(null); navigate(file.Name); },
      onCut: () => {
        setContextMenu(null);
        clipboardCut(panel.remote, panel.path, [{ name: file.Name, isDir: file.IsDir }]);
      },
      onCopy: () => {
        setContextMenu(null);
        clipboardCopy(panel.remote, panel.path, [{ name: file.Name, isDir: file.IsDir }]);
      },
      onRename: () => { setContextMenu(null); setRenamingFile(file.Name); },
      onDelete: () => { setContextMenu(null); deleteSingle(file.Name); },
      onProperties: () => { setContextMenu(null); setPropertiesFile(file); },
    });
  }, [panel.remote, panel.path, navigate, clipboardCut, clipboardCopy]);

  const handleEmptyContextMenu = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    setContextMenu({
      type: 'empty',
      x: e.clientX,
      y: e.clientY,
      onClose: () => setContextMenu(null),
      onPaste: () => { setContextMenu(null); paste(); },
      onNewFolder: () => { setContextMenu(null); setNewFolderMode(true); },
    });
  }, [paste]);

  // --- File operations ---
  const handleClick = useCallback((file: RcloneFile, e: React.MouseEvent) => {
    if (e.detail === 2 && file.IsDir) {
      navigate(file.Name);
      return;
    }
    if (e.metaKey || e.ctrlKey) {
      toggleSelect(side, file.Name);
    } else {
      clearSelection(side);
      toggleSelect(side, file.Name);
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

      if (data.side === side) return;

      const srcSide = data.side as 'left' | 'right';
      const srcPanel = usePanelStore.getState()[srcSide];
      const dstPanel = panel;

      if (!srcPanel.remote || !dstPanel.remote) return;

      const srcPath = srcPanel.path ? `${srcPanel.path}/${data.fileName}` : data.fileName;
      const dstPath = dstPanel.path ? `${dstPanel.path}/${data.fileName}` : data.fileName;

      const isMove = e.altKey;
      const rcloneApi = window.rcloneAPI;

      if (!isMove) {
        useTransferStore.getState().addCopyOrigin({
          name: data.fileName, srcFs: srcPanel.remote, srcRemote: srcPath,
          dstFs: dstPanel.remote, dstRemote: dstPath, isDir: data.isDir,
        });
      }

      if (data.isDir) {
        if (isMove) {
          await rcloneApi.moveDir(srcPanel.remote, srcPath, dstPanel.remote, dstPath);
        } else {
          await rcloneApi.copyDir(srcPanel.remote, srcPath, dstPanel.remote, dstPath);
        }
      } else {
        if (isMove) {
          await rcloneApi.moveFile(srcPanel.remote, srcPath, dstPanel.remote, dstPath);
        } else {
          await rcloneApi.copyFile(srcPanel.remote, srcPath, dstPanel.remote, dstPath);
        }
      }

      refresh();
      const otherSide = side === 'left' ? 'right' : 'left';
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
      onContextMenu={(e) => { e.preventDefault(); handleEmptyContextMenu(e); }}
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
            onDoubleClick={(e) => { e.stopPropagation(); goUp(); }}
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
            onContextMenu={(e) => { e.stopPropagation(); handleFileContextMenu(e, file); }}
            onRename={handleRename}
          />
        ))}

        {sorted.length === 0 && !panel.loading && (
          <div className="flex items-center justify-center h-32 text-text-muted text-sm">
            {t('file.emptyFolder')}
          </div>
        )}
      </div>

      {contextMenu && <ContextMenu {...contextMenu} />}

      {propertiesFile && (
        <PropertiesModal
          file={propertiesFile}
          remote={panel.remote}
          path={panel.path}
          onClose={() => setPropertiesFile(null)}
        />
      )}
    </div>
  );
}
```

- [ ] **Step 2: Verify TypeScript and build**

Run: `npm run typecheck`
Expected: No errors

Run: `npm run build`
Expected: Build succeeds

- [ ] **Step 3: Commit**

```bash
git add src/components/file-browser/FileList.tsx
git commit -m "feat: FileList에 새 컨텍스트 메뉴 연동 (잘라내기/복사/붙여넣기/속성)"
```

---

### Task 8: Remove dead code and final cleanup

**Files:**
- Modify: `src/lib/i18n.ts` (remove `ctx.copyToOther` key)

- [ ] **Step 1: Remove the old ctx.copyToOther i18n key**

In `src/lib/i18n.ts`, delete the line:

```ts
  'ctx.copyToOther': { ko: '반대편에 복사', en: 'Copy to Other Panel' },
```

- [ ] **Step 2: Verify full build passes**

Run: `npm run typecheck && npm run build`
Expected: Both pass with no errors

- [ ] **Step 3: Commit**

```bash
git add src/lib/i18n.ts
git commit -m "refactor: 사용하지 않는 ctx.copyToOther i18n 키 제거"
```
