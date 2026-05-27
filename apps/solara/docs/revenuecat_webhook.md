# RevenueCat Webhook + Worker エンタイトルメント検証 設計 (v2.3)

> v2.3 (2026-05-27): 課金堅牢化 5 ステップ + 監査 7 項目を反映。
>   - Pro 同期遅延窓での購入クレジット誤消費を防ぐ **425 pro_sync_pending** 経路
>   - grace_period_expiration_at_ms の DO 保存 + MAX(expires_at, grace_expires_at) 判定
>   - event_timestamp_ms による out-of-order 厳密判定
>   - TRANSFER 旧/新 owner 判定 (transferred_from/to)
>   - SUBSCRIPTION_EXTENDED を ACTIVE に追加
>   - 未知 event を IGNORE 倒し (副作用なし)
>   - GDPR `DELETE /v1/subscribers/{id}` の三段削除 (DO + memory + RC + Apple revoke)
>   - Apple Token Revocation (Service ID + Authentication Key)
>
> 詳細は本ファイル末尾「v2.3 変更点 (2026-05-27)」セクション参照。

`launch_checklist.md` Phase 1「Webhook 受信」+「RevenueCat エンタイトルメント検証 middleware」の確定設計。`app_attest_design.md` v2.1 (App Attest) と組み合わせて、Solara の Pro ゲート 2 層目 (= Worker 側真実) を成立させる。

## 関連ドキュメント

- `app_attest_design.md` — Layer A (端末改ざん耐性 + signCount + assertion)
- `project_solara_security_principles.md` 原則 1「クライアント単独 isPro 禁止」
- `store_products_setup.md` — RevenueCat ダッシュボード / 両ストア IAP 設定 (オーナー作業)
- `launch_checklist.md` Phase 1 (Worker 基盤) + Phase 4 (ストア準備)

## 設計判断 (確定)

| # | 項目 | 決定 | 理由 |
|---|---|---|---|
| D1 | Webhook 認証 | `Authorization: Bearer <REVENUECAT_WEBHOOK_AUTH>` を constant-time 比較 | RevenueCat ダッシュボード標準。secret は wrangler secret 管理 |
| D2 | Pro 状態保存先 | `AttestationState` Durable Object に `user_entitlements` + `webhook_events` 2 表を追加 (KV ではなく) | Webhook 即時 invalidate / SQL 履歴 / 既存 DO 統合の 3 点で KV に勝る |
| D3 | キャッシュ層 | Worker instance メモリ Map 60s TTL (`auth/entitlement_cache.js`) | DO 連打抑制。cold start ごと空、cross-instance は eventual 60s |
| D4 | appUserId 伝達 | `/protected/*` POST body に `__appUserId` 予約フィールドで Flutter→Worker | App Attest assertion が payload 全体を SHA-256 署名するため改ざん耐性あり |
| D5 | 未 sign-in | RevenueCat SDK 発行の `$RCAnonymousID:xxx` をそのまま使う | Sign in は任意、anonymous でも entitlement の機械的同等性は保たれる |
| D6 | Trusted Entitlements (REST API) | 今フェーズは Webhook 単独。REST fallback は公開後の精度向上タスク | Webhook の信頼性は十分 (RC 公式 SLA)、二重通信のコスト > 精度ゲイン |
| D7 | quota 切替 | Pro=`APP_ATTEST_QUOTA_PRO` (100/日) / Free=`APP_ATTEST_QUOTA_FREE` (5/日) | 既存 DO `quota-check-and-bump` は keyId 単位で動くまま、middleware の `limit` だけ差替え |
| D8 | event 種別マップ | ACTIVE=6 種 / GRACE=3 種 / INACTIVE=2 種 / IGNORE=4 種、未知 event は inactive 倒し | 既知 7 ライフサイクル網羅、未知は安全側 (Pro 失効) |
| D9 | 冪等性 | `webhook_events` 表に event_id INSERT OR IGNORE、既存なら副作用なしで 200 | RC 再送 / 攻撃 / リプレイ全部同じ防御 |
| D10 | out-of-order ガード | `last_event_at > now` の event は無視 | RC は順序保証しないため、古い event で新しい状態を上書きしない |

