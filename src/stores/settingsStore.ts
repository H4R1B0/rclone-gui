import { create } from 'zustand';

export interface RcloneSettings {
  transfers: number;
  checkers: number;
  multiThreadStreams: number;
  bufferSize: string;
  bwLimit: string;
  retries: number;
  lowLevelRetries: number;
  contimeout: string;
  timeout: string;
  userAgent: string;
  noCheckCertificate: boolean;
  ignoreExisting: boolean;
  ignoreSize: boolean;
  noTraverse: boolean;
  noUpdateModTime: boolean;
}

interface SettingsStore {
  settings: RcloneSettings;
  setSettings: (s: Partial<RcloneSettings>) => void;
  resetSettings: () => void;
}

const defaults: RcloneSettings = {
  transfers: 4,
  checkers: 8,
  multiThreadStreams: 4,
  bufferSize: '16M',
  bwLimit: '',
  retries: 3,
  lowLevelRetries: 10,
  contimeout: '60s',
  timeout: '300s',
  userAgent: '',
  noCheckCertificate: false,
  ignoreExisting: false,
  ignoreSize: false,
  noTraverse: false,
  noUpdateModTime: false,
};

export const defaultSettings = { ...defaults };

export const useSettingsStore = create<SettingsStore>((set) => ({
  settings: { ...defaults },
  setSettings: (s) => set((state) => ({ settings: { ...state.settings, ...s } })),
  resetSettings: () => set({ settings: { ...defaults } }),
}));
