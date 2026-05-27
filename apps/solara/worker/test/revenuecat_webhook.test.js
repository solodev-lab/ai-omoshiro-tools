/**
 * apps/solara/worker/src/webhooks/revenuecat.js + entitlement_cache.js + DO entitlement API のテスト
 *
 * 実行: cd apps/solara/worker && node --test test/revenuecat_webhook.test.js
 *
 * AttestationState の DO 実装は Cloudflare Workers runtime 依存 (state.storage.sql)
 * なので、Node から直接 import せず、`callDo` を mock する handleRevenueCatWebhook
 * の周辺ロジックと、純粋関数 (event 種別分類、constant-time 比較、cache) を検証する。
 *
 * カバー範囲:
 *   1. timingSafeEqualString 動作
 *   2. event 種別マップ (ACTIVE/GRACE/INACTIVE/IGNORE) の網羅
 *   3. handleRevenueCatWebhook の主要分岐:
 *      - secret 未設定 → 503
 *      - Bearer 不一致 → 401
 *      - JSON 不正 → 400
 *      - missing event → 400
 *      - ignore event → 200 ignored
 *      - 非 cosmic_pro event → 200 ignored
 *      - active event → DO upsert 呼出 + cache invalidate
 *      - DO エラー → 500
 *   4. entitlement_cache の TTL + 上限 + clear 動作
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  handleRevenueCatWebhook,
  _internal,
} from '../src/webhooks/revenuecat.js';
import {
  getCachedEntitlement,
  setCachedEntitlement,
  clearMemoryEntitlementCache,
  _resetEntitlementCacheForTest,
} from '../src/auth/entitlement_cache.js';

// ── helpers ────────────────────────────────────────────────

/**
 * env mock。ATTESTATION_DO は callDo() のシグネチャに合わせて
 * idFromName→get→fetch を返す stub 構造を持たせる。
 */
function makeEnv({ secret = 'test-secret', doImpl } = {}) {
  const calls = [];
  const stub = {
    fetch: async (url, init) => {
      const path = new URL(url).pathname;
      const body = init?.body ? JSON.parse(init.body) : {};
      calls.push({ path, body });
      if (typeof doImpl === 'function') {
        const { status, body: respBody } = await doImpl(path, body);
        return new Response(JSON.stringify(respBody), { status });
      }
      return new Response(JSON.stringify({ ok: true }), { status: 200 });
    },
  };
  return {
    env: {
      REVENUECAT_WEBHOOK_AUTH: secret,
      ATTESTATION_DO: {
        idFromName: (_n) => 'global-id',
        get: (_id) => stub,
      },
    },
    calls,
  };
}

function makeRequest({
  method = 'POST',
  bearer = 'test-secret',
  body = { event: { type: 'TEST', id: 'evt-1' } },
} = {}) {
  return new Request('https://example.com/webhooks/revenuecat', {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(bearer === null ? {} : { 'Authorization': `Bearer ${bearer}` }),
    },
    body: method === 'GET' ? undefined : JSON.stringify(body),
  });
}

// ── timing-safe ─────────────────────────────────────────────

test('timingSafeEqualString: 等しい', () => {
  assert.equal(_internal.timingSafeEqualString('abc', 'abc'), true);
  assert.equal(_internal.timingSafeEqualString('', ''), true);
});

test('timingSafeEqualString: 長さ違い', () => {
  assert.equal(_internal.timingSafeEqualString('abc', 'abcd'), false);
  assert.equal(_internal.timingSafeEqualString('abc', 'ab'), false);
});

test('timingSafeEqualString: 内容違い', () => {
  assert.equal(_internal.timingSafeEqualString('abc', 'abd'), false);
});

test('timingSafeEqualString: 非 string', () => {
  assert.equal(_internal.timingSafeEqualString(null, 'abc'), false);
  assert.equal(_internal.timingSafeEqualString('abc', undefined), false);
});

// ── event 種別マップ網羅 ─────────────────────────────────────

