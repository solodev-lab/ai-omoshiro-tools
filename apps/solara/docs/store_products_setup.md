# サブスクプロダクト設定ガイド (両ストア + RevenueCat オーナー作業)

`launch_checklist.md` Phase 4「ストア準備」のうち、**サブスクリプション商品の作成と RevenueCat 紐付け** を進めるための手順書。コード側は Phase 2-6b で配線済 (`lib/utils/purchases_service.dart` + `lib/screens/paywall_screen.dart`)、本ドキュメントはアプリ外設定の手順書。

`sign_in_setup.md` と並ぶオーナー作業ドキュメント。

---

## 0. 確定値とプロジェクト固定値

| 項目 | 値 | 出典 |
|---|---|---|
| Bundle ID / Package Name | `com.solodevlab.solara` | `sign_in_setup.md`, RC コード |
| RevenueCat エンタイトルメント ID | `cosmic_pro` | `purchases_service.dart` L39 |
| RevenueCat Package タイプ | `monthly` + `annual` | `paywall_widgets.dart` L135-136 |
| 月額 価格 (USD ベース) | **$9.99** | `competitive_analysis.md` §6 #1, `pro_candidates.md` §7.6 |
| 年額 価格 (USD ベース) | **$59.99**（攻めすぎな $49.99 から修正済） | `competitive_analysis.md` §6 #1 推奨 |
| 無料トライアル | **7 日間**（年額のみ。月額は無し） | `competitive_analysis.md` §6 #7, `pro_candidates.md` §7.6 |
| Family Sharing | **OFF**（両ストアで明示） | `security_principles.md` 原則 5 |
| 言語 | ja-JP（メタデータ）。EN は i18n フェーズで追加 | `feedback_i18n_last.md` |

🔴 **Apple / Google で値が割れる可能性**: USD 基準で App Store の Price Tier、Google Play の自動価格換算を使う。為替で JP の表示が ±数円ずれるが許容範囲（公開後の調整可能）。

🔴 **税込表示の責任は OS 側**: ストア側で「税別」設定にしてもエンドユーザーには税込で表示される（StoreKit/Play Billing がローカライズ）。`paywall_widgets.dart` の `(税込)` ラベルは StoreKit/Play 提供の `priceString` をそのまま貼り付けているので二重表記にならない。

---

## 1. RevenueCat ダッシュボード (アカウント + プロジェクト準備)

### 1-1. アカウント作成

