/**
 * Pro 同期遅延の安全停止 (425 pro_sync_pending) のテスト。
 *
 * 設計の核:
 *   クライアント側 RC SDK が「Pro active」と認識しているが Worker (DO `user_entitlements`)
 *   が「非 Pro」と判定する瞬間に、購入クレジットを誤消費しないための安全機構。
 *
 * 対象:
 *   - src/auth/rc_rest.js                 reverifyEntitlementViaRC (RC REST V1 再検証 + 30s memcache)
 *   - src/index.js _internal:
 *       consultationClientEntitlement      body 解析 (validate + null fallback)
 *       proSyncReconcile                   "client claims Pro × DO non-Pro" の判定ロジック
 *       gateConsultation                   Stella 相談ゲート (proSyncReconcile を経由)
 *       consumeReadingCreditGate           Tarot カテゴリゲート (同上)
 *
 * fetch は globalThis.fetch を _setFetchForTest で差し替えてモックする。
 *
 * 実行: cd apps/solara/worker && node --test test/pro_sync_pending.test.js
 */
import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { _internal } from '../src/index.js';
import {
  reverifyEntitlementViaRC,
  deleteSubscriberViaRC,
  _setFetchForTest,
  _resetRcRestCacheForTest,
} from '../src/auth/rc_rest.js';
import { _resetEntitlementCacheForTest } from '../src/auth/entitlement_cache.js';

const {
  consultationClientEntitlement,
  proSyncReconcile,
  gateConsultation,
  consumeReadingCreditGate,
  consultationCreditStatus,
} = _internal;

const APP_USER_ID = 'google:117419213296986181342';
const SECRET = 'sk_test_dummy';

// ── env / request / fetch mock ──────────────────────────────

function makeEnv({ doHandler, secret = SECRET, extra = {} } = {}) {
  const calls = [];
  const stub = {
    fetch: async (url, init) => {
      const path = new URL(url).pathname;
      const body = init?.body ? JSON.parse(init.body) : {};
      calls.push({ path, body });
      const { status, body: respBody } = await doHandler(path, body);
      return new Response(JSON.stringify(respBody), { status });
    },
  };
  return {
    env: {
      ATTESTATION_DO: { idFromName: () => 'g', get: () => stub },
      REVENUECAT_SECRET_KEY: secret,
      ...extra,
    },
    calls,
  };
}

function makeRequest(headers = {}) {
  return { headers: { get: (h) => (h in headers ? headers[h] : null) } };
}

function doNoEntitlement() {
  // 全ての DO 呼出に 404 を返す = "DO は user を知らない"
  return (path) => {
    if (path === '/entitlement-get') return { status: 404, body: { error: 'entitlement_not_found' } };
    if (path === '/consultation-credit-get') return { status: 200, body: { used: 3 } }; // 無料使い切り
    if (path === '/consultation-purchased-get') return { status: 200, body: { balance: 10 } }; // 購入残あり
    if (path === '/consultation-purchased-spend') return { status: 200, body: { balance: 9, spent: true } };
    if (path === '/consultation-pro-credit-get') return { status: 200, body: { used: 0 } };
    if (path === '/consultation-pro-credit-bump') return { status: 200, body: { used: 1 } };
    return { status: 404, body: {} };
  };
}

function makeFetchMock(handler) {
  return async (url, init) => {
    return handler(url, init);
  };
}

beforeEach(() => {
  _resetEntitlementCacheForTest();
  _resetRcRestCacheForTest();
  _setFetchForTest((...args) => globalThis.fetch(...args));
});

// ── consultationClientEntitlement ────────────────────────────

test('consultationClientEntitlement: body 無し / 不正 → null', () => {
  assert.equal(consultationClientEntitlement(null), null);
  assert.equal(consultationClientEntitlement({}), null);
  assert.equal(consultationClientEntitlement({ __clientEntitlement: 'not-an-object' }), null);
  assert.equal(consultationClientEntitlement({ __clientEntitlement: null }), null);
});

test('consultationClientEntitlement: 正常な snapshot を parse', () => {
  const ent = consultationClientEntitlement({
    __clientEntitlement: {
      isPro: true,
      verification: 'verified',
      expiresAtMs: 1779000000000,
      productId: 'solara.pro.monthly',
    },
  });
  assert.deepEqual(ent, {
    isPro: true,
    verification: 'verified',
    expiresAtMs: 1779000000000,
    productId: 'solara.pro.monthly',
  });
});

