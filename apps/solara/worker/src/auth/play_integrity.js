/**
 * Play Integrity (Android) サーバー検証 — Standard request 方式 (設計 v1.1 §4)。
 *
 * 役割: `/protected/*` middleware の Android 経路。Apple App Attest と対称。
 *
 * 🚨 v1.1 アーキテクチャ訂正 (2026-05-20、R8 実機失敗):
 *   Standard request の token は JWE ではなく Google 独自の protobuf 形式で、
 *   **Self-managed key で local decode できない** (公式 docs 確認、JWEInvalid)。
 *   → Q2 訂正: Self-managed key (Workers 自前 decode) → Google decodeIntegrityToken API。
 *   Self-managed key は Classic request 専用、Standard は Google decode 必須。
 *
 * 12 step 検証フロー (詳細は apps/solara/docs/play_integrity_design.md §4):
 *   Step 1   /auth/integrity/challenge で nonce 発行 (本ファイル範囲外、S4 で /index.js に実装)
 *   Step 2   X-PlayIntegrity-Token + ClientData + NonceId 受領
 *   Step 3   clientData JSON parse (nonce/uid/ts 必須)
 *   Step 4   clientData.ts ±5min (client clock drift)
 *   Step 5   DO consume → clientData.nonce 一致 (S3 は注入関数で抽象化、S4 で実 DO)
 *   Step 6-7 Google decodeIntegrityToken API で復号 + verdict 取得 (v1.1 で jose 自前 decode から置換)
 *   Step 8   payload parse (timestampMillis/versionCode は string、v0.5 訂正)
 *   Step 9   requestHash binding = base64(sha256(clientData)) (Standard 方式の核)
 *   Step 10  Number(payload.timestamp) ±5min + packageName 確認
 *   Step 11  PLAY_RECOGNIZED + MEETS_DEVICE_INTEGRITY + cert allowlist 評価
 *   Step 12  uid binding (= __appUserId 一致) は middleware 層で実施 (本関数は uid 返却まで)
 *
 * jose は **Self-managed key decode 用ではなく、Google OAuth2 用 Service Account JWT
 * (RS256) 署名に再利用** する (SignJWT + importPKCS8)。
 */
import { SignJWT, importPKCS8 } from 'jose';

// ── 定数 ─────────────────────────────────────────────────────────

/** Solara の Android パッケージ名 (env.ANDROID_PACKAGE_NAME 未設定時の fallback)。 */
export const DEFAULT_ANDROID_PACKAGE_NAME = 'com.solodevlab.solara';

/** clientData.ts / token.timestampMillis のドリフト許容 (5 分、設計 v0.5 Step 4 + Step 10)。 */
export const TS_DRIFT_MS = 5 * 60 * 1000;

/** clientData.nonce の最小長 (base64 32B = 44 char)。攻撃者が短い nonce で衝突を狙うのを防止。 */
export const MIN_NONCE_LENGTH = 32;

/** Google Play Integrity decode API の scope。 */
const PLAY_INTEGRITY_SCOPE = 'https://www.googleapis.com/auth/playintegrity';

/** Google OAuth2 token endpoint。 */
const GOOGLE_TOKEN_URL = 'https://oauth2.googleapis.com/token';

// ── Google OAuth2 access token cache (Worker instance メモリ) ──
//
// Service Account JWT 署名 + token 取得は 200-400ms かかるため、access token を
// 50 分 cache する (Google の access token は 1 時間有効)。cold start で消えるが、
// その場合は次の 1 リクエストだけ JWT 再署名すれば良い。
let _accessTokenCache = { token: null, expiresAt: 0 };

// ── 公開 API ─────────────────────────────────────────────────────

/**
 * Service Account credentials から Google OAuth2 access token を取得 (50min cache)。
 *
 * @param {object} env - GOOGLE_PLAY_INTEGRITY_SA_JSON (Service Account JSON 文字列)
 * @returns {Promise<string>} access token
 */
