import { create } from 'zustand';

export interface PanelState {
  remote: string; // e.g. "gdrive:" or "" for home selector
  path: string;
  files: RcloneFile[];
  loading: boolean;
  error: string | null;
  selectedFiles: Set<string>;
  sortBy: 'name' | 'size' | 'date';
  sortAsc: boolean;
}

interface DualPanelStore {
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
}

const defaultPanel: PanelState = {
  remote: '',
  path: '',
  files: [],
  loading: false,
  error: null,
  selectedFiles: new Set(),
  sortBy: 'name',
  sortAsc: true,
};

export const usePanelStore = create<DualPanelStore>((set) => ({
  left: { ...defaultPanel },
  right: { ...defaultPanel },
  activePanel: 'left',
  remotes: [],
  remotesLoading: false,

  setActivePanel: (side) => set({ activePanel: side }),

  setRemote: (side, remote) =>
    set((s) => ({ [side]: { ...s[side], remote, path: '', files: [], selectedFiles: new Set(), error: null } })),

  setPath: (side, path) =>
    set((s) => ({ [side]: { ...s[side], path, selectedFiles: new Set() } })),

  setFiles: (side, files) =>
    set((s) => ({ [side]: { ...s[side], files, loading: false, error: null } })),

  setLoading: (side, loading) =>
    set((s) => ({ [side]: { ...s[side], loading } })),

  setError: (side, error) =>
    set((s) => ({ [side]: { ...s[side], error, loading: false } })),

  toggleSelect: (side, name) =>
    set((s) => {
      const panel = s[side];
      const newSet = new Set(panel.selectedFiles);
      if (newSet.has(name)) newSet.delete(name);
      else newSet.add(name);
      return { [side]: { ...panel, selectedFiles: newSet } };
    }),

  selectAll: (side) =>
    set((s) => {
      const panel = s[side];
      const newSet = new Set(panel.files.map((f) => f.Name));
      return { [side]: { ...panel, selectedFiles: newSet } };
    }),

  clearSelection: (side) =>
    set((s) => ({ [side]: { ...s[side], selectedFiles: new Set() } })),

  setSort: (side, sortBy) =>
    set((s) => {
      const panel = s[side];
      const sortAsc = panel.sortBy === sortBy ? !panel.sortAsc : true;
      return { [side]: { ...panel, sortBy, sortAsc } };
    }),

  setRemotes: (remotes) => set({ remotes }),
  setRemotesLoading: (loading) => set({ remotesLoading: loading }),
}));
