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
