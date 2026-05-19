/**
 * Play Integrity (Android) サーバー検証 — Standard request 方式 (設計 v0.5/v0.6 §4)。
 *
 * 役割: `/protected/*` middleware の Android 経路。Apple App Attest と対称。
 *
 * 12 step 検証フロー (詳細は apps/solara/docs/play_integrity_design.md §4):
 *   Step 1   /auth/integrity/challenge で nonce 発行 (本ファイル範囲外、S4 で /index.js に実装)
 *   Step 2   X-PlayIntegrity-Token + ClientData + NonceId 受領
 *   Step 3   clientData JSON parse (nonce/uid/ts 必須)
 *   Step 4   clientData.ts ±5min (client clock drift)
 *   Step 5   DO consume → clientData.nonce 一致 (S3 は注入関数で抽象化、S4 で実 DO)
 *   Step 6   JWE A256KW + A256GCM decode (jose.compactDecrypt)
 *   Step 7   JWS ES256 verify (jose.compactVerify、Self-managed verification key)
 *   Step 8   payload parse (timestampMillis/versionCode は string、v0.5 訂正)
 *   Step 9   requestHash binding = base64(sha256(clientData)) (Standard 方式の核)
 *   Step 10  Number(payload.timestamp) ±5min + packageName 確認
 *   Step 11  PLAY_RECOGNIZED + MEETS_DEVICE_INTEGRITY + cert allowlist 評価
 *   Step 12  uid binding (= __appUserId 一致) は middleware 層で実施 (本関数は uid 返却まで)
 *
 * 🟢 v1.0 本実装 (S3、2026-05-19): verifyPlayIntegrityFlow を Step 3-11 統合。
 *    既存 diagnoseKeys / decodeIntegrityToken は診断 endpoint 用に残置。
 */
import { compactDecrypt, compactVerify } from 'jose';

// ── 定数 ─────────────────────────────────────────────────────────

/** Solara の Android パッケージ名 (env.ANDROID_PACKAGE_NAME 未設定時の fallback)。 */
export const DEFAULT_ANDROID_PACKAGE_NAME = 'com.solodevlab.solara';

/** clientData.ts / token.timestampMillis のドリフト許容 (5 分、設計 v0.5 Step 4 + Step 10)。 */
export const TS_DRIFT_MS = 5 * 60 * 1000;

/** clientData.nonce の最小長 (base64 32B = 44 char)。攻撃者が短い nonce で衝突を狙うのを防止。 */
export const MIN_NONCE_LENGTH = 32;

// ── 公開 API ─────────────────────────────────────────────────────

/**
 * Self-managed key (Play Console から取得した base64 DER SPKI / AES-256) の
 * crypto.subtle import を確認する診断関数。S2 minimal worker 用。
 *
 * @param {object} env - Workers env (PLAY_INTEGRITY_ENCRYPTION_KEY / VERIFICATION_KEY を含む secret)
 * @returns {Promise<{encryptionKeyOk: boolean, verificationKeyOk: boolean, errors: string[]}>}
 */
export async function diagnoseKeys(env) {
  const errors = [];
  let encryptionKeyOk = false;
  let verificationKeyOk = false;

  try {
    const encB64 = env.PLAY_INTEGRITY_ENCRYPTION_KEY;
    if (!encB64) throw new Error('PLAY_INTEGRITY_ENCRYPTION_KEY secret 未設定');
    const encBytes = base64ToBytes(encB64);
    if (encBytes.length !== 32) {
      throw new Error(`encryption key 長さ異常: ${encBytes.length} (期待値 32)`);
    }
    await crypto.subtle.importKey('raw', encBytes, { name: 'AES-KW' }, false, ['unwrapKey']);
    encryptionKeyOk = true;
  } catch (e) {
    errors.push(`encryption: ${e.message}`);
  }

  try {
    const verB64 = env.PLAY_INTEGRITY_VERIFICATION_KEY;
    if (!verB64) throw new Error('PLAY_INTEGRITY_VERIFICATION_KEY secret 未設定');
    const verBytes = base64ToBytes(verB64);
    await crypto.subtle.importKey(
      'spki',
      verBytes,
      { name: 'ECDSA', namedCurve: 'P-256' },
      false,
      ['verify'],
    );
    verificationKeyOk = true;
  } catch (e) {
    errors.push(`verification: ${e.message}`);
  }

  return { encryptionKeyOk, verificationKeyOk, errors };
}

