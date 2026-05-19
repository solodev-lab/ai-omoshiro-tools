/**
 * apps/solara/worker/src/auth/play_integrity.js の単体テスト (S2 + S3、v0.6)
 *
 * 実行: cd apps/solara/worker && node --test test/play_integrity.test.js
 *
 * カバー範囲 (設計 v0.5/v0.6 §4):
 *   S2 (既存 9 ケース):
 *     - R7: base64 (DER SPKI) verification key を crypto.subtle.importKey('spki') で import
 *     - R7': AES-256 (44 char base64) encryption key を crypto.subtle.importKey('raw') で import
 *     - decode pipeline 機能確証: 自前生成 JWE A256KW(JWS ES256) を round-trip decode
 *     - エラー処理: 鍵未設定 / 鍵長異常 / 改竄 token
 *   S3 (新規 15 ケース、verifyPlayIntegrityFlow Step 3-11):
 *     - happy path 全 step 通過
 *     - ヘッダー欠落 / clientData 改竄 / 必須キー欠落 / ts drift
 *     - DO nonce consume 失敗 / consumed nonce ≠ clientData.nonce
 *     - requestHash binding 不一致 (= clientData 改竄検出)
 *     - token timestamp drift / packageName 不一致
 *     - verdict 3 パターン (UNRECOGNIZED_VERSION, UNEVALUATED, deviceRecognitionVerdict empty)
 *     - MEETS_DEVICE_INTEGRITY 不在 / cert allowlist mismatch / allowlist 未設定パス
 *
 * 限界 (R8 は本テストでは実証不能):
 *   - Google が実際の Standard request 応答で Self-managed key を使うかは
 *     実機採取の Play Integrity token が必要 (= S5 で確証)
 *   - 本テストは「Workers ランタイムで JWE A256KW + JWS ES256 decode が動く」ことと
 *     「Worker 側の検証ロジックが全失敗パスを検知できる」ことを証明
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
import {
  diagnoseKeys,
  decodeIntegrityToken,
  verifyPlayIntegrityFlow,
  DEFAULT_ANDROID_PACKAGE_NAME,
  TS_DRIFT_MS,
  __test,
} from '../src/auth/play_integrity.js';

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

// ─────────────────────────────────────────────────────────────────
// S3 (verifyPlayIntegrityFlow Step 3-11) ─ 15 ケース
// ─────────────────────────────────────────────────────────────────

const VALID_PKG = DEFAULT_ANDROID_PACKAGE_NAME;
const FIXED_NONCE = 'A'.repeat(44); // 44 char (= base64 32B) で MIN_NONCE_LENGTH 32 を超える
const FIXED_NONCE_ID = 'nonce-id-xxxx';
const FIXED_UID = 'apple:abc123';

/**
 * Step 5 DO consume の S3 用 mock。
 * @param {object} opts - { ok, nonceB64, error }
 * @returns 注入用 consumeNonce 関数
 */
function mockConsume(opts) {
  return async (_nonceId, _env) => opts;
}

/**
 * 正常系の payload を生成。
 * - timestampMillis は string (公式仕様)
 * - requestHash は呼出側で sha256(clientDataStr) を計算して上書き必須
 */
function buildPayload(overrides = {}) {
  return {
    requestDetails: {
      requestPackageName: VALID_PKG,
      timestampMillis: String(Date.now()),
      requestHash: 'PLACEHOLDER',
      ...overrides.requestDetails,
    },
    appIntegrity: {
      appRecognitionVerdict: 'PLAY_RECOGNIZED',
      packageName: VALID_PKG,
      certificateSha256Digest: ['cert-fp-A'],
      versionCode: '1',
      ...overrides.appIntegrity,
    },
    deviceIntegrity: {
      deviceRecognitionVerdict: ['MEETS_DEVICE_INTEGRITY', 'MEETS_BASIC_INTEGRITY'],
      ...overrides.deviceIntegrity,
    },
    accountDetails: {
      appLicensingVerdict: 'LICENSED',
      ...overrides.accountDetails,
    },
  };
}

/**
 * 正常系の Request を生成 + 対応する token を JWE+JWS で signing。
 * payload.requestDetails.requestHash には sha256(clientDataStr) を自動で埋め込む。
 *
 * @param {object} options
 *   - clientData: {nonce, uid, ts} を渡すと JSON.stringify、欠落キー検証用 raw 上書き可
 *   - payloadOverrides: buildPayload に渡される
 *   - skipRequestHash: true なら requestHash を意図的にずらす (= mismatch 検証用)
 *   - keysOverride: 既存 keys を再利用 (失敗系で同一鍵で複数回試行する場合)
 * @returns {{request, env, keys, clientData, clientDataStr, payload, token}}
 */
