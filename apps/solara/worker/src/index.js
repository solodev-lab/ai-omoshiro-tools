/**
 * Solara API — Cloudflare Worker
 *
 * 🔴 ルート物理分離 (project_solara_security_principles.md §2):
 *   /public/*     誰でも OK    純数学計算 (`/astro/chart` 等)、マップタイル、検索
 *   /auth/*       Sign in 系   whoami / App Attest 登録 (現状 stub)
 *   /protected/*  重防御       Gemini 呼び出し全部 (`/fortune`/`/tarot`/`/relocation`/
 *                              `/astro/consultation`/`/astro/line-narrative`)。
 *                              将来 attestation + entitlement + per-user rate limit。
 *
 * 旧 top-level ルート (`/fortune` `/astro/chart` 等) は撤廃。Flutter クライアント側も
 * 同セッションで新 path に書き換え済（`apps/solara/lib/utils/solara_api.dart` 参照）。
 */
import { computeChart, computePredictions, computeMonthEvents, computeForecast } from './astro.js';
import { computeDailyTransits } from './daily_transits.js';
import { searchPlace } from './search.js';
import { lookupTimezone } from './tzlookup.js';
import { handleFortune } from './fortune.js';
import { handleTarot } from './tarot.js';
import { handleRelocation } from './relocation.js';
import { handleLineNarrative } from './line_narrative.js';
import { handleConsultation } from './consultation.js';
import { verifyAttestation, verifyAssertion } from './auth/app_attest.js';

// Durable Object 本体は worker entry から re-export 必須 (wrangler が class を解決するため)
export { AttestationState } from './auth/attestation_state.js';

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
// `/public/astro/forecast` は計算コストが高いので厳しめ。
// 永続化は後段の KV 側で追加する（checkKvQuota）。
// 将来: `/protected/*` 配下は per-appUserId rate limit に置き換える（Phase 1 残）。
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
// クライアントから /public/tiles/osm/<source>/<z>/<x>/<y>.png で来たリクエストを
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

/**
 * /public/tiles/osm/<source>/<z>/<x>/<y>.png を OSM 系へ中継。
 * tilePathTail はプレフィックス除去後の `<source>/<z>/<x>/<y>.png` 部分。
 */