export async function getGoogleAccessToken(env) {
  const now = Date.now();
  if (_accessTokenCache.token && _accessTokenCache.expiresAt > now) {
    return _accessTokenCache.token;
  }

  const saJson = env.GOOGLE_PLAY_INTEGRITY_SA_JSON;
  if (!saJson) throw new Error('GOOGLE_PLAY_INTEGRITY_SA_JSON secret 未設定');
  const sa = JSON.parse(saJson);
  if (!sa.private_key || !sa.client_email) {
    throw new Error('SA JSON に private_key / client_email がない');
  }

  // RS256 JWT を Service Account private key (PEM PKCS8) で署名
  const privateKey = await importPKCS8(sa.private_key, 'RS256');
  const iat = Math.floor(now / 1000);
  const assertion = await new SignJWT({ scope: PLAY_INTEGRITY_SCOPE })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience(GOOGLE_TOKEN_URL)
    .setIssuedAt(iat)
    .setExpirationTime(iat + 3600)
    .sign(privateKey);

  const res = await fetch(GOOGLE_TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  const json = await res.json();
  if (!res.ok || !json.access_token) {
    throw new Error(`OAuth token 取得失敗: ${res.status} ${json.error || ''} ${json.error_description || ''}`);
  }

  // 50 分 cache (Google の token は 3600s 有効、余裕を見て 3000s)
  _accessTokenCache = {
    token: json.access_token,
    expiresAt: now + 3000 * 1000,
  };
  return json.access_token;
}

/**
 * 実 token を Google decodeIntegrityToken API で復号 (v1.1、Self-managed 自前 decode から置換)。
 *
 * Standard request の token (`CqUC...` 形式の protobuf) は jose で decode できないため、
 * Google の decode API に投げて verdict payload (tokenPayloadExternal) を取得する。
 *
 * @param {string} token - X-PlayIntegrity-Token (Standard request token)
 * @param {object} env - GOOGLE_PLAY_INTEGRITY_SA_JSON + ANDROID_PACKAGE_NAME
 * @returns {Promise<{ok: boolean, payload?: object, error?: string, decodeMs?: number}>}
 */
export async function decodeIntegrityToken(token, env) {
  const t0 = performance.now();
  try {
    if (!env.GOOGLE_PLAY_INTEGRITY_SA_JSON) {
      return { ok: false, error: 'sa_json_unset' };
    }
    const pkg = env.ANDROID_PACKAGE_NAME || DEFAULT_ANDROID_PACKAGE_NAME;
    const accessToken = await getGoogleAccessToken(env);

    const res = await fetch(
      `https://playintegrity.googleapis.com/v1/${pkg}:decodeIntegrityToken`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ integrity_token: token }),
      },
    );
    const json = await res.json();
    if (!res.ok || json.error) {
      const msg = json.error?.message || `HTTP ${res.status}`;
      return { ok: false, error: `decode_api: ${msg}`, decodeMs: performance.now() - t0 };
    }
    if (!json.tokenPayloadExternal) {
      return { ok: false, error: 'no_token_payload', decodeMs: performance.now() - t0 };
    }
    return { ok: true, payload: json.tokenPayloadExternal, decodeMs: performance.now() - t0 };
  } catch (e) {
    return {
      ok: false,
      error: `${e.name || 'Error'}: ${e.message}`,
      decodeMs: performance.now() - t0,
    };
  }
}

/** テスト専用: access token cache をリセット。 */
export function _resetAccessTokenCacheForTest() {
  _accessTokenCache = { token: null, expiresAt: 0 };
}

/**
 * Step 3-11 統合: Play Integrity token を verdict まで一気に検証。
 *
 * @param {Request} request - X-PlayIntegrity-Token/ClientData/NonceId ヘッダーを持つ
 * @param {object} env - PLAY_INTEGRITY_ENCRYPTION_KEY / VERIFICATION_KEY +
 *                       ANDROID_PACKAGE_NAME (任意) +
 *                       ANDROID_CERT_SHA256_ALLOWLIST (任意、CSV、空なら cert check skip)
 * @param {(nonceId: string, env: object) => Promise<{ok: boolean, nonceB64?: string, error?: string}>} consumeNonce
 *   - DO 抽象化。S3 では mock を渡し、S4 で AttestationState DO 呼び出しに置換。
 * @param {(token: string, env: object) => Promise<{ok: boolean, payload?: object, error?: string}>} [decodeFn]
 *   - decode 抽象化 (v1.1)。default は本物の decodeIntegrityToken (Google decode API)。
 *     テストでは Google API を叩かない mock を注入する。
 * @returns {Promise<{ok: boolean, status?: number, error?: string, detail?: string, payload?: object, uid?: string}>}
 */