## アーキテクチャ図

```
Apple Store / Google Play
        │  (subscription event)
        ▼
RevenueCat
        │  (Webhook POST)
        │  Authorization: Bearer <REVENUECAT_WEBHOOK_AUTH>
        ▼
Cloudflare Worker  /webhooks/revenuecat
        ├─ Bearer 検証 (constant-time)
        ├─ event 種別 → is_active / expires_at 計算
        └─ Durable Object: AttestationState
                ├─ webhook_events: event_id 冪等性
                └─ user_entitlements: appUserId×entitlementId
                       │
                       ▼  (60s memory cache + DO lookup)
Flutter App
        │  POST /protected/*
        │  body: {..., "__appUserId": "apple:xxx"}
        │  X-AppAttest-KeyId, X-AppAttest-Assertion
        ▼
protectedMiddleware
        ├─ App Attest 9-step verify (Layer A)
        ├─ entitlement lookup → isPro 判定
        └─ Free=5/日 or Pro=100/日 quota
```

## API スキーマ

### Worker `/webhooks/revenuecat` (POST)

**Request**
```http
POST /webhooks/revenuecat HTTP/1.1
Authorization: Bearer <REVENUECAT_WEBHOOK_AUTH>
Content-Type: application/json

{
  "api_version": "1.0",
  "event": {
    "type": "INITIAL_PURCHASE" | "RENEWAL" | ...,
    "id": "<event uuid>",
    "app_user_id": "apple:xxx" | "google:xxx" | "$RCAnonymousID:xxx",
    "entitlement_ids": ["cosmic_pro", ...],
    "product_id": "com.solodevlab.solara.cosmicpro.monthly",
    "period_type": "NORMAL" | "TRIAL" | "INTRO",
    "purchased_at_ms": 1700000000000,
    "expiration_at_ms": 1700000000000,
    "environment": "PRODUCTION" | "SANDBOX",
    "store": "APP_STORE" | "PLAY_STORE",
    "is_family_share": false
  }
}
```

**Response**

| status | body | 意味 |
|---|---|---|
| 200 | `{ok: true, eventType, appUserId, isActive, expiresAt}` | 正常処理 |
| 200 | `{ok: true, ignored: "TEST"}` | RC ダッシュボードのテスト送信 |
| 200 | `{ok: true, ignored: "entitlement_not_targeted"}` | `cosmic_pro` 以外の entitlement |
| 200 | `{ok: true, alreadyProcessed: true}` | 同 event_id 再送 (冪等) |
| 200 | `{ok: true, skippedOutOfOrder: true}` | last_event_at より古い event |
| 400 | `{error: "invalid_app_user_id"}` 等 | Body 形式異常 |
| 401 | `{error: "unauthorized"}` | Bearer 不一致 |
| 405 | `{error: "method_not_allowed"}` | GET 等 |
| 503 | `{error: "webhook_disabled"}` | `REVENUECAT_WEBHOOK_AUTH` 未設定 |
| 500 | `{error: "internal_error"}` | DO 失敗 / 例外 (RC が再送する) |

### event 種別マップ

| type | is_active | expires_at | 備考 |
|---|---|---|---|
| INITIAL_PURCHASE | `true` | event.expiration_at_ms | 新規購入 |
| RENEWAL | `true` | event.expiration_at_ms | 自動更新 |
| PRODUCT_CHANGE | `true` | event.expiration_at_ms | 月→年 等 |
| UNCANCELLATION | `true` | event.expiration_at_ms | 解約取消 |
| NON_RENEWING_PURCHASE | `true` | event.expiration_at_ms | 買い切り (Solara 未利用) |
| TEMPORARY_ENTITLEMENT_GRANT | `true` | event.expiration_at_ms | 期間限定付与 |
| CANCELLATION | `true` | event.expiration_at_ms | 期限まで Pro 維持 |
| BILLING_ISSUE | `true` | event.expiration_at_ms | 猶予期間中は Pro 維持 |
| SUBSCRIPTION_PAUSED | `true` | event.expiration_at_ms | 一時停止 (Google のみ) |
| EXPIRATION | `false` | event.expiration_at_ms | 期限切れ確定 |
| REFUND | `false` | event.expiration_at_ms | 返金 |
| TRANSFER | `true` | event.expiration_at_ms | 1 transfer = 旧 user 1 通 + 新 user 1 通 で来る |
| SUBSCRIBER_ALIAS | (無視) | - | alias 通知単独では entitlement 更新しない |
| TEST | (無視) | - | RC ダッシュボードのテスト送信 |
| INVOICE_ISSUANCE | (無視) | - | Web purchase、Solara 未利用 |
| VIRTUAL_CURRENCY_TRANSACTION | (無視) | - | Solara 未利用 |

