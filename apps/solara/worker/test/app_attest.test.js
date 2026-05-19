/**
 * apps/solara/worker/src/auth/app_attest.js verifyAttestation の単体テスト
 *
 * 実行: cd apps/solara/worker && node --test test/app_attest.test.js
 *
 * fixture: node-app-attest test/fixtures (MIT) を流用、bundle/team は元のテストアプリ
 *   io.uebelacker.AppAttestExample / V8H6LQ9448 を使う (rpId 一致のため)
 *
 * カバー範囲:
 *   - 正常系 (production + development) で 9 step 全パス
 *   - allowDevelopmentEnvironment ゲート
 *   - Step 4 (nonce) / Step 5 (keyId) / Step 6 (rpId, team/bundle) の改竄検出
 *   - CBOR / 入力バリデーションエラー
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { verifyAttestation } from '../src/auth/app_attest.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

function loadFixture(name) {
  return JSON.parse(readFileSync(join(__dirname, 'fixtures', name), 'utf8'));
}

function b64ToBytes(s) {
  return new Uint8Array(Buffer.from(s, 'base64'));
}

// node-app-attest test fixture の bundle/team (rpId 計算で必須)
const FIXTURE_BUNDLE = 'io.uebelacker.AppAttestExample';
const FIXTURE_TEAM = 'V8H6LQ9448';

// ── 正常系 ───────────────────────────────────────────────

test('production fixture: 9 step 全パス', async () => {
  const fx = loadFixture('attestation-production.json');
  const result = await verifyAttestation({
    attestation: b64ToBytes(fx.attestation),
    challenge: b64ToBytes(fx.challenge),
    keyId: fx.keyId,
    bundleIdentifier: FIXTURE_BUNDLE,
    teamIdentifier: FIXTURE_TEAM,
    allowDevelopmentEnvironment: false,
  });
  assert.equal(result.ok, true, `expected ok, got ${JSON.stringify(result)}`);
  assert.equal(result.environment, 'production');
  assert.ok(result.publicKeyPem.startsWith('-----BEGIN PUBLIC KEY-----\n'));
  assert.ok(result.publicKeyPem.endsWith('-----END PUBLIC KEY-----\n'));
  assert.ok(result.receipt instanceof Uint8Array);
  assert.ok(result.receipt.length > 1000); // ~5KB
});

test('development fixture: allowDev=true で全パス', async () => {
  const fx = loadFixture('attestation-development.json');
  const result = await verifyAttestation({
    attestation: b64ToBytes(fx.attestation),
    challenge: b64ToBytes(fx.challenge),
    keyId: fx.keyId,
    bundleIdentifier: FIXTURE_BUNDLE,
    teamIdentifier: FIXTURE_TEAM,
    allowDevelopmentEnvironment: true,
  });
  assert.equal(result.ok, true, `expected ok, got ${JSON.stringify(result)}`);
  assert.equal(result.environment, 'development');
});

test('development fixture: allowDev=false (デフォルト) で fail_dev_env_not_allowed', async () => {
  const fx = loadFixture('attestation-development.json');
  const result = await verifyAttestation({
    attestation: b64ToBytes(fx.attestation),
    challenge: b64ToBytes(fx.challenge),
    keyId: fx.keyId,
    bundleIdentifier: FIXTURE_BUNDLE,
    teamIdentifier: FIXTURE_TEAM,
    // allowDevelopmentEnvironment: false (default)
  });
  assert.equal(result.ok, false);
  assert.equal(result.error, 'fail_dev_env_not_allowed');
});

// ── 改竄ケース (production fixture をベースに 1 項目ずつ変える) ─────

test('challenge 改竄 → fail_nonce_mismatch', async () => {
  const fx = loadFixture('attestation-production.json');
  const tampered = b64ToBytes(fx.challenge);
  tampered[0] ^= 0xff; // 1 ビット反転
  const result = await verifyAttestation({
    attestation: b64ToBytes(fx.attestation),
    challenge: tampered,
    keyId: fx.keyId,
    bundleIdentifier: FIXTURE_BUNDLE,
    teamIdentifier: FIXTURE_TEAM,
  });
  assert.equal(result.ok, false);
  assert.equal(result.error, 'fail_nonce_mismatch');
});

test('keyId 改竄 (last char 変更) → fail_keyid_mismatch', async () => {
  const fx = loadFixture('attestation-production.json');
  // keyId は base64 32B SHA-256 → 最後の文字を別の有効 base64 char に変える
  const keyId = fx.keyId.endsWith('=') ? fx.keyId.replace(/=$/, 'A=') : fx.keyId + 'A=';
  const result = await verifyAttestation({
    attestation: b64ToBytes(fx.attestation),
    challenge: b64ToBytes(fx.challenge),
    keyId,
    bundleIdentifier: FIXTURE_BUNDLE,
    teamIdentifier: FIXTURE_TEAM,
  });
  assert.equal(result.ok, false);
  assert.equal(result.error, 'fail_keyid_mismatch');
});

test('teamIdentifier 違い → fail_rpid_mismatch', async () => {
  const fx = loadFixture('attestation-production.json');
  const result = await verifyAttestation({
    attestation: b64ToBytes(fx.attestation),
    challenge: b64ToBytes(fx.challenge),
    keyId: fx.keyId,
    bundleIdentifier: FIXTURE_BUNDLE,
    teamIdentifier: 'TY5JW393Q5', // Solara のだが fixture とは別
  });
  assert.equal(result.ok, false);
  assert.equal(result.error, 'fail_rpid_mismatch');
});

test('bundleIdentifier 違い → fail_rpid_mismatch', async () => {
  const fx = loadFixture('attestation-production.json');
  const result = await verifyAttestation({
    attestation: b64ToBytes(fx.attestation),
    challenge: b64ToBytes(fx.challenge),
    keyId: fx.keyId,
    bundleIdentifier: 'com.solodevlab.solara',
    teamIdentifier: FIXTURE_TEAM,
  });
  assert.equal(result.ok, false);
  assert.equal(result.error, 'fail_rpid_mismatch');
});

test('attestation バイト改竄 (credCert DER 内 = offset 500) → 証明書チェーン or CBOR 失敗', async () => {
  // CBOR 構造的順序: header (~10B) → x5c[0] credCert (~1KB) → x5c[1] subCA (~600B)
  //                  → receipt (~5KB) → authData (~200B)
  // offset 500 は credCert DER の中央付近 = 改竄すると署名検証 or X.509 parse で落ちる
  const fx = loadFixture('attestation-production.json');
  const tampered = b64ToBytes(fx.attestation);
  tampered[500] ^= 0xff;
  const result = await verifyAttestation({
    attestation: tampered,
    challenge: b64ToBytes(fx.challenge),
    keyId: fx.keyId,
    bundleIdentifier: FIXTURE_BUNDLE,
    teamIdentifier: FIXTURE_TEAM,
  });
  assert.equal(result.ok, false);
  assert.ok(
    [
      'fail_cbor_decode',
      'fail_x509_parse',
      'fail_x5c_bytes',
      'fail_x5c_shape',
      'fail_subca_not_signed_by_root',
      'fail_credcert_not_signed_by_subca',
      'fail_cert_chain_exception',
      'fail_nonce_mismatch',
      'fail_keyid_mismatch',
    ].includes(result.error),
    `unexpected error: ${result.error}`,
  );
});

test('attestation の receipt 部分 (中央) 改竄 → 検証対象外なので ok: true (設計通り)', async () => {
  // verifyAttestation は Step 1-9 のみ。receipt は Apple Server-to-Server API
  // (将来) 用に保存するだけで、内容は検証しない。
  const fx = loadFixture('attestation-production.json');
  const tampered = b64ToBytes(fx.attestation);
  tampered[Math.floor(tampered.length / 2)] ^= 0xff; // receipt 内
  const result = await verifyAttestation({
    attestation: tampered,
    challenge: b64ToBytes(fx.challenge),
    keyId: fx.keyId,
    bundleIdentifier: FIXTURE_BUNDLE,
    teamIdentifier: FIXTURE_TEAM,
  });
  // 改竄位置が receipt 内なら ok: true で抜ける (設計通り)。
  // ただし運悪く CBOR 境界に当たった場合は fail_cbor_decode も許容。
  if (!result.ok) {
    assert.equal(result.error, 'fail_cbor_decode', `unexpected: ${result.error}`);
  }
});

test('空の attestation → fail_cbor_decode', async () => {
  const result = await verifyAttestation({
    attestation: new Uint8Array(0),
    challenge: new Uint8Array(32),
    keyId: 'AAAA',
    bundleIdentifier: FIXTURE_BUNDLE,
    teamIdentifier: FIXTURE_TEAM,
  });
  assert.equal(result.ok, false);
  assert.equal(result.error, 'fail_cbor_decode');
});

test('fmt が違う CBOR → fail_fmt', async () => {
  // {fmt: "fake", attStmt: {}, authData: <88 bytes>}
  // CBOR: map(3) "fmt" "fake" "attStmt" {} "authData" <bytes(88)>
  const fakeBytes = Buffer.from(
    'a3' + // map of 3
    '63666d74' + '6466616b65' + // "fmt" -> "fake"
    '676174745374' + '6dt' + 'a0' + // "attStmt" -> {} (この行は壊れた hex、書き直す)
    '68617574684461' + '7461' + '5858' + '00'.repeat(88), // "authData" -> bytes(88) of zero
    'hex',
  );
  // 上記 hex は手書きで壊れる可能性高いので、実装側で CBOR テストを別に書く
  // ここは「不正な fmt は弾かれる」を確認する目的
  // → 実 fixture の fmt 文字列をバイトレベルで書き換え
  const fx = loadFixture('attestation-production.json');
  const orig = b64ToBytes(fx.attestation);
  // "apple-appattest" は CBOR text-string 0x6f (15) + "apple-appattest" の 16 バイト
  // 探して 1 文字を変える
  const sig = new TextEncoder().encode('apple-appattest');
  let pos = -1;
  for (let i = 0; i < orig.length - sig.length; i++) {
    let match = true;
    for (let j = 0; j < sig.length; j++) {
      if (orig[i + j] !== sig[j]) { match = false; break; }
    }
    if (match) { pos = i; break; }
  }
  assert.notEqual(pos, -1, 'should find apple-appattest in attestation');
  const tampered = new Uint8Array(orig);
  tampered[pos] = 0x42; // 'B' に書き換え (= "Bpple-appattest")
  const result = await verifyAttestation({
    attestation: tampered,
    challenge: b64ToBytes(fx.challenge),
    keyId: fx.keyId,
    bundleIdentifier: FIXTURE_BUNDLE,
    teamIdentifier: FIXTURE_TEAM,
  });
  assert.equal(result.ok, false);
  assert.equal(result.error, 'fail_fmt');
});

// ── 入力バリデーション (caller 側のバグ早期検出) ───────────

test('invalid: attestation が Uint8Array でない → invalid_attestation_type', async () => {
  const result = await verifyAttestation({
    attestation: 'not bytes',
    challenge: new Uint8Array(32),
    keyId: 'k',
    bundleIdentifier: 'b',
    teamIdentifier: 't',
  });
  assert.equal(result.error, 'invalid_attestation_type');
});

test('invalid: challenge が Uint8Array でない → invalid_challenge_type', async () => {
  const result = await verifyAttestation({
    attestation: new Uint8Array(10),
    challenge: 'string',
    keyId: 'k',
    bundleIdentifier: 'b',
    teamIdentifier: 't',
  });
  assert.equal(result.error, 'invalid_challenge_type');
});

test('invalid: 空 keyId → invalid_keyid_type', async () => {
  const result = await verifyAttestation({
    attestation: new Uint8Array(10),
    challenge: new Uint8Array(32),
    keyId: '',
    bundleIdentifier: 'b',
    teamIdentifier: 't',
  });
  assert.equal(result.error, 'invalid_keyid_type');
});

test('invalid: 空 bundleIdentifier → invalid_bundle_id', async () => {
  const result = await verifyAttestation({
    attestation: new Uint8Array(10),
    challenge: new Uint8Array(32),
    keyId: 'k',
    bundleIdentifier: '',
    teamIdentifier: 't',
  });
  assert.equal(result.error, 'invalid_bundle_id');
});

test('invalid: 空 teamIdentifier → invalid_team_id', async () => {
  const result = await verifyAttestation({
    attestation: new Uint8Array(10),
    challenge: new Uint8Array(32),
    keyId: 'k',
    bundleIdentifier: 'b',
    teamIdentifier: '',
  });
  assert.equal(result.error, 'invalid_team_id');
});

// ── 時刻チェック (案 C+D) ────────────────────────────────

test('時刻チェック C: now が credCert の notBefore より過去 → fail_credcert_future_issued', async () => {
  // fixture credCert は notBefore = 2024-02-06。now を 2023 にすると未来発行扱い。
  const fx = loadFixture('attestation-production.json');
  const result = await verifyAttestation({
    attestation: b64ToBytes(fx.attestation),
    challenge: b64ToBytes(fx.challenge),
    keyId: fx.keyId,
    bundleIdentifier: FIXTURE_BUNDLE,
    teamIdentifier: FIXTURE_TEAM,
    now: new Date('2023-01-01T00:00:00Z').getTime(), // fixture より過去
  });
  assert.equal(result.ok, false);
  // subCa の notBefore は 2020-03-18 なので、subCa は未来扱いにならず credCert で落ちる
  assert.equal(result.error, 'fail_credcert_future_issued');
});

test('時刻チェック C: clock skew 5 分は許容 (skew 内なら通る)', async () => {
  const fx = loadFixture('attestation-production.json');
  // fixture credCert notBefore = 2024-02-06T21:08:56Z、その 3 分前 (skew 5 分内)
  const credCertNotBefore = new Date('2024-02-06T21:08:56Z').getTime();
  const result = await verifyAttestation({
    attestation: b64ToBytes(fx.attestation),
    challenge: b64ToBytes(fx.challenge),
    keyId: fx.keyId,
    bundleIdentifier: FIXTURE_BUNDLE,
    teamIdentifier: FIXTURE_TEAM,
    now: credCertNotBefore - 3 * 60 * 1000, // 3 分前 (skew 5 分内なので通る)
  });
  assert.equal(result.ok, true, `expected ok with 3min skew, got ${JSON.stringify(result)}`);
});

test('時刻チェック D: expired credCert は通すが console.warn を出す', async () => {
  // production fixture credCert notAfter = 2024-12-21、現在は 2026-05-19 で expired
  // → ok: true を返しつつ console.warn でログ出力
  const fx = loadFixture('attestation-production.json');
  const warnMessages = [];
  const origWarn = console.warn;
  console.warn = (msg) => warnMessages.push(msg);
  try {
    const result = await verifyAttestation({
      attestation: b64ToBytes(fx.attestation),
      challenge: b64ToBytes(fx.challenge),
      keyId: fx.keyId,
      bundleIdentifier: FIXTURE_BUNDLE,
      teamIdentifier: FIXTURE_TEAM,
      // now: default (Date.now())
    });
    assert.equal(result.ok, true);
    // credCert expired の warning が 1 件以上
    assert.ok(
      warnMessages.some((m) => m.includes('credCert expired')),
      `expected credCert expired warning, got: ${warnMessages.join(' | ')}`,
    );
  } finally {
    console.warn = origWarn;
  }
});

// ── 戻り値の構造確認 ────────────────────────────────────

test('publicKeyPem が PEM 形式で createPublicKey 可能 (assertion 検証の前提)', async () => {
  const fx = loadFixture('attestation-production.json');
  const result = await verifyAttestation({
    attestation: b64ToBytes(fx.attestation),
    challenge: b64ToBytes(fx.challenge),
    keyId: fx.keyId,
    bundleIdentifier: FIXTURE_BUNDLE,
    teamIdentifier: FIXTURE_TEAM,
  });
  assert.equal(result.ok, true);
  // node:crypto.createPublicKey で読めるか (verifyAssertion で使う形式)
  const { createPublicKey } = await import('node:crypto');
  const pk = createPublicKey(result.publicKeyPem);
  assert.equal(pk.asymmetricKeyType, 'ec');
  assert.equal(pk.asymmetricKeyDetails.namedCurve, 'prime256v1'); // = P-256
});
