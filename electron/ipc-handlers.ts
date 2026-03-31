import { IpcMain, BrowserWindow } from 'electron';
import { app, safeStorage, systemPreferences } from 'electron';
import { readFileSync, writeFileSync, existsSync, unlinkSync } from 'fs';
import path from 'path';
import { RcloneDaemon } from './rclone/daemon';

// Active search abort controllers
const activeSearches = new Map<string, { aborted: boolean }>();

export function registerIpcHandlers(ipcMain: IpcMain, daemon: RcloneDaemon) {
  const api = daemon.api;

  // --- system ---
  ipcMain.handle('system:homeDir', () => {
    return app.getPath('home');
  });

  ipcMain.handle('system:restart', () => {
    app.relaunch();
    app.exit(0);
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

  ipcMain.handle('rclone:searchFiles', async (_e, fs: string, query: string) => {
    const result = await api.call<{ list: unknown[] }>('operations/list', {
      fs, remote: '', 
      opt: { recurse: true },
      _filter: { AddRule: [`+ *${query}*`, `- *`] }
    });
    return result.list ?? [];
  });

  // --- streaming BFS search ---
  ipcMain.handle('rclone:searchStream', async (event, searchId: string, targets: string[], query: string) => {
    const control = { aborted: false };
    activeSearches.set(searchId, control);
    const sender = event.sender;
    const queryLower = query.toLowerCase();
    const CONCURRENCY = 5;

    const searchRemote = async (remoteName: string) => {
      if (control.aborted) return;
      const fsOpt = remoteName.endsWith(':') ? remoteName : `${remoteName}:`;
      // BFS queue: start from root
      const queue: string[] = [''];

      while (queue.length > 0 && !control.aborted) {
        // Process directories in batches for concurrency
        const batch = queue.splice(0, CONCURRENCY);
        const batchPromises = batch.map(async (dirPath) => {
          if (control.aborted) return;
          try {
            const result = await api.call<{ list: { Path: string; Name: string; Size: number; MimeType: string; ModTime: string; IsDir: boolean; ID?: string }[] }>('operations/list', {
              fs: fsOpt, remote: dirPath, opt: { recurse: false },
            });
            const items = result.list ?? [];
            const matchingFiles: unknown[] = [];

            for (const item of items) {
              if (control.aborted) break;
              if (item.IsDir) {
                // Queue subdirectory for BFS
                queue.push(item.Path);
                // Also check if dir name matches
                if (item.Name.toLowerCase().includes(queryLower)) {
                  matchingFiles.push({ ...item, RemoteFs: remoteName });
                }
              } else {
                // Check if filename matches
                if (item.Name.toLowerCase().includes(queryLower)) {
                  matchingFiles.push({ ...item, RemoteFs: remoteName });
                }
              }
            }

            // Send batch of matching results immediately
            if (matchingFiles.length > 0 && !control.aborted && !sender.isDestroyed()) {
              sender.send('search:results', searchId, matchingFiles);
            }
          } catch (err) {
            console.error(`Search error in ${fsOpt}:${dirPath}:`, err);
          }
        });
        await Promise.all(batchPromises);
      }
    };

    try {
      // Search all target remotes in parallel
      await Promise.all(targets.map(t => searchRemote(t)));
    } finally {
      activeSearches.delete(searchId);
      if (!sender.isDestroyed()) {
        sender.send('search:done', searchId);
      }
    }
  });

  ipcMain.handle('rclone:searchAbort', async (_e, searchId: string) => {
    const control = activeSearches.get(searchId);
    if (control) {
      control.aborted = true;
      activeSearches.delete(searchId);
    }
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
    return api.call('operations/copyfile', { srcFs, srcRemote, dstFs, dstRemote, _async: true });
  });

  ipcMain.handle('rclone:moveFile', async (_e, srcFs: string, srcRemote: string, dstFs: string, dstRemote: string) => {
    return api.call('operations/movefile', { srcFs, srcRemote, dstFs, dstRemote, _async: true });
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

  ipcMain.handle('rclone:getJobStatus', async (_e, jobid: number) => {
    return api.call('job/status', { jobid });
  });

  ipcMain.handle('rclone:setBwLimit', async (_e, rate: string) => {
    return api.call('core/bwlimit', { rate });
  });

  ipcMain.handle('rclone:getTransferred', async () => {
    return api.call('core/transferred');
  });

  ipcMain.handle('rclone:resetStats', async () => {
    return api.call('core/stats-reset');
  });

  ipcMain.handle('rclone:speedLimit', async (_e, rate: string) => {
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

  // --- app lock ---
  const lockPasswordPath = path.join(app.getPath('userData'), 'app-lock.enc');
  const lockConfigPath = path.join(app.getPath('userData'), 'app-lock-config.json');

  ipcMain.handle('appLock:setPassword', async (_e, password: string) => {
    if (!safeStorage.isEncryptionAvailable()) {
      throw new Error('Encryption is not available on this system');
    }
    const encrypted = safeStorage.encryptString(password);
    writeFileSync(lockPasswordPath, encrypted);
  });

  ipcMain.handle('appLock:verifyPassword', async (_e, password: string) => {
    if (!existsSync(lockPasswordPath)) return false;
    try {
      const encrypted = readFileSync(lockPasswordPath);
      const stored = safeStorage.decryptString(encrypted);
      return stored === password;
    } catch {
      return false;
    }
  });

  ipcMain.handle('appLock:removePassword', async () => {
    if (existsSync(lockPasswordPath)) {
      unlinkSync(lockPasswordPath);
    }
  });

  ipcMain.handle('appLock:hasPassword', async () => {
    return existsSync(lockPasswordPath);
  });

  ipcMain.handle('appLock:promptTouchID', async () => {
    try {
      await systemPreferences.promptTouchID('Rclone GUI 잠금 해제');
      return true;
    } catch {
      return false;
    }
  });

  ipcMain.handle('appLock:canUseTouchID', async () => {
    return systemPreferences.canPromptTouchID();
  });

  ipcMain.handle('appLock:getConfig', async () => {
    if (!existsSync(lockConfigPath)) return { appLockEnabled: false, useTouchID: false };
    try {
      return JSON.parse(readFileSync(lockConfigPath, 'utf-8'));
    } catch {
      return { appLockEnabled: false, useTouchID: false };
    }
  });

  ipcMain.handle('appLock:saveConfig', async (_e, config: { appLockEnabled: boolean; useTouchID: boolean }) => {
    writeFileSync(lockConfigPath, JSON.stringify(config, null, 2), 'utf-8');
  });
}
