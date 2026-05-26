/**
 * Solara API — Cloudflare Worker
 *
 * 🔴 ルート物理分離 (project_solara_security_principles.md §2):
 *   /public/*     誰でも OK    純数学計算 (`/astro/chart` 等)、マップタイル、検索
 *   /auth/*       Sign in 系   whoami / App Attest 登録
 *   /protected/*  重防御       Gemini 呼び出し全部 (`/fortune`/`/tarot`/`/relocation`/
 *                              `/astro/consultation`/`/astro/line-narrative`)。
 *                              attestation + entitlement (RevenueCat 連携) +
 *                              per-user rate limit (Free=5 Pro=100 /日)。
 *   /webhooks/*   外部連携      RevenueCat Webhook (Pro 状態の真の出所)。
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
import { handleConsultationV2 } from './consultation_v2.js';
import { verifyAttestation, verifyAssertion } from './auth/app_attest.js';
// Play Integrity (Android) — 設計 v1.1 §4 + §8 (Google decode API 方式)
import {
  getGoogleAccessToken,
  decodeIntegrityToken,
  verifyPlayIntegrityFlow,
} from './auth/play_integrity.js';
import {
  getCachedEntitlement,
  setCachedEntitlement,
  clearMemoryEntitlementCache,
} from './auth/entitlement_cache.js';
import { handleRevenueCatWebhook } from './webhooks/revenuecat.js';

/** Solara の Pro エンタイトルメント ID (`purchases_service.dart` と一致) */
const SOLARA_ENTITLEMENT_ID = 'cosmic_pro';

/** /protected/* body 内で Flutter が送る予約フィールド名 (App User ID 受け渡し) */
const APP_USER_ID_FIELD = '__appUserId';

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
const RATE_WEBHOOK_MAX = 600;  // 1分あたり600 (RevenueCat 突発バースト想定、Bearer 認証で守る前提)

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

