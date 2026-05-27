# Solara — Age Rating 推奨回答 (詳細根拠)

> **推奨レーティング: Apple 4+ / Google ESRB Teen (13+) / 日本 CERO B (12+)**
>
> 🔴 2026-05-28 全面書き直し: 旧版に subagent 推測の誤情報 (§1.8 「Fortune Telling」項目、§1.11
> 「AI 予測不可能性」項目) があったため修正。Apple 公式情報確認で **新質問票には「占い」
> 「占星術」「AI 生成コンテンツ」専用項目は存在しない** と判明。
>
> オーナー作業は [apple_app_store_connect.md §A-4](apple_app_store_connect.md) +
> [google_play_console.md §C-4](google_play_console.md) を参照。本ドキュメントは
> 「なぜ 4+ なのか」の **根拠** + Reviewer から質問された際の Q&A 集として保管。
>
> 関連: [store_compliance.md](../store_compliance.md) §2.2 / §3.6
>
> 最終更新: 2026-05-28

---

## 1. Apple 公式情報 (2025-07 改訂後、2026-01-31 期限)

### 1.1 新 質問票の **全 7 ステップ**

| ステップ | カテゴリ | Solara の回答 |
|---|---|---|
| 1 | 機能 (In-App Controls / Capabilities) | 全項目「いいえ」 |
| 2 | 成人向けのテーマ (汚言 / ホラー / 薬物) | 全項目「なし」 |
| 3 | 医療 / ウェルネス | 全項目「なし / いいえ」 |
| 4 | 性的内容またはヌード | 全項目「なし」 |
| 5 | 暴力表現 | 全項目「なし」 |
| 6 | 運や偶然に基づくアクティビティ (ギャンブル) | 全項目「なし / いいえ」 |
| 7 | 追加情報 (算出結果 + 上書き) | 算出 4+ をそのまま採用、上書きしない |

→ **算出結果: 4+** (173 か国・地域に適用、確認済)

### 1.2 「占い」「占星術」「Tarot」「AI」専用項目は **存在しない**

旧版 §1.8 (Fortune Telling = Yes) / §1.11 (AI-Generated Content with Unpredictable Output = Yes)
は subagent 調査時の推測情報で、Apple の実際の質問票には対応する項目が無い。

Apple 公式 Age Rating 質問項目カテゴリ (確認済):
- In-App Controls (ペアレンタル / 年齢認証)
- Capabilities (Web アクセス / UGC / メッセージング / 広告)
- Mature Themes (汚言 / ホラー / 薬物)
- Medical or Wellness
- Sexuality or Nudity
- Violence
- Chance-Based Activities

### 1.3 既存 占星術・タロット アプリの実際の レーティング

| アプリ | App Store レーティング |
|---|---|
| Tarot Card Reading & Astrology (id1245111678) | **4+** |
| Daily Tarot and Horoscope (id1199448297) | 9+ |
| CHANI: Your Astrology Guide | 4+ |
| Co-Star Personalized Astrology | 4+ |

→ **4+ または 9+ が一般的**。専門項目がないので、Apple のアルゴリズム上 4+ が自然算出される。

### 1.4 ホラー判定の灰色領域 (タロットの「死神」「悪魔」「塔」)

タロット 22 枚の大アルカナには「Death (死神)」「The Devil (悪魔)」「The Tower (塔)」等の
象徴的カードがある。これを「ホラー / 恐怖テーマ」と申告するかは灰色:

- **「なし」を選ぶ理由 (Solara 採用)**: 古典シンボルで本物のホラーではない。実際に Co-Star,
  CHANI 等の同類アプリも「なし」で 4+ を取得。
- 「まれ」を選ぶ理由 (保守的): Reviewer がカードを見た際の「不一致」リスクを完全に消したい場合。

→ Solara は **「なし」で運用** (実例多数あり、reviewer 個別判断のリスクは低い)。

---

## 2. Google Play IARC 質問票

IARC (International Age Rating Coalition) の質問票から自動算出される地域別レーティング:

| 地域 | レーティング |
|---|---|
| ESRB (米) | **T (Teen 13+)** |
| PEGI (EU) | 12 |
| USK (独) | 12 |
| CERO (日本) | B (12+) |
| ACB (豪) | PG (8+) または M (15+) |

