# Play Integrity サーバー検証 設計ドキュメント

**ステータス**: 設計 v0.7 (2026-05-19、S4 完成 — DO `integrity_nonces` + `/auth/integrity/challenge` + middleware OS 経路分岐、worker 121/121 PASS、S5 Flutter 実装着手準備完了)
**対象**: Cloudflare Worker `solara-api` の `/auth/integrity/*` + `/protected/*` middleware の Android 経路
**前提**: `project_solara_launch_checklist.md` Phase 1 認証ミドルウェア + Phase 2 Flutter クライアント
**関連**:
- `app_attest_design.md` v3.0 (iOS 側、Apple App Attest)
- `revenuecat_webhook.md` v2.2 (RC エンタイトルメント検証 middleware、Play Integrity 統合後も互換)
- `project_solara_security_principles.md` 原則 1〜3
- `../../docs/app_development_lessons.md` §1.3 ケーススタディ + §5.6 鍵交換ハイブリッド方式 + §5.7 設計と公式 UI 乖離

## 変更履歴

### v0.7 (2026-05-19、S4 完成 — DO + endpoint + middleware 統合)
- **DO `AttestationState` に `integrity_nonces` 表追加** (`src/auth/attestation_state.js`):
  - schema: `nonce_id TEXT PRIMARY KEY, nonce_b64 TEXT NOT NULL, expires_at INTEGER NOT NULL, consumed_at INTEGER` + `idx_integrity_nonces_expires`
  - 既存 SQLite-backed DO に CREATE TABLE IF NOT EXISTS で追加 (migration 不要)
  - `_integrityNonceCreate({nonceId, nonceB64, expiresAt})` + `_integrityNonceConsume({nonceId, now})` API 追加
  - 既存 `_challengeConsume` と同じ SELECT WHERE consumed_at IS NULL → UPDATE consumed_at の 2 statement パターンを踏襲
  - dispatch に `/integrity-nonce-create` + `/integrity-nonce-consume` 追加
- **`/auth/integrity/challenge` POST endpoint 実装** (`src/index.js`):
  - `handleIntegrityChallenge(env, origin)` で 32B random nonce 生成 → 標準 base64 → DO INSERT (TTL 300s)
  - 返却: `{nonceId, nonce(base64), ttlSec}`
- **`protectedMiddleware` OS 経路分岐** (`src/index.js`):
  - ヘッダー判定: `X-AppAttest-KeyId` → iOS、`X-PlayIntegrity-Token` → Android、両方 → 400 `both_attest_headers`、両欠落 → 401 `missing_attestation_headers`
  - 既存 iOS ロジックを `verifyAppleAssertionFlow(request, env, payloadBytes, fail)` に関数抽出
  - 新規 `verifyPlayIntegrityRoute(request, env, fail)` で `verifyPlayIntegrityFlow` を呼出、DO consume を注入関数で渡す
  - 共通: body 取得 (request.clone().arrayBuffer()) → entitlement (RC) → uid binding (Step 12、Android のみ `clientData.uid === body.__appUserId`) → quota
  - quota key は経路依存: iOS=`keyId` / Android=`play:${uid}` (App Attest 端末 binding は強、Play Integrity は uid binding でしか縛れないため別 namespace)
  - enforcement は OS 別独立 (App Attest と Play Integrity の roll-out 差を吸収)
- **wrangler.toml に Play Integrity vars 追加**:
  - `PLAY_INTEGRITY_ENFORCEMENT = "log_only"` (初期値、Flutter Android 実装 + 1 週間モニタ後に `enforced` 切替)
  - `PLAY_INTEGRITY_NONCE_TTL_SEC = "300"`
  - `ANDROID_PACKAGE_NAME = "com.solodevlab.solara"`
  - `ANDROID_CERT_SHA256_ALLOWLIST = ""` (空、S5 で実機 cert 採取後に設定)
- **テスト 14 ケース追加 (合計 121 PASS)**: `test/integrity_endpoints.test.js`
  - `handleIntegrityChallenge`: 正常系 + base64 形式検証 (URL-safe ではない `=` パディング) + uniqueness + DO エラー応答 + TTL env 上書き
  - `getPlayIntegrityEnforcement`: env 解釈 + App Attest と独立性
  - `extractAppUserId`: body parse の defensive ケース
  - DO 単体テストは Cloudflare runtime 依存のため Node から直接 import せず、`env.ATTESTATION_DO.fetch` を mock する既存パターン (revenuecat_webhook.test.js) を踏襲
- **bundle**: gzip 171.89 → **173.99 KiB** (+2.10 KiB、middleware OS 分岐 + endpoint 追加分。Workers Free 1MB に対し残 83%)
- **§13 を S5 着手前提に書き換え**

### v0.6.1 (2026-05-19、S4 前最新仕様再確認 — patch、内容追加のみ)
S4 着手前にオーナーから「最新情報で心配点点検」依頼。Cloudflare Durable Object + Play Integrity API 公式の最新仕様を再確認、以下を確証:

- **DO migration 不要**: 既存 `AttestationState` は `new_sqlite_classes` で SQLite-backed 化済。`CREATE TABLE IF NOT EXISTS integrity_nonces` で第 6 表追加するだけ
- **`integrity_nonces.nonce_b64` 選択理由を §5 に明記**: 既存 `challenges` 表は BLOB だが Play Integrity の nonce は plugin 側で base64 文字列、`consumeResult.nonceB64 === clientData.nonce` の string compare が最速。一貫性より処理効率優先 (用途が違う)
- **Play Integrity 2026 変更**: ① minSdk 23 (Solara 31 で余裕) ② `showDialog` 経路を `IntegrityManager` 側に移動 (Solara は使わない、Pro UX 強化の将来課題) ③ GET_INTEGRITY / GET_STRONG_INTEGRITY remediation dialog (v1.5.0+) は不要 (= Pro 未取得時は単に「Pro 機能オフ」)
- **Workers SQLite storage billing (2026-01-07 開始)**: Solara nonce 容量 <1MB のため料金影響実質ゼロ
- **DO sequential write 保証**: Workers input gate により default で同 DO への requests は順次処理、明示的トランザクション不要。one-time consume は SELECT WHERE consumed_at IS NULL → UPDATE consumed_at の 2 statement で完結
- **`/auth/integrity/challenge` DoS 耐性**: `default` rate limit bucket (30/min/IP) + `_integrityNonceCreate` で `DELETE FROM integrity_nonces WHERE expires_at <` を毎回実施で問題なし
- **Buffer / btoa / performance.now / nodejs_compat**: 既存 worker で動作確認済、S3 で実証
- **既存 `protectedMiddleware` が完璧な手本**: Step 1-6 (DO 取得 → body 取得 → 検証 → signCount bump → entitlement → quota) を Play Integrity 経路にも踏襲

