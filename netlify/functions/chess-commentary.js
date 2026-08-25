/**
 * Netlify Function: chess-commentary
 *
 * Generates AI commentary for chess moves using multiple LLM providers.
 *
 * Environment Variables:
 * - ANTHROPIC_API_KEY: Anthropic API key
 * - OPENAI_API_KEY: OpenAI API key
 * - GOOGLE_API_KEY: Google AI API key
 *
 * Request Body:
 * {
 *   "provider": "anthropic" | "openai" | "google",
 *   "model": "claude-haiku-4-5-20251001" | "gpt-4o-mini" | "gemini-2.5-flash",
 *   "personality": "System prompt for the AI personality",
 *   "prompt": "The move description to comment on",
 *   "variantId": "jetan" | "grand_chess" | etc.
 * }
 *
 * Response:
 * {
 *   "commentary": "The AI's commentary on the move"
 * }
 */

// ---------------------------------------------------------------------------
// Rate limiting (in-memory, per function instance)
// Max RATE_LIMIT_MAX requests per RATE_LIMIT_WINDOW_MS from a single IP.
// ---------------------------------------------------------------------------
const RATE_LIMIT_MAX = 100;
const RATE_LIMIT_WINDOW_MS = 10 * 60 * 1000; // 10 minutes
const _rateLimitMap = new Map();

function checkRateLimit(ip) {
  const now = Date.now();
  const entry = _rateLimitMap.get(ip);

  if (!entry || now - entry.windowStart > RATE_LIMIT_WINDOW_MS) {
    _rateLimitMap.set(ip, { count: 1, windowStart: now });
    return true;
  }
  if (entry.count >= RATE_LIMIT_MAX) return false;
  entry.count++;
  return true;
}

const PROVIDER_CONFIGS = {
  anthropic: {
    url: 'https://api.anthropic.com/v1/messages',
    envKey: 'ANTHROPIC_API_KEY',
    defaultModel: 'claude-haiku-4-5-20251001',
  },
  openai: {
    url: 'https://api.openai.com/v1/chat/completions',
    envKey: 'OPENAI_API_KEY',
    defaultModel: 'gpt-4o-mini',
  },
  google: {
    url: 'https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent',
    envKey: 'GOOGLE_API_KEY',
    defaultModel: 'gemini-2.5-flash',
  },
};

// ---------------------------------------------------------------------------
// Retired-model remap.
//
// Shipped mobile binaries cannot be forced to update, and users may have an
// old model id saved in SharedPreferences.  Providers return 404 for a retired
// model id, so without this table every old client breaks permanently.
// Add a row here whenever a model is retired; never delete a row.
// ---------------------------------------------------------------------------
const RETIRED_MODELS = {
  'claude-3-haiku-20240307': 'claude-haiku-4-5-20251001',
  'claude-3-5-haiku-20241022': 'claude-haiku-4-5-20251001',
  'claude-3-sonnet-20240229': 'claude-sonnet-4-5-20250929',
  'claude-3-opus-20240229': 'claude-opus-4-1-20250805',
  'gemini-1.5-flash': 'gemini-2.5-flash',
  'gemini-1.5-pro': 'gemini-2.5-pro',
  'gemini-2.0-flash': 'gemini-2.5-flash',
};

function resolveModel(model, providerConfig) {
  if (!model) return providerConfig.defaultModel;
  const replacement = RETIRED_MODELS[model];
  if (replacement) {
    console.warn(`Remapped retired model ${model} -> ${replacement}`);
    return replacement;
  }
  return model;
}

// Errors thrown by the provider callers carry the upstream status so the
// handler can pass it through instead of flattening everything to a 500.
class UpstreamError extends Error {
  constructor(provider, status, body) {
    super(`${provider} API error: ${status} - ${body}`);
    this.status = status;
    this.upstreamBody = body;
  }
}

async function callAnthropic(apiKey, model, personality, prompt) {
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model,
      max_tokens: 150,
      system: personality,
      messages: [{ role: 'user', content: prompt }],
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new UpstreamError('Anthropic', response.status, errorText);
  }

  const data = await response.json();
  return data.content?.[0]?.text || '';
}

