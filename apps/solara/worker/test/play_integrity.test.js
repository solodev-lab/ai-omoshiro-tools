/**
 * apps/solara/worker/src/auth/play_integrity.js の単体テスト (v1.1、Google decode API 方式)
 *
 * 実行: cd apps/solara/worker && node --test test/play_integrity.test.js
 *
 * 🚨 v1.1 アーキテクチャ訂正 (2026-05-20、R8 実機失敗):
 *   Standard request の token は JWE ではなく Google 独自 protobuf 形式で、
 *   Self-managed key で local decode 不可 (公式 docs 確認、JWEInvalid)。
 *   → Q2 訂正: Self-managed key (jose 自前 decode) → Google decodeIntegrityToken API。
 *   jose は Service Account JWT (RS256) 署名に再利用。
 *
 * カバー範囲:
 *   getGoogleAccessToken (Service Account JWT → OAuth2 access token、cache):
 *     - SA JSON 未設定 → throw
 *     - 正常: RS256 JWT 署名 + token 取得 + 50min cache
 *     - cache hit: 2 回目は fetch 呼ばない
 *   decodeIntegrityToken (Google decode API、mock fetch):
 *     - SA JSON 未設定 → sa_json_unset
 *     - 正常: tokenPayloadExternal を payload として返却
 *     - API error → decode_api
 *     - tokenPayloadExternal なし → no_token_payload
 *   verifyPlayIntegrityFlow (Step 2-12、decodeFn を mock 注入):
 *     - happy path 全 step 通過
 *     - ヘッダー欠落 / clientData 改竄 / 必須キー欠落 / ts drift
 *     - DO nonce consume 失敗 / consumed nonce ≠ clientData.nonce
 *     - requestHash binding 不一致 / token ts drift / packageName 不一致
 *     - verdict 3 パターン (UNRECOGNIZED_VERSION / 空配列 / MEETS_DEVICE_INTEGRITY 不在)
 *     - cert allowlist mismatch / match / 未設定 skip
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { generateKeyPair, exportPKCS8 } from 'jose';
import {
  getGoogleAccessToken,
  decodeIntegrityToken,
  verifyPlayIntegrityFlow,
  _resetAccessTokenCacheForTest,
  DEFAULT_ANDROID_PACKAGE_NAME,
  __test,
} from '../src/auth/play_integrity.js';

// ── fetch mock ヘルパー ────────────────────────────────────────────

/**
 * globalThis.fetch を一時的に差し替えて fn を実行、終了後に復元。
 * @param {(url: string, opts: object) => Promise<Response>} handler
 * @param {() => Promise<any>} fn
 */
async function withMockFetch(handler, fn) {
  const orig = globalThis.fetch;
  globalThis.fetch = handler;
  try {
    return await fn();
  } finally {
    globalThis.fetch = orig;
  }
}

