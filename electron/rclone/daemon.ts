import { ChildProcess, spawn } from 'child_process';
import { resolveRcloneBinary, RcloneBinaryInfo } from './binary';
import { RcloneApiClient } from './api';

const RC_ADDR = 'localhost:5572';

export class RcloneDaemon {
  private process: ChildProcess | null = null;
  private binaryInfo: RcloneBinaryInfo | null = null;
  private _api: RcloneApiClient;

  constructor() {
    this._api = new RcloneApiClient(`http://${RC_ADDR}`);
  }

  get api(): RcloneApiClient {
    return this._api;
  }

  get info(): RcloneBinaryInfo | null {
    return this.binaryInfo;
  }

  async start(): Promise<void> {
    if (this.process) return;

    this.binaryInfo = resolveRcloneBinary();
    console.log(`Using rclone: ${this.binaryInfo.path} (${this.binaryInfo.source}, v${this.binaryInfo.version})`);

    this.process = spawn(this.binaryInfo.path, [
      'rcd',
      '--rc-no-auth',
      `--rc-addr=${RC_ADDR}`,
      '--rc-allow-origin=*',
    ], {
      stdio: ['ignore', 'pipe', 'pipe'],
    });

    this.process.stdout?.on('data', (data: Buffer) => {
      console.log(`[rclone] ${data.toString().trim()}`);
    });

    this.process.stderr?.on('data', (data: Buffer) => {
      console.log(`[rclone] ${data.toString().trim()}`);
    });

    this.process.on('close', (code) => {
      console.log(`rclone daemon exited with code ${code}`);
      this.process = null;
    });

    // Wait for daemon to be ready
    await this.waitForReady();
  }

  stop(): void {
    if (this.process) {
      this.process.kill('SIGTERM');
      this.process = null;
    }
  }

  private async waitForReady(maxRetries = 30): Promise<void> {
    for (let i = 0; i < maxRetries; i++) {
      try {
        await this._api.call('rc/noop', {});
        console.log('rclone daemon is ready');
        return;
      } catch {
        await new Promise((r) => setTimeout(r, 200));
      }
    }
    throw new Error('rclone daemon failed to start within timeout');
  }
}