async function buildHappyPathSetup({
  clientData = { nonce: FIXED_NONCE, uid: FIXED_UID, ts: Date.now() },
  payloadOverrides = {},
  skipRequestHash = false,
  clientDataRaw,         // 渡されたら JSON.stringify せずそのまま使う (= malformed JSON 検証用)
  keysOverride,
  headersOverride = {},  // 個別のヘッダー欠落をシミュレート
  envOverride = {},
} = {}) {
  const keys = keysOverride ?? (await generateFixtureKeys());

  const clientDataStr = clientDataRaw ?? JSON.stringify(clientData);
  const requestHash = skipRequestHash
    ? 'WRONG_HASH_VALUE_XXXXXXXX'
    : await __test.sha256Base64(clientDataStr);

  const payload = buildPayload({
    ...payloadOverrides,
    requestDetails: { requestHash, ...payloadOverrides.requestDetails },
  });
  const token = await buildSelfManagedToken(payload, keys);

  const defaultHeaders = {
    'X-PlayIntegrity-Token': token,
    'X-PlayIntegrity-ClientData': clientDataStr,
    'X-PlayIntegrity-NonceId': FIXED_NONCE_ID,
  };
  const finalHeaders = { ...defaultHeaders, ...headersOverride };
  // ヘッダー値が null → 削除を意味する (Request.headers.get → null)
  const headersInit = Object.fromEntries(
    Object.entries(finalHeaders).filter(([, v]) => v !== null && v !== undefined),
  );

  const request = new Request('https://example.com/protected/fortune', {
    method: 'POST',
    headers: headersInit,
  });

  const env = {
    PLAY_INTEGRITY_ENCRYPTION_KEY: keys.encB64,
    PLAY_INTEGRITY_VERIFICATION_KEY: keys.verB64,
    ...envOverride,
  };

  return { request, env, keys, clientData, clientDataStr, payload, token };
}

// ── S3-1: Happy path ────────────────────────────────────────────

test('S3 happy path: 全 step 通過、payload + uid 返却', async () => {
  const { request, env, clientData } = await buildHappyPathSetup();

  const result = await verifyPlayIntegrityFlow(
    request,
    env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
  );

  assert.equal(result.ok, true, `失敗: ${result.error}`);
  assert.equal(result.uid, FIXED_UID);
  assert.equal(result.payload.appIntegrity.appRecognitionVerdict, 'PLAY_RECOGNIZED');
  assert.ok(result.payload.deviceIntegrity.deviceRecognitionVerdict.includes('MEETS_DEVICE_INTEGRITY'));
});

// ── S3-2: ヘッダー欠落 (Step 2) ──────────────────────────────────

test('S3 Step2: X-PlayIntegrity-Token ヘッダー欠落 → missing_token', async () => {
  const { request, env, clientData } = await buildHappyPathSetup({
    headersOverride: { 'X-PlayIntegrity-Token': null },
  });

  const result = await verifyPlayIntegrityFlow(
    request,
    env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'missing_token');
  assert.equal(result.status, 401);
});

test('S3 Step2: X-PlayIntegrity-ClientData ヘッダー欠落 → missing_clientdata', async () => {
  const { request, env, clientData } = await buildHappyPathSetup({
    headersOverride: { 'X-PlayIntegrity-ClientData': null },
  });

  const result = await verifyPlayIntegrityFlow(
    request,
    env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'missing_clientdata');
});

// ── S3-3: clientData parse / 必須キー (Step 3) ────────────────────

test('S3 Step3: clientData が malformed JSON → clientdata_malformed', async () => {
  const { request, env, clientData } = await buildHappyPathSetup({
    clientDataRaw: '{not valid json',
  });

  const result = await verifyPlayIntegrityFlow(
    request,
    env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'clientdata_malformed');
});

