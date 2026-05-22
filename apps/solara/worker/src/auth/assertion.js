/**
 * Apple App Attest 「assertion」 検証 (4 step + Step 5/6 caller 責任、設計 v3.0)。
 *
 * /protected/* リクエスト時に DCAppAttestService.generateAssertion() で生成された
 * CBOR を受け取り、署名検証 + rpId 一致 + signCount 抽出。
 *
 * 本関数は汎用: 渡された `payload` bytes を SHA-256 して nonce を作り署名検証する。
 * caller (index.js verifyAppleAssertionFlow) が「何を payload として渡すか」で規約が決まる。
 *
 * 🔴 設計 v3.1 (2026-05-22) でリプレイ防止を counter → リクエスト毎チャレンジに変更:
 *   - caller は `clientData` (= JSON({challenge, uid, ts}) のヘッダー文字列) の utf8 を
 *     payload として渡す。プラグインが SHA256(utf8(clientData)) で署名するため一致する。
 *   - リプレイ防止は caller 側の「使い捨て challenge 単回消費」で行う (本関数が返す
 *     signCount は参照しない = counter 厳密増加は廃止。並行リクエストで誤 401 になる盲点)。
 *   - 旧 v1.8: payload = HTTP body raw bytes + signCount monotonic。clientDataHash の
 *     base64/raw 取り違えで fail_nonce_mismatch、並行で sign_count_not_greater が出た。
 *
 * Reference implementation: node-app-attest (MIT, Copyright (c) 2024 David Übelacker)
 * https://github.com/uebelack/node-app-attest
 */
import { createHash, createVerify } from 'node:crypto';
import { decodeFirst } from './cbor.js';
import { concatBytes, bytesEqual, readUint32BE } from './apple_root_ca.js';

function sha256(bytes) {
  const h = createHash('sha256');
  h.update(bytes);
  return new Uint8Array(h.digest());
}

/**
 * @param {object} params
 * @param {Uint8Array} params.assertion    CBOR バイト列 (DCAppAttestService.generateAssertion の出力)
 * @param {Uint8Array} params.payload      Worker が request.arrayBuffer() で取得した raw body bytes
 * @param {string}     params.publicKeyPem verifyAttestation の戻り値 publicKeyPem (DO から取得)
 * @param {string}     params.bundleIdentifier
 * @param {string}     params.teamIdentifier
 * @returns {{ok: true, signCount: number} | {ok: false, error: string}}
 */
export function verifyAssertion(params) {
  const { assertion, payload, publicKeyPem, bundleIdentifier, teamIdentifier } = params;

  if (!(assertion instanceof Uint8Array)) return { ok: false, error: 'invalid_assertion_type' };
  if (!(payload instanceof Uint8Array)) return { ok: false, error: 'invalid_payload_type' };
  if (typeof publicKeyPem !== 'string' || !publicKeyPem.includes('BEGIN PUBLIC KEY')) {
    return { ok: false, error: 'invalid_publickey_pem' };
  }
  if (typeof bundleIdentifier !== 'string' || !bundleIdentifier) return { ok: false, error: 'invalid_bundle_id' };
  if (typeof teamIdentifier !== 'string' || !teamIdentifier) return { ok: false, error: 'invalid_team_id' };

  // CBOR decode: { signature: Uint8Array (DER ECDSA), authenticatorData: Uint8Array (37+ bytes) }
  let decoded;
  try {
    decoded = decodeFirst(assertion);
  } catch (_e) {
    return { ok: false, error: 'fail_cbor_decode' };
  }
  const { signature, authenticatorData } = decoded;
  if (!(signature instanceof Uint8Array)) return { ok: false, error: 'fail_signature_missing' };
  if (!(authenticatorData instanceof Uint8Array)) return { ok: false, error: 'fail_authdata_missing' };
  if (authenticatorData.length < 37) return { ok: false, error: 'fail_authdata_short' };

  // ── Step 1-3: nonce = SHA-256(authenticatorData || SHA-256(payload)) ──
  const clientDataHash = sha256(payload);
  const nonce = sha256(concatBytes(authenticatorData, clientDataHash));

  // ── Step 1-3 続: ECDSA P-256 signature verify (DER 形式を node:crypto.createVerify で直接) ──
  // node-app-attest と同じパターン: 公開鍵 type (= P-256) と署名形式 (= DER) を Node 内部で自動判定
  let verified;
  try {
    const v = createVerify('SHA256');
    v.update(nonce);
    verified = v.verify(publicKeyPem, signature);
  } catch (_e) {
    return { ok: false, error: 'fail_signature_exception' };
  }
  if (!verified) return { ok: false, error: 'fail_signature_invalid' };

  // ── Step 4: rpIdHash (authenticatorData[0..31]) == SHA-256(`<teamId>.<bundleId>`) ──
  const appId = `${teamIdentifier}.${bundleIdentifier}`;
  const expectedRpIdHash = sha256(new TextEncoder().encode(appId));
  const actualRpIdHash = authenticatorData.slice(0, 32);
  if (!bytesEqual(actualRpIdHash, expectedRpIdHash)) {
    return { ok: false, error: 'fail_rpid_mismatch' };
  }

  // ── Step 5/6 は caller 責任 (DO の前回 signCount と比較、challenge inclusion は v1.8 で不採用) ──
  const signCount = readUint32BE(authenticatorData, 33);

  return { ok: true, signCount };
}
