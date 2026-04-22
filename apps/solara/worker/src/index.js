/**
 * Solara API — Cloudflare Worker
 * Endpoints: /astro/chart, /astro/predict, /search, /fortune, /health
 */
import { computeChart, computePredictions, computeMonthEvents, computeForecast } from './astro.js';
import { searchPlace } from './search.js';
import { lookupTimezone } from './tzlookup.js';
import { handleFortune } from './fortune.js';

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

// ── Rate Limit (memory-based, per-endpoint) ──
// memory は CF Worker インスタンスローカル（cold start で消える）。
// /astro/forecast は計算コストが高いので厳しめ。
// 永続化は後段の KV 側で追加する（checkKvQuota）。
const rateLimitMap = new Map();
const RATE_WINDOW = 60000; // 1分
const RATE_DEFAULT_MAX = 30;
const RATE_FORECAST_MAX = 6;   // 1分あたり6req
const RATE_TILES_MAX = 600;    // 1分あたり600タイル（1ユーザーの地図操作を想定、5-10セッション/分）

function rateLimitKey(ip, bucket) { return `${bucket}:${ip}`; }

function checkRateLimit(ip, bucket, max) {
  const key = rateLimitKey(ip, bucket);
  const now = Date.now();
  const rec = rateLimitMap.get(key);
  if (!rec || now - rec.start > RATE_WINDOW) {
    rateLimitMap.set(key, { start: now, count: 1 });
    return true;
  }
  rec.count++;
  return rec.count <= max;
}

function cleanupRateLimit() {
  const now = Date.now();
  for (const [k, rec] of rateLimitMap) {
    if (now - rec.start > RATE_WINDOW * 2) rateLimitMap.delete(k);
  }
}

// ── KV-based monthly quota (per IP) ──
// FORECAST_KV が binding されていない環境では no-op。
// 月次で forecast の利用回数を制限する（デフォルト 60回/月）。
const FORECAST_MONTHLY_MAX = 60;

