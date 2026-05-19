/**
 * Apple App Attest + RevenueCat エンタイトルメント用 Durable Object (SQLite-backed)。
 *
 * 設計 v1.8 §6.1 + v2.2 (RevenueCat Webhook 統合) に従い、1 instance
 * (`idFromName('global')`) に 5 表を集約:
 *   - attestations:      端末ごとの公開鍵 + counter (App Attest)
 *   - challenges:        server 発行 challenge の強整合管理 (one-time use)
 *   - user_quota:        per-user rate limit (Layer C、Free=5/日 Pro=100/日)
 *   - user_entitlements: appUserId × entitlementId の Pro 状態 (RevenueCat Webhook で書込)
 *   - webhook_events:    Webhook event_id の idempotent 受信ログ (重複送信耐性)
 *
 * 単一 DO instance への集約理由:
 *   - DAU 1,500 想定で同時刻書き込み <100/sec → DO の sequential write 内に余裕で収まる
 *   - 複数 instance に sharding すると billing と運用コスト上昇
 *   - 将来バズった場合のみ keyId-prefix sharding に切替 (= 256 instance に分散)
 *
 * 外部 HTTP API (`fetch(request)`):
 *   POST /challenge-create  body: {challengeId, challengeBytes, expiresAt}
 *   POST /challenge-consume body: {challengeId, now}  → {challengeBytes} or 404
 *   POST /attestation-store body: {keyId, publicKeyPem, rpId, aaguid, now}
 *   POST /attestation-get   body: {keyId}              → {publicKeyPem, counter} or 404
 *   POST /attestation-bump-counter body: {keyId, signCount, now}  → {ok} or 409 (signCount <= prev)
 *   POST /quota-check-and-bump body: {keyId, dayBucket, limit, now}
 *                                                       → {ok: true, remaining} or 429 {remaining: 0}
 *   POST /entitlement-upsert body: {appUserId, entitlementId, isActive, expiresAt,
 *                                   environment, store, productId, periodType,
 *                                   eventType, eventId, now}
 *                                                       → {ok, alreadyProcessed?}
 *   POST /entitlement-get   body: {appUserId, entitlementId, now}
 *                                                       → {isActive, expiresAt, environment, ...}
 *                                                         or 404 (record なし or 期限切れで自然失効)
 *
 * Caller (Worker middleware) はこれらを順番に叩いて検証する。
 */