test('event 種別マップ: ACTIVE が想定通り', () => {
  const expected = [
    'INITIAL_PURCHASE', 'RENEWAL', 'PRODUCT_CHANGE',
    'UNCANCELLATION', 'NON_RENEWING_PURCHASE', 'TEMPORARY_ENTITLEMENT_GRANT',
  ];
  for (const e of expected) {
    assert.equal(_internal.ACTIVE_EVENT_TYPES.has(e), true, `missing: ${e}`);
  }
});

test('event 種別マップ: GRACE/INACTIVE/IGNORE が想定通り', () => {
  assert.equal(_internal.GRACE_EVENT_TYPES.has('CANCELLATION'), true);
  assert.equal(_internal.GRACE_EVENT_TYPES.has('BILLING_ISSUE'), true);
  assert.equal(_internal.INACTIVE_EVENT_TYPES.has('EXPIRATION'), true);
  assert.equal(_internal.INACTIVE_EVENT_TYPES.has('REFUND'), true);
  assert.equal(_internal.IGNORE_EVENT_TYPES.has('TEST'), true);
  assert.equal(_internal.IGNORE_EVENT_TYPES.has('SUBSCRIBER_ALIAS'), true);
});

test('SOLARA_ENTITLEMENT_ID == cosmic_pro', () => {
  assert.equal(_internal.SOLARA_ENTITLEMENT_ID, 'cosmic_pro');
});

// ── 消費型 Stella クレジット購入 (NON_RENEWING_PURCHASE) ──────

const CREDIT_ENV = {
  CONSULTATION_CREDIT_PRODUCTS: 'com.solodevlab.solara.credits.large:10',
};

test('webhook: 消費型クレジット購入 → /consultation-credit-grant 呼出 + 残高返却', async () => {
  _resetEntitlementCacheForTest();
  const { env, calls } = makeEnv({
    doImpl: (path) => {
      if (path === '/consultation-credit-grant') {
        return { status: 200, body: { balance: 10 } };
      }
      return { status: 200, body: { ok: true } };
    },
  });
  Object.assign(env, CREDIT_ENV);
  const req = makeRequest({
    body: {
      event: {
        type: 'NON_RENEWING_PURCHASE',
        id: 'evt-credit-1',
        app_user_id: 'google:buyer1',
        product_id: 'com.solodevlab.solara.credits.large',
      },
    },
  });
  const res = await handleRevenueCatWebhook(req, env);
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.creditsGranted, 10);
  assert.equal(body.balance, 10);
  // grant が呼ばれ、entitlement-upsert は呼ばれない (entitlement を持たない購入)
  const grant = calls.find((c) => c.path === '/consultation-credit-grant');
  assert.ok(grant, 'grant should be called');
  assert.equal(grant.body.appUserId, 'google:buyer1');
  assert.equal(grant.body.amount, 10);
  assert.equal(grant.body.eventId, 'evt-credit-1');
  assert.ok(!calls.some((c) => c.path === '/entitlement-upsert'));
});

test('webhook: NON_RENEWING_PURCHASE だが credit 商品でない → 従来 entitlement 経路', async () => {
  _resetEntitlementCacheForTest();
  const { env, calls } = makeEnv({
    doImpl: () => ({ status: 200, body: { ok: true } }),
  });
  Object.assign(env, CREDIT_ENV);
  const req = makeRequest({
    body: {
      event: {
        type: 'NON_RENEWING_PURCHASE',
        id: 'evt-np-1',
        app_user_id: 'google:u1',
        product_id: 'com.solodevlab.solara.something_else',
        entitlement_ids: ['cosmic_pro'],
        environment: 'PRODUCTION',
      },
    },
  });
  const res = await handleRevenueCatWebhook(req, env);
  assert.equal(res.status, 200);
  // credit grant は呼ばれず、entitlement-upsert に進む
  assert.ok(!calls.some((c) => c.path === '/consultation-credit-grant'));
  assert.ok(calls.some((c) => c.path === '/entitlement-upsert'));
});

