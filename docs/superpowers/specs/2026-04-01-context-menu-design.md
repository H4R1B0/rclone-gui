# Context Menu Redesign

## Overview

Replace the current minimal context menu (rename, copy-to-other, delete) with a full-featured context menu system that supports: open, cut, copy, paste, rename, delete, play (disabled), new folder, and properties. The menu adapts based on what was right-clicked (file, folder, or empty area).

## Clipboard Store (`clipboardStore.ts`)

New Zustand store for cross-panel clipboard state:

```ts
interface ClipboardState {
  action: 'copy' | 'cut' | null;
  sourceSide: 'left' | 'right';
  sourceRemote: string;
  sourcePath: string;
  files: { name: string; isDir: boolean }[];
}
```

- `copy` / `cut` — sets the clipboard with selected file(s) and source info
- `paste` — executes copy or move from source to current panel's location, then clears clipboard
- `cut` + `paste` = move operation; `copy` + `paste` = copy operation
- Clipboard is global — copy on the left panel, paste on the right panel

## Context Menu Types

### 1. File/Folder Context Menu

Shown when right-clicking on a file or folder.

| Menu Item | Folder | File | Condition |
|-----------|--------|------|-----------|
| Open | Enabled | Hidden | Folder only — navigates into the folder |
| *(separator)* | | | |
| Cut | Enabled | Enabled | Always |
| Copy | Enabled | Enabled | Always |
| *(separator)* | | | |
| Rename | Enabled | Enabled | Always |
| Delete | Enabled | Enabled | Always (danger style) |
| *(separator)* | | | |
| Play | Hidden | Disabled | Not yet implemented, grayed out on files |
| *(separator)* | | | |
| Properties | Enabled | Enabled | Always — opens properties modal |

### 2. Empty Area Context Menu

Shown when right-clicking on an empty area (no file under cursor).

| Menu Item | Condition |
|-----------|-----------|
| Paste | Enabled only when clipboard has data |
| New Folder | Always enabled |

## Properties Modal

A modal dialog showing file/folder metadata.

### Basic Info
- Name
- Type (file / folder)
- Size (formatted)
- Modified date
- Full path

### Cloud Info
- Remote name (e.g., `gdrive:`)
- Hash values — fetched via `operations/hashfile` rclone API
  - Only shown for files (not folders)
  - Show loading state while fetching

## Component Changes

### `ContextMenu.tsx`
- Refactor to accept a `type` prop: `'file'` or `'empty'`
- File menu: open, cut, copy, rename, delete, play (disabled), properties
- Empty menu: paste, new folder
- Each item receives an `enabled` prop for grayed-out state

### `FileList.tsx`
- Add right-click handler on the empty area (the container div) to show the empty-area context menu
- Remove `onCopy` (copy-to-other-panel) — replaced by cut/copy/paste flow
- Add handlers: `onCut`, `onCopy` (clipboard), `onPaste`, `onOpen`, `onProperties`
- Wire up `clipboardStore` for paste operations

### `useFileOperations.ts`
- Add `paste()` — reads from clipboardStore, performs copy or move to current panel
- Remove `copyToOtherPanel` — replaced by clipboard paste
- Keep `moveToOtherPanel` internally (used by paste when action is 'cut')

### New: `PropertiesModal.tsx`
- Displays file metadata in a modal
- Fetches hash via `operations/hashfile` for files
- Shows remote name from panel state

## Removed Features

- **"Copy to Other Panel"** menu item — replaced by the standard cut/copy/paste workflow

## i18n Keys to Add

```
ctx.open — 열기 / Open
ctx.cut — 잘라내기 / Cut
ctx.copy — 복사 / Copy
ctx.paste — 붙여넣기 / Paste
ctx.play — 재생 / Play
ctx.properties — 속성 / Properties
ctx.newFolder — 새 폴더 / New Folder
properties.title — 속성 / Properties
properties.name — 이름 / Name
properties.type — 유형 / Type
properties.size — 크기 / Size
properties.modified — 수정일 / Modified
properties.path — 경로 / Path
properties.remote — 리모트 / Remote
properties.hash — 해시 / Hash
properties.file — 파일 / File
properties.folder — 폴더 / Folder
properties.loading — 로딩 중... / Loading...
```