export class AttestationState {
  /**
   * @param {DurableObjectState} state
   * @param {object} env
   */
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.sql = state.storage.sql;
    this._initialized = false;
  }

  // 起動時にスキーマを idempotent に作成 (CREATE TABLE IF NOT EXISTS)
  _ensureSchema() {
    if (this._initialized) return;
    // attestations: 端末ごとの永続情報
    this.sql.exec(`
      CREATE TABLE IF NOT EXISTS attestations (
        key_id TEXT PRIMARY KEY,
        public_key_pem TEXT NOT NULL,
        counter INTEGER NOT NULL DEFAULT 0,
        rp_id TEXT NOT NULL,
        aaguid TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        last_used_at INTEGER NOT NULL
      );
    `);
    // challenges: one-time use challenge
    this.sql.exec(`
      CREATE TABLE IF NOT EXISTS challenges (
        challenge_id TEXT PRIMARY KEY,
        challenge_bytes BLOB NOT NULL,
        expires_at INTEGER NOT NULL,
        consumed_at INTEGER
      );
    `);
    this.sql.exec(`CREATE INDEX IF NOT EXISTS idx_challenges_expires ON challenges(expires_at);`);
    // user_quota: per-user per-day rate limit
    this.sql.exec(`
      CREATE TABLE IF NOT EXISTS user_quota (
        key_id TEXT NOT NULL,
        day_bucket TEXT NOT NULL,
        count INTEGER NOT NULL DEFAULT 0,
        last_used_at INTEGER NOT NULL,
        PRIMARY KEY (key_id, day_bucket)
      );
    `);
    this.sql.exec(`CREATE INDEX IF NOT EXISTS idx_user_quota_day ON user_quota(day_bucket);`);
    // user_entitlements: appUserId × entitlementId → 現在の Pro 状態 (RevenueCat Webhook で書込)
    // expires_at null は lifetime (現状は subscription のみのため実際は常に値あり)
    // last_event_at は同 (appUserId, entitlementId) に対する out-of-order Webhook の排除に使う
    this.sql.exec(`
      CREATE TABLE IF NOT EXISTS user_entitlements (
        app_user_id TEXT NOT NULL,
        entitlement_id TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 0,
        expires_at INTEGER,
        environment TEXT NOT NULL,
        store TEXT,
        product_id TEXT,
        period_type TEXT,
        last_event_type TEXT,
        last_event_id TEXT,
        last_event_at INTEGER NOT NULL,
        PRIMARY KEY (app_user_id, entitlement_id)
      );
    `);
    this.sql.exec(`CREATE INDEX IF NOT EXISTS idx_user_entitlements_expires ON user_entitlements(expires_at);`);
    // webhook_events: event_id 単位の冪等性保証 (同 event_id 再送で副作用を起こさない)
    this.sql.exec(`
      CREATE TABLE IF NOT EXISTS webhook_events (
        event_id TEXT PRIMARY KEY,
        received_at INTEGER NOT NULL,
        event_type TEXT NOT NULL,
        app_user_id TEXT,
        entitlement_id TEXT
      );
    `);
    this.sql.exec(`CREATE INDEX IF NOT EXISTS idx_webhook_events_received ON webhook_events(received_at);`);
    this._initialized = true;
  }

  // ── /challenge-create ──
  async _challengeCreate({ challengeId, challengeBytes, expiresAt }) {
    if (typeof challengeId !== 'string' || !challengeId) return { status: 400, body: { error: 'invalid_challenge_id' } };
    if (!Array.isArray(challengeBytes) || challengeBytes.length !== 32) {
      return { status: 400, body: { error: 'invalid_challenge_bytes' } };
    }
    if (typeof expiresAt !== 'number' || expiresAt <= Date.now()) {
      return { status: 400, body: { error: 'invalid_expires_at' } };
    }
    // expired 行 cleanup を毎回実施 (DAU 1500 想定で行数が爆発しない)
    this.sql.exec(`DELETE FROM challenges WHERE expires_at < ?`, Date.now());
    try {
      this.sql.exec(
        `INSERT INTO challenges (challenge_id, challenge_bytes, expires_at) VALUES (?, ?, ?)`,
        challengeId,
        new Uint8Array(challengeBytes),
        expiresAt,
      );
    } catch (_e) {
      return { status: 409, body: { error: 'challenge_id_conflict' } };
    }
    return { status: 200, body: { ok: true } };
  }

  // ── /challenge-consume ──
  async _challengeConsume({ challengeId, now = Date.now() }) {
    if (typeof challengeId !== 'string' || !challengeId) return { status: 400, body: { error: 'invalid_challenge_id' } };
    const rows = this.sql.exec(
      `SELECT challenge_bytes FROM challenges WHERE challenge_id = ? AND expires_at > ? AND consumed_at IS NULL`,
      challengeId,
      now,
    ).toArray();
    if (rows.length === 0) return { status: 404, body: { error: 'challenge_not_found_or_consumed_or_expired' } };
    this.sql.exec(`UPDATE challenges SET consumed_at = ? WHERE challenge_id = ?`, now, challengeId);
    return { status: 200, body: { challengeBytes: Array.from(new Uint8Array(rows[0].challenge_bytes)) } };
  }

  // ── /attestation-store ──
  async _attestationStore({ keyId, publicKeyPem, rpId, aaguid, now = Date.now() }) {
    if (typeof keyId !== 'string' || !keyId) return { status: 400, body: { error: 'invalid_key_id' } };
    if (typeof publicKeyPem !== 'string' || !publicKeyPem.includes('BEGIN PUBLIC KEY')) {
      return { status: 400, body: { error: 'invalid_public_key_pem' } };
    }
    if (typeof rpId !== 'string' || !rpId) return { status: 400, body: { error: 'invalid_rp_id' } };
    if (aaguid !== 'production' && aaguid !== 'development') return { status: 400, body: { error: 'invalid_aaguid' } };
    // INSERT OR REPLACE で同一 keyId 再 attest 時も上書き (Apple は端末再 attest を許容)
    this.sql.exec(
      `INSERT OR REPLACE INTO attestations (key_id, public_key_pem, counter, rp_id, aaguid, created_at, last_used_at)
       VALUES (?, ?, 0, ?, ?, ?, ?)`,
      keyId, publicKeyPem, rpId, aaguid, now, now,
    );
    return { status: 200, body: { ok: true } };
  }

  // ── /attestation-get ──
  async _attestationGet({ keyId }) {
    if (typeof keyId !== 'string' || !keyId) return { status: 400, body: { error: 'invalid_key_id' } };
    const rows = this.sql.exec(`SELECT public_key_pem, counter FROM attestations WHERE key_id = ?`, keyId).toArray();
    if (rows.length === 0) return { status: 404, body: { error: 'attestation_not_found' } };
    return { status: 200, body: { publicKeyPem: rows[0].public_key_pem, counter: rows[0].counter } };
  }

  // ── /attestation-bump-counter ──
  // signCount が DO 内の前回値より strictly greater のみ受理 (= replay 防止)
  async _attestationBumpCounter({ keyId, signCount, now = Date.now() }) {
    if (typeof keyId !== 'string' || !keyId) return { status: 400, body: { error: 'invalid_key_id' } };
    if (typeof signCount !== 'number' || !Number.isInteger(signCount) || signCount < 0) {
      return { status: 400, body: { error: 'invalid_sign_count' } };
    }
    const rows = this.sql.exec(`SELECT counter FROM attestations WHERE key_id = ?`, keyId).toArray();
    if (rows.length === 0) return { status: 404, body: { error: 'attestation_not_found' } };
    const prev = rows[0].counter;
    if (signCount <= prev) {
      return { status: 409, body: { error: 'sign_count_not_greater', prev, given: signCount } };
    }
    this.sql.exec(
      `UPDATE attestations SET counter = ?, last_used_at = ? WHERE key_id = ?`,
      signCount, now, keyId,
    );
    return { status: 200, body: { ok: true } };
  }

  // ── /quota-check-and-bump ──
  // 当日 bucket の count を atomic に +1、limit 超なら 429
  async _quotaCheckAndBump({ keyId, dayBucket, limit, now = Date.now() }) {
    if (typeof keyId !== 'string' || !keyId) return { status: 400, body: { error: 'invalid_key_id' } };
    if (typeof dayBucket !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(dayBucket)) {
      return { status: 400, body: { error: 'invalid_day_bucket' } };
    }
    if (typeof limit !== 'number' || !Number.isInteger(limit) || limit < 1) {
      return { status: 400, body: { error: 'invalid_limit' } };
    }
    // 古い day_bucket は適当に cleanup (7 日より前)
    const cutoff = new Date(now - 7 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
    this.sql.exec(`DELETE FROM user_quota WHERE day_bucket < ?`, cutoff);
    const rows = this.sql.exec(
      `SELECT count FROM user_quota WHERE key_id = ? AND day_bucket = ?`,
      keyId, dayBucket,
    ).toArray();
    const current = rows.length > 0 ? rows[0].count : 0;
    if (current >= limit) {
      return { status: 429, body: { ok: false, error: 'quota_exceeded', remaining: 0, used: current, limit } };
    }
    const next = current + 1;
    this.sql.exec(
      `INSERT INTO user_quota (key_id, day_bucket, count, last_used_at)
       VALUES (?, ?, ?, ?)
       ON CONFLICT(key_id, day_bucket) DO UPDATE SET count = ?, last_used_at = ?`,
      keyId, dayBucket, next, now,
      next, now,
    );
    return { status: 200, body: { ok: true, remaining: limit - next, used: next, limit } };
  }

  // ── /entitlement-upsert ──
  //
  // RevenueCat Webhook handler から呼ばれる。1 event = 1 upsert。
  //
  // 冪等性保証:
  //   1. webhook_events に event_id INSERT OR IGNORE。既存なら {alreadyProcessed: true}
  //      を即返して副作用なし (Webhook 再送 / リプレイ攻撃の二重課金検知)
  //   2. last_event_at が DB 内 last_event_at より小さい (= out-of-order) なら無視
  //      (RevenueCat は順序保証しないため、古い event で新しい状態を上書きしない)
  //
  // is_active と expires_at の意味:
  //   - is_active=1, expires_at=X: 期限 X まで Pro
  //   - is_active=0: 期限切れ確定 (EXPIRATION / REFUND / TRANSFER 旧側)
  //   - is_active=1, expires_at<now: graceful (BILLING_ISSUE 等)、middleware が
  //     最終的に expires_at >= now でも判定する (Layer 2 防御)
  async _entitlementUpsert({
    appUserId, entitlementId, isActive, expiresAt,
    environment, store, productId, periodType,
    eventType, eventId, now = Date.now(),
  }) {
    if (typeof appUserId !== 'string' || !appUserId) return { status: 400, body: { error: 'invalid_app_user_id' } };
    if (typeof entitlementId !== 'string' || !entitlementId) return { status: 400, body: { error: 'invalid_entitlement_id' } };
    if (typeof isActive !== 'boolean') return { status: 400, body: { error: 'invalid_is_active' } };
    if (expiresAt !== null && (typeof expiresAt !== 'number' || !Number.isFinite(expiresAt))) {
      return { status: 400, body: { error: 'invalid_expires_at' } };
    }
    if (typeof environment !== 'string' || !environment) return { status: 400, body: { error: 'invalid_environment' } };
    if (typeof eventType !== 'string' || !eventType) return { status: 400, body: { error: 'invalid_event_type' } };
    if (typeof eventId !== 'string' || !eventId) return { status: 400, body: { error: 'invalid_event_id' } };

    // 1. event_id idempotent ガード (INSERT OR IGNORE)
    const before = this.sql.exec(
      `SELECT 1 FROM webhook_events WHERE event_id = ?`,
      eventId,
    ).toArray();
    if (before.length > 0) {
      return { status: 200, body: { ok: true, alreadyProcessed: true } };
    }
    this.sql.exec(
      `INSERT INTO webhook_events (event_id, received_at, event_type, app_user_id, entitlement_id)
       VALUES (?, ?, ?, ?, ?)`,
      eventId, now, eventType, appUserId, entitlementId,
    );

    // 2. out-of-order ガード (last_event_at 比較)
    const existing = this.sql.exec(
      `SELECT last_event_at FROM user_entitlements WHERE app_user_id = ? AND entitlement_id = ?`,
      appUserId, entitlementId,
    ).toArray();
    if (existing.length > 0 && existing[0].last_event_at > now) {
      // 古い event は無視 (event 自体は idempotent log に残す)
      return { status: 200, body: { ok: true, skippedOutOfOrder: true } };
    }

    // 3. INSERT OR REPLACE
    this.sql.exec(
      `INSERT INTO user_entitlements (
         app_user_id, entitlement_id, is_active, expires_at,
         environment, store, product_id, period_type,
         last_event_type, last_event_id, last_event_at
       ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT(app_user_id, entitlement_id) DO UPDATE SET
         is_active = excluded.is_active,
         expires_at = excluded.expires_at,
         environment = excluded.environment,
         store = excluded.store,
         product_id = excluded.product_id,
         period_type = excluded.period_type,
         last_event_type = excluded.last_event_type,
         last_event_id = excluded.last_event_id,
         last_event_at = excluded.last_event_at`,
      appUserId, entitlementId, isActive ? 1 : 0, expiresAt,
      environment, store ?? null, productId ?? null, periodType ?? null,
      eventType, eventId, now,
    );
    return { status: 200, body: { ok: true } };
  }

  // ── /entitlement-get ──
  //
  // middleware から /protected/* ごとに呼ばれる。
  // 戻り値: {isActive, expiresAt, environment, productId, periodType} or 404
  //
  // expires_at < now なら自動的に 404 を返す (= 期限切れ自然失効、Webhook 遅延吸収)。
  // ただし expires_at が null の lifetime (NON_RENEWING_PURCHASE 等) は失効しない。
  async _entitlementGet({ appUserId, entitlementId, now = Date.now() }) {
    if (typeof appUserId !== 'string' || !appUserId) return { status: 400, body: { error: 'invalid_app_user_id' } };
    if (typeof entitlementId !== 'string' || !entitlementId) return { status: 400, body: { error: 'invalid_entitlement_id' } };
    const rows = this.sql.exec(
      `SELECT is_active, expires_at, environment, product_id, period_type, last_event_type
       FROM user_entitlements
       WHERE app_user_id = ? AND entitlement_id = ?`,
      appUserId, entitlementId,
    ).toArray();
    if (rows.length === 0) return { status: 404, body: { error: 'entitlement_not_found' } };
    const r = rows[0];
    const isActive = r.is_active === 1;
    const expiresAt = r.expires_at;
    // expires_at が今より過去 → 自然失効
    if (expiresAt !== null && typeof expiresAt === 'number' && expiresAt < now) {
      return { status: 404, body: { error: 'entitlement_expired', expiresAt } };
    }
    if (!isActive) {
      return { status: 404, body: { error: 'entitlement_inactive', expiresAt } };
    }
    return {
      status: 200,
      body: {
        isActive: true,
        expiresAt,
        environment: r.environment,
        productId: r.product_id,
        periodType: r.period_type,
        lastEventType: r.last_event_type,
      },
    };
  }

  // ── HTTP entry ──
  async fetch(request) {
    this._ensureSchema();
    const url = new URL(request.url);
    const path = url.pathname;

    if (request.method !== 'POST') {
      return new Response('only POST', { status: 405 });
    }

    let body;
    try {
      body = await request.json();
    } catch (_e) {
      return new Response('invalid json', { status: 400 });
    }

    const dispatch = {
      '/challenge-create': () => this._challengeCreate(body),
      '/challenge-consume': () => this._challengeConsume(body),
      '/attestation-store': () => this._attestationStore(body),
      '/attestation-get': () => this._attestationGet(body),
      '/attestation-bump-counter': () => this._attestationBumpCounter(body),
      '/quota-check-and-bump': () => this._quotaCheckAndBump(body),
      '/entitlement-upsert': () => this._entitlementUpsert(body),
      '/entitlement-get': () => this._entitlementGet(body),
    };
    const handler = dispatch[path];
    if (!handler) return new Response('not found', { status: 404 });

    const { status, body: res } = await handler();
    return new Response(JSON.stringify(res), {
      status,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}
