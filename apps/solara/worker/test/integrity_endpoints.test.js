/**
 * apps/solara/worker/src/index.js の S4 endpoint テスト:
 *   - handleIntegrityChallenge (POST /auth/integrity/challenge)
 *   - getEnforcement / getPlayIntegrityEnforcement の env 解釈
 *   - extractAppUserId の body parse
 *
 * 実行: cd apps/solara/worker && node --test test/integrity_endpoints.test.js
 *
 * AttestationState 本体は Cloudflare runtime 依存のため Node から直接 import しない
 * (revenuecat_webhook.test.js と同じ方針)。env.ATTESTATION_DO.fetch を mock することで
 * Worker 側ロジックを検証する。
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { _internal } from '../src/index.js';

const { handleIntegrityChallenge, getEnforcement, getPlayIntegrityEnforcement, extractAppUserId } =
  _internal;

// ── env mock ───────────────────────────────────────────────

/**
 * env.ATTESTATION_DO.fetch を mock。
 * @param {(path: string, body: object) => {status, body}} handler - DO の応答を返す
 * @returns {{env, calls}}
 */
function makeEnv(handler, extra = {}) {
  const calls = [];
  const stub = {
    fetch: async (url, init) => {
      const path = new URL(url).pathname;
      const body = init?.body ? JSON.parse(init.body) : {};
      calls.push({ path, body });
      const { status, body: respBody } = await handler(path, body);
      return new Response(JSON.stringify(respBody), { status });
    },
  };
  return {
    env: {
      PLAY_INTEGRITY_NONCE_TTL_SEC: '300',
      ATTESTATION_DO: {
        idFromName: () => 'global-id',
        get: () => stub,
      },
      ...extra,
    },
    calls,
  };
}

// ── handleIntegrityChallenge ─────────────────────────────

test('handleIntegrityChallenge: 正常系で {nonceId, nonce, ttlSec} 返却 + DO INSERT 呼出', async () => {
  const { env, calls } = makeEnv(() => ({ status: 200, body: { ok: true } }));

  const response = await handleIntegrityChallenge(env, null);
  assert.equal(response.status, 200);
  const json = await response.json();

  assert.ok(typeof json.nonceId === 'string' && json.nonceId.length > 0);
  assert.ok(typeof json.nonce === 'string' && json.nonce.length === 44, 'base64 32B should be 44 char');
  assert.equal(json.ttlSec, 300);

  // DO に正しく INSERT 呼出されたか
  assert.equal(calls.length, 1);
  assert.equal(calls[0].path, '/integrity-nonce-create');
  assert.equal(calls[0].body.nonceId, json.nonceId);
  assert.equal(calls[0].body.nonceB64, json.nonce);
  assert.ok(typeof calls[0].body.expiresAt === 'number');
  assert.ok(calls[0].body.expiresAt > Date.now());
  assert.ok(calls[0].body.expiresAt <= Date.now() + 301_000);
});

test('handleIntegrityChallenge: 標準 base64 (URL-safe ではない、=パディングあり)', async () => {
  const { env } = makeEnv(() => ({ status: 200, body: { ok: true } }));

  // 100 回回して URL-safe 文字 (- _) が含まれず、`=` パディングが正しいことを確認
  for (let i = 0; i < 50; i++) {
    const response = await handleIntegrityChallenge(env, null);
    const json = await response.json();
    assert.match(json.nonce, /^[A-Za-z0-9+/]{43}=$/, `nonce ${i} is not standard base64`);
  }
});

test('handleIntegrityChallenge: 各呼出で nonce が unique', async () => {
  const { env } = makeEnv(() => ({ status: 200, body: { ok: true } }));
  const seen = new Set();
  for (let i = 0; i < 20; i++) {
    const response = await handleIntegrityChallenge(env, null);
    const json = await response.json();
    assert.equal(seen.has(json.nonce), false, `nonce ${json.nonce} duplicated`);
    seen.add(json.nonce);
  }
  assert.equal(seen.size, 20);
});

test('handleIntegrityChallenge: DO が 409 nonce_id_conflict → 500 返却', async () => {
  const { env } = makeEnv(() => ({
    status: 409,
    body: { error: 'nonce_id_conflict' },
  }));

  const response = await handleIntegrityChallenge(env, null);
  assert.equal(response.status, 500);
  const json = await response.json();
  assert.match(json.error, /integrity-nonce-create failed/);
  assert.match(json.error, /nonce_id_conflict/);
});

