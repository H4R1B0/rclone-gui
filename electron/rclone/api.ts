import http from 'http';

export class RcloneApiClient {
  private baseUrl: string;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
  }

  async call<T = unknown>(endpoint: string, params: Record<string, unknown> = {}): Promise<T> {
    const url = `${this.baseUrl}/${endpoint}`;
    const body = JSON.stringify(params);

    return new Promise<T>((resolve, reject) => {
      const req = http.request(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(body),
        },
      }, (res) => {
        let data = '';
        res.on('data', (chunk) => { data += chunk; });
        res.on('end', () => {
          if (res.statusCode && res.statusCode >= 400) {
            try {
              const err = JSON.parse(data);
              reject(new Error(err.error || `rclone API error: ${res.statusCode}`));
            } catch {
              reject(new Error(`rclone API error: ${res.statusCode} ${data}`));
            }
            return;
          }
          try {
            resolve(data ? JSON.parse(data) as T : {} as T);
          } catch {
            resolve({} as T);
          }
        });
      });

      req.on('error', reject);
      req.write(body);
      req.end();
    });
  }
}
