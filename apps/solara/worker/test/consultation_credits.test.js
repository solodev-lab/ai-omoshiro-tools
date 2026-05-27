/**
 * Stella 相談 Free 試食クレジットのテスト (設計 project_solara_stella_free_credits.md)。
 *
 * 対象 (src/index.js _internal):
 *   - isoWeekBucket            : ISO 週バケット (月曜リセット、年跨ぎ)
 *   - consultationFreeModes    : CONSULTATION_FREE_MODES の解釈
 *   - consultationFreeWeekly   : CONSULTATION_FREE_WEEKLY の解釈
 *   - consultationDeviceKey    : 端末 ID 導出 (iOS keyId / appUserId / null)
 *   - gateConsultation         : Pro 無制限 / Free 週N / モード/refresh ゲート / 残量
 *
 * AttestationState 本体は Cloudflare runtime 依存のため import しない。
 * env.ATTESTATION_DO.fetch を mock して Worker 側ロジックを検証する
 * (integrity_endpoints.test.js と同方針)。
 *
 * 実行: cd apps/solara/worker && node --test test/consultation_credits.test.js
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { _internal } from '../src/index.js';
import { _internal as rcInternal } from '../src/webhooks/revenuecat.js';
import { _resetEntitlementCacheForTest } from '../src/auth/entitlement_cache.js';

const {
  isoWeekBucket,
  consultationFreeModes,
  consultationFreeWeekly,
  consultationProWeekly,
  consultationDeviceKey,
  consultationCreditStatus,
  consumeReadingCreditGate,
  gateConsultation,
  consultationConsumed,
} = _internal;
const { consultationCreditAmountForProduct } = rcInternal;

// ── env / request mock ──────────────────────────────────────

/**
 * env.ATTESTATION_DO.fetch を mock。
 * @param {(path, body) => {status, body}} handler
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
      ATTESTATION_DO: { idFromName: () => 'global-id', get: () => stub },
      ...extra,
    },
    calls,
  };
}

/** X-AppAttest-KeyId だけ持つ簡易 request mock。 */
function makeRequest(headers = {}) {
  return { headers: { get: (h) => (h in headers ? headers[h] : null) } };
}

/**
 * DO handler 合成。
 *   isPro      : entitlement-get で Pro 判定を返す
 *   used       : 無料週次 (consultation_credits.used)
 *   purchased  : 購入残高 (consultation_purchased.balance)
 *   proUsed    : Pro 週次 (consultation_pro_credits.used、2026-05-27 追加)
 */
function doHandler({ isPro = false, used = 0, purchased = 0, proUsed = 0 } = {}) {
  return (path) => {
    if (path === '/entitlement-get') {
      if (isPro) {
        return { status: 200, body: { isActive: true, expiresAt: Date.now() + 86_400_000 } };
      }
      return { status: 404, body: { error: 'entitlement_not_found' } };
    }
    if (path === '/consultation-credit-get') {
      return { status: 200, body: { used } };
    }
    if (path === '/consultation-credit-bump') {
      return { status: 200, body: { used: used + 1 } };
    }
    if (path === '/consultation-pro-credit-get') {
      return { status: 200, body: { used: proUsed } };
    }
    if (path === '/consultation-pro-credit-bump') {
      return { status: 200, body: { used: proUsed + 1 } };
    }
    if (path === '/consultation-purchased-get') {
      return { status: 200, body: { balance: purchased } };
    }
    if (path === '/consultation-purchased-spend') {
      return { status: 200, body: { balance: Math.max(0, purchased - 1), spent: purchased > 0 } };
    }
    return { status: 404, body: {} };
  };
}

// ── isoWeekBucket ───────────────────────────────────────────

test('isoWeekBucket: 形式 YYYY-Www + 同週は同値・月曜で繰り上がる', () => {
  assert.match(isoWeekBucket(new Date('2026-05-23T12:00:00Z')), /^\d{4}-W\d{2}$/);
  // 2026-05-18(月)〜05-24(日) は同一週、05-25(月) で次週
  const w21mon = isoWeekBucket(new Date('2026-05-18T00:00:00Z'));
  const w21sat = isoWeekBucket(new Date('2026-05-23T23:59:59Z'));
  const w21sun = isoWeekBucket(new Date('2026-05-24T12:00:00Z'));
  const w22mon = isoWeekBucket(new Date('2026-05-25T00:00:00Z'));
  assert.equal(w21mon, '2026-W21');
  assert.equal(w21sat, '2026-W21');
  assert.equal(w21sun, '2026-W21');
  assert.equal(w22mon, '2026-W22');
});