1. [app.revenuecat.com](https://app.revenuecat.com) でサインアップ（無料プラン: $2.5k MTR まで無料）
2. Organization 名: `solodev-lab` 推奨（複数プロジェクトを後で追加できる）
3. 2FA 必須化（Settings → Security）

### 1-2. プロジェクト作成

1. **+ Add new project** → Name: `Solara`
2. Apps を 2 つ追加:
   - **iOS**
     - App name: `Solara (iOS)`
     - Bundle ID: `com.solodevlab.solara`
     - App Store Connect Shared Secret（後で App Store Connect 側で発行して貼る）
   - **Android (Google Play)**
     - App name: `Solara (Android)`
     - Package: `com.solodevlab.solara`
     - Service Account credentials（後で Google Play Console で SA 作成して貼る）

### 1-3. API キーの取得

1. **Project settings → API keys** で各プラットフォームの **Public app-specific API key** をコピー
2. それぞれ `--dart-define` 経由でアプリに注入する:
   ```powershell
   flutter run `
     --dart-define=SOLARA_RC_IOS_KEY=appl_xxxxxxxxxxxxxxxxxxxxxxxx `
     --dart-define=SOLARA_RC_ANDROID_KEY=goog_xxxxxxxxxxxxxxxxxxxxxxxx
   ```
3. **Secret API キー** (`sk_...`) は Worker 専用 (将来 Phase 1 で `wrangler secret put REVENUECAT_SECRET_KEY` に入れる)。アプリには絶対に渡さない。

### 1-4. エンタイトルメント作成

1. **Entitlements → + New** → Identifier: `cosmic_pro`（必ずこの ID。コードがハードコード）
2. Display name: `Cosmic Pro`
3. **Save**（プロダクトは後で紐付ける）

---

## 2. App Store Connect (iOS サブスク)

### 2-1. アプリ作成（未作成の場合のみ）

1. App Store Connect → **マイ App → + → 新規 App**
2. プラットフォーム: iOS / Bundle ID: `com.solodevlab.solara`（Apple Developer Portal で先に登録済の前提）
3. 名前: `Solara` / プライマリ言語: 日本語

### 2-2. サブスクリプショングループ作成

1. アプリ詳細 → **App 内課金 → サブスクリプション**
2. **+ サブスクリプショングループ作成**
3. **参照名**: `Cosmic Pro Group`（社内識別、ユーザーには非表示）
4. **App Store でのローカリゼーション**:
   - 日本語: 表示名 `Cosmic Pro`
5. 🔴 **Family Sharing**: **OFF** のまま放置（既定 OFF だが明示確認）

### 2-3. 月額プロダクト

1. グループ内 **+ サブスクリプション**
2. **参照名**: `Cosmic Pro Monthly`
3. **製品 ID**: `com.solodevlab.solara.cosmicpro.monthly`
4. **登録期間**: `1 か月`
5. **価格**:
   - 基準国: **米国 $9.99 (Tier 10)** → 全 175 マーケットで自動換算（日本は約 ¥1,500 程度）
   - 必要なら日本だけ手動調整（例: ¥1,500 → ¥1,480 にして psychological pricing）
6. **App Store でのローカリゼーション**:
   - 日本語:
     - 表示名: `Cosmic Pro (月額)`
     - 説明（30 字以内）: `Stella の解釈・Map 全機能・記録庫の使い切り。`
7. **App Store プロモーション設定**: 任意（プロモ画像は公開直前）
8. **税カテゴリ**: 「自動更新サブスクリプション」既定のまま
9. **無料トライアル**: **設定しない**（月額は無し方針）
10. **審査メモ**: `日本国内向け占星術アプリのサブスク。Stella (生成AI) 占い使い放題と Map 上級機能。`
11. **スクリーンショット**: ペイウォール画面のキャプチャ 1 枚（公開直前）

### 2-4. 年額プロダクト

1. グループ内 **+ サブスクリプション**
2. **参照名**: `Cosmic Pro Annual`
3. **製品 ID**: `com.solodevlab.solara.cosmicpro.annual`
4. **登録期間**: `1 年`
5. **価格**:
   - 基準国: **米国 $59.99 (Tier 60)** → 全マーケットで自動換算（日本は約 ¥9,000 程度）
6. **App Store でのローカリゼーション**:
   - 日本語:
     - 表示名: `Cosmic Pro (年額)`
     - 説明: `Stella の解釈・Map 全機能・記録庫の使い切り。年額でお得に。`
7. **App Store プロモーション設定**: 任意
8. **無料トライアル**:
   - **サブスクリプションオファー → + → 入門オファー**
   - **オファー種別**: `無料`
   - **期間**: `1 週間`
   - **対象**: `初回購入者のみ`（既定）
9. **審査メモ**: 月額と同じ

### 2-5. App Store Shared Secret

1. **App Information → App-Specific Shared Secret → 生成**（既存があれば再利用）
2. RevenueCat **Project settings → Apps → Solara (iOS) → App Store connection** に貼る
3. **In-App Purchase Key** (P8) を **Users and Access → Integrations → App Store Connect API** で発行し、RC にも登録（StoreKit 2 / Subscription Notifications の正規ルート、Shared Secret より優先される）

### 2-6. App Store Subscription Notifications (RC Webhook 受け口)

1. App Store Connect → **App Information → App Store Server Notifications**
2. **Production Server URL**: RevenueCat 側で表示される URL を貼る
3. **Sandbox Server URL**: 同上の sandbox 用 URL
4. Version: **Version 2** 推奨

---

## 3. Google Play Console (Android サブスク)

### 3-1. アプリ作成（未作成の場合のみ）

1. Play Console → **すべての App → App を作成**
2. App 名: `Solara` / デフォルト言語: 日本語 / App かゲーム: App / 無料か有料: 無料（IAP 有り）
3. パッケージ名: `com.solodevlab.solara`（一度決めると変更不可）

### 3-2. 定期購入プロダクト 月額

1. **収益化 → 商品 → 定期購入 → + 定期購入を作成**
2. **商品 ID**: `cosmic_pro_monthly`
3. **名前**: `Cosmic Pro (月額)`
4. **説明 (80 字以内)**: `Stella の解釈・Map 全機能・記録庫の使い切り。`
5. **税金設定**: 「自動更新サブスクリプション」既定
6. **基本プラン**:
   - **基本プラン ID**: `monthly-auto`
   - **タイプ**: 自動更新
   - **請求期間**: `1 か月`
   - **更新タイプ**: 自動更新
   - **猶予期間**: 既定（3 日）
   - **アカウントの保留期間**: 既定（30 日）
   - **再登録**: 有効
7. **価格**: 日本 ¥1,500（USD $9.99 基準で全マーケット自動換算してから日本のみ確認）
8. 🔴 **家族向け共有**: **無効**（Family Sharing OFF）
9. **オファー**: 設定しない（月額はトライアル無し）
10. **有効化**

### 3-3. 定期購入プロダクト 年額

1. **+ 定期購入を作成**
2. **商品 ID**: `cosmic_pro_annual`
3. **名前**: `Cosmic Pro (年額)`
4. **説明**: `Stella の解釈・Map 全機能・記録庫の使い切り。年額でお得に。`
5. **基本プラン**:
   - **基本プラン ID**: `annual-auto`
   - **請求期間**: `1 年`
   - 他は月額と同じ
6. **価格**: 日本 ¥9,000（USD $59.99 基準で自動換算してから日本のみ確認）
7. **オファー**: **+ オファーを作成**
   - **オファー ID**: `freetrial-7d`
   - **タイプ**: **無料トライアル**
   - **期間**: `7 日間`
   - **対象**: 新規登録者のみ
   - **適用条件**: 既定（同一定期購入を一度も購入していない）
8. 🔴 **家族向け共有**: **無効**
9. **有効化**

### 3-4. Google Play Service Account (RC 連携用)

1. **設定 → API アクセス**（Play Console）
2. Google Cloud プロジェクトをリンク（既存 `solara-xxxxxx` を流用 or 新規）
3. **サービスアカウントを作成**:
   - 名前: `revenuecat-billing`
   - ロール: **財務 → 注文と定期購入の表示** + **Pub/Sub Subscriber**（Real-time developer notifications 受信用）
4. **JSON キー** を発行 → ダウンロード
5. RevenueCat **Project settings → Apps → Solara (Android) → Service Account credentials** に JSON を貼る
6. Play Console 側で SA に **App アクセス権** を付与（**ユーザーと権限 → 招待 → SA メールアドレス → アプリへのアクセス → 財務、定期購入、Order の閲覧**）

### 3-5. Real-time Developer Notifications

1. Play Console → **収益化 → 収益化セットアップ → Google Cloud Pub/Sub のトピック名**
2. RevenueCat 側で表示される Pub/Sub トピック (`projects/revenuecat-xxx/topics/xxx`) を貼る
3. SA に **Pub/Sub Subscriber** ロールが付与されていることを再確認
4. **テスト通知を送信** → RC 側 Webhooks タブで受信を確認

---

## 4. RevenueCat に両ストアのプロダクトを紐付け

### 4-1. プロダクトをインポート

1. RC ダッシュボード → **Products → + New Product** を 2 回（月額・年額）or **Import from App Store / Import from Play Store** で一括取込
2. 各プロダクトの **Entitlements** タブで `cosmic_pro` をチェック → Save
3. **App Store** と **Play Store** で同じ「Solara 月額」「Solara 年額」を 1 プロダクトにグループ化（クロスプラットフォーム判定が効く）

### 4-2. Offerings 作成

1. **Offerings → + New Offering**
2. **Identifier**: `default`（current にする）
3. **Display name**: `Cosmic Pro`
4. **+ Add Package** を 2 回:
   - **Package**: `$rc_monthly`（識別子は固定の `$rc_monthly`、コード側 `offering.monthly` で取れる）
     - Products: 月額プロダクト 2 つ（iOS + Android）
   - **Package**: `$rc_annual`（同じく `offering.annual` で取れる）
     - Products: 年額プロダクト 2 つ
5. **Set as current** をクリック → 既定 Offering になる

🔴 **`paywall_widgets.dart` L135-136 は `offering.current?.monthly` と `.annual` を読む**。Package タイプを `$rc_monthly` / `$rc_annual` 以外（カスタム識別子）で作るとコードが取り出せない。

### 4-3. 動作確認

1. iOS / Android 両方で `flutter run --dart-define=SOLARA_RC_IOS_KEY=... --dart-define=SOLARA_RC_ANDROID_KEY=...`
2. Sanctuary の `✦ Cosmic Pro` バナータップ → ペイウォール表示
3. 月額 / 年額 2 枚のカードが表示され、価格が `¥1,500 / 月 (税込)` / `¥9,000 / 年 (税込)` で出ること
4. 年額のみ「無料トライアル 1 週間 → 終了後に自動課金」が黄色で出ること

---

## 5. テスト購入

### 5-1. iOS Sandbox テスト

1. App Store Connect → **ユーザーとアクセス → Sandbox Apple ID → +** で sandbox ユーザーを作成（実家アドレス以外 / バーチャルオフィスアドレスでも可）
2. 実機 → **設定 → App Store → サンドボックスアカウント** で sandbox ユーザーをサインイン
3. アプリ起動 → ペイウォール → 月額タップ → Apple ID ダイアログで sandbox ユーザーを承認
4. RC ダッシュボードの **Customers** で `apple:xxx` の uid に `cosmic_pro` entitlement が `active: true` で記録されること
5. **設定 → サブスクリプション** で sandbox 解約 → 数分後 RC 側で `expires_date` が更新されること

### 5-2. Android テスト

1. Play Console → **設定 → ライセンステスト → +** で Google アカウントを追加（テスター扱い、課金が発生せず即座に更新サイクルが回る）
2. アプリを **内部テストトラック** で配信
3. 内部テスター URL から OPT-IN → Play からインストール
4. ペイウォール → 年額タップ → トライアル開始
5. RC Customers で `google:xxx` の entitlement 確認
6. Play **メニュー → 定期購入** で解約 → 数分後 RC で反映

### 5-3. クロスプラットフォーム復元テスト

1. iOS で sandbox 月額購入
2. **Sanctuary → Account** で同じ Apple ID にサインイン → uid = `apple:xxx`
3. Android で **同じ Apple ID は使えないので Google サインイン**
   - 🔴 同一ユーザーの Apple ↔ Google 切替は別 uid 扱い（`sign_in_setup.md` §3 末尾の注記通り）。クロスプラットフォーム merge は公開後検討
4. 同一プラットフォーム (iOS → iOS) では **購入を復元** ボタンで復元できる: アプリ削除 → 再インストール → ペイウォール下部 **購入を復元** → entitlement 復活を確認

---

## 6. 公開前最終チェック

`launch_checklist.md` Phase 4 該当項目に対応:

- [ ] RC エンタイトルメント `cosmic_pro` 作成
- [ ] RC Offering `default` に `$rc_monthly` + `$rc_annual` Package 設定 + current 化
- [ ] App Store Connect サブスクグループ `Cosmic Pro Group` 作成 (Family Sharing OFF)
- [ ] App Store 月額プロダクト `com.solodevlab.solara.cosmicpro.monthly` 有効化
- [ ] App Store 年額プロダクト `com.solodevlab.solara.cosmicpro.annual` 有効化 + 7日トライアル
- [ ] App Store Shared Secret / In-App Purchase Key (P8) を RC に登録
- [ ] App Store Server Notifications V2 を RC URL に設定
- [ ] Play Console 月額定期購入 `cosmic_pro_monthly` 有効化 (家族向け共有 OFF)
- [ ] Play Console 年額定期購入 `cosmic_pro_annual` 有効化 + 7日無料トライアルオファー
- [ ] Play Service Account を RC に登録 + Pub/Sub Notifications 配線
- [ ] iOS sandbox 購入テスト通過
- [ ] Android ライセンステスト購入テスト通過
- [ ] 復元ボタン動作確認
- [ ] RC Webhook がアプリ削除→再インストールでも entitlement を維持することを確認

---

## 7. 既知の注意点 (公開後の落とし穴)

- **Apple は税抜入力 / Google は税込入力**: 同じ ¥1,500 でも内部処理が違う。`priceString` は両方 OS 側で税込整形される
- **Sandbox では更新サイクルが短縮される**: 月額が 5 分、年額が 1 時間相当。本物の月次決済テストはできない
- **トライアル開始通知は遅延が出る**: iOS は最大 5 分、Android は最大 10 分。手動で `restorePurchases` 叩くと即時同期
- **解約は OS 側専用**: アプリ内で解約 UI を作れない（Apple 3.1.2 / Play 違反）。ペイウォール「解約方法」リンクは `paywall_screen._openCancelGuide` 経由で OS 設定アプリを開く
- **値上げ通知**: 後で値上げするときは Apple 30 日 + Google 30 日の猶予が要る。攻めの $59.99 から始める方が後の値下げ余地が残る
- **JP 円表記**: USD 自動換算で `¥1,500` のような数字を採用するが、為替が大きく動くと `¥1,489` のような半端な数字になる。3 ヶ月に 1 回見直す

---

## 8. 次フェーズ (本ドキュメントの後)

| フェーズ | 内容 | 担当 |
|---|---|---|
| Phase 4 残り | スクリーンショット撮影 / プライバシーラベル / データセーフティフォーム | オーナー |
| Phase 1 Worker | RevenueCat Webhook 受信 + Trusted Entitlements 二重検証 | 実装 (Claude) |
| Phase 5 | TestFlight / Internal Testing 配信 + 5-10 人ベータテスト | オーナー + 実装 |

`launch_checklist.md` を都度更新すること。
