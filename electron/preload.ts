import { contextBridge, ipcRenderer } from 'electron';

contextBridge.exposeInMainWorld('rcloneAPI', {
  // system
  getHomeDir: () => ipcRenderer.invoke('system:homeDir'),
  restartApp: () => ipcRenderer.invoke('system:restart'),

  // rclone binary
  getRcloneVersion: () => ipcRenderer.invoke('rclone:version'),

  // config / remotes
  listRemotes: () => ipcRenderer.invoke('rclone:listRemotes'),
  getRemoteConfig: (name: string) => ipcRenderer.invoke('rclone:getRemoteConfig', name),
  createRemote: (name: string, type: string, params: Record<string, string>) =>
    ipcRenderer.invoke('rclone:createRemote', name, type, params),
  deleteRemote: (name: string) => ipcRenderer.invoke('rclone:deleteRemote', name),
  getProviders: () => ipcRenderer.invoke('rclone:getProviders'),

  // file operations
  listFiles: (fs: string, remote: string) => ipcRenderer.invoke('rclone:listFiles', fs, remote),
  mkdir: (fs: string, remote: string) => ipcRenderer.invoke('rclone:mkdir', fs, remote),
  deleteFile: (fs: string, remote: string) => ipcRenderer.invoke('rclone:deleteFile', fs, remote),
  deleteDir: (fs: string, remote: string) => ipcRenderer.invoke('rclone:deleteDir', fs, remote),
  copyFile: (srcFs: string, srcRemote: string, dstFs: string, dstRemote: string) =>
    ipcRenderer.invoke('rclone:copyFile', srcFs, srcRemote, dstFs, dstRemote),
  moveFile: (srcFs: string, srcRemote: string, dstFs: string, dstRemote: string) =>
    ipcRenderer.invoke('rclone:moveFile', srcFs, srcRemote, dstFs, dstRemote),
  copyDir: (srcFs: string, srcRemote: string, dstFs: string, dstRemote: string) =>
    ipcRenderer.invoke('rclone:copyDir', srcFs, srcRemote, dstFs, dstRemote),
  moveDir: (srcFs: string, srcRemote: string, dstFs: string, dstRemote: string) =>
    ipcRenderer.invoke('rclone:moveDir', srcFs, srcRemote, dstFs, dstRemote),
  renameFile: (fs: string, oldName: string, newName: string) =>
    ipcRenderer.invoke('rclone:renameFile', fs, oldName, newName),
  getAbout: (fs: string) => ipcRenderer.invoke('rclone:getAbout', fs),

  // transfers
  getStats: () => ipcRenderer.invoke('rclone:getStats'),
  getJobList: () => ipcRenderer.invoke('rclone:getJobList'),
  stopJob: (jobid: number) => ipcRenderer.invoke('rclone:stopJob', jobid),
  getJobStatus: (jobid: number) => ipcRenderer.invoke('rclone:getJobStatus', jobid),
  setBwLimit: (rate: string) => ipcRenderer.invoke('rclone:setBwLimit', rate),
  getTransferred: () => ipcRenderer.invoke('rclone:getTransferred'),
  resetStats: () => ipcRenderer.invoke('rclone:resetStats'),

  // settings
  applyOptions: (opts: Record<string, unknown>) => ipcRenderer.invoke('rclone:applyOptions', opts),
  getOptions: () => ipcRenderer.invoke('rclone:getOptions'),
  saveSettings: (settings: Record<string, unknown>) => ipcRenderer.invoke('settings:save', settings),
  loadSettings: () => ipcRenderer.invoke('settings:load'),

  // app lock
  appLockSetPassword: (password: string) => ipcRenderer.invoke('appLock:setPassword', password),
  appLockVerifyPassword: (password: string) => ipcRenderer.invoke('appLock:verifyPassword', password),
  appLockRemovePassword: () => ipcRenderer.invoke('appLock:removePassword'),
  appLockHasPassword: () => ipcRenderer.invoke('appLock:hasPassword'),
  appLockPromptTouchID: () => ipcRenderer.invoke('appLock:promptTouchID'),
  appLockCanUseTouchID: () => ipcRenderer.invoke('appLock:canUseTouchID'),
  appLockGetConfig: () => ipcRenderer.invoke('appLock:getConfig'),
  appLockSaveConfig: (config: { appLockEnabled: boolean; useTouchID: boolean }) => ipcRenderer.invoke('appLock:saveConfig', config),
});