async function checkKvForecastQuota(env, ip) {
  if (!env || !env.FORECAST_KV) return { ok: true, remaining: -1 };
  const now = new Date();
  const ymKey = `fq:${ip}:${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, '0')}`;
  const prev = parseInt((await env.FORECAST_KV.get(ymKey)) || '0', 10);
  if (prev >= FORECAST_MONTHLY_MAX) {
    return { ok: false, remaining: 0 };
  }
  // 月末まで TTL（簡易: 45日）
  await env.FORECAST_KV.put(ymKey, String(prev + 1), { expirationTtl: 60 * 60 * 24 * 45 });
  return { ok: true, remaining: FORECAST_MONTHLY_MAX - (prev + 1) };
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

// ── Jawg Maps tile proxy ──
// クライアントから /tiles/jawg/<style>/<z>/<x>/<y>.png?lang=xx で来たリクエストを
// Jawg 公式 (https://tile.jawg.io/<style>/<z>/<x>/<y>.png?access-token=SECRET&lang=xx) に
// 中継する。トークンは env.JAWG_TOKEN（wrangler secret put JAWG_TOKEN で設定）。
//
// - 許可スタイル/言語は allowlist で制限（URL 書き換えによる悪用防止）
// - Z/X/Y は整数のみ受け付け
// - Cloudflare edge cache を活用し、Jawg 使用量を抑える（24時間キャッシュ）
const JAWG_ALLOWED_STYLES = new Set([
  'jawg-streets',
  'jawg-dark',
  'jawg-light',
  'jawg-sunny',
  'jawg-terrain',
  'jawg-matrix',
  'jawg-lagoon',
]);
const JAWG_ALLOWED_LANGS = new Set([
  'ja', 'en', 'de', 'es', 'fr', 'it', 'ko', 'nl', 'ru', 'zh',
]);

async function handleJawgTile(request, url, env) {
  if (!env || !env.JAWG_TOKEN) {
    return new Response('Jawg token not configured', { status: 503 });
  }

  // /tiles/jawg/<style>/<z>/<x>/<y>.png を分解
  const prefix = '/tiles/jawg/';
  const rest = url.pathname.slice(prefix.length); // e.g. "jawg-streets/14/7234/5928.png"
  const parts = rest.split('/');
  if (parts.length !== 4) {
    return new Response('Bad tile path', { status: 400 });
  }
  const [style, zStr, xStr, yWithExt] = parts;

  if (!JAWG_ALLOWED_STYLES.has(style)) {
    return new Response('Style not allowed', { status: 400 });
  }

  // y 部分は "{number}.png" 形式
  const yMatch = yWithExt.match(/^(\d+)\.png$/);
  if (!yMatch || !/^\d+$/.test(zStr) || !/^\d+$/.test(xStr)) {
    return new Response('Bad tile coordinates', { status: 400 });
  }
  const z = parseInt(zStr, 10);
  const x = parseInt(xStr, 10);
  const y = parseInt(yMatch[1], 10);
  if (z < 0 || z > 22) {
    return new Response('Zoom out of range', { status: 400 });
  }

  const lang = url.searchParams.get('lang') || 'ja';
  if (!JAWG_ALLOWED_LANGS.has(lang)) {
    return new Response('Language not allowed', { status: 400 });
  }

  const target =
    `https://tile.jawg.io/${style}/${z}/${x}/${y}.png` +
    `?access-token=${encodeURIComponent(env.JAWG_TOKEN)}&lang=${lang}`;

  // Cloudflare edge cache を利用（24時間）
  const cache = caches.default;
  const cacheKey = new Request(
    `https://tile-cache/${style}/${z}/${x}/${y}/${lang}`,
    { method: 'GET' },
  );
  let cached = await cache.match(cacheKey);
  if (cached) return cached;

  const upstream = await fetch(target, {
    // Jawg の CDN に直接。User-Agent はデフォルトでよい。
    cf: { cacheTtl: 86400, cacheEverything: true },
  });
  if (!upstream.ok) {
    return new Response(`Upstream error: ${upstream.status}`, {
      status: upstream.status,
    });
  }

  // 返却用レスポンスを複製し、明示的にキャッシュヘッダを付与
  const headers = new Headers(upstream.headers);
  headers.set('Cache-Control', 'public, max-age=86400, immutable');
  // クライアント側（flutter_map の HTTP キャッシュ）にも効かせる
  const body = await upstream.arrayBuffer();
  const response = new Response(body, {
    status: 200,
    headers: {
      'Content-Type': headers.get('Content-Type') || 'image/png',
      'Cache-Control': 'public, max-age=86400, immutable',
    },
  });

  // edge cache へ保存（async で待たない）
  try { await cache.put(cacheKey, response.clone()); } catch (_) { /* ignore */ }

  return response;
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

    // Rate limit (per-endpoint bucket)
    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
    let bucket;
    let max;
    if (path === '/astro/forecast') {
      bucket = 'forecast'; max = RATE_FORECAST_MAX;
    } else if (path.startsWith('/tiles/')) {
      bucket = 'tiles'; max = RATE_TILES_MAX;
    } else {
      bucket = 'default'; max = RATE_DEFAULT_MAX;
    }
    if (!checkRateLimit(ip, bucket, max)) {
      return jsonError(429, 'Rate limit exceeded', origin);
    }

    try {
      // ── Health ──
      if (path === '/health') {
        return jsonOk({ status: 'ok', service: 'solara-api' }, origin);
      }

      // ── Jawg tile proxy ──
      // GET /tiles/jawg/<style>/<z>/<x>/<y>.png?lang=ja
      // JAWG_TOKEN を環境変数から注入して Jawg 公式エンドポイントに中継する。
      // アプリバイナリにトークンを埋め込まず、サーバ側で管理。
      if (path.startsWith('/tiles/jawg/') && request.method === 'GET') {
        return await handleJawgTile(request, url, env);
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

      // ── Astro Forecast (日次スコアの時系列) ──
      if (path === '/astro/forecast' && request.method === 'POST') {
        const body = await request.json();
        if (!body.birthDate || !body.birthTime) {
          return jsonError(400, 'Missing required fields: birthDate, birthTime', origin);
        }
        // KV 月次クォータ（binding 未設定なら no-op）
        const q = await checkKvForecastQuota(env, ip);
        if (!q.ok) {
          return jsonError(429, 'Monthly forecast quota exceeded', origin);
        }
        const result = computeForecast(body);
        if (q.remaining >= 0) result.quotaRemaining = q.remaining;
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

      // ── Timezone Lookup ──
      if (path === '/tz' && request.method === 'GET') {
        const lat = parseFloat(url.searchParams.get('lat'));
        const lng = parseFloat(url.searchParams.get('lng'));
        if (isNaN(lat) || isNaN(lng)) {
          return jsonError(400, 'Query parameters "lat" and "lng" required', origin);
        }
        const result = lookupTimezone(lat, lng);
        return jsonOk(result, origin);
      }

      // ── Astro Events (ingress / retrograde / eclipse) ──
      if (path === '/astro/events' && request.method === 'GET') {
        const year = parseInt(url.searchParams.get('year'), 10);
        const month = parseInt(url.searchParams.get('month'), 10);
        if (!year || !month || month < 1 || month > 12) {
          return jsonError(400, 'Query parameters "year" and "month" (1-12) required', origin);
        }
        const result = computeMonthEvents(year, month);
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

      // ── Fortune (Gemini-powered reading) ──
      if (path === '/fortune' && request.method === 'POST') {
        const body = await request.json();
        try {
          const result = await handleFortune(body, env);
          return jsonOk(result, origin);
        } catch (err) {
          console.error('Fortune error:', err);
          return jsonError(500, err.message || 'Fortune generation failed', origin);
        }
      }

      return jsonError(404, 'Not found', origin);

    } catch (err) {
      console.error('Worker error:', err);
      return jsonError(500, err.message || 'Internal server error', origin);
    }
  }
};
