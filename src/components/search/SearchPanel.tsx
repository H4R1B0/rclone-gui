import React, { useEffect, useRef, useState } from 'react';
import { useSearchStore } from '../../stores/searchStore';
import { useSearch } from '../../hooks/useSearch';
import { usePanelStore } from '../../stores/panelStore';
import { Search, Loader2, Folder, File as FileIcon, ArrowUpDown, ArrowUp, ArrowDown, StopCircle } from 'lucide-react';
import { ProviderIconSvg } from '../common/ProviderIconSvg';
import { useT } from '../../lib/i18n';

type SortKey = 'Name' | 'RemoteFs' | 'Size' | 'ModTime' | 'Path';
type SortDir = 'asc' | 'desc';

function formatSize(bytes: number): string {
  if (bytes === 0) return '—';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(1024));
  return `${(bytes / Math.pow(1024, i)).toFixed(i === 0 ? 0 : 1)} ${units[i]}`;
}

function formatDate(dateStr: string): string {
  if (!dateStr) return '—';
  const d = new Date(dateStr);
  const year = d.getFullYear();
  const mon = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  const hour = String(d.getHours()).padStart(2, '0');
  const min = String(d.getMinutes()).padStart(2, '0');
  return `${year}-${mon}-${day} ${hour}:${min}`;
}

function getFolderPath(path: string): string {
  if (!path) return '/';
  const parts = path.split('/');
  parts.pop(); // remove filename
  return parts.length > 0 ? parts.join('/') || '/' : '/';
}