S4 の設計は v0.6 のまま、新規発見はゼロ。実装に進める状態。

### v0.6 (2026-05-19、S3 本実装完成)
- **`verifyPlayIntegrityFlow(request, env, consumeNonce)` v1.0 実装** (`src/auth/play_integrity.js` +260 行)
  - Step 2-11 を一括検証 (Step 5 DO consume は注入関数で抽象化、S4 で実 DO 呼出に置換)
  - 全 11 種の失敗 error code を返す: `missing_token` / `missing_clientdata` / `missing_nonceid` / `clientdata_malformed` / `clientdata_nonce_invalid` / `clientdata_uid_invalid` / `clientdata_ts_invalid` / `client_clock_drift` / `nonce_consume_failed` (任意 detail) / `nonce_mismatch` / `decode_failed` / `payload_invalid` / `payload_request_details_missing` / `requesthash_mismatch` / `token_ts_invalid` / `token_ts_drift` / `package_mismatch` / `app_not_recognized` (detail=verdict 値) / `app_package_mismatch` / `cert_not_allowlisted` / `device_verdict_empty` / `device_integrity_missing`
  - 成功時は `{ok:true, payload, uid}` を返却 (Step 12 = uid と body.__appUserId 一致確認は middleware 側)
  - `ANDROID_CERT_SHA256_ALLOWLIST` env (CSV) で cert allowlist を制御、空なら check skip (log_only 期間で実機 cert 採取まで)
  - 標準 base64 (RFC 4648 §4、`=` パディング) で SHA-256 を計算: `btoa(String.fromCharCode(...new Uint8Array(crypto.subtle.digest('SHA-256', clientDataBytes))))`
- **テスト 19 ケース追加 (合計 28、全 PASS)**: happy path + 18 失敗パス。clientData 欠落 / 改竄 / ts drift / nonce mismatch / requestHash mismatch / token ts drift / package mismatch / verdict 3 パターン (UNRECOGNIZED_VERSION / 空配列 / MEETS_DEVICE_INTEGRITY 不在) / cert allowlist mismatch + match + skip
- **bundle 計測**: gzip 171.76 → 171.89 KiB (+0.13 KiB、本実装ロジック追加分、Workers Free 1MB 残 83% 維持)
- Worker 全テスト 79 → 107 PASS (S2 9 + S3 19 = 28 新規追加)
- **§13 を S4 着手前提に書き換え**: DO `integrity_nonces` 表 + `/auth/integrity/challenge` + middleware 統合

### v0.5 (2026-05-19、S3 前最終チェック — 公式 verdict 仕様反映)
S3 着手前に最新の公式 Android Developer docs (`/google/play/integrity/standard` + `/verdicts`) を読み直して 8 件の重要訂正を反映:
- **🔴 `timestampMillis` は STRING 型** (例 `"1675655009345"`): §4 Step 10 で `Number(payload.requestDetails.timestampMillis)` 明示変換必須。JS の `-` 演算子は coerce するが、`Math.abs(now - String)` を意図せず動作させるのは fragile
- **🔴 `versionCode` も STRING** (例 `"42"`): §8 payload schema 記載修正、必要なら `parseInt` で扱う
- **🔴 `appRecognitionVerdict` は 3 値** (PLAY_RECOGNIZED / UNRECOGNIZED_VERSION / UNEVALUATED): §4 Step 11 で PLAY_RECOGNIZED 以外を明示拒否、UNEVALUATED は端末側問題のため log_only 期間中に検出
- **🔴 `deviceRecognitionVerdict` は空配列 `[]` 可能性あり** (= 端末攻撃検知): §4 Step 11 で `Array.isArray(...) && length > 0` を明示
- **🔴 `environmentDetails` は OPTIONAL** (Play Console で opt-in 必須): defensive parse、未存在で 401 にしない (v0.5 では使わない、将来 Pro 機能で参照)
- **🔴 Standard の自動 replay 保護は Google decode API 経由でのみ有効**: Self-managed key を使う Solara では DO `integrity_nonces` consume が **必須** (= v0.4 設計と整合、改めて明記)
- **🟢 R8 概算解決**: 公式 docs で「Self-managed: ... You must update your backend server logic to use the keys to decrypt responses」と明記、Self-managed は decode layer (request 種別非依存) と確証。**実機 token での最終確認は S5 で維持** (実装ミスのリスクは残る)
- **Standard vs Classic payload 差分確認**: `requestDetails.requestHash` (Standard) vs `requestDetails.nonce` (Classic) のみ。他は完全同一 (= v0.4 設計と整合)
- **test fixture 修正**: `SAMPLE_PAYLOAD.requestDetails.timestampMillis` を `Date.now()` (number) → `String(Date.now())` (string) に変更、実 token 仕様と一致

### v0.4 (2026-05-19、S2 完了 — R1/R6/R7 解決)
- **R6 ✅ 解決**: jose v6.2.3 追加で bundle gzip **+11.95 KiB (+7.5%、171.76 KiB)**。Workers Free 1MB 制限 (gzip) に対し残 83%。v0.3 想定 24% より大幅に少 (= jose の tree-shaking 良好)
- **R7 ✅ 解決**: base64 DER SPKI verification key を `crypto.subtle.importKey('spki', verBytes, {name:'ECDSA',namedCurve:'P-256'}, false, ['verify'])` で正常 import 確証。AES-256 raw も `importKey('raw', encBytes, {name:'AES-KW'}, ...)` で問題なし
- **R1 ✅ 概算解決**: Node.js (`node --test`) 計測で平均 1.73ms / 最大 4.32ms (warmup 後)。Workers Free 10ms CPU 制限に対し十分余裕。**確証はステージング deploy 後の本番計測**
- **`src/auth/play_integrity.js` 骨格追加**: `diagnoseKeys(env)` + `decodeIntegrityToken(token, env)` + jose v6 import (compactDecrypt / compactVerify / importSPKI)。S3 で `verifyPlayIntegrityFlow(request, env, body)` に拡張
- **`test/play_integrity.test.js` 追加**: 9 ケース全 PASS (R7 4 + decode pipeline 4 + R1 概算 1)
- **R8 残置**: Self-managed key が Standard 応答に適用されるかは実機採取 token が必要 → S5 (Flutter Android 実装) で `/auth/integrity/decode-test` を実機 token で叩いて確証

