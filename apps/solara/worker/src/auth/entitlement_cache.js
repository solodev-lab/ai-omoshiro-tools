/**
 * Worker instance ローカルの entitlement キャッシュ。
 *
 * 目的:
 *   /protected/* 1 リクエストごとに DO へ entitlement-get する代わりに、
 *   60s TTL のメモリ Map で間引く (= DO billing と latency 両方を下げる)。
 *
 * 整合性:
 *   - cold start ごとに空。Worker instance が短命のため十分。
 *   - Webhook 受信 instance は INSERT 直後に clearMemoryEntitlementCache を呼ぶ。
 *   - 他 instance は最悪 60s で次回 read 時に DO から最新を取得 (eventual)。
 *   - false positive (Pro じゃないのに Pro 判定) は最大 60s 発生し得る。
 *     refund/cancellation 直後 60s は Pro 維持 = 攻撃には使えない、UX 影響だけ。
 *
 * 形状: Map<appUserId, {snapshot, fetchedAt}>
 *   snapshot: {isActive, expiresAt, environment, productId, periodType} or null (= 404)
 *   fetchedAt: ms
 */

const TTL_MS = 60_000;
const _cache = new Map();

/** GC 用上限 (これ超えたら最古から間引く) */
const MAX_ENTRIES = 10_000;

function _prune(now) {
  // 期限切れ + 上限超過の古いものを順に削除
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

/**
 * snapshot を取得。期限切れ / 未保存なら null。
 * @returns {{isActive: boolean, expiresAt: number|null}|null|undefined}
 *   - undefined = キャッシュミス (DO を叩く必要あり)
 *   - null      = キャッシュ済 + Pro 無し
 *   - object    = キャッシュ済 + Pro あり (有効期限内)
 */
export function getCachedEntitlement(appUserId) {
  if (typeof appUserId !== 'string' || !appUserId) return undefined;
  const rec = _cache.get(appUserId);
  if (!rec) return undefined;
  const now = Date.now();
  if (now - rec.fetchedAt > TTL_MS) {
    _cache.delete(appUserId);
    return undefined;
  }
  return rec.snapshot;
}

/**
 * DO 取得結果を Worker instance キャッシュへ。null は「Pro 無し」も含めて記録する
 * (= 404 を 60s memoize して DO 連打を防ぐ)。
 */
export function setCachedEntitlement(appUserId, snapshot) {
  if (typeof appUserId !== 'string' || !appUserId) return;
  const now = Date.now();
  _cache.set(appUserId, { snapshot, fetchedAt: now });
  _prune(now);
}

/** Webhook 受信時に呼ぶ (同 instance 内で即時無効化) */
export function clearMemoryEntitlementCache(appUserId) {
  if (typeof appUserId !== 'string' || !appUserId) return;
  _cache.delete(appUserId);
}

/** テスト用: 全消し */
export function _resetEntitlementCacheForTest() {
  _cache.clear();
}
