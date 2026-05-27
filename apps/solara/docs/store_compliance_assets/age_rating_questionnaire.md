# Solara — Age Rating 質問票 推奨回答

> Apple App Store Connect の新 Age Rating 質問票 (2025-07 改訂、**2026-01-31 期限**) と
> Google Play IARC 質問票 への推奨回答ドラフト。
>
> **推奨 Age Rating: 13+ (Teen)**
>
> 関連: [store_compliance.md](../store_compliance.md) §2.2 / [legal.md](../legal.md) §3
>
> 最終更新: 2026-05-28

---

## 0. 推奨レーティング理由

### 13+ を選ぶ理由
- ✅ 出生情報入力 (生年月日・出生時刻・出生地) = ある程度の判断力が必要
- ✅ 移住・転職・結婚等の人生相談機能 = 大人向けトピック
- ✅ AI 生成コンテンツの**予測不可能性** (2025-07 新設項目に該当)
- ✅ サブスクリプション (Cosmic Pro) = 課金判断 = 保護者の同意が必要なレベル
- ✅ 占い・タロット = ライト宗教/オカルト要素

### 16+ を選ばない理由
- 性的内容・暴力・薬物等は一切なし
- 占いの「悪魔」「死神」「塔」カードはタロットの古典シンボルで、ホラーではない
- Apple/Google 共に「Fortune Telling 単独 = 16+」というガイドラインはない

### 18+ を選ばない理由
- 該当する要素 (ギャンブル / 性的 / 違法薬物等) は一切なし

---

## 1. Apple App Store Connect 新 質問票 (2025-07 改訂)

新体系: 4+ / 9+ / 13+ / 16+ / 18+
締切: **2026-01-31** (期限超過で update 提出ブロック)

### 1.1 暴力 (Violence)

| 項目 | 回答 | 備考 |
|---|---|---|
| Cartoon or Fantasy Violence | None | - |
| Realistic Violence | None | - |
| Prolonged Graphic or Sadistic Realistic Violence | None | - |

### 1.2 性的内容と裸体 (Sexual Content and Nudity)

| 項目 | 回答 | 備考 |
|---|---|---|
| Sexual Content and Nudity | None | - |
| Graphic Sexual Content and Nudity | None | - |

### 1.3 不適切な言葉 (Profanity and Crude Humor)

| 項目 | 回答 | 備考 |
|---|---|---|
| Profanity or Crude Humor | None | Gemini prompt で禁止語フィルタあり |

### 1.4 ホラーとサスペンス (Horror / Suspense)

| 項目 | 回答 | 備考 |
|---|---|---|
| Horror / Fear Themes | **Infrequent / Mild** | タロットの「死神」「悪魔」「塔」カードは古典的象徴。本物のホラーではない |

### 1.5 アルコール・タバコ・薬物 (Alcohol, Tobacco, Drugs)

| 項目 | 回答 | 備考 |
|---|---|---|
| Alcohol, Tobacco, or Drug Use or References | None | - |
| Glamorization of Alcohol, Tobacco, or Drugs | None | - |

### 1.6 ギャンブル (Gambling)

| 項目 | 回答 | 備考 |
|---|---|---|
| Simulated Gambling | None | - |
| Real Money Gambling | None | - |
| Contests | None | - |

### 1.7 医療/治療情報 (Medical/Treatment Info)

| 項目 | 回答 | 備考 |
|---|---|---|
| Unrestricted Medical / Treatment Information | None | Stella prompt で医療助言を禁止済み (safety guard) |

### 1.8 占い / 信念体系 (Fortune Telling / Religious Themes) ← Solara 該当

| 項目 | 回答 | 備考 |
|---|---|---|
| Fortune Telling | **Yes** | Solara のコア機能 (占星術 + タロット) |
| Religious or Cultural References | **Infrequent / Mild** | タロット = 西洋オカルト/神秘主義の古典シンボル |

### 1.9 Mature / Suggestive Themes

| 項目 | 回答 | 備考 |
|---|---|---|
| Mature or Suggestive Themes | **Infrequent / Mild** | 移住・転職・結婚等の人生判断テーマ |

### 1.10 Web ブラウジング / SNS (User-Generated Content)

| 項目 | 回答 | 備考 |
|---|---|---|
| Unrestricted Web Access | None | アプリ内ブラウザなし |
| Users can Communicate with Each Other | None | SNS 機能なし |
| Shares Location with Other Users | None | 位置情報は本人の占星術計算のみ、共有なし |
| User Generated Content | None | 相談文は本人 → AI のみ、他ユーザーへ公開しない |

### 1.11 🔴 AI 生成コンテンツ (2025-07 新設項目)

| 項目 | 回答 | 備考 |
|---|---|---|
| **AI-Generated Content with Unpredictable Output** | **Yes** | Gemini AI の出力は決定的でなく、毎回異なる解釈を返す |
| AI-Generated Content can be Used to Create Harmful Output | **No** | prompt 側で医療・法律・金融・自傷の断定禁止 + アプリ内報告ボタン設置 |

🟢 Apple は「AI 予測不可能性 = Yes」だけでは即 18+ にはならない (safety filter + 報告機能で対処していれば 13+ で通る)。

### 1.12 質問票回答結果

