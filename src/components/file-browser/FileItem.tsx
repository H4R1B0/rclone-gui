import { useState, useCallback } from 'react';
import type { LucideIcon } from 'lucide-react';
import { Folder, File, FileText, Image, Film, Music, Archive, FileCode } from 'lucide-react';
import { formatBytes, formatDate, getFileIcon } from '../../lib/utils';

interface FileItemProps {
  file: RcloneFile;
  selected: boolean;
  renaming: boolean;
  side: 'left' | 'right';
  onClick: (e: React.MouseEvent) => void;
  onContextMenu: (e: React.MouseEvent) => void;
  onRename: (oldName: string, newName: string) => void;
}

const iconMap: Record<string, LucideIcon> = {
  folder: Folder,
  file: File,
  'file-text': FileText,
  image: Image,
  video: Film,
  music: Music,
  archive: Archive,
  'file-code': FileCode,
};

export function FileItem({ file, selected, renaming, side, onClick, onContextMenu, onRename }: FileItemProps) {
  const [editName, setEditName] = useState(file.Name);
  const iconType = getFileIcon(file.Name, file.IsDir);
  const Icon = iconMap[iconType] ?? File;

  const handleRenameSubmit = () => {
    onRename(file.Name, editName);
  };

  const handleDragStart = useCallback((e: React.DragEvent) => {
    e.dataTransfer.setData('application/json', JSON.stringify({
      side,
      fileName: file.Name,
      isDir: file.IsDir,
    }));
    e.dataTransfer.effectAllowed = 'copyMove';
  }, [side, file.Name, file.IsDir]);

  return (
    <div
      className={`grid grid-cols-[1fr_100px_160px] gap-2 px-3 py-1.5 text-xs cursor-pointer transition-colors ${
        selected ? 'bg-accent-muted text-text' : 'hover:bg-surface-overlay text-text'
      }`}
      draggable={!renaming}
      onDragStart={handleDragStart}
      onClick={onClick}
      onContextMenu={onContextMenu}
    >
      <span className="flex items-center gap-2 min-w-0">
        <Icon
          size={16}
          className={`flex-shrink-0 ${file.IsDir ? 'text-warning' : 'text-text-muted'}`}
        />
        {renaming ? (
          <input
            autoFocus
            className="bg-surface-overlay border border-accent rounded px-1 py-0.5 text-xs text-text outline-none flex-1 min-w-0"
            value={editName}
            onChange={(e) => setEditName(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') handleRenameSubmit();
              if (e.key === 'Escape') onRename(file.Name, file.Name);
            }}
            onBlur={handleRenameSubmit}
            onClick={(e) => e.stopPropagation()}
          />
        ) : (
          <span className="truncate">{file.Name}</span>
        )}
      </span>
      <span className="text-text-muted">{file.IsDir ? '-' : formatBytes(file.Size)}</span>
      <span className="text-text-muted">{formatDate(file.ModTime)}</span>
    </div>
  );
}