async function handleOsmTile(request, tilePathTail) {
  const parts = tilePathTail.split('/');
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

// ──────────────────────────────────────────────────────────
// App Attest middleware & handlers (設計 v1.9、セッション 5 で本実装)
// ──────────────────────────────────────────────────────────

/**
 * Durable Object (AttestationState) を呼ぶ薄いラッパー。
 * 全 keyId を 1 instance ('global') に集約する設計 (設計 v1.8 §6.1)。
 */
async function callDo(env, path, body) {
  const stub = env.ATTESTATION_DO.get(env.ATTESTATION_DO.idFromName('global'));
  const res = await stub.fetch(`https://do${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const json = await res.json().catch(() => ({}));
  return { status: res.status, body: json };
}

/**
 * APP_ATTEST_ENFORCEMENT の評価。
 * - "disabled" : middleware 完全スキップ (kill switch)
 * - "log_only" : 検証は走るが失敗しても通す + console.warn
 * - "enforced" : 検証失敗で 401 (本番想定)
 * 未設定時は "log_only" を default に倒す (= 初回 deploy は壊れない)
 */
function getEnforcement(env) {
  const v = (env.APP_ATTEST_ENFORCEMENT || 'log_only').toLowerCase();
  if (v === 'disabled' || v === 'log_only' || v === 'enforced') return v;
  return 'log_only';
}

/**
 * GET /auth/whoami
 * 現状 stub のまま (Phase 2 Sign in + RevenueCat Webhook 統合時に本実装、
 * App Attest とは独立タスクなのでセッション 5 のスコープ外)。
 */
function handleWhoami(_request, origin) {
  return jsonOk({ anonymous: true, isPro: false, stub: true }, origin);
}

/**
 * POST /auth/challenge
 * App Attest 用 random 32B を発行 → DO に 5 分 TTL で INSERT → クライアントへ返却。
 * Flutter 側はこの challenge を `DCAppAttestService.attestKey` の clientDataHash
 * (= SHA-256(challenge)) として渡す。
 */
async function handleAuthChallenge(env, origin) {
  const challengeId = crypto.randomUUID();
  const challengeBytes = Array.from(crypto.getRandomValues(new Uint8Array(32)));
  const ttlSec = parseInt(env.APP_ATTEST_CHALLENGE_TTL_SEC || '300', 10);
  const expiresAt = Date.now() + ttlSec * 1000;
  const result = await callDo(env, '/challenge-create', { challengeId, challengeBytes, expiresAt });
  if (result.status !== 200) {
    return jsonError(500, `challenge-create failed: ${result.body?.error || 'unknown'}`, origin);
  }
  // クライアントへは challenge bytes を base64 で返す (Flutter で base64 decode 後 SHA-256)
  return jsonOk({
    challengeId,
    challenge: btoa(String.fromCharCode(...challengeBytes)),
    ttlSec,
  }, origin);
}

/**
 * POST /auth/attest
 * 端末初回起動時 attestation 登録。
 * Body: { keyId: <base64>, challengeId: <uuid>, attestation: <base64 CBOR> }
 */
async function handleAuthAttest(request, env, origin) {
  let body;
  try {
    body = await request.json();
  } catch (_e) {
    return jsonError(400, 'invalid_json', origin);
  }
  const { keyId, challengeId, attestation: attB64 } = body;
  if (typeof keyId !== 'string' || !keyId) return jsonError(400, 'missing_key_id', origin);
  if (typeof challengeId !== 'string' || !challengeId) return jsonError(400, 'missing_challenge_id', origin);
  if (typeof attB64 !== 'string' || !attB64) return jsonError(400, 'missing_attestation', origin);

  // 1. DO から challenge を取り出して consume (one-time use、replay 防止)
  const ch = await callDo(env, '/challenge-consume', { challengeId });
  if (ch.status !== 200) {
    return jsonError(401, `invalid_challenge: ${ch.body?.error || 'unknown'}`, origin);
  }
  const challengeBytes = new Uint8Array(ch.body.challengeBytes);

  // 2. attestation 検証 (9 step + Step 1.5 時刻チェック)
  let attResult;
  try {
    attResult = await verifyAttestation({
      attestation: new Uint8Array(Buffer.from(attB64, 'base64')),
      challenge: challengeBytes,
      keyId,
      bundleIdentifier: env.APPLE_BUNDLE_ID,
      teamIdentifier: env.APPLE_TEAM_ID,
      allowDevelopmentEnvironment: false, // 設計 Q4 production only
    });
  } catch (err) {
    console.error('[auth/attest] verifyAttestation threw:', err.stack || err.message);
    return jsonError(500, 'attestation_verify_exception', origin);
  }
  if (!attResult.ok) {
    return jsonError(401, attResult.error, origin);
  }

  // 3. DO に永続化
  const rpId = `${env.APPLE_TEAM_ID}.${env.APPLE_BUNDLE_ID}`;
  const store = await callDo(env, '/attestation-store', {
    keyId,
    publicKeyPem: attResult.publicKeyPem,
    rpId,
    aaguid: attResult.environment,
  });
  if (store.status !== 200) {
    return jsonError(500, `attestation-store failed: ${store.body?.error || 'unknown'}`, origin);
  }
  return jsonOk({ ok: true, environment: attResult.environment }, origin);
}

/**
 * /protected/* middleware (本実装、設計 v1.9)。
 *
 * 戻り値: null なら通過、Response を返したらブロック (即レスポンス)。
 * 返り値の Response は Worker entry がそのままクライアントへ返す。
 *
 * `APP_ATTEST_ENFORCEMENT` の値で挙動切替:
 *   - "disabled" : 即通過 (kill switch)
 *   - "log_only" : 検証は走るが失敗しても通す + warning ログ (移行期間)
 *   - "enforced" : 失敗時 401
 *
 * 戻り値が `null` なら通過。通過時に、handler 側で再度 body を読めるよう、
 * middleware は `request.clone()` ではなく Worker entry 側で arrayBuffer を
 * 取って context に積む形にする (= middleware 内では body を一度読むだけ)。
 */
async function protectedMiddleware(request, env) {
  const mode = getEnforcement(env);
  if (mode === 'disabled') return null;

  const fail = (status, error) => {
    if (mode === 'log_only') {
      console.warn(`[middleware:log_only] would block ${status} ${error}`);
      return null; // 通過
    }
    return jsonError(status, error, getAllowedOrigin(request));
  };

  const keyId = request.headers.get('X-AppAttest-KeyId');
  const assertionB64 = request.headers.get('X-AppAttest-Assertion');
  if (!keyId || !assertionB64) return fail(401, 'missing_attestation_headers');

  // 1. DO から公開鍵 + 前回 signCount 取得
  const att = await callDo(env, '/attestation-get', { keyId });
  if (att.status !== 200) return fail(401, 'attestation_not_registered');
  const { publicKeyPem, counter: prevSignCount } = att.body;

  // 2. payload (request body raw bytes) を取得して payload SHA-256 計算用
  // 設計 v1.8 §16.2 規約: Flutter は jsonEncode → utf8.encode → そのまま POST body
  // request.clone() で stream を分岐 (= handler 側で request.json() がそのまま動く)
  let payloadBytes;
  try {
    const cloned = request.clone();
    payloadBytes = new Uint8Array(await cloned.arrayBuffer());
  } catch (err) {
    console.error('[middleware] body read error:', err.message);
    return fail(400, 'body_read_error');
  }

  // 3. assertion 検証
  let result;
  try {
    result = verifyAssertion({
      assertion: new Uint8Array(Buffer.from(assertionB64, 'base64')),
      payload: payloadBytes,
      publicKeyPem,
      bundleIdentifier: env.APPLE_BUNDLE_ID,
      teamIdentifier: env.APPLE_TEAM_ID,
    });
  } catch (err) {
    console.error('[middleware] verifyAssertion threw:', err.stack || err.message);
    return fail(500, 'assertion_verify_exception');
  }
  if (!result.ok) return fail(401, result.error);

  // 4. signCount monotonic bump (DO 内で race-free)
  const bump = await callDo(env, '/attestation-bump-counter', {
    keyId,
    signCount: result.signCount,
  });
  if (bump.status === 409) return fail(401, 'sign_count_not_greater'); // replay
  if (bump.status !== 200) return fail(500, `bump-counter failed: ${bump.body?.error || 'unknown'}`);

  // 5. per-user quota check (Layer C、Free=5/日 Pro=100/日)
  // 当面は isPro を判定する RevenueCat 経路がないので Free 想定 (= 厳しい上限)。
  // 後続セッションで Sign in + RevenueCat 配線時に isPro 判定して Pro 上限へ切替。
  const limit = parseInt(env.APP_ATTEST_QUOTA_FREE || '5', 10);
  const dayBucket = new Date().toISOString().slice(0, 10);
  const quota = await callDo(env, '/quota-check-and-bump', { keyId, dayBucket, limit });
  if (quota.status === 429) return fail(429, 'quota_exceeded');
  if (quota.status !== 200) return fail(500, `quota-check failed: ${quota.body?.error || 'unknown'}`);

  return null; // 通過
}

// ── Rate limit bucket dispatch ──
//
// path → (bucket_name, max_per_minute)。bucket はメモリ内マップのキー prefix。
function pickRateBucket(path) {
  if (path === '/public/astro/forecast') return { bucket: 'forecast', max: RATE_FORECAST_MAX };
  if (path.startsWith('/public/tiles/')) return { bucket: 'tiles', max: RATE_TILES_MAX };
  return { bucket: 'default', max: RATE_DEFAULT_MAX };
}

// ── /public/* dispatcher ──
async function dispatchPublic(request, env, url, origin) {
  const path = url.pathname;

  if (path === '/public/health') {
    return jsonOk({ status: 'ok', service: 'solara-api' }, origin);
  }

  // GET /public/tiles/osm/<source>/<z>/<x>/<y>.png
  if (path.startsWith('/public/tiles/osm/') && request.method === 'GET') {
    const tail = path.slice('/public/tiles/osm/'.length);
    return await handleOsmTile(request, tail);
  }

  if (path === '/public/astro/chart' && request.method === 'POST') {
    const body = await request.json();
    if (!body.birthDate || !body.birthTime || body.birthLat == null || body.birthLng == null) {
      return jsonError(400, 'Missing required fields: birthDate, birthTime, birthLat, birthLng', origin);
    }
    return jsonOk(computeChart(body), origin);
  }

  if (path === '/public/astro/forecast' && request.method === 'POST') {
    const body = await request.json();
    if (!body.birthDate || !body.birthTime) {
      return jsonError(400, 'Missing required fields: birthDate, birthTime', origin);
    }
    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
    const q = await checkKvForecastQuota(env, ip);
    if (!q.ok) {
      return jsonError(429, 'Monthly forecast quota exceeded', origin);
    }
    const result = computeForecast(body);
    if (q.remaining >= 0) result.quotaRemaining = q.remaining;
    return jsonOk(result, origin);
  }

  if (path === '/public/astro/predict' && request.method === 'POST') {
    const body = await request.json();
    if (!body.birthDate || !body.birthTime) {
      return jsonError(400, 'Missing required fields: birthDate, birthTime', origin);
    }
    return jsonOk(computePredictions(body), origin);
  }

  if (path === '/public/astro/daily-transits' && request.method === 'POST') {
    const body = await request.json();
    if (typeof body.lat !== 'number' || typeof body.lng !== 'number') {
      return jsonError(400, 'lat / lng required (numbers)', origin);
    }
    return jsonOk(computeDailyTransits(body), origin);
  }

  if (path === '/public/tz' && request.method === 'GET') {
    const lat = parseFloat(url.searchParams.get('lat'));
    const lng = parseFloat(url.searchParams.get('lng'));
    if (isNaN(lat) || isNaN(lng)) {
      return jsonError(400, 'Query parameters "lat" and "lng" required', origin);
    }
    return jsonOk(lookupTimezone(lat, lng), origin);
  }

  if (path === '/public/astro/events' && request.method === 'GET') {
    const year = parseInt(url.searchParams.get('year'), 10);
    const month = parseInt(url.searchParams.get('month'), 10);
    if (!year || !month || month < 1 || month > 12) {
      return jsonError(400, 'Query parameters "year" and "month" (1-12) required', origin);
    }
    return jsonOk(computeMonthEvents(year, month), origin);
  }

  // /public/search — Google Places 経由。コストはかかるが Free 機能のため public に置く
  // (Gemini ではない、IP rate limit + Google 側 quota で防御)。
  if (path === '/public/search' && request.method === 'GET') {
    const q = url.searchParams.get('q');
    if (!q || q.length < 2) {
      return jsonError(400, 'Query parameter "q" required (min 2 chars)', origin);
    }
    const latParam = parseFloat(url.searchParams.get('lat'));
    const lngParam = parseFloat(url.searchParams.get('lng'));
    const options = {};
    if (!isNaN(latParam) && !isNaN(lngParam)) {
      options.lat = latParam;
      options.lng = lngParam;
    }
    const results = await searchPlace(q, env, options);
    return jsonOk(results, origin);
  }

  return null; // 未マッチ
}

// ── /auth/* dispatcher ──
async function dispatchAuth(request, env, url, origin) {
  const path = url.pathname;
  if (path === '/auth/whoami' && request.method === 'GET') {
    return handleWhoami(request, origin);
  }
  if (path === '/auth/challenge' && request.method === 'POST') {
    return await handleAuthChallenge(env, origin);
  }
  if (path === '/auth/attest' && request.method === 'POST') {
    return await handleAuthAttest(request, env, origin);
  }
  return null;
}

// ── /protected/* dispatcher ──
async function dispatchProtected(request, env, url, origin) {
  // ★ middleware (現状 no-op、Phase 1 残で attestation + entitlement)
  const blocked = await protectedMiddleware(request, env);
  if (blocked) return blocked;

  const path = url.pathname;

  if (path === '/protected/fortune' && request.method === 'POST') {
    const body = await request.json();
    try {
      return jsonOk(await handleFortune(body, env), origin);
    } catch (err) {
      console.error('Fortune error:', err);
      return jsonError(500, err.message || 'Fortune generation failed', origin);
    }
  }

  if (path === '/protected/tarot' && request.method === 'POST') {
    const body = await request.json();
    try {
      return jsonOk(await handleTarot(body, env), origin);
    } catch (err) {
      console.error('Tarot error:', err);
      return jsonError(500, err.message || 'Tarot generation failed', origin);
    }
  }

  if (path === '/protected/relocation' && request.method === 'POST') {
    const body = await request.json();
    try {
      return jsonOk(await handleRelocation(body, env), origin);
    } catch (err) {
      console.error('Relocation error:', err);
      return jsonError(500, err.message || 'Relocation generation failed', origin);
    }
  }

  // 旧 /astro/line-narrative。Flutter 現役呼出なし (consultation に置換済) だが
  // Worker 側ハンドラは temp 残置 (将来再利用余地)。
  if (path === '/protected/astro/line-narrative' && request.method === 'POST') {
    const body = await request.json();
    try {
      return jsonOk(await handleLineNarrative(body, env), origin);
    } catch (err) {
      console.error('LineNarrative error:', err);
      return jsonError(500, err.message || 'Line narrative generation failed', origin);
    }
  }

  if (path === '/protected/astro/consultation' && request.method === 'POST') {
    const body = await request.json();
    try {
      return jsonOk(await handleConsultation(body, env), origin);
    } catch (err) {
      console.error('Consultation error:', err);
      return jsonError(500, err.message || 'Consultation generation failed', origin);
    }
  }

  return null;
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
    const { bucket, max } = pickRateBucket(path);
    if (!checkRateLimit(ip, bucket, max)) {
      return jsonError(429, 'Rate limit exceeded', origin);
    }

    try {
      let res = null;
      if (path.startsWith('/public/')) {
        res = await dispatchPublic(request, env, url, origin);
      } else if (path.startsWith('/auth/')) {
        res = await dispatchAuth(request, env, url, origin);
      } else if (path.startsWith('/protected/')) {
        res = await dispatchProtected(request, env, url, origin);
      }
      if (res) return res;
      return jsonError(404, 'Not found', origin);
    } catch (err) {
      console.error('Worker error:', err);
      return jsonError(500, err.message || 'Internal server error', origin);
    }
  }
};
