/**
 * Apple App Attest 用 Durable Object (SQLite-backed)。
 *
 * 設計 v1.8 §6.1 に従い、1 instance (`idFromName('global')`) に 3 表を集約:
 *   - attestations: 端末ごとの公開鍵 + counter
 *   - challenges:   server 発行 challenge の強整合管理 (one-time use)
 *   - user_quota:   per-user rate limit (Layer C、Free=5/日 Pro=100/日)
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
