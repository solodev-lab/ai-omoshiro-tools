# Solara — App Store / Google Play 審査対応 正典

> **このドキュメントは Solara の Apple/Google 審査対応の唯一の正典 (single source of truth)。**
> 最終更新: 2026-05-27 (commit 着手フェーズ)
> 主源泉: Apple Developer (developer.apple.com) / Google Play Console Help (support.google.com/googleplay/android-developer) / TechCrunch / 公式 blog 等 4 並列調査結果。
> 関連: [feature_inventory.md](feature_inventory.md) §0 (機能インベントリ) / [legal.md](legal.md) (法務文書下書き) / [release_checklist.md](release_checklist.md) (出荷チェック)

---

## 0. 利用ガイド

新しい審査関連の判断・実装をするときは **このドキュメントを最初に読む**。各 section は:
- 「ガイドラインの最新事実」(根拠 URL 付き)
- 「Solara への適用判断」(なぜそうすべきか)
- 「対応状況」(実装済 / 未対応 / 判断待ち)

の 3 点で書く。一方的な reference ではなく、Solara 文脈での解釈を残すのが目的。

---

## 1. ステータス サマリ (2026-05-27 現在)

### 1.1 既に対応済 (commit/deploy 済)

| 領域 | 内容 | 根拠 |
|---|---|---|
| **アカウント削除** | アプリ内 (Sanctuary > アカウント > 削除) + サーバ GDPR DELETE + RC subscriber DELETE | Apple 5.1.1(v) / Google Account Deletion (2024 義務化) |
| **Apple Token Revocation** | `/auth/revoke` 経由で Apple refresh token 無効化 | App Store Guideline 5.1.1(v) 厳格対応 |
| **Sign in with Apple** | Apple SIWA を Google より上 or 並列、name+email のみ取得 | Apple 4.8 同時提供義務 |
| **3.1.2(a) 自動更新サブスク 必須開示 3 項目** | (1) 期間 + 自動更新 (2) 24h 前まで解約 (3) アカウント設定で解約 | Apple 3.1.2(a) (2025-11-13 後の厳格運用) |
| **「払い戻し不可」文言削除** | 法定返金権を消す表現を全廃 | Apple 3.1.1 違反予防 |
| **Paywall 必須要素** | title/price/period/restore/terms/privacy リンク全部表示 | Apple 3.1.2 / Google Play Billing |
| **特商法表記** (Platform 分岐) | iOS=個人事業主 / Android=arrayu株式会社 | 日本 特商法 11 条 |
| **解約方法案内** | iOS / Android / Web の 3 ストア deep link | Apple 3.1.2(a) / Google subscriptions |
| **Tarot prompt safety guard** | 医療・法律・自傷 + プロンプト注入対策 | Apple 1.4.1 / Google Health Content (適用前) |
| **Stella V2 + Horo prompt safety guard** (本セッション追加) | 医療・法律・金融・投資・自傷の断定禁止、「必ず/絶対」禁止 | 同上、Tarot との対称性 |
| **App Attest (iOS) + Play Integrity (Android)** | log_only、enforced 化は 2026-05-29 頃判断 | Apple App Attest / Google Play Integrity |
| **Worker GDPR DELETE** | DO + Webhook events purge | EU GDPR / Apple 5.1.1(viii) |
| **位置情報 最小権限** | iOS=WhenInUse のみ (本セッションで Always を削除) / Android=Foreground のみ | Apple 5.1.5 / Google Sensitive Permissions |
| **OSM Attribution** (本セッション追加) | Map / Picker / Minimap すべての地図画面に "© OpenStreetMap contributors" + ODbL リンク | OSM ODbL ライセンス |

### 1.2 未対応 (Gap)

§4 Gap Analysis 参照。

### 1.3 最新 AAB / iOS ビルド

