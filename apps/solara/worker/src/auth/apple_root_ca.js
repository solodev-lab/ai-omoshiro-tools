/**
 * Apple App Attest 検証で使う定数とヘルパー。
 *
 * - APPLE_ROOT_CA_PEM: 2045-03-15 まで有効な Apple App Attestation Root CA (ECDSA P-384 self-signed)
 *   フィンガープリント SHA-256(DER) = 1CB9823BA28BA6AD2D33A006941DE2AE4F513EF1D4E831B9F7E0FA7B6242C932
 *   原本: apps/solara/docs/Apple_App_Attestation_Root_CA.pem
 * - AAGUID_PRODUCTION / AAGUID_DEVELOPMENT: authData[37..52] と比較する 16 バイト
 * - APPLE_NONCE_OID: credCert の Apple 独自拡張 OID
 * - SUB_CA_SUBJECT_HINT: 中間 CA の subject に必ず含まれる文字列
 */

export const APPLE_ROOT_CA_PEM = `-----BEGIN CERTIFICATE-----
MIICITCCAaegAwIBAgIQC/O+DvHN0uD7jG5yH2IXmDAKBggqhkjOPQQDAzBSMSYw
JAYDVQQDDB1BcHBsZSBBcHAgQXR0ZXN0YXRpb24gUm9vdCBDQTETMBEGA1UECgwK
QXBwbGUgSW5jLjETMBEGA1UECAwKQ2FsaWZvcm5pYTAeFw0yMDAzMTgxODMyNTNa
Fw00NTAzMTUwMDAwMDBaMFIxJjAkBgNVBAMMHUFwcGxlIEFwcCBBdHRlc3RhdGlv
biBSb290IENBMRMwEQYDVQQKDApBcHBsZSBJbmMuMRMwEQYDVQQIDApDYWxpZm9y
bmlhMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAERTHhmLW07ATaFQIEVwTtT4dyctdh
NbJhFs/Ii2FdCgAHGbpphY3+d8qjuDngIN3WVhQUBHAoMeQ/cLiP1sOUtgjqK9au
Yen1mMEvRq9Sk3Jm5X8U62H+xTD3FE9TgS41o0IwQDAPBgNVHRMBAf8EBTADAQH/
MB0GA1UdDgQWBBSskRBTM72+aEH/pwyp5frq5eWKoTAOBgNVHQ8BAf8EBAMCAQYw
CgYIKoZIzj0EAwMDaAAwZQIwQgFGnByvsiVbpTKwSga0kP0e8EeDS4+sQmTvb7vn
53O5+FRXgeLhpJ06ysC5PrOyAjEAp5U4xDgEgllF7En3VcE3iexZZtKeYnpqtijV
oyFraWVIyd/dganmrduC1bmTBGwD
-----END CERTIFICATE-----`;

// authData[37..52] と比較する 16 バイト
// production: ASCII "appattest" (9B) + NULL バイト 7 個
export const AAGUID_PRODUCTION = new Uint8Array([
  0x61, 0x70, 0x70, 0x61, 0x74, 0x74, 0x65, 0x73, 0x74,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
]);

// development: ASCII "appattestdevelop" (16B)
export const AAGUID_DEVELOPMENT = new Uint8Array([
  0x61, 0x70, 0x70, 0x61, 0x74, 0x74, 0x65, 0x73,
  0x74, 0x64, 0x65, 0x76, 0x65, 0x6c, 0x6f, 0x70,
]);

export const APPLE_NONCE_OID = '1.2.840.113635.100.8.2';

// 中間 CA (subCA) の subject 内に必ず含まれる文字列。
// 完全な subject 例: "CN=Apple App Attestation CA 1, O=Apple Inc., ST=California"
export const SUB_CA_SUBJECT_HINT = 'Apple App Attestation CA 1';

/**
 * 2 つの Uint8Array を結合した新しい Uint8Array を返す。
 */
export function concatBytes(a, b) {
  const out = new Uint8Array(a.length + b.length);
  out.set(a, 0);
  out.set(b, a.length);
  return out;
}

/**
 * 2 つの Uint8Array が同じ長さで全バイト一致するか (timing-safe ではないが、
 * 攻撃面では nonce/keyId/AAGUID 比較なので timing leak の意味は薄い)。
 */
export function bytesEqual(a, b) {
  if (a.length !== b.length) return false;
  for (let i = 0; i < a.length; i++) {
    if (a[i] !== b[i]) return false;
  }
  return true;
}

/**
 * Uint8Array → 16進 string (小文字)
 */
export function bytesToHex(bytes) {
  let s = '';
  for (let i = 0; i < bytes.length; i++) {
    s += bytes[i].toString(16).padStart(2, '0');
  }
  return s;
}

/**
 * Uint8Array → base64 string (Workers/Node 両対応、Buffer 経由)
 */
export function bytesToBase64(bytes) {
  // Buffer は nodejs_compat フラグで Workers でも使える
  return Buffer.from(bytes).toString('base64');
}

/**
 * base64 string → Uint8Array
 */
export function base64ToBytes(b64) {
  return new Uint8Array(Buffer.from(b64, 'base64'));
}

/**
 * authData の特定オフセットから big-endian uint32 を読む。
 * (subarray が same buffer を共有するので byteOffset を明示)
 */
export function readUint32BE(bytes, offset) {
  const dv = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  return dv.getUint32(offset, false);
}

/**
 * authData の特定オフセットから big-endian uint16 を読む。
 */
export function readUint16BE(bytes, offset) {
  const dv = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  return dv.getUint16(offset, false);
}
