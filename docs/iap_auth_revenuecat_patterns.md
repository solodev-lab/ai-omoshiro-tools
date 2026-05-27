# IAP + Auth + RevenueCat 統合パターン集 (他アプリ流用可)

Solara で確立したパターンを、他のモバイルアプリでも再利用できる形で整理したリファレンス。コードは Flutter + Cloudflare Workers + RevenueCat 前提だが、設計原則は他スタックでも応用可能。

実例 (Solara): `apps/solara/docs/revenuecat_webhook.md` v2.3 + `apps/solara/lib/utils/purchases_service.dart` + `apps/solara/worker/src/`

---

## 0. 設計原則 (この章だけ読めば全体方針が分かる)

1. **クライアント単独 isPro 禁止** — クライアントが「Pro である」と言うだけでは Pro 機能は解放しない。サーバが entitlement 真実を別経路で確認する。
2. **Webhook 遅延を前提に設計しろ** — RC SDK ローカルは即時、Webhook はサーバ反映まで数秒〜分の窓がある。この窓で何が起きても安全に倒す。
3. **クライアント主張は「購入消費を止める」だけに使う** — 攻撃面ゼロ。悪意クライアントが Pro 偽主張しても機能解放されないが、購入残は守られる。
4. **三重防御で event 整合性を保証** — `event_id` 冪等性 + `event_timestamp_ms` out-of-order + `grace_expires_at` の MAX 判定。
5. **削除は四段** — DO 削除 + memory invalidate + RC マスター削除 + Apple Token Revocation。前段失敗以外は best-effort。

---

## 1. IAP 商品設計

### 消費型 (Consumable) と 非消費型 (Non-Renewing / Subscription) を明確に分ける

| 種類 | 用途 | RC Entitlement 紐付け | 消費 webhook |
|---|---|---|---|
| Auto-Renewing Subscription | Pro 等の継続課金 | あり (例: `cosmic_pro`) | INITIAL_PURCHASE / RENEWAL / EXPIRATION 等 |
| Non-Renewing Purchase | 消費型クレジット (3 個 / 10 個など) | **なし** (= Entitlement に紐付けない) | NON_RENEWING_PURCHASE のみ |

**よくある間違い**: 消費型に Entitlement を紐付けると「購入したら Pro になる」挙動になる。消費型は **product_id で識別 + サーバ側残高加算** が正解。

### Solara 実装例

- Pro: `cosmic_pro` entitlement に Apple/Google の subscription product を紐付け
- クレジット: `credits` Offering に `small` (3個) / `large` (10個) パッケージを置き、entitlement は **付けない**
- Worker は webhook の `product_id` を `CONSULTATION_CREDIT_PRODUCTS` env (CSV: `productId:amount,...`) で照合して残高加算

---

## 2. Auth + RevenueCat appUserId 連携

### 推奨フロー

1. `Purchases.configure(appUserID: null)` で起動 → SDK が `$RCAnonymousID:xxx` を発行
2. ユーザーが Sign In (Apple/Google) → `Purchases.logIn(uid)` で永続 ID へエイリアス
3. uid フォーマット: `apple:xxx` / `google:xxx` (どちらのプロバイダか判別可能に)
4. Sign Out → `Purchases.logOut()` で新規 anonymous ID 発行 (別ユーザーへの entitlement 漏洩防止)

### Sign In with Apple の必須事項

- **email/fullName は初回のみ来る**。SharedPreferences 等に永続化必須 (2 回目以降は null)
- **credentialState を起動時に確認** (`getCredentialState(userIdentifier)`)。`!= authorized` なら local session をクリア
- App Store Review Guideline 4.8 (Login Services): 他のサインイン手段があるなら Sign in with Apple も提供必須

### Google Sign In (7.x 系)

