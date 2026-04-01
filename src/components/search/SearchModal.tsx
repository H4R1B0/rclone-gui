import React, { useEffect, useRef } from 'react';
import { useSearchStore } from '../../stores/searchStore';
import { useSearch } from '../../hooks/useSearch';
import { usePanelStore } from '../../stores/panelStore';
import { usePanelFiles } from '../../hooks/useRclone';
import { Search, X, Loader2, Folder, File as FileIcon, Cloud } from 'lucide-react';

export function SearchModal() {
  const { 
    isOpen, query, isSearching, results, error, selectedClouds,
    setIsOpen, setQuery, toggleCloud, reset 
  } = useSearchStore();
  
  const { performSearch } = useSearch();
  const { remotes, navigateTo } = usePanelStore();
  const { loadFiles } = usePanelFiles('right');
  const inputRef = useRef<HTMLInputElement>(null);

  // Focus input when opened
  useEffect(() => {
    if (isOpen) {
      setTimeout(() => inputRef.current?.focus(), 100);
    } else {
      reset();
    }
  }, [isOpen, reset]);

  // Handle Cmd+F / Ctrl+F globally (you can also bind this in App.tsx)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Cmd/Ctrl + F
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'f') {
        e.preventDefault();
        setIsOpen(true);
      }
      if (e.key === 'Escape' && isOpen) {
        setIsOpen(false);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, setIsOpen]);

  if (!isOpen) return null;

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
    const fs = remoteFs.endsWith(':') ? remoteFs : `${remoteFs}:`;
    navigateTo('right', fs, dirPath);
    loadFiles(fs, dirPath);
    setIsOpen(false);
  };

  // cloud remotes
  const cloudRemotes = remotes.filter(r => r !== '/');

  return (
    <div className="fixed inset-0 z-[100] flex items-start justify-center pt-[10vh] bg-black/50 backdrop-blur-sm">
      <div className="bg-white dark:bg-zinc-900 w-full max-w-3xl rounded-xl shadow-2xl border border-zinc-200 dark:border-zinc-800 flex flex-col max-h-[80vh] overflow-hidden">
        
        {/* Header / Search Bar */}
        <form onSubmit={handleSearch} className="flex items-center px-4 border-b border-zinc-200 dark:border-zinc-800">
          <Search className="w-5 h-5 text-zinc-400 mr-3 shrink-0" />
          <input 
            ref={inputRef}
            type="text"
            className="flex-1 bg-transparent border-none outline-none py-4 text-lg text-zinc-900 dark:text-zinc-100 placeholder:text-zinc-400 focus:ring-0"
            placeholder="Search all connected clouds..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
          {query && (
            <button type="button" onClick={() => setQuery('')} className="p-1 mr-2 text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-200">
              <X className="w-4 h-4" />
            </button>
          )}
          <button type="submit" disabled={isSearching || !query} className="px-4 py-2 bg-blue-600 text-white rounded-md text-sm font-medium hover:bg-blue-700 disabled:opacity-50">
            {isSearching ? <Loader2 className="w-4 h-4 animate-spin" /> : 'Search'}
          </button>
          <button type="button" onClick={() => setIsOpen(false)} className="ml-3 p-2 border-l border-zinc-200 dark:border-zinc-800 text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-200">
            Esc
          </button>
        </form>

        {/* Cloud Filters */}
        <div className="flex px-4 py-2 gap-2 border-b border-zinc-100 dark:border-zinc-800 overflow-x-auto whitespace-nowrap bg-zinc-50 dark:bg-zinc-900/50" style={{ msOverflowStyle: 'none', scrollbarWidth: 'none' }}>
          <span className="text-xs font-semibold text-zinc-500 py-1 mr-2 uppercase tracking-wide flex items-center">Filters</span>
          {cloudRemotes.map(remote => (
            <button
              key={remote}
              type="button"
              onClick={() => toggleCloud(remote)}
              className={`px-3 py-1 rounded-full text-xs font-medium border flex items-center gap-1.5 transition-colors
                ${selectedClouds.includes(remote) 
                  ? 'bg-blue-100 text-blue-700 border-blue-200 dark:bg-blue-900/30 dark:text-blue-400 dark:border-blue-800' 
                  : 'bg-white text-zinc-600 border-zinc-200 hover:bg-zinc-50 dark:bg-zinc-800 dark:text-zinc-300 dark:border-zinc-700 hover:dark:bg-zinc-700'
                }`}
            >
              <Cloud className="w-3 h-3" />
              {remote}
            </button>
          ))}
          {cloudRemotes.length === 0 && (
            <span className="text-xs text-zinc-400 py-1">No cloud remotes configured</span>
          )}
        </div>

        {/* Results Area */}
        <div className="flex-1 overflow-y-auto p-2 min-h-[300px]">
          {error && (
            <div className="p-4 text-center text-red-500 text-sm">{error}</div>
          )}
          
          {!isSearching && !error && results.length === 0 && query && (
            <div className="py-16 flex flex-col items-center justify-center text-zinc-500">
               <Search className="w-10 h-10 mb-3 text-zinc-300 dark:text-zinc-700" />
              <p>No files found matching "{query}"</p>
            </div>
          )}

          {!isSearching && !error && !query && results.length === 0 && (
            <div className="py-16 flex flex-col items-center justify-center text-zinc-400">
              <Search className="w-12 h-12 mb-4 text-zinc-200 dark:text-zinc-800" />
              <p>Type a keyword to begin searching</p>
              <p className="text-xs mt-2 text-zinc-500">Results will be fetched from the selected clouds above.</p>
            </div>
          )}

          {isSearching && results.length === 0 && (
            <div className="py-16 flex flex-col items-center justify-center text-zinc-400">
              <Loader2 className="w-8 h-8 animate-spin mb-4 text-blue-500" />
              <p>Searching through clouds...</p>
            </div>
          )}

          <div className="space-y-1">
            {results.map((file, idx) => (
              <div 
                key={`${file.RemoteFs}-${file.Path}-${idx}`}
                onClick={() => handleResultClick(file.RemoteFs, file.Path, file.IsDir)}
                className="flex items-center p-3 rounded-lg hover:bg-zinc-100 dark:hover:bg-zinc-800/80 cursor-pointer group transition-colors"
                title={`${file.RemoteFs}:${file.Path}`}
              >
                <div className="mr-4 text-zinc-400 group-hover:text-blue-500 transition-colors">
                  {file.IsDir ? <Folder className="w-6 h-6 fill-current opacity-20" /> : <FileIcon className="w-6 h-6" />}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="text-sm font-medium text-zinc-900 dark:text-zinc-100 truncate">
                    {file.Name}
                  </div>
                  <div className="break-all text-[11px] text-zinc-500 flex items-center gap-2 mt-1">
                    <span className="inline-flex items-center py-0.5 px-1.5 rounded bg-zinc-200/50 dark:bg-zinc-700/50 text-zinc-600 dark:text-zinc-300 font-semibold uppercase tracking-wider text-[9px]">
                      {file.RemoteFs}
                    </span>
                    <span className="truncate opacity-75">{file.Path}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
