import { execFileSync } from 'child_process';
import { existsSync } from 'fs';
import { app } from 'electron';
import path from 'path';

export interface RcloneBinaryInfo {
  path: string;
  version: string;
  source: 'system' | 'bundled';
}

const MIN_VERSION = '1.60.0';

function parseVersion(versionStr: string): string {
  const match = versionStr.match(/v?(\d+\.\d+\.\d+)/);
  return match ? match[1] : '0.0.0';
}

function compareVersions(a: string, b: string): number {
  const pa = a.split('.').map(Number);
  const pb = b.split('.').map(Number);
  for (let i = 0; i < 3; i++) {
    if (pa[i] > pb[i]) return 1;
    if (pa[i] < pb[i]) return -1;
  }
  return 0;
}

function getRcloneVersion(binaryPath: string): string | null {
  try {
    const output = execFileSync(binaryPath, ['version'], {
      timeout: 5000,
      encoding: 'utf-8',
    });
    return parseVersion(output.split('\n')[0]);
  } catch {
    return null;
  }
}

function findSystemRclone(): string | null {
  try {
    const output = execFileSync('which', ['rclone'], {
      timeout: 3000,
      encoding: 'utf-8',
    }).trim();
    return output || null;
  } catch {
    return null;
  }
}

function getBundledRclonePath(): string {
  const resourcesPath = app.isPackaged
    ? path.join(process.resourcesPath, 'bin', 'rclone')
    : path.join(app.getAppPath(), 'resources', 'bin', 'rclone');
  return resourcesPath;
}

export function resolveRcloneBinary(): RcloneBinaryInfo {
  // 1. Try system rclone
  const systemPath = findSystemRclone();
  if (systemPath) {
    const version = getRcloneVersion(systemPath);
    if (version && compareVersions(version, MIN_VERSION) >= 0) {
      return { path: systemPath, version, source: 'system' };
    }
    // System rclone exists but version too low — fall through to bundled
    console.warn(`System rclone version ${version} is below minimum ${MIN_VERSION}, trying bundled.`);
  }

  // 2. Try bundled rclone
  const bundledPath = getBundledRclonePath();
  if (existsSync(bundledPath)) {
    const version = getRcloneVersion(bundledPath);
    if (version) {
      return { path: bundledPath, version, source: 'bundled' };
    }
  }

  // 3. Fall back to system rclone even if version is low
  if (systemPath) {
    const version = getRcloneVersion(systemPath) ?? 'unknown';
    return { path: systemPath, version, source: 'system' };
  }

  throw new Error(
    'rclone not found. Install rclone via "brew install rclone" or ensure the bundled binary exists.',
  );
}
