/**
 * RevenueCat REST API クライアント (server-side source-of-truth 再検証用)。
 *
 * 用途:
 *   DO `user_entitlements` 表が webhook 遅延等で古い場合に、RC 本体 API に直接問い合わせて
 *   entitlement 状態を取り直す。`gateConsultation` で「クライアント主張 Pro × DO non-Pro」
 *   のときだけ呼ぶ (= 通常リクエストには影響しない)。
 *
 * 設計:
 *   - V1 API (`GET /v1/subscribers/{app_user_id}`) を使う。
 *     `expires_date` と `grace_period_expires_date` が entitlement 直下に出るため、
 *     V2 より素直に grace を扱える。
 *   - Bearer 認証: `REVENUECAT_SECRET_KEY` (sk_xxx)。wrangler secret put 済み。
 *   - 結果を 30 秒だけ Worker instance のメモリ Map に memcache する
 *     (= 同 appUserId への連続リクエスト時に RC API へバーストしない)。
 *   - 失敗時は安全側に倒す: `{ isPro: false, reason: ... }` を返し、呼び出し側は
 *     「再検証できなかった」と扱う (= 結果として Free 扱い経路には進まず、425 になる)。
 *
 * 設計参考:
 *   - https://www.revenuecat.com/docs/api-v1#operation/get-the-latest-subscriber-info
 *   - https://www.revenuecat.com/docs/customers/customer-info (server fetch ガイダンス)
 *   - https://www.revenuecat.com/docs/subscription-guidance/how-grace-periods-work
 */

/** RC 公式ホスト (固定)。 */
const RC_BASE = 'https://api.revenuecat.com/v1';

/** Solara が監視する entitlement ID。`purchases_service.dart` / webhook と同値。 */
const SOLARA_ENTITLEMENT_ID = 'cosmic_pro';

/** 30 秒 memcache。バースト吸収専用 (TTL 短い=データ鮮度を優先)。 */
const TTL_MS = 30_000;

/** GC 用上限 (1 Worker instance あたり 1000 ユーザーを超えたら最古から間引く) */
const MAX_ENTRIES = 1000;

/** Map<appUserId, {snapshot, fetchedAt}> */
const _cache = new Map();

function _prune(now) {
  for (const [k, v] of _cache) {
    if (now - v.fetchedAt > TTL_MS) _cache.delete(k);
  }
  if (_cache.size > MAX_ENTRIES) {
    const overflow = _cache.size - MAX_ENTRIES;
    const it = _cache.keys();
    for (let i = 0; i < overflow; i++) {
      const k = it.next().value;
      if (k !== undefined) _cache.delete(k);
    }
  }
}

function _getCached(appUserId) {
  const rec = _cache.get(appUserId);
  if (!rec) return undefined;
  const now = Date.now();
  if (now - rec.fetchedAt > TTL_MS) {
    _cache.delete(appUserId);
    return undefined;
  }
  return rec.snapshot;
}

function _setCached(appUserId, snapshot) {
  const now = Date.now();
  _cache.set(appUserId, { snapshot, fetchedAt: now });
  _prune(now);
}

/**
 * 注入可能な fetch wrapper (テスト用)。本番では globalThis.fetch を使う。
 * @type {typeof fetch}
 */
let _fetchImpl = (...args) => globalThis.fetch(...args);

/** テスト用: fetch を差し替える。 */
export function _setFetchForTest(impl) {
  _fetchImpl = impl;
}

/** テスト用: 再検証 cache をクリア。 */
export function _resetRcRestCacheForTest() {
  _cache.clear();
}

/**
 * RC REST V1 で entitlement を再検証する。
 *
 * @param {object} env - Worker bindings (`REVENUECAT_SECRET_KEY` 必須)
 * @param {string} appUserId - RC app_user_id (例: "google:117...")
 * @returns {Promise<{
 *   isPro: boolean,
 *   reason?: string,                                  // isPro=false のとき判明している理由
 *   appUserId?: string,
 *   entitlementId?: string,
 *   isActive?: boolean,
 *   expiresAt?: number|null,                          // ms (grace 込みの effective expires)
 *   environment?: 'sandbox'|'production',
 *   productId?: string|null,
 *   periodType?: string|null,
 * }>}
 *
 * 失敗時 (`isPro: false`) の reason 一覧:
 *   - 'no_key'         : REVENUECAT_SECRET_KEY 未設定 (= 機能無効)
 *   - 'invalid_id'     : appUserId が空 or 文字列でない
 *   - 'rc_<status>'    : RC API が HTTP エラー (rc_404=ユーザー未知 / rc_5xx=RC側障害)
 *   - 'parse_error'    : レスポンス JSON 解析失敗
 *   - 'no_entitlement' : subscriber は居るが cosmic_pro entitlement が無い
 *   - 'expired'        : entitlement はあるが expires_date と grace 両方とも過去
 *   - 'fetch_error'    : ネットワーク例外
 */
