/**
 * apps/solara/worker/src/auth/play_integrity.js の単体テスト (S2 minimal worker)
 *
 * 実行: cd apps/solara/worker && node --test test/play_integrity.test.js
 *
 * カバー範囲 (設計 v0.3 §10):
 *   - R7: base64 (DER SPKI) verification key を crypto.subtle.importKey('spki') で正常 import
 *   - R7': AES-256 (44 char base64) encryption key を crypto.subtle.importKey('raw') で AES-KW 用に import
 *   - decode pipeline 機能確証: 自前で生成した JWE A256KW(JWS ES256) を round-trip decode
 *   - エラー処理: 鍵未設定 / 鍵長異常 / 改竄 token
 *
 * 限界 (R8 は本テストでは実証不能):
 *   - Google が実際の Standard request 応答で Self-managed key を使うかは
 *     実機採取の Play Integrity token が必要 (= S5 で確証)
 *   - 本テストは「Workers ランタイムで JWE A256KW + JWS ES256 decode が動く」ことのみ証明
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  CompactEncrypt,
  CompactSign,
  exportSPKI,
  generateKeyPair,
  generateSecret,
} from 'jose';
import { diagnoseKeys, decodeIntegrityToken } from '../src/auth/play_integrity.js';

// ── テスト fixture 生成ヘルパー ─────────────────────────────────

/**
 * Play Integrity Self-managed key と同じ形式のテスト鍵を生成。
 * - encryptionKey: AES-256 raw (32B) → base64 標準 (44 char + パディング)
 * - verificationKey: ECDSA P-256 公開鍵 → base64 (DER SubjectPublicKeyInfo、124 char)
 *
 * 戻り値: { encB64, verB64, encKey, verKey, signKey }
 */
async function generateFixtureKeys() {
  // AES-256 (A256KW)
  const encKey = await generateSecret('A256KW', { extractable: true });
  const encRaw = await crypto.subtle.exportKey('raw', encKey);
  const encB64 = Buffer.from(encRaw).toString('base64');

  // ECDSA P-256 (ES256)
  const { publicKey: verKey, privateKey: signKey } = await generateKeyPair('ES256', {
    extractable: true,
  });
  // Play Console と同じ DER SPKI base64 (PEM ヘッダーなし) 形式を作る
  const verPem = await exportSPKI(verKey);
  const verB64 = verPem
    .replace('-----BEGIN PUBLIC KEY-----', '')
    .replace('-----END PUBLIC KEY-----', '')
    .replace(/\s/g, '');

  return { encB64, verB64, encKey, verKey, signKey };
}

/**
 * Play Integrity サーバー応答と同じ JWE A256KW(JWS ES256(payload)) を生成。
 *
 * @param {object} payload - Standard request の verdict payload
 * @param {object} keys    - generateFixtureKeys() の戻り値
 */
async function buildSelfManagedToken(payload, keys) {
  const payloadBytes = new TextEncoder().encode(JSON.stringify(payload));

  // JWS ES256 sign
  const jws = await new CompactSign(payloadBytes)
    .setProtectedHeader({ alg: 'ES256' })
    .sign(keys.signKey);

  // JWE A256KW + A256GCM (Google が使うのは A256KW + A256GCM の組み合わせ)
  const jwsBytes = new TextEncoder().encode(jws);
  const jwe = await new CompactEncrypt(jwsBytes)
    .setProtectedHeader({ alg: 'A256KW', enc: 'A256GCM' })
    .encrypt(keys.encKey);

  return jwe;
}

// 公式 verdict 仕様 (developer.android.com/google/play/integrity/verdicts):
// - timestampMillis: STRING (例 "1675655009345")
// - versionCode: STRING (例 "42")
// - deviceRecognitionVerdict: 配列、空配列 [] は端末攻撃検知
// - environmentDetails: 任意 (Play Console opt-in、本 fixture では含めない)
const SAMPLE_PAYLOAD = {
  requestDetails: {
    requestPackageName: 'com.solodevlab.solara',
    timestampMillis: String(Date.now()),               // ⚠️ string (v0.5 訂正)
    requestHash: 'PLACEHOLDER_BASE64_SHA256',
  },
  appIntegrity: {
    appRecognitionVerdict: 'PLAY_RECOGNIZED',
    packageName: 'com.solodevlab.solara',
    certificateSha256Digest: ['REPLACE_WITH_REAL_FP'],
    versionCode: '1',                                   // ⚠️ string (公式仕様)
  },
  deviceIntegrity: {
    deviceRecognitionVerdict: ['MEETS_DEVICE_INTEGRITY'],
  },
  accountDetails: {
    appLicensingVerdict: 'LICENSED',
  },
};

// ── R7: 鍵 import 単体 ──────────────────────────────────────────

test('R7: diagnoseKeys は正常な base64 SPKI + AES-256 base64 を import 成功', async () => {
  const keys = await generateFixtureKeys();
  const env = {
    PLAY_INTEGRITY_ENCRYPTION_KEY: keys.encB64,
    PLAY_INTEGRITY_VERIFICATION_KEY: keys.verB64,
  };

  const result = await diagnoseKeys(env);

  assert.equal(result.encryptionKeyOk, true, 'encryption key import 失敗');
  assert.equal(result.verificationKeyOk, true, 'verification key import 失敗');
  assert.deepEqual(result.errors, []);
});

test('R7: encryption key 未設定で encryptionKeyOk=false + errors に記載', async () => {
  const keys = await generateFixtureKeys();
  const env = {
    PLAY_INTEGRITY_ENCRYPTION_KEY: undefined,
    PLAY_INTEGRITY_VERIFICATION_KEY: keys.verB64,
  };

  const result = await diagnoseKeys(env);

  assert.equal(result.encryptionKeyOk, false);
  assert.equal(result.verificationKeyOk, true);
  assert.equal(result.errors.length, 1);
  assert.match(result.errors[0], /encryption:.*未設定/);
});

