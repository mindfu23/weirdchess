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
 *   "model": "claude-3-haiku-20240307" | "gpt-4o-mini" | "gemini-1.5-flash",
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

const PROVIDER_CONFIGS = {
  anthropic: {
    url: 'https://api.anthropic.com/v1/messages',
    envKey: 'ANTHROPIC_API_KEY',
    defaultModel: 'claude-3-haiku-20240307',
  },
  openai: {
    url: 'https://api.openai.com/v1/chat/completions',
    envKey: 'OPENAI_API_KEY',
    defaultModel: 'gpt-4o-mini',
  },
  google: {
    url: 'https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent',
    envKey: 'GOOGLE_API_KEY',
    defaultModel: 'gemini-1.5-flash',
  },
};

async function callAnthropic(apiKey, model, personality, prompt) {
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: model || 'claude-3-haiku-20240307',
      max_tokens: 150,
      system: personality,
      messages: [{ role: 'user', content: prompt }],
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Anthropic API error: ${response.status} - ${errorText}`);
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
      model: model || 'gpt-4o-mini',
      max_tokens: 150,
      messages: [
        { role: 'system', content: personality },
        { role: 'user', content: prompt },
      ],
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`OpenAI API error: ${response.status} - ${errorText}`);
  }

  const data = await response.json();
  return data.choices?.[0]?.message?.content || '';
}

async function callGoogle(apiKey, model, personality, prompt) {
  const modelName = model || 'gemini-1.5-flash';
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${apiKey}`;

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
    throw new Error(`Google API error: ${response.status} - ${errorText}`);
  }

  const data = await response.json();
  return data.candidates?.[0]?.content?.parts?.[0]?.text || '';
}

exports.handler = async (event, context) => {
  // CORS headers
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
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

    // Call the appropriate provider
    let commentary;
    switch (provider) {
      case 'anthropic':
        commentary = await callAnthropic(apiKey, model, personality, prompt);
        break;
      case 'openai':
        commentary = await callOpenAI(apiKey, model, personality, prompt);
        break;
      case 'google':
        commentary = await callGoogle(apiKey, model, personality, prompt);
        break;
      default:
        throw new Error(`Unknown provider: ${provider}`);
    }

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ commentary, variantId, provider }),
    };
  } catch (error) {
    console.error('Function error:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: error.message || 'Internal server error' }),
    };
  }
};