async function callOpenAI(apiKey, model, personality, prompt) {
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      max_tokens: 150,
      messages: [
        { role: 'system', content: personality },
        { role: 'user', content: prompt },
      ],
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new UpstreamError('OpenAI', response.status, errorText);
  }

  const data = await response.json();
  return data.choices?.[0]?.message?.content || '';
}

async function callGoogle(apiKey, model, personality, prompt) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      contents: [
        {
          parts: [{ text: `${personality}\n\n${prompt}` }],
        },
      ],
      generationConfig: {
        maxOutputTokens: 150,
      },
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new UpstreamError('Google', response.status, errorText);
  }

  const data = await response.json();
  return data.candidates?.[0]?.content?.parts?.[0]?.text || '';
}

exports.handler = async (event, context) => {
  // CORS headers
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-App-Token',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Content-Type': 'application/json',
  };

  // Handle preflight
  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 200, headers, body: '' };
  }

  // Only allow POST
  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers,
      body: JSON.stringify({ error: 'Method not allowed' }),
    };
  }

  // App-token validation — if APP_SECRET_TOKEN env var is set, all requests
  // must include the matching X-App-Token header.
  const expectedToken = process.env.APP_SECRET_TOKEN;
  if (expectedToken) {
    const sentToken = event.headers['x-app-token'] || event.headers['X-App-Token'];
    if (sentToken !== expectedToken) {
      return {
        statusCode: 403,
        headers,
        body: JSON.stringify({ error: 'Forbidden' }),
      };
    }
  }

  // IP-based rate limiting
  const clientIp =
    event.headers['x-forwarded-for']?.split(',')[0].trim() ||
    event.headers['client-ip'] ||
    'unknown';
  if (!checkRateLimit(clientIp)) {
    return {
      statusCode: 429,
      headers,
      body: JSON.stringify({ error: 'Rate limit exceeded — try again later' }),
    };
  }

  try {
    const body = JSON.parse(event.body);
    const { provider = 'anthropic', model, personality, prompt, variantId } = body;

    if (!prompt || !personality) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'Missing required fields: prompt, personality' }),
      };
    }

    // Get provider config
    const providerConfig = PROVIDER_CONFIGS[provider];
    if (!providerConfig) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: `Unknown provider: ${provider}` }),
      };
    }

    // Get API key from environment or Authorization header
    let apiKey = process.env[providerConfig.envKey];

    // Allow client to pass their own key via Authorization header
    const authHeader = event.headers.authorization || event.headers.Authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const clientKey = authHeader.substring(7);
      // Use client key if no server key is set, or always for client-provided keys
      if (!apiKey || clientKey !== apiKey) {
        apiKey = clientKey;
      }
    }

    if (!apiKey) {
      return {
        statusCode: 401,
        headers,
        body: JSON.stringify({ error: `API key not configured for provider: ${provider}` }),
      };
    }

    // Resolve the requested model, remapping retired ids so old clients work.
    const resolvedModel = resolveModel(model, providerConfig);

    // Call the appropriate provider
    let commentary;
    switch (provider) {
      case 'anthropic':
        commentary = await callAnthropic(apiKey, resolvedModel, personality, prompt);
        break;
      case 'openai':
        commentary = await callOpenAI(apiKey, resolvedModel, personality, prompt);
        break;
      case 'google':
        commentary = await callGoogle(apiKey, resolvedModel, personality, prompt);
        break;
      default:
        throw new Error(`Unknown provider: ${provider}`);
    }

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ commentary, variantId, provider, model: resolvedModel }),
    };
  } catch (error) {
    console.error('Function error:', error);
    // Pass provider failures through with their real status so a retired model
    // or a revoked key reads as 404/401 rather than an opaque 500.
    if (error instanceof UpstreamError) {
      return {
        statusCode: error.status,
        headers,
        body: JSON.stringify({
          error: error.message,
          upstreamStatus: error.status,
        }),
      };
    }
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: error.message || 'Internal server error' }),
    };
  }
};