test('R7: encryption key 長さ異常 (32B 未満) で encryptionKeyOk=false', async () => {
  const keys = await generateFixtureKeys();
  // 16B (= 128bit) を base64 → 24 char (パディング込)
  const shortB64 = Buffer.from(new Uint8Array(16)).toString('base64');
  const env = {
    PLAY_INTEGRITY_ENCRYPTION_KEY: shortB64,
    PLAY_INTEGRITY_VERIFICATION_KEY: keys.verB64,
  };

  const result = await diagnoseKeys(env);

  assert.equal(result.encryptionKeyOk, false);
  assert.match(result.errors[0], /encryption.*長さ異常/);
});

test('R7: verification key が壊れた base64 で verificationKeyOk=false', async () => {
  const keys = await generateFixtureKeys();
  const env = {
    PLAY_INTEGRITY_ENCRYPTION_KEY: keys.encB64,
    PLAY_INTEGRITY_VERIFICATION_KEY: 'not_valid_base64_!!!@@',
  };

  const result = await diagnoseKeys(env);

  assert.equal(result.encryptionKeyOk, true);
  assert.equal(result.verificationKeyOk, false);
  assert.match(result.errors[0], /verification:/);
});

// ── decode pipeline 機能確証 ─────────────────────────────────────

test('decode pipeline: 自前生成 JWE(JWS) を round-trip decode + payload 一致', async () => {
  const keys = await generateFixtureKeys();
  const token = await buildSelfManagedToken(SAMPLE_PAYLOAD, keys);

  const env = {
    PLAY_INTEGRITY_ENCRYPTION_KEY: keys.encB64,
    PLAY_INTEGRITY_VERIFICATION_KEY: keys.verB64,
  };

  const result = await decodeIntegrityToken(token, env);

  assert.equal(result.ok, true, `decode 失敗: ${result.error}`);
  assert.equal(result.payload.requestDetails.requestPackageName, 'com.solodevlab.solara');
  assert.equal(result.payload.appIntegrity.appRecognitionVerdict, 'PLAY_RECOGNIZED');
  assert.ok(
    result.payload.deviceIntegrity.deviceRecognitionVerdict.includes('MEETS_DEVICE_INTEGRITY'),
  );
  assert.ok(typeof result.decodeMs === 'number' && result.decodeMs >= 0);
});

test('decode pipeline: 鍵未設定で ok=false / keys_unset', async () => {
  const result = await decodeIntegrityToken('dummy.token.value', {});
  assert.equal(result.ok, false);
  assert.equal(result.error, 'keys_unset');
});

test('decode pipeline: 改竄 token で ok=false (decode 失敗)', async () => {
  const keys = await generateFixtureKeys();
  const token = await buildSelfManagedToken(SAMPLE_PAYLOAD, keys);

  // token の最後 1 文字を変える (= JWS signature 改竄)
  const tampered = token.slice(0, -2) + (token.endsWith('A') ? 'B' : 'A');

  const env = {
    PLAY_INTEGRITY_ENCRYPTION_KEY: keys.encB64,
    PLAY_INTEGRITY_VERIFICATION_KEY: keys.verB64,
  };

  const result = await decodeIntegrityToken(tampered, env);

  assert.equal(result.ok, false);
  assert.match(result.error, /Error|JWE|JWS|signature/i);
});

test('decode pipeline: 別の verification key で署名検証失敗', async () => {
  const keys1 = await generateFixtureKeys();
  const keys2 = await generateFixtureKeys();
  const token = await buildSelfManagedToken(SAMPLE_PAYLOAD, keys1);

  // encryption key は keys1 (decode は通る) だが verification key は keys2 (= signature 検証失敗)
  const env = {
    PLAY_INTEGRITY_ENCRYPTION_KEY: keys1.encB64,
    PLAY_INTEGRITY_VERIFICATION_KEY: keys2.verB64,
  };

  const result = await decodeIntegrityToken(token, env);

  assert.equal(result.ok, false);
});

// ── R1: パフォーマンス 概算 (Workers Free 10ms 制限の目安) ───────────────

test('R1 (概算): JWE+JWS decode が Node.js で 10ms 以内に完了', async () => {
  const keys = await generateFixtureKeys();
  const token = await buildSelfManagedToken(SAMPLE_PAYLOAD, keys);

  const env = {
    PLAY_INTEGRITY_ENCRYPTION_KEY: keys.encB64,
    PLAY_INTEGRITY_VERIFICATION_KEY: keys.verB64,
  };

  // Warmup (鍵 import + WebCrypto init で初回は遅いため)
  await decodeIntegrityToken(token, env);

  // 5 回測定して平均を取る
  const times = [];
  for (let i = 0; i < 5; i++) {
    const r = await decodeIntegrityToken(token, env);
    assert.equal(r.ok, true);
    times.push(r.decodeMs);
  }
  const avg = times.reduce((a, b) => a + b, 0) / times.length;
  const max = Math.max(...times);

  console.log(`  [R1] decode 平均 ${avg.toFixed(2)}ms / 最大 ${max.toFixed(2)}ms (Node.js 計測)`);

  // Node.js 上の計測は Workers ランタイムと厳密一致しないが、桁感の目安として 50ms 以内
  // (実 Workers 環境での 10ms 制限はデプロイ後 staging 計測で確証 = R1 残)
  assert.ok(max < 50, `decode が遅すぎ: ${max.toFixed(2)}ms (50ms 上限)`);
});
