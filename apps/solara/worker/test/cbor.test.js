/**
 * apps/solara/worker/src/auth/cbor.js の単体テスト
 *
 * 実行: cd apps/solara/worker && node --test test/cbor.test.js
 *
 * テストカバー:
 *   - 基本的な major types (0/2/3/4/5)
 *   - length encoding 全パターン (info < 24, info = 24/25/26)
 *   - エラーケース (truncated, invalid UTF-8, extra bytes, unsupported)
 *   - 実 attestation fixture (production + development) で fmt / x5c.length / authData などの構造確認
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { decodeFirst, CborError } from '../src/auth/cbor.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

function hex(s) {
  return new Uint8Array(s.replace(/\s/g, '').match(/.{2}/g).map((b) => parseInt(b, 16)));
}

// ── 基本 major types ────────────────────────────────────────

test('unsigned int (major 0) — info < 24', () => {
  assert.equal(decodeFirst(hex('00')), 0);
  assert.equal(decodeFirst(hex('01')), 1);
  assert.equal(decodeFirst(hex('17')), 23);
});

test('unsigned int (major 0) — 1-byte length (info 24)', () => {
  assert.equal(decodeFirst(hex('1818')), 24);
  assert.equal(decodeFirst(hex('18ff')), 255);
});

test('unsigned int (major 0) — 2-byte length (info 25)', () => {
  assert.equal(decodeFirst(hex('190100')), 256);
  assert.equal(decodeFirst(hex('19ffff')), 65535);
});

test('unsigned int (major 0) — 4-byte length (info 26)', () => {
  assert.equal(decodeFirst(hex('1a00010000')), 65536);
  assert.equal(decodeFirst(hex('1affffffff')), 4294967295); // 2^32 - 1
});

test('byte string (major 2) — empty', () => {
  const v = decodeFirst(hex('40'));
  assert.ok(v instanceof Uint8Array);
  assert.equal(v.length, 0);
});

test('byte string (major 2) — short', () => {
  const v = decodeFirst(hex('43010203'));
  assert.deepEqual(Array.from(v), [0x01, 0x02, 0x03]);
});

test('byte string (major 2) — 1-byte length', () => {
  const payload = new Array(30).fill(0xaa);
  const input = hex('581e' + 'aa'.repeat(30));
  const v = decodeFirst(input);
  assert.deepEqual(Array.from(v), payload);
});

test('byte string (major 2) — 2-byte length (1024 bytes)', () => {
  const len = 1024;
  const input = new Uint8Array(3 + len);
  input[0] = 0x59;
  input[1] = (len >> 8) & 0xff;
  input[2] = len & 0xff;
  for (let i = 0; i < len; i++) input[3 + i] = i & 0xff;
  const v = decodeFirst(input);
  assert.equal(v.length, len);
  assert.equal(v[0], 0);
  assert.equal(v[255], 255);
  assert.equal(v[1023], 255);
});

test('text string (major 3) — apple-appattest', () => {
  // 0x6f = major 3, length 15 (= len of "apple-appattest")
  const v = decodeFirst(hex('6f' + Buffer.from('apple-appattest').toString('hex')));
  assert.equal(v, 'apple-appattest');
});

test('text string (major 3) — UTF-8 multi-byte', () => {
  const text = 'こんにちは';
  const utf8 = new TextEncoder().encode(text);
  const input = new Uint8Array(2 + utf8.length);
  input[0] = 0x78; // major 3, info 24 (1-byte length)
  input[1] = utf8.length;
  input.set(utf8, 2);
  assert.equal(decodeFirst(input), text);
});

test('array (major 4) — [1, 2, 3]', () => {
  const v = decodeFirst(hex('83010203'));
  assert.deepEqual(v, [1, 2, 3]);
});

test('array (major 4) — nested', () => {
  // [[1, 2], [3]]
  const v = decodeFirst(hex('82' + '82' + '0102' + '81' + '03'));
  assert.deepEqual(v, [[1, 2], [3]]);
});

test('map (major 5) — {a: 1, b: [2, 3]}', () => {
  const v = decodeFirst(hex('a26161016162820203'));
  assert.deepEqual(v, { a: 1, b: [2, 3] });
});

test('map (major 5) — values can be byte string', () => {
  // {sig: <3 bytes>, ad: <1 byte>}
  const input = hex('a2' + '63736967' + '43010203' + '626164' + '4109');
  const v = decodeFirst(input);
  assert.deepEqual(Object.keys(v), ['sig', 'ad']);
  assert.deepEqual(Array.from(v.sig), [1, 2, 3]);
  assert.deepEqual(Array.from(v.ad), [9]);
});

// ── エラーケース ──────────────────────────────────────────

test('error: truncated 1-byte length', () => {
  assert.throws(() => decodeFirst(hex('18')), CborError);
});

test('error: byte string overflow', () => {
  // 0x45 = byte string length 5, but only 3 bytes after
  assert.throws(() => decodeFirst(hex('45010203')), CborError);
});

test('error: invalid UTF-8 in text string', () => {
  // major 3 length 1, byte 0xff (invalid as standalone UTF-8)
  assert.throws(() => decodeFirst(hex('61ff')), CborError);
});

test('error: map key not string', () => {
  // {1: 2} — key is int, not string
  assert.throws(() => decodeFirst(hex('a10102')), CborError);
});

test('error: unsupported major type (negative int)', () => {
  // 0x20 = major 1 (negative int)
  assert.throws(() => decodeFirst(hex('20')), CborError);
});

test('error: extra bytes after top-level', () => {
  // 0x01 (uint 1) + 0x02 (extra)
  assert.throws(() => decodeFirst(hex('0102')), CborError);
});

test('error: non-Uint8Array input', () => {
  assert.throws(() => decodeFirst([0x01]), CborError);
  assert.throws(() => decodeFirst('01'), CborError);
});

// ── 実 attestation fixture (node-app-attest, MIT) ───────────────

function loadFixture(name) {
  const path = join(__dirname, 'fixtures', name);
  return JSON.parse(readFileSync(path, 'utf8'));
}

function b64ToBytes(s) {
  const bin = Buffer.from(s, 'base64');
  return new Uint8Array(bin);
}

test('real attestation (production fixture) — top-level structure', () => {
  const fx = loadFixture('attestation-production.json');
  const bytes = b64ToBytes(fx.attestation);
  const obj = decodeFirst(bytes);
  // 期待: { fmt: "apple-appattest", attStmt: {...}, authData: Uint8Array }
  assert.equal(obj.fmt, 'apple-appattest');
  assert.equal(typeof obj.attStmt, 'object');
  assert.ok(obj.authData instanceof Uint8Array);
  assert.ok(obj.authData.length >= 88, 'authData should be at least 88 bytes');
});

test('real attestation (production fixture) — attStmt structure', () => {
  const fx = loadFixture('attestation-production.json');
  const obj = decodeFirst(b64ToBytes(fx.attestation));
  // 期待: attStmt = { x5c: [credCert, intermediate], receipt: Uint8Array }
  assert.ok(Array.isArray(obj.attStmt.x5c));
  assert.equal(obj.attStmt.x5c.length, 2);
  assert.ok(obj.attStmt.x5c[0] instanceof Uint8Array);
  assert.ok(obj.attStmt.x5c[1] instanceof Uint8Array);
  assert.ok(obj.attStmt.x5c[0].length > 500, 'credCert should be ~1KB');
  assert.ok(obj.attStmt.x5c[1].length > 500, 'intermediate should be ~600B');
  assert.ok(obj.attStmt.receipt instanceof Uint8Array);
  assert.ok(obj.attStmt.receipt.length > 1000, 'receipt should be ~5KB');
});

test('real attestation (production fixture) — authData AAGUID = appattest+NULL×7', () => {
  const fx = loadFixture('attestation-production.json');
  const obj = decodeFirst(b64ToBytes(fx.attestation));
  // authData[37..52] が AAGUID (16B)、production なら 'appattest' + 7 NULL
  const aaguid = obj.authData.slice(37, 53);
  const expected = new Uint8Array([
    0x61, 0x70, 0x70, 0x61, 0x74, 0x74, 0x65, 0x73, 0x74, // "appattest" (9B)
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,             // NULL × 7
  ]);
  assert.deepEqual(Array.from(aaguid), Array.from(expected));
});

test('real attestation (development fixture) — authData AAGUID = appattestdevelop', () => {
  const fx = loadFixture('attestation-development.json');
  const obj = decodeFirst(b64ToBytes(fx.attestation));
  const aaguid = obj.authData.slice(37, 53);
  // 'appattestdevelop' (16B ASCII)
  const expected = new TextEncoder().encode('appattestdevelop');
  assert.deepEqual(Array.from(aaguid), Array.from(expected));
});

test('real assertion (from test fixture) — top-level structure', () => {
  const fx = loadFixture('assertion.json');
  const obj = decodeFirst(b64ToBytes(fx.assertion));
  // 期待: { signature: Uint8Array, authenticatorData: Uint8Array }
  assert.ok(obj.signature instanceof Uint8Array);
  assert.ok(obj.authenticatorData instanceof Uint8Array);
  // signature は DER P-256 ECDSA で 70-72 bytes が典型
  assert.ok(obj.signature.length >= 64 && obj.signature.length <= 72, `signature length unusual: ${obj.signature.length}`);
  assert.equal(obj.signature[0], 0x30, 'DER SEQUENCE marker');
  // authenticatorData は rpIdHash 32 + flags 1 + signCount 4 = 37 bytes 以上
  assert.ok(obj.authenticatorData.length >= 37);
});
