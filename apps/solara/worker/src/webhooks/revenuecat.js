/**
 * RevenueCat Webhook 受信 (`POST /webhooks/revenuecat`)
 *
 * 設計:
 *   - apps/solara/docs/revenuecat_webhook.md (本実装と同時新規)
 *   - project_solara_launch_checklist.md Phase 1 「Webhook 受信」
 *   - project_solara_security_principles.md 原則 1「クライアント単独 isPro 禁止」
 *
 * 認証:
 *   - `Authorization: Bearer <REVENUECAT_WEBHOOK_AUTH>` を constant-time 比較
 *   - 値は RevenueCat ダッシュボード Integrations → Webhooks で Solara が設定する任意文字列
 *
 * 状態管理:
 *   - Pro エンタイトルメント状態は `AttestationState` Durable Object に統合
 *     (1 instance 集約、`webhook_events` 表で event_id 冪等性保証)
 *
 * イベント体系 (RevenueCat 公式 + サブスクライフサイクル):
 *   active 化:
 *     INITIAL_PURCHASE / RENEWAL / PRODUCT_CHANGE / UNCANCELLATION /
 *     NON_RENEWING_PURCHASE / TEMPORARY_ENTITLEMENT_GRANT
 *   active 維持 (キャンセル予約 / 課金問題は期限内有効):
 *     CANCELLATION (auto_renew=false だが expiration まで有効) /
 *     BILLING_ISSUE (grace period 内)
 *   inactive 化:
 *     EXPIRATION / REFUND
 *   旧 user 失効 + 新 user に付与:
 *     TRANSFER
 *   何もしない:
 *     SUBSCRIBER_ALIAS (anonymous→authenticated alias 通知、entitlement は別 event で来る)
 *     TEST (RC ダッシュボードのテスト送信)
 *
 * 戻り値:
 *   200 {ok: true, ...}        正常処理
 *   200 {ok: true, ignored: …} 未知 event / Solara entitlement 対象外
 *   401 {error: 'unauthorized'} Bearer 認証失敗
 *   400 {error: 'invalid_…'}   Body 形式異常
 *   500 ...                    DO エラー (RC は失敗時に再送する)
 *
 * 🔴 Cache invalidation:
 *   middleware の in-memory cache は Worker instance ごと TTL 60s で自然失効する。
 *   Webhook 受信 instance 内の cache は INSERT/UPDATE 直後に同 instance 内で
 *   `clearMemoryEntitlementCache(appUserId)` を呼んで即時無効化。
 *   他 instance は最悪 60s で次回 read 時に DO から最新値を取得する (eventual consistency)。
 */

import { clearMemoryEntitlementCache } from '../auth/entitlement_cache.js';

/** Solara が監視する RevenueCat エンタイトルメント ID (`purchases_service.dart` と一致) */
const SOLARA_ENTITLEMENT_ID = 'cosmic_pro';

/** active 化 = is_active=true で upsert */
const ACTIVE_EVENT_TYPES = new Set([
  'INITIAL_PURCHASE',
  'RENEWAL',
  'PRODUCT_CHANGE',
  'UNCANCELLATION',
  'NON_RENEWING_PURCHASE',
  'TEMPORARY_ENTITLEMENT_GRANT',
  // 2024-2026 で RC が追加した期限延長イベント (CS が dashboard から手動延長 / 補填等)。
  // ACTIVE 扱いしないと「期限延長したのに Pro が誤失効」する事故が起きる。
  'SUBSCRIPTION_EXTENDED',
]);

/** 期限内は active 維持 (auto_renew=false でも期限まで Pro) */
const GRACE_EVENT_TYPES = new Set([
  'CANCELLATION',
  'BILLING_ISSUE',
  'SUBSCRIPTION_PAUSED',
]);

/** inactive 化 (Pro 失効) */
const INACTIVE_EVENT_TYPES = new Set([
  'EXPIRATION',
  'REFUND',
]);

/** 無視 (副作用なし、200 返す) */
const IGNORE_EVENT_TYPES = new Set([
  'SUBSCRIBER_ALIAS', // alias 通知単独では entitlement は更新しない (別 event が来る)
  'TEST',
  'INVOICE_ISSUANCE', // Web purchase 通知、Solara 対象外
  'VIRTUAL_CURRENCY_TRANSACTION',
]);

/**
 * constant-time string compare (タイミング攻撃耐性、長さ違いは即 false)。
 *
 * btoa(secret) ≠ btoa(claim) のとき長さが同じでも各バイトを最後まで XOR で比較。
 */
function timingSafeEqualString(a, b) {
  if (typeof a !== 'string' || typeof b !== 'string') return false;
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}

function jsonResponse(status, data) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