test('isoWeekBucket: 年跨ぎ (12/29 月曜 = 翌年 W01、12/31 = W53)', () => {
  assert.equal(isoWeekBucket(new Date('2025-12-29T12:00:00Z')), '2026-W01');
  assert.equal(isoWeekBucket(new Date('2026-12-31T12:00:00Z')), '2026-W53');
  assert.equal(isoWeekBucket(new Date('2027-01-01T12:00:00Z')), '2026-W53');
});

// ── consultationFreeModes / consultationFreeWeekly ─────────

test('consultationFreeModes: default は 3 モード全部', () => {
  const s = consultationFreeModes({});
  assert.ok(s.has('migration') && s.has('travel') && s.has('daily'));
  assert.equal(s.size, 3);
});

test('consultationFreeModes: env で "daily" だけに絞れる', () => {
  const s = consultationFreeModes({ CONSULTATION_FREE_MODES: 'daily' });
  assert.ok(s.has('daily'));
  assert.ok(!s.has('migration') && !s.has('travel'));
});

test('consultationFreeModes: 空白/余分なカンマを除去', () => {
  const s = consultationFreeModes({ CONSULTATION_FREE_MODES: ' daily , travel , ' });
  assert.deepEqual([...s].sort(), ['daily', 'travel']);
});

test('consultationFreeWeekly: default 3 / 上書き / 不正値は 3', () => {
  assert.equal(consultationFreeWeekly({}), 3);
  assert.equal(consultationFreeWeekly({ CONSULTATION_FREE_WEEKLY: '5' }), 5);
  assert.equal(consultationFreeWeekly({ CONSULTATION_FREE_WEEKLY: '0' }), 0);
  assert.equal(consultationFreeWeekly({ CONSULTATION_FREE_WEEKLY: 'abc' }), 3);
});

test('consultationProWeekly: default 100 / 上書き / 不正値は 100', () => {
  assert.equal(consultationProWeekly({}), 100);
  assert.equal(consultationProWeekly({ CONSULTATION_PRO_WEEKLY: '50' }), 50);
  assert.equal(consultationProWeekly({ CONSULTATION_PRO_WEEKLY: '0' }), 0);
  assert.equal(consultationProWeekly({ CONSULTATION_PRO_WEEKLY: 'xyz' }), 100);
});

// ── consultationDeviceKey ───────────────────────────────────

test('consultationDeviceKey: iOS keyId 優先 → ios:{keyId}', () => {
  const req = makeRequest({ 'X-AppAttest-KeyId': 'KEY123' });
  assert.equal(consultationDeviceKey(req, 'google:u1'), 'ios:KEY123');
});

test('consultationDeviceKey: keyId 無し + appUserId → usr:{appUserId}', () => {
  const req = makeRequest({});
  assert.equal(consultationDeviceKey(req, 'google:u1'), 'usr:google:u1');
});

test('consultationDeviceKey: どちらも無し → null', () => {
  const req = makeRequest({});
  assert.equal(consultationDeviceKey(req, null), null);
});

// ── gateConsultation ────────────────────────────────────────

test('gate: Pro + 週次キャップ未到達 → source=pro_weekly (Free 残量 DO は呼ばない)', async () => {
  _resetEntitlementCacheForTest();
  const { env, calls } = makeEnv(doHandler({ isPro: true, proUsed: 50 })); // 50/100
  const req = makeRequest({ 'X-AppAttest-KeyId': 'K' });
  const body = { __appUserId: 'google:pro1', mode: 'daily' };
  const r = await gateConsultation(req, env, body, null);
  assert.equal(r.isPro, true);
  assert.equal(r.allow, true);
  assert.equal(r.source, 'pro_weekly');
  assert.equal(r.deviceKey, 'ios:K');
  // Pro 週次 DO は呼ぶが、Free credit-get は呼ばない (別表)
  assert.ok(calls.some((c) => c.path === '/consultation-pro-credit-get'));
  assert.ok(!calls.some((c) => c.path === '/consultation-credit-get'));
});

test('gate: Pro 99→100 ぎりぎり通る (proUsed=99, limit 100)', async () => {
  _resetEntitlementCacheForTest();
  const { env } = makeEnv(doHandler({ isPro: true, proUsed: 99 }));
  const req = makeRequest({ 'X-AppAttest-KeyId': 'K' });
  const r = await gateConsultation(req, env, { __appUserId: 'google:pro', mode: 'daily' }, null);
  assert.equal(r.source, 'pro_weekly');
});