### v0.3 (2026-05-19、R4 解決 — Classic→Standard アーキテクチャ訂正)
- **🔴 Q1 訂正: Classic request → Standard request**: `app_attest_integrity` v1.0.0 は `StandardIntegrityManager` 専用実装と判明。Classic 用 API は提供されない (`androidPrepareIntegrityServer(int cloudProjectNumber)` warmup + `verify({clientData})` per request)
- **Binding 方式変更**: payload の `requestDetails.nonce` 一致確認 → `requestDetails.requestHash == base64(SHA-256(clientData))` 一致確認 (Standard 形式)
- **`clientData` 埋込ハイブリッド**: README で推奨される「server-issued challenge を clientData JSON に埋め込み + nonce TTL 2-5min」を採用 = DO `integrity_nonces` 表 + `/auth/integrity/challenge` endpoint は維持 (one-time consume による replay 防止)
- **§4 検証 step 更新**: Step 6/7 を Standard payload (requestHash) + clientData parse + DO consume の 3 段に再構成
- **§7 Flutter 側 API 更新**: `prepareTokenProvider(cloudProjectNumber)` を起動時 1 回、`verify(clientData: jsonEncode({nonce, uid, ts}))` を `/protected/*` 呼出ごと
- **新 R8 追加**: Standard request 応答に Self-managed key (Classic 用 UI で設定) が適用されるか実機 token で確証 (= R7 の前提条件)
- **R5 撤回**: Classic payload 仕様は S2 範囲外 (Standard 採用で不要)
- **base64 形式注意**: `sha256HashBase64` は **標準 base64 (RFC 4648 §4)**、URL-safe ではない、`=` パディングあり

### v0.2 (2026-05-19、S1 オーナー作業完了)
- §6 Self-managed key 管理を **実際の Play Console フローに更新** (ハイブリッド方式: RSA 鍵ペア生成 → public.pem upload → 暗号化応答鍵 download → 復号)
- §6.1 verification key 形式を **PEM 想定 → base64 (DER SubjectPublicKeyInfo) に訂正** (実 UI で確認、`crypto.subtle.importKey('spki', ...)` で扱う)
- §11 オーナー作業を全 7 項目チェック付きに展開、完了マークと作業時の TIPS を追加
- §10 R 項目: R2 (Play Console 鍵取得) を ✅ 解決済、R5 (Classic payload 仕様) を「公式 doc 再読 + S2 で確証」に維持

### v0.1 (2026-05-19、S1 完了)
- Q1-Q4 オーナー判断確定 (Classic + Self-managed + DEVICE + PLAY_RECOGNIZED)
- R1-R6 を「実装中 / 計測後確定」3 分類で明示
- 10-step 検証フロー + DO スキーマ追加 + middleware 統合 + 段階リリース機構 + 6 セッションロードマップ

## 0. なぜ Play Integrity か

Solara は JP 公開で iOS/Android 両ストア配信を予定。Apple App Attest は iOS でしか動かないため、Android 端末からの `/protected/*` 呼出は現状すべて bypass されて Gemini を叩ける状態。Apple 3.2.2 + Play ポリシー違反リスクに加え、Pro 機能ゲートが Android で実質効かない。

Apple App Attest と対称的な検証層を Android にも置く = **Play Integrity API v1 Classic request + Self-managed key + Workers 自前 decode**。

## 1. オーナー判断 確定 (Q1-Q4)

| # | 項目 | 確定 | 理由 |
|---|---|---|---|
| Q1 | request 種別 | **Standard request (ハイブリッド)** ※v0.3 訂正 | `app_attest_integrity` v1.0.0 が Standard 専用。`clientData` JSON に server-issued nonce を埋込み + DO で one-time consume = Classic 同等の replay 防止を Standard 上で実装 |
| Q2 | decode 方式 | **Self-managed key (Workers 自前 JWE A256KW + JWS ES256 decode)** | Google サーバー decode は ① 障害連鎖 ② 100-300ms レイテンシ ③ 10k/day quota 消費。Apple App Attest と同じ「Workers 完結」哲学。**前提: Self-managed key が Standard 応答にも適用される (R8 で確証)** |
| Q3 | deviceIntegrity 閾値 | **`MEETS_DEVICE_INTEGRITY` 必須** | minSdk 31 (Android 12) 下限維持。STRONG は「セキュリティパッチ 1 年以内」要件で古いパッチ端末を追加で弾き、サポート負荷増 |
| Q4 | appIntegrity 閾値 | **`PLAY_RECOGNIZED` 必須** | サイドロード排除、Pro 機能ゲートの基本要件 |

## 2. アーキテクチャ概要 (v0.3 Standard 方式)

```
Flutter 起動時 (Android のみ、1 回)
    │ app_attest_integrity.androidPrepareIntegrityServer(cloudProjectNumber)
    │ → StandardIntegrityTokenProvider 取得 (warmup、~1 時間有効)
    ▼

Flutter /protected/* 呼出ごと (Android)
    │
    │ ① POST /auth/integrity/challenge
    ▼
Worker /auth/integrity/challenge
    └─ DO IntegrityNonce 表に random 32B INSERT (TTL 5min)
       → {nonceId, nonce} を base64 で返却
    │
    │ ② nonce 受領
    ▼
Flutter
    │ clientData = jsonEncode({nonce, uid: appUserId, ts: now})
    │ token = app_attest_integrity.verify(clientData: clientData)
    │ → 内部で requestHash = base64(sha256(clientData)) 計算
    │   StandardIntegrityTokenProvider.request(requestHash) で token 取得
    │   token = JWE A256KW( JWS ES256(payload) )  ※Self-managed key 前提
    │
    │ ③ POST /protected/* with:
    │   X-PlayIntegrity-Token: <token>
    │   X-PlayIntegrity-ClientData: <clientData JSON>
    │   X-PlayIntegrity-NonceId: <nonceId>
    ▼
Worker /protected/* middleware (Android 経路)
    ├─ X-PlayIntegrity-ClientData parse → {nonce, uid, ts}
    ├─ ts ±5min 確認 (client clock)
    ├─ DO IntegrityNonce から nonceId で nonce を consume (one-time)
    ├─ consumed nonce == clientData.nonce 一致
    ├─ JWE A256KW decode (Worker Web Crypto)
    ├─ JWS ES256 verify (Google ECDSA P-256 公開鍵)
    ├─ payload.requestDetails.requestHash == base64(sha256(clientData)) 一致 (binding)
    ├─ payload.requestDetails.timestampMillis ±5min 確認 (server clock)
    ├─ payload.requestDetails.requestPackageName == "com.solodevlab.solara"
    ├─ payload.appIntegrity.appRecognitionVerdict == "PLAY_RECOGNIZED"
    ├─ "MEETS_DEVICE_INTEGRITY" ∈ payload.deviceIntegrity.deviceRecognitionVerdict
    ├─ clientData.uid == body.__appUserId 一致 (token swap 防止)
    └─ RevenueCat entitlement lookup → Free/Pro quota (App Attest と完全共通)
```