上記 (Fortune Telling = Yes, Religious = Mild, Mature = Mild, Horror = Mild, AI Unpredictable = Yes) で Apple のアルゴリズム上は **13+** が自動算出される見込み。

ただし Apple の最終判定は Reviewer 裁量。万一 16+ が提案されても、本アプリは違反コンテンツ無しのため申立で 13+ に戻せる可能性あり。

---

## 2. Google Play IARC 質問票

Google Play のレーティングは IARC (International Age Rating Coalition) の質問票から自動算出される。地域別レーティング:
- ESRB (米): T (Teen 13+)
- PEGI (EU): 12
- USK (独): 12
- 日本 CERO: B (12+)
- ACB (豪): PG (8+)

### 2.1 暴力 (Violence)
- Realistic Violence: No
- Cartoon/Fantasy Violence: No
- Blood and Gore: No

### 2.2 性的コンテンツ (Sexual Content)
- Sexual Content: No
- Nudity: No
- Sex Education: No

### 2.3 言葉遣い (Language)
- Profanity: No
- Crude Language: No

### 2.4 制御物質 (Controlled Substances)
- References to Alcohol/Tobacco/Drugs: No

### 2.5 ギャンブル (Gambling)
- Simulated Gambling: No
- Real Money Gambling: No

### 2.6 恐怖 (Fear / Horror)
- Fear Themes: **Mild** (タロットの伝統的象徴のみ)

### 2.7 差別 (Discrimination)
- Discriminatory Content: No

### 2.8 占星術・スピリチュアル (Astrology / Spiritual)
- Mentions of Fortune Telling, Astrology, Tarot etc: **Yes**
- このアプリは占星術 / タロットを主要機能として提供します。
- 解釈は娯楽および自己探求の目的のみ。

### 2.9 ユーザー生成コンテンツとコミュニケーション
- Users can Share Content: No
- Users can Communicate Directly: No
- User-Generated Content Visible to Other Users: No

### 2.10 AI 生成コンテンツ (Google Play 2024 以降強化項目)
- このアプリは AI が生成するコンテンツを含みますか?: **Yes**
- AI 出力に安全策はありますか?: **Yes**
  - 詳細: Gemini safety settings + Worker 側 prompt の医療・法律・金融・自傷断定禁止 + アプリ内の報告ボタン

### 2.11 個人情報・位置情報
- 位置情報の収集: Yes (出生地・現在地、機能のため必須)
- 個人情報の収集: Yes (ニックネーム・出生情報、ユーザー入力)

### 2.12 課金 (In-App Purchases)
- アプリ内課金あり: Yes (Cosmic Pro サブスクリプション + 消費型クレジット)
- 保護者の同意推奨: Yes (13+ 推奨のため)

### 2.13 IARC 自動算出見込み

上記回答で IARC が算出するレーティング:
- ESRB: T (Teen, 13+)
- PEGI: 12
- USK: 12
- CERO: B (12+)
- ACB: PG (8+) または M (15+) (PG が見込み)

→ **総合的に 13+ (Teen) で運用** が安全。

---

## 3. 提出ステップ (オーナー作業)

### Apple App Store Connect
1. App Store Connect > マイ App > Solara > App 情報
2. 「Age Rating」セクション > 「編集」
3. §1.1 ~ §1.11 の質問に回答 (本ドキュメントを参考)
4. 自動算出されたレーティング (13+ 想定) を確認 > 保存
5. **🔴 2026-01-31 までに新質問票へ移行**

### Google Play Console
1. Play Console > すべてのアプリ > Solara > ポリシーとプログラム > **アプリのコンテンツ**
2. 「コンテンツのレーティング」セクション > 「アンケートを開始」
3. 連絡先メール: `usin.kodima@gmail.com`
4. カテゴリ: 「ライフスタイル」
5. §2.1 ~ §2.12 の質問に回答 (本ドキュメントを参考)
6. 自動算出されたレーティング (Teen 想定) を確認 > 完了

---

## 4. 想定 Q&A (Reviewer / 監査人から質問される可能性)

### Q1: 「占星術アプリで Mild Religious と回答した根拠は?」
A: タロットの伝統的シンボル (大アルカナ 22 枚の象徴) を、宗教的崇拝の対象ではなく
古典的な心理的元型として扱っているため。新興宗教の勧誘や礼拝行為への誘導は一切ない。

### Q2: 「AI 出力の予測不可能性 = Yes と回答した上で 13+ で問題ないのか?」
A: Apple の 2025-07 改定後ガイドラインによれば、AI 予測不可能性 = Yes でも以下を満たせば
13+ で通る:
- 出力前の safety filter (Solara: Gemini safety settings + Worker prompt)
- ユーザーが報告できる機能 (Solara: 全 AI 結果画面に「報告」ボタン設置済)
- 利用前の明示同意 (Solara: 初回起動の AiConsentScreen)

### Q3: 「移住助言 = 重大な人生判断、なぜ 13+ で十分か?」
A: 本アプリは候補地を**比較検討する観点**を提供するもので、特定の移住先を断定・推奨
しない (Stella prompt で「最終判断は本人」を明示)。情報提供のレベルは新聞のライフ
スタイル記事と同等。

---

## 5. 変更履歴

| 日付 | 内容 |
|---|---|
| 2026-05-28 | 初版作成 (G9 対応、Apple 2025-07 新体系 + Google IARC) |
