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
