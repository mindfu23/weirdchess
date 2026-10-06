/**
 * Run a classic (Lambda-style) handler as a Netlify Functions v2 function.
 *
 * Why: the AI gate's daily counter needs strongly consistent Netlify Blobs reads, which are only
 * available to v2 functions (Lambda-compat functions get a cached edge URL only, so back-to-back
 * calls would read a stale count). Wrapping keeps each handler's code unchanged.
 *
 *   export default asV2(handler);   // instead of: export { handler };
 */

import type { Handler, HandlerContext, HandlerEvent, HandlerResponse } from '@netlify/functions';

export function asV2(handler: Handler) {
  return async (req: Request): Promise<Response> => {
    const url = new URL(req.url);
    const headers: Record<string, string> = {};
    req.headers.forEach((value, key) => {
      headers[key] = value;
    });

    const event = {
      httpMethod: req.method,
      headers,
      multiValueHeaders: {},
      body: req.method === 'GET' || req.method === 'HEAD' ? null : await req.text(),
      isBase64Encoded: false,
      path: url.pathname,
      rawUrl: req.url,
      rawQuery: url.search.slice(1),
      queryStringParameters: Object.fromEntries(url.searchParams),
      multiValueQueryStringParameters: null,
    } as unknown as HandlerEvent;

    const res = (await handler(event, {} as HandlerContext, () => {})) as HandlerResponse | void;
    if (!res) return new Response(null, { status: 204 });

    const out = new Headers();
    for (const [key, value] of Object.entries(res.headers ?? {})) out.set(key, String(value));
    for (const [key, values] of Object.entries(res.multiValueHeaders ?? {})) {
      for (const value of values) out.append(key, String(value));
    }
    const body = res.isBase64Encoded && res.body ? Buffer.from(res.body, 'base64') : res.body;
    // 204/205/304 must have a null body: new Response('', { status: 204 }) throws (a 502 to the caller).
    const nullBodyStatus = [204, 205, 304].includes(res.statusCode);
    return new Response(nullBodyStatus ? null : body ?? null, { status: res.statusCode, headers: out });
  };
}
