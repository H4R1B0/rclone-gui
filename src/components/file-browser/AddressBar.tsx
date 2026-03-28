import { useState, useCallback, useRef, useEffect } from 'react';
import { ChevronRight, Monitor, Cloud, ChevronUp } from 'lucide-react';
import { usePanelStore } from '../../stores/panelStore';
import { usePanelFiles } from '../../hooks/useRclone';

interface AddressBarProps {
  side: 'left' | 'right';
}

export function AddressBar({ side }: AddressBarProps) {
  const panel = usePanelStore((s) => s[side]);
  const setRemote = usePanelStore((s) => s.setRemote);
  const { loadFiles, goUp } = usePanelFiles(side);
  const [editing, setEditing] = useState(false);
  const [inputValue, setInputValue] = useState('');
  const inputRef = useRef<HTMLInputElement>(null);

  const isLocal = panel.mode === 'local';

  // Full path display
  const fullPath = isLocal
    ? `/${panel.path}`.replace(/\/+/g, '/')
    : panel.path
      ? `${panel.remote}/${panel.path}`
      : panel.remote;

  const breadcrumbParts = panel.path.split('/').filter(Boolean);

  const startEditing = useCallback(() => {
    setInputValue(isLocal ? `/${panel.path}`.replace(/\/+/g, '/') : fullPath);
    setEditing(true);
  }, [isLocal, panel.path, fullPath]);

  useEffect(() => {
    if (editing && inputRef.current) {
      inputRef.current.focus();
      inputRef.current.select();
    }
  }, [editing]);

  const handleSubmit = useCallback(() => {
    setEditing(false);
    const val = inputValue.trim();
    if (!val) return;

    if (isLocal) {
      // Navigate to absolute local path
      const cleanPath = val.replace(/^\/+/, '');
      loadFiles('/', cleanPath);
    } else {
      // Could be remote:path format
      if (val.includes(':')) {
        const colonIdx = val.indexOf(':');
        const remote = val.substring(0, colonIdx + 1);
        const path = val.substring(colonIdx + 1).replace(/^\/+/, '');
        setRemote(side, remote);
        setTimeout(() => loadFiles(remote, path), 100);
      } else {
        loadFiles(undefined, val);
      }
    }
  }, [inputValue, isLocal, side, loadFiles, setRemote]);

  const goToPathIndex = useCallback((index: number) => {
    const newPath = breadcrumbParts.slice(0, index + 1).join('/');
    loadFiles(undefined, newPath);
  }, [breadcrumbParts, loadFiles]);

  const goToRoot = useCallback(() => {
    if (isLocal) {
      loadFiles('/', '');
    } else {
      loadFiles(panel.remote, '');
    }
  }, [isLocal, panel.remote, loadFiles]);

  const goToCloudHome = useCallback(() => {
    setRemote(side, '');
  }, [side, setRemote]);

  return (
    <div className="flex items-center gap-1 bg-surface-raised border-b border-border">
      {/* Up button */}
      <button
        onClick={goUp}
        className="px-2 py-2.5 text-text-muted hover:text-accent hover:bg-surface-overlay transition-colors"
        title="상위 폴더"
      >
        <ChevronUp size={14} />
      </button>

      {/* Address bar */}
      <div
        className="flex-1 flex items-center min-w-0 cursor-text"
        onClick={() => !editing && startEditing()}
      >
        {editing ? (
          <input
            ref={inputRef}
            className="flex-1 bg-surface-overlay border border-accent rounded px-2 py-1 text-xs text-text outline-none mr-2"
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') handleSubmit();
              if (e.key === 'Escape') setEditing(false);
            }}
            onBlur={() => setEditing(false)}
          />
        ) : (
          <div className="flex items-center gap-0.5 py-2 text-xs overflow-x-auto min-w-0">
            {/* Root icon */}
            <button
              onClick={(e) => { e.stopPropagation(); isLocal ? goToRoot() : goToCloudHome(); }}
              className="flex items-center gap-1 px-1.5 py-0.5 rounded hover:bg-surface-overlay text-text-muted hover:text-accent flex-shrink-0 transition-colors"
              title={isLocal ? '/ (루트)' : '클라우드 선택'}
            >
              {isLocal ? <Monitor size={13} /> : <Cloud size={13} />}
              <span>{isLocal ? '내 PC' : panel.remote}</span>
            </button>

            {/* Path segments */}
            {breadcrumbParts.map((part, i) => (
              <span key={i} className="flex items-center gap-0.5 flex-shrink-0">
                <ChevronRight size={11} className="text-text-muted" />
                <button
                  onClick={(e) => { e.stopPropagation(); goToPathIndex(i); }}
                  className={`px-1 py-0.5 rounded hover:bg-surface-overlay transition-colors ${
                    i === breadcrumbParts.length - 1 ? 'text-text' : 'text-text-muted hover:text-accent'
                  }`}
                >
                  {part}
                </button>
              </span>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
