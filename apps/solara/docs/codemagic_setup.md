# Codemagic で Solara を Mac なしで App Store へ (オーナー手順書)

> Windows のまま、Mac を一切使わずに Solara を TestFlight → App Store へ出すための手順。
> リポジトリ側の設定 (`codemagic.yaml` (リポジトリルート) / `Runner.entitlements` / Xcode 署名設定) は
> 実装済み。このドキュメントは **オーナーが Web UI で行う作業** をまとめたもの。
>
> 唯一必要な実機 = **iPhone 14** (iOS 18、Sandbox 課金テスト用)。Mac は不要。

---

## 前提 (済んでいるもの)
- Apple Developer Program 登録済み ($99/年)
- App Store Connect にアプリ登録済み + サブスク商品 (月額 ¥1,500 / 年額 ¥9,000・年額7日トライアル) 作成済み
- RevenueCat の iOS 配線・サーバ通知 設定済み
- Bundle ID = `com.solodevlab.solara` / 最小 iOS 15.0
- GitHub: `solodev-lab/ai-omoshiro-tools` (モノレポ、Solara は `apps/solara/`)

---

## Step 1. Codemagic サインアップ + リポジトリ接続
1. https://codemagic.io/ で GitHub アカウントでサインアップ (無料プラン)。
2. Add application → GitHub → `solodev-lab/ai-omoshiro-tools` を選択。
3. プロジェクト種別は Flutter。**codemagic.yaml を使う** を選ぶ (リポジトリ内の `codemagic.yaml` (リポジトリルート) が自動で読まれる)。

> 無料枠 = macOS M2 で月500ビルド分 (個人アカウント)。iOS ビルド1回 約8〜15分なので通常は無料で完走できる。

---

## Step 2. App Store Connect API キー発行 → Codemagic に登録
1. App Store Connect → **Users and Access** → **Integrations** タブ → **App Store Connect API** → **+** で新規キー。
   - 名前: 任意 (例 `Codemagic`)
   - アクセス: **App Manager**
   - 発行後、**Issuer ID** / **Key ID** を控え、**.p8 ファイルをダウンロード** (再DL不可、要保管)。
2. Codemagic → 右上のチーム/ユーザー設定 → **Integrations** → **App Store Connect** → **Add key**。
   - Issuer ID / Key ID / .p8 を登録。
   - **キー名を `Solara ASC Key` にする** (codemagic.yaml の `integrations.app_store_connect` と一致させるため)。
   - 別名にしたい場合は `codemagic.yaml` (リポジトリルート) の該当行も合わせて変更する。

---

## Step 3. 環境変数グループ `solara_ios_secrets` を作成
Codemagic → アプリ設定 → **Environment variables**。Group 名は **`solara_ios_secrets`**。以下を追加:

| 変数名 | 値 | Secure |
|---|---|---|
| `SOLARA_RC_IOS_KEY` | RevenueCat iOS Public SDK key (`appl_xxx`) | ✅ ON |
| `SOLARA_FREERASP_IOS_TEAM_ID` | Apple Team ID (10桁、任意) | OFF でも可 |
| `APP_STORE_APP_ID` | App Store Connect のアプリ数値 ID | OFF でも可 |

- `SOLARA_RC_IOS_KEY`: RevenueCat → Project → API keys の **iOS (Public app-specific) key**。
- `APP_STORE_APP_ID`: App Store Connect → 対象アプリ → **App Information** → 「Apple ID」(数値)。
- `SOLARA_FREERASP_IOS_TEAM_ID`: Apple Developer → **Membership** の Team ID。未設定でもビルドは通る (RASP 改変検知が no-op になるだけ)。

---

## Step 4. Sign in with Apple capability を有効化 (ビルド前必須)
Apple Developer → **Certificates, Identifiers & Profiles** → **Identifiers** → `com.solodevlab.solara` を開く →
**Sign In with Apple** にチェック → Save。