test('consultationClientEntitlement: isPro 以外の型が不正でも安全に null fallback', () => {
  // isPro が boolean でない → false に倒れる
  const ent = consultationClientEntitlement({
    __clientEntitlement: { isPro: 'yes', verification: null, expiresAtMs: 'bad', productId: 42 },
  });
  assert.deepEqual(ent, {
    isPro: false,
    verification: null,
    expiresAtMs: null,
    productId: null,
  });
});

// ── reverifyEntitlementViaRC ─────────────────────────────────

test('reverifyEntitlementViaRC: SECRET_KEY 未設定 → no_key', async () => {
  const result = await reverifyEntitlementViaRC({}, APP_USER_ID);
  assert.equal(result.isPro, false);
  assert.equal(result.reason, 'no_key');
});

test('reverifyEntitlementViaRC: appUserId 空 → invalid_id', async () => {
  const result = await reverifyEntitlementViaRC({ REVENUECAT_SECRET_KEY: SECRET }, '');
  assert.equal(result.isPro, false);
  assert.equal(result.reason, 'invalid_id');
});

test('reverifyEntitlementViaRC: 200 + active entitlement → isPro:true', async () => {
  const future = new Date(Date.now() + 30 * 86_400_000).toISOString();
  _setFetchForTest(makeFetchMock(async () => new Response(JSON.stringify({
    subscriber: {
      entitlements: {
        cosmic_pro: {
          expires_date: future,
          grace_period_expires_date: null,
          product_identifier: 'solara.pro.monthly',
          period_type: 'normal',
        },
      },
    },
  }), { status: 200 })));
  const result = await reverifyEntitlementViaRC({ REVENUECAT_SECRET_KEY: SECRET }, APP_USER_ID);
  assert.equal(result.isPro, true);
  assert.equal(result.entitlementId, 'cosmic_pro');
  assert.equal(result.productId, 'solara.pro.monthly');
  assert.equal(result.periodType, 'normal');
  assert.ok(result.expiresAt > Date.now());
});

test('reverifyEntitlementViaRC: 200 + expired both expiries → reason:expired', async () => {
  const past = new Date(Date.now() - 60_000).toISOString();
  _setFetchForTest(makeFetchMock(async () => new Response(JSON.stringify({
    subscriber: {
      entitlements: {
        cosmic_pro: { expires_date: past, grace_period_expires_date: null },
      },
    },
  }), { status: 200 })));
  const result = await reverifyEntitlementViaRC({ REVENUECAT_SECRET_KEY: SECRET }, APP_USER_ID);
  assert.equal(result.isPro, false);
  assert.equal(result.reason, 'expired');
});

test('reverifyEntitlementViaRC: expires_date 過去 + grace 未来 → grace で Pro 維持', async () => {
  const past = new Date(Date.now() - 60_000).toISOString();
  const future = new Date(Date.now() + 3 * 86_400_000).toISOString();
  _setFetchForTest(makeFetchMock(async () => new Response(JSON.stringify({
    subscriber: {
      entitlements: {
        cosmic_pro: { expires_date: past, grace_period_expires_date: future },
      },
    },
  }), { status: 200 })));
  const result = await reverifyEntitlementViaRC({ REVENUECAT_SECRET_KEY: SECRET }, APP_USER_ID);
  assert.equal(result.isPro, true);
  // effective expiry は grace 側
  assert.equal(result.expiresAt, Date.parse(future));
});

test('reverifyEntitlementViaRC: 200 + entitlement なし → no_entitlement', async () => {
  _setFetchForTest(makeFetchMock(async () => new Response(JSON.stringify({
    subscriber: { entitlements: {} },
  }), { status: 200 })));
  const result = await reverifyEntitlementViaRC({ REVENUECAT_SECRET_KEY: SECRET }, APP_USER_ID);
  assert.equal(result.isPro, false);
  assert.equal(result.reason, 'no_entitlement');
});

test('reverifyEntitlementViaRC: RC 404 → reason:rc_404', async () => {
  _setFetchForTest(makeFetchMock(async () => new Response('not found', { status: 404 })));
  const result = await reverifyEntitlementViaRC({ REVENUECAT_SECRET_KEY: SECRET }, APP_USER_ID);
  assert.equal(result.isPro, false);
  assert.equal(result.reason, 'rc_404');
});