iOS は引き続き Apple App Attest 経路。**Flutter 側 OS 判定で片方のみ動作**。

## 3. ファイル構成 (実装後の最終形)

```
apps/solara/worker/src/auth/
  play_integrity.js        # 新規 — token decode + verdict 評価 (~250 行)
  google_play_keys.js      # 新規 — Self-managed key 定数 + key rotation 入口 (~60 行)
  integrity_state.js       # 新規 OR attestation_state.js に統合
  jose_wrapper.js          # 新規 — jose v6 で JWE/JWS の Solara 用 wrapper (~50 行)

apps/solara/lib/utils/
  app_attest_client.dart   # 既存 — iOS/Android 両 OS 対応に拡張 (rename 検討: IntegrityClient)

apps/solara/docs/
  play_integrity_design.md # 本ドキュメント
```

## 4. Worker 検証フロー (12 step、Standard 方式 v0.3)

### Step 1: Client → Worker `/auth/integrity/challenge` (POST)
- Worker: `crypto.getRandomValues(Uint8Array(32))` で nonce 生成 (32 random bytes)
- DO `integrity_nonces` 表に INSERT (`nonce_id = uuidv4`, `nonce_bytes`, `expires_at = now + 300_000ms`)
- 返却: `{ nonceId: <uuid>, nonce: <base64 32B>, ttlSec: 300 }`
- Flutter は `nonce` を `clientData` JSON に埋め込んで `verify(clientData: ...)` に渡す

### Step 2: Worker `/protected/*` middleware で token + clientData + nonceId 受領
- HTTP header `X-PlayIntegrity-Token: <jwe.jws compact form>`
- HTTP header `X-PlayIntegrity-ClientData: <utf-8 JSON string of clientData>`
- HTTP header `X-PlayIntegrity-NonceId: <uuid>` (DO 検索キー)

### Step 3: clientData parse + 形式検証
- `X-PlayIntegrity-ClientData` を UTF-8 JSON parse
- 期待 schema: `{ nonce: string, uid: string, ts: number }` (将来拡張可能)
- 必須キー欠落なら 401 + `clientdata_malformed`

### Step 4: clientData.ts ±5min 確認 (client clock drift 検出)
- `Math.abs(now - clientData.ts) < 300_000` (5 分窓)
- 失敗なら 401 + `client_clock_drift` (= 端末時刻偽装の早期検知)

### Step 5: DO nonce consume (one-time use、Apple challenge と同様)
- DO `integrity_nonces` から `nonceId` で SELECT (expired/consumed なら 401 + `nonce_invalid`)
- `clientData.nonce` と DO の `nonce_bytes` (base64) を一致確認 → 失敗なら 401 + `nonce_mismatch`
- `consumed_at` をマーク

### Step 6: JWE A256KW decode (encryption key で復号)
- `jose.compactDecrypt(jweToken, ENCRYPTION_KEY)` で plaintext (= JWS compact) を取り出す
- `ENCRYPTION_KEY` は Play Console > App integrity > Settings からダウンロードした AES-256 鍵 (Base64)
- Workers 内で `crypto.subtle.importKey('raw', keyBytes, 'AES-KW', ...)` で読み込み

### Step 7: JWS ES256 verify (Google ECDSA 公開鍵で署名検証)
- `jose.compactVerify(jwsToken, VERIFICATION_KEY)` で payload を取り出す
- `VERIFICATION_KEY` は Play Console から取得した ECDSA P-256 公開鍵 (base64 DER SPKI、v0.2 §6.1)
- Workers 内で `crypto.subtle.importKey('spki', base64Decode(key), {name: 'ECDSA', namedCurve: 'P-256'}, true, ['verify'])` で読み込み

### Step 8: payload parse

🔴 **重要 (v0.5)**: `timestampMillis` と `versionCode` は **string 型** (公式 docs `/verdicts` 確証)。数値比較する場合は明示的に `Number()` 変換すること。

```json
{
  "requestDetails": {
    "requestPackageName": "com.solodevlab.solara",
    "timestampMillis": "1700000000000",                  // ⚠️ string!
    "requestHash": "<base64(sha256(clientData))>"        // Standard 形式 (Classic の nonce ではない)
  },
  "appIntegrity": {
    "appRecognitionVerdict": "PLAY_RECOGNIZED",          // 3 値: PLAY_RECOGNIZED / UNRECOGNIZED_VERSION / UNEVALUATED
    "packageName": "com.solodevlab.solara",
    "certificateSha256Digest": ["..."],
    "versionCode": "1"                                   // ⚠️ string!
  },
  "deviceIntegrity": {
    "deviceRecognitionVerdict": ["MEETS_DEVICE_INTEGRITY", "MEETS_BASIC_INTEGRITY", ...]
    // 可能値: MEETS_DEVICE_INTEGRITY / MEETS_VIRTUAL_INTEGRITY / MEETS_BASIC_INTEGRITY / MEETS_STRONG_INTEGRITY
    // 空配列 [] = 端末攻撃検知 (root/emulator/compromised)、必ず拒否
  },
  "accountDetails": {
    "appLicensingVerdict": "LICENSED"                    // 3 値: LICENSED / UNLICENSED / UNEVALUATED
  },
  // ↓ 任意フィールド (Play Console で opt-in 必須、v0.5 では参照しない)
  "environmentDetails": {                                // OPTIONAL — 未存在で 401 にしない
    "appAccessRiskVerdict": {"appsDetected": [...]},
    "playProtectVerdict": "NO_ISSUES"
  }
}
```