- `serverClientId` 必須 (Android 14+)。Web client OAuth ID を `--dart-define` で注入
- `authenticationEvents` ストリームで実行時のアカウント切替 / 暗黙的サインアウトを購読
- 機種変更時の挙動: Google アカウント自体が端末に紐付くため、新端末で同 Google アカウントに sign in すれば automatically RC が前 entitlement を引き継ぐ (logIn による alias)

### Sign In 強制のタイミング

| 場面 | サインイン強制? |
|---|---|
| アプリ起動 / 無料機能利用 | 不要 (anonymous でも動く) |
| Pro 購入 | **必須** (paywall でダイアログ) |
| 消費型クレジット購入 | **必須** (機種変更で残高失わないため) |
| 機能解放 (entitlement 確認) | 不要 (entitlement は purchases に紐付くため anonymous でも判定可) |

匿名状態で IAP が走るパスを実質ゼロにすると、RC の「Transfer behavior」設定の事故リスクが消える。

---

## 3. Webhook + DO + memory cache の三層構造

### Webhook 受信 (`/webhooks/revenuecat`)

- `Authorization: Bearer <secret>` を constant-time 比較
- `event_id` で冪等性 (`INSERT OR IGNORE webhook_events`)
- `event_timestamp_ms` で out-of-order 判定 (RC 公式: webhook 順序保証なし)
- 種別マップ:

| 分類 | Event |
|---|---|
| ACTIVE | INITIAL_PURCHASE / RENEWAL / PRODUCT_CHANGE / UNCANCELLATION / NON_RENEWING_PURCHASE / TEMPORARY_ENTITLEMENT_GRANT / **SUBSCRIPTION_EXTENDED** |
| GRACE (期限内維持) | CANCELLATION / BILLING_ISSUE / SUBSCRIPTION_PAUSED |
| INACTIVE | EXPIRATION / REFUND |
| TRANSFER | `transferred_from` に居れば inactive / `transferred_to` に居れば active |
| IGNORE | SUBSCRIBER_ALIAS / TEST / INVOICE_ISSUANCE / VIRTUAL_CURRENCY_TRANSACTION |
| **未知 event** | **副作用なしで 200 ignored 返却** (DO は touch しない) |

未知 event を inactive で書き込む実装は危険。RC が新 event を追加したときに Pro 誤失効する事故が起きる。

### Durable Object (entitlement 真実)

```sql
CREATE TABLE user_entitlements (
  app_user_id TEXT NOT NULL,
  entitlement_id TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 0,
  expires_at INTEGER,
  grace_expires_at INTEGER,        -- BILLING_ISSUE 等の grace 期限 (MAX で実効期限を出す)
  environment TEXT NOT NULL,
  store TEXT,
  product_id TEXT,
  period_type TEXT,
  last_event_type TEXT,
  last_event_id TEXT,
  last_event_at INTEGER NOT NULL,
  last_event_timestamp_ms INTEGER,  -- RC payload の event_timestamp_ms (out-of-order 判定の正典)
  PRIMARY KEY (app_user_id, entitlement_id)
);

CREATE TABLE webhook_events (
  event_id TEXT PRIMARY KEY,        -- INSERT OR IGNORE で冪等性
  received_at INTEGER NOT NULL,
  event_type TEXT NOT NULL,
  app_user_id TEXT,
  entitlement_id TEXT
);
```

**`_entitlementGet` での失効判定**:
```js
const effectiveExpires = (expiresAt == null && graceExpiresAt == null)
  ? null  // lifetime
  : Math.max(expiresAt ?? 0, graceExpiresAt ?? 0);
if (effectiveExpires !== null && effectiveExpires < now) {
  return 404 entitlement_expired;
}
```

これで Apple/Google 公式の「grace 中はサービス維持」要件を完全に満たす。

### Memory cache (Worker instance 内、60s TTL)

`/protected/*` のリクエストごとに DO を叩くと latency + billing が増える。60s TTL のメモリ Map で間引く。Webhook 受信 instance では即時 invalidate (`clearMemoryEntitlementCache`)。

