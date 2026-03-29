import { create } from 'zustand';

export type PanelMode = 'local' | 'cloud';

export interface TabState {
  id: string;
  label: string;
  mode: PanelMode;
  remote: string;
  path: string;
  files: RcloneFile[];
  loading: boolean;
  error: string | null;
  selectedFiles: Set<string>;
  sortBy: 'name' | 'size' | 'date';
  sortAsc: boolean;
}

// PanelState is now the active tab — kept for backward compat
export type PanelState = TabState;

export interface SideState {
  tabs: TabState[];
  activeTabId: string;
}

function makeTab(mode: PanelMode, remote: string, path: string, label: string): TabState {
  return {
    id: crypto.randomUUID(),
    label,
    mode,
    remote,
    path,
    files: [],
    loading: false,
    error: null,
    selectedFiles: new Set(),
    sortBy: 'name',
    sortAsc: true,
  };
}

const leftInit: SideState = (() => {
  const tab = makeTab('local', '/', '', '내 PC');
  return { tabs: [tab], activeTabId: tab.id };
})();

const rightInit: SideState = (() => {
  const tab = makeTab('cloud', '', '', '클라우드');
  return { tabs: [tab], activeTabId: tab.id };
})();

function getActiveTab(side: SideState): TabState {
  return side.tabs.find((t) => t.id === side.activeTabId) ?? side.tabs[0];
}

function updateActiveTab(side: SideState, updater: (tab: TabState) => TabState): SideState {
  return {
    ...side,
    tabs: side.tabs.map((t) => (t.id === side.activeTabId ? updater(t) : t)),
  };
}

interface DualPanelStore {
  // Raw side states with tabs
  leftSide: SideState;
  rightSide: SideState;

  // Convenience: returns active tab as PanelState
  left: PanelState;
  right: PanelState;

  activePanel: 'left' | 'right';
  remotes: string[];
  remotesLoading: boolean;

  setActivePanel: (side: 'left' | 'right') => void;
  setRemote: (side: 'left' | 'right', remote: string) => void;
  setPath: (side: 'left' | 'right', path: string) => void;
  setFiles: (side: 'left' | 'right', files: RcloneFile[]) => void;
  setLoading: (side: 'left' | 'right', loading: boolean) => void;
  setError: (side: 'left' | 'right', error: string | null) => void;
  toggleSelect: (side: 'left' | 'right', name: string) => void;
  selectAll: (side: 'left' | 'right') => void;
  clearSelection: (side: 'left' | 'right') => void;
  setSort: (side: 'left' | 'right', sortBy: 'name' | 'size' | 'date') => void;
  setRemotes: (remotes: string[]) => void;
  setRemotesLoading: (loading: boolean) => void;

  // Tab operations
  addTab: (side: 'left' | 'right', mode: PanelMode, remote: string, path: string, label: string) => void;
  closeTab: (side: 'left' | 'right', tabId: string) => void;
  switchTab: (side: 'left' | 'right', tabId: string) => void;
}

const sideKey = (side: 'left' | 'right') => (side === 'left' ? 'leftSide' : 'rightSide');

function recompute(state: { leftSide: SideState; rightSide: SideState }) {
  return {
    left: getActiveTab(state.leftSide),
    right: getActiveTab(state.rightSide),
  };
}