### Step 9: requestHash binding 確認 (Standard 方式の核)
- `expectedHash = base64.encode(sha256(utf8Bytes(clientData)))` を Worker 側で再計算 (**標準 base64 / RFC 4648 §4 / `=` パディングあり、URL-safe ではない**)
- `payload.requestDetails.requestHash === expectedHash` 必須 → 失敗なら 401 + `requesthash_mismatch`
- これにより token が `clientData` (= nonce + uid + ts) と暗号学的にバインド = 改ざん検出

### Step 10: timestamp + package 確認 (server clock + パッケージ偽装)
🔴 v0.5: `timestampMillis` は **string** なので `Number()` で明示変換:
```js
const tokenTs = Number(payload.requestDetails.timestampMillis);
if (Number.isNaN(tokenTs)) return fail(401, 'token_ts_invalid');
if (Math.abs(Date.now() - tokenTs) >= 300_000) return fail(401, 'token_ts_drift');
if (payload.requestDetails.requestPackageName !== 'com.solodevlab.solara') return fail(401, 'package_mismatch');
```

### Step 11: verdict 評価 (Q4 + Q3)
🔴 v0.5: 公式 verdict 3 値を意識した defensive チェック:
- `payload.appIntegrity?.appRecognitionVerdict === "PLAY_RECOGNIZED"` 必須 (Q4)
  - 拒否対象: `UNRECOGNIZED_VERSION` (= サイドロード) / `UNEVALUATED` (= 端末検証不能)
  - log_only 期間中はカウント記録して傾向把握
- `payload.appIntegrity?.packageName === "com.solodevlab.solara"` 必須
- `Array.isArray(payload.appIntegrity?.certificateSha256Digest)` で Play 配信用 SHA-256 を allowlist 比較 (= 自前署名・サイドロード排除)
- `Array.isArray(payload.deviceIntegrity?.deviceRecognitionVerdict) && payload.deviceIntegrity.deviceRecognitionVerdict.includes("MEETS_DEVICE_INTEGRITY")` 必須 (Q3)
  - 空配列 `[]` = 端末攻撃検知 (root/emulator/未署名 ROM) → 拒否
- `environmentDetails` は v0.5 では参照しない (Play Console opt-in 必須、将来 Pro 機能で `playProtectVerdict` を弱信号として参照する可能性)

### Step 12: uid binding + entitlement / quota (RevenueCat 連動)
- `clientData.uid === body.__appUserId` 一致確認 (= token swap 防止)
- DO `user_entitlements` lookup → Pro/Free quota 切替
- App Attest 経路と middleware ロジック共通化 (= 統合 middleware で OS 判定 + 検証関数だけ切替)

## 5. Durable Object スキーマ追加

既存 `AttestationState` DO に 1 表追加 (1 instance 集約継続、migration 不要):

```sql
CREATE TABLE IF NOT EXISTS integrity_nonces (
  nonce_id TEXT PRIMARY KEY,
  nonce_b64 TEXT NOT NULL,           -- 標準 base64 (RFC 4648 §4、=パディングあり) 32B → 44 char
  expires_at INTEGER NOT NULL,        -- unix ms
  consumed_at INTEGER                 -- one-time consume marker (NULL = 未使用)
);
CREATE INDEX IF NOT EXISTS idx_integrity_nonces_expires ON integrity_nonces(expires_at);
```

API (App Attest `challenges` と並列):
- `POST /integrity-nonce-create body: {nonceId, nonceB64, expiresAt}`
- `POST /integrity-nonce-consume body: {nonceId, now} → {nonceB64} (consumed_at マーク) or 404`

注意: v0.2 では BLOB を提案したが、v0.3 では JSON シリアライズ容易性とログ可読性のため TEXT (base64) で保管。32B × ~10k/day × 5min TTL = ピーク 2-3MB なので容量は問題なし。

🔴 v0.6.1 補足 — TEXT 選択理由 (既存 `challenges` BLOB との不一致):
- 既存 `challenges` (App Attest) は raw bytes 用途 (= challenge → SHA-256(challengeHash) → attest) で BLOB が自然
- 新規 `integrity_nonces` (Play Integrity) は **base64 string 用途** (= plugin が string ↔ Worker が string compare) で TEXT が自然
- 用途が違うため一貫性犠牲は許容、処理効率優先
- `consumeResult.nonceB64 === clientData.nonce` が単純 string equality でも O(1)、BLOB → base64 変換のオーバーヘッドなし

## 6. Self-managed key 管理

### 6.1 key 種別 (v0.2 実 Play Console 確認後)
| 鍵 | 形式 | 取得値 | Worker 側 import |
|---|---|---|---|
| Encryption key (DECRYPTION_KEY) | AES-256 base64 | 44 char (末尾 `=` パディング 1) | `crypto.subtle.importKey('raw', base64Decode(key), 'AES-KW', ...)` |
| Verification key (VERIFICATION_KEY) | ECDSA P-256 公開鍵 **base64 (DER SubjectPublicKeyInfo)** | 124 char (末尾 `=` パディング 1) | `crypto.subtle.importKey('spki', base64Decode(key), {name:'ECDSA',namedCurve:'P-256'}, ...)` |

🔴 **v0.1 からの訂正**: Verification key は PEM 形式と想定していたが、**実際の Play Console は base64 (DER SubjectPublicKeyInfo) で出力**。PEM ヘッダー (`-----BEGIN PUBLIC KEY-----`) は付かない。Workers Web Crypto では `format: 'spki'` で扱う (PEM の場合は手動で base64 decode + headers strip が必要だったが不要に)。

両方 Play Console > **アプリの完全性 > Play Integrity API の設定 > クラシック リクエスト > レスポンスの暗号化 > 鉛筆アイコンで編集 > 「レスポンスの暗号鍵を自分で管理、ダウンロードする」を選択** から取得。

### 6.2 取得手順 (Self-managed key、ハイブリッド方式)

Google は AES-256 + ECDSA 鍵を直接ダウンロードさせず、クライアント側で生成した RSA 公開鍵で暗号化したファイルを返す (= 「Google サーバー保管中の漏洩を排除する」追加層、`app_development_lessons.md` §5.6 ハイブリッド方式)。