export async function verifyPlayIntegrityFlow(request, env, consumeNonce, decodeFn = decodeIntegrityToken) {
  // ── Step 2: ヘッダー受領 ──
  const token = request.headers.get('X-PlayIntegrity-Token');
  const clientDataStr = request.headers.get('X-PlayIntegrity-ClientData');
  const nonceId = request.headers.get('X-PlayIntegrity-NonceId');

  if (!token) return fail('missing_token');
  if (!clientDataStr) return fail('missing_clientdata');
  if (!nonceId) return fail('missing_nonceid');

  // (R8 確認完了 2026-05-20: 一時 debug log は削除済。token を tail に流す診断は
  //  /auth/integrity/decode-test で代替。uid 等の検証は middleware の
  //  `[middleware:log_only] would block ...` ログで追跡可能。)

  // ── Step 3: clientData parse + 必須キー検証 ──
  let clientData;
  try {
    clientData = JSON.parse(clientDataStr);
  } catch {
    return fail('clientdata_malformed');
  }
  if (!clientData || typeof clientData !== 'object') {
    return fail('clientdata_not_object');
  }
  if (typeof clientData.nonce !== 'string' || clientData.nonce.length < MIN_NONCE_LENGTH) {
    return fail('clientdata_nonce_invalid');
  }
  if (typeof clientData.uid !== 'string' || clientData.uid.length === 0) {
    return fail('clientdata_uid_invalid');
  }
  if (typeof clientData.ts !== 'number' || !Number.isFinite(clientData.ts)) {
    return fail('clientdata_ts_invalid');
  }

  // ── Step 4: clientData.ts ±5min (client clock drift 早期検知) ──
  const now = Date.now();
  if (Math.abs(now - clientData.ts) >= TS_DRIFT_MS) {
    return fail('client_clock_drift');
  }

  // ── Step 5: DO consume → nonce 一致 ──
  const consumeResult = await consumeNonce(nonceId, env);
  if (!consumeResult || !consumeResult.ok) {
    return fail(consumeResult?.error || 'nonce_consume_failed');
  }
  if (consumeResult.nonceB64 !== clientData.nonce) {
    return fail('nonce_mismatch');
  }

  // ── Step 6 + 7: Google decodeIntegrityToken API で復号 + verdict 取得 (v1.1) ──
  const decodeResult = await decodeFn(token, env);
  if (!decodeResult.ok) {
    return fail('decode_failed', decodeResult.error);
  }
  const payload = decodeResult.payload;

  // ── Step 8: payload 構造チェック ──
  if (!payload || typeof payload !== 'object') {
    return fail('payload_invalid');
  }
  if (!payload.requestDetails || typeof payload.requestDetails !== 'object') {
    return fail('payload_request_details_missing');
  }

  // ── Step 9: requestHash binding 確認 (Standard 方式の核) ──
  // payload.requestDetails.requestHash == base64(sha256(clientDataStr))
  const expectedHash = await sha256Base64(clientDataStr);
  if (payload.requestDetails.requestHash !== expectedHash) {
    return fail('requesthash_mismatch');
  }

  // ── Step 10: token timestamp ±5min + packageName ──
  // ⚠ timestampMillis は STRING (公式 verdict 仕様)、明示変換必須
  const tokenTs = Number(payload.requestDetails.timestampMillis);
  if (!Number.isFinite(tokenTs)) {
    return fail('token_ts_invalid');
  }
  if (Math.abs(now - tokenTs) >= TS_DRIFT_MS) {
    return fail('token_ts_drift');
  }
  const expectedPkg = env.ANDROID_PACKAGE_NAME || DEFAULT_ANDROID_PACKAGE_NAME;
  if (payload.requestDetails.requestPackageName !== expectedPkg) {
    return fail('package_mismatch');
  }

  // ── Step 11: verdict 評価 ──
  // appRecognitionVerdict: PLAY_RECOGNIZED 必須 (UNRECOGNIZED_VERSION / UNEVALUATED 拒否)
  const appVerdict = payload.appIntegrity?.appRecognitionVerdict;
  if (appVerdict !== 'PLAY_RECOGNIZED') {
    return fail('app_not_recognized', appVerdict || 'undefined');
  }
  if (payload.appIntegrity?.packageName !== expectedPkg) {
    return fail('app_package_mismatch');
  }
  // certificateSha256Digest: 設定された allowlist (CSV) と少なくとも 1 つ一致
  // allowlist 未設定 (空) なら check skip (= log_only 期間で実機 cert 採取するまで)
  const certAllowlist = parseAllowlist(env.ANDROID_CERT_SHA256_ALLOWLIST);
  if (certAllowlist.length > 0) {
    const certs = payload.appIntegrity?.certificateSha256Digest;
    if (!Array.isArray(certs) || !certs.some((c) => certAllowlist.includes(c))) {
      return fail('cert_not_allowlisted');
    }
  }
  // deviceRecognitionVerdict: 空配列拒否 + MEETS_DEVICE_INTEGRITY 必須
  const deviceVerdict = payload.deviceIntegrity?.deviceRecognitionVerdict;
  if (!Array.isArray(deviceVerdict) || deviceVerdict.length === 0) {
    return fail('device_verdict_empty');
  }
  if (!deviceVerdict.includes('MEETS_DEVICE_INTEGRITY')) {
    return fail('device_integrity_missing');
  }

  // 全 step 通過 = 検証成功。uid は middleware 層で body.__appUserId と一致確認 (Step 12)
  return { ok: true, payload, uid: clientData.uid };
}