test('gate: Pro 100 到達 + 購入残あり → source=purchased (フォールバック)', async () => {
  _resetEntitlementCacheForTest();
  const { env } = makeEnv(doHandler({ isPro: true, proUsed: 100, purchased: 5 }));
  const req = makeRequest({ 'X-AppAttest-KeyId': 'K' });
  const r = await gateConsultation(req, env, { __appUserId: 'google:pro', mode: 'daily' }, null);
  assert.equal(r.allow, true);
  assert.equal(r.isPro, true);
  assert.equal(r.source, 'purchased');
  assert.equal(r.appUserId, 'google:pro');
});

test('gate: Pro 100 到達 + 購入 0 → 402 consultation_pro_weekly_exhausted', async () => {
  _resetEntitlementCacheForTest();
  const { env } = makeEnv(doHandler({ isPro: true, proUsed: 100, purchased: 0 }));
  const req = makeRequest({ 'X-AppAttest-KeyId': 'K' });
  const r = await gateConsultation(req, env, { __appUserId: 'google:pro', mode: 'daily' }, null);
  assert.ok(r.block);
  assert.equal(r.block.status, 402);
  const j = await r.block.json();
  assert.equal(j.error, 'consultation_pro_weekly_exhausted');
  assert.equal(j.proRemaining, 0);
  assert.equal(j.proLimit, 100);
});

test('gate: Pro + appUserId 経由の deviceKey (keyId 無し Android) → 週次キャップ適用', async () => {
  // Android Play Integrity 経路は X-AppAttest-KeyId 無し。consultationDeviceKey は
  // appUserId にフォールバックして 'usr:{appUserId}' を返す = Pro 週次キャップは適用される。
  // (iOS と Android で Pro 週次の挙動が変わらないことを保証)
  _resetEntitlementCacheForTest();
  const { env } = makeEnv(doHandler({ isPro: true, proUsed: 50 }));
  const req = makeRequest({}); // keyId 無し
  const body = { __appUserId: 'google:proA', mode: 'daily' };
  const r = await gateConsultation(req, env, body, null);
  assert.equal(r.allow, true);
  assert.equal(r.isPro, true);
  assert.equal(r.source, 'pro_weekly');
  assert.equal(r.deviceKey, 'usr:google:proA'); // appUserId フォールバック
});

test('gate: Pro CONSULTATION_PRO_WEEKLY=50 で env 上書き効く', async () => {
  _resetEntitlementCacheForTest();
  const { env } = makeEnv(
    doHandler({ isPro: true, proUsed: 50 }),
    { CONSULTATION_PRO_WEEKLY: '50' },
  );
  const req = makeRequest({ 'X-AppAttest-KeyId': 'K' });
  // 50/50 = 残 0 → 402 (購入残 0)
  const r = await gateConsultation(req, env, { __appUserId: 'google:pro', mode: 'daily' }, null);
  assert.ok(r.block);
  const j = await r.block.json();
  assert.equal(j.error, 'consultation_pro_weekly_exhausted');
  assert.equal(j.proLimit, 50);
});

test('gate: Free + 許可モード + 無料残量あり → source=free', async () => {
  _resetEntitlementCacheForTest();
  const { env } = makeEnv(doHandler({ isPro: false, used: 1 })); // used 1 / limit 3
  const req = makeRequest({ 'X-AppAttest-KeyId': 'K1' });
  const body = { __appUserId: 'google:free1', mode: 'daily' };
  const r = await gateConsultation(req, env, body, null);
  assert.equal(r.allow, true);
  assert.equal(r.isPro, false);
  assert.equal(r.source, 'free');
  assert.equal(r.deviceKey, 'ios:K1');
});

test('gate: Free + 出し直し (excluded) も通過 (出し直しもクレジット消費)', async () => {
  _resetEntitlementCacheForTest();
  const { env } = makeEnv(doHandler({ isPro: false, used: 0 }));
  const req = makeRequest({ 'X-AppAttest-KeyId': 'K' });
  const body = { __appUserId: 'google:free3', mode: 'daily', excluded: ['東京'] };
  const r = await gateConsultation(req, env, body, null);
  assert.ok(!r.block); // 出し直しはブロックしない
  assert.equal(r.source, 'free');
});