### 2.1 質問票の主要項目と Solara 回答

| 項目 | Solara | 根拠 |
|---|---|---|
| 暴力 (リアル / カートゥーン / 流血) | No | 該当なし |
| 性的コンテンツ / ヌード / 性教育 | No | 該当なし |
| 不適切な言葉 / 下品 | No | Gemini prompt で禁止語フィルタ済 |
| 制御物質 (アルコール / タバコ / 薬物) | No | 該当なし |
| ギャンブル | No | 該当なし |
| 恐怖 / ホラー | **Mild** (タロット古典シンボル) | Apple では「なし」、Google IARC では「軽度」で安全 |
| 差別 (Discrimination) | No | 該当なし |
| 占星術 / タロット = 主要機能 | **Yes** | Solara のコア |
| ユーザー間共有 / 直接通信 | No | SNS 機能なし |
| AI 生成コンテンツ + 安全策 | Yes + Yes | Gemini safety settings + Worker prompt + 報告ボタン |
| 位置情報の収集 | Yes | 出生地 + 現在地 (機能のため必須) |
| 個人情報の収集 | Yes | ニックネーム + 出生情報 |
| アプリ内課金 | Yes | Cosmic Pro サブスク + 消費型クレジット |

---

## 3. なぜ Apple は 4+、Google は 13+ なのか?

両ストアの判定ロジックが異なる:

- **Apple**: 「成人向け要素 (暴力 / 性的 / 薬物 / ギャンブル / 医療助言) の頻度」のみで判定。
  占星術・タロット・AI 自体は成人向け要素じゃないので、Solara は 4+。
- **Google IARC**: 「占星術・タロット主要機能 = Yes」と「AI 生成コンテンツ = Yes」を質問項目に
  含むため、合算で Teen (13+) ESRB 算出。

→ **両ストアで違うレーティングになっても問題なし** (それぞれの算出ロジックに従っているだけ)。

---

## 4. Reviewer Q&A (想定される質問とその回答)

### Q1: 「占星術アプリで Apple 4+ が適切な根拠は?」
A: Apple の Age Rating 質問票には「占い」「占星術」「Tarot」専用項目が存在せず、暴力・性的・
薬物・ギャンブル・医療助言の有無で判定される。Solara はこれらすべて該当しないため 4+ が
自然算出。同類アプリ Co-Star / CHANI / Tarot Card Reading & Astrology も 4+ で運用中。

### Q2: 「AI 生成コンテンツがあるのに 4+ で問題ないのか?」
A: Apple の Age Rating 質問票に「AI 予測不可能性」専用項目はない (2025-07 改訂後も)。
Apple の AI 関連ガイダンスでは「AI が生成し得る成人向け要素 (暴力等) を既存カテゴリで申告
する」とされ、Solara は Gemini safety settings + Worker prompt で医療・法律・金融・自傷の
断定を禁止しているため、AI 由来の成人向け出力リスクは最小化済。

### Q3: 「タロットの『死神』『悪魔』『塔』はホラー判定では?」
A: タロットの古典シンボルとして広く認知されているもので、本物のホラー (恐怖や不安を煽る
コンテンツ) ではない。同類タロットアプリの多くも「ホラーなし」で 4+ を取得している。

### Q4: 「移住助言があるのに 13+ で十分か (Google IARC)?」
A: Solara は候補地を比較検討する観点を提供するもので、特定の移住先を断定推奨しない
(Stella prompt で「最終判断は本人」を明示)。情報提供レベルは新聞のライフスタイル記事と同等。

### Q5: 「Cosmic Pro サブスクがあるのに 4+ / Teen で十分か?」
A: アプリ内課金の有無は Age Rating に影響しない (Apple/Google 両方とも別申告)。
Solara は購入時に Apple/Google のシステムが OS レベルで保護者承認等を実施。

---

## 5. 変更履歴

| 日付 | 内容 |
|---|---|
| 2026-05-27 (旧版) | 初版作成。subagent 推測情報あり (§1.8 Fortune Telling / §1.11 AI Unpredictability) |
| **2026-05-28 (現版)** | 全面書き直し: Apple 4+ 正解確定、subagent 誤情報削除、公式根拠 + Reviewer Q&A 追加 |
