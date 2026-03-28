import { IpcMain } from 'electron';
import { app } from 'electron';
import { readFileSync, writeFileSync, existsSync } from 'fs';
import path from 'path';
import { RcloneDaemon } from './rclone/daemon';

export function registerIpcHandlers(ipcMain: IpcMain, daemon: RcloneDaemon) {
  const api = daemon.api;

  // --- system ---
  ipcMain.handle('system:homeDir', () => {
    return app.getPath('home');
  });

  // --- rclone binary info ---
  ipcMain.handle('rclone:version', () => {
    const info = daemon.info;
    return info ? { version: info.version, path: info.path, source: info.source } : null;
  });

  // --- config / remotes ---
  ipcMain.handle('rclone:listRemotes', async () => {
    const result = await api.call<{ remotes: string[] }>('config/listremotes');
    return result.remotes ?? [];
  });

  ipcMain.handle('rclone:getRemoteConfig', async (_e, name: string) => {
    return api.call('config/get', { name });
  });

  ipcMain.handle('rclone:createRemote', async (_e, name: string, type: string, params: Record<string, string>) => {
    return api.call('config/create', { name, type, parameters: params });
  });

  ipcMain.handle('rclone:deleteRemote', async (_e, name: string) => {
    return api.call('config/delete', { name });
  });

  ipcMain.handle('rclone:getProviders', async () => {
    const result = await api.call<{ providers: unknown[] }>('config/providers');
    return result.providers ?? [];
  });

  // --- file operations ---
  ipcMain.handle('rclone:listFiles', async (_e, fs: string, remote: string) => {
    const result = await api.call<{ list: unknown[] }>('operations/list', {
      fs, remote, opt: { recurse: false },
    });
    return result.list ?? [];
  });

  ipcMain.handle('rclone:mkdir', async (_e, fs: string, remote: string) => {
    return api.call('operations/mkdir', { fs, remote });
  });

  ipcMain.handle('rclone:deleteFile', async (_e, fs: string, remote: string) => {
    return api.call('operations/deletefile', { fs, remote });
  });

  ipcMain.handle('rclone:deleteDir', async (_e, fs: string, remote: string) => {
    return api.call('operations/purge', { fs, remote });
  });

  ipcMain.handle('rclone:copyFile', async (_e, srcFs: string, srcRemote: string, dstFs: string, dstRemote: string) => {
    return api.call('operations/copyfile', { srcFs, srcRemote, dstFs, dstRemote });
  });

  ipcMain.handle('rclone:moveFile', async (_e, srcFs: string, srcRemote: string, dstFs: string, dstRemote: string) => {
    return api.call('operations/movefile', { srcFs, srcRemote, dstFs, dstRemote });
  });

  ipcMain.handle('rclone:copyDir', async (_e, srcFs: string, srcRemote: string, dstFs: string, dstRemote: string) => {
    return api.call('sync/copy', { srcFs: `${srcFs}${srcRemote}`, dstFs: `${dstFs}${dstRemote}`, _async: true });
  });

  ipcMain.handle('rclone:moveDir', async (_e, srcFs: string, srcRemote: string, dstFs: string, dstRemote: string) => {
    return api.call('sync/move', { srcFs: `${srcFs}${srcRemote}`, dstFs: `${dstFs}${dstRemote}`, _async: true });
  });

  ipcMain.handle('rclone:renameFile', async (_e, fs: string, oldName: string, newName: string) => {
    return api.call('operations/movefile', {
      srcFs: fs, srcRemote: oldName,
      dstFs: fs, dstRemote: newName,
    });
  });

  ipcMain.handle('rclone:getAbout', async (_e, fs: string) => {
    try {
      return await api.call('operations/about', { fs });
    } catch {
      return null;
    }
  });

  // --- transfers ---
  ipcMain.handle('rclone:getStats', async () => {
    return api.call('core/stats');
  });

  ipcMain.handle('rclone:getJobList', async () => {
    return api.call('job/list');
  });

  ipcMain.handle('rclone:stopJob', async (_e, jobid: number) => {
    return api.call('job/stop', { jobid });
  });

  ipcMain.handle('rclone:setBwLimit', async (_e, rate: string) => {
    return api.call('core/bwlimit', { rate });
  });

  // --- settings ---
  ipcMain.handle('rclone:applyOptions', async (_e, opts: Record<string, unknown>) => {
    // rclone rc options/set allows changing global options at runtime
    return api.call('options/set', { main: opts });
  });

  ipcMain.handle('rclone:getOptions', async () => {
    return api.call('options/get');
  });

  const settingsPath = path.join(app.getPath('userData'), 'rclone-gui-settings.json');

  ipcMain.handle('settings:save', async (_e, settings: Record<string, unknown>) => {
    writeFileSync(settingsPath, JSON.stringify(settings, null, 2), 'utf-8');
  });

  ipcMain.handle('settings:load', async () => {
    if (!existsSync(settingsPath)) return null;
    try {
      return JSON.parse(readFileSync(settingsPath, 'utf-8'));
    } catch {
      return null;
    }
  });
}