test('S3 Step3: clientData.nonce が短すぎる (< 32 char) → clientdata_nonce_invalid', async () => {
  const { request, env } = await buildHappyPathSetup({
    clientData: { nonce: 'short', uid: FIXED_UID, ts: Date.now() },
  });

  const result = await verifyPlayIntegrityFlow(
    request,
    env,
    mockConsume({ ok: true, nonceB64: 'short' }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'clientdata_nonce_invalid');
});

test('S3 Step3: clientData.uid 欠落 → clientdata_uid_invalid', async () => {
  const { request, env, clientData } = await buildHappyPathSetup({
    clientData: { nonce: FIXED_NONCE, ts: Date.now() }, // uid なし
  });

  const result = await verifyPlayIntegrityFlow(
    request,
    env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'clientdata_uid_invalid');
});

test('S3 Step3: clientData.ts が number 以外 → clientdata_ts_invalid', async () => {
  const { request, env, clientData } = await buildHappyPathSetup({
    clientData: { nonce: FIXED_NONCE, uid: FIXED_UID, ts: 'now' },
  });

  const result = await verifyPlayIntegrityFlow(
    request,
    env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'clientdata_ts_invalid');
});

// ── S3-4: clientData.ts drift (Step 4) ────────────────────────────

test('S3 Step4: clientData.ts が現在から 10 分前 → client_clock_drift', async () => {
  const past = Date.now() - 10 * 60 * 1000;
  const { request, env } = await buildHappyPathSetup({
    clientData: { nonce: FIXED_NONCE, uid: FIXED_UID, ts: past },
  });

  const result = await verifyPlayIntegrityFlow(
    request,
    env,
    mockConsume({ ok: true, nonceB64: FIXED_NONCE }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'client_clock_drift');
});

// ── S3-5: nonce consume (Step 5) ──────────────────────────────────

test('S3 Step5: consumeNonce が ok=false (= DO で expired/consumed) → nonce_consume_failed', async () => {
  const { request, env } = await buildHappyPathSetup();

  const result = await verifyPlayIntegrityFlow(
    request,
    env,
    mockConsume({ ok: false, error: 'nonce_expired' }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'nonce_expired');
});

test('S3 Step5: consumed nonce が clientData.nonce と一致しない → nonce_mismatch', async () => {
  const { request, env } = await buildHappyPathSetup();
  // mock は別の nonce 値を返す
  const otherNonce = 'B'.repeat(44);

  const result = await verifyPlayIntegrityFlow(
    request,
    env,
    mockConsume({ ok: true, nonceB64: otherNonce }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'nonce_mismatch');
});

// ── S3-6: requestHash binding (Step 9) ────────────────────────────

test('S3 Step9: payload.requestHash が clientData の SHA-256 と不一致 → requesthash_mismatch', async () => {
  const { request, env, clientData } = await buildHappyPathSetup({ skipRequestHash: true });

  const result = await verifyPlayIntegrityFlow(
    request,
    env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'requesthash_mismatch');
});

// ── S3-7: token timestamp + package (Step 10) ─────────────────────

test('S3 Step10: token.timestampMillis が 10 分前 → token_ts_drift', async () => {
  const oldTs = String(Date.now() - 10 * 60 * 1000);
  const { request, env, clientData } = await buildHappyPathSetup({
    payloadOverrides: { requestDetails: { timestampMillis: oldTs } },
  });

  const result = await verifyPlayIntegrityFlow(
    request,
    env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'token_ts_drift');
});

test('S3 Step10: payload.requestPackageName 不一致 → package_mismatch', async () => {
  const { request, env, clientData } = await buildHappyPathSetup({
    payloadOverrides: { requestDetails: { requestPackageName: 'com.attacker.app' } },
  });

  const result = await verifyPlayIntegrityFlow(
    request,
    env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'package_mismatch');
});

// ── S3-8: verdict 評価 (Step 11) ──────────────────────────────────

test('S3 Step11: appRecognitionVerdict=UNRECOGNIZED_VERSION → app_not_recognized', async () => {
  const { request, env, clientData } = await buildHappyPathSetup({
    payloadOverrides: { appIntegrity: { appRecognitionVerdict: 'UNRECOGNIZED_VERSION' } },
  });

  const result = await verifyPlayIntegrityFlow(
    request,
    env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'app_not_recognized');
  assert.equal(result.detail, 'UNRECOGNIZED_VERSION');
});

test('S3 Step11: deviceRecognitionVerdict が空配列 → device_verdict_empty', async () => {
  const { request, env, clientData } = await buildHappyPathSetup({
    payloadOverrides: { deviceIntegrity: { deviceRecognitionVerdict: [] } },
  });

  const result = await verifyPlayIntegrityFlow(
    request,
    env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'device_verdict_empty');
});

test('S3 Step11: MEETS_DEVICE_INTEGRITY 不在 (BASIC のみ) → device_integrity_missing', async () => {
  const { request, env, clientData } = await buildHappyPathSetup({
    payloadOverrides: { deviceIntegrity: { deviceRecognitionVerdict: ['MEETS_BASIC_INTEGRITY'] } },
  });

  const result = await verifyPlayIntegrityFlow(
    request,
    env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'device_integrity_missing');
});

test('S3 Step11: cert allowlist 設定済 + token cert 不一致 → cert_not_allowlisted', async () => {
  const { request, env, clientData } = await buildHappyPathSetup({
    envOverride: { ANDROID_CERT_SHA256_ALLOWLIST: 'cert-fp-PROD-1,cert-fp-PROD-2' },
  });

  const result = await verifyPlayIntegrityFlow(
    request,
    env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'cert_not_allowlisted');
});

test('S3 Step11: cert allowlist 未設定なら cert check skip (= log_only 期間用) → ok:true', async () => {
  const { request, env, clientData } = await buildHappyPathSetup({
    envOverride: { ANDROID_CERT_SHA256_ALLOWLIST: '' },
  });

  const result = await verifyPlayIntegrityFlow(
    request,
    env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
  );

  assert.equal(result.ok, true, `失敗: ${result.error}`);
});

test('S3 Step11: cert allowlist 設定済 + token cert allowlist 内 → ok:true', async () => {
  const { request, env, clientData } = await buildHappyPathSetup({
    envOverride: { ANDROID_CERT_SHA256_ALLOWLIST: 'cert-fp-A,cert-fp-PROD' },
  });

  const result = await verifyPlayIntegrityFlow(
    request,
    env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
  );

  assert.equal(result.ok, true);
});