// ── handleRevenueCatWebhook 主要分岐 ─────────────────────────

test('webhook: secret 未設定 → 503', async () => {
  const { env } = makeEnv({ secret: '' });
  const res = await handleRevenueCatWebhook(makeRequest(), env);
  assert.equal(res.status, 503);
  const body = await res.json();
  assert.equal(body.error, 'webhook_disabled');
});

test('webhook: GET → 405', async () => {
  const { env } = makeEnv();
  const res = await handleRevenueCatWebhook(makeRequest({ method: 'GET' }), env);
  assert.equal(res.status, 405);
});

test('webhook: Bearer 不一致 → 401', async () => {
  const { env } = makeEnv();
  const res = await handleRevenueCatWebhook(makeRequest({ bearer: 'wrong' }), env);
  assert.equal(res.status, 401);
});

test('webhook: Bearer 未指定 → 401', async () => {
  const { env } = makeEnv();
  const res = await handleRevenueCatWebhook(makeRequest({ bearer: null }), env);
  assert.equal(res.status, 401);
});

test('webhook: 非 JSON body → 400', async () => {
  const { env } = makeEnv();
  const req = new Request('https://example.com/webhooks/revenuecat', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer test-secret',
    },
    body: 'not-json',
  });
  const res = await handleRevenueCatWebhook(req, env);
  assert.equal(res.status, 400);
  const body = await res.json();
  assert.equal(body.error, 'invalid_json');
});

test('webhook: event 欠落 → 400', async () => {
  const { env } = makeEnv();
  const res = await handleRevenueCatWebhook(
    makeRequest({ body: { api_version: '1.0' } }),
    env,
  );
  assert.equal(res.status, 400);
});

test('webhook: TEST event → 200 ignored', async () => {
  const { env, calls } = makeEnv();
  const res = await handleRevenueCatWebhook(
    makeRequest({ body: { event: { type: 'TEST', id: 'evt-test-1' } } }),
    env,
  );
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.ignored, 'TEST');
  assert.equal(calls.length, 0, 'DO は呼ばれない');
});

test('webhook: 別 entitlement の event → 200 ignored', async () => {
  const { env, calls } = makeEnv();
  const res = await handleRevenueCatWebhook(
    makeRequest({
      body: {
        event: {
          type: 'INITIAL_PURCHASE',
          id: 'evt-x',
          app_user_id: 'apple:abc',
          entitlement_ids: ['some_other_pro'],
          environment: 'PRODUCTION',
        },
      },
    }),
    env,
  );
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.ignored, 'entitlement_not_targeted');
  assert.equal(calls.length, 0);
});

test('webhook: INITIAL_PURCHASE active event → DO upsert 呼出 + isActive=true', async () => {
  const { env, calls } = makeEnv({
    doImpl: async (_path, _body) => ({ status: 200, body: { ok: true } }),
  });
  _resetEntitlementCacheForTest();
  setCachedEntitlement('apple:abc', { isActive: true, expiresAt: 9999999999999 });

  const res = await handleRevenueCatWebhook(
    makeRequest({
      body: {
        event: {
          type: 'INITIAL_PURCHASE',
          id: 'evt-1',
          app_user_id: 'apple:abc',
          entitlement_ids: ['cosmic_pro'],
          environment: 'PRODUCTION',
          store: 'APP_STORE',
          product_id: 'com.solodevlab.solara.cosmicpro.monthly',
          period_type: 'NORMAL',
          expiration_at_ms: 1700000000000,
        },
      },
    }),
    env,
  );
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.ok, true);
  assert.equal(body.isActive, true);
  assert.equal(body.appUserId, 'apple:abc');
  assert.equal(calls.length, 1);
  assert.equal(calls[0].path, '/entitlement-upsert');
  assert.equal(calls[0].body.entitlementId, 'cosmic_pro');
  assert.equal(calls[0].body.isActive, true);
  assert.equal(calls[0].body.expiresAt, 1700000000000);
  assert.equal(calls[0].body.environment, 'production');
  // cache が invalidate された (前 set 後に webhook で消えている)
  assert.equal(getCachedEntitlement('apple:abc'), undefined);
});