未知 event は `is_active=false` で記録 (= 安全側、未知の挙動で Pro を維持しない)。

### Durable Object 追加表

```sql
-- 1 appUserId × 1 entitlementId に 1 行
CREATE TABLE user_entitlements (
  app_user_id TEXT NOT NULL,
  entitlement_id TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 0,      -- 0/1
  expires_at INTEGER,                          -- ms epoch, null=lifetime
  environment TEXT NOT NULL,                   -- 'production'/'sandbox'
  store TEXT,                                  -- 'app_store'/'play_store'/null
  product_id TEXT,
  period_type TEXT,                            -- 'NORMAL'/'TRIAL'/'INTRO'/null
  last_event_type TEXT,
  last_event_id TEXT,
  last_event_at INTEGER NOT NULL,
  PRIMARY KEY (app_user_id, entitlement_id)
);

-- event_id 単位の冪等ログ (同 event の再送で副作用なし)
CREATE TABLE webhook_events (
  event_id TEXT PRIMARY KEY,
  received_at INTEGER NOT NULL,
  event_type TEXT NOT NULL,
  app_user_id TEXT,
  entitlement_id TEXT
);
```

**migration 不要**: SQLite-backed DO は CREATE TABLE IF NOT EXISTS で表追加できる。`wrangler.toml` の `[[migrations]]` 更新は不要 (= 既存 `tag = "v1"` のまま、追加 schema は `_ensureSchema()` で自動作成)。

### Flutter `/protected/*` body 規約 (v2.2)

```dart
// /protected/fortune 等の body
{
  // 既存フィールド (handler 側で使う)
  "birthDate": "1977-10-24",
  "birthTime": "06:56",
  "lang": "ja",
  ...,
  // ↓ 新規予約フィールド (Worker middleware が読む)
  "__appUserId": "apple:xxx" | "google:xxx" | "$RCAnonymousID:xxx"
}
```

`AppAttestClient.postProtected(url, payload: {...})` が自動注入する。`addHeaders` 経路で自前 body を組む場合は `AppAttestClient.withAppUserIdMerged(payload)` を encode 前に呼ぶ。

**改ざん耐性**: App Attest assertion は HTTP body の raw bytes 全体を payload SHA-256 で署名するため、`__appUserId` を別人の uid に書き換えると assertion が一致せず middleware で 401。

## middleware 順序 (`protectedMiddleware` 関数)

1. `APP_ATTEST_ENFORCEMENT` ゲート (disabled/log_only/enforced)
2. `X-AppAttest-KeyId` / `X-AppAttest-Assertion` ヘッダー存在チェック
3. DO `attestation-get` で公開鍵 + 前回 signCount 取得
4. body raw bytes 取得 (request.clone() で再読保証)
5. `verifyAssertion` (Apple Step 1-6 + signCount 動的判定)
6. DO `attestation-bump-counter` (replay 防止)
7. **body から `__appUserId` 抽出** → cache or DO `entitlement-get` で isPro 判定
8. **Free/Pro 切替で DO `quota-check-and-bump`** (Free=5/日 Pro=100/日)

各段で `mode=log_only` なら通過させ console.warn、`enforced` なら 401/429。

## エラーコード一覧 (新規追加 v2.2)