async function callDo(env, path, body) {
  const stub = env.ATTESTATION_DO.get(env.ATTESTATION_DO.idFromName('global'));
  const res = await stub.fetch(`https://do${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const json = await res.json().catch(() => ({}));
  return { status: res.status, body: json };
}

/**
 * CONSULTATION_CREDIT_PRODUCTS ("productId:amount,productId:amount") から
 * 該当 product_id の付与クレジット数を返す。該当なし or 未設定は 0。
 * 消費型 Stella クレジット商品の判定に使う (Stella 相談 Free 試食クレジット設計 B 案)。
 */
function consultationCreditAmountForProduct(env, productId) {
  if (typeof productId !== 'string' || !productId) return 0;
  const raw = env.CONSULTATION_CREDIT_PRODUCTS || '';
  for (const pair of raw.split(',')) {
    const idx = pair.lastIndexOf(':');
    if (idx <= 0) continue;
    const id = pair.slice(0, idx).trim();
    const amt = parseInt(pair.slice(idx + 1).trim(), 10);
    if (id === productId && Number.isInteger(amt) && amt > 0) return amt;
  }
  return 0;
}

/**
 * 1 RevenueCat event を 1 entitlement upsert に変換。
 * 戻り値は最終的にクライアント (RC dashboard) に返す JSON。
 */
async function processEvent(env, ev) {
  const eventType = ev.type;
  const eventId = ev.id;
  if (typeof eventType !== 'string' || !eventType) {
    return { status: 400, body: { error: 'invalid_event_type' } };
  }
  if (typeof eventId !== 'string' || !eventId) {
    return { status: 400, body: { error: 'invalid_event_id' } };
  }

  if (IGNORE_EVENT_TYPES.has(eventType)) {
    return { status: 200, body: { ok: true, ignored: eventType } };
  }

  // ── 消費型 Stella クレジット購入 (entitlement を持たないので entitlement フィルタより前で処理) ──
  // NON_RENEWING_PURCHASE のうち product_id が CONSULTATION_CREDIT_PRODUCTS にあれば、
  // 購入残高に付与する (cosmic_pro エンタイトルメントとは無関係)。
  if (eventType === 'NON_RENEWING_PURCHASE') {
    const creditAmount = consultationCreditAmountForProduct(env, ev.product_id);
    if (creditAmount > 0) {
      const appUserId = ev.app_user_id;
      if (typeof appUserId !== 'string' || !appUserId) {
        return { status: 400, body: { error: 'invalid_app_user_id' } };
      }
      const grant = await callDo(env, '/consultation-credit-grant', {
        appUserId, amount: creditAmount, eventId,
      });
      if (grant.status !== 200) {
        return { status: 500, body: { error: 'credit_grant_failed', detail: grant.body } };
      }
      return {
        status: 200,
        body: {
          ok: true,
          eventType,
          appUserId,
          creditsGranted: creditAmount,
          balance: grant.body.balance,
          alreadyProcessed: grant.body.alreadyProcessed === true,
        },
      };
    }
    // credit 商品でない NON_RENEWING_PURCHASE は従来の entitlement 処理へ続行
  }

  // Solara 対象 entitlement に絡まないイベントは無視
  // (RC は project 内全 entitlement の event を 1 webhook URL に送るため、ここで絞る)
  const eventEntitlements = Array.isArray(ev.entitlement_ids)
    ? ev.entitlement_ids
    : (typeof ev.entitlement_id === 'string' ? [ev.entitlement_id] : []);
  if (!eventEntitlements.includes(SOLARA_ENTITLEMENT_ID)) {
    return { status: 200, body: { ok: true, ignored: 'entitlement_not_targeted' } };
  }

  // app_user_id は RC 公式: 現在の owner uid。anonymous なら `$RCAnonymousID:xxx`。
  const appUserId = ev.app_user_id;
  if (typeof appUserId !== 'string' || !appUserId) {
    return { status: 400, body: { error: 'invalid_app_user_id' } };
  }

  const environment = (ev.environment === 'PRODUCTION') ? 'production' : 'sandbox';
  const store = (typeof ev.store === 'string') ? ev.store.toLowerCase() : null;
  const productId = (typeof ev.product_id === 'string') ? ev.product_id : null;
  const periodType = (typeof ev.period_type === 'string') ? ev.period_type : null;

  // expires_at は ms 単位、auto-renew off で null になることも (lifetime/NON_RENEWING)
  let expiresAt = null;
  if (typeof ev.expiration_at_ms === 'number' && Number.isFinite(ev.expiration_at_ms)) {
    expiresAt = ev.expiration_at_ms;
  }

  // grace_period_expiration_at_ms (Apple/Google grace 中サービス維持の公式要件)。
  // BILLING_ISSUE / 一部 CANCELLATION で値が入る。entitlement_get は MAX(expires_at, grace_expires_at)
  // で失効判定するため、grace を渡すと正しく grace 期間まで Pro が維持される。
  let graceExpiresAt = null;
  if (typeof ev.grace_period_expiration_at_ms === 'number' && Number.isFinite(ev.grace_period_expiration_at_ms)) {
    graceExpiresAt = ev.grace_period_expiration_at_ms;
  }

  // event_timestamp_ms (out-of-order 判定の正典、RC 公式: webhook 受信順序は保証されない)。
  // 古い event が新しい状態を上書きする事故を防ぐため必須。
  let eventTimestampMs = null;
  if (typeof ev.event_timestamp_ms === 'number' && Number.isFinite(ev.event_timestamp_ms)) {
    eventTimestampMs = ev.event_timestamp_ms;
  }

  // is_active 判定
  let isActive;
  if (ACTIVE_EVENT_TYPES.has(eventType)) {
    isActive = true;
  } else if (GRACE_EVENT_TYPES.has(eventType)) {
    // 期限まで is_active=true (DO 側 entitlement-get で expires_at<now なら自然失効)
    isActive = true;
  } else if (INACTIVE_EVENT_TYPES.has(eventType)) {
    isActive = false;
  } else if (eventType === 'TRANSFER') {
    // RC 公式: 1 transfer = 旧 owner 通 + 新 owner 通 の 2 webhook 発火。
    // 各 event の app_user_id が transferred_from / transferred_to のどちらに含まれるかで
    // active/inactive を分岐する。両方に居ない場合 (= 不明) は安全側で active 維持
    // (旧実装の挙動を踏襲、後方互換)。
    // 公式: https://www.revenuecat.com/docs/integrations/webhooks/event-types-and-fields#transfer
    const fromArr = Array.isArray(ev.transferred_from) ? ev.transferred_from : [];
    const toArr = Array.isArray(ev.transferred_to) ? ev.transferred_to : [];
    if (fromArr.includes(appUserId)) {
      isActive = false; // 旧 owner: entitlement を失う
    } else if (toArr.includes(appUserId)) {
      isActive = true;  // 新 owner: entitlement を獲得
    } else {
      isActive = true;  // 判別不能: 旧実装と同じく安全側で active 維持
    }
  } else {
    // 未知 event は副作用なしで 200 ignored 返却 (DO は touch しない)。
    // 旧実装は isActive=false で upsert して「未知 event で Pro 誤失効」事故を起こすリスクがあった。
    // RC が将来追加する event でも、明示 ACTIVE 対応するまで DO は前回状態を維持する方が安全。
    return { status: 200, body: { ok: true, ignored: 'unknown_event_type', eventType } };
  }

  const result = await callDo(env, '/entitlement-upsert', {
    appUserId,
    entitlementId: SOLARA_ENTITLEMENT_ID,
    isActive,
    expiresAt,
    graceExpiresAt,
    environment,
    store,
    productId,
    periodType,
    eventType,
    eventId,
    eventTimestampMs,
  });

  if (result.status !== 200) {
    return { status: 500, body: { error: 'entitlement_upsert_failed', detail: result.body } };
  }

  // 受信 Worker instance のメモリキャッシュは即時 invalidate
  clearMemoryEntitlementCache(appUserId);

  return {
    status: 200,
    body: {
      ok: true,
      eventType,
      appUserId,
      isActive,
      expiresAt,
      alreadyProcessed: result.body.alreadyProcessed === true,
      skippedOutOfOrder: result.body.skippedOutOfOrder === true,
    },
  };
}

/**
 * Worker entry から呼ばれる Webhook handler。
 *
 * @param {Request} request - POST /webhooks/revenuecat
 * @param {object} env - Worker bindings (REVENUECAT_WEBHOOK_AUTH + ATTESTATION_DO 必須)
 * @returns {Promise<Response>}
 */
export async function handleRevenueCatWebhook(request, env) {
  if (request.method !== 'POST') {
    return jsonResponse(405, { error: 'method_not_allowed' });
  }

  // 1. Bearer 認証 (constant-time)
  const expected = env.REVENUECAT_WEBHOOK_AUTH;
  if (typeof expected !== 'string' || expected.length === 0) {
    // secret 未設定で受け入れない (公開前ガード)
    console.error('[revenuecat-webhook] REVENUECAT_WEBHOOK_AUTH not set');
    return jsonResponse(503, { error: 'webhook_disabled' });
  }
  const auth = request.headers.get('Authorization') || '';
  const claimed = auth.startsWith('Bearer ') ? auth.slice('Bearer '.length) : '';
  if (!timingSafeEqualString(expected, claimed)) {
    return jsonResponse(401, { error: 'unauthorized' });
  }

  // 2. JSON parse
  let payload;
  try {
    payload = await request.json();
  } catch (_e) {
    return jsonResponse(400, { error: 'invalid_json' });
  }
  const ev = payload && typeof payload === 'object' ? payload.event : null;
  if (!ev || typeof ev !== 'object') {
    return jsonResponse(400, { error: 'missing_event' });
  }

  // 3. event 処理 (DO upsert + cache invalidate)
  try {
    const { status, body } = await processEvent(env, ev);
    return jsonResponse(status, body);
  } catch (err) {
    console.error('[revenuecat-webhook] processEvent threw:', err.stack || err.message);
    return jsonResponse(500, { error: 'internal_error', message: err.message });
  }
}

// テスト用 export (本番コードからは import しない)
export const _internal = {
  timingSafeEqualString,
  consultationCreditAmountForProduct,
  ACTIVE_EVENT_TYPES,
  GRACE_EVENT_TYPES,
  INACTIVE_EVENT_TYPES,
  IGNORE_EVENT_TYPES,
  SOLARA_ENTITLEMENT_ID,
};