// ── 内部 helpers ─────────────────────────────────────────────────

function fail(error, detail) {
  const r = { ok: false, status: 401, error };
  if (detail !== undefined) r.detail = detail;
  return r;
}

/**
 * SHA-256 → base64 (標準アルファベット、**`=` パディング無し / NO_WRAP**) で計算。
 * Workers の crypto.subtle.digest + Web 標準 btoa を利用 (Node 18+ も互換)。
 *
 * 🔴 重要 (v1.2 修正): `app_attest_integrity` v1.0.0 の Android 実装 (getToken) は
 *    `Base64.encodeToString(sha256(clientData), Base64.NO_WRAP or Base64.NO_PADDING)`
 *    を requestHash に使う (= 標準アルファベット・**`=` パディング無し**)。
 *    Standard Integrity API は requestHash を不透明文字列としてそのまま echo するので、
 *    Worker 側も padding を除去しないと SHA-256 の末尾 `=` 分だけ一致せず
 *    requesthash_mismatch になる。
 *    (旧コメントは「CryptoUtils.sha256HashBase64 = パディングあり」と誤記していた。
 *     実際の plugin v1.0.0 Android 経路は NO_PADDING。これが log_only で検出された)
 */
async function sha256Base64(input) {
  const bytes = new TextEncoder().encode(input);
  const hash = await crypto.subtle.digest('SHA-256', bytes);
  const arr = new Uint8Array(hash);
  let bin = '';
  for (let i = 0; i < arr.length; i++) bin += String.fromCharCode(arr[i]);
  // plugin の Base64.NO_PADDING に合わせて末尾 `=` を除去 (標準アルファベットは btoa と同一)。
  return btoa(bin).replace(/=+$/, '');
}

/**
 * env.ANDROID_CERT_SHA256_ALLOWLIST (CSV) を配列に。
 * 例: "ABCD...,EFGH..." → ["ABCD...", "EFGH..."]
 * 空文字 / undefined → []
 */
function parseAllowlist(csv) {
  if (!csv || typeof csv !== 'string') return [];
  return csv
    .split(',')
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
}

// テスト用に内部 helpers を export (production import 不要)
export const __test = { sha256Base64, parseAllowlist };