test('reverifyEntitlementViaRC: 30s memcache が効く (同じ appUserId は再 fetch しない)', async () => {
  let fetchCount = 0;
  const future = new Date(Date.now() + 30 * 86_400_000).toISOString();
  _setFetchForTest(async () => {
    fetchCount += 1;
    return new Response(JSON.stringify({
      subscriber: { entitlements: { cosmic_pro: { expires_date: future } } },
    }), { status: 200 });
  });
  const env = { REVENUECAT_SECRET_KEY: SECRET };
  await reverifyEntitlementViaRC(env, APP_USER_ID);
  await reverifyEntitlementViaRC(env, APP_USER_ID);
  await reverifyEntitlementViaRC(env, APP_USER_ID);
  assert.equal(fetchCount, 1);
});

test('reverifyEntitlementViaRC: lifetime (両方 null) → isPro:true', async () => {
  _setFetchForTest(makeFetchMock(async () => new Response(JSON.stringify({
    subscriber: {
      entitlements: {
        cosmic_pro: { expires_date: null, grace_period_expires_date: null, product_identifier: 'lifetime' },
      },
    },
  }), { status: 200 })));
  const result = await reverifyEntitlementViaRC({ REVENUECAT_SECRET_KEY: SECRET }, APP_USER_ID);
  assert.equal(result.isPro, true);
  assert.equal(result.expiresAt, null);
});

// ── proSyncReconcile ─────────────────────────────────────────

test('proSyncReconcile: appUserId 無し → effectiveIsPro:false (RC 呼ばない)', async () => {
  let fetched = false;
  _setFetchForTest(async () => { fetched = true; return new Response('{}', { status: 200 }); });
  const recon = await proSyncReconcile({ REVENUECAT_SECRET_KEY: SECRET }, null, {
    __clientEntitlement: { isPro: true, verification: 'verified' },
  }, null);
  assert.equal(recon.effectiveIsPro, false);
  assert.equal(fetched, false);
});

test('proSyncReconcile: clientEntitlement 無し → effectiveIsPro:false', async () => {
  let fetched = false;
  _setFetchForTest(async () => { fetched = true; return new Response('{}', { status: 200 }); });
  const recon = await proSyncReconcile(
    { REVENUECAT_SECRET_KEY: SECRET }, APP_USER_ID, {}, null);
  assert.equal(recon.effectiveIsPro, false);
  assert.equal(fetched, false);
});

test('proSyncReconcile: clientEnt.isPro=false → effectiveIsPro:false', async () => {
  const recon = await proSyncReconcile(
    { REVENUECAT_SECRET_KEY: SECRET }, APP_USER_ID,
    { __clientEntitlement: { isPro: false, verification: 'verified' } }, null);
  assert.equal(recon.effectiveIsPro, false);
});

test('proSyncReconcile: clientEnt Pro + RC も Pro → effectiveIsPro:true', async () => {
  const future = new Date(Date.now() + 30 * 86_400_000).toISOString();
  _setFetchForTest(makeFetchMock(async () => new Response(JSON.stringify({
    subscriber: { entitlements: { cosmic_pro: { expires_date: future } } },
  }), { status: 200 })));
  const recon = await proSyncReconcile(
    { REVENUECAT_SECRET_KEY: SECRET }, APP_USER_ID,
    { __clientEntitlement: { isPro: true, verification: 'verified', expiresAtMs: Date.parse(future) } },
    null);
  assert.equal(recon.effectiveIsPro, true);
});

test('proSyncReconcile: clientEnt Pro (verified, 期限間近) + RC 非Pro → 425 block', async () => {
  _setFetchForTest(makeFetchMock(async () => new Response(JSON.stringify({
    subscriber: { entitlements: {} },
  }), { status: 200 })));
  const recon = await proSyncReconcile(
    { REVENUECAT_SECRET_KEY: SECRET }, APP_USER_ID,
    {
      __clientEntitlement: {
        isPro: true,
        verification: 'verified',
        expiresAtMs: Date.now() + 60_000,  // まだ未来 (or 失効から 5 分以内)
      },
    },
    null);
  assert.ok(recon.block);
  assert.equal(recon.block.status, 425);
  assert.equal(recon.block.headers.get('Retry-After'), '30');
  const body = await recon.block.json();
  assert.equal(body.error, 'pro_sync_pending');
  assert.equal(body.retryAfterSec, 30);
});