```powershell
# Step 1: クライアント側で RSA 2048-bit 鍵ペア生成
mkdir C:\Users\<user>\solara-integrity-keys
cd C:\Users\<user>\solara-integrity-keys
& "C:\Program Files\Git\usr\bin\openssl.exe" genrsa -aes128 -out private.pem 2048
# → passphrase 入力 (2 回)、忘れないものをパスワードマネージャー保管

& "C:\Program Files\Git\usr\bin\openssl.exe" rsa -in private.pem -pubout -out public.pem
# → passphrase 入力 (1 回)、public.pem 451B + private.pem 1886B 生成

# Step 2: public.pem を Play Console にアップロード (UI でファイル選択)
# Play Console が暗号化応答ファイル (例: com.solodevlab.solara.enc) を自動 download
# Move-Item で作業ディレクトリに移動

# Step 3: 復号して平文鍵を取り出す
& "C:\Program Files\Git\usr\bin\openssl.exe" pkeyutl -decrypt -inkey private.pem `
  -pkeyopt rsa_padding_mode:oaep -in com.solodevlab.solara.enc -out api_keys.txt
# → passphrase 入力、api_keys.txt に
#   DECRYPTION_KEY=<44 char base64>
#   VERIFICATION_KEY=<124 char base64>

# Step 4: Worker secret に投入
cd E:\AppCreate\apps\solara\worker
npx wrangler secret put PLAY_INTEGRITY_ENCRYPTION_KEY  # DECRYPTION_KEY の右辺のみ貼り付け
npx wrangler secret put PLAY_INTEGRITY_VERIFICATION_KEY  # VERIFICATION_KEY の右辺のみ貼り付け

# Step 5: 平文鍵を削除 (= Worker 投入後は不要、Play Console から再復号可能)
Remove-Item api_keys.txt
Remove-Item com.solodevlab.solara.enc

# 保管するもの: private.pem (passphrase 暗号化済) + passphrase のみ
```

### 6.3 Workers での保管
- **Encryption key (PLAY_INTEGRITY_ENCRYPTION_KEY)**: secret 必須 (= 漏れたら任意の偽 token を作られる)
- **Verification key (PLAY_INTEGRITY_VERIFICATION_KEY)**: public 情報だが secret 管理に統一 (= 漏洩リスクなし、運用簡素化)

### 6.4 key rotation
- Play Console で key 再生成可能 (= attacker が encryption key を入手したら必須)
- rotation 手順: Play Console で「キーをダウンロード」再実行 → private.pem で復号 → `wrangler secret put` で上書き
- 既存 token は invalid 化 (= rotation 時はクライアント側も再 attest 必要)
- 平常時は **rotation 不要** (Apple Root CA と同じく長期固定で OK)

### 6.5 重要な落とし穴
- **PowerShell `>` リダイレクトは UTF-16LE になる罠**: `openssl ... > file.txt` ではなく `openssl ... -out file.txt` (openssl 自身) で ASCII 出力させる
- **OpenSSL 単体インストール不要**: Git for Windows 同梱の `C:\Program Files\Git\usr\bin\openssl.exe` で十分 (PowerShell からは `&` call operator + フルパス実行)
- **平文鍵をローカルに残さない**: `api_keys.txt` は wrangler secret 投入後即削除。Play Console から何度でも再ダウンロード + 復号可能なため、平文を残すリスク > 失うリスク
- **base64 末尾 `=` パディングは必須**: 抜くと復号失敗、必ず含めて貼り付け

## 7. Flutter 側実装 (v0.3 Standard 方式)

### 7.1 `app_attest_integrity` v1.0.0 の実 API (R4 確証済)

`app_attest_integrity` v1.0.0 (`bamlab/app_attest_integrity`) の Dart 公開 API:
```dart
class AppAttestIntegrity {
  Future<void> androidPrepareIntegrityServer(int cloudProjectNumber);  // 起動時 1 回、warmup
  Future<GenerateAttestationResponse?> iOSgenerateAttestation(String challenge);
  Future<String> verify({
    required String clientData,
    String? iOSkeyID,                 // iOS のみ必須
    int? androidCloudProjectNumber,   // Android で prepareTokenProvider 未呼出時のみ
  });
}
```

内部実装 (Android、`StandardIntegrityManager`):
1. `prepareIntegrityToken(cloudProjectNumber)` → `StandardIntegrityTokenProvider` を保持 (≈1 時間有効)
2. `verify(clientData)` 内で `requestHash = base64(sha256(clientData))` を計算 (= 標準 base64、URL-safe ではない)
3. `provider.request(requestHash)` → token (JWE A256KW(JWS ES256(payload))) を返却

### 7.2 既存 `AppAttestClient` の OS 分岐 (lib/utils/app_attest_client.dart)

```dart
// 起動時 (initialize 内、Android のみ 1 回)
if (Platform.isAndroid) {
  await _attest.androidPrepareIntegrityServer(_cloudProjectNumber);
}