| code | 由来 | 意味 |
|---|---|---|
| `quota_exceeded_free` | middleware | Free quota (5/日) 超過 → ペイウォール導線 |
| `quota_exceeded_pro` | middleware | Pro quota (100/日) 超過 → 異常使用、まず無いはず |
| `entitlement_not_found` | DO `entitlement-get` | Webhook 未受信 (新規購入直後の数秒) |
| `entitlement_expired` | DO `entitlement-get` | expires_at < now、自然失効 |
| `entitlement_inactive` | DO `entitlement-get` | 明示的に is_active=0 (refund 等) |
| `unauthorized` | webhook | Bearer 不一致 |
| `webhook_disabled` | webhook | secret 未設定 (公開前ガード) |

## 運用

### 初回 deploy 手順

1. **wrangler secret 投入**
   ```powershell
   cd apps/solara/worker
   # 32-byte 以上のランダム文字列を生成 (例)
   $secret = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 48 | % {[char]$_})
   echo $secret | npx wrangler secret put REVENUECAT_WEBHOOK_AUTH
   ```
2. **wrangler deploy**
   ```powershell
   npx wrangler deploy
   ```
3. **RevenueCat ダッシュボード設定**
   - Project settings → Integrations → Webhooks → **+ Add new endpoint**
   - URL: `https://solara-api.solodev-lab.com/webhooks/revenuecat`
   - Authorization Header: `Bearer <secret>` (1 で生成した値)
   - Events: 全て ON (ACTIVE/GRACE/INACTIVE/IGNORE は Worker 側で分類)
4. **テスト送信** → RC ダッシュボードから「Send test event」→ Worker logs で `{ignored: "TEST"}` を確認
5. **本番購入テスト** (sandbox) → CustomerInfo 更新が DO に届くこと確認

### 監視ポイント

- `wrangler tail` で `/webhooks/revenuecat` の 401/503/500 を観測
- DO `webhook_events` 表の `received_at` を SQL で見て event 流入頻度を把握
- middleware `[middleware:log_only] would block` が `enforced` 切替後にゼロになること

### Bearer 漏洩時

1. `wrangler secret put REVENUECAT_WEBHOOK_AUTH` で上書き
2. RC ダッシュボードの Authorization header を同時更新
3. 漏洩期間中の DO `webhook_events` をレビュー (偽 event が混入していないか)
4. 偽 event があれば DO で該当 event_id を DELETE + 該当 entitlement を再計算

## 既知の限界 (公開後改善候補)

- **anonymous → authenticated alias 結合**: 現状 `SUBSCRIBER_ALIAS` event は ignore。anonymous で購入 → sign in した場合、購入は authenticated uid に紐づくが、anonymous uid の DO 行は残ったまま。実害なし (anonymous uid は誰も再利用しない) だが、cleanup ジョブを将来追加してもよい
- **TRANSFER event の旧 user 失効**: 現状 transfer event 1 通で新 user の active 化はするが、旧 user の inactive 化は別 event 期待。RC 公式仕様で 2 通来るのを前提
- **Trusted Entitlements REST API**: 公開後、`/auth/whoami` 等で「Worker 側 entitlement が DB に無い」場合のみ REST API で取りに行く fallback を追加すると、Webhook 取りこぼし時の UX が改善する
- **DO 1 instance 集約の上限**: DAU 5000 超で書込 100/sec 接近時に keyId-prefix sharding 化を検討

## v2.2 リリース範囲

- ✅ Worker `auth/entitlement_cache.js` (60s TTL メモリキャッシュ)
- ✅ Worker `webhooks/revenuecat.js` (170 行)
- ✅ Worker `auth/attestation_state.js` に user_entitlements / webhook_events 2 表追加 + 2 endpoint
- ✅ Worker `index.js` の middleware 拡張 (extractAppUserId + lookupIsPro + Pro/Free quota 切替)
- ✅ Flutter `purchases_service.dart` に `appUserId` getter 追加
- ✅ Flutter `app_attest_client.dart` で body に `__appUserId` 自動注入
- ✅ Flutter `consultation_api.dart` を `withAppUserIdMerged` 経由に変更
- ✅ Worker test 26/26 PASS (webhook + cache)
- ✅ flutter analyze clean

---

## v2.3 変更点 (2026-05-27) — 課金堅牢化 + 監査対応

### 動機

v2.2 までで Webhook 受信 + DO entitlement 真実保持 + 60s memcache は完成していたが、以下の窓で **購入クレジットが誤消費されるバグ** が発見された:

