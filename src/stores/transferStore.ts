import { create } from 'zustand';

export interface TransferItem {
  name: string;
  size: number;
  bytes: number;
  percentage: number;
  speed: number;
  eta: number;
  group: string;
}

export interface CompletedTransfer {
  name: string;
  size: number;
  error: string;
  completedAt: string;
  ok: boolean;
  group: string;
}

// Stopped transfers that can be restarted
export interface StoppedTransfer {
  name: string;
  group: string;
  size: number;
  srcFs?: string;
  srcRemote?: string;
  dstFs?: string;
  dstRemote?: string;
  isDir?: boolean;
}

// Track active copy origins so we can restart
export interface CopyOrigin {
  name: string;
  srcFs: string;
  srcRemote: string;
  dstFs: string;
  dstRemote: string;
  isDir: boolean;
}

interface TransferStore {
  transfers: TransferItem[];
  completed: CompletedTransfer[];
  stopped: StoppedTransfer[];
  copyOrigins: CopyOrigin[];
  jobIds: number[];
  totalSpeed: number;
  totalBytes: number;
  totalSize: number;
  totalTransfers: number;
  doneTransfers: number;
  errors: number;
  paused: boolean;
  polling: boolean;

  setStats: (stats: RcloneStats) => void;
  setJobIds: (ids: number[]) => void;
  addCompleted: (items: CompletedTransfer[]) => void;
  addStopped: (item: StoppedTransfer) => void;
  removeStopped: (group: string) => void;
  addCopyOrigin: (origin: CopyOrigin) => void;
  removeCopyOrigin: (name: string) => void;
  clearCompleted: () => void;
  clearStopped: () => void;
  setPaused: (p: boolean) => void;
  setPolling: (p: boolean) => void;
}

export const useTransferStore = create<TransferStore>((set) => ({
  transfers: [],
  completed: [],
  stopped: [],
  copyOrigins: [],
  jobIds: [],
  totalSpeed: 0,
  totalBytes: 0,
  totalSize: 0,
  totalTransfers: 0,
  doneTransfers: 0,
  errors: 0,
  paused: false,
  polling: false,

  setStats: (stats) =>
    set({
      transfers: (stats.transferring ?? []).map((t) => ({
        name: t.name,
        size: t.size,
        bytes: t.bytes,
        percentage: t.percentage,
        speed: t.speed,
        eta: t.eta,
        group: t.group,
      })),
      totalSpeed: stats.speed,
      totalBytes: stats.bytes,
      totalSize: stats.totalBytes,
      totalTransfers: stats.totalTransfers,
      doneTransfers: stats.transfers,
      errors: stats.errors,
    }),

  setJobIds: (ids) => set({ jobIds: ids }),

  addCompleted: (items) =>
    set((s) => ({
      completed: [...items, ...s.completed].slice(0, 200),
    })),

  addStopped: (item) =>
    set((s) => ({ stopped: [item, ...s.stopped] })),

  removeStopped: (group) =>
    set((s) => ({ stopped: s.stopped.filter((t) => t.group !== group) })),

  addCopyOrigin: (origin) =>
    set((s) => ({ copyOrigins: [...s.copyOrigins, origin] })),

  removeCopyOrigin: (name) =>
    set((s) => ({ copyOrigins: s.copyOrigins.filter((o) => o.name !== name) })),

  clearCompleted: () => set({ completed: [] }),
  clearStopped: () => set({ stopped: [] }),
  setPaused: (p) => set({ paused: p }),
  setPolling: (p) => set({ polling: p }),
}));