export function SearchPanel() {
  const t = useT();
  const {
    query, isSearching, results, error, selectedClouds,
    setQuery, toggleCloud, reset,
  } = useSearchStore();

  const { performSearch, abortSearch } = useSearch();
  const { remotes, activePanel, setPath, setRemote } = usePanelStore();
  const inputRef = useRef<HTMLInputElement>(null);
  const [sortKey, setSortKey] = useState<SortKey>('Name');
  const [sortDir, setSortDir] = useState<SortDir>('asc');
  const [remoteTypes, setRemoteTypes] = useState<Record<string, string>>({});

  // Auto-focus on mount, abort search on unmount
  useEffect(() => {
    setTimeout(() => inputRef.current?.focus(), 100);
    return () => { abortSearch(); reset(); };
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  // Load remote types for icons
  useEffect(() => {
    const cloudRemotes = remotes.filter(r => r !== '/');
    cloudRemotes.forEach(async (name) => {
      try {
        const cfg = await window.rcloneAPI.getRemoteConfig(name) as Record<string, string>;
        setRemoteTypes(prev => ({ ...prev, [name]: cfg.type ?? '' }));
      } catch { /* ignore */ }
    });
  }, [remotes]);

  // Keyboard shortcut
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'f') {
        e.preventDefault();
        inputRef.current?.focus();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    performSearch();
  };

  const handleResultClick = (remoteFs: string, path: string, isDir: boolean) => {
    let dirPath = '';
    if (isDir) {
      dirPath = path;
    } else {
      const parts = path.split('/');
      parts.pop();
      dirPath = parts.join('/');
    }
    setRemote(activePanel, remoteFs);
    setTimeout(() => {
      setPath(activePanel, dirPath);
    }, 50);
  };

  const handleSort = (key: SortKey) => {
    if (sortKey === key) {
      setSortDir(d => d === 'asc' ? 'desc' : 'asc');
    } else {
      setSortKey(key);
      setSortDir('asc');
    }
  };

  const sortedResults = [...results].sort((a, b) => {
    const dir = sortDir === 'asc' ? 1 : -1;
    switch (sortKey) {
      case 'Name':
        return dir * a.Name.localeCompare(b.Name);
      case 'RemoteFs':
        return dir * a.RemoteFs.localeCompare(b.RemoteFs);
      case 'Size':
        return dir * (a.Size - b.Size);
      case 'ModTime':
        return dir * (new Date(a.ModTime).getTime() - new Date(b.ModTime).getTime());
      case 'Path':
        return dir * getFolderPath(a.Path).localeCompare(getFolderPath(b.Path));
      default:
        return 0;
    }
  });

  const cloudRemotes = remotes.filter(r => r !== '/');

  const SortIcon = ({ col }: { col: SortKey }) => {
    if (sortKey !== col) return <ArrowUpDown size={12} className="opacity-30" />;
    return sortDir === 'asc' ? <ArrowUp size={12} className="text-accent" /> : <ArrowDown size={12} className="text-accent" />;
  };

  return (
    <div className="w-full h-full bg-surface flex flex-col overflow-hidden">
      {/* Search bar */}
      <div className="flex-shrink-0 px-5 pt-5 pb-3">
        <form onSubmit={handleSearch} className="flex items-center gap-2">
          <div className="relative flex-1">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-text-muted" />
            <input
              ref={inputRef}
              type="text"
              className="w-full pl-10 pr-4 py-2.5 rounded-xl bg-surface-raised border border-border focus:border-accent text-sm text-text outline-none transition-colors"
              placeholder={t('search.placeholder')}
              value={query}
              onChange={(e) => setQuery(e.target.value)}
            />
          </div>
          <button
            type="submit"
            disabled={isSearching || !query.trim()}
            className="flex items-center gap-1.5 px-5 py-2.5 rounded-xl bg-accent hover:bg-accent-hover text-white text-sm font-medium disabled:opacity-50 transition-colors"
          >
            {isSearching ? <Loader2 size={14} className="animate-spin" /> : <Search size={14} />}
            {t('search.button')}
          </button>
          {isSearching && (
            <button
              type="button"
              onClick={abortSearch}
              className="flex items-center gap-1.5 px-4 py-2.5 rounded-xl bg-danger/10 hover:bg-danger/20 text-danger text-sm font-medium transition-colors"
              title={t('search.stop')}
            >
              <StopCircle size={14} />
              {t('search.stop')}
            </button>
          )}
        </form>
      </div>

      {/* Cloud filters */}
      <div className="flex-shrink-0 flex items-center gap-2 px-5 pb-3 overflow-x-auto" style={{ scrollbarWidth: 'none' }}>
        <span className="text-[11px] font-semibold text-text-muted uppercase tracking-wider mr-1">{t('search.filter')}</span>
        {cloudRemotes.length === 0 ? (
          <span className="text-xs text-text-muted">{t('search.noCloud')}</span>
        ) : (
          cloudRemotes.map(remote => (
            <button
              key={remote}
              type="button"
              onClick={() => toggleCloud(remote)}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium border transition-all
                ${selectedClouds.includes(remote)
                  ? 'bg-accent/10 text-accent border-accent/30 shadow-sm'
                  : 'bg-surface-raised text-text-muted border-border hover:border-accent/20 hover:text-text'
                }`}
            >
              <ProviderIconSvg prefix={remoteTypes[remote] ?? ''} size={14} />
              {remote}
            </button>
          ))
        )}
      </div>

      {/* Divider */}
      <div className="h-px bg-border flex-shrink-0" />

      {/* Results area */}
      <div className="flex-1 overflow-y-auto min-h-0">
        {/* Empty states */}
        {!isSearching && !error && !query && results.length === 0 && (
          <div className="flex flex-col items-center justify-center h-full text-text-muted">
            <Search size={48} className="mb-4 opacity-20" />
            <p className="text-sm">{t('search.emptyHint')}</p>
            <p className="text-xs mt-1 opacity-60">{t('search.emptyDesc')}</p>
          </div>
        )}

        {!isSearching && !error && query && results.length === 0 && (
          <div className="flex flex-col items-center justify-center h-full text-text-muted">
            <Search size={40} className="mb-3 opacity-20" />
            <p className="text-sm">{t('search.noResults')} "{query}"</p>
          </div>
        )}

        {isSearching && results.length === 0 && (
          <div className="flex flex-col items-center justify-center h-full text-text-muted">
            <Loader2 size={32} className="mb-4 animate-spin text-accent" />
            <p className="text-sm">{t('search.searching')}</p>
          </div>
        )}

        {error && (
          <div className="flex items-center justify-center h-full">
            <p className="text-sm text-danger">{error}</p>
          </div>
        )}

        {/* Data table */}
        {results.length > 0 && (
          <table className="w-full text-xs">
            <thead className="sticky top-0 z-10 bg-surface-raised border-b border-border">
              <tr>
                <th className="text-left px-4 py-2.5 font-semibold text-text-muted">
                  <button onClick={() => handleSort('Name')} className="flex items-center gap-1 hover:text-text transition-colors">
                    {t('search.colName')} <SortIcon col="Name" />
                  </button>
                </th>
                <th className="text-left px-3 py-2.5 font-semibold text-text-muted w-[140px]">
                  <button onClick={() => handleSort('RemoteFs')} className="flex items-center gap-1 hover:text-text transition-colors">
                    {t('search.colCloud')} <SortIcon col="RemoteFs" />
                  </button>
                </th>
                <th className="text-right px-3 py-2.5 font-semibold text-text-muted w-[90px]">
                  <button onClick={() => handleSort('Size')} className="flex items-center gap-1 justify-end hover:text-text transition-colors">
                    {t('search.colSize')} <SortIcon col="Size" />
                  </button>
                </th>
                <th className="text-left px-3 py-2.5 font-semibold text-text-muted w-[140px]">
                  <button onClick={() => handleSort('ModTime')} className="flex items-center gap-1 hover:text-text transition-colors">
                    {t('search.colDate')} <SortIcon col="ModTime" />
                  </button>
                </th>
                <th className="text-left px-3 py-2.5 font-semibold text-text-muted">
                  <button onClick={() => handleSort('Path')} className="flex items-center gap-1 hover:text-text transition-colors">
                    {t('search.colFolder')} <SortIcon col="Path" />
                  </button>
                </th>
              </tr>
            </thead>
            <tbody>
              {sortedResults.map((file, idx) => (
                <tr
                  key={`${file.RemoteFs}-${file.Path}-${idx}`}
                  onClick={() => handleResultClick(file.RemoteFs, file.Path, file.IsDir)}
                  className="hover:bg-surface-overlay cursor-pointer transition-colors border-b border-border/50 group"
                >
                  <td className="px-4 py-2.5">
                    <div className="flex items-center gap-2.5">
                      <span className="text-text-muted group-hover:text-accent transition-colors flex-shrink-0">
                        {file.IsDir ? <Folder size={16} className="fill-current opacity-30" /> : <FileIcon size={16} />}
                      </span>
                      <span className="text-text font-medium truncate">{file.Name}</span>
                    </div>
                  </td>
                  <td className="px-3 py-2.5">
                    <div className="flex items-center gap-1.5">
                      <ProviderIconSvg prefix={remoteTypes[file.RemoteFs] ?? ''} size={14} className="flex-shrink-0" />
                      <span className="text-text-muted truncate">{file.RemoteFs}</span>
                    </div>
                  </td>
                  <td className="px-3 py-2.5 text-right text-text-muted tabular-nums">
                    {file.IsDir ? '—' : formatSize(file.Size)}
                  </td>
                  <td className="px-3 py-2.5 text-text-muted tabular-nums">
                    {formatDate(file.ModTime)}
                  </td>
                  <td className="px-3 py-2.5">
                    <span className="text-text-muted truncate block max-w-[200px]" title={getFolderPath(file.Path)}>
                      {getFolderPath(file.Path)}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}

        {/* Result count */}
        {results.length > 0 && (
          <div className="px-5 py-2 text-[11px] text-text-muted border-t border-border bg-surface-raised sticky bottom-0">
            {results.length}{t('search.resultCount')}
            {isSearching && <Loader2 size={10} className="inline-block ml-2 animate-spin" />}
          </div>
        )}
      </div>
    </div>
  );
}