- Pro サブスク renewal の数十秒 (RC Webhook 遅延)
- 解約直後の数十秒 (RC SDK ローカルが先行)
- Play 内部テスト sandbox の 5-10 分圧縮 renewal サイクル

クライアント側 RC SDK は `cosmic_pro` active を即時認識するが、Worker DO は Webhook 着信まで「非 Pro」のまま → `consumeReadingCreditGate` が Free 経路に落ちて購入クレジットを 1 つずつ消費していく。`/protected/astro/consultation2` 12 回呼出のうち 11 回が `purchased-spend` に流れていた実例あり。

### 5 ステップの堅牢化

| Step | 内容 | コミット |
|---|---|---|
| 1 | Flutter `__clientEntitlement` snapshot を `/protected/*` body に注入 | `purchases_service.dart clientEntitlementSnapshot` + `app_attest_client.dart` |
| 2 | Worker `gateConsultation` / `consumeReadingCreditGate` / `consultationCreditStatus` に `proSyncReconcile` 経由 | `index.js` |
| 3 | RC REST `/v1/subscribers/{id}` で source-of-truth 再検証 (30s memcache) | 新規 `auth/rc_rest.js reverifyEntitlementViaRC` |
| 4 | DO スキーマに `grace_expires_at` 追加 + Webhook BILLING_ISSUE で `grace_period_expiration_at_ms` を保存 + `_entitlementGet` で `MAX(expires_at, grace_expires_at)` 判定 | `attestation_state.js` migration + `webhooks/revenuecat.js` |
| 5 | DO `last_event_timestamp_ms` 追加 + Webhook `event_timestamp_ms` で厳密 out-of-order 判定 (legacy: 受信時刻 fallback) | `attestation_state.js _entitlementUpsert` |

### Pro 同期遅延の安全停止フロー

```
クライアント主張 Pro × DO 非 Pro
        │
        ▼
proSyncReconcile
        │
        ├─ RC REST `/v1/subscribers/{id}` で再確認 (30s memcache)
        │     │
        │     ├─ RC も Pro と認める → memory cache 修復 + Pro 経路で処理続行
        │     │
        │     └─ RC も非 Pro と認める
        │           │
        │           ├─ verification != 'failed' (= 攻撃でない健全な状態)
        │           │   かつ失効から 5 分以内 → 425 pro_sync_pending
        │           │   (Retry-After: 30、購入残は触らない)
        │           │
        │           └─ verification == 'failed' (MITM 検出)
        │               → 通常 Free 経路 (= 攻撃を阻止、不正に Pro 機能を使わせない)
```

セキュリティ原則: クライアント主張は **何も解放しない**。425 は「購入消費を止める安全停止」のみに使う。悪意あるクライアントが Pro を偽主張しても、サーバが認められなければ機能は使えない (攻撃面ゼロ)。

### Event 種別マップ更新 (v2.3)

| 分類 | Event 種別 | 挙動 |
|---|---|---|
| ACTIVE (isActive=true で upsert) | INITIAL_PURCHASE / RENEWAL / PRODUCT_CHANGE / UNCANCELLATION / NON_RENEWING_PURCHASE / TEMPORARY_ENTITLEMENT_GRANT / **SUBSCRIPTION_EXTENDED** (v2.3 追加) | 7 種 |
| GRACE (期限内維持) | CANCELLATION / BILLING_ISSUE / SUBSCRIPTION_PAUSED | 3 種、`grace_period_expiration_at_ms` を `grace_expires_at` に記録 |
| INACTIVE (isActive=false) | EXPIRATION / REFUND | 2 種 |
| IGNORE (副作用なし 200) | SUBSCRIBER_ALIAS / TEST / INVOICE_ISSUANCE / VIRTUAL_CURRENCY_TRANSACTION | 4 種 |
| TRANSFER | 旧 owner: `transferred_from` に appUserId あり → isActive=false / 新 owner: `transferred_to` に appUserId あり → isActive=true / 不明 → active 維持 | RC 公式: 2 通発火 |
| 未知 event (v2.3 変更) | **副作用なしで 200 ignored 返却** (旧: isActive=false で upsert → Pro 誤失効事故あり) | DO は touch しない |

