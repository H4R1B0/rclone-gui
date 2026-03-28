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
}

interface TransferStore {
  transfers: TransferItem[];
  completed: CompletedTransfer[];
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
  clearCompleted: () => void;
  setPaused: (p: boolean) => void;
  setPolling: (p: boolean) => void;
}

export const useTransferStore = create<TransferStore>((set) => ({
  transfers: [],
  completed: [],
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

  clearCompleted: () => set({ completed: [] }),
  setPaused: (p) => set({ paused: p }),
  setPolling: (p) => set({ polling: p }),
}));
