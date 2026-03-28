import { useEffect, useRef } from 'react';
import type { LucideIcon } from 'lucide-react';
import { Copy, Trash2, Edit3 } from 'lucide-react';

interface ContextMenuProps {
  x: number;
  y: number;
  file: RcloneFile;
  onClose: () => void;
  onRename: (name: string) => void;
  onDelete: (name: string) => void;
  onCopy: (name: string) => void;
}

export function ContextMenu({ x, y, file, onClose, onRename, onDelete, onCopy }: ContextMenuProps) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        onClose();
      }
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, [onClose]);

  const style: React.CSSProperties = {
    position: 'fixed',
    left: x,
    top: y,
    zIndex: 100,
  };

  const Item = ({ icon: Icon, label, onClick, danger }: { icon: LucideIcon; label: string; onClick: () => void; danger?: boolean }) => (
    <button
      className={`flex items-center gap-2 w-full px-3 py-1.5 text-xs text-left hover:bg-surface-overlay transition-colors ${
        danger ? 'text-danger' : 'text-text'
      }`}
      onClick={onClick}
    >
      <Icon size={14} />
      {label}
    </button>
  );

  return (
    <div ref={ref} style={style} className="bg-surface-raised border border-border rounded-lg shadow-xl py-1 min-w-[160px]">
      <Item icon={Edit3} label="이름 변경" onClick={() => onRename(file.Name)} />
      <Item icon={Copy} label="반대편에 복사" onClick={() => onCopy(file.Name)} />
      <div className="border-t border-border my-1" />
      <Item icon={Trash2} label="삭제" onClick={() => onDelete(file.Name)} danger />
    </div>
  );
}
