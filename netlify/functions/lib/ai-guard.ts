/**
 * AI Guard: cost limits for Netlify functions that spend paid AI credit on behalf of the public.
 *
 * Copy this file (and v2-adapter.ts) into an app's netlify/functions/lib/. Then, at the top of each paid
 * function's handler:
 *
 *   const blocked = await aiGuard(event, { store: 'ai-usage' });
 *   if (blocked) return blocked;
 *
 * and export the function as v2: `export default asV2(handler);` (strongly consistent Blobs reads, which the
 * counters need, only work in v2 functions; Lambda-compat functions throw BlobsConsistencyError).
 *
 * What it enforces (all server-side; a browser or script can't skip it):
 *   - POST only, body size cap.
 *   - Per-visitor daily limit, keyed by Netlify's client IP (x-nf-client-connection-ip, which the caller
 *     can't set). The IP is hashed before storage.
 *   - Global daily cap across all visitors: the hard ceiling on what the function can spend per day.
 *   - Optional Origin allowlist for browser calls (a speed bump only: scripts can send any Origin).
 *
 * It fails closed: if the counters can't be read, the call is refused (503).
 * The model allowlist, fixed system prompt and input/output caps stay in each function, since they're
 * app-specific.
 *
 * Env overrides: AI_PER_IP_DAILY, AI_GLOBAL_DAILY (numbers).
 * Requires @netlify/blobs (8.x works on Node 20; 9+ needs Node 22).
 */

import { createHash } from 'crypto';
import { getStore } from '@netlify/blobs';
import type { HandlerEvent, HandlerResponse } from '@netlify/functions';

export interface AiGuardOptions {
  /** Netlify Blobs store name for the counters, e.g. 'ai-usage'. */
  store: string;
  /** Calls per visitor (IP) per UTC day. Default 20; env AI_PER_IP_DAILY overrides. */
  perIpDaily?: number;
  /** Calls per UTC day across everyone. Default 300; env AI_GLOBAL_DAILY overrides. */
  globalDaily?: number;
  /** Max request body in bytes. Default 20,000. */
  maxBodyBytes?: number;
  /** If set, browser requests whose Origin isn't listed are refused. Requests with no Origin (mobile apps,
   *  server-to-server) are allowed through to the caps. */
  allowedOrigins?: string[];
  /** Extra response headers (e.g. CORS for the allowed origin) to add to refusals. */
  headers?: Record<string, string>;
}

function reply(statusCode: number, body: Record<string, unknown>, headers: Record<string, string> = {}): HandlerResponse {
  return {
    statusCode,
    headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store', ...headers },
    body: JSON.stringify(body),
  };
}

function header(event: HandlerEvent, name: string): string {
  return event.headers[name] || event.headers[name.toLowerCase()] || '';
}

/** Netlify's view of the caller's IP. Never use x-forwarded-for's first entry: callers can set it. */
export function clientIp(event: HandlerEvent): string {
  return header(event, 'x-nf-client-connection-ip') || 'unknown';
}

/** Count one call. Returns 'ok', 'ip' (visitor limit hit), 'global' (daily cap hit) or 'error'. */
async function take(storeName: string, ip: string, perIp: number, global: number): Promise<'ok' | 'ip' | 'global' | 'error'> {
  try {
    const store = getStore({ name: storeName, consistency: 'strong' });
    const day = new Date().toISOString().slice(0, 10); // UTC day
    const ipKey = `${day}/ip/${createHash('sha256').update(ip).digest('hex').slice(0, 24)}`;
    const globalKey = `${day}/global`;
    const [ipUsed, globalUsed] = (await Promise.all([store.get(ipKey), store.get(globalKey)])).map(v => Number(v) || 0);
    if (globalUsed >= global) return 'global';
    if (ipUsed >= perIp) return 'ip';
    await Promise.all([store.set(ipKey, String(ipUsed + 1)), store.set(globalKey, String(globalUsed + 1))]);
    return 'ok';
  } catch (error) {
    console.error('[AI Guard] Usage counter unavailable:', error);
    return 'error';
  }
}

/**
 * Returns a response to send back when the call is refused, or null when it may go ahead.
 * Call it before any paid API call (and before any expensive work).
 */
export async function aiGuard(event: HandlerEvent, opts: AiGuardOptions): Promise<HandlerResponse | null> {
  const h = opts.headers ?? {};
  if (event.httpMethod !== 'POST') return reply(405, { error: 'Method not allowed' }, h);

  const maxBody = opts.maxBodyBytes ?? 20_000;
  if ((event.body?.length ?? 0) > maxBody) return reply(413, { error: `Request too large (max ${maxBody} bytes)` }, h);

  const origin = header(event, 'origin');
  if (opts.allowedOrigins && origin && !opts.allowedOrigins.includes(origin)) {
    return reply(403, { error: 'Origin not allowed' }, h);
  }

  const perIp = Number(process.env.AI_PER_IP_DAILY) || opts.perIpDaily || 20;
  const global = Number(process.env.AI_GLOBAL_DAILY) || opts.globalDaily || 300;
  const result = await take(opts.store, clientIp(event), perIp, global);
  if (result === 'ip') return reply(429, { error: 'Daily limit reached for this visitor. Try again tomorrow.', code: 'ai_ip_cap' }, h);
  if (result === 'global') return reply(429, { error: 'Daily limit reached. Try again tomorrow.', code: 'ai_daily_cap' }, h);
  if (result === 'error') return reply(503, { error: 'Usage limits unavailable; try again shortly.' }, h);
  return null;
}