export const usePanelStore = create<DualPanelStore>((set) => ({
  leftSide: leftInit,
  rightSide: rightInit,
  left: getActiveTab(leftInit),
  right: getActiveTab(rightInit),
  activePanel: 'left',
  remotes: [],
  remotesLoading: false,

  setActivePanel: (side) => set({ activePanel: side }),

  setRemote: (side, remote) =>
    set((s) => {
      const key = sideKey(side);
      const updated = updateActiveTab(s[key], (t) => ({
        ...t,
        mode: remote === '/' ? 'local' : 'cloud',
        remote,
        path: '',
        files: [],
        selectedFiles: new Set(),
        error: null,
        label: remote === '/' ? '내 PC' : remote === '' ? '클라우드' : remote,
      }));
      const next = { ...s, [key]: updated };
      return { ...next, ...recompute(next) };
    }),

  setPath: (side, path) =>
    set((s) => {
      const key = sideKey(side);
      const updated = updateActiveTab(s[key], (t) => ({ ...t, path, selectedFiles: new Set() }));
      const next = { ...s, [key]: updated };
      return { ...next, ...recompute(next) };
    }),

  setFiles: (side, files) =>
    set((s) => {
      const key = sideKey(side);
      const updated = updateActiveTab(s[key], (t) => ({ ...t, files, loading: false, error: null }));
      const next = { ...s, [key]: updated };
      return { ...next, ...recompute(next) };
    }),

  setLoading: (side, loading) =>
    set((s) => {
      const key = sideKey(side);
      const updated = updateActiveTab(s[key], (t) => ({ ...t, loading }));
      const next = { ...s, [key]: updated };
      return { ...next, ...recompute(next) };
    }),

  setError: (side, error) =>
    set((s) => {
      const key = sideKey(side);
      const updated = updateActiveTab(s[key], (t) => ({ ...t, error, loading: false }));
      const next = { ...s, [key]: updated };
      return { ...next, ...recompute(next) };
    }),

  toggleSelect: (side, name) =>
    set((s) => {
      const key = sideKey(side);
      const updated = updateActiveTab(s[key], (t) => {
        const newSet = new Set(t.selectedFiles);
        if (newSet.has(name)) newSet.delete(name); else newSet.add(name);
        return { ...t, selectedFiles: newSet };
      });
      const next = { ...s, [key]: updated };
      return { ...next, ...recompute(next) };
    }),

  selectAll: (side) =>
    set((s) => {
      const key = sideKey(side);
      const updated = updateActiveTab(s[key], (t) => ({
        ...t, selectedFiles: new Set(t.files.map((f) => f.Name)),
      }));
      const next = { ...s, [key]: updated };
      return { ...next, ...recompute(next) };
    }),

  clearSelection: (side) =>
    set((s) => {
      const key = sideKey(side);
      const updated = updateActiveTab(s[key], (t) => ({ ...t, selectedFiles: new Set() }));
      const next = { ...s, [key]: updated };
      return { ...next, ...recompute(next) };
    }),

  setSort: (side, sortBy) =>
    set((s) => {
      const key = sideKey(side);
      const updated = updateActiveTab(s[key], (t) => {
        const sortAsc = t.sortBy === sortBy ? !t.sortAsc : true;
        return { ...t, sortBy, sortAsc };
      });
      const next = { ...s, [key]: updated };
      return { ...next, ...recompute(next) };
    }),

  setRemotes: (remotes) => set({ remotes }),
  setRemotesLoading: (loading) => set({ remotesLoading: loading }),

  // --- Tab operations ---
  addTab: (side, mode, remote, path, label) =>
    set((s) => {
      const key = sideKey(side);
      const newTab = makeTab(mode, remote, path, label);
      const sideState = { ...s[key], tabs: [...s[key].tabs, newTab], activeTabId: newTab.id };
      const next = { ...s, [key]: sideState };
      return { ...next, ...recompute(next) };
    }),

  closeTab: (side, tabId) =>
    set((s) => {
      const key = sideKey(side);
      const sideState = s[key];
      if (sideState.tabs.length <= 1) return s; // Don't close last tab
      const newTabs = sideState.tabs.filter((t) => t.id !== tabId);
      const activeTabId = sideState.activeTabId === tabId
        ? newTabs[Math.max(0, sideState.tabs.findIndex((t) => t.id === tabId) - 1)].id
        : sideState.activeTabId;
      const updated = { tabs: newTabs, activeTabId };
      const next = { ...s, [key]: updated };
      return { ...next, ...recompute(next) };
    }),

  switchTab: (side, tabId) =>
    set((s) => {
      const key = sideKey(side);
      const updated = { ...s[key], activeTabId: tabId };
      const next = { ...s, [key]: updated };
      return { ...next, ...recompute(next) };
    }),
}));