- AAB: `apps/solara/build/app/outputs/bundle/release/app-release.aab` (v1.0.0+12、2026-05-27 14:07 ビルド)
- iOS: Codemagic 経由、Build #? は本セッションの変更込みで再ビルド要 (v+13 予定)
- Worker: deploy 済 (Version `2957ebc6`、2026-05-27 15:00 頃)

---

## 2. Apple App Store 最新動向 (2025-2026)

### 2.1 大型改定: 2025-11-13 App Review Guidelines 更新
出典: [Apple Developer News](https://developer.apple.com/news/?id=ey6d8onl) / [TechCrunch 解説](https://techcrunch.com/2025/11/13/apples-new-app-review-guidelines-clamp-down-on-apps-sharing-personal-data-with-third-party-ai/)

**Solara 直撃の 4 項目**:

1. **5.1.2(i) 第三者 AI へのデータ送信 明示同意義務** (★最重要)
   > "You must clearly disclose where personal data will be shared with third parties, **including with third-party AI**, and obtain explicit permission before doing so."
   - **Reviewer は onboarding 画面 / プライバシーポリシー / App Privacy 質問票 の 3 点を line-by-line で比較**
   - 不一致 = 自動リジェクト
   - **Solara 適用**: Gemini API に出生情報 + 相談内容を送信 = 該当。**未対応 (Gap #1)**
2. **1.2.1(a) Creator Apps の年齢制限機構** — AI 生成も同種扱いされ得る
3. **4.1(c) 他社のアイコン/ブランド名利用禁止** — 「Apple」「Google」「Gemini」ロゴをアプリ内に表示しない
4. **4.7 mini app/chatbot の対象拡大** — ネイティブ AI 機能にも moderation 義務の発想が適用される傾向

### 2.2 Age Rating 改訂 (2025-07-25 発表、2026-01-31 期限)
出典: [Apple Developer News](https://developer.apple.com/news/?id=ks775ehf)

- 旧 4+/9+/12+/17+ → 新 **4+/9+/13+/16+/18+** 体系
- 「**AI 生成の予測不可能性**」を質問項目に追加
- **2026-01-31 までに新質問票回答 deadline** (期限超過で update 提出不可)
- **Solara 推奨**: AI チャット + タロット + ライト宗教 = **13+ 推奨**

### 2.3 Privacy Manifest 全 SDK 必須 (2024-05-01 施行済)
出典: [Apple Third-party SDK requirements](https://developer.apple.com/support/third-party-SDK-requirements/)

- `PrivacyInfo.xcprivacy` を Xcode で生成 + 全 SDK が同梱版必要
- 2025 Q1 で 12% のリジェクト要因
- **Solara 確認対象**: google_sign_in / google_maps_flutter / sign_in_with_apple / purchases_flutter / share_plus / package_info_plus / url_launcher / permission_handler — 全部最新版に上げて Privacy Manifest 同梱確認

### 2.4 4.3(b) Spam (★Solara 最大の地雷)
> "the App Store has enough fart, burp, flashlight, **fortune telling**, dating, drinking games, and Kama Sutra apps... We will reject these apps unless they provide a unique, high-quality experience."

- **「占い」「fortune telling」を明示列挙**
- 単純な占星術アプリは reject 多数
- **Solara 適用**: AI 相談 + 地図 + Pro 機能 + Stella キャラ等の差別化要素を **App Store 説明文 + reviewer notes に明示** すれば通せる

### 2.5 その他 (Solara 関連)
- **3.1.2 Subscription ongoing value**: paywall に Pro の継続価値 (相談 100 回/週 + 毎日 Horo + 広告無し等) を明示
- **5.1.1(v) Account Deletion**: 「Account 画面から 2 タップ以内」 = Sanctuary > アカウント > 削除 OK
- **5.1.5 Location purpose string**: 具体例必須 → 本セッションで「出生地・候補地・現在地での占星術計算と地図表示」に更新済
- **DMA / EU 代替決済 / Web Distribution**: 日本市場は影響なし

---

## 3. Google Play 最新動向 (2025-2026)

### 3.1 Generative AI Apps Policy (★公開ブロック級)
出典: [Understanding Google Play's AI-Generated Content policy](https://support.google.com/googleplay/android-developer/answer/14094294)
施行: **2026-04-15 全面施行**

**必須要件 (Solara 全 AI 機能に直撃)**:
1. **In-app reporting / flagging 機能**: ユーザーが「不適切な AI 出力」を **アプリ内で報告** できる UI 必須
   - Stella 相談・Tarot 結果・Horo 結果 **各画面に「報告」ボタン**
2. **AI 生成であることの明示**: chat 応答 / 文章生成、全て "AI generated" ラベル
3. **事前防止義務**: 苦情対応ではなく **生成前に filter**
4. **moderation プロセス**: ユーザー報告を反映する仕組みの説明資料 (審査時提示用)

### 3.2 Target API Level
出典: [Meet Google Play's target API level requirement](https://developer.android.com/google/play/requirements/target-sdk)

| 期間 | 新規/更新提出 |
|---|---|
| 現在 (2025-08-31 以降) | **Android 15 (API 35) 以上** |
| 2026-08-31 以降 | Android 16 (API 36) 以上 |
| 既存ユーザー継続のみ | Android 14 (API 34) |

→ Solara は Flutter デフォルトで追随、`apps/solara/android/app/build.gradle` の targetSdkVersion 確認のみ。

### 3.3 16 KB Page Size
- 当初 2025-11-01 → Play Console で **2026-05-31 まで延長可**
- NDK 依存 SDK が対象
- **Solara 確認対象**: RC / google_sign_in / sign_in_with_apple / google_maps_flutter のネイティブ層

### 3.4 Closed Testing 12 testers × 14 days
出典: [App testing requirements for new personal developer accounts](https://support.google.com/googleplay/android-developer/answer/14151465)
- **個人アカウント** (2023-11-13 以降作成) は Production access の前提として **12 名 × 14 日 opt-in**
- 法人アカウントは対象外
- **Solara**: 個人/法人どちらかの確認要

### 3.5 Account Deletion (2024 義務化)
- アプリ内削除 UI ✅ + **Web URL での削除リクエスト窓口** ← 未対応 (Gap)
- Web URL を Play Console > Data Safety form の "Delete Account URL" に提出

### 3.6 Health Content & Services policy (2025-08-28 強化、2026-01 enforce)
- 占星術アプリは Health 分類外だが、**「相性占い」「メンタル助言風」回答が "Health-adjacent" と誤判定** されうる
- **Solara 予防策**: Stella prompt で「健康・医療・投薬は答えない」を明示 (本セッションで対応済)

### 3.7 Sensitive Permissions
- 最小スコープ原則 — FINE が本当に必要か再検討推奨
- Background location は permission declaration form 必須 (Solara は未使用 ✅)

### 3.8 Data Safety Form (2025-04 改訂)
- Android ID = "Device or other IDs" として明示開示必須 (RC SDK が読む可能性)
- AI 入力テキスト (相談文) = User-generated content + Personal info
- Gemini API への送信 = "Data shared with third parties: Yes"

---

## 4. Gap Analysis (公開前必須項目)

### 4.1 公開ブロック級 (リジェクト確率高)

| # | 項目 | 該当ストア | 状態 | 工数 |
|---|---|---|---|---|
| G1 | **Gemini 送信前の明示同意モーダル** | Apple 5.1.2(i) | ❌ | 1.5h |
| G2 | **AI 結果画面に「報告」ボタン** (Stella/Tarot/Horo) | Google Gen AI Policy | ❌ | 3h |
| G3 | **アプリ内 disclaimer 「これはエンタメ」** 全 AI 結果画面 | Apple 4.0 + Google | ❌ | 1h |
| G4 | **Account Deletion Web URL** (Cloudflare Pages 等) | Google Data Safety | ❌ | 1.5h |
| G5 | **iOS の Google Sign In OAuth クライアント** または iOS で Google ボタン非表示 | Google ボタン押すとクラッシュ | ❌ | 0.5h (非表示) / 2h (配線) |
| G6 | **ストア提出メタデータ** (スクショ / 説明文 / Data Safety / 年齢レーティング) | Apple/Google | ❌ | 4-8h |

### 4.2 中優先

| # | 項目 | 該当 |
|---|---|---|
| G7 | App Store / Play 説明文から「占い」「運勢」「予言」「的中」「保証」を全削除 → 「西洋占星術ベース自己探求」表現に置換 | Apple 4.3(b) Spam 対策 |
| G8 | Privacy Manifest 全 SDK 対応確認 | Apple 2024-05 施行 |
| G9 | Age Rating 質問票更新 (13+ 推奨) | Apple **2026-01-31 期限** |
| G10 | 16 KB page size 対応確認 (NDK 依存 SDK) | Google **2026-05-31 期限** |
| G11 | Data Safety form 入力 (Android ID / Gemini 共有 / 出生情報等) | Google Play Console |

### 4.3 本セッションで完了

| 項目 | 内容 |
|---|---|
| ✅ Stella V2 + Horo prompt の medical/legal/self-harm safety guard | Tarot と対称化 |
| ✅ iOS Info.plist の不要な `NSLocationAlwaysAndWhenInUseUsageDescription` 削除 | Background 未使用なので削除、WhenInUse の文言も具体化 |
| ✅ Map / Picker / Minimap 全 3 画面に OSM Attribution 表示 | `buildOsmAttribution` + `buildOsmAttributionCompact` ヘルパー追加 |
| ✅ Apple SIWA Token Revocation 本稼働 (前セッション完了) | Service ID + Authentication Key + Worker secret + deploy 全完了 |

---

## 5. AI 生成 × 占い系アプリ特有のリスク

### 5.1 disclaimer 多層化が必須

両ストア共通で、以下 4 箇所に disclaimer を入れる:

| 箇所 | 文言の役割 | Solara 対応状況 |
|---|---|---|
| 初回起動の Acknowledge モーダル | ユーザー consent 取得 (Apple 5.1.2(i)) | ❌ 未実装 (Gap G1) |
| 結果画面の常時フッター | 「AI 生成 + エンタメ目的」明示 (Google Gen AI policy) | ❌ 未実装 (Gap G3) |
| App Store / Google Play 説明文 冒頭 | metadata 監査対象 | ❌ 未対応 (Gap G7) |
| 利用規約内の責任制限条項 | 法的保護 | ✅ legal.md 既存 |

### 5.2 必須 disclaimer 文言テンプレート

#### A. 初回起動 Acknowledge モーダル (日本語)
```
Solara をご利用いただきありがとうございます。

本アプリの占星術・タロット・AI 相談はすべて娯楽および
自己探求の目的で提供されるものです。医療・法律・金融・
心理に関する専門的助言を提供するものではありません。

あなたの出生情報および相談内容は、AI 解釈の生成のために
Google の Gemini AI サービスに送信されます。

[同意して続ける]   [同意しない]
```

#### B. 結果画面の常時フッター (毎回表示)
```
✦ Stella の解釈は AI が生成しています。娯楽目的のみ。
重要な決定は専門家にご相談ください。  [この回答を報告 ⚑]
```

#### C. App Store / Google Play 説明文 冒頭
```
【重要】Solara は娯楽および自己探求のためのアプリです。
占星術・タロット・AI 相談はいかなる種類の専門的助言
(医療・法律・金融・心理) も提供しません。
将来の出来事を予測・保証するものではありません。
```

#### D. Gemini prompt system instruction (実装済、本セッションで Stella V2 + Horo に拡張)
```
- 🔴 安全性ガイド: 医療・法律・金融・投資・自傷に関わる断定的なアドバイスをしない。
- 移住・転職・離婚等の重要な人生判断についても「占星術はあなたの意識を映す鏡」として読み、
  最終判断は相談者本人のものと明確にする。「必ず」「絶対」「○○すべき」は禁止。
```

### 5.3 類似アプリの実例 (参考)

| アプリ | 観察された対策 |
|---|---|
| **Co-Star** | NASA JPL 天体データを根拠提示 + 人間アストロロジャー + AI のハイブリッド説明で "single AI bot" 感を回避 |
| **Sanctuary** | "Review Guidelines" を独自に公開、サービス類型 (astrology/tarot/energy healing) を **列挙** = 4.3 Spam 回避 |
| **Nebula** | サブスク開示不透明の苦情多数 (Trustpilot) → Solara は同じ罠を避けること |
| **日本 LINE 占い** | 特商法表記 (運営者・住所・連絡先) フッター固定、「結果には個人差があります」全画面下部固定 |

---

## 6. リジェクト時のリカバリ手順

| リジェクト理由 | 典型メッセージ | 対応 |
|---|---|---|
| **Apple 4.3(b) Spam (saturated category)** | "Your app duplicates content of similar apps already on the App Store" | Resolution Center で差別化要素 3-5 個列挙 (AI 個別相談 / 移住 AI 提案 / 3 層トランジット / Stella キャラ等)。スクショ追加。 |
| **Apple 5.1.2(i) AI data sharing 不備** | "Your app shares user data with third-party AI services without clear disclosure or consent" | 初回モーダル + プライバシーポリシー更新を実装し、変更前後 screencast 添付 |
| **Apple 1.4.1 Medical** | "Your app contains content that may mislead users about its medical capabilities" | 「健康運」「体調」表現を Gemini system prompt 側で禁止 + UI 文言から削除 |
| **Apple 2.3.10 Metadata misleading** | "Your app's description includes claims that may mislead users about the app's purpose" | 説明文冒頭に disclaimer 配置、「占う」「予測」を「解釈する」「読み解く」に置換 |
| **Apple 3.1.2 Subscription integrity** | "Your subscription information does not clearly state..." | paywall に期間・価格・自動更新・解約方法・利用規約 URL・プライバシーポリシー URL の 6 点を一覧表示 |
| **Google Generative AI policy violation** | "Your app generates content using AI without an in-app user reporting mechanism" | 各 AI 結果画面に flag ボタン追加 |
| **Google Misleading claims (health)** | "App contains health claims contradicting medical consensus" | 健康運・体調系の表現を全削除し変更履歴提出 |

**対応のコツ**:
- Apple Resolution Center は **変更前後の screencast 添付** で通過率大幅向上
- Google は declaration form の修正のみで通ることが多い

---

## 7. Data Safety Form 推奨回答 (Google Play Console)

| カテゴリ | 項目 | 収集? | 共有? | 任意/必須 | 目的 | 備考 |
|---|---|---|---|---|---|---|
| Personal info | Name (ニックネーム) | Yes | No | 任意 | App functionality | DO 保存 |
| Personal info | Email | Yes | No | Sign-In 時必須 | Account management | Apple/Google 経由 |
| Personal info | User IDs | Yes | Yes (RC) | 必須 | Analytics / Account | appUserId |
| Location | Approximate location | Yes | Yes (Maps) | 任意 | App functionality | 出生地 / 現在地 |
| Location | Precise location | Yes | Yes (Maps) | 任意 | App functionality | 同上 |
| Financial info | Purchase history | Yes | Yes (RC + Google Play) | 課金時 | Account management | |
| User content | Other user-generated content | Yes | Yes (Gemini) | 相談時必須 | App functionality | 相談入力 / 出生情報 |
| App activity | App interactions | Yes | No | 任意 | Analytics | DO 集計 |
| Device or other IDs | Device or other IDs | Yes | Yes (RC, GA) | 必須 | Analytics / Fraud prevention | Android ID 含 |

**Security practices**:
- [x] Data is encrypted in transit (HTTPS)
- [x] Users can request that their data be deleted (アプリ内 + Web)
- [x] Account deletion Web URL: **未提出 (Gap G4)**

**Generative AI disclosure** (新セクション・将来必須化):
- 用途: 占星術解釈の文章生成 / タロット解釈 / 相談応答
- モデル: Google Gemini API (gemini-2.5-flash)
- フィルタ: Gemini safety settings + Worker post-filter
- 報告手段: アプリ内「報告」ボタン (Gap G2 で追加予定)

---

## 8. 参考 URL (一次情報)

### Apple
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Updated App Review Guidelines (2025-11-13)](https://developer.apple.com/news/?id=ey6d8onl)
- [Offering account deletion in your app](https://developer.apple.com/support/offering-account-deletion-in-your-app/)
- [Third-party SDK requirements (Privacy Manifest)](https://developer.apple.com/support/third-party-SDK-requirements/)
- [Updated age ratings (2025-07)](https://developer.apple.com/news/?id=ks775ehf)
- [Age ratings values and definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions)

### Google
- [Developer Program Policy](https://support.google.com/googleplay/android-developer/answer/16944162)
- [AI-Generated Content policy](https://support.google.com/googleplay/android-developer/answer/14094294)
- [Best Practices to Safeguard AI-Generated Content](https://support.google.com/googleplay/android-developer/answer/16353813)
- [App testing requirements (Closed testing)](https://support.google.com/googleplay/android-developer/answer/14151465)
- [Target API level requirements](https://support.google.com/googleplay/android-developer/answer/11926878)
- [Account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111)
- [Health Content and Services](https://support.google.com/googleplay/android-developer/answer/16679511)
- [Sensitive Permissions and APIs](https://support.google.com/googleplay/android-developer/answer/16585319)
- [Policy announcement — April 15, 2026 (Gen AI)](https://support.google.com/googleplay/android-developer/answer/16926792)
- [16 KB page sizes](https://android-developers.googleblog.com/2025/05/prepare-play-apps-for-devices-with-16kb-page-size.html)

### 二次情報 (高信頼)
- [TechCrunch — Apple's new App Review Guidelines clamp down on third-party AI (2025-11)](https://techcrunch.com/2025/11/13/apples-new-app-review-guidelines-clamp-down-on-apps-sharing-personal-data-with-third-party-ai/)
- [DEV — Apple Guideline 5.1.2(i) The AI Data Sharing Rule](https://dev.to/arshtechpro/apples-guideline-512i-the-ai-data-sharing-rule-that-will-impact-every-ios-developer-1b0p)
- [RevenueCat — Apple App Store Rejections (3.1.x ケース集)](https://www.revenuecat.com/docs/test-and-launch/app-store-rejections)
- [RevenueCat — Navigating Google Play's 14-Day testing rule](https://www.revenuecat.com/blog/engineering/google-play-14-day/)
- [iMore — Apple rejects horoscope app](https://www.imore.com/apple-rejects-developers-horoscope-app-says-app-store-has-enough)
- [Apple Developer Forums Thread 737999 — Astrology app rejection](https://developer.apple.com/forums/thread/737999)

### 日本固有
- [消費者庁 — 不実証広告規制](https://www.caa.go.jp/policies/policy/representation/fair_labeling/representation_regulation/misleading_representation/not_demonstrated_ad)
- [Stripe — 特商法表記ガイド](https://stripe.com/resources/more/specified-commercial-transactions-act-japan)

---

## 9. 変更履歴

| 日付 | 変更 | commit |
|---|---|---|
| 2026-05-27 | 初版作成 (4 並列調査結果統合 + 機械的修正 4 項目反映) | このセッション |
| 2026-05-27 | Stella V2 + Horo prompt に safety guard 追記、iOS Info.plist 整理、OSM Attribution 追加 | このセッション |
| 2026-05-27 | Apple SIWA Token Revocation 本稼働 | 23c4727 |