---

## 4. Pro 同期遅延の安全停止 (425 pro_sync_pending)

### 問題

- クライアント RC SDK は購入完了時に即時 `cosmic_pro` active を認識
- Worker DO は Webhook 着信まで「非 Pro」のまま (数秒〜分)
- この窓で `consumeReadingCreditGate` が Free 経路に落ちて **購入クレジットを誤消費する**

実例: Solara で Stella 相談 12 回呼出のうち 11 回が purchased-spend に流れていた (Play 内部テスト sandbox の 5-10 分圧縮 renewal が原因)。

### 解決策: 3 段階の自己治癒

```
クライアントが /protected/* を呼ぶ
        │  body: { __appUserId, __clientEntitlement: {isPro, verification, expiresAtMs, productId} }
        ▼
gateConsultation
        │
        ├─ DO entitlement-get → isPro?
        │     │
        │     ├─ YES → 通常 Pro 経路
        │     │
        │     └─ NO + クライアント主張 Pro
        │           │
        │           ▼ proSyncReconcile
        │           │
        │           ├─ RC REST `/v1/subscribers/{id}` で再確認 (30s memcache)
        │           │     │
        │           │     ├─ RC も Pro → memory cache 修復 + Pro 経路続行
        │           │     │
        │           │     └─ RC も非 Pro
        │           │           │
        │           │           ├─ verification != 'failed' + 失効から 5 分以内
        │           │           │   → **425 pro_sync_pending** (Retry-After: 30、購入残不触)
        │           │           │
        │           │           └─ verification == 'failed' (MITM 検出)
        │           │               → 通常 Free 経路 (攻撃を阻止)
```

### Trusted Entitlements の verification 値

| 値 | 意味 | 425 保護対象? |
|---|---|---|
| `verified` | RC サーバ側で署名検証 OK | ✅ |
| `verifiedOnDevice` | iOS StoreKit 2 で on-device 検証 OK | ✅ |
| `notRequested` | 検証機構が利用できない (古い SDK 等) | ✅ (信頼度低いが攻撃面ゼロのため保護対象) |
| `failed` | RC が MITM を検出 | ❌ (攻撃確定なので Free 経路で阻止) |

Solara は `purchases_flutter 10.x` (= iOS 5.x SDK / Android 8.x SDK) で Trusted Entitlements がデフォルト有効。`EntitlementVerificationMode.informational` で SDK 検証を走らせる。

### クライアント側 UI

425 受信時:
- 「Pro 状態を同期しています」表示 (購入/Pro 誘導なし)
- 数十秒後にユーザーが手動で再試行 → 大抵この間に Webhook が DO へ反映している
- もしくは `Purchases.invalidateCustomerInfoCache()` で SDK を強制 refresh して再送

---

## 5. アカウント削除 (4 段階)

App Store Review Guideline 5.1.1(v) (2022/6/30 義務化) + GDPR Right to Erasure + 個人情報保護法対応。

```
POST /protected/account/delete
body: { __appUserId, appleAuthorizationCode? }
        │
        ├─ 1. DO 物理削除 (`/account-purge`)
        │     - user_entitlements + webhook_events から該当 app_user_id を削除
        │     - **クリティカル**: 失敗で 500 返却 (ユーザーに再試行を促す)
        │
        ├─ 2. Worker memory cache invalidate
        │     - clearMemoryEntitlementCache(appUserId)
        │
        ├─ 3. RC マスター削除 (`DELETE /v1/subscribers/{id}`)
        │     - GDPR Right to Erasure
        │     - best-effort: 失敗しても DO 削除は完了、レスポンスは ok:true
        │     - RC 公式: https://www.revenuecat.com/docs/api-v1#operation/delete-subscriber
        │
        └─ 4. Apple Token Revocation (Apple Sign In ユーザーのみ)
              - Flutter 側で `getAppleIDCredential` を再起動 → fresh authorizationCode 取得
              - Worker が ES256 client_secret JWT を生成
              - POST `https://appleid.apple.com/auth/revoke`
              - 鍵未設定なら no-op skip = コード先行 deploy 可能
              - best-effort: 失敗しても他工程は完了
