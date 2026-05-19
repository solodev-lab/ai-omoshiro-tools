/**
 * Play Integrity (Android) サーバー検証 — Standard request 方式 (設計 v0.3 §4)。
 *
 * 役割: `/protected/*` middleware の Android 経路。Apple App Attest と対称。
 *
 * 12 step 検証フロー (詳細は apps/solara/docs/play_integrity_design.md §4):
 *   Step 1   /auth/integrity/challenge で nonce 発行 (本ファイル範囲外、index.js で実装)
 *   Step 2   X-PlayIntegrity-Token + ClientData + NonceId 受領
 *   Step 3   clientData JSON parse (nonce/uid/ts 必須)
 *   Step 4   clientData.ts ±5min (client clock drift)
 *   Step 5   DO consume → clientData.nonce 一致
 *   Step 6   JWE A256KW decode (jose.compactDecrypt)
 *   Step 7   JWS ES256 verify (jose.compactVerify、Self-managed verification key)
 *   Step 8   payload parse (requestDetails / appIntegrity / deviceIntegrity)
 *   Step 9   requestHash binding = base64(sha256(clientData)) (Standard 方式の核)
 *   Step 10  payload.timestamp ±5min + packageName 確認
 *   Step 11  PLAY_RECOGNIZED + MEETS_DEVICE_INTEGRITY 評価
 *   Step 12  uid binding + entitlement / quota
 *
 * 🟡 v0.3 スケルトン: jose の import 確認 + bundle 計測 (R6) 用。
 *    本実装は S3 で展開 (auth/play_integrity.js v1.0)。
 */
import { compactDecrypt, compactVerify, importSPKI } from 'jose';

/**
 * Self-managed key (Play Console から取得した base64 DER SPKI / AES-256) の
 * crypto.subtle import を確認する診断関数。S2 minimal worker テスト用。
 *
 * @param {object} env - Workers env (PLAY_INTEGRITY_ENCRYPTION_KEY / VERIFICATION_KEY を含む secret)
 * @returns {Promise<{encryptionKeyOk: boolean, verificationKeyOk: boolean, errors: string[]}>}
 */
export async function diagnoseKeys(env) {
  const errors = [];
  let encryptionKeyOk = false;
  let verificationKeyOk = false;

  // Encryption key: AES-256 base64 (44 char、Self-managed key 設計 v0.2 §6.1)
  try {
    const encB64 = env.PLAY_INTEGRITY_ENCRYPTION_KEY;
    if (!encB64) throw new Error('PLAY_INTEGRITY_ENCRYPTION_KEY secret 未設定');
    const encBytes = Uint8Array.from(atob(encB64), (c) => c.charCodeAt(0));
    if (encBytes.length !== 32) {
      throw new Error(`encryption key 長さ異常: ${encBytes.length} (期待値 32)`);
    }
    // AES-KW として import 可能か (= JWE A256KW decode で使う key)
    await crypto.subtle.importKey(
      'raw',
      encBytes,
      { name: 'AES-KW' },
      false,
      ['unwrapKey'],
    );
    encryptionKeyOk = true;
  } catch (e) {
    errors.push(`encryption: ${e.message}`);
  }

  // Verification key: ECDSA P-256 base64 DER SubjectPublicKeyInfo (124 char、v0.2 §6.1)
  try {
    const verB64 = env.PLAY_INTEGRITY_VERIFICATION_KEY;
    if (!verB64) throw new Error('PLAY_INTEGRITY_VERIFICATION_KEY secret 未設定');
    const verBytes = Uint8Array.from(atob(verB64), (c) => c.charCodeAt(0));
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
 * 実 token を decode (R7 + R8 検証用、S2 minimal worker)。
 *
 * S3 本実装で `verifyPlayIntegrityFlow(request, env, body)` に拡張予定。
 * 本関数は Standard 応答の JWE A256KW + JWS ES256 + Self-managed key 適用を実証する診断専用。
 *
 * @param {string} token - X-PlayIntegrity-Token (JWE compact form)
 * @param {object} env
 * @returns {Promise<{ok: boolean, payload?: object, error?: string, decodeMs?: number}>}
 */
export async function decodeIntegrityToken(token, env) {
  const t0 = performance.now();
  try {
    const encB64 = env.PLAY_INTEGRITY_ENCRYPTION_KEY;
    const verB64 = env.PLAY_INTEGRITY_VERIFICATION_KEY;
    if (!encB64 || !verB64) {
      return { ok: false, error: 'keys_unset' };
    }

    const encBytes = Uint8Array.from(atob(encB64), (c) => c.charCodeAt(0));
    const encKey = await crypto.subtle.importKey(
      'raw',
      encBytes,
      { name: 'AES-KW' },
      false,
      ['unwrapKey'],
    );

    const verBytes = Uint8Array.from(atob(verB64), (c) => c.charCodeAt(0));
    const verKey = await crypto.subtle.importKey(
      'spki',
      verBytes,
      { name: 'ECDSA', namedCurve: 'P-256' },
      false,
      ['verify'],
    );

    // Step 6: JWE A256KW decode
    const { plaintext } = await compactDecrypt(token, encKey);
    const jwsCompact = new TextDecoder().decode(plaintext);

    // Step 7: JWS ES256 verify
    const { payload: payloadBytes } = await compactVerify(jwsCompact, verKey);
    const payload = JSON.parse(new TextDecoder().decode(payloadBytes));

    return { ok: true, payload, decodeMs: performance.now() - t0 };
  } catch (e) {
    return { ok: false, error: `${e.name || 'Error'}: ${e.message}`, decodeMs: performance.now() - t0 };
  }
}

// importSPKI は将来 PEM 形式の verification key 取得形態に切り替わった場合用 (v0.4 で利用予定)
// 現状の base64 DER SPKI 形式では crypto.subtle.importKey('spki', ...) 直接使用で十分
// (v0.3 設計 §6.1 で確証済)
void importSPKI;