test('proSyncReconcile: clientEnt Pro (verifiedOnDevice) + RC 非Pro → 425 block', async () => {
  _setFetchForTest(makeFetchMock(async () => new Response(JSON.stringify({
    subscriber: { entitlements: {} },
  }), { status: 200 })));
  const recon = await proSyncReconcile(
    { REVENUECAT_SECRET_KEY: SECRET }, APP_USER_ID,
    {
      __clientEntitlement: {
        isPro: true,
        verification: 'verifiedOnDevice',
        expiresAtMs: null, // lifetime
      },
    },
    null);
  assert.ok(recon.block);
  assert.equal(recon.block.status, 425);
});

test('proSyncReconcile: clientEnt Pro (notRequested) + RC 非Pro → 425 block (RC 鍵未設定でも善意ユーザーを保護)', async () => {
  // notRequested は RC ダッシュボード Trusted Entitlements 鍵未設定時のデフォルト。
  // 「検証してない」だけで「偽である」根拠はないので、攻撃面ゼロ (= 偽主張しても機能解放
  // されない) を踏まえて 425 で安全停止する。これで RC 鍵設定無しでも善意ユーザーが
  // 守られる。
  _setFetchForTest(makeFetchMock(async () => new Response(JSON.stringify({
    subscriber: { entitlements: {} },
  }), { status: 200 })));
  const recon = await proSyncReconcile(
    { REVENUECAT_SECRET_KEY: SECRET }, APP_USER_ID,
    {
      __clientEntitlement: {
        isPro: true,
        verification: 'notRequested',
        expiresAtMs: Date.now() + 60_000,
      },
    },
    null);
  assert.ok(recon.block);
  assert.equal(recon.block.status, 425);
});

test('proSyncReconcile: clientEnt Pro (failed=MITM 検出) + RC 非Pro → effectiveIsPro:false (block しない、攻撃を阻止)', async () => {
  // RC が「署名不一致 = MITM 攻撃の可能性」を確定したケース。クライアント主張は
  // 信用してはいけない。425 出さず通常 Free 経路に落とし、購入残あれば消費される。
  // 結果として攻撃者は機能を使えず、防御として機能する。
  _setFetchForTest(makeFetchMock(async () => new Response(JSON.stringify({
    subscriber: { entitlements: {} },
  }), { status: 200 })));
  const recon = await proSyncReconcile(
    { REVENUECAT_SECRET_KEY: SECRET }, APP_USER_ID,
    {
      __clientEntitlement: {
        isPro: true,
        verification: 'failed',
        expiresAtMs: Date.now() + 60_000,
      },
    },
    null);
  assert.equal(recon.effectiveIsPro, false);
  assert.equal(recon.block, undefined);
});

test('proSyncReconcile: clientEnt Pro (verified, 失効から 10 分超) + RC 非Pro → effectiveIsPro:false', async () => {
  _setFetchForTest(makeFetchMock(async () => new Response(JSON.stringify({
    subscriber: { entitlements: {} },
  }), { status: 200 })));
  const recon = await proSyncReconcile(
    { REVENUECAT_SECRET_KEY: SECRET }, APP_USER_ID,
    {
      __clientEntitlement: {
        isPro: true,
        verification: 'verified',
        expiresAtMs: Date.now() - 10 * 60 * 1000, // 10 分前失効 → 古すぎる
      },
    },
    null);
  assert.equal(recon.effectiveIsPro, false);
  assert.equal(recon.block, undefined);
});

// ── gateConsultation (proSyncReconcile 経由の挙動) ─────────────

test('gateConsultation: DO 非Pro + clientEnt Pro + RC 確認 OK → Pro 経路 (pro_weekly 消費)', async () => {
  const future = new Date(Date.now() + 30 * 86_400_000).toISOString();
  _setFetchForTest(makeFetchMock(async () => new Response(JSON.stringify({
    subscriber: { entitlements: { cosmic_pro: { expires_date: future } } },
  }), { status: 200 })));
  const { env } = makeEnv({ doHandler: doNoEntitlement() });
  const req = makeRequest({ 'X-AppAttest-KeyId': 'KID1' });
  const body = {
    __appUserId: APP_USER_ID,
    __clientEntitlement: { isPro: true, verification: 'verified', expiresAtMs: Date.parse(future) },
    mode: 'daily',
  };
  const result = await gateConsultation(req, env, body, null);
  assert.equal(result.allow, true);
  assert.equal(result.isPro, true);
  assert.equal(result.source, 'pro_weekly');
});

