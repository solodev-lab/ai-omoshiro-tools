/**
 * Solara API — Cloudflare Worker
 * Endpoints: /astro/chart, /astro/predict, /search, /fortune, /health
 */
import { computeChart, computePredictions } from './astro.js';
import { searchPlace } from './search.js';

// ── CORS ──
const ALLOWED_ORIGINS = [
  'https://solodev-lab.github.io',
  'https://solodev-lab.com',
  'http://localhost',
  'http://127.0.0.1',
];

function getAllowedOrigin(request) {
  const origin = request.headers.get('Origin') || '';
  if (ALLOWED_ORIGINS.some(a => origin.startsWith(a))) return origin;
  return null;
}

function corsHeaders(origin) {
  return {
    'Access-Control-Allow-Origin': origin || '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Max-Age': '86400',
  };
}

// ── Rate Limit (memory-based) ──
const rateLimitMap = new Map();
const RATE_WINDOW = 60000;
const RATE_MAX = 30;

function checkRateLimit(ip) {
  const now = Date.now();
  const rec = rateLimitMap.get(ip);
  if (!rec || now - rec.start > RATE_WINDOW) {
    rateLimitMap.set(ip, { start: now, count: 1 });
    return true;
  }
  rec.count++;
  return rec.count <= RATE_MAX;
}

function cleanupRateLimit() {
  const now = Date.now();
  for (const [ip, rec] of rateLimitMap) {
    if (now - rec.start > RATE_WINDOW * 2) rateLimitMap.delete(ip);
  }
}

// ── JSON helpers ──
function jsonOk(data, origin) {
  return new Response(JSON.stringify(data), {
    headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) }
  });
}

function jsonError(status, message, origin) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) }
  });
}

// ── Main Handler ──
export default {
  async fetch(request, env) {
    cleanupRateLimit();
    const origin = getAllowedOrigin(request);
    const url = new URL(request.url);
    const path = url.pathname;

    // Preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders(origin) });
    }

    // Rate limit
    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
    if (!checkRateLimit(ip)) {
      return jsonError(429, 'Rate limit exceeded', origin);
    }

    try {
      // ── Health ──
      if (path === '/health') {
        return jsonOk({ status: 'ok', service: 'solara-api' }, origin);
      }

      // ── Astro Chart ──
      if (path === '/astro/chart' && request.method === 'POST') {
        const body = await request.json();
        if (!body.birthDate || !body.birthTime || body.birthLat == null || body.birthLng == null) {
          return jsonError(400, 'Missing required fields: birthDate, birthTime, birthLat, birthLng', origin);
        }
        const result = computeChart(body);
        return jsonOk(result, origin);
      }

      // ── Astro Predict ──
      if (path === '/astro/predict' && request.method === 'POST') {
        const body = await request.json();
        if (!body.birthDate || !body.birthTime) {
          return jsonError(400, 'Missing required fields: birthDate, birthTime', origin);
        }
        const result = computePredictions(body);
        return jsonOk(result, origin);
      }

      // ── Search ──
      if (path === '/search' && request.method === 'GET') {
        const q = url.searchParams.get('q');
        if (!q || q.length < 2) {
          return jsonError(400, 'Query parameter "q" required (min 2 chars)', origin);
        }
        const results = await searchPlace(q, env);
        return jsonOk(results, origin);
      }

      // ── Fortune (stub) ──
      if (path === '/fortune' && request.method === 'POST') {
        return jsonError(501, 'Fortune endpoint not yet implemented', origin);
      }

      return jsonError(404, 'Not found', origin);

    } catch (err) {
      console.error('Worker error:', err);
      return jsonError(500, err.message || 'Internal server error', origin);
    }
  }
};
