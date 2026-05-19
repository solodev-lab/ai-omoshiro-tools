/**
 * Apple App Attest サーバー検証。
 *
 * Reference implementation: node-app-attest (MIT, Copyright (c) 2024 David Übelacker)
 * https://github.com/uebelack/node-app-attest
 * Apple X509Certificate を @peculiar/x509 に置き換え、Buffer/Node 依存を Workers
 * (nodejs_compat) 互換に整理した派生実装。
 *
 * Apple 公式仕様:
 * https://developer.apple.com/documentation/devicecheck/validating-apps-that-connect-to-your-server
 *
 * 戻り値の方針:
 *   - 成功時: { ok: true, publicKeyPem, environment, receipt }
 *   - 失敗時: { ok: false, error: '<verify_error_code>' } を return (例外を投げない)
 * 設計 v1.4 Q1 (詳細エラーコード) に合致。
 */
import { createHash } from 'node:crypto';
import { X509Certificate } from '@peculiar/x509';
import { decodeFirst } from './cbor.js';
import {
  APPLE_ROOT_CA_PEM,
  AAGUID_PRODUCTION,
  AAGUID_DEVELOPMENT,
  APPLE_NONCE_OID,
  SUB_CA_SUBJECT_HINT,
  concatBytes,
  bytesEqual,
  bytesToHex,
  bytesToBase64,
  readUint16BE,
  readUint32BE,
} from './apple_root_ca.js';

const APPLE_ROOT_CA = new X509Certificate(APPLE_ROOT_CA_PEM);

/**
 * SHA-256 over a Uint8Array, returns Uint8Array (32 bytes).
 */
function sha256(bytes) {
  const h = createHash('sha256');
  h.update(bytes);
  return new Uint8Array(h.digest());
}

/**
 * X509Certificate 配列から「subject に Apple App Attestation CA 1 を含む」中間 CA と
 * 「含まない」credCert (leaf) を分離する。x5c の格納順序に依存しない。
 */
function partitionCerts(certs) {
  let subCa = null;
  let leaf = null;
  for (const c of certs) {
    if (c.subject.includes(SUB_CA_SUBJECT_HINT)) {
      subCa = c;
    } else {
      leaf = c;
    }
  }
  return { subCa, leaf };
}

/**
 * @peculiar/x509 の `cert.getExtension(oid).toString('asn')` 出力の末尾から
 * Apple nonce を抽出して期待値 (hex) と比較する。
 *
 * ASN.1 構造は 3 段ネスト ( SEQUENCE → [0] EXPLICIT SEQUENCE → OCTET STRING ) だが、
 * `toString('asn')` で文字列展開した末尾が常に `OCTET STRING : <hex>\n?` 形式になるため
 * suffix 比較で深さに依存しない (appattest-checker-node 流の堅牢パターン)。
 */
function extractAppleNonceMatches(credCert, expectedHex) {
  const ext = credCert.getExtension(APPLE_NONCE_OID);
  if (!ext) return false;
  const asn = ext.toString('asn');
  const expectedSuffix = `OCTET STRING : ${expectedHex}`;
  // toString('asn') の末尾改行を無視するために trim
  return asn.trim().endsWith(expectedSuffix);
}

/**
 * @peculiar/x509 の publicKey.rawData (SubjectPublicKeyInfo DER) から、
 * uncompressed EC point の本体 65 バイト (`0x04 || X || Y`) を取り出す。
 *
 * App Attest credCert は必ず P-256 (= 65 バイト point)。Apple 公式の Step 5 では
 * SHA-256(this 65 bytes) が keyId と一致する。
 */
function extractEcUncompressedPoint(publicKey) {
  const spki = new Uint8Array(publicKey.rawData);
  // SPKI の末尾 65 バイトが uncompressed point (BIT STRING の最後)
  // ※ node-app-attest verifyAttestation.js:155 の `.slice(-65)` と同じ
  if (spki.length < 65) {
    throw new Error('publicKey.rawData too short for P-256 uncompressed point');
  }
  return spki.slice(spki.length - 65);
}

/**
 * App Attest attestation を 9 step で検証する。
 *
 * @param {object} params
 * @param {Uint8Array} params.attestation                  CBOR バイト列
 * @param {Uint8Array} params.challenge                    サーバー発行 random 32B (DO から取得)
 * @param {string}     params.keyId                        base64 (`DCAppAttestService.generateKey()` の値)
 * @param {string}     params.bundleIdentifier             `com.solodevlab.solara`
 * @param {string}     params.teamIdentifier               `TY5JW393Q5`
 * @param {boolean}    [params.allowDevelopmentEnvironment=false]
 * @param {number}     [params.now=Date.now()]             optional、テスト用 (時刻ベース判定の基準)
 * @returns {Promise<
 *   {ok: true, publicKeyPem: string, environment: 'production'|'development', receipt: Uint8Array}
 *   | {ok: false, error: string}>}
 */
