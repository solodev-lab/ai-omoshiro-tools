/**
 * R1 検証用 minimal Worker (本番には絶対 deploy しない、検証後に削除)
 *
 * 案 B' (ハイブリッド) の 3 つの中核操作が Cloudflare Workers (nodejs_compat 有効)
 * で実機動作するかを実機で確認するだけの test worker。
 *
 *   /r1/x509          — @peculiar/x509 で Apple Root CA を parse + 自己署名 verify
 *   /r1/cbor          — 自前 minimal CBOR decoder (Apple App Attest subset の元) の動作
 *   /r1/createverify  — node:crypto の createSign/createVerify で ECDSA P-256 + DER 署名
 *   /r1/all           — 3 つを一括実行してまとめて返す
 *
 * 起動: cd apps/solara/worker && npx wrangler dev --config r1_check/wrangler.toml
 * 確認: curl http://127.0.0.1:8787/r1/all | jq
 */
import { X509Certificate } from '@peculiar/x509';
import { createVerify, createSign, generateKeyPairSync } from 'node:crypto';

// Apple App Attestation Root CA (DER → PEM、apps/solara/docs/ の保存版と一致)
const APPLE_ROOT_PEM = `-----BEGIN CERTIFICATE-----
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

async function checkX509() {
  const cert = new X509Certificate(APPLE_ROOT_PEM);
  const selfVerified = await cert.verify({ publicKey: cert.publicKey });
  return {
    subject: cert.subject,
    issuer: cert.issuer,
    selfSigned: cert.subject === cert.issuer,
    selfVerified,
    notBefore: cert.notBefore.toISOString(),
    notAfter: cert.notAfter.toISOString(),
    publicKeyAlgorithm: cert.publicKey.algorithm,
  };
}

// 期待: {"a": 1, "b": [2, 3]} を CBOR エンコードしたもの
// 0xa2  (map of 2)
//   0x61 0x61 (text "a")  0x01 (uint 1)
//   0x61 0x62 (text "b")  0x82 (array of 2)  0x02 0x03
function checkCbor() {
  const hex = 'a26161016162820203';
  const bytes = new Uint8Array(hex.match(/.{2}/g).map((h) => parseInt(h, 16)));
  let i = 0;

  function decode() {
    const initial = bytes[i++];
    const major = initial >> 5;
    const arg = initial & 0x1f;
    if (major === 0) return arg; // unsigned int (subset)
    if (major === 3) {
      const s = new TextDecoder().decode(bytes.slice(i, i + arg));
      i += arg;
      return s;
    }
    if (major === 4) {
      const arr = [];
      for (let j = 0; j < arg; j++) arr.push(decode());
      return arr;
    }
    if (major === 5) {
      const m = {};
      for (let j = 0; j < arg; j++) {
        const k = decode();
        m[k] = decode();
      }
      return m;
    }
    throw new Error(`unsupported major type ${major}`);
  }

  const decoded = decode();
  const expected = { a: 1, b: [2, 3] };
  return {
    decoded,
    expected,
    match: JSON.stringify(decoded) === JSON.stringify(expected),
  };
}

function checkCreateVerify() {
  const { privateKey, publicKey } = generateKeyPairSync('ec', { namedCurve: 'P-256' });
  const message = new TextEncoder().encode('hello app attest');
  const signer = createSign('SHA256');
  signer.update(message);
  const derSig = signer.sign(privateKey);
  const verifier = createVerify('SHA256');
  verifier.update(message);
  const ok = verifier.verify(publicKey, derSig);
  return {
    verifyOk: ok,
    sigByteLength: derSig.length,
    sigStartsWith0x30: derSig[0] === 0x30, // DER SEQUENCE marker
    sigSecondByte: derSig[1],
    looksLikeDer: derSig[0] === 0x30 && derSig.length >= 70 && derSig.length <= 72,
  };
}

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const path = url.pathname;

    try {
      if (path === '/r1/x509') {
        return Response.json({ ok: true, ...(await checkX509()) });
      }
      if (path === '/r1/cbor') {
        return Response.json({ ok: true, ...checkCbor() });
      }
      if (path === '/r1/createverify') {
        return Response.json({ ok: true, ...checkCreateVerify() });
      }
      if (path === '/r1/all') {
        const x509 = await checkX509();
        const cbor = checkCbor();
        const cv = checkCreateVerify();
        return Response.json({
          summary: {
            x509_ok: x509.selfVerified,
            cbor_ok: cbor.match,
            createverify_ok: cv.verifyOk,
            all_pass: x509.selfVerified && cbor.match && cv.verifyOk,
          },
          x509,
          cbor,
          createverify: cv,
        });
      }
      return new Response('Use /r1/x509, /r1/cbor, /r1/createverify, or /r1/all', { status: 404 });
    } catch (err) {
      return Response.json({ ok: false, error: err.message, stack: err.stack }, { status: 500 });
    }
  },
};