// /protected/* 呼出ごと (postProtected/addHeaders 内)
if (Platform.isIOS) {
  // 既存
  final assertion = await _attest.verify(clientData: bodyJson, iOSkeyID: _keyId);
  headers['X-AppAttest-KeyId'] = _keyId!;
  headers['X-AppAttest-Assertion'] = assertion;
} else if (Platform.isAndroid) {
  // 新規 (v0.3)
  final ch = await http.post('/auth/integrity/challenge');
  final nonceId = ch['nonceId'];
  final nonce = ch['nonce'];
  final clientData = jsonEncode({
    'nonce': nonce,
    'uid': appUserId,
    'ts': DateTime.now().millisecondsSinceEpoch,
  });
  final token = await _attest.verify(clientData: clientData);
  headers['X-PlayIntegrity-Token'] = token;
  headers['X-PlayIntegrity-ClientData'] = clientData;
  headers['X-PlayIntegrity-NonceId'] = nonceId;
}
```

リネーム候補: `AppAttestClient` → `IntegrityClient`、ただし変更影響を最小化するため **本実装フェーズ後に decide** (今は API 互換維持で OS 分岐だけ追加)。

### 7.3 cloudProjectNumber の取得
- Play Console > Solara > アプリの完全性 > Play Integrity API > リンク済 Cloud project の **Cloud Project Number** (= 数字 12 桁前後)
- `--dart-define=SOLARA_GCP_PROJECT_NUMBER=<number>` で release ビルド時に注入 (= public 情報、secret 不要)

### 7.4 nonce / token ライフサイクル
- iOS: keyId は端末永続 (SharedPreferences、1 端末 1 keyId)
- Android: nonce は呼出ごと使い捨て (毎回 `/auth/integrity/challenge`)、token も毎回新規 (Standard `provider.request(requestHash)` は per-call)

iOS は起動時 1 回 attest、Android は **毎回 token 取得 + nonce 取得**。これは Play Integrity Standard の仕様 (短命 token + Google サーバー側 quota) で、Apple App Attest との大きな違い。

### 7.5 quota への影響
Solara `/protected/*` 1 呼出につき:
- iOS: assertion 生成 (端末ローカル、Apple サーバー不要)
- Android: token 生成 (Google サーバー 1 req 消費、Standard request は **10k/day quota 共通**)
- Standard は warmup の `prepareTokenProvider` だけは追加 1 req/起動 (≈ DAU 数と等価)

Free 5/日、Pro 100/日想定なら Android DAU 1500 × 平均 3 req (warmup + 2 protected) = 4,500/day → 10k quota 内で十分余裕。ただし Pro ユーザーが 100/日上限まで使うと quota 圧迫リスク → R3 で実装後計測。

### 7.6 Standard の自動 replay 保護 (v0.5 補足)
公式 docs `/google/play/integrity/standard` によれば、Standard request は **Google decode API で復号する場合に限り** 自動 replay 保護がかかる (= 同 token を 2 回復号するとブランクな verdict を返す)。**Solara は Self-managed key で自前 decode するためこの保護は無効**。よって DO `integrity_nonces` での one-time consume が必須 (= v0.4 設計と整合、改めて明記)。

## 8. middleware 統合 (iOS/Android 自動切替)

`apps/solara/worker/src/index.js` の `protectedMiddleware` を OS 判定で 2 経路分岐:

```js
async function protectedMiddleware(request, env) {
  // ... (mode 評価、body 取得)

  const isApple = !!request.headers.get('X-AppAttest-KeyId');
  const isAndroid = !!request.headers.get('X-PlayIntegrity-Token');

  if (isApple && isAndroid) return fail(400, 'both_attest_headers');
  if (!isApple && !isAndroid) return fail(401, 'missing_attest_headers');

  // 経路 1: iOS App Attest (既存)
  if (isApple) {
    const r = await verifyAppleAssertionFlow(request, env, payloadBytes);
    if (r.error) return fail(r.status, r.error);
  }

  // 経路 2: Android Play Integrity (新規)
  if (isAndroid) {
    const r = await verifyPlayIntegrityFlow(request, env, payloadBytes);
    if (r.error) return fail(r.status, r.error);
  }

  // 共通: entitlement lookup + quota (RevenueCat 連動、両 OS 同じ)
  // ...
}
```

## 9. 段階リリース機構

App Attest と独立した env var で制御:
```
PLAY_INTEGRITY_ENFORCEMENT = "disabled" | "log_only" | "enforced"
```
- 初期値 `log_only` (Flutter Android 実装 → TestFlight Android テスト → 1 週間モニタ → `enforced` 切替)
- App Attest と独立 = iOS は enforced、Android は log_only、というスケジュール差を吸収

## 10. R 項目 (実装中 / 実装後計測)

| # | 項目 | 解決時期 | 状態 |
|---|---|---|---|
| R1 | Workers Web Crypto JWE A256KW + JWS ES256 decode のパフォーマンス (Workers Free 10ms 制限内?) | 実装直後 (S2 で minimal Worker 検証) | ✅ **概算解決 2026-05-19** (Node.js 平均 1.73ms / 最大 4.32ms、Workers 制限 10ms に十分余裕。本番計測はステージング deploy 後) |
| R2 | Play Console > アプリの完全性 > Play Integrity API > クラシック リクエスト > レスポンスの暗号化 > 自分で管理 切替 + 鍵取得 (オーナー作業) | S2 着手前 | ✅ **解決 2026-05-19** (DECRYPTION_KEY 44 char + VERIFICATION_KEY 124 char、wrangler secret 投入完了) |
| R3 | Free 10k/day で Solara Android DAU 跳ね返り (実 traffic で確認) | 本番 deploy 後 1 週間モニタ | ⏳ deploy 後 |
| R4 | `app_attest_integrity` v1.0.0 の Android API + 戻り値構造 + Standard/Classic 選択肢 | S2 で GitHub ソース確認 | ✅ **解決 2026-05-19** (bamlab/app_attest_integrity v1.0.0: `StandardIntegrityManager` 専用、`verify(clientData)` 内で `requestHash=base64(sha256(clientData))` を計算 → `provider.request(requestHash)` で token 取得。Standard request 専用と判明 → Q1 訂正) |
| R5 | ~~Classic payload 仕様 (requestHash は Standard 限定、Classic では nonce のみ)~~ | ❌ **撤回** | ❌ Standard 採用で不要 (R4 解決) |
| R6 | Workers bundle 増加実測 (jose v6 追加で gzip 24% 想定が実際の値) | S2 deploy 後計測 | ✅ **解決 2026-05-19** (gzip 159.81→171.76 KiB、+7.5% で想定 24% より大幅に少。Workers Free 1MB に対し残 83%) |
| R7 | base64 (DER SubjectPublicKeyInfo) verification key の `crypto.subtle.importKey('spki', ...)` で正常 import できるか | S2 minimal worker | ✅ **解決 2026-05-19** (`test/play_integrity.test.js` 9/9 PASS、ECDSA P-256 + AES-KW 両 import 確証) |
| R8 (新規 v0.3) | Self-managed key (Classic request 用 UI で設定) が **Standard request** 応答にも適用されるか (= Workers が自前 decode できるか、Google decode API 呼び出し不要か) | 公式 docs 確認 (v0.5) | ✅ **概算解決 2026-05-19** (公式 docs で「Self-managed は decode layer、request 種別非依存」と明記)。実機 token での最終確認は S5 で維持 (実装ミスのリスク残) |

## 11. オーナー作業 (チェックリスト、2026-05-19 S1 完了)

### 11.1 Play Console 設定
- [x] **Cloud project link**: Play Console > Solara > アプリの完全性 > Play Integrity API > Cloud プロジェクトをリンク → 既存 `Solara-api` を選択
- [x] **Response encryption 切替**: クラシック リクエスト > レスポンスの暗号化 > 鉛筆アイコン > 「レスポンスの暗号鍵を自分で管理、ダウンロードする」を選択
- [x] **RSA 鍵ペア生成**: `openssl genrsa -aes128 -out private.pem 2048` + `openssl rsa -in private.pem -pubout -out public.pem` (Git for Windows 同梱の openssl で実行)
- [x] **public.pem upload**: Play Console UI で公開鍵をアップロード → 暗号化応答ファイル (com.solodevlab.solara.enc) 自動 download
- [x] **復号**: `openssl pkeyutl -decrypt -inkey private.pem -pkeyopt rsa_padding_mode:oaep -in com.solodevlab.solara.enc -out api_keys.txt` で DECRYPTION_KEY / VERIFICATION_KEY 取出
- [x] **wrangler secret 投入**: `PLAY_INTEGRITY_ENCRYPTION_KEY` (44 char) + `PLAY_INTEGRITY_VERIFICATION_KEY` (124 char)
- [x] **平文鍵削除**: `api_keys.txt` + `com.solodevlab.solara.enc` 削除、`private.pem` (passphrase 暗号化済) と passphrase のみ保管

### 11.2 残作業 (S2 以降)
- [ ] wrangler.toml に vars 追加 (S2 で実装と同時):
  ```toml
  PLAY_INTEGRITY_ENFORCEMENT = "log_only"
  PLAY_INTEGRITY_NONCE_TTL_SEC = "300"
  ANDROID_PACKAGE_NAME = "com.solodevlab.solara"
  ```
- [ ] S2-S6 実装後、`PLAY_INTEGRITY_ENFORCEMENT = "log_only"` で初回 deploy → 1 週間モニタ → `enforced` 切替
- [ ] **API quota** 初期 10k/day を確認、必要に応じて増量申請 (公開後、R3 計測結果次第)

## 12. 実装ロードマップ (S2-S6、約 6-8 セッション)

```
S1 ✅: 本設計ドキュメント完成 + Q1-Q4 確定 + R1-R6 明示
S2 ✅: R4 解決 (Standard 訂正 v0.3) + jose v6 追加 + minimal worker (R7) +
       bundle 計測 (R6) + decode pipeline 単体テスト 9/9 PASS + R1 概算解決
       (R8 は実機 token 必要 → S5 残置)
S3 🔵: auth/play_integrity.js 本実装 (Step 3-11 = clientData parse + DO consume +
       decode + verify + binding + verdict)
       + 既存 diagnoseKeys/decodeIntegrityToken をベースに verifyPlayIntegrityFlow 拡張
       + 単体テスト追加 (clientData 改竄、requestHash 不一致、verdict 不足、etc.)
S4  : DO integrity_nonces 表 (TEXT base64 形式 v0.3) +
      /auth/integrity/challenge POST 実装 (existing AttestationState DO 拡張)
      + middleware 統合 (経路分岐 + 共通フロー保持、AppAttest と非排他)
      + 単体テスト
S5  : Flutter AppAttestClient を OS 分岐対応に拡張
      + cloudProjectNumber を --dart-define で配線
      + Android 実機テスト (or Android Emulator + Play services)
      + flutter analyze + 既存 test 維持
      + 🔴 R8 確証 — 実機 token を `/auth/integrity/decode-test` に POST して
        Self-managed key で decode 成功するか確認
S6  : docs 仕上げ (deploy 手順 §13 + 運用ガイド §14)
      + launch_checklist 更新 + メモリ整理
      + オーナー作業 (Cloud Project Number 取得 + Worker vars 投入) → 本番 deploy
      + 診断 endpoint (/auth/integrity/diagnose, /auth/integrity/decode-test) を
        ENFORCEMENT==='enforced' 時に 404 化 (= 本番でデバッグ口を露出しない)
```

App Attest と同等の重さを想定 (6-8 セッション、計 15-20h)、現実績 S1+S2=2 セッション。

## 13. v0.7 から v0.8 への次タスク (S5 Flutter Android 実装 + 実機テスト)

S4 ✅ 完了。S5 のスコープ:
1. **`lib/utils/app_attest_client.dart` Android 分岐拡張**:
   - 起動時: `Platform.isAndroid` で `AppAttestIntegrity().androidPrepareIntegrityServer(_cloudProjectNumber)` を 1 回呼出 (warmup)
   - `postProtected` / `addHeaders` を OS 分岐:
     - iOS: 既存 (X-AppAttest-KeyId + X-AppAttest-Assertion)
     - Android: `/auth/integrity/challenge` で nonce 取得 → `clientData = jsonEncode({nonce, uid: appUserId, ts: now})` → `verify(clientData: ...)` で token 取得 → X-PlayIntegrity-Token / X-PlayIntegrity-ClientData / X-PlayIntegrity-NonceId をヘッダー注入
   - kDebugMode / Android Emulator は自動 bypass (実機 release のみ有効)
2. **`--dart-define=SOLARA_GCP_PROJECT_NUMBER=<number>`** で Cloud Project Number (Play Console > Solara > アプリの完全性 > リンク済 Cloud project の 12 桁) を release ビルドに注入
3. **Flutter 単体テスト**: AppAttestClient の Android 分岐 (mock 用 mock-token を返す `AppAttestIntegrity` を注入してロジック検証)
4. **Android 実機テスト**:
   - `flutter run --release` (Android device with Google Play Services + Play Store 経由配信)
   - `/protected/fortune` 呼出が 200 で通る (log_only 期間中なので token 検証失敗でも警告ログ + 通過)
   - Worker logs で「`[middleware:log_only] would block 401 ...`」が出ないことを確認 (= 検証成功)
5. **🔴 R8 最終確認**: 実機採取 token を `/auth/integrity/decode-test` に POST、Self-managed key で decode 成功 + payload が PLAY_RECOGNIZED + MEETS_DEVICE_INTEGRITY を含むことを確認
6. **🔴 cert SHA-256 採取 → allowlist 設定**: 実機 token の `appIntegrity.certificateSha256Digest` 値を `wrangler` の `ANDROID_CERT_SHA256_ALLOWLIST` に投入 (deploy 必要)
7. **設計 v0.8 にバンプ**: 実機検証結果 + R8 確証 + cert allowlist 確定値

## 関連ドキュメント

- `app_attest_design.md` (iOS 側、9 step + 案 B' ハイブリッド)
- `revenuecat_webhook.md` (RC エンタイトルメント連動、Play Integrity 経路でも同じ middleware 共通フロー)
- `apps/solara/docs/architecture.md` (将来更新時に Android セキュリティ層を追記)