test('gateConsultation: DO 非Pro + clientEnt Pro (verified, 期限内) + RC 非Pro → 425 block', async () => {
  _setFetchForTest(makeFetchMock(async () => new Response(JSON.stringify({
    subscriber: { entitlements: {} },
  }), { status: 200 })));
  const { env } = makeEnv({ doHandler: doNoEntitlement() });
  const req = makeRequest({ 'X-AppAttest-KeyId': 'KID1' });
  const body = {
    __appUserId: APP_USER_ID,
    __clientEntitlement: { isPro: true, verification: 'verified', expiresAtMs: Date.now() + 60_000 },
    mode: 'daily',
  };
  const result = await gateConsultation(req, env, body, null);
  assert.ok(result.block);
  assert.equal(result.block.status, 425);
  const respBody = await result.block.json();
  assert.equal(respBody.error, 'pro_sync_pending');
});

test('gateConsultation: DO 非Pro + clientEnt Pro (notRequested) + RC 非Pro → 425 block (RC 鍵未設定でも保護)', async () => {
  // 旧仕様: notRequested は信用せず Free 経路 → 購入残誤消費。
  // 新仕様: notRequested も「失敗証拠なし」として 425 で安全停止 (= 攻撃面ゼロ + 善意ユーザー保護)。
  _setFetchForTest(makeFetchMock(async () => new Response(JSON.stringify({
    subscriber: { entitlements: {} },
  }), { status: 200 })));
  const { env } = makeEnv({ doHandler: doNoEntitlement() });
  const req = makeRequest({ 'X-AppAttest-KeyId': 'KID1' });
  const body = {
    __appUserId: APP_USER_ID,
    __clientEntitlement: { isPro: true, verification: 'notRequested', expiresAtMs: Date.now() + 60_000 },
    mode: 'daily',
  };
  const result = await gateConsultation(req, env, body, null);
  assert.ok(result.block);
  assert.equal(result.block.status, 425);
});

test('gateConsultation: DO 非Pro + clientEnt Pro (failed=MITM) + RC 非Pro → Free 経路 (攻撃阻止)', async () => {
  // MITM 攻撃確定時は client 主張を信用せず、通常 Free 経路で攻撃を阻止する。
  _setFetchForTest(makeFetchMock(async () => new Response(JSON.stringify({
    subscriber: { entitlements: {} },
  }), { status: 200 })));
  const { env } = makeEnv({ doHandler: doNoEntitlement() });
  const req = makeRequest({ 'X-AppAttest-KeyId': 'KID1' });
  const body = {
    __appUserId: APP_USER_ID,
    __clientEntitlement: { isPro: true, verification: 'failed', expiresAtMs: Date.now() + 60_000 },
    mode: 'daily',
  };
  const result = await gateConsultation(req, env, body, null);
  // failed は信用しない → Free 経路。doNoEntitlement は無料0+購入10 を返すので purchased が当たる。
  assert.equal(result.allow, true);
  assert.equal(result.isPro, false);
  assert.equal(result.source, 'purchased');
});

test('gateConsultation: clientEnt なし (旧クライアント) → 従来挙動 (Free 経路) — 後方互換', async () => {
  const { env } = makeEnv({ doHandler: doNoEntitlement() });
  const req = makeRequest({ 'X-AppAttest-KeyId': 'KID1' });
  const body = { __appUserId: APP_USER_ID, mode: 'daily' };
  const result = await gateConsultation(req, env, body, null);
  assert.equal(result.allow, true);
  assert.equal(result.isPro, false);
  assert.equal(result.source, 'purchased');
});

// ── consumeReadingCreditGate (Tarot カテゴリゲート) ────────────

test('consumeReadingCreditGate: DO 非Pro + clientEnt Pro + RC OK → Pro 通過 (Tarot 無制限)', async () => {
  const future = new Date(Date.now() + 30 * 86_400_000).toISOString();
  _setFetchForTest(makeFetchMock(async () => new Response(JSON.stringify({
    subscriber: { entitlements: { cosmic_pro: { expires_date: future } } },
  }), { status: 200 })));
  const { env } = makeEnv({ doHandler: doNoEntitlement() });
  const req = makeRequest({ 'X-AppAttest-KeyId': 'KID1' });
  const body = {
    __appUserId: APP_USER_ID,
    __clientEntitlement: { isPro: true, verification: 'verified', expiresAtMs: Date.parse(future) },
  };
  const result = await consumeReadingCreditGate(req, env, body, null);
  assert.equal(result.allow, true);
  assert.equal(result.isPro, true);
});

