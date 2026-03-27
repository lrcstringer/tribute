import { onRequest } from 'firebase-functions/v2/https';
import { IncomingMessage, ServerResponse } from 'http';
import app from './hono';

// Convert Firebase's Express-style req/res into a Fetch API Request,
// run it through the Hono app, and pipe the Response back out.
export const api = onRequest(
  { region: 'us-central1', memory: '512MiB', timeoutSeconds: 60 },
  async (req: IncomingMessage & { rawBody?: Buffer; url?: string; method?: string; hostname?: string; headers: Record<string, string | string[] | undefined> }, res: ServerResponse) => {
    const protocol = 'https';
    const host = (req.headers['host'] as string) ?? 'localhost';
    const url = `${protocol}://${host}${req.url ?? '/'}`;

    // Flatten multi-value headers for the Fetch API
    const headers = new Headers();
    for (const [key, value] of Object.entries(req.headers)) {
      if (value === undefined) continue;
      if (Array.isArray(value)) {
        for (const v of value) headers.append(key, v);
      } else {
        headers.set(key, value);
      }
    }

    const isBodyMethod = !['GET', 'HEAD'].includes((req.method ?? 'GET').toUpperCase());
    const fetchReq = new Request(url, {
      method: req.method ?? 'GET',
      headers,
      body: isBodyMethod && req.rawBody ? (req.rawBody as unknown as BodyInit) : undefined,
    });

    const fetchRes = await app.fetch(fetchReq);

    res.statusCode = fetchRes.status;
    fetchRes.headers.forEach((value: string, key: string) => {
      res.setHeader(key, value);
    });

    const body = await fetchRes.text();
    res.end(body);
  }
);