export async function verifyAttestation(params) {
  const {
    attestation,
    challenge,
    keyId,
    bundleIdentifier,
    teamIdentifier,
    allowDevelopmentEnvironment = false,
    now = Date.now(), // optional、テスト用 (production は default の Date.now())
  } = params;

  // 入力バリデーション (caller のバグを早期検出)
  if (!(attestation instanceof Uint8Array)) return { ok: false, error: 'invalid_attestation_type' };
  if (!(challenge instanceof Uint8Array)) return { ok: false, error: 'invalid_challenge_type' };
  if (typeof keyId !== 'string' || keyId.length === 0) return { ok: false, error: 'invalid_keyid_type' };
  if (typeof bundleIdentifier !== 'string' || !bundleIdentifier) return { ok: false, error: 'invalid_bundle_id' };
  if (typeof teamIdentifier !== 'string' || !teamIdentifier) return { ok: false, error: 'invalid_team_id' };

  // CBOR デコード
  let decoded;
  try {
    decoded = decodeFirst(attestation);
  } catch (_e) {
    return { ok: false, error: 'fail_cbor_decode' };
  }

  if (decoded?.fmt !== 'apple-appattest') return { ok: false, error: 'fail_fmt' };
  const attStmt = decoded.attStmt;
  if (!attStmt || typeof attStmt !== 'object') return { ok: false, error: 'fail_attstmt_missing' };
  const x5c = attStmt.x5c;
  if (!Array.isArray(x5c) || x5c.length !== 2) return { ok: false, error: 'fail_x5c_shape' };
  if (!(x5c[0] instanceof Uint8Array) || !(x5c[1] instanceof Uint8Array)) {
    return { ok: false, error: 'fail_x5c_bytes' };
  }
  const receipt = attStmt.receipt;
  if (!(receipt instanceof Uint8Array)) return { ok: false, error: 'fail_receipt_missing' };
  const authData = decoded.authData;
  if (!(authData instanceof Uint8Array) || authData.length < 88) {
    return { ok: false, error: 'fail_authdata_short' };
  }

  // X509 parse
  let certs;
  try {
    certs = x5c.map((der) => new X509Certificate(der));
  } catch (_e) {
    return { ok: false, error: 'fail_x509_parse' };
  }

  const { subCa, leaf: credCert } = partitionCerts(certs);
  if (!subCa) return { ok: false, error: 'fail_no_subca' };
  if (!credCert) return { ok: false, error: 'fail_no_credcert' };

  // ── Step 1: 証明書チェーン検証 (credCert → subCA → Apple Root CA) ──
  // signatureOnly: true → @peculiar/x509 デフォルトの notBefore/notAfter 時刻チェック
  // をスキップ (= 署名のみ検証)。時刻は §1.5 で自前判定する (理由は §1.5 コメント参照)。
  let subCaOk = false;
  let credCertOk = false;
  try {
    subCaOk = await subCa.verify({ publicKey: APPLE_ROOT_CA.publicKey, signatureOnly: true });
    credCertOk = await credCert.verify({ publicKey: subCa.publicKey, signatureOnly: true });
  } catch (_e) {
    return { ok: false, error: 'fail_cert_chain_exception' };
  }
  if (!subCaOk) return { ok: false, error: 'fail_subca_not_signed_by_root' };
  if (!credCertOk) return { ok: false, error: 'fail_credcert_not_signed_by_subca' };

  // ── Step 1.5: 時刻ベースの追加検証 (案 C+D、設計 v1.7 で追加) ──
  // node-app-attest / appattest-checker-node 等はここを実装していないが、Solara は:
  //   (C) notBefore > now + skew → 未来発行 = 偽証明書の兆候 → 拒否
  //   (D) notAfter < now           → 期限切れ = 監視対象だが通す + warning ログ
  // (D) を「通す」根拠: Apple iOS 側で attestation 再取得を強制する機構があるため
  //                     サーバー側時刻ブロックの実利は薄く、Firebase + App Check の
  //                     7 日 TTL 0% verified 障害と同パターンを避ける。
  // ただし完全無視ではなく Cloudflare Workers ログに warning を残し、本番監視で
  // 異常傾向 (= 攻撃の兆候) を検知できるようにする。
  const SKEW_MS = 5 * 60 * 1000; // clock skew 許容 5 分
  if (subCa.notBefore.getTime() > now + SKEW_MS) {
    return { ok: false, error: 'fail_subca_future_issued' };
  }
  if (credCert.notBefore.getTime() > now + SKEW_MS) {
    return { ok: false, error: 'fail_credcert_future_issued' };
  }
  if (subCa.notAfter.getTime() < now) {
    console.warn(
      `[app_attest] subCa expired at ${subCa.notAfter.toISOString()} (now=${new Date(now).toISOString()}), accepting (signature OK)`,
    );
  }
  if (credCert.notAfter.getTime() < now) {
    console.warn(
      `[app_attest] credCert expired at ${credCert.notAfter.toISOString()} for keyId=${keyId.slice(0, 8)}... (now=${new Date(now).toISOString()}), accepting (signature OK)`,
    );
  }

  // ── Step 2-3: clientDataHash = SHA-256(challenge), nonce = SHA-256(authData || clientDataHash) ──
  const clientDataHash = sha256(challenge);
  const nonce = sha256(concatBytes(authData, clientDataHash));

  // ── Step 4: credCert の Apple OID から nonce 抽出して一致確認 ──
  if (!extractAppleNonceMatches(credCert, bytesToHex(nonce))) {
    return { ok: false, error: 'fail_nonce_mismatch' };
  }

  // ── Step 5: SHA-256(credCert public key uncompressed point) == keyId ──
  let publicKeyHashB64;
  try {
    const point = extractEcUncompressedPoint(credCert.publicKey);
    publicKeyHashB64 = bytesToBase64(sha256(point));
  } catch (_e) {
    return { ok: false, error: 'fail_pubkey_extract' };
  }
  if (publicKeyHashB64 !== keyId) {
    return { ok: false, error: 'fail_keyid_mismatch' };
  }

  // ── Step 6: rpIdHash (authData[0..31]) == SHA-256(`<teamId>.<bundleId>`) ──
  const appId = `${teamIdentifier}.${bundleIdentifier}`;
  const expectedRpIdHash = sha256(new TextEncoder().encode(appId));
  const actualRpIdHash = authData.slice(0, 32);
  if (!bytesEqual(actualRpIdHash, expectedRpIdHash)) {
    return { ok: false, error: 'fail_rpid_mismatch' };
  }

  // ── Step 7: signCount (authData[33..36], big-endian uint32) == 0 ──
  const signCount = readUint32BE(authData, 33);
  if (signCount !== 0) return { ok: false, error: 'fail_signcount_nonzero' };

  // ── Step 8: AAGUID (authData[37..52]) == production or development ──
  const aaguid = authData.slice(37, 53);
  let environment;
  if (bytesEqual(aaguid, AAGUID_PRODUCTION)) {
    environment = 'production';
  } else if (bytesEqual(aaguid, AAGUID_DEVELOPMENT)) {
    if (!allowDevelopmentEnvironment) {
      return { ok: false, error: 'fail_dev_env_not_allowed' };
    }
    environment = 'development';
  } else {
    return { ok: false, error: 'fail_aaguid_invalid' };
  }

  // ── Step 9: authData の credentialId (length-prefixed) == keyId (base64) ──
  // authData[53..54] = credentialId length (big-endian uint16、必ず 32)
  const credIdLen = readUint16BE(authData, 53);
  if (credIdLen !== 32) return { ok: false, error: 'fail_credid_length_invalid' };
  if (authData.length < 55 + credIdLen) return { ok: false, error: 'fail_credid_overflow' };
  const credentialId = authData.slice(55, 55 + credIdLen);
  if (bytesToBase64(credentialId) !== keyId) {
    return { ok: false, error: 'fail_credentialid_mismatch' };
  }

  // 全 step 通過 → 公開鍵 (PEM 形式) を呼び出し元に返す
  const publicKeySpkiDer = new Uint8Array(credCert.publicKey.rawData);
  const publicKeyPem = derToPem(publicKeySpkiDer, 'PUBLIC KEY');

  return {
    ok: true,
    publicKeyPem,
    environment,
    receipt,
  };
}

/**
 * DER (Uint8Array) → PEM string ( `-----BEGIN <label>-----\n<base64>\n-----END <label>-----` )
 * verifyAssertion 側で `createPublicKey(pem)` に渡す形式。
 */
function derToPem(der, label) {
  const b64 = bytesToBase64(der);
  const lines = [];
  for (let i = 0; i < b64.length; i += 64) {
    lines.push(b64.slice(i, i + 64));
  }
  return `-----BEGIN ${label}-----\n${lines.join('\n')}\n-----END ${label}-----\n`;
}