test('gate: Free + モード対象外 → 402 consultation_pro_only_mode', async () => {
  _resetEntitlementCacheForTest();
  const { env } = makeEnv(doHandler({ isPro: false }), { CONSULTATION_FREE_MODES: 'daily' });
  const req = makeRequest({ 'X-AppAttest-KeyId': 'K' });
  const body = { __appUserId: 'google:free2', mode: 'migration' };
  const r = await gateConsultation(req, env, body, null);
  assert.ok(r.block);
  assert.equal(r.block.status, 402);
  const j = await r.block.json();
  assert.equal(j.error, 'consultation_pro_only_mode');
});

test('gate: Free + 無料0 + 購入残高あり → source=purchased', async () => {
  _resetEntitlementCacheForTest();
  const { env } = makeEnv(doHandler({ isPro: false, used: 3, purchased: 5 }));
  const req = makeRequest({ 'X-AppAttest-KeyId': 'K' });
  const body = { __appUserId: 'google:free5', mode: 'daily' };
  const r = await gateConsultation(req, env, body, null);
  assert.equal(r.allow, true);
  assert.equal(r.source, 'purchased');
  assert.equal(r.appUserId, 'google:free5');
});

test('gate: Free + 無料0 + 購入0 → 402 consultation_credit_exhausted', async () => {
  _resetEntitlementCacheForTest();
  const { env } = makeEnv(doHandler({ isPro: false, used: 3, purchased: 0 }));
  const req = makeRequest({ 'X-AppAttest-KeyId': 'K' });
  const body = { __appUserId: 'google:free4', mode: 'daily' };
  const r = await gateConsultation(req, env, body, null);
  assert.ok(r.block);
  assert.equal(r.block.status, 402);
  const j = await r.block.json();
  assert.equal(j.error, 'consultation_credit_exhausted');
  assert.equal(j.remaining, 0);
  assert.equal(j.limit, 3);
});

test('gate: Free + 無料0 + 購入あり だが匿名(appUserId無し) → exhausted', async () => {
  _resetEntitlementCacheForTest();
  // keyId はあるが appUserId 無し = 購入残高を引けない (サインイン必須)
  const { env } = makeEnv(doHandler({ isPro: false, used: 3, purchased: 5 }));
  const req = makeRequest({ 'X-AppAttest-KeyId': 'K' });
  const body = { mode: 'daily' }; // __appUserId 無し
  const r = await gateConsultation(req, env, body, null);
  assert.ok(r.block);
  const j = await r.block.json();
  assert.equal(j.error, 'consultation_credit_exhausted');
});

test('gate: 非Pro + deviceKey 無し (bypass/dev) → source=null で通過', async () => {
  _resetEntitlementCacheForTest();
  const { env, calls } = makeEnv(doHandler({ isPro: false }));
  const req = makeRequest({}); // keyId 無し
  const body = { mode: 'daily' }; // __appUserId も無し
  const r = await gateConsultation(req, env, body, null);
  assert.equal(r.allow, true);
  assert.equal(r.isPro, false);
  assert.equal(r.source, null);
  assert.ok(!calls.some((c) => c.path === '/consultation-credit-get'));
});

// ── consumeReadingCreditGate (共通ゲート、タロットカテゴリ等で共用) ──────

test('共通ゲート (Tarot 等): Pro は週次キャップ無し (= 既存無制限挙動を維持)', async () => {
  // consumeReadingCreditGate は Tarot カテゴリと共用 = Pro 週次キャップは適用しない。
  // Pro 週次キャップは gateConsultation (Stella 専用) でのみ発火する。
  // → Tarot は Pro 無制限のまま (オーナー方針「タロットそのまま」)。
  _resetEntitlementCacheForTest();
  const { env, calls } = makeEnv(doHandler({ isPro: true, proUsed: 999 }));
  const req = makeRequest({ 'X-AppAttest-KeyId': 'K' });
  const r = await consumeReadingCreditGate(req, env, { __appUserId: 'google:pro1' }, null);
  assert.equal(r.isPro, true);
  assert.ok(!calls.some((c) => c.path === '/consultation-credit-get'));
  assert.ok(!calls.some((c) => c.path === '/consultation-pro-credit-get'));
});

