/**
 * Health Check — WeirdChess
 *
 * GET /api/health          → cheap checks (frontend, model-liveness, key validity)
 * GET /api/health?deep=1   → additionally makes one real commentary round-trip
 *
 * Monitored by UptimeRobot with a keyword monitor on: "status":"healthy"
 *
 * WHY THE MODEL-LIVENESS CHECK EXISTS
 * On 2026-08-25 commentary broke on web, Android and iOS because
 * claude-3-haiku-20240307 had been retired: the provider answered 404 and the
 * proxy flattened it to "API error: 500".  A key-validity check would have
 * passed the whole time — the key was fine, the *model* was gone.  So this
 * endpoint asserts that the exact model ids the app ships with still appear in
 * each provider's live model list.
 */

const TIMEOUT_MS = 8000;

const APP_NAME = 'weirdchess';
const SITE = 'https://weirdchess.netlify.app';

// Must match the defaults in lib/services/config_service.dart and
// netlify/functions/chess-commentary.js.
const MODELS_IN_USE = {
  anthropic: 'claude-haiku-4-5-20251001',
  openai: 'gpt-4o-mini',
  google: 'gemini-2.5-flash',
};

function withTimeout(promise, ms, label) {
  return Promise.race([
    promise,
    new Promise((_, reject) =>
      setTimeout(() => reject(new Error(`${label} timed out after ${ms}ms`)), ms)
    ),
  ]);
}

/** The frontend actually serves the Flutter app, not a redirect or an error. */
async function checkFrontend() {
  const res = await fetch(SITE);
  if (!res.ok) throw new Error(`frontend returned ${res.status}`);
  const html = await res.text();
  if (!html.includes('flutter')) {
    throw new Error('frontend HTML does not look like the Flutter app');
  }
  return `${html.length} bytes`;
}

/**
 * The configured model id is still listed by the provider.
 * Catches model retirement, which is invisible to a key-validity check.
 */
async function checkModelLive(provider) {
  const wanted = MODELS_IN_USE[provider];

  let url;
  let headers = {};
  if (provider === 'anthropic') {
    const key = process.env.ANTHROPIC_API_KEY;
    if (!key) throw new Error('ANTHROPIC_API_KEY not set');
    url = 'https://api.anthropic.com/v1/models?limit=100';
    headers = { 'x-api-key': key, 'anthropic-version': '2023-06-01' };
  } else if (provider === 'openai') {
    const key = process.env.OPENAI_API_KEY;
    if (!key) throw new Error('OPENAI_API_KEY not set');
    url = 'https://api.openai.com/v1/models';
    headers = { Authorization: `Bearer ${key}` };
  } else {
    const key = process.env.GOOGLE_API_KEY;
    if (!key) throw new Error('GOOGLE_API_KEY not set');
    url = `https://generativelanguage.googleapis.com/v1beta/models?key=${key}&pageSize=200`;
  }

  const res = await fetch(url, { headers });
  if (!res.ok) {
    // A bad key shows up here as 401/403 — still a real failure worth alerting on.
    throw new Error(`${provider} model list returned ${res.status}`);
  }
  const data = await res.json();

  const ids =
    provider === 'google'
      ? (data.models || []).map((m) => String(m.name).replace(/^models\//, ''))
      : (data.data || []).map((m) => m.id);

  if (!ids.includes(wanted)) {
    throw new Error(
      `model "${wanted}" is NOT in ${provider}'s live model list — likely retired`
    );
  }
  return wanted;
}

/** End-to-end: a real commentary request through the proxy the app calls. */
async function checkCommentaryRoundTrip() {
  const headers = { 'Content-Type': 'application/json' };
  if (process.env.APP_SECRET_TOKEN) {
    headers['X-App-Token'] = process.env.APP_SECRET_TOKEN;
  }
  const res = await fetch(`${SITE}/.netlify/functions/chess-commentary`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      provider: 'anthropic',
      model: MODELS_IN_USE.anthropic,
      personality: 'You are a terse chess commentator.',
      prompt: 'White opens with e4. Reply in under ten words.',
      variantId: 'health-check',
    }),
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`commentary returned ${res.status}: ${text.slice(0, 200)}`);
  const data = JSON.parse(text);
  if (!data.commentary || !data.commentary.trim()) {
    throw new Error('commentary returned an empty string');
  }
  return data.commentary.slice(0, 60);
}

exports.handler = async (event) => {
  const deep = event.queryStringParameters?.deep === '1';
  const start = Date.now();

  const checks = [
    { name: 'frontend', run: checkFrontend },
    { name: 'model-anthropic', run: () => checkModelLive('anthropic') },
  ];
  if (process.env.OPENAI_API_KEY) {
    checks.push({ name: 'model-openai', run: () => checkModelLive('openai') });
  }
  if (process.env.GOOGLE_API_KEY) {
    checks.push({ name: 'model-google', run: () => checkModelLive('google') });
  }
  if (deep) {
    checks.push({ name: 'commentary-e2e', run: checkCommentaryRoundTrip });
  }

  const results = {};
  let passed = 0;

  await Promise.all(
    checks.map(async (check) => {
      const t0 = Date.now();
      try {
        const detail = await withTimeout(check.run(), TIMEOUT_MS, check.name);
        results[check.name] = { status: 'pass', detail, responseTime: Date.now() - t0 };
        passed++;
      } catch (err) {
        results[check.name] = {
          status: 'fail',
          error: err.message || String(err),
          responseTime: Date.now() - t0,
        };
      }
    })
  );

  const failed = checks.length - passed;
  // No silent all-clear: an unconfigured endpoint must never read as healthy.
  const status =
    checks.length === 0 ? 'unhealthy' : failed === 0 ? 'healthy' : failed < checks.length ? 'degraded' : 'unhealthy';

  return {
    statusCode: status === 'unhealthy' ? 503 : 200,
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Access-Control-Allow-Origin': '*',
    },
    body: JSON.stringify(
      {
        status,
        app: APP_NAME,
        timestamp: new Date().toISOString(),
        totalTime: Date.now() - start,
        checks: results,
        summary: `${passed}/${checks.length} checks passed`,
      },
      null,
      2
    ),
  };
};
