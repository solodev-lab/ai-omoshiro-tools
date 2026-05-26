/**
 * Apple App Attest + RevenueCat エンタイトルメント + Play Integrity 用 Durable Object (SQLite-backed)。
 *
 * 設計 v1.8 §6.1 + v2.2 (RevenueCat Webhook 統合) + Play Integrity v0.6 §5 に従い、
 * 1 instance (`idFromName('global')`) に 6 表を集約:
 *   - attestations:      端末ごとの公開鍵 + counter (App Attest)
 *   - challenges:        App Attest 用 server 発行 challenge の強整合管理 (one-time use、BLOB)
 *   - user_quota:        per-user rate limit (Layer C、Free=5/日 Pro=100/日)
 *   - user_entitlements: appUserId × entitlementId の Pro 状態 (RevenueCat Webhook で書込)
 *   - webhook_events:    Webhook event_id の idempotent 受信ログ (重複送信耐性)
 *   - integrity_nonces:  Play Integrity Standard request 用 nonce (one-time use、TEXT base64)
 *   - consultation_credits: Stella 相談の Free 試食クレジット (端末ごと週次カウンター)
 *   - consultation_purchased: Stella 相談の購入クレジット残高 (アカウント appUserId ごと、消費型 IAP)
 *   - fortune_readings:  Horo「今日の占い」の 1 日 1 回固定キャッシュ
 *                        ((appUserId, local_date, category) で一意。プロフィール変更で
 *                        再生成されない=「変更しない事にする」設計。Free=overall 1 件、
 *                        Pro=5 カテゴリ。日付境界はユーザの local TZ。)
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
 *   POST /integrity-nonce-create  body: {nonceId, nonceB64, expiresAt}
 *                                                       → {ok} or 409 {nonce_id_conflict}
 *   POST /integrity-nonce-consume body: {nonceId, now}  → {nonceB64} or 404 (一致+consume)
 *   POST /account-purge     body: {appUserId}            → {ok, deletedEntitlements, deletedEvents}
 *                                                          (アカウント削除: appUserId の Pro 記録 +
 *                                                           Webhook event ログを物理削除)
 *   POST /consultation-credit-get  body: {deviceKey, weekBucket}  → {used}
 *                                                          (週が違えば used=0 = 自然リセット)
 *   POST /consultation-credit-bump body: {deviceKey, weekBucket, now}  → {used}
 *                                                          (週が違えばリセットして 1、同週なら +1)
 *   POST /consultation-purchased-get   body: {appUserId}            → {balance}
 *   POST /consultation-purchased-spend body: {appUserId, now}       → {balance, spent}
 *                                                          (balance>0 なら -1 して spent:true)
 *   POST /consultation-credit-grant    body: {appUserId, amount, eventId, now}
 *                                                          → {balance, alreadyProcessed?}
 *                                                          (消費型購入で残高 +amount、event_id 冪等)
 *   POST /fortune-reading-get   body: {appUserId, localDate, category, lang?}
 *                                                          → {found:true, reading, advice, score}
 *                                                            or {found:false}
 *   POST /fortune-reading-set   body: {appUserId, localDate, category, lang?,
 *                                       reading, advice, score, now?}  → {ok}
 *                                                          ((appUserId, localDate, category, lang) 一意、
 *                                                           ON CONFLICT DO NOTHING で初回勝ち。
 *                                                           14日より古い行を毎回 cleanup)
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
    // integrity_nonces: Play Integrity Standard request 用 nonce (one-time use)
    // 設計 v0.6.1 §5: TEXT (base64) で保管 — plugin 側の clientData.nonce が
    // base64 文字列のため、`consumed === clientData.nonce` の string compare が最速。
    // 既存 `challenges` 表 (BLOB、App Attest の raw bytes 用途) とは用途が違うため不一致は許容。
    this.sql.exec(`
      CREATE TABLE IF NOT EXISTS integrity_nonces (
        nonce_id TEXT PRIMARY KEY,
        nonce_b64 TEXT NOT NULL,
        expires_at INTEGER NOT NULL,
        consumed_at INTEGER
      );
    `);
    this.sql.exec(`CREATE INDEX IF NOT EXISTS idx_integrity_nonces_expires ON integrity_nonces(expires_at);`);
    // consultation_credits: Stella 相談の Free 試食クレジット (端末ごと週次カウンター)
    // device_key を PRIMARY KEY にするため 1 端末 = 1 行 (週が変わったら used を上書きリセット)。
    // 行は端末ごとに使い回すので無限増殖しない (cleanup 不要、DAU 5000 で sharding 検討は他表と同じ)。
    this.sql.exec(`
      CREATE TABLE IF NOT EXISTS consultation_credits (
        device_key TEXT PRIMARY KEY,
        week_bucket TEXT NOT NULL,
        used INTEGER NOT NULL DEFAULT 0,
        last_used_at INTEGER NOT NULL
      );
    `);
    // consultation_purchased: 消費型 IAP で買った相談クレジットの残高 (アカウント appUserId ごと)。
    // 無料週次 (consultation_credits) を使い切った後に消費する。失効しない (購入物)。
    // サインイン必須前提なので appUserId は apple:/google: の安定値。
    this.sql.exec(`
      CREATE TABLE IF NOT EXISTS consultation_purchased (
        app_user_id TEXT PRIMARY KEY,
        balance INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL
      );
    `);
    // fortune_readings: Horo「今日の占い」の 1 日 1 回固定キャッシュ。
    // (appUserId, local_date, category, lang) で一意 = プロフィール変更で再生成されない設計。
    // local_date は端末の local TZ (例: Asia/Tokyo 0 時境界) で YYYY-MM-DD。
    // lang は ja/en (内容が言語で異なるため、別 language で再 fetch しても上書きしない)。
    // SET は ON CONFLICT DO NOTHING で初回勝ち (並行リクエストでも安全)。
    // 14 日より古い行は毎回 SET 時に cleanup (DAU 1500 × 5cat × 14日 ≒ 100K 行で頭打ち)。
    this.sql.exec(`
      CREATE TABLE IF NOT EXISTS fortune_readings (
        app_user_id TEXT NOT NULL,
        local_date  TEXT NOT NULL,
        category    TEXT NOT NULL,
        lang        TEXT NOT NULL DEFAULT 'ja',
        reading     TEXT NOT NULL,
        advice      TEXT NOT NULL,
        score       INTEGER NOT NULL,
        generated_at INTEGER NOT NULL,
        PRIMARY KEY (app_user_id, local_date, category, lang)
      );
    `);
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

  // ── /account-purge ──
  //
  // アカウント削除 (App Store ガイドライン 5.1.1(v)) の「サーバー側の関連データ削除」。
  // 指定 appUserId に紐づく Pro エンタイトルメント記録と Webhook event ログを物理削除する。
  //
  // 注意:
  //   - これは RevenueCat の真実 (購読そのもの) を解約するものではない。購読は
  //     Apple/Google が管理し、解約はユーザーが各ストアで行う。ここで消すのは
  //     Worker が保持する「派生キャッシュ + 個人識別子 (apple:/google: の uid)」のみ。
  //   - quota 表は appUserId ではなく keyId/play:uid キーで日次ローテートするため対象外。
  //   - 削除後に再び Webhook が届けば user_entitlements は再生成されるが、それは
  //     ストア側の現実 (まだ購読中) を反映するだけで、個人識別子の削除義務とは独立。
  async _accountPurge({ appUserId }) {
    if (typeof appUserId !== 'string' || !appUserId) {
      return { status: 400, body: { error: 'invalid_app_user_id' } };
    }
    const ent = this.sql.exec(
      `DELETE FROM user_entitlements WHERE app_user_id = ?`,
      appUserId,
    );
    const evt = this.sql.exec(
      `DELETE FROM webhook_events WHERE app_user_id = ?`,
      appUserId,
    );
    return {
      status: 200,
      body: {
        ok: true,
        deletedEntitlements: ent.rowsWritten ?? 0,
        deletedEvents: evt.rowsWritten ?? 0,
      },
    };
  }

  // ── /integrity-nonce-create ──
  //
  // Play Integrity Standard request 用の server-issued nonce を発行・保存。
  // Apple App Attest の /challenge-create と対称 (BLOB ではなく TEXT で保管)。
  async _integrityNonceCreate({ nonceId, nonceB64, expiresAt }) {
    if (typeof nonceId !== 'string' || !nonceId) {
      return { status: 400, body: { error: 'invalid_nonce_id' } };
    }
    if (typeof nonceB64 !== 'string' || nonceB64.length < 32) {
      return { status: 400, body: { error: 'invalid_nonce_b64' } };
    }
    if (typeof expiresAt !== 'number' || expiresAt <= Date.now()) {
      return { status: 400, body: { error: 'invalid_expires_at' } };
    }
    // expired 行 cleanup を毎回実施 (DAU 1500 想定で行数が爆発しない、challenges と同パターン)
    this.sql.exec(`DELETE FROM integrity_nonces WHERE expires_at < ?`, Date.now());
    try {
      this.sql.exec(
        `INSERT INTO integrity_nonces (nonce_id, nonce_b64, expires_at) VALUES (?, ?, ?)`,
        nonceId,
        nonceB64,
        expiresAt,
      );
    } catch (_e) {
      return { status: 409, body: { error: 'nonce_id_conflict' } };
    }
    return { status: 200, body: { ok: true } };
  }

  // ── /integrity-nonce-consume ──
  //
  // 一度きりの consume。expired / consumed / 未存在は 404。
  // 成功時は nonce_b64 を返却 → middleware が clientData.nonce と一致確認。
  async _integrityNonceConsume({ nonceId, now = Date.now() }) {
    if (typeof nonceId !== 'string' || !nonceId) {
      return { status: 400, body: { error: 'invalid_nonce_id' } };
    }
    const rows = this.sql
      .exec(
        `SELECT nonce_b64 FROM integrity_nonces
           WHERE nonce_id = ? AND expires_at > ? AND consumed_at IS NULL`,
        nonceId,
        now,
      )
      .toArray();
    if (rows.length === 0) {
      return { status: 404, body: { error: 'nonce_not_found_or_consumed_or_expired' } };
    }
    this.sql.exec(
      `UPDATE integrity_nonces SET consumed_at = ? WHERE nonce_id = ?`,
      now,
      nonceId,
    );
    return { status: 200, body: { nonceB64: rows[0].nonce_b64 } };
  }

  // ── /consultation-credit-get ──
  //
  // Stella 相談 Free 試食クレジットの当週使用回数を返す (read-only)。
  // 保存されている週が weekBucket と違えば used=0 (= 月曜リセットの自然失効)。
  // limit との比較は呼び出し側 (Worker) が env の CONSULTATION_FREE_WEEKLY で行う。
  async _consultationCreditGet({ deviceKey, weekBucket }) {
    if (typeof deviceKey !== 'string' || !deviceKey) {
      return { status: 400, body: { error: 'invalid_device_key' } };
    }
    if (typeof weekBucket !== 'string' || !/^\d{4}-W\d{2}$/.test(weekBucket)) {
      return { status: 400, body: { error: 'invalid_week_bucket' } };
    }
    const rows = this.sql.exec(
      `SELECT week_bucket, used FROM consultation_credits WHERE device_key = ?`,
      deviceKey,
    ).toArray();
    if (rows.length === 0 || rows[0].week_bucket !== weekBucket) {
      return { status: 200, body: { used: 0 } };
    }
    return { status: 200, body: { used: rows[0].used } };
  }

  // ── /consultation-credit-bump ──
  //
  // 当週の used を +1 して返す。保存週が違えば (= 別週) リセットして used=1。
  // Worker は「Stella 生成が実際に成功した時だけ」これを呼ぶ (静的 fallback は消費しない)。
  async _consultationCreditBump({ deviceKey, weekBucket, now = Date.now() }) {
    if (typeof deviceKey !== 'string' || !deviceKey) {
      return { status: 400, body: { error: 'invalid_device_key' } };
    }
    if (typeof weekBucket !== 'string' || !/^\d{4}-W\d{2}$/.test(weekBucket)) {
      return { status: 400, body: { error: 'invalid_week_bucket' } };
    }
    const rows = this.sql.exec(
      `SELECT week_bucket, used FROM consultation_credits WHERE device_key = ?`,
      deviceKey,
    ).toArray();
    const used = (rows.length === 0 || rows[0].week_bucket !== weekBucket)
      ? 1
      : rows[0].used + 1;
    this.sql.exec(
      `INSERT INTO consultation_credits (device_key, week_bucket, used, last_used_at)
       VALUES (?, ?, ?, ?)
       ON CONFLICT(device_key) DO UPDATE SET week_bucket = ?, used = ?, last_used_at = ?`,
      deviceKey, weekBucket, used, now,
      weekBucket, used, now,
    );
    return { status: 200, body: { used } };
  }

  // ── /consultation-purchased-get ──
  // 購入クレジット残高 (read-only)。未保存は 0。
  async _consultationPurchasedGet({ appUserId }) {
    if (typeof appUserId !== 'string' || !appUserId) {
      return { status: 400, body: { error: 'invalid_app_user_id' } };
    }
    const rows = this.sql.exec(
      `SELECT balance FROM consultation_purchased WHERE app_user_id = ?`,
      appUserId,
    ).toArray();
    return { status: 200, body: { balance: rows.length > 0 ? rows[0].balance : 0 } };
  }

  // ── /consultation-purchased-spend ──
  // 残高 > 0 なら -1 して {balance, spent:true}、0 なら {balance:0, spent:false}。
  // Worker は「無料週次を使い切った + Stella 生成が成功した時」だけ呼ぶ。
  async _consultationPurchasedSpend({ appUserId, now = Date.now() }) {
    if (typeof appUserId !== 'string' || !appUserId) {
      return { status: 400, body: { error: 'invalid_app_user_id' } };
    }
    const rows = this.sql.exec(
      `SELECT balance FROM consultation_purchased WHERE app_user_id = ?`,
      appUserId,
    ).toArray();
    const cur = rows.length > 0 ? rows[0].balance : 0;
    if (cur <= 0) return { status: 200, body: { balance: 0, spent: false } };
    const next = cur - 1;
    this.sql.exec(
      `UPDATE consultation_purchased SET balance = ?, updated_at = ? WHERE app_user_id = ?`,
      next, now, appUserId,
    );
    return { status: 200, body: { balance: next, spent: true } };
  }

  // ── /consultation-credit-grant ──
  // 消費型 IAP 購入で残高 +amount。RC Webhook (NON_RENEWING_PURCHASE) から呼ばれる。
  // eventId で冪等 (webhook_events を共用、二重付与防止)。
  async _consultationCreditGrant({ appUserId, amount, eventId, now = Date.now() }) {
    if (typeof appUserId !== 'string' || !appUserId) {
      return { status: 400, body: { error: 'invalid_app_user_id' } };
    }
    if (typeof amount !== 'number' || !Number.isInteger(amount) || amount <= 0) {
      return { status: 400, body: { error: 'invalid_amount' } };
    }
    if (typeof eventId !== 'string' || !eventId) {
      return { status: 400, body: { error: 'invalid_event_id' } };
    }
    // 冪等ガード (webhook_events を共用、INSERT OR IGNORE 相当)
    const before = this.sql.exec(
      `SELECT 1 FROM webhook_events WHERE event_id = ?`, eventId,
    ).toArray();
    if (before.length > 0) {
      const cur = this.sql.exec(
        `SELECT balance FROM consultation_purchased WHERE app_user_id = ?`, appUserId,
      ).toArray();
      return {
        status: 200,
        body: { balance: cur.length > 0 ? cur[0].balance : 0, alreadyProcessed: true },
      };
    }
    this.sql.exec(
      `INSERT INTO webhook_events (event_id, received_at, event_type, app_user_id, entitlement_id)
       VALUES (?, ?, ?, ?, ?)`,
      eventId, now, 'NON_RENEWING_PURCHASE', appUserId, null,
    );
    this.sql.exec(
      `INSERT INTO consultation_purchased (app_user_id, balance, updated_at)
       VALUES (?, ?, ?)
       ON CONFLICT(app_user_id) DO UPDATE SET balance = balance + ?, updated_at = ?`,
      appUserId, amount, now,
      amount, now,
    );
    const after = this.sql.exec(
      `SELECT balance FROM consultation_purchased WHERE app_user_id = ?`, appUserId,
    ).toArray();
    return { status: 200, body: { balance: after.length > 0 ? after[0].balance : amount } };
  }

  // ── /fortune-reading-get ──
  //
  // Horo「今日の占い」の 1 日 1 回固定キャッシュを read-only で参照。
  // (appUserId, local_date, category, lang) が見つかれば {found:true, reading, advice, score}、
  // 無ければ {found:false} を 200 で返す (404 にせず、ハンドラ分岐を簡素化)。
  async _fortuneReadingGet({ appUserId, localDate, category, lang = 'ja' }) {
    if (typeof appUserId !== 'string' || !appUserId) {
      return { status: 400, body: { error: 'invalid_app_user_id' } };
    }
    if (typeof localDate !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(localDate)) {
      return { status: 400, body: { error: 'invalid_local_date' } };
    }
    if (typeof category !== 'string' || !category) {
      return { status: 400, body: { error: 'invalid_category' } };
    }
    if (typeof lang !== 'string' || !lang) {
      return { status: 400, body: { error: 'invalid_lang' } };
    }
    const rows = this.sql.exec(
      `SELECT reading, advice, score FROM fortune_readings
       WHERE app_user_id = ? AND local_date = ? AND category = ? AND lang = ?`,
      appUserId, localDate, category, lang,
    ).toArray();
    if (rows.length === 0) {
      return { status: 200, body: { found: false } };
    }
    return {
      status: 200,
      body: {
        found: true,
        reading: rows[0].reading,
        advice: rows[0].advice,
        score: rows[0].score,
      },
    };
  }

  // ── /fortune-reading-set ──
  //
  // Horo「今日の占い」を保存。(appUserId, local_date, category, lang) は ON CONFLICT DO NOTHING
  // で初回勝ち (= プロフィール変更や並行リクエストで再生成されない)。
  // 毎回 14 日より古い行を cleanup (テーブル肥大化防止)。
  async _fortuneReadingSet({ appUserId, localDate, category, lang = 'ja', reading, advice, score, now = Date.now() }) {
    if (typeof appUserId !== 'string' || !appUserId) {
      return { status: 400, body: { error: 'invalid_app_user_id' } };
    }
    if (typeof localDate !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(localDate)) {
      return { status: 400, body: { error: 'invalid_local_date' } };
    }
    if (typeof category !== 'string' || !category) {
      return { status: 400, body: { error: 'invalid_category' } };
    }
    if (typeof lang !== 'string' || !lang) {
      return { status: 400, body: { error: 'invalid_lang' } };
    }
    if (typeof reading !== 'string') {
      return { status: 400, body: { error: 'invalid_reading' } };
    }
    if (typeof advice !== 'string') {
      return { status: 400, body: { error: 'invalid_advice' } };
    }
    if (typeof score !== 'number' || !Number.isInteger(score)) {
      return { status: 400, body: { error: 'invalid_score' } };
    }
    // 14日より古い行を cleanup (YYYY-MM-DD は辞書順比較で OK)
    const cleanupBefore = new Date(now - 14 * 86400_000).toISOString().slice(0, 10);
    this.sql.exec(`DELETE FROM fortune_readings WHERE local_date < ?`, cleanupBefore);
    // ON CONFLICT DO NOTHING: 同一 (user, date, category, lang) は最初に書いた者勝ち。
    // 並行リクエスト (2 端末同時 fetch 等) でも結果は安定。
    this.sql.exec(
      `INSERT INTO fortune_readings
         (app_user_id, local_date, category, lang, reading, advice, score, generated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT(app_user_id, local_date, category, lang) DO NOTHING`,
      appUserId, localDate, category, lang, reading, advice, score, now,
    );
    return { status: 200, body: { ok: true } };
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
      '/integrity-nonce-create': () => this._integrityNonceCreate(body),
      '/integrity-nonce-consume': () => this._integrityNonceConsume(body),
      '/account-purge': () => this._accountPurge(body),
      '/consultation-credit-get': () => this._consultationCreditGet(body),
      '/consultation-credit-bump': () => this._consultationCreditBump(body),
      '/consultation-purchased-get': () => this._consultationPurchasedGet(body),
      '/consultation-purchased-spend': () => this._consultationPurchasedSpend(body),
      '/consultation-credit-grant': () => this._consultationCreditGrant(body),
      '/fortune-reading-get': () => this._fortuneReadingGet(body),
      '/fortune-reading-set': () => this._fortuneReadingSet(body),
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
