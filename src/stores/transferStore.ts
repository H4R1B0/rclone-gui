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

interface TransferStore {
  transfers: TransferItem[];
  totalSpeed: number;
  totalBytes: number;
  totalSize: number;
  errors: number;
  polling: boolean;

  setStats: (stats: RcloneStats) => void;
  setPolling: (p: boolean) => void;
}

export const useTransferStore = create<TransferStore>((set) => ({
  transfers: [],
  totalSpeed: 0,
  totalBytes: 0,
  totalSize: 0,
  errors: 0,
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
      errors: stats.errors,
    }),

  setPolling: (p) => set({ polling: p }),
}));