> これを忘れると、自動署名のプロビジョニングプロファイル生成が entitlement 不一致で失敗する。
> (リポジトリ側で Sign in with Apple の entitlement は追加済み。Google ログイン併用のため Apple 審査ガイドライン 4.8/5.4 上、本番審査前に必須。)

---

## Step 5. ビルド実行
1. Codemagic ダッシュボード → ワークフロー **「Solara iOS Release (TestFlight)」** → **Start new build**。
2. 成功すると IPA が自動署名され、**TestFlight へ自動アップロード**される (処理に数分〜数十分)。
3. 失敗時はログを確認 (下のトラブルシュート参照)。

---

## Step 6. iPhone 14 で Sandbox 課金テスト (Mac 不要)
1. App Store Connect → **TestFlight** → 対象ビルドを Internal Testing に追加 → 自分を Tester 登録。
2. iPhone 14 に **TestFlight アプリ** をインストール → Solara をインストール。
3. Sandbox テスター作成: App Store Connect → **Users and Access** → **Sandbox** → **Testers** → +。
4. iPhone 14: **設定 > Developer > Sandbox Apple Account** に上記 Sandbox テスターでサインイン。
   - (iOS 17 以前の iPhone なら **設定 > App Store > Sandbox Account**)
5. Solara を起動し主要画面を一通り確認: Map / Horoscope / Observe / Stella / Sanctuary。
6. **Cosmic Pro 購入** (¥1,500 または年額 ¥9,000・7日トライアル) → Pro 機能が解放されるか確認。
7. RevenueCat → **Customers** で `apple:xxx` ユーザーに `cosmic_pro` が active になっているか確認。
8. Sign in with Apple ボタンが Apple ログインを起動し、落ちないことを確認。

> 注意: TestFlight の定期購入更新は「24時間に1回」。基本の購入・Pro 有効化検証はこれで OK。
> iPhone 7 / 8 は旧 iOS のスモークテスト用予備として使える。

---

## Step 7. 審査提出 (TestFlight 確認後)
1. App Store Connect でアプリの **スクリーンショット** (6.9" / 6.5")、説明、**App プライバシー** を入力。
2. **In-App Purchase を初回バージョンと同時に審査提出** + IAP のスクショ + 審査メモを添付。
3. `codemagic.yaml` (リポジトリルート) の `# submit_to_app_store: true` のコメントを外して再ビルド → 自動で審査提出。
   - もしくは App Store Connect から手動で「審査へ提出」。

---

## トラブルシュート
| 症状 | 原因 | 対処 |
|---|---|---|
| `No matching profiles found` / 署名失敗 | App ID の capability 未有効 or キー名不一致 | Step 4 を実施 / `integrations.app_store_connect` の名前を Step 2 の登録名に合わせる |
| `app-store-connect get-latest-testflight-build-number` でエラー | `APP_STORE_APP_ID` 未設定/誤り | Step 3 の数値 ID を確認 |
| 課金画面が出ない / 購入が進まない | `SOLARA_RC_IOS_KEY` 未注入 | Step 3 で Secure 変数を確認、グループ名 `solara_ios_secrets` を確認 |
| TestFlight にビルドが出ない | 処理待ち or コンプライアンス未回答 | 数十分待つ / ASC で輸出コンプライアンス質問に回答 |
| pod install 失敗 | Podfile.lock 不整合 | ログ確認。`cd ios && pod install` ステップのエラー内容を見る |

## 費用まとめ
- Codemagic: **¥0** (無料枠 macOS M2 500分/月)
- クラウド Mac: **不要**
- 追加ハード: iPhone 所有のため **¥0**

---

## 関連
- ワークフロー定義: `codemagic.yaml` (リポジトリルート)
- 署名 entitlement: `apps/solara/ios/Runner/Runner.entitlements`
- dart-define 整合元: `apps/solara/tools/build_release.py` / `apps/solara/docs/build_release.md`
- ストア商品設定の正典: `apps/solara/docs/store_products_setup.md`
