/**
 * Solara API — Cloudflare Worker
 * Endpoints: /astro/chart, /astro/predict, /search, /fortune, /health
 */
import { computeChart, computePredictions, computeMonthEvents, computeForecast } from './astro.js';
import { searchPlace } from './search.js';
import { lookupTimezone } from './tzlookup.js';
import { handleFortune } from './fortune.js';
import { handleTarot } from './tarot.js';
import { handleRelocation } from './relocation.js';

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

// ── OSM tile proxy ──
// クライアントから /tiles/osm/<source>/<z>/<x>/<y>.png で来たリクエストを
// 各 OSM ソース（OSM France HOT / 標準 OSM / CyclOSM）に中継する。
// アプリから直接叩くと UA 不足で 403 を食らうため、Worker 側で
// 識別可能な User-Agent を設定し、edge cache（24h）で OSM 側負荷も最小化する。
//
// - source は allowlist 制限（'hot' | 'standard' | 'cyclosm'）
// - Z/X/Y は整数のみ受け付け
// - Cloudflare edge cache を活用し、同一タイル再取得は OSM に届かない
const OSM_SOURCE_TARGETS = {
  hot: (z, x, y) => `https://a.tile.openstreetmap.fr/hot/${z}/${x}/${y}.png`,
  standard: (z, x, y) => `https://tile.openstreetmap.org/${z}/${x}/${y}.png`,
  cyclosm: (z, x, y) => `https://a.tile-cyclosm.openstreetmap.fr/cyclosm/${z}/${x}/${y}.png`,
};

const OSM_USER_AGENT = 'Solara/1.0 (https://solodev-lab.com; kojifo369@gmail.com)';

async function handleOsmTile(request, url) {
  const prefix = '/tiles/osm/';
  const rest = url.pathname.slice(prefix.length);
  const parts = rest.split('/');
  if (parts.length !== 4) {
    return new Response('Bad tile path', { status: 400 });
  }
  const [source, zStr, xStr, yWithExt] = parts;

  const buildTarget = OSM_SOURCE_TARGETS[source];
  if (!buildTarget) {
    return new Response('Source not allowed', { status: 400 });
  }

  const yMatch = yWithExt.match(/^(\d+)\.png$/);
  if (!yMatch || !/^\d+$/.test(zStr) || !/^\d+$/.test(xStr)) {
    return new Response('Bad tile coordinates', { status: 400 });
  }
  const z = parseInt(zStr, 10);
  const x = parseInt(xStr, 10);
  const y = parseInt(yMatch[1], 10);
  if (z < 0 || z > 19) {
    return new Response('Zoom out of range', { status: 400 });
  }

  const target = buildTarget(z, x, y);

  const cache = caches.default;
  const cacheKey = new Request(
    `https://tile-cache/osm/${source}/${z}/${x}/${y}`,
    { method: 'GET' },
  );
  const cached = await cache.match(cacheKey);
  if (cached) return cached;

  const upstream = await fetch(target, {
    headers: { 'User-Agent': OSM_USER_AGENT },
    cf: { cacheTtl: 86400, cacheEverything: true },
  });
  if (!upstream.ok) {
    return new Response(`Upstream error: ${upstream.status}`, {
      status: upstream.status,
    });
  }

  const contentType = upstream.headers.get('Content-Type') || 'image/png';
  const body = await upstream.arrayBuffer();
  const response = new Response(body, {
    status: 200,
    headers: {
      'Content-Type': contentType,
      'Cache-Control': 'public, max-age=86400, immutable',
    },
  });

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

      // ── OSM tile proxy ──
      // GET /tiles/osm/<source>/<z>/<x>/<y>.png
      // OSM 系（hot/standard/cyclosm）に Worker 側 UA で中継。
      // 直叩きで 403 を食らうのを回避し、edge cache で OSM 負荷も最小化。
      if (path.startsWith('/tiles/osm/') && request.method === 'GET') {
        return await handleOsmTile(request, url);
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

      // ── Tarot (Gemini-powered tarot reading + Stella message) ──
      if (path === '/tarot' && request.method === 'POST') {
        const body = await request.json();
        try {
          const result = await handleTarot(body, env);
          return jsonOk(result, origin);
        } catch (err) {
          console.error('Tarot error:', err);
          return jsonError(500, err.message || 'Tarot generation failed', origin);
        }
      }

      // ── Relocation (Gemini-powered relocation chart narrative) ──
      // Phase B: 静的テンプレート (horo_relocation_templates.dart) を動的解説で上書き。
      // 失敗時は呼出側 (Dart) で null を受けて静的テンプレ表示にフォールバック。
      if (path === '/relocation' && request.method === 'POST') {
        const body = await request.json();
        try {
          const result = await handleRelocation(body, env);
          return jsonOk(result, origin);
        } catch (err) {
          console.error('Relocation error:', err);
          return jsonError(500, err.message || 'Relocation generation failed', origin);
        }
      }

      return jsonError(404, 'Not found', origin);

    } catch (err) {
      console.error('Worker error:', err);
      return jsonError(500, err.message || 'Internal server error', origin);
    }
  }
};