test('共通ゲート: mode 無し (タロット) でも無料残あれば source=free', async () => {
  _resetEntitlementCacheForTest();
  const { env } = makeEnv(doHandler({ isPro: false, used: 0 }));
  const req = makeRequest({ 'X-AppAttest-KeyId': 'K1' });
  // body に mode は無い (タロットは mode 概念なし) → モード制限で弾かれない
  const r = await consumeReadingCreditGate(req, env, { __appUserId: 'google:f1' }, null);
  assert.equal(r.allow, true);
  assert.equal(r.source, 'free');
});

test('共通ゲート: 無料0 + 購入あり → source=purchased / 0+0 → 402', async () => {
  _resetEntitlementCacheForTest();
  const env1 = makeEnv(doHandler({ isPro: false, used: 3, purchased: 4 })).env;
  const req = makeRequest({ 'X-AppAttest-KeyId': 'K' });
  const r1 = await consumeReadingCreditGate(req, env1, { __appUserId: 'google:f2' }, null);
  assert.equal(r1.source, 'purchased');

  _resetEntitlementCacheForTest();
  const env2 = makeEnv(doHandler({ isPro: false, used: 3, purchased: 0 })).env;
  const r2 = await consumeReadingCreditGate(req, env2, { __appUserId: 'google:f3' }, null);
  assert.ok(r2.block);
  assert.equal(r2.block.status, 402);
});

// ── consultationCreditStatus ────────────────────────────────

test('status: Pro は 週次残 + 上限 + 週バケット + 購入残 (Free 項目は null)', async () => {
  _resetEntitlementCacheForTest();
  const { env } = makeEnv(doHandler({ isPro: true, proUsed: 13, purchased: 4 }));
  const req = makeRequest({ 'X-AppAttest-KeyId': 'K' });
  const s = await consultationCreditStatus(env, req, { __appUserId: 'google:pro1' });
  assert.equal(s.pro, true);
  assert.equal(s.proRemaining, 87); // 100 - 13
  assert.equal(s.proLimit, 100);
  assert.match(s.weekBucket, /^\d{4}-W\d{2}$/);
  assert.equal(s.purchasedBalance, 4); // Pro でも購入残はある (Pro 100 後のフォールバック用)
  assert.equal(s.freeRemaining, null);
  assert.equal(s.freeLimit, null);
});

test('status: Free は 無料残 + 上限 + 購入残高 (Pro 項目は null)', async () => {
  _resetEntitlementCacheForTest();
  const { env } = makeEnv(doHandler({ isPro: false, used: 1, purchased: 7 }));
  const req = makeRequest({ 'X-AppAttest-KeyId': 'K' });
  const s = await consultationCreditStatus(env, req, { __appUserId: 'google:free1' });
  assert.equal(s.pro, false);
  assert.equal(s.freeRemaining, 2); // 3 - 1
  assert.equal(s.freeLimit, 3);
  assert.equal(s.purchasedBalance, 7);
  assert.equal(s.proRemaining, null);
  assert.equal(s.proLimit, null);
});

// ── consultationCreditAmountForProduct (revenuecat.js) ──────

test('creditProduct: env から商品ID→付与数を引く', () => {
  const env = {
    CONSULTATION_CREDIT_PRODUCTS:
      'com.solodevlab.solara.credits.small:3, com.solodevlab.solara.credits.large:10',
  };
  assert.equal(consultationCreditAmountForProduct(env, 'com.solodevlab.solara.credits.small'), 3);
  assert.equal(consultationCreditAmountForProduct(env, 'com.solodevlab.solara.credits.large'), 10);
  assert.equal(consultationCreditAmountForProduct(env, 'com.solodevlab.solara.unknown'), 0);
  assert.equal(consultationCreditAmountForProduct({}, 'anything'), 0);
});

// ── consultationConsumed (V2: 1クレジット=1候補の課金判定) ──────

test('consultationConsumed: 本物の候補が出た時だけ課金 (exhausted/fallback/候補なしは課金しない)', () => {
  // 本物の候補 → 課金する
  assert.equal(consultationConsumed({ candidate: { name: '京都' } }), true);
  // 候補出し尽くし (excluded) → 課金しない
  assert.equal(consultationConsumed({ exhausted: true }), false);
  // 静的フォールバック (Stella 不通) → 課金しない (旧 consultation と同方針)
  assert.equal(consultationConsumed({ candidate: { name: '京都' }, fallback: true }), false);
  // 候補が無い (null) → 課金しない
  assert.equal(consultationConsumed({ candidate: null }), false);
  assert.equal(consultationConsumed(null), false);
});