test('handleIntegrityChallenge: DO 500 エラー → 500 返却', async () => {
  const { env } = makeEnv(() => ({
    status: 500,
    body: { error: 'internal' },
  }));

  const response = await handleIntegrityChallenge(env, null);
  assert.equal(response.status, 500);
});

test('handleIntegrityChallenge: TTL_SEC env 未設定で default 300 使用', async () => {
  const { env, calls } = makeEnv(() => ({ status: 200, body: { ok: true } }));
  delete env.PLAY_INTEGRITY_NONCE_TTL_SEC;

  const response = await handleIntegrityChallenge(env, null);
  const json = await response.json();
  assert.equal(json.ttlSec, 300);
  assert.ok(calls[0].body.expiresAt <= Date.now() + 301_000);
});

test('handleIntegrityChallenge: TTL_SEC env で TTL 上書き可能', async () => {
  const { env, calls } = makeEnv(() => ({ status: 200, body: { ok: true } }));
  env.PLAY_INTEGRITY_NONCE_TTL_SEC = '60';

  const response = await handleIntegrityChallenge(env, null);
  const json = await response.json();
  assert.equal(json.ttlSec, 60);
  assert.ok(calls[0].body.expiresAt <= Date.now() + 61_000);
  assert.ok(calls[0].body.expiresAt > Date.now());
});

// ── getPlayIntegrityEnforcement ──────────────────────────

test('getPlayIntegrityEnforcement: env 未設定で log_only default', () => {
  assert.equal(getPlayIntegrityEnforcement({}), 'log_only');
});

test('getPlayIntegrityEnforcement: 3 値 (disabled / log_only / enforced) を認識', () => {
  assert.equal(getPlayIntegrityEnforcement({ PLAY_INTEGRITY_ENFORCEMENT: 'disabled' }), 'disabled');
  assert.equal(getPlayIntegrityEnforcement({ PLAY_INTEGRITY_ENFORCEMENT: 'log_only' }), 'log_only');
  assert.equal(getPlayIntegrityEnforcement({ PLAY_INTEGRITY_ENFORCEMENT: 'enforced' }), 'enforced');
});

test('getPlayIntegrityEnforcement: 大文字小文字を正規化 + 不明値は log_only fallback', () => {
  assert.equal(getPlayIntegrityEnforcement({ PLAY_INTEGRITY_ENFORCEMENT: 'ENFORCED' }), 'enforced');
  assert.equal(getPlayIntegrityEnforcement({ PLAY_INTEGRITY_ENFORCEMENT: 'invalid' }), 'log_only');
  assert.equal(getPlayIntegrityEnforcement({ PLAY_INTEGRITY_ENFORCEMENT: '' }), 'log_only');
});

test('getEnforcement / getPlayIntegrityEnforcement は独立 (App Attest と Play Integrity)', () => {
  const env = {
    APP_ATTEST_ENFORCEMENT: 'enforced',
    PLAY_INTEGRITY_ENFORCEMENT: 'log_only',
  };
  assert.equal(getEnforcement(env), 'enforced');
  assert.equal(getPlayIntegrityEnforcement(env), 'log_only');
});

// ── extractAppUserId (Step 12 共通基盤) ────────────────────

test('extractAppUserId: 正常な body から取出', () => {
  const body = JSON.stringify({ __appUserId: 'apple:abc123', foo: 'bar' });
  const bytes = new TextEncoder().encode(body);
  assert.equal(extractAppUserId(bytes), 'apple:abc123');
});

test('extractAppUserId: 欠落 / 空 / 非 string で null', () => {
  assert.equal(extractAppUserId(new TextEncoder().encode('{}')), null);
  assert.equal(extractAppUserId(new TextEncoder().encode('{"__appUserId":""}')), null);
  assert.equal(extractAppUserId(new TextEncoder().encode('{"__appUserId":123}')), null);
});

test('extractAppUserId: 非 JSON / 空 bytes で null (例外を投げない)', () => {
  assert.equal(extractAppUserId(new TextEncoder().encode('not json')), null);
  assert.equal(extractAppUserId(new Uint8Array(0)), null);
  assert.equal(extractAppUserId(null), null);
});