/**
 * 実 token を decode (R7/R8 検証用、S2 minimal worker から継続使用)。
 *
 * @param {string} token - X-PlayIntegrity-Token (JWE compact form)
 * @param {object} env
 * @returns {Promise<{ok: boolean, payload?: object, error?: string, decodeMs?: number}>}
 */
export async function decodeIntegrityToken(token, env) {
  const t0 = performance.now();
  try {
    const { encKey, verKey } = await loadKeys(env);
    if (!encKey || !verKey) return { ok: false, error: 'keys_unset' };

    // Step 6: JWE A256KW + A256GCM decode
    const { plaintext } = await compactDecrypt(token, encKey);
    const jwsCompact = new TextDecoder().decode(plaintext);

    // Step 7: JWS ES256 verify
    const { payload: payloadBytes } = await compactVerify(jwsCompact, verKey);
    const payload = JSON.parse(new TextDecoder().decode(payloadBytes));

    return { ok: true, payload, decodeMs: performance.now() - t0 };
  } catch (e) {
    return {
      ok: false,
      error: `${e.name || 'Error'}: ${e.message}`,
      decodeMs: performance.now() - t0,
    };
  }
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
 * @returns {Promise<{ok: boolean, status?: number, error?: string, detail?: string, payload?: object, uid?: string}>}
 */
export async function verifyPlayIntegrityFlow(request, env, consumeNonce) {
  // ── Step 2: ヘッダー受領 ──
  const token = request.headers.get('X-PlayIntegrity-Token');
  const clientDataStr = request.headers.get('X-PlayIntegrity-ClientData');
  const nonceId = request.headers.get('X-PlayIntegrity-NonceId');

  if (!token) return fail('missing_token');
  if (!clientDataStr) return fail('missing_clientdata');
  if (!nonceId) return fail('missing_nonceid');

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

  // ── Step 6 + 7: JWE A256KW decode + JWS ES256 verify ──
  const decodeResult = await decodeIntegrityToken(token, env);
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
 * 標準 base64 (RFC 4648 §4、=パディングあり) で SHA-256 を計算。
 * Workers の crypto.subtle.digest + Web 標準 btoa を利用 (Node 18+ も互換)。
 *
 * 🔴 重要 (v0.5): `app_attest_integrity` v1.0.0 の `CryptoUtils.sha256HashBase64` は
 *    base64.encode (URL-safe ではない、`=` パディングあり) を使う。
 *    Standard request の payload.requestDetails.requestHash も同形式。
 */
async function sha256Base64(input) {
  const bytes = new TextEncoder().encode(input);
  const hash = await crypto.subtle.digest('SHA-256', bytes);
  const arr = new Uint8Array(hash);
  let bin = '';
  for (let i = 0; i < arr.length; i++) bin += String.fromCharCode(arr[i]);
  return btoa(bin);
}

function base64ToBytes(b64) {
  return Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
}

async function loadKeys(env) {
  const encB64 = env.PLAY_INTEGRITY_ENCRYPTION_KEY;
  const verB64 = env.PLAY_INTEGRITY_VERIFICATION_KEY;
  if (!encB64 || !verB64) return { encKey: null, verKey: null };

  const encKey = await crypto.subtle.importKey(
    'raw',
    base64ToBytes(encB64),
    { name: 'AES-KW' },
    false,
    ['unwrapKey'],
  );
  const verKey = await crypto.subtle.importKey(
    'spki',
    base64ToBytes(verB64),
    { name: 'ECDSA', namedCurve: 'P-256' },
    false,
    ['verify'],
  );
  return { encKey, verKey };
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
export const __test = { sha256Base64, base64ToBytes, parseAllowlist };
