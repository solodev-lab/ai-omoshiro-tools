/**
 * Apple Token Revocation (auth/revoke) のテスト。
 *
 * 対象:
 *   - buildAppleClientSecret  : ES256 JWT 生成 (header.payload.signature)
 *   - revokeAppleToken        : Apple /auth/revoke 呼出 + 結果分類
 *
 * fetch は _setFetchForTest で差し替え。実 Apple API は呼ばない。
 *
 * 実行: cd apps/solara/worker && node --test test/apple_revoke.test.js
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  buildAppleClientSecret,
  revokeAppleToken,
  _setFetchForTest,
} from '../src/auth/apple_revoke.js';

// ── テスト用 P8 秘密鍵 (P-256、PKCS#8、公開可能なダミー) ─────────
// このペアは本テスト専用に生成したもので、本番では使われない。
// 生成: openssl ecparam -name prime256v1 -genkey -noout -out test.pem
//       openssl pkcs8 -topk8 -nocrypt -in test.pem -out test_p8.pem
const TEST_P8_PEM = `-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2
OF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r
1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G
-----END PRIVATE KEY-----`;

const VALID_ENV = {
  APPLE_TEAM_ID: 'TY5JW393Q5',
  APPLE_SIWA_SERVICE_ID: 'com.solodevlab.solara.signin',
  APPLE_SIWA_KEY_ID: 'ABC123DEF4',
  APPLE_SIWA_PRIVATE_KEY: TEST_P8_PEM,
};

// ── buildAppleClientSecret ───────────────────────────────────

test('buildAppleClientSecret: 必須 secret 揃っていれば三段 base64url JWT を返す', async () => {
  const jwt = await buildAppleClientSecret(VALID_ENV, 1700000000);
  const parts = jwt.split('.');
  assert.equal(parts.length, 3, 'JWT は 3 つの base64url セグメント');
  // base64url 以外の文字が含まれていないこと
  assert.match(parts[0], /^[A-Za-z0-9_-]+$/);
  assert.match(parts[1], /^[A-Za-z0-9_-]+$/);
  assert.match(parts[2], /^[A-Za-z0-9_-]+$/);

  // header と payload を decode して内容確認
  const decode = (s) => JSON.parse(atob(s.replace(/-/g, '+').replace(/_/g, '/')));
  const header = decode(parts[0]);
  assert.equal(header.alg, 'ES256');
  assert.equal(header.typ, 'JWT');
  assert.equal(header.kid, 'ABC123DEF4');

  const payload = decode(parts[1]);
  assert.equal(payload.iss, 'TY5JW393Q5');
  assert.equal(payload.sub, 'com.solodevlab.solara.signin');
  assert.equal(payload.aud, 'https://appleid.apple.com');
  assert.equal(payload.iat, 1700000000);
  assert.equal(payload.exp, 1700000000 + 600);
});

test('buildAppleClientSecret: secret 欠落 → throw apple_siwa_secrets_missing', async () => {
  await assert.rejects(
    buildAppleClientSecret({ APPLE_TEAM_ID: 'X' }, 1700000000),
    /apple_siwa_secrets_missing/,
  );
});

// ── revokeAppleToken ─────────────────────────────────────────

test('revokeAppleToken: secrets 未設定 → secrets_missing (no-op で skip)', async () => {
  let fetched = false;
  _setFetchForTest(async () => { fetched = true; return new Response('', { status: 200 }); });
  const result = await revokeAppleToken({}, 'auth-code-xxx');
  assert.equal(result.ok, false);
  assert.equal(result.reason, 'secrets_missing');
  assert.equal(fetched, false, '鍵未設定で fetch しない');
});

test('revokeAppleToken: authorizationCode 空 → invalid_code', async () => {
  const result = await revokeAppleToken(VALID_ENV, '');
  assert.equal(result.ok, false);
  assert.equal(result.reason, 'invalid_code');
});

test('revokeAppleToken: Apple 200 → ok=true', async () => {
  let captured = null;
  _setFetchForTest(async (url, init) => {
    captured = { url, method: init.method, body: init.body, contentType: init.headers['Content-Type'] };
    return new Response('', { status: 200 });
  });
  const result = await revokeAppleToken(VALID_ENV, 'c.auth.code');
  assert.equal(result.ok, true);
  assert.equal(result.status, 200);
  assert.equal(captured.url, 'https://appleid.apple.com/auth/revoke');
  assert.equal(captured.method, 'POST');
  assert.equal(captured.contentType, 'application/x-www-form-urlencoded');
  // body は URL encoded form。client_id / client_secret / token / token_type_hint を含む
  assert.match(captured.body, /client_id=com\.solodevlab\.solara\.signin/);
  assert.match(captured.body, /token=c\.auth\.code/);
  assert.match(captured.body, /token_type_hint=access_token/);
  assert.match(captured.body, /client_secret=eyJ/); // JWT 開始 (base64url of {"alg":...})
});

test('revokeAppleToken: Apple 400 (invalid_client 等) → ok=false apple_400', async () => {
  _setFetchForTest(async () => new Response('{"error":"invalid_client"}', { status: 400 }));
  const result = await revokeAppleToken(VALID_ENV, 'bad-code');
  assert.equal(result.ok, false);
  assert.equal(result.reason, 'apple_400');
});

test('revokeAppleToken: fetch 例外 → fetch_error', async () => {
  _setFetchForTest(async () => { throw new Error('network'); });
  const result = await revokeAppleToken(VALID_ENV, 'code');
  assert.equal(result.ok, false);
  assert.equal(result.reason, 'fetch_error');
});