export async function reverifyEntitlementViaRC(env, appUserId) {
  if (typeof appUserId !== 'string' || appUserId.length === 0) {
    return { isPro: false, reason: 'invalid_id' };
  }
  const key = env && env.REVENUECAT_SECRET_KEY;
  if (typeof key !== 'string' || key.length === 0) {
    return { isPro: false, reason: 'no_key' };
  }

  const cached = _getCached(appUserId);
  if (cached !== undefined) return cached;

  let res;
  try {
    res = await _fetchImpl(`${RC_BASE}/subscribers/${encodeURIComponent(appUserId)}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${key}`,
        'X-Platform': 'server',
        'Accept': 'application/json',
      },
    });
  } catch (_e) {
    return { isPro: false, reason: 'fetch_error' };
  }

  if (!res.ok) {
    const snap = { isPro: false, reason: `rc_${res.status}` };
    // 404 (ユーザー未知) と 5xx は 30s memcache (RC を連打しない)
    // 401/403 は memcache しない (キー差し替え時に即反映させたい)
    if (res.status === 404 || res.status >= 500) {
      _setCached(appUserId, snap);
    }
    return snap;
  }

  let json;
  try {
    json = await res.json();
  } catch (_e) {
    return { isPro: false, reason: 'parse_error' };
  }

  const ent = json && json.subscriber && json.subscriber.entitlements
    ? json.subscriber.entitlements[SOLARA_ENTITLEMENT_ID]
    : null;
  if (!ent || typeof ent !== 'object') {
    const snap = { isPro: false, reason: 'no_entitlement' };
    _setCached(appUserId, snap);
    return snap;
  }

  // RC V1 は ISO 8601 文字列。null は lifetime (NON_RENEWING 等)。
  const expiresMs = ent.expires_date ? Date.parse(ent.expires_date) : null;
  const graceMs = ent.grace_period_expires_date ? Date.parse(ent.grace_period_expires_date) : null;
  // null = lifetime (失効しない)。両方 null なら effective=null (= lifetime 扱い)。
  let effectiveExpires;
  if (expiresMs == null && graceMs == null) {
    effectiveExpires = null; // lifetime
  } else {
    effectiveExpires = Math.max(expiresMs || 0, graceMs || 0);
  }
  const isActive = effectiveExpires === null || effectiveExpires > Date.now();

  if (!isActive) {
    const snap = { isPro: false, reason: 'expired', expiresAt: effectiveExpires };
    _setCached(appUserId, snap);
    return snap;
  }

  const subscriber = json.subscriber;
  // V1 の entitlement に environment が無いケースがあるので subscriber の original_app_user_id 等から推定不可。
  // 代替として subscriber.entitlements[ID].is_sandbox があれば見る (古い形式)。
  // 安全のため判別できなければ 'production' とせず undefined を残す (DO 既存値を上書きしない)。
  const environment = ent.is_sandbox === true ? 'sandbox' : (ent.is_sandbox === false ? 'production' : undefined);

  const snap = {
    isPro: true,
    appUserId,
    entitlementId: SOLARA_ENTITLEMENT_ID,
    isActive: true,
    expiresAt: effectiveExpires,
    environment,
    productId: ent.product_identifier || null,
    periodType: ent.period_type || null,
  };
  _setCached(appUserId, snap);
  return snap;
}

/**
 * RC REST V1 で subscriber を物理削除する (アカウント削除 / GDPR Right to Erasure 用)。
 *
 * 用途:
 *   `handleAccountDelete` から best-effort で呼ぶ。DO の派生キャッシュ削除 +
 *   memory cache invalidate に加えて、RC マスター DB からも appUserId とその購入履歴を
 *   物理削除することで、個人情報保護法 / GDPR の「忘れられる権利」を満たす。
 *
 * 失敗は呼出側にとって致命的でない (= DO 削除は既に完了している)。RC 側削除が失敗しても
 * アカウント削除フロー全体は成功扱いにする。RC は後から手動 / 再送で削除可能。
 *
 * 設計参考:
 *   - https://www.revenuecat.com/docs/api-v1#operation/delete-subscriber
 *   - 「Use this for GDPR / CCPA compliance.」 (RC 公式)
 *
 * @param {object} env - Worker bindings (`REVENUECAT_SECRET_KEY` 必須)
 * @param {string} appUserId - RC app_user_id
 * @returns {Promise<{ok: boolean, reason?: string, status?: number}>}
 *   - ok=true : 削除成功 (RC 200) or 既に居ない (RC 404)
 *   - ok=false: 失敗。reason に分類 ('no_key' / 'invalid_id' / 'rc_<status>' / 'fetch_error')
 *
 * 副作用: 削除成功時、reverify cache も invalidate (古い isPro:true snapshot を残さない)。
 */
export async function deleteSubscriberViaRC(env, appUserId) {
  if (typeof appUserId !== 'string' || appUserId.length === 0) {
    return { ok: false, reason: 'invalid_id' };
  }
  const key = env && env.REVENUECAT_SECRET_KEY;
  if (typeof key !== 'string' || key.length === 0) {
    return { ok: false, reason: 'no_key' };
  }

  let res;
  try {
    res = await _fetchImpl(`${RC_BASE}/subscribers/${encodeURIComponent(appUserId)}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${key}`,
        'X-Platform': 'server',
        'Accept': 'application/json',
      },
    });
  } catch (_e) {
    return { ok: false, reason: 'fetch_error' };
  }

  // 200 = 削除成功、404 = もう居ない (= 既に削除済 or 一度も登録されていない)。どちらも ok 扱い。
  if (res.status === 200 || res.status === 204 || res.status === 404) {
    // reverify cache に「Pro である」snapshot が残っていると整合性が崩れるので削除。
    _cache.delete(appUserId);
    return { ok: true, status: res.status };
  }

  return { ok: false, reason: `rc_${res.status}`, status: res.status };
}