test('consumeReadingCreditGate: DO 非Pro + clientEnt Pro (verified) + RC 非Pro → 425 block (Tarot でも誤消費しない)', async () => {
  _setFetchForTest(makeFetchMock(async () => new Response(JSON.stringify({
    subscriber: { entitlements: {} },
  }), { status: 200 })));
  const { env } = makeEnv({ doHandler: doNoEntitlement() });
  const req = makeRequest({ 'X-AppAttest-KeyId': 'KID1' });
  const body = {
    __appUserId: APP_USER_ID,
    __clientEntitlement: { isPro: true, verification: 'verified', expiresAtMs: Date.now() + 60_000 },
  };
  const result = await consumeReadingCreditGate(req, env, body, null);
  assert.ok(result.block);
  assert.equal(result.block.status, 425);
});

// ── consultationCreditStatus (Pro 購入直後の Sanctuary 残数表示 自己治癒) ────────

test('consultationCreditStatus: DO 非Pro + clientEnt Pro + RC で Pro 確認 → Pro レスポンス (proRemaining 数値)', async () => {
  // Pro 購入直後のシナリオ:
  //   - 端末は RC SDK の listener で Pro active 認識 (instant)
  //   - Worker DO はまだ webhook が届いておらず非 Pro
  //   - status endpoint で 0/0 が出ると Sanctuary 残数表示が壊れる
  //   - reconcile が RC REST 再検証で Pro 確認 → proRemaining=100/proLimit=100 返却
  const future = new Date(Date.now() + 30 * 86_400_000).toISOString();
  _setFetchForTest(makeFetchMock(async () => new Response(JSON.stringify({
    subscriber: { entitlements: { cosmic_pro: { expires_date: future } } },
  }), { status: 200 })));
  const { env } = makeEnv({ doHandler: doNoEntitlement() });
  const req = makeRequest({ 'X-AppAttest-KeyId': 'KID1' });
  const body = {
    __appUserId: APP_USER_ID,
    __clientEntitlement: { isPro: true, verification: 'verified', expiresAtMs: Date.parse(future) },
  };
  const status = await consultationCreditStatus(env, req, body);
  assert.equal(status.pro, true, 'reverify 経由で Pro レスポンスを返す');
  assert.equal(status.proLimit, 100);
  assert.equal(status.proRemaining, 100);
  assert.equal(status.freeRemaining, null);
  assert.equal(status.freeLimit, null);
});

test('consultationCreditStatus: DO 非Pro + clientEnt Pro + RC も非Pro → Free レスポンス (block しない)', async () => {
  // RC でも非 Pro と確認できれば、status endpoint は block を返さず通常 Free 表示を返す。
  // gateConsultation と異なり 425 で残数画面を壊さないこと。
  _setFetchForTest(makeFetchMock(async () => new Response(JSON.stringify({
    subscriber: { entitlements: {} },
  }), { status: 200 })));
  const { env } = makeEnv({ doHandler: doNoEntitlement() });
  const req = makeRequest({ 'X-AppAttest-KeyId': 'KID1' });
  const body = {
    __appUserId: APP_USER_ID,
    __clientEntitlement: { isPro: true, verification: 'verified', expiresAtMs: Date.now() + 60_000 },
  };
  const status = await consultationCreditStatus(env, req, body);
  assert.equal(status.pro, false, 'reverify 失敗時は素直に Free 表示');
  assert.equal(status.proRemaining, null);
  assert.equal(status.proLimit, null);
  // doNoEntitlement の Free 残量 3 - 3 used = 0、purchased 10
  assert.equal(status.purchasedBalance, 10);
});

test('consultationCreditStatus: clientEnt なし (旧クライアント) + DO 非Pro → 従来 Free レスポンス (RC 呼ばない)', async () => {
  let fetched = false;
  _setFetchForTest(async () => { fetched = true; return new Response('{}', { status: 200 }); });
  const { env } = makeEnv({ doHandler: doNoEntitlement() });
  const req = makeRequest({ 'X-AppAttest-KeyId': 'KID1' });
  const body = { __appUserId: APP_USER_ID }; // __clientEntitlement なし
  const status = await consultationCreditStatus(env, req, body);
  assert.equal(status.pro, false);
  assert.equal(fetched, false, 'クライアント主張なしで RC REST を呼ばない');
});

