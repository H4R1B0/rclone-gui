/// <reference types="vite/client" />

interface RcloneAPI {
  // system
  getHomeDir: () => Promise<string>;

  // rclone binary
  getRcloneVersion: () => Promise<{ version: string; path: string; source: 'system' | 'bundled' }>;

  // config / remotes
  listRemotes: () => Promise<string[]>;
  getRemoteConfig: (name: string) => Promise<Record<string, string>>;
  createRemote: (name: string, type: string, params: Record<string, string>) => Promise<void>;
  deleteRemote: (name: string) => Promise<void>;
  getProviders: () => Promise<RcloneProvider[]>;

  // file operations
  listFiles: (fs: string, remote: string) => Promise<RcloneFile[]>;
  mkdir: (fs: string, remote: string) => Promise<void>;
  deleteFile: (fs: string, remote: string) => Promise<void>;
  deleteDir: (fs: string, remote: string) => Promise<void>;
  copyFile: (srcFs: string, srcRemote: string, dstFs: string, dstRemote: string) => Promise<{ jobid: number }>;
  moveFile: (srcFs: string, srcRemote: string, dstFs: string, dstRemote: string) => Promise<{ jobid: number }>;
  copyDir: (srcFs: string, srcRemote: string, dstFs: string, dstRemote: string) => Promise<{ jobid: number }>;
  moveDir: (srcFs: string, srcRemote: string, dstFs: string, dstRemote: string) => Promise<{ jobid: number }>;
  renameFile: (fs: string, oldName: string, newName: string) => Promise<void>;
  getAbout: (fs: string) => Promise<RcloneAbout | null>;

  // transfers
  getStats: () => Promise<RcloneStats>;
  getJobList: () => Promise<{ jobids: number[] }>;
  stopJob: (jobid: number) => Promise<void>;
  getJobStatus: (jobid: number) => Promise<RcloneJobStatus>;
  setBwLimit: (rate: string) => Promise<{ bytesPerSecond: number; rate: string }>;
  getTransferred: () => Promise<{ transferred: RcloneCompletedTransfer[] }>;
  resetStats: () => Promise<void>;

  // settings
  applyOptions: (opts: Record<string, unknown>) => Promise<void>;
  getOptions: () => Promise<Record<string, unknown>>;
  saveSettings: (settings: Record<string, unknown>) => Promise<void>;
  loadSettings: () => Promise<Record<string, unknown> | null>;
}

interface RcloneProvider {
  Name: string;
  Description: string;
  Prefix: string;
}

interface RcloneFile {
  Path: string;
  Name: string;
  Size: number;
  MimeType: string;
  ModTime: string;
  IsDir: boolean;
  ID?: string;
}

interface RcloneAbout {
  total?: number;
  used?: number;
  free?: number;
  trashed?: number;
}

interface RcloneStats {
  bytes: number;
  checks: number;
  deletedDirs: number;
  deletes: number;
  elapsedTime: number;
  errors: number;
  eta?: number;
  fatalError: boolean;
  renames: number;
  retryError: boolean;
  speed: number;
  totalBytes: number;
  totalChecks: number;
  totalTransfers: number;
  transferring?: RcloneTransferring[];
  transfers: number;
}

interface RcloneTransferring {
  bytes: number;
  eta: number;
  group: string;
  name: string;
  percentage: number;
  size: number;
  speed: number;
  speedAvg: number;
}

interface RcloneJobStatus {
  duration: number;
  endTime: string;
  error: string;
  finished: boolean;
  group: string;
  id: number;
  startTime: string;
  success: boolean;
}

interface RcloneCompletedTransfer {
  name: string;
  size: number;
  bytes: number;
  checked: boolean;
  started_at: string;
  completed_at: string;
  error: string;
  group: string;
}

interface Window {
  rcloneAPI: RcloneAPI;
}