test('webhook: BILLING_ISSUE event → grace_period_expiration_at_ms を upsert に渡す + isActive=true', async () => {
  // Apple/Google 公式: grace 期間中はサービス維持。grace_expires_at が DO に書かれ、
  // entitlement_get が MAX(expires_at, grace_expires_at) で判定することで grace 中 Pro 維持。
  const { env, calls } = makeEnv({
    doImpl: async () => ({ status: 200, body: { ok: true } }),
  });
  const expirationMs = 1700000000000;       // 元の sub 期限
  const graceMs = expirationMs + 16 * 86_400_000; // +16 日 (Apple billing grace)
  const eventTsMs = expirationMs - 1000;
  const res = await handleRevenueCatWebhook(
    makeRequest({
      body: {
        event: {
          type: 'BILLING_ISSUE',
          id: 'evt-bi-1',
          app_user_id: 'apple:bill',
          entitlement_ids: ['cosmic_pro'],
          environment: 'PRODUCTION',
          expiration_at_ms: expirationMs,
          grace_period_expiration_at_ms: graceMs,
          event_timestamp_ms: eventTsMs,
        },
      },
    }),
    env,
  );
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.isActive, true, 'GRACE event は active 維持');
  assert.equal(calls.length, 1);
  assert.equal(calls[0].path, '/entitlement-upsert');
  assert.equal(calls[0].body.graceExpiresAt, graceMs, 'grace_expires_at が DO に渡される');
  assert.equal(calls[0].body.eventTimestampMs, eventTsMs, 'event_timestamp_ms が DO に渡される');
});

test('webhook: event_timestamp_ms が無い event でも upsert は通る (legacy)', async () => {
  const { env, calls } = makeEnv({
    doImpl: async () => ({ status: 200, body: { ok: true } }),
  });
  const res = await handleRevenueCatWebhook(
    makeRequest({
      body: {
        event: {
          type: 'INITIAL_PURCHASE',
          id: 'evt-legacy-1',
          app_user_id: 'google:legacy',
          entitlement_ids: ['cosmic_pro'],
          environment: 'PRODUCTION',
          expiration_at_ms: 1800000000000,
          // event_timestamp_ms 無し、grace_period_expiration_at_ms 無し
        },
      },
    }),
    env,
  );
  assert.equal(res.status, 200);
  assert.equal(calls.length, 1);
  // 無いフィールドは null として渡る
  assert.equal(calls[0].body.graceExpiresAt, null);
  assert.equal(calls[0].body.eventTimestampMs, null);
});

test('webhook: EXPIRATION event → isActive=false', async () => {
  const { env, calls } = makeEnv({
    doImpl: async () => ({ status: 200, body: { ok: true } }),
  });
  const res = await handleRevenueCatWebhook(
    makeRequest({
      body: {
        event: {
          type: 'EXPIRATION',
          id: 'evt-exp-1',
          app_user_id: 'google:xyz',
          entitlement_id: 'cosmic_pro',
          environment: 'PRODUCTION',
        },
      },
    }),
    env,
  );
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.isActive, false);
  assert.equal(calls[0].body.isActive, false);
});

test('webhook: CANCELLATION event → isActive=true (期限まで Pro 維持)', async () => {
  const { env, calls } = makeEnv({
    doImpl: async () => ({ status: 200, body: { ok: true } }),
  });
  const res = await handleRevenueCatWebhook(
    makeRequest({
      body: {
        event: {
          type: 'CANCELLATION',
          id: 'evt-cancel-1',
          app_user_id: 'apple:abc',
          entitlement_ids: ['cosmic_pro'],
          environment: 'PRODUCTION',
          expiration_at_ms: 1700000000000,
        },
      },
    }),
    env,
  );
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.isActive, true);
  assert.equal(body.expiresAt, 1700000000000);
});