// ── deleteSubscriberViaRC (GDPR Right to Erasure 用) ─────────────

test('deleteSubscriberViaRC: SECRET_KEY 未設定 → no_key (fetch しない)', async () => {
  let fetched = false;
  _setFetchForTest(async () => { fetched = true; return new Response('{}', { status: 200 }); });
  const result = await deleteSubscriberViaRC({}, APP_USER_ID);
  assert.equal(result.ok, false);
  assert.equal(result.reason, 'no_key');
  assert.equal(fetched, false);
});

test('deleteSubscriberViaRC: appUserId 空 → invalid_id', async () => {
  const result = await deleteSubscriberViaRC({ REVENUECAT_SECRET_KEY: SECRET }, '');
  assert.equal(result.ok, false);
  assert.equal(result.reason, 'invalid_id');
});

test('deleteSubscriberViaRC: RC 200 → ok=true + DELETE method 使用', async () => {
  let captured = null;
  _setFetchForTest(async (url, init) => {
    captured = { url, method: init.method, auth: init.headers.Authorization };
    return new Response(JSON.stringify({}), { status: 200 });
  });
  const result = await deleteSubscriberViaRC(
    { REVENUECAT_SECRET_KEY: SECRET },
    APP_USER_ID,
  );
  assert.equal(result.ok, true);
  assert.equal(result.status, 200);
  assert.equal(captured.method, 'DELETE');
  assert.match(captured.url, /\/v1\/subscribers\//);
  assert.equal(captured.auth, `Bearer ${SECRET}`);
});

test('deleteSubscriberViaRC: RC 404 (既に居ない) → ok=true (= 既削除扱い)', async () => {
  _setFetchForTest(async () => new Response('not found', { status: 404 }));
  const result = await deleteSubscriberViaRC(
    { REVENUECAT_SECRET_KEY: SECRET },
    APP_USER_ID,
  );
  assert.equal(result.ok, true);
  assert.equal(result.status, 404);
});

test('deleteSubscriberViaRC: RC 500 → ok=false (アカウント削除フローは継続するが警告ログ)', async () => {
  _setFetchForTest(async () => new Response('error', { status: 500 }));
  const result = await deleteSubscriberViaRC(
    { REVENUECAT_SECRET_KEY: SECRET },
    APP_USER_ID,
  );
  assert.equal(result.ok, false);
  assert.equal(result.reason, 'rc_500');
});

test('deleteSubscriberViaRC: fetch 例外 → ok=false fetch_error', async () => {
  _setFetchForTest(async () => { throw new Error('network'); });
  const result = await deleteSubscriberViaRC(
    { REVENUECAT_SECRET_KEY: SECRET },
    APP_USER_ID,
  );
  assert.equal(result.ok, false);
  assert.equal(result.reason, 'fetch_error');
});

test('deleteSubscriberViaRC: 削除成功時に reverify cache を invalidate (古い Pro snapshot を残さない)', async () => {
  // 1. reverify cache に Pro snapshot を載せる (RC 200 で active を取得)
  const future = new Date(Date.now() + 30 * 86_400_000).toISOString();
  _setFetchForTest(makeFetchMock(async () => new Response(JSON.stringify({
    subscriber: { entitlements: { cosmic_pro: { expires_date: future } } },
  }), { status: 200 })));
  const env = { REVENUECAT_SECRET_KEY: SECRET };
  const before = await reverifyEntitlementViaRC(env, APP_USER_ID);
  assert.equal(before.isPro, true);

  // 2. DELETE を実行 → 200
  _setFetchForTest(async () => new Response('', { status: 200 }));
  const delResult = await deleteSubscriberViaRC(env, APP_USER_ID);
  assert.equal(delResult.ok, true);

  // 3. 次の reverify は cache miss して新規 fetch を行うはず (cache invalidate されている)
  let refetched = false;
  _setFetchForTest(async () => {
    refetched = true;
    return new Response(JSON.stringify({ subscriber: { entitlements: {} } }), { status: 200 });
  });
  const after = await reverifyEntitlementViaRC(env, APP_USER_ID);
  assert.equal(refetched, true, '削除後の reverify は cache miss して再 fetch する');
  assert.equal(after.isPro, false);
});