```

### Apple Token Revocation の Developer Console 設定

1. Service ID 作成 (例: `com.example.app.signin`、Bundle ID とは別)
2. Authentication Key (.p8) 発行 + Key ID メモ
3. wrangler secret put で `APPLE_SIWA_PRIVATE_KEY` (.p8 内容) を登録
4. wrangler.toml に public 値 (`APPLE_SIWA_SERVICE_ID` / `APPLE_SIWA_KEY_ID`) を追記

ES256 (ECDSA + SHA-256) JWT を Cloudflare Worker の WebCrypto で生成可能。コード ~50 行。

### UI 上の必須案内

- 「サブスクは別途ストアで解約してください」(自動解約しない旨)
- Apple Sign In ユーザー向け「削除確認のため Apple サインインを再度求められます」
- 「この操作は取り消せません」
- 「端末内の記録 (履歴等) は残ります」or「端末内も消えます」を明確に

---

## 6. Paywall 必須開示文言 (Apple 3.1.2(a) + Google)

```
サブスクリプションは自動更新されます。期間終了の 24 時間以上前に自動更新を解約
しない限り、同じ価格で次の期間に更新されます。料金は期間終了の 24 時間以内に
Apple ID / Google アカウントへ請求されます。自動更新の管理や解約は、ご利用ストア
のアカウント設定からいつでも行えます。
```

必須 3 項目:
1. 期間終了 24 時間以上前に解約しないと更新される
2. 料金は期間終了 24 時間以内に課金される
3. 自動更新の管理 / 解約はストアのアカウント設定から可能

**禁止表現** (Apple 3.1.1):
- 「払い戻し不可」「all sales are final」「refunds will not be granted」
- → 払い戻しは Apple が判断するため、開発者が断言してはいけない

加えて必須リンク: 利用規約 / プライバシーポリシー / 解約方法 / 特定商取引法に基づく表記 (日本)。

---

## 7. App Attest / Play Integrity との統合 (任意)

`/protected/*` middleware で:
- iOS: App Attest assertion 検証 → 9 step
- Android: Play Integrity Standard request → decode + verify
- 共通: body から `__appUserId` 抽出 → DO entitlement lookup → Pro/Free quota 切替

検証段階:
1. `log_only` (deploy 直後): 失敗しても通す + console.warn
2. `enforced` (1 週間ログクリーン確認後): 失敗で 401

これで「クライアント単独 isPro 禁止」原則と「Webhook 遅延吸収」の両方が成立する。

---

## 8. 共通 pitfalls (= 業界で見落とされがちな箇所)

| 罠 | 症状 | 対策 |
|---|---|---|
| Webhook 順序保証なし | 古い EXPIRATION が新 RENEWAL を上書き | `event_timestamp_ms` で厳密判定 |
| grace 期間中の判定漏れ | BILLING_ISSUE 中なのに失効扱い | `grace_expires_at` を保存して `MAX(expires_at, grace_expires_at)` で判定 |
| クライアント Pro × サーバ非 Pro 窓 | 購入クレジット誤消費 | 425 pro_sync_pending + RC REST 再検証 |
| 未知 webhook event | Pro 誤失効 | inactive 書込み ❌ → IGNORE 倒し ✅ |
| RC アカウント削除漏れ | RC マスター DB に個人識別子残存 | `DELETE /v1/subscribers/{id}` を best-effort で呼ぶ |
| Apple Sign In email 取得タイミング | 2 回目以降 null で `null@apple.com` 化 | 初回のみ SharedPreferences に保存 |
| sandbox renewal cycle 圧縮 | 「Pro 残 0/0」が頻発 | RC REST 再検証 + 425 で吸収 |
| 消費型 IAP に entitlement 紐付け | 「クレジット買ったら Pro になる」事故 | RC ダッシュボードで entitlement を付けない |
| Anonymous で IAP 走る経路 | 機種変更で entitlement 失う | paywall でサインイン強制 |

---

## 9. テスト戦略

### Worker (node --test)

- entitlement-get / -upsert の SQL ロジック (Cloudflare runtime 依存部分は callDo mock)
- webhook event 種別分類 (各 event type で正しい active/inactive)
- proSyncReconcile の 4 分岐 (RC OK / RC 非Pro + verified / RC 非Pro + failed / clientEnt なし)
- RC REST 再検証の rc_404 / rc_500 / fetch_error / 30s memcache
- TRANSFER 旧/新 owner 判定
- 未知 event の IGNORE 倒し
- Apple ES256 JWT 生成 (テスト用 P-256 鍵で署名 → header.payload.signature の三段 base64url)

### Flutter (flutter test)

- PurchasesService.clientEntitlementSnapshot の各 verification 値での出力
- consultation_v2_api の 200/402/425 ステータス処理
- アカウント削除 dialog の文言 (Apple サインイン再表示の告知)

### 実機検証 (sandbox)

- Pro 購入 → Sanctuary 残数即時表示 (~1 秒)
- 連続 Stella 相談 12 回 → CF Logs で `/consultation-purchased-spend` が呼ばれない
- アカウント削除 → CF Logs で `/account-purge` + RC DELETE 両方ヒット
- iOS の場合: Apple ID 設定 (パスワードとセキュリティ > Apple ID を使用しているサインイン履歴) からアプリが消える

---

## 10. 参考リソース

### RevenueCat
- [Caching & Offline Grace Period](https://www.revenuecat.com/docs/test-and-launch/debugging/caching)
- [Common Webhook Flows](https://www.revenuecat.com/docs/integrations/webhooks/event-flows)
- [Trusted Entitlements](https://www.revenuecat.com/docs/customers/trusted-entitlements)
- [DELETE Subscriber (GDPR)](https://www.revenuecat.com/docs/api-v1#operation/delete-subscriber)
- [Reliability at RevenueCat (blog)](https://www.revenuecat.com/blog/engineering/reliability-at-revenuecat/)

### Apple
- [Sign in with Apple REST API](https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api)
- [Revoke Tokens](https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api/revoke_tokens)
- [App Store Review Guideline 3.1.2 (Auto-Renewing Subscriptions)](https://developer.apple.com/app-store/review/guidelines/#auto-renewing-subscriptions)
- [App Store Review Guideline 5.1.1(v) (Account Deletion)](https://developer.apple.com/app-store/review/guidelines/#5.1.1)
- [App Attest](https://developer.apple.com/documentation/devicecheck/establishing_your_app_s_integrity)

### Google
- [Google Play Subscription Lifecycle](https://developer.android.com/google/play/billing/lifecycle/subscriptions)
- [Real-Time Developer Notifications](https://developer.android.com/google/play/billing/rtdn-reference)
- [Play Integrity](https://developer.android.com/google/play/integrity/overview)

---

## 適用例: Solara

Solara はこのパターン集を完全実装しています。実コード参照:
- Worker: `apps/solara/worker/src/index.js` + `worker/src/auth/{rc_rest,apple_revoke,attestation_state,entitlement_cache}.js` + `worker/src/webhooks/revenuecat.js`
- Flutter: `apps/solara/lib/utils/{purchases_service,solara_auth,app_attest_client,consultation_credits}.dart` + `lib/screens/paywall_*.dart` + `lib/widgets/sanctuary_account_section.dart`
- 設計詳細: `apps/solara/docs/revenuecat_webhook.md` (v2.3)
- Apple Developer 設定手順: メモリ `project_solara_apple_siwa_revoke_setup.md`