test('webhook: SUBSCRIPTION_EXTENDED event → isActive=true (CS 経由の期限延長で Pro 誤失効を防ぐ)', async () => {
  // RC が dashboard から手動延長したときに発火。ACTIVE_EVENT_TYPES に含めないと
  // 未知 event 扱い → 旧実装では isActive=false で Pro 誤失効、新実装では ignored 200。
  // 正しい挙動は isActive=true で期限延長を反映すること。
  const { env, calls } = makeEnv({
    doImpl: async () => ({ status: 200, body: { ok: true } }),
  });
  const res = await handleRevenueCatWebhook(
    makeRequest({
      body: {
        event: {
          type: 'SUBSCRIPTION_EXTENDED',
          id: 'evt-ext-1',
          app_user_id: 'google:ext1',
          entitlement_ids: ['cosmic_pro'],
          environment: 'PRODUCTION',
          expiration_at_ms: 1800000000000,
        },
      },
    }),
    env,
  );
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.isActive, true);
  assert.equal(calls.length, 1);
  assert.equal(calls[0].path, '/entitlement-upsert');
  assert.equal(calls[0].body.expiresAt, 1800000000000);
});

test('webhook: TRANSFER 旧 owner (transferred_from) → isActive=false (entitlement を失う)', async () => {
  // RC 公式: 1 transfer = 旧/新 2 通発火。旧 owner 側 event は transferred_from に
  // 自分の appUserId が含まれる。これを isActive=false で書込み、二重 Pro を防ぐ。
  const { env, calls } = makeEnv({
    doImpl: async () => ({ status: 200, body: { ok: true } }),
  });
  const res = await handleRevenueCatWebhook(
    makeRequest({
      body: {
        event: {
          type: 'TRANSFER',
          id: 'evt-xfer-from-1',
          app_user_id: 'google:oldOwner',
          entitlement_ids: ['cosmic_pro'],
          environment: 'PRODUCTION',
          transferred_from: ['google:oldOwner'],
          transferred_to: ['apple:newOwner'],
        },
      },
    }),
    env,
  );
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.isActive, false, '旧 owner は entitlement を失う');
  assert.equal(calls.length, 1);
  assert.equal(calls[0].body.isActive, false);
});

test('webhook: TRANSFER 新 owner (transferred_to) → isActive=true (entitlement 獲得)', async () => {
  const { env, calls } = makeEnv({
    doImpl: async () => ({ status: 200, body: { ok: true } }),
  });
  const res = await handleRevenueCatWebhook(
    makeRequest({
      body: {
        event: {
          type: 'TRANSFER',
          id: 'evt-xfer-to-1',
          app_user_id: 'apple:newOwner',
          entitlement_ids: ['cosmic_pro'],
          environment: 'PRODUCTION',
          transferred_from: ['google:oldOwner'],
          transferred_to: ['apple:newOwner'],
        },
      },
    }),
    env,
  );
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.isActive, true, '新 owner は entitlement を獲得');
  assert.equal(calls.length, 1);
  assert.equal(calls[0].body.isActive, true);
});

test('webhook: TRANSFER で transferred_from/to 両方欠落 → 旧実装互換で active 維持', async () => {
  const { env, calls } = makeEnv({
    doImpl: async () => ({ status: 200, body: { ok: true } }),
  });
  const res = await handleRevenueCatWebhook(
    makeRequest({
      body: {
        event: {
          type: 'TRANSFER',
          id: 'evt-xfer-unknown-1',
          app_user_id: 'google:someone',
          entitlement_ids: ['cosmic_pro'],
          environment: 'PRODUCTION',
        },
      },
    }),
    env,
  );
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.isActive, true);
});