function jsonResponse(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

/** RS256 private key を持つ fake Service Account JSON を生成。 */
async function makeFakeSaJson() {
  const { privateKey } = await generateKeyPair('RS256', { extractable: true });
  const pem = await exportPKCS8(privateKey);
  return JSON.stringify({
    client_email: 'test-sa@solara-api.iam.gserviceaccount.com',
    private_key: pem,
  });
}

// ── getGoogleAccessToken ───────────────────────────────────────────

test('getGoogleAccessToken: SA JSON 未設定で throw', async () => {
  _resetAccessTokenCacheForTest();
  await assert.rejects(
    () => getGoogleAccessToken({}),
    /GOOGLE_PLAY_INTEGRITY_SA_JSON secret 未設定/,
  );
});

test('getGoogleAccessToken: 正常系で OAuth2 token 取得 + RS256 JWT を assertion に使う', async () => {
  _resetAccessTokenCacheForTest();
  const saJson = await makeFakeSaJson();
  let capturedBody = null;

  const result = await withMockFetch(
    async (url, opts) => {
      assert.equal(url, 'https://oauth2.googleapis.com/token');
      capturedBody = opts.body.toString();
      return jsonResponse({ access_token: 'fake-access-token-123', expires_in: 3600 });
    },
    () => getGoogleAccessToken({ GOOGLE_PLAY_INTEGRITY_SA_JSON: saJson }),
  );

  assert.equal(result, 'fake-access-token-123');
  // assertion (JWT) が body に含まれる
  assert.match(capturedBody, /grant_type=urn/);
  assert.match(capturedBody, /assertion=eyJ/); // JWT は eyJ で始まる
});

test('getGoogleAccessToken: cache hit で 2 回目は fetch を呼ばない', async () => {
  _resetAccessTokenCacheForTest();
  const saJson = await makeFakeSaJson();
  let fetchCalls = 0;

  const env = { GOOGLE_PLAY_INTEGRITY_SA_JSON: saJson };
  await withMockFetch(
    async () => {
      fetchCalls++;
      return jsonResponse({ access_token: 'cached-token', expires_in: 3600 });
    },
    async () => {
      const t1 = await getGoogleAccessToken(env);
      const t2 = await getGoogleAccessToken(env);
      assert.equal(t1, 'cached-token');
      assert.equal(t2, 'cached-token');
    },
  );

  assert.equal(fetchCalls, 1, 'cache が効かず fetch が 2 回呼ばれた');
});

test('getGoogleAccessToken: OAuth2 が error 応答で throw', async () => {
  _resetAccessTokenCacheForTest();
  const saJson = await makeFakeSaJson();

  await assert.rejects(
    () =>
      withMockFetch(
        async () => jsonResponse({ error: 'invalid_grant', error_description: 'bad jwt' }, 400),
        () => getGoogleAccessToken({ GOOGLE_PLAY_INTEGRITY_SA_JSON: saJson }),
      ),
    /OAuth token 取得失敗/,
  );
});

// ── decodeIntegrityToken (Google decode API) ───────────────────────

const SAMPLE_VERDICT = {
  requestDetails: {
    requestPackageName: 'com.solodevlab.solara',
    timestampMillis: String(Date.now()),
    requestHash: 'sample-hash',
  },
  appIntegrity: {
    appRecognitionVerdict: 'PLAY_RECOGNIZED',
    packageName: 'com.solodevlab.solara',
    certificateSha256Digest: ['cert-fp-A'],
    versionCode: '1',
  },
  deviceIntegrity: {
    deviceRecognitionVerdict: ['MEETS_DEVICE_INTEGRITY'],
  },
  accountDetails: { appLicensingVerdict: 'LICENSED' },
};

test('decodeIntegrityToken: SA JSON 未設定で sa_json_unset', async () => {
  _resetAccessTokenCacheForTest();
  const result = await decodeIntegrityToken('any-token', {});
  assert.equal(result.ok, false);
  assert.equal(result.error, 'sa_json_unset');
});

test('decodeIntegrityToken: 正常系で tokenPayloadExternal を payload 返却', async () => {
  _resetAccessTokenCacheForTest();
  const saJson = await makeFakeSaJson();

  const result = await withMockFetch(
    async (url) => {
      if (url.includes('oauth2.googleapis.com')) {
        return jsonResponse({ access_token: 'tok', expires_in: 3600 });
      }
      if (url.includes('playintegrity.googleapis.com')) {
        assert.match(url, /com\.solodevlab\.solara:decodeIntegrityToken/);
        return jsonResponse({ tokenPayloadExternal: SAMPLE_VERDICT });
      }
      throw new Error(`unexpected url ${url}`);
    },
    () =>
      decodeIntegrityToken('CqUC-fake-standard-token', {
        GOOGLE_PLAY_INTEGRITY_SA_JSON: saJson,
        ANDROID_PACKAGE_NAME: 'com.solodevlab.solara',
      }),
  );

  assert.equal(result.ok, true, `失敗: ${result.error}`);
  assert.equal(result.payload.appIntegrity.appRecognitionVerdict, 'PLAY_RECOGNIZED');
  assert.ok(typeof result.decodeMs === 'number' && result.decodeMs >= 0);
});

test('decodeIntegrityToken: decode API が error 応答 → decode_api', async () => {
  _resetAccessTokenCacheForTest();
  const saJson = await makeFakeSaJson();

  const result = await withMockFetch(
    async (url) => {
      if (url.includes('oauth2.googleapis.com')) {
        return jsonResponse({ access_token: 'tok', expires_in: 3600 });
      }
      return jsonResponse({ error: { code: 400, message: 'Token malformed' } }, 400);
    },
    () =>
      decodeIntegrityToken('bad-token', {
        GOOGLE_PLAY_INTEGRITY_SA_JSON: saJson,
      }),
  );

  assert.equal(result.ok, false);
  assert.match(result.error, /decode_api: Token malformed/);
});

test('decodeIntegrityToken: tokenPayloadExternal 欠落 → no_token_payload', async () => {
  _resetAccessTokenCacheForTest();
  const saJson = await makeFakeSaJson();

  const result = await withMockFetch(
    async (url) => {
      if (url.includes('oauth2.googleapis.com')) {
        return jsonResponse({ access_token: 'tok', expires_in: 3600 });
      }
      return jsonResponse({ somethingElse: true }); // tokenPayloadExternal なし
    },
    () =>
      decodeIntegrityToken('token', {
        GOOGLE_PLAY_INTEGRITY_SA_JSON: saJson,
      }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'no_token_payload');
});

// ─────────────────────────────────────────────────────────────────
// verifyPlayIntegrityFlow (Step 2-12、decodeFn を mock 注入)
// ─────────────────────────────────────────────────────────────────

const VALID_PKG = DEFAULT_ANDROID_PACKAGE_NAME;
const FIXED_NONCE = 'A'.repeat(44); // 44 char (= base64 32B) で MIN_NONCE_LENGTH 32 を超える
const FIXED_NONCE_ID = 'nonce-id-xxxx';
const FIXED_UID = 'apple:abc123';

/** Step 5 DO consume の mock。 */
function mockConsume(opts) {
  return async (_nonceId, _env) => opts;
}

/** Step 6-7 decode の mock (Google decode API の代わり)。 */
function mockDecode(result) {
  return async (_token, _env) => result;
}

/** 正常系の verdict payload を生成 (requestHash は呼出側で上書き)。 */
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
 * 正常系の Request + payload を生成。
 * payload.requestDetails.requestHash には sha256(clientDataStr) を自動で埋め込む
 * (= Step 9 binding が成立する状態)。decode は mockDecode(payload) で注入する想定。
 *
 * 戻り値: {request, env, clientData, clientDataStr, payload}
 */
async function buildHappyPathSetup({
  clientData = { nonce: FIXED_NONCE, uid: FIXED_UID, ts: Date.now() },
  payloadOverrides = {},
  skipRequestHash = false,
  clientDataRaw,
  headersOverride = {},
  envOverride = {},
} = {}) {
  const clientDataStr = clientDataRaw ?? JSON.stringify(clientData);
  const requestHash = skipRequestHash
    ? 'WRONG_HASH_VALUE_XXXXXXXX'
    : await __test.sha256Base64(clientDataStr);

  const payload = buildPayload({
    ...payloadOverrides,
    requestDetails: { requestHash, ...payloadOverrides.requestDetails },
  });

  const defaultHeaders = {
    'X-PlayIntegrity-Token': 'CqUC-dummy-standard-token',
    'X-PlayIntegrity-ClientData': clientDataStr,
    'X-PlayIntegrity-NonceId': FIXED_NONCE_ID,
  };
  const finalHeaders = { ...defaultHeaders, ...headersOverride };
  const headersInit = Object.fromEntries(
    Object.entries(finalHeaders).filter(([, v]) => v !== null && v !== undefined),
  );

  const request = new Request('https://example.com/protected/fortune', {
    method: 'POST',
    headers: headersInit,
  });

  const env = {
    GOOGLE_PLAY_INTEGRITY_SA_JSON: '{"client_email":"x","private_key":"y"}', // 形だけ (decodeFn は mock)
    ...envOverride,
  };

  return { request, env, clientData, clientDataStr, payload };
}

// ── Happy path ──────────────────────────────────────────────────

test('happy path: 全 step 通過、payload + uid 返却', async () => {
  const { request, env, clientData, payload } = await buildHappyPathSetup();

  const result = await verifyPlayIntegrityFlow(
    request,
    env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
    mockDecode({ ok: true, payload }),
  );

  assert.equal(result.ok, true, `失敗: ${result.error}`);
  assert.equal(result.uid, FIXED_UID);
  assert.equal(result.payload.appIntegrity.appRecognitionVerdict, 'PLAY_RECOGNIZED');
  assert.ok(result.payload.deviceIntegrity.deviceRecognitionVerdict.includes('MEETS_DEVICE_INTEGRITY'));
});

// ── ヘッダー欠落 (Step 2) ─────────────────────────────────────────

test('Step2: X-PlayIntegrity-Token ヘッダー欠落 → missing_token', async () => {
  const { request, env, clientData, payload } = await buildHappyPathSetup({
    headersOverride: { 'X-PlayIntegrity-Token': null },
  });

  const result = await verifyPlayIntegrityFlow(
    request, env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
    mockDecode({ ok: true, payload }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'missing_token');
  assert.equal(result.status, 401);
});

test('Step2: X-PlayIntegrity-ClientData ヘッダー欠落 → missing_clientdata', async () => {
  const { request, env, clientData, payload } = await buildHappyPathSetup({
    headersOverride: { 'X-PlayIntegrity-ClientData': null },
  });

  const result = await verifyPlayIntegrityFlow(
    request, env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
    mockDecode({ ok: true, payload }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'missing_clientdata');
});

test('Step2: X-PlayIntegrity-NonceId ヘッダー欠落 → missing_nonceid', async () => {
  const { request, env, clientData, payload } = await buildHappyPathSetup({
    headersOverride: { 'X-PlayIntegrity-NonceId': null },
  });

  const result = await verifyPlayIntegrityFlow(
    request, env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
    mockDecode({ ok: true, payload }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'missing_nonceid');
});

// ── clientData parse / 必須キー (Step 3) ──────────────────────────

test('Step3: clientData が malformed JSON → clientdata_malformed', async () => {
  const { request, env, payload } = await buildHappyPathSetup({
    clientDataRaw: '{not valid json',
  });

  const result = await verifyPlayIntegrityFlow(
    request, env,
    mockConsume({ ok: true, nonceB64: FIXED_NONCE }),
    mockDecode({ ok: true, payload }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'clientdata_malformed');
});

test('Step3: clientData.nonce が短すぎる (< 32 char) → clientdata_nonce_invalid', async () => {
  const { request, env, payload } = await buildHappyPathSetup({
    clientData: { nonce: 'short', uid: FIXED_UID, ts: Date.now() },
  });

  const result = await verifyPlayIntegrityFlow(
    request, env,
    mockConsume({ ok: true, nonceB64: 'short' }),
    mockDecode({ ok: true, payload }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'clientdata_nonce_invalid');
});

test('Step3: clientData.uid 欠落 → clientdata_uid_invalid', async () => {
  const { request, env, payload } = await buildHappyPathSetup({
    clientData: { nonce: FIXED_NONCE, ts: Date.now() },
  });

  const result = await verifyPlayIntegrityFlow(
    request, env,
    mockConsume({ ok: true, nonceB64: FIXED_NONCE }),
    mockDecode({ ok: true, payload }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'clientdata_uid_invalid');
});

test('Step3: clientData.ts が number 以外 → clientdata_ts_invalid', async () => {
  const { request, env, payload } = await buildHappyPathSetup({
    clientData: { nonce: FIXED_NONCE, uid: FIXED_UID, ts: 'now' },
  });

  const result = await verifyPlayIntegrityFlow(
    request, env,
    mockConsume({ ok: true, nonceB64: FIXED_NONCE }),
    mockDecode({ ok: true, payload }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'clientdata_ts_invalid');
});

// ── clientData.ts drift (Step 4) ─────────────────────────────────

test('Step4: clientData.ts が現在から 10 分前 → client_clock_drift', async () => {
  const past = Date.now() - 10 * 60 * 1000;
  const { request, env, payload } = await buildHappyPathSetup({
    clientData: { nonce: FIXED_NONCE, uid: FIXED_UID, ts: past },
  });

  const result = await verifyPlayIntegrityFlow(
    request, env,
    mockConsume({ ok: true, nonceB64: FIXED_NONCE }),
    mockDecode({ ok: true, payload }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'client_clock_drift');
});

// ── nonce consume (Step 5) ────────────────────────────────────────

test('Step5: consumeNonce が ok=false (= DO で expired/consumed) → propagated error', async () => {
  const { request, env, payload } = await buildHappyPathSetup();

  const result = await verifyPlayIntegrityFlow(
    request, env,
    mockConsume({ ok: false, error: 'nonce_expired' }),
    mockDecode({ ok: true, payload }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'nonce_expired');
});

test('Step5: consumed nonce が clientData.nonce と一致しない → nonce_mismatch', async () => {
  const { request, env, payload } = await buildHappyPathSetup();
  const otherNonce = 'B'.repeat(44);

  const result = await verifyPlayIntegrityFlow(
    request, env,
    mockConsume({ ok: true, nonceB64: otherNonce }),
    mockDecode({ ok: true, payload }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'nonce_mismatch');
});

// ── decode 失敗 (Step 6-7) ────────────────────────────────────────

test('Step6-7: decode が ok=false → decode_failed (detail 付き)', async () => {
  const { request, env, clientData } = await buildHappyPathSetup();

  const result = await verifyPlayIntegrityFlow(
    request, env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
    mockDecode({ ok: false, error: 'decode_api: Token malformed' }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'decode_failed');
  assert.equal(result.detail, 'decode_api: Token malformed');
});

// ── requestHash binding (Step 9) ─────────────────────────────────

test('Step9: payload.requestHash が clientData の SHA-256 と不一致 → requesthash_mismatch', async () => {
  const { request, env, clientData, payload } = await buildHappyPathSetup({ skipRequestHash: true });

  const result = await verifyPlayIntegrityFlow(
    request, env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
    mockDecode({ ok: true, payload }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'requesthash_mismatch');
});

// ── token timestamp + package (Step 10) ──────────────────────────

test('Step10: token.timestampMillis が 10 分前 → token_ts_drift', async () => {
  const oldTs = String(Date.now() - 10 * 60 * 1000);
  const { request, env, clientData, payload } = await buildHappyPathSetup({
    payloadOverrides: { requestDetails: { timestampMillis: oldTs } },
  });

  const result = await verifyPlayIntegrityFlow(
    request, env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
    mockDecode({ ok: true, payload }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'token_ts_drift');
});

test('Step10: payload.requestPackageName 不一致 → package_mismatch', async () => {
  const { request, env, clientData, payload } = await buildHappyPathSetup({
    payloadOverrides: { requestDetails: { requestPackageName: 'com.attacker.app' } },
  });

  const result = await verifyPlayIntegrityFlow(
    request, env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
    mockDecode({ ok: true, payload }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'package_mismatch');
});

// ── verdict 評価 (Step 11) ────────────────────────────────────────

test('Step11: appRecognitionVerdict=UNRECOGNIZED_VERSION → app_not_recognized', async () => {
  const { request, env, clientData, payload } = await buildHappyPathSetup({
    payloadOverrides: { appIntegrity: { appRecognitionVerdict: 'UNRECOGNIZED_VERSION' } },
  });

  const result = await verifyPlayIntegrityFlow(
    request, env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
    mockDecode({ ok: true, payload }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'app_not_recognized');
  assert.equal(result.detail, 'UNRECOGNIZED_VERSION');
});

test('Step11: deviceRecognitionVerdict が空配列 → device_verdict_empty', async () => {
  const { request, env, clientData, payload } = await buildHappyPathSetup({
    payloadOverrides: { deviceIntegrity: { deviceRecognitionVerdict: [] } },
  });

  const result = await verifyPlayIntegrityFlow(
    request, env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
    mockDecode({ ok: true, payload }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'device_verdict_empty');
});

test('Step11: MEETS_DEVICE_INTEGRITY 不在 (BASIC のみ) → device_integrity_missing', async () => {
  const { request, env, clientData, payload } = await buildHappyPathSetup({
    payloadOverrides: { deviceIntegrity: { deviceRecognitionVerdict: ['MEETS_BASIC_INTEGRITY'] } },
  });

  const result = await verifyPlayIntegrityFlow(
    request, env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
    mockDecode({ ok: true, payload }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'device_integrity_missing');
});

test('Step11: cert allowlist 設定済 + token cert 不一致 → cert_not_allowlisted', async () => {
  const { request, env, clientData, payload } = await buildHappyPathSetup({
    envOverride: { ANDROID_CERT_SHA256_ALLOWLIST: 'cert-fp-PROD-1,cert-fp-PROD-2' },
  });

  const result = await verifyPlayIntegrityFlow(
    request, env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
    mockDecode({ ok: true, payload }),
  );

  assert.equal(result.ok, false);
  assert.equal(result.error, 'cert_not_allowlisted');
});

test('Step11: cert allowlist 未設定なら cert check skip → ok:true', async () => {
  const { request, env, clientData, payload } = await buildHappyPathSetup({
    envOverride: { ANDROID_CERT_SHA256_ALLOWLIST: '' },
  });

  const result = await verifyPlayIntegrityFlow(
    request, env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
    mockDecode({ ok: true, payload }),
  );

  assert.equal(result.ok, true, `失敗: ${result.error}`);
});

test('Step11: cert allowlist 設定済 + token cert allowlist 内 → ok:true', async () => {
  const { request, env, clientData, payload } = await buildHappyPathSetup({
    envOverride: { ANDROID_CERT_SHA256_ALLOWLIST: 'cert-fp-A,cert-fp-PROD' },
  });

  const result = await verifyPlayIntegrityFlow(
    request, env,
    mockConsume({ ok: true, nonceB64: clientData.nonce }),
    mockDecode({ ok: true, payload }),
  );

  assert.equal(result.ok, true);
});