### アカウント削除フロー (v2.3 拡張)

`/protected/account/delete` は 4 段階削除:

1. **DO 物理削除** (`/account-purge` で `user_entitlements` + `webhook_events` 行を削除) — クリティカル、失敗で 500
2. **Worker memory cache invalidate** (`clearMemoryEntitlementCache`)
3. **RC 本体 subscriber DELETE** (`auth/rc_rest.js deleteSubscriberViaRC`、`DELETE /v1/subscribers/{id}`) — GDPR Right to Erasure / 個人情報保護法対応。best-effort
4. **Apple Token Revocation** (Apple Sign In ユーザーのみ、`auth/apple_revoke.js`) — fresh authorizationCode を Flutter 側で `getAppleIDCredential` 再起動で取得 → Worker が ES256 client_secret JWT を生成 → POST `https://appleid.apple.com/auth/revoke`。鍵未設定 (`secrets_missing`) は no-op skip。best-effort

レスポンス:
```json
{
  "ok": true,
  "deletedEntitlements": 1,
  "deletedEvents": 3,
  "rcDeleted": true,
  "rcReason": null,
  "appleRevoked": true,
  "appleRevokeReason": null
}
```

### v2.3 で追加された env / secret

```toml
# wrangler.toml (public, 既存値の隣に追記)
APPLE_SIWA_SERVICE_ID = "com.solodevlab.solara.signin"  # Apple Developer Console で発行
APPLE_SIWA_KEY_ID     = "ABC123DEF4"                     # Authentication Key の 10 桁 ID
# APPLE_TEAM_ID は v2.2 から既存
```

```sh
# wrangler secret put (secret)
APPLE_SIWA_PRIVATE_KEY  # .p8 ファイルの PEM 内容 (-----BEGIN PRIVATE KEY----- 含む)
REVENUECAT_SECRET_KEY   # sk_xxx、reverify + DELETE で使う
```

### DO スキーマ migration (v2.3)

```sql
ALTER TABLE user_entitlements ADD COLUMN grace_expires_at INTEGER;
ALTER TABLE user_entitlements ADD COLUMN last_event_timestamp_ms INTEGER;
```

旧 instance への migration は constructor の try/catch で冪等。新 instance は CREATE TABLE で最初から付く。

### v2.3 リリース範囲

- ✅ Worker `auth/rc_rest.js` (新規、reverify + DELETE)
- ✅ Worker `auth/apple_revoke.js` (新規、ES256 client_secret JWT + /auth/revoke)
- ✅ Worker `index.js` の `proSyncReconcile` + `handleAccountDelete` 4 段階拡張
- ✅ Worker `webhooks/revenuecat.js` の TRANSFER 旧/新判定 + SUBSCRIPTION_EXTENDED + 未知 IGNORE
- ✅ Worker `auth/attestation_state.js` の grace_expires_at + last_event_timestamp_ms migration + `_entitlementGet` MAX 判定 + `_entitlementUpsert` out-of-order 強化
- ✅ Flutter `purchases_service.dart clientEntitlementSnapshot` + `app_attest_client.dart __clientEntitlement` merge
- ✅ Flutter `solara_auth.dart deleteAccount` で Apple authorizationCode 再取得 + `_purgeServerAccountData` に渡す
- ✅ Flutter `paywall_widgets.dart` の auto-renew 文言を Apple 3.1.1 + 3.1.2(a) 準拠に書換 (「払い戻し不可」削除)
- ✅ Flutter `consultation_credit_sheet.dart` polling 1500ms → 500ms (購入後シート閉じる速度)
- ✅ Flutter `main.dart` で ProStatus listener → ConsultationCredits.refresh() 自動配線 (Pro 購入直後の Sanctuary 残数即反映)
- ✅ Flutter `sanctuary_screen.dart` の `_buildCreditRow` で proRemaining/proLimit 両 null 時に「Pro 残 確認中」表示 (= 「0/0」誤表示防止)
- ✅ Flutter `consultation_v2_api.dart` で 425 ステータスを block として扱う
- ✅ Worker test 295/295 PASS (新規 19 件)
- ✅ flutter analyze clean