test('webhook: 未知 event 種別 → 200 ignored (DO は touch しない)', async () => {
  // 旧実装は未知 event を isActive=false で upsert → 「未知 event で Pro 誤失効」事故あり。
  // 新実装は副作用なしで 200 ignored 返却。RC が将来追加する event でも安全側に倒す。
  const { env, calls } = makeEnv({
    doImpl: async () => ({ status: 200, body: { ok: true } }),
  });
  const res = await handleRevenueCatWebhook(
    makeRequest({
      body: {
        event: {
          type: 'SOME_FUTURE_EVENT_TYPE',
          id: 'evt-future-1',
          app_user_id: 'google:future',
          entitlement_ids: ['cosmic_pro'],
          environment: 'PRODUCTION',
        },
      },
    }),
    env,
  );
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.ignored, 'unknown_event_type');
  assert.equal(body.eventType, 'SOME_FUTURE_EVENT_TYPE');
  assert.equal(calls.length, 0, '未知 event で DO upsert は呼ばれない');
});

test('webhook: alreadyProcessed=true を伝搬', async () => {
  const { env } = makeEnv({
    doImpl: async () => ({ status: 200, body: { ok: true, alreadyProcessed: true } }),
  });
  const res = await handleRevenueCatWebhook(
    makeRequest({
      body: {
        event: {
          type: 'INITIAL_PURCHASE',
          id: 'evt-dup',
          app_user_id: 'apple:abc',
          entitlement_ids: ['cosmic_pro'],
          environment: 'PRODUCTION',
        },
      },
    }),
    env,
  );
  const body = await res.json();
  assert.equal(body.alreadyProcessed, true);
});

test('webhook: DO エラー → 500', async () => {
  const { env } = makeEnv({
    doImpl: async () => ({ status: 500, body: { error: 'sql_failed' } }),
  });
  const res = await handleRevenueCatWebhook(
    makeRequest({
      body: {
        event: {
          type: 'INITIAL_PURCHASE',
          id: 'evt-err',
          app_user_id: 'apple:abc',
          entitlement_ids: ['cosmic_pro'],
          environment: 'PRODUCTION',
        },
      },
    }),
    env,
  );
  assert.equal(res.status, 500);
});

test('webhook: app_user_id 欠落 → 400', async () => {
  const { env } = makeEnv();
  const res = await handleRevenueCatWebhook(
    makeRequest({
      body: {
        event: {
          type: 'INITIAL_PURCHASE',
          id: 'evt-missing-uid',
          entitlement_ids: ['cosmic_pro'],
          environment: 'PRODUCTION',
        },
      },
    }),
    env,
  );
  assert.equal(res.status, 400);
});

// ── entitlement_cache TTL ──────────────────────────────────

test('cache: set → get で値が返る', () => {
  _resetEntitlementCacheForTest();
  setCachedEntitlement('apple:c1', { isActive: true, expiresAt: 9999999999999 });
  const v = getCachedEntitlement('apple:c1');
  assert.equal(v.isActive, true);
});

test('cache: 未保存は undefined', () => {
  _resetEntitlementCacheForTest();
  assert.equal(getCachedEntitlement('apple:none'), undefined);
});

test('cache: null memoize (Pro 無し) を区別', () => {
  _resetEntitlementCacheForTest();
  setCachedEntitlement('apple:nopro', null);
  assert.equal(getCachedEntitlement('apple:nopro'), null);
});

test('cache: clear で消える', () => {
  _resetEntitlementCacheForTest();
  setCachedEntitlement('apple:c2', { isActive: true });
  clearMemoryEntitlementCache('apple:c2');
  assert.equal(getCachedEntitlement('apple:c2'), undefined);
});

test('cache: 非 string key は no-op', () => {
  _resetEntitlementCacheForTest();
  setCachedEntitlement('', { isActive: true });
  assert.equal(getCachedEntitlement(''), undefined);
  setCachedEntitlement(null, { isActive: true });
  assert.equal(getCachedEntitlement(null), undefined);
});