/** error コード + 追加フィールドを載せた JSON レスポンス (例: 402 paywall with remaining/limit)。 */
function jsonStatus(status, payload, origin) {
  return new Response(JSON.stringify(payload), {
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
 * PLAY_INTEGRITY_ENFORCEMENT (Android 経路) の評価。
 * App Attest と同じ semantics、独立 env var で iOS/Android のロールアウト差を吸収。
 * 未設定時は "log_only" を default に倒す。
 */
function getPlayIntegrityEnforcement(env) {
  const v = (env.PLAY_INTEGRITY_ENFORCEMENT || 'log_only').toLowerCase();
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
 * POST /auth/integrity/challenge
 * Play Integrity Standard request 用 random 32B nonce を発行 → DO に 5 分 TTL で INSERT
 * → クライアントへ {nonceId, nonce(base64), ttlSec} を返却。
 *
 * Flutter (Android) 側は受け取った nonce を `clientData = JSON({nonce, uid, ts})` に
 * 埋込み、`AppAttestIntegrity().verify(clientData: jsonEncode(...))` の引数として渡す。
 * plugin が内部で `requestHash = base64(sha256(clientData))` を計算 → Standard token 取得。
 *
 * 設計: apps/solara/docs/play_integrity_design.md §4 Step 1 + §7.2
 */
async function handleIntegrityChallenge(env, origin) {
  const nonceId = crypto.randomUUID();
  const nonceBytes = crypto.getRandomValues(new Uint8Array(32));
  // 標準 base64 (RFC 4648 §4、`=` パディングあり、URL-safe ではない)
  // = app_attest_integrity plugin の CryptoUtils.sha256HashBase64 と同形式
  let bin = '';
  for (let i = 0; i < nonceBytes.length; i++) bin += String.fromCharCode(nonceBytes[i]);
  const nonceB64 = btoa(bin);
  const ttlSec = parseInt(env.PLAY_INTEGRITY_NONCE_TTL_SEC || '300', 10);
  const expiresAt = Date.now() + ttlSec * 1000;
  const result = await callDo(env, '/integrity-nonce-create', { nonceId, nonceB64, expiresAt });
  if (result.status !== 200) {
    return jsonError(500, `integrity-nonce-create failed: ${result.body?.error || 'unknown'}`, origin);
  }
  return jsonOk({ nonceId, nonce: nonceB64, ttlSec }, origin);
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
    console.error(
      '[auth/attest] challenge consume failed:',
      ch.status,
      ch.body?.error || 'unknown',
      '| challengeId=',
      String(challengeId).slice(0, 12),
    );
    return jsonError(401, `invalid_challenge: ${ch.body?.error || 'unknown'}`, origin);
  }
  const challengeBytes = new Uint8Array(ch.body.challengeBytes);

  // 🔴 clientDataHash 規約 (2026-05-22 実機 fail_nonce_mismatch で判明):
  //   app_attest_integrity プラグイン (ios/Classes/AppAttestIntegrityPlugin.swift) は
  //     clientDataHash = SHA256(utf8(challengeBase64String))
  //   で attestKey を呼ぶ。challengeBase64String は /auth/challenge が
  //     btoa(String.fromCharCode(...challengeBytes))  (標準 base64 + padding)
  //   で送った文字列そのもの。verifyAttestation は渡された challenge を SHA256 する
  //   だけなので、ここで「base64 文字列の UTF-8 バイト」を渡して nonce 規約を端末と
  //   一致させる。生の challengeBytes を渡すと nonce 不一致で 401 になる。
  const challengeClientData = new TextEncoder().encode(
    Buffer.from(challengeBytes).toString('base64'),
  );

  // 2. attestation 検証 (9 step + Step 1.5 時刻チェック)
  let attResult;
  try {
    attResult = await verifyAttestation({
      attestation: new Uint8Array(Buffer.from(attB64, 'base64')),
      challenge: challengeClientData,
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
    console.error(
      '[auth/attest] verification rejected:',
      attResult.error,
      '| keyId=',
      String(keyId).slice(0, 12),
      '| bundle=',
      env.APPLE_BUNDLE_ID,
      '| team=',
      env.APPLE_TEAM_ID,
    );
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
 * Body から `__appUserId` 予約フィールドを取り出す。
 *
 * 設計 (v2.2):
 *   - Flutter `AppAttestClient.postProtected` が body に自動注入する。
 *   - assertion が body 全体 (raw bytes) を payload SHA-256 で署名するため、
 *     middleware で署名検証を通過した時点で `__appUserId` は端末固有の値として
 *     改ざんされていないことが保証される (詐称しても assertion mismatch で 401)。
 *   - 値の形状: Sign in 済み = `apple:xxx` / `google:xxx`、anonymous = RC 発行の
 *     `$RCAnonymousID:xxx`。
 *
 * 戻り値: appUserId string or null (未注入 / 非 JSON body)。
 */
function extractAppUserId(payloadBytes) {
  if (!(payloadBytes instanceof Uint8Array) || payloadBytes.length === 0) return null;
  try {
    const text = new TextDecoder('utf-8').decode(payloadBytes);
    const obj = JSON.parse(text);
    if (!obj || typeof obj !== 'object') return null;
    const v = obj[APP_USER_ID_FIELD];
    return typeof v === 'string' && v.length > 0 ? v : null;
  } catch (_e) {
    return null;
  }
}

/**
 * appUserId から Pro エンタイトルメント有効性を取得 (cache → DO の二段)。
 * 戻り値: true = Pro / false = Free (未登録 or 期限切れ含む)
 */
async function lookupIsPro(env, appUserId) {
  if (typeof appUserId !== 'string' || !appUserId) return false;
  const cached = getCachedEntitlement(appUserId);
  if (cached !== undefined) {
    return cached !== null && cached.isActive === true;
  }
  const res = await callDo(env, '/entitlement-get', {
    appUserId,
    entitlementId: SOLARA_ENTITLEMENT_ID,
  });
  if (res.status === 200 && res.body && res.body.isActive === true) {
    setCachedEntitlement(appUserId, {
      isActive: true,
      expiresAt: res.body.expiresAt ?? null,
      environment: res.body.environment,
      productId: res.body.productId,
      periodType: res.body.periodType,
    });
    return true;
  }
  // 404 or inactive: null を memoize (= 60s は DO に問い合わせない)
  setCachedEntitlement(appUserId, null);
  return false;
}

// ──────────────────────────────────────────────────────────
// Stella 相談 Free 試食クレジット (設計 project_solara_stella_free_credits.md)
//
//   - Free は週 N 回 (CONSULTATION_FREE_WEEKLY、default 3) まで Stella 相談を試食できる。
//   - 対象モードは CONSULTATION_FREE_MODES (default "migration,travel,daily"。後から
//     "daily" だけ等に env で変更可能、コード変更/再ビルド不要)。
//   - Free は thinking OFF (浅い)・出し直し (excluded) 不可。Pro は無制限・thinking ON・出し直し可。
//   - クレジットは「実際に Stella 生成が成功した時だけ」消費する (静的 fallback は消費しない)。
//   - カウンターは端末 ID (iOS=keyId / それ以外=appUserId) × ISO 週 (月曜リセット、UTC) で DO に保持。
//   - 相談は middleware の日次クォータ (Free5/Pro100) も 1 消費する (多層防御のバックストップ。
//     週次 3 とは別軸)。
// ──────────────────────────────────────────────────────────

/** ISO 8601 週バケット文字列 "YYYY-Www" (週は月曜始まり、UTC 基準)。月曜リセットの key。 */
function isoWeekBucket(date = new Date()) {
  const d = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  // その週の木曜が ISO 週の年を決める (木曜へ移動)
  const dayNum = (d.getUTCDay() + 6) % 7; // Mon=0..Sun=6
  d.setUTCDate(d.getUTCDate() - dayNum + 3);
  const isoYear = d.getUTCFullYear();
  const firstThursday = new Date(Date.UTC(isoYear, 0, 4)); // 1/4 は必ず第1週
  const firstDayNum = (firstThursday.getUTCDay() + 6) % 7;
  firstThursday.setUTCDate(firstThursday.getUTCDate() - firstDayNum + 3);
  const week = 1 + Math.round((d.getTime() - firstThursday.getTime()) / (7 * 24 * 3600 * 1000));
  return `${isoYear}-W${String(week).padStart(2, '0')}`;
}

/** CONSULTATION_FREE_MODES を Set に。default は 3 モード全部。 */
function consultationFreeModes(env) {
  const raw = (env.CONSULTATION_FREE_MODES || 'migration,travel,daily');
  return new Set(raw.split(',').map((s) => s.trim()).filter(Boolean));
}

/** CONSULTATION_FREE_WEEKLY を int に。default 3、不正値も 3 に倒す。 */
function consultationFreeWeekly(env) {
  const n = parseInt(env.CONSULTATION_FREE_WEEKLY || '3', 10);
  return Number.isInteger(n) && n >= 0 ? n : 3;
}

/**
 * 相談クレジットのカウンター key を決める。
 *   - iOS: X-AppAttest-KeyId ヘッダー (端末固定、再インストールに強い) → `ios:{keyId}`
 *   - それ以外 (Android 含む): appUserId → `usr:{appUserId}` (匿名は再インストールで farming 可、
 *     既存日次クォータと同じ既知の限界。enforced 後の主防御は週次 + 日次の二段)
 *   - どちらも無い (bypass/dev) → null (クレジット計上しない)
 */
function consultationDeviceKey(request, appUserId) {
  const keyId = request.headers.get('X-AppAttest-KeyId');
  if (keyId) return `ios:${keyId}`;
  if (typeof appUserId === 'string' && appUserId) return `usr:${appUserId}`;
  return null;
}

/** body から appUserId を取り出す (署名検証済の予約フィールド)。 */
function consultationAppUserId(body) {
  return (body && typeof body[APP_USER_ID_FIELD] === 'string') ? body[APP_USER_ID_FIELD] : null;
}

/**
 * 相談クレジットの現在状況を返す (status endpoint + 生成後の残数添付で共用)。
 * Pro は無制限 (各値 null)。非 Pro は 無料週次残 + 購入残高。
 */
async function consultationCreditStatus(env, request, body) {
  const appUserId = consultationAppUserId(body);
  const isPro = await lookupIsPro(env, appUserId);
  if (isPro) {
    return { pro: true, freeRemaining: null, freeLimit: null, purchasedBalance: null, weekBucket: null };
  }
  const deviceKey = consultationDeviceKey(request, appUserId);
  const weekBucket = isoWeekBucket();
  const limit = consultationFreeWeekly(env);
  let freeRemaining = 0;
  if (deviceKey) {
    const got = await callDo(env, '/consultation-credit-get', { deviceKey, weekBucket });
    const used = (got.status === 200 && typeof got.body?.used === 'number') ? got.body.used : 0;
    freeRemaining = Math.max(0, limit - used);
  }
  let purchasedBalance = 0;
  if (appUserId) {
    const pg = await callDo(env, '/consultation-purchased-get', { appUserId });
    purchasedBalance = (pg.status === 200 && typeof pg.body?.balance === 'number') ? pg.body.balance : 0;
  }
  return { pro: false, freeRemaining, freeLimit: limit, purchasedBalance, weekBucket };
}

/**
 * 共通: 1 AI 占いクレジットの消費判定 (Stella 相談・タロットカテゴリで共用 = 同じ財布)。
 * 1 クレジット = AI 占い 1 回。消費順 = 無料週次 → 購入残高。Pro は無制限。
 *
 * 戻り値:
 *   - { block: Response }   → ブロック (402 paywall コード)
 *   - { allow:true, isPro:true }                                  → Pro 無制限
 *   - { allow:true, isPro:false, source:'free', deviceKey, weekBucket } → 無料週次を消費予定
 *   - { allow:true, isPro:false, source:'purchased', appUserId }  → 購入残高を消費予定
 *   - { allow:true, isPro:false, source:null }                    → bypass/dev (計上なし)
 */
async function consumeReadingCreditGate(request, env, body, origin) {
  const appUserId = consultationAppUserId(body);
  const isPro = await lookupIsPro(env, appUserId);
  if (isPro) return { allow: true, isPro: true };

  const deviceKey = consultationDeviceKey(request, appUserId);
  if (!deviceKey) {
    // bypass/dev (ヘッダーも appUserId も無い) はクレジット計上せず通す。
    return { allow: true, isPro: false, source: null };
  }

  const weekBucket = isoWeekBucket();
  const limit = consultationFreeWeekly(env);

  // 1) 無料週次の残量
  const got = await callDo(env, '/consultation-credit-get', { deviceKey, weekBucket });
  const used = (got.status === 200 && typeof got.body?.used === 'number') ? got.body.used : 0;
  if (limit - used > 0) {
    return { allow: true, isPro: false, source: 'free', deviceKey, weekBucket };
  }

  // 2) 購入残高 (サインイン済 appUserId のみ)
  if (appUserId) {
    const pg = await callDo(env, '/consultation-purchased-get', { appUserId });
    const balance = (pg.status === 200 && typeof pg.body?.balance === 'number') ? pg.body.balance : 0;
    if (balance > 0) {
      return { allow: true, isPro: false, source: 'purchased', appUserId };
    }
  }

  // 3) 無料・購入とも尽きた
  return {
    block: jsonStatus(402, {
      error: 'consultation_credit_exhausted', remaining: 0, limit, weekBucket,
    }, origin),
  };
}

/** 生成成功後に 1 クレジット消費する (free→bump / purchased→spend)。Pro / bypass は何もしない。 */
async function consumeReadingCredit(env, gate) {
  if (!gate || gate.isPro || !gate.source) return;
  if (gate.source === 'free') {
    await callDo(env, '/consultation-credit-bump', {
      deviceKey: gate.deviceKey, weekBucket: gate.weekBucket,
    });
  } else if (gate.source === 'purchased') {
    await callDo(env, '/consultation-purchased-spend', { appUserId: gate.appUserId });
  }
}

/**
 * V2 相談 (1 クレジット = 1 候補) で実際に課金すべきか。
 * 候補が無い (excluded で出し尽くした exhausted) / 静的フォールバック (Stella 不通) は課金しない。
 * 本物の候補が生成できた時だけ true。
 */
function consultationConsumed(result) {
  return !!(result && !result.exhausted && result.fallback !== true && result.candidate);
}

/**
 * Stella 相談のクレジットゲート。共通ゲート + 相談固有のモード制限 (CONSULTATION_FREE_MODES)。
 * 1 クレジット = 候補 1 つ (初回も「別の候補地」も消費)。Free も Pro 同等品質 (thinking ON / 出し直し可)。
 */
async function gateConsultation(request, env, body, origin) {
  const appUserId = consultationAppUserId(body);
  const isPro = await lookupIsPro(env, appUserId);
  // 非 Pro はアクセス可能モードか (Pro は全モード)
  if (!isPro) {
    const mode = body && body.mode;
    if (!consultationFreeModes(env).has(mode)) {
      return { block: jsonStatus(402, { error: 'consultation_pro_only_mode', mode }, origin) };
    }
  }
  return consumeReadingCreditGate(request, env, body, origin);
}

/**
 * /protected/* middleware (本実装、設計 v0.7 — iOS App Attest + Android Play Integrity 統合)。
 *
 * 戻り値: null なら通過、Response を返したらブロック (即レスポンス)。
 * 返り値の Response は Worker entry がそのままクライアントへ返す。
 *
 * 経路分岐 (S4 で追加):
 *   - X-AppAttest-KeyId ヘッダー → iOS App Attest
 *   - X-PlayIntegrity-Token ヘッダー → Android Play Integrity
 *   - 両方欠落 → 401 missing_attestation_headers
 *   - 両方同時 → 400 both_attest_headers (= クライアントバグ検出)
 *
 * Enforcement 切替 (env で OS 別独立):
 *   - APP_ATTEST_ENFORCEMENT (iOS): disabled | log_only | enforced
 *   - PLAY_INTEGRITY_ENFORCEMENT (Android): 同 semantics、別 var
 *   - 両方とも "disabled" → 即通過 (kill switch)
 *
 * 経路依存処理:
 *   - iOS: DO 公開鍵 取得 → assertion 検証 → signCount bump → keyId を quota key に使う
 *   - Android: clientData parse → DO nonce consume → token decode/verify → verdict
 *               → uid を quota key に使う (端末 binding が弱いため、攻撃者には DAU 単位の負荷)
 *
 * 共通処理:
 *   - body 取得 (request.clone().arrayBuffer())
 *   - appUserId 抽出 (body.__appUserId) + entitlement (RC) 参照
 *   - Pro / Free quota (Layer C、Free=5/日 Pro=100/日)
 *   - Step 12 (iOS は body 全体に署名済、Android は uid と __appUserId の equality 確認)
 */
/**
 * クォータ対象外パスの判定 (2026-05-26 追加)。
 *
 * クォータの目的は「Gemini AI 呼出コスト乱用ガード」なので、AI 呼出を伴わない
 * 残数照会系は対象外にする。これにより:
 *   - 本番ユーザーが残数を頻繁にチェックしてもクォータが減らない (UX 安定)
 *   - クォータ値が「1日の AI 占い回数の上限」として明確な意味を持つ
 *   - Pro の「無制限」謳いと整合 (残数照会は無限に可能)
 *
 * 対象外:
 *   - /protected/consultation/credits  残数照会 (AI なし、DO SELECT + JSON 返却のみ)
 *
 * 対象 (引き続きクォータ消費):
 *   - /protected/astro/consultation2   Stella 相談 (Gemini 呼出)
 *   - /protected/tarot                 Tarot リーディング (Gemini 呼出)
 *   - /protected/fortune (Pro)         Fortune 占い (Gemini 呼出)
 *   - /protected/relocation (Pro)      Relocation 解説 (Gemini 呼出)
 *   - /protected/account/delete        アカウント削除 (重操作、DDoS 防護のため残す)
 */
export function isQuotaExemptPath(pathname) {
  return pathname === '/protected/consultation/credits';
}

async function protectedMiddleware(request, env) {
  const iosMode = getEnforcement(env);
  const androidMode = getPlayIntegrityEnforcement(env);
  if (iosMode === 'disabled' && androidMode === 'disabled') return null;

  // 経路判定 (ヘッダー存在で OS を識別)
  const hasApple = !!request.headers.get('X-AppAttest-KeyId');
  const hasAndroid = !!request.headers.get('X-PlayIntegrity-Token');

  // どちらの mode に従うかは経路で決まる。経路未確定時 (両欠落) は iOS mode に倒す
  const activeMode = hasAndroid ? androidMode : iosMode;
  const failResponder = (status, error) => {
    if (activeMode === 'log_only') {
      console.warn(`[middleware:log_only] would block ${status} ${error}`);
      return null; // 通過
    }
    return jsonError(status, error, getAllowedOrigin(request));
  };

  if (hasApple && hasAndroid) return failResponder(400, 'both_attest_headers');
  if (!hasApple && !hasAndroid) return failResponder(401, 'missing_attestation_headers');

  // body 取得 (両経路共通)
  let payloadBytes;
  try {
    const cloned = request.clone();
    payloadBytes = new Uint8Array(await cloned.arrayBuffer());
  } catch (err) {
    console.error('[middleware] body read error:', err.message);
    return failResponder(400, 'body_read_error');
  }

  let quotaKey;     // per-user quota の key (iOS=keyId / Android=uid)
  let verifiedUid;  // Android のみ。Step 12 で __appUserId と一致確認

  // ── 経路 1: iOS App Attest ──
  if (hasApple) {
    const r = await verifyAppleAssertionFlow(request, env, payloadBytes, failResponder);
    if (r === null || r instanceof Response) return r;
    quotaKey = r.keyId;
  }

  // ── 経路 2: Android Play Integrity ──
  if (hasAndroid) {
    const r = await verifyPlayIntegrityRoute(request, env, failResponder);
    if (r === null || r instanceof Response) return r;
    quotaKey = `play:${r.uid}`;
    verifiedUid = r.uid;
  }

  // ── 共通: entitlement lookup ──
  const appUserId = extractAppUserId(payloadBytes);

  // Android のみ: clientData.uid と body.__appUserId の一致確認 (Step 12)
  if (verifiedUid !== undefined && appUserId !== null && verifiedUid !== appUserId) {
    return failResponder(401, 'uid_mismatch');
  }

  const isPro = await lookupIsPro(env, appUserId);

  // ── 共通: per-user quota (Layer C、Free=30/日 Pro=200/日) ──
  // 2026-05-26 改修: クォータの本来の目的「Gemini AI 呼出コスト乱用ガード」と
  // 実装を整合させる。詳細は isQuotaExemptPath() 参照。
  const url = new URL(request.url);
  if (isQuotaExemptPath(url.pathname)) {
    return null; // 通過 (クォータ skip)
  }

  const freeLimit = parseInt(env.APP_ATTEST_QUOTA_FREE || '30', 10);
  const proLimit = parseInt(env.APP_ATTEST_QUOTA_PRO || '200', 10);
  const limit = isPro ? proLimit : freeLimit;
  const dayBucket = new Date().toISOString().slice(0, 10);
  const quota = await callDo(env, '/quota-check-and-bump', { keyId: quotaKey, dayBucket, limit });
  if (quota.status === 429) {
    return failResponder(429, isPro ? 'quota_exceeded_pro' : 'quota_exceeded_free');
  }
  if (quota.status !== 200) {
    return failResponder(500, `quota-check failed: ${quota.body?.error || 'unknown'}`);
  }

  return null; // 通過
}

/**
 * iOS assertion の clientData JSON を検証 (DO/crypto 非依存の純関数 = 単体テスト可能)。
 *
 * clientData = JSON({challenge, uid, ts}) (Android の X-PlayIntegrity-ClientData と同形)。
 *   - challenge: 消費した使い捨て challenge の base64 と一致するか (リプレイ防止の核)
 *   - ts:        鮮度 (maxSkewMs 以内)
 *   - uid:       body の __appUserId と一致するか (なりすまし防止)
 *
 * @returns {{ok:true}|{ok:false,error:string}}
 */
function validateAppleAssertionClientData({
  clientDataStr,
  consumedChallengeB64,
  bodyUid,
  now = Date.now(),
  maxSkewMs = 5 * 60 * 1000,
}) {
  let cd;
  try {
    cd = JSON.parse(clientDataStr);
  } catch (_e) {
    return { ok: false, error: 'invalid_apple_clientdata' };
  }
  if (!cd || typeof cd !== 'object') return { ok: false, error: 'invalid_apple_clientdata' };
  if (typeof cd.challenge !== 'string' || cd.challenge !== consumedChallengeB64) {
    return { ok: false, error: 'challenge_mismatch' };
  }
  if (typeof cd.ts !== 'number' || Math.abs(now - cd.ts) > maxSkewMs) {
    return { ok: false, error: 'clientdata_stale' };
  }
  const cdUid = typeof cd.uid === 'string' ? cd.uid : '';
  if ((bodyUid || '') !== cdUid) return { ok: false, error: 'uid_mismatch' };
  return { ok: true };
}

/**
 * iOS App Attest 経路 (設計 v3.1 = リクエスト毎チャレンジ方式、Android と統一)。
 *
 * 端末は protected 呼び出しのたびに /auth/challenge で使い捨て challenge を取得し、
 * clientData = JSON({challenge, uid, ts}) を App Attest assertion で署名 →
 * X-AppAttest-{KeyId,Assertion,ClientData,ChallengeId} ヘッダーで送る。
 * サーバーは assertion 署名検証 → challenge を単回消費 (リプレイ防止) →
 * clientData の challenge/ts/uid を検証。
 *
 * 旧 signCount 厳密増加方式 (counter) は廃止。理由: 占い5本同時など並行リクエストで
 * 到着順がズレて誤って 401 (sign_count_not_greater) になる盲点があったため。使い捨て
 * challenge は各リクエストが独立した値を持つので並行でも衝突しない (2026-05-22 切替)。
 *
 * clientData は「受信したヘッダー文字列そのもの」を SHA256 する (Android の
 * X-PlayIntegrity-ClientData と同方式)。サーバー側で base64 を再構築しないので、
 * バイトズレ (= 前回の fail_nonce_mismatch の原因) が原理的に起きない。
 *
 * 戻り値: Response (ブロック) / null (log_only 通過) / {keyId} (検証 OK)
 */
async function verifyAppleAssertionFlow(request, env, payloadBytes, fail) {
  const keyId = request.headers.get('X-AppAttest-KeyId');
  const assertionB64 = request.headers.get('X-AppAttest-Assertion');
  const clientDataStr = request.headers.get('X-AppAttest-ClientData');
  const challengeId = request.headers.get('X-AppAttest-ChallengeId');
  if (!keyId || !assertionB64) return fail(401, 'missing_apple_attest_headers');
  if (!clientDataStr || !challengeId) return fail(401, 'missing_apple_clientdata');

  const att = await callDo(env, '/attestation-get', { keyId });
  if (att.status !== 200) return fail(401, 'attestation_not_registered');
  const { publicKeyPem } = att.body;

  // assertion 署名検証: clientData ヘッダー文字列の UTF-8 を payload として渡す。
  // プラグインは clientDataHash = SHA256(utf8(clientData)) で署名するため、受信した
  // ヘッダー文字列をそのまま hash すれば一致する (再構築のバイトズレ無し)。
  let result;
  try {
    result = verifyAssertion({
      assertion: new Uint8Array(Buffer.from(assertionB64, 'base64')),
      payload: new TextEncoder().encode(clientDataStr),
      publicKeyPem,
      bundleIdentifier: env.APPLE_BUNDLE_ID,
      teamIdentifier: env.APPLE_TEAM_ID,
    });
  } catch (err) {
    console.error('[middleware] verifyAssertion threw:', err.stack || err.message);
    return fail(500, 'assertion_verify_exception');
  }
  if (!result.ok) return fail(401, result.error);

  // 使い捨て challenge を単回消費 (リプレイ防止)。並行リクエストでも各自が別 challenge を
  // 持つので衝突しない。署名が偽物なら上で弾かれるので、ここでは正規端末分のみ消費する。
  const consume = await callDo(env, '/challenge-consume', { challengeId });
  if (consume.status !== 200) {
    return fail(401, `invalid_challenge: ${consume.body?.error || 'unknown'}`);
  }
  // /auth/challenge が送ったのと同じ base64 を再構築 (btoa で完全一致)。
  const consumedB64 = btoa(String.fromCharCode(...new Uint8Array(consume.body.challengeBytes)));

  const cdCheck = validateAppleAssertionClientData({
    clientDataStr,
    consumedChallengeB64: consumedB64,
    bodyUid: extractAppUserId(payloadBytes),
  });
  if (!cdCheck.ok) return fail(401, cdCheck.error);

  return { keyId };
}

/**
 * Android Play Integrity 経路: verifyPlayIntegrityFlow を呼出し、DO consume を実装側に注入。
 * 戻り値: Response (ブロック) / null (log_only 通過) / {uid} (検証 OK)
 */
async function verifyPlayIntegrityRoute(request, env, fail) {
  // DO consume の注入: verifyPlayIntegrityFlow に Step 5 の DO 呼出を委譲する
  const consumeNonce = async (nonceId) => {
    const r = await callDo(env, '/integrity-nonce-consume', { nonceId });
    if (r.status !== 200) {
      return { ok: false, error: 'nonce_invalid' };
    }
    return { ok: true, nonceB64: r.body.nonceB64 };
  };

  let result;
  try {
    result = await verifyPlayIntegrityFlow(request, env, consumeNonce);
  } catch (err) {
    console.error('[middleware] verifyPlayIntegrityFlow threw:', err.stack || err.message);
    return fail(500, 'play_integrity_verify_exception');
  }
  if (!result.ok) {
    const code = result.detail ? `${result.error}:${result.detail}` : result.error;
    return fail(result.status || 401, code);
  }
  return { uid: result.uid };
}

// ── Rate limit bucket dispatch ──
//
// path → (bucket_name, max_per_minute)。bucket はメモリ内マップのキー prefix。
function pickRateBucket(path) {
  if (path === '/public/astro/forecast') return { bucket: 'forecast', max: RATE_FORECAST_MAX };
  if (path.startsWith('/public/tiles/')) return { bucket: 'tiles', max: RATE_TILES_MAX };
  if (path.startsWith('/webhooks/')) return { bucket: 'webhook', max: RATE_WEBHOOK_MAX };
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
  // Play Integrity Standard request 用 nonce 発行 (S4、設計 v0.7 §4 Step 1)
  if (path === '/auth/integrity/challenge' && request.method === 'POST') {
    return await handleIntegrityChallenge(env, origin);
  }
  // Play Integrity 診断 endpoint (設計 v1.1 §13 + 本番ガード)
  // v1.1: Service Account credentials の健全性確認 (Google decode API 方式)。
  //   - GOOGLE_PLAY_INTEGRITY_SA_JSON が設定され、OAuth2 access token が取れるか
  //
  // 🔒 本番ガード: PLAY_INTEGRITY_ENFORCEMENT === 'enforced' 時は 404 化
  // (本番でデバッグ口を露出しない。`disabled`/`log_only` 期間中のみアクセス可)。
  if (path === '/auth/integrity/diagnose' && request.method === 'GET') {
    if (isDiagnosticsBlocked(env)) {
      return jsonError(404, 'not_found', origin);
    }
    try {
      const tokenStr = await getGoogleAccessToken(env);
      // access token は秘密なので値は返さず、取得成功 + 長さだけ報告
      return jsonOk({ saConfigured: true, accessTokenOk: true, accessTokenLen: tokenStr.length }, origin);
    } catch (e) {
      return jsonOk({ saConfigured: !!env.GOOGLE_PLAY_INTEGRITY_SA_JSON, accessTokenOk: false, error: e.message }, origin);
    }
  }
  // 実 token decode 試験 (実機採取 token を POST して Google decode API 動作確認)
  if (path === '/auth/integrity/decode-test' && request.method === 'POST') {
    if (isDiagnosticsBlocked(env)) {
      return jsonError(404, 'not_found', origin);
    }
    const body = await request.json().catch(() => ({}));
    if (!body.token) return jsonError(400, 'token required', origin);
    const result = await decodeIntegrityToken(body.token, env);
    return jsonOk(result, origin);
  }
  return null;
}

/**
 * 診断 endpoint (/auth/integrity/diagnose + /auth/integrity/decode-test) を
 * 本番モードでブロックする判定。
 *
 * - PLAY_INTEGRITY_ENFORCEMENT === 'enforced' → 404 で完全隠蔽
 * - それ以外 (disabled / log_only / 未設定) → アクセス可 (S5 オーナー実機作業中)
 *
 * 検証用の最後の砦として log_only の間は active のまま残す。enforced 切替と
 * 同時に本ガードが発火、攻撃者がデバッグ口を発見できないようにする。
 */
function isDiagnosticsBlocked(env) {
  return getPlayIntegrityEnforcement(env) === 'enforced';
}

/**
 * POST /protected/account/delete
 *
 * アカウント削除 (App Store ガイドライン 5.1.1(v)) の「サーバー側の関連データ削除」。
 * protectedMiddleware を通過済 = App Attest / Play Integrity 検証 OK かつ body の
 * `__appUserId` は assertion で署名済 (転送中の改ざん不可)。その appUserId に紐づく
 * Pro エンタイトルメント記録 + Webhook event ログを DO から物理削除する。
 *
 * 注意:
 *   - 購読そのものの解約はしない (Apple/Google が管理)。ここで消すのは Worker が持つ
 *     派生キャッシュ + 個人識別子 (apple:/google: の uid) のみ。クライアント側の UI で
 *     「有料プランは別途ストアで解約」を案内する。
 *   - メモリキャッシュも即時 invalidate (削除後に Pro と誤判定しないため)。
 */
async function handleAccountDelete(request, env, origin) {
  let body;
  try {
    body = await request.json();
  } catch (_e) {
    return jsonError(400, 'invalid_json', origin);
  }
  const appUserId =
    body && typeof body === 'object' ? body[APP_USER_ID_FIELD] : null;
  if (typeof appUserId !== 'string' || !appUserId) {
    return jsonError(400, 'missing_app_user_id', origin);
  }
  const res = await callDo(env, '/account-purge', { appUserId });
  if (res.status !== 200) {
    return jsonError(500, `account-purge failed: ${res.body?.error || 'unknown'}`, origin);
  }
  clearMemoryEntitlementCache(appUserId);
  return jsonOk({ ok: true, ...res.body }, origin);
}

// ── /protected/* dispatcher ──
async function dispatchProtected(request, env, url, origin) {
  // ★ middleware (現状 no-op、Phase 1 残で attestation + entitlement)
  const blocked = await protectedMiddleware(request, env);
  if (blocked) return blocked;

  const path = url.pathname;

  if (path === '/protected/account/delete' && request.method === 'POST') {
    return await handleAccountDelete(request, env, origin);
  }

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
    // カテゴリ指定時のみクレジット消費 (相談と同じ財布)。指定なし = 従来の無料 全体運。
    // Pro はカテゴリ指定でも消費なし (無制限)。
    const hasCategory = typeof body.category === 'string' && body.category.length > 0;
    let gate = null;
    if (hasCategory) {
      gate = await consumeReadingCreditGate(request, env, body, origin);
      if (gate.block) return gate.block;
    }
    try {
      const result = await handleTarot(body, env);
      // handleTarot は失敗時 throw (静的 fallback なし) → ここに来たら成功。消費する。
      if (gate) await consumeReadingCredit(env, gate);
      // 非 Pro かつカテゴリ指定時は残数を添付 (クライアント表示用)
      if (gate && !gate.isPro) {
        const status = await consultationCreditStatus(env, request, body);
        result.freeCreditsRemaining = status.freeRemaining;
        result.freeCreditsLimit = status.freeLimit;
        result.purchasedBalance = status.purchasedBalance;
      }
      return jsonOk(result, origin);
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
    // クレジットゲート (Pro=無制限、非Pro=無料週次→購入残高、尽きたら 402 paywall)
    const gate = await gateConsultation(request, env, body, origin);
    if (gate.block) return gate.block;
    try {
      const result = await handleConsultation(body, env);
      // 非 Pro: 実際に Stella 生成が成功 (非 fallback) した時だけ 1 クレジット消費
      if (result && result.fallback !== true) {
        await consumeReadingCredit(env, gate);
      }
      // 残数をレスポンスに添付 (消費後の正確な値、クライアント表示用)
      if (!gate.isPro) {
        const status = await consultationCreditStatus(env, request, body);
        result.freeCreditsRemaining = status.freeRemaining;
        result.freeCreditsLimit = status.freeLimit;
        result.purchasedBalance = status.purchasedBalance;
      }
      return jsonOk(result, origin);
    } catch (err) {
      console.error('Consultation error:', err);
      return jsonError(500, err.message || 'Consultation generation failed', origin);
    }
  }

  // 相談 V2 (全要素統合: client 最小入力 → 全サーバー計算 → Stella ナレーション)。
  // 1 クレジット = 1 候補。「別の候補地」は excluded を足して再呼び出し (= +1 クレジット)。
  // 旧 /protected/astro/consultation は deployed app 用に温存 (後方互換)。
  if (path === '/protected/astro/consultation2' && request.method === 'POST') {
    const body = await request.json();
    // クレジットゲート (Pro=無制限、非Pro=無料週次→購入残高、尽きたら 402 paywall)
    const gate = await gateConsultation(request, env, body, origin);
    if (gate.block) return gate.block;
    try {
      const result = await handleConsultationV2(body, env);
      // 候補が生成できた時 (exhausted/fallback でない) だけ 1 クレジット消費
      if (consultationConsumed(result)) {
        await consumeReadingCredit(env, gate);
      }
      // 残数をレスポンスに添付 (消費後の正確な値、クライアント表示用)
      if (!gate.isPro) {
        const status = await consultationCreditStatus(env, request, body);
        result.freeCreditsRemaining = status.freeRemaining;
        result.freeCreditsLimit = status.freeLimit;
        result.purchasedBalance = status.purchasedBalance;
      }
      return jsonOk(result, origin);
    } catch (err) {
      console.error('Consultation V2 error:', err);
      return jsonError(500, err.message || 'Consultation generation failed', origin);
    }
  }

  // クレジット状況 (残数表示 / 購入後の残高更新用)。middleware 通過必須。
  if (path === '/protected/consultation/credits' && request.method === 'POST') {
    const body = await request.json().catch(() => ({}));
    try {
      return jsonOk(await consultationCreditStatus(env, request, body), origin);
    } catch (err) {
      console.error('Consultation credits error:', err);
      return jsonError(500, err.message || 'Consultation credits failed', origin);
    }
  }

  return null;
}

// テスト用エクスポート (Cloudflare runtime 非依存の関数のみ)
// 既存ロジック (handleAuthChallenge / handleAuthAttest 等) は callDo 経由で env.ATTESTATION_DO に
// 依存するため、env を mock することで Node から直接呼出してテスト可能。
export const _internal = {
  handleIntegrityChallenge,
  handleAccountDelete,
  getEnforcement,
  getPlayIntegrityEnforcement,
  extractAppUserId,
  isDiagnosticsBlocked,
  validateAppleAssertionClientData,
  isoWeekBucket,
  consultationFreeModes,
  consultationFreeWeekly,
  consultationDeviceKey,
  consultationAppUserId,
  consultationCreditStatus,
  consumeReadingCreditGate,
  gateConsultation,
  consultationConsumed,
};

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
      } else if (path === '/webhooks/revenuecat') {
        // 外部 (RevenueCat) からの通信。CORS 不要 (ブラウザ起点ではない、Origin null)。
        // 認証は RevenueCat ダッシュボード設定の Bearer (REVENUECAT_WEBHOOK_AUTH)。
        res = await handleRevenueCatWebhook(request, env);
      }
      if (res) return res;
      return jsonError(404, 'Not found', origin);
    } catch (err) {
      console.error('Worker error:', err);
      return jsonError(500, err.message || 'Internal server error', origin);
    }
  }
};
