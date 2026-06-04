# Solara 声と多言語化の正典 — Voice & Localization Canon v2

> **これは Solara の言葉の「単一の正典」です。** 翻訳・新規文言・i18n・声の調整に関わるときは、
> **まずこのファイルを読む**こと。ここに無い語・声を勝手に増やさない。迷ったら正典に追記してから使う。
>
> **目的**：オーナー（占い師「光源」）の**言葉とニュアンスを、言語と時間を越えて保全する**こと。
> 将来 ES / PT / FR / DE / KO へ広げても、別のセッション（別の AI）が来ても、ここから始められるようにする。
>
> 関連：`worker/src/style_voice.js`（声の本体）／[feature_inventory.md](feature_inventory.md) §0.2.56〜57／
> `utils/app_locale.dart`（ja/en/system 切替）／`utils/solara_i18n.dart`（`tr` / `categoryLabel`）。

---

## 0. マスターの声（オーナーの言葉 — 最優先で保全する核）

### 0.1 正典の声 = `STYLE_VOICE_JP`
- **声の本体は `worker/src/style_voice.js` の `STYLE_VOICE_JP`**（占い師「光源」の文体ガイド）。これが**マスター**。
- 🔒 **オーナー承認済み・無断で変えない**（2026-06-03 オーナー「満足している」と確定）。変更はオーナーの明示指示があるときだけ。
- すべての言語の声は、**この JP マスターから派生**する。`STYLE_VOICE_EN` がその第一の手本（fortune / tarot / consultation の英語プロンプトに注入済み）。

### 0.2 翻訳の大原則（どの言語でも守る）
> **言葉を置き換えるのではなく、意図と温度を写す。**
- 逐語訳をしない。**「光源ならこの言語でどう語るか」**を再表現する。
- 各言語に `STYLE_VOICE_<LANG>` を作り、§0.3 の哲学と §0.1 のマスターの精神を保つ。
- 語彙（§2〜§5）は正典の対訳を使う。トーン規則（§7）は**言語非依存の絶対ルール**として全言語に適用。

### 0.3 ブランド哲学（WHY — 言葉の背骨。翻訳者はここを守る）
1. **吉凶を出さない・中立**：Soft（流れ・受容・拡大・調和）と Hard（摩擦・変容・対峙・深化）は**独立した別エネルギー**。「良い/悪い」ではなく性質の違い。Hard は「悪い」ではなく「向き合う招待・覚悟が要るかもしれない機会」。
   *なぜ*：ユーザーを判断で縛らず、自分で選ぶ余地を残すため（=「意図する」思想の土台）。
2. **意図する**：基準点も日時も**自分で決める**。正解・不正解はなく、**あなたが決めたことが正解**。星に振り回されるのでなく、意図して味方につける。
   *なぜ*：Solara の核心。主導権をユーザーの手に戻す。
3. **予測・保証しない**：未来の言い当てではなく、膨大なエビデンスから導いた**「ひとつの解釈」**。違和感があれば自分の解釈を重ねてよい。
   *なぜ*：娯楽・自己探求の誠実さ／審査適合／占いの倫理。
4. **Stella = 占い師「光源」の分身**：20年超の人生相談の経験と「**あなたに幸せになってほしい**」という願いを託した存在。**常にあなたの味方**。🔴 自分を「AI」「人工知能」とは**名乗らない**。
   *なぜ*：温度と信頼の中心。Stella は道具ではなく寄り添う存在。
5. **読心しない**：他人や第三者の私的な心を事実として断定しない（「彼はこう思っている」は禁止）。「**あなたが何を意識し・どう動き・いつ動くか**」へ変換する。
   *なぜ*：誠実さ。占い師としての一線。
6. **名前・挨拶・前置きをしない**：呼びかけや定型の前置きで始めない。**語り口だけで声を出す**。締めも命令・「すべき」にしない（余韻で終えてよい）。
   *なぜ*：押し付けない。読み手の主体性を尊重する。
7. **文体ハイブリッド（日本語の妙）**：エネルギー描写＝観察（だ・である）、語りかけ＝寄り添い（ですます）。英語等では「叙述（plain）＋語りかけ（gentle）」のブロック切替で再現。
   *なぜ*：事実の静けさと、人への温かさを同居させる。
8. **誠実な静けさ**：何も無い場所を「隠れたパワーが」と持ち上げない。正直に「テーマの線が遠い、静かな場」と言う。
   *なぜ*：盛らない誠実さが信頼になる。

### 0.4 オーナーの声の源泉（保全ポインタ — 失わないために）
| 源泉 | 場所 | 役割 |
|---|---|---|
| 文体ガイド（マスター） | `worker/src/style_voice.js` `STYLE_VOICE_JP` | 声の本体 🔒 |
| 設計思想マニフェスト | `lib/utils/solara_manifesto.dart`（JP/EN） | Soft/Hard・中立の世界観 |
| 哲学画面 | `lib/screens/solara_philosophy_screen.dart` | ユーザーに見せる哲学 |
| オーナーの「魂」原稿 | `Solaraアプリの魅力.docx`（オーナー私物） | 声・物語の一次資料 |
| 設計思想メモ | memory `project_solara_design_philosophy.md` | 吉凶回避の確定経緯 |
| 相談の表現ルール | `worker/src/consultation_v2.js` 冒頭 + 12原則 | 相談ナレーションの規範 |

---

## 1. 運用ルール（現状 — 2026-06-03 slang 採用）
- **i18n 基盤 = `slang`**（pub `slang`/`slang_flutter`/dev `slang_build_runner`）。対訳ソースは `lib/i18n/<locale>.i18n.json`（`ja.i18n.json`=base/master, `en.i18n.json`, 将来 `es/pt/fr/de/ko`）。生成コードは `lib/i18n/strings*.g.dart`（**コミット対象**）。設定は `slang.yaml`（base_locale=ja, fallback_strategy=base_locale, flat_map=true, lazy=false, timestamp=false）。
- **アクセス方法**：① 型安全 `t.category.overall`（`import '../i18n/strings.g.dart'`）＝新規実装はこちらを使う。② 動的キー `tr('category.overall')`（`utils/solara_i18n.dart` の薄いファサード、slang flat map 委譲）＝既存コード互換。
- **ロケール切替**：`AppLocale`（utils/app_locale.dart）が `ja`/`en`/`system` を `MaterialApp.locale` に注入し、同時に notifier listener で **slang `LocaleSettings`** へ橋渡し（`_syncSlang`）。
- **EN 表示の完成度ゲート**：`_syncSlang` は **override=='en' のときだけ** slang を en にする（端末が英語でも override 未設定なら ja）。理由：EN カバレッジが揃うまで「半分英語の UI」を出さない＋test 安定。**揃ったら（`dart run slang analyze` で `_missing_translations.json` の `en:{}` を確認）`_syncSlang` を system 連動へ広げる**。
- **API の言語**：Worker へ送る `lang` は `currentLang()`（solara_i18n.dart）が単一の真実源。
- **ワークフロー（必須）**：`<locale>.i18n.json` を編集 → `dart run slang`（再生成）→ `dart run slang analyze`（未訳検出）→ analyze=0 を確認して `strings*.g.dart` ごとコミット。
- **キー命名**：`namespace.camelCase`（例 `category.overall`）。namespace = `category` / `feature` / `metric` / `place` / `brand` / `energy` / `astro` / `tone` / `disclaimer`。
- **内部キー（'overall','love' 等の英字 id）は不変**。正典が固定するのは「表示語」と「i18nキー」。

---

## 2. カテゴリ（最重要・全画面で反復）
> ルール：**カテゴリ名に「運」を付けない**。どの言語でも吉凶語（lucky/good 等）を使わない。

| 内部id | i18nキー | ja | en | es | pt | fr | de | ko |
|---|---|---|---|---|---|---|---|---|
| overall/all | `category.overall` | 総合 | Overall | General | Geral | Général | Gesamt | 종합 |
| healing | `category.healing` | 癒し | Healing | Sanación | Cura | Apaisement | Heilung | 치유 |
| money | `category.abundance` | 豊かさ | Abundance | Abundancia | Abundância | Abondance | Fülle | 풍요 |
| love | `category.love` | 恋愛 | Love | Amor | Amor | Amour | Liebe | 사랑 |
| work/career | `category.work` | 仕事 | Work | Trabajo | Trabalho | Travail | Arbeit | 일 |
| communication | `category.talk` | 話す | Talk | Hablar | Conversar | Parler | Reden | 대화 |
| newStart | `category.change` | 変化 | Change | Cambio | Mudança | Changement | Wandel | 변화 |

> 🔴 money は全言語で「豊かさ/Abundancia 系」＝ Money/Wealth/金運 を使わない（吉凶回避）。
> 🟡 es/pt/fr/de/ko はドラフト（ネイティブ確認推奨、特に de/ko）。

**言語別 禁止語/代替語（トーン規則 §7 の各言語版・抜粋）**
| 言語 | 🚫 吉凶/予測（禁止） | ✅ 代替 |
|---|---|---|
| es | afortunado/desafortunado, buen/mal día, suerte, predecir, garantizar | la energía presente, suave/tenso, se intensifica/se suaviza |
| pt | sortudo/azarado, bom/mau dia, sorte, prever, garantir | a energia presente, suave/tenso, intensifica-se/suaviza-se |
| fr | chanceux/malchanceux, bon/mauvais jour, prédire, garantir | l'énergie présente, doux/tendu, s'intensifie/s'adoucit |
| de | Glück/Pech, guter/schlechter Tag, vorhersagen, garantieren | die vorhandene Energie, sanft/hart, wird stärker/sanfter |
| ko | 행운/불운, 좋은/나쁜 날, 길흉, 예언/예측, 보장 | 지금 있는 에너지, 부드러움/단단함, 강해진다/누그러진다 |

> communication：Map/Horo/Observe＝「話す」/ Talk に統一済。相談の compound テーマ「対話・学び」は Talk & Learning。

---

## 3. 機能名
| JP（master） | EN | i18nキー | メモ |
|---|---|---|---|
| 星読み（Horo 日次） | **Star Reading** | `feature.starReading` | Horo の「今日の」読み |
| 読み解き（総称・旧「占い」） | **Interpretation** | `feature.interpretation` | 星読み/タロット/相談の結果の総称。"Reading" と衝突回避＋「解釈の一つ」思想 |
| 方位エネルギー（旧 運勢方位） | Directional Energy | `feature.directionalEnergy` | Map 16方位の扇 |
| 星のサイクル（旧 運勢サイクル） | Star Cycle | `feature.starCycle` | Forecast の「◯◯期」 |
| ハイライト Top5（旧 強運Top5） | Highlights Top 5 | `feature.highlightsTop5` | |
| 高まる方位（旧 強運方位） | Peak Direction | `metric.peakDirection` | |
| 5年の流れ（旧 5年予測） | 5-Year Flow | `feature.fiveYearFlow` | Pro |
| Stella 相談 | Stella Consultation | `feature.stellaConsult` | |
| タロット | Tarot | `feature.tarot` | |
| ホロスコープ | **Horoscope** | `feature.horoscope` | 画面名 |
| 出生図 / 円盤チャート | **Birth Chart** | `astro.birthChart` | チャートのオブジェクト |
| ヒートマップ | Heatmap | `feature.heatmap` | |
| Star Atlas（星座アーカイブ） | Star Atlas | `feature.starAtlas` | |
| 称号（クラス） | Title | `feature.title` | |
| 二つ名 | Epithet | `feature.epithet` | 生涯固定の方 |

---

## 4. 場所・地図の概念
| JP | EN | i18nキー | メモ |
|---|---|---|---|
| VIEWPOINT | VIEWPOINT | `place.viewpoint` | 固定（翻訳しない） |
| LOCATIONS | LOCATIONS | `place.locations` | 固定 |
| 拠点（登録地点） | Saved Place | `place.savedPlace` | |
| 現住所 | Current Address | `place.currentAddress` | home ピン |
| 出生地 | Birthplace | `place.birthplace` | |
| 引越し（シミュレーション） | Relocation | `feature.relocation` | Pro。中立：吉凶でなく「強まる/やわらぐ」 |
| アスペクトライン | Aspect Lines | `astro.aspectLines` | |
| 天頂帯・天底帯 | Zenith / Nadir Zones | `astro.zenithNadirZones` | Pro |
| 天頂点・天底点 | Zenith / Nadir Point | `astro.zenithNadirPoint` | |

---

## 5. ブランド・世界観の固定語（翻訳しない or 固定綴り）
`Solara` ／ `Stella` ／ `Cosmic Pro` ／ `ACG`・`CCG`（初出のみ Astrocartography / Cyclocartography）／ `VIEWPOINT`・`LOCATIONS`

| JP | EN | i18nキー |
|---|---|---|
| ソフト（エネルギー） | Soft (energy) | `energy.soft` |
| ハード（エネルギー） | Hard (energy) | `energy.hard` |
| 在るエネルギー | the energy present | `energy.present` |
| 新月 / 満月 | New Moon / Full Moon | `astro.newMoon` / `astro.fullMoon` |
| 刻星化（カタステリズム） | Catasterism | `feature.catasterism` |

---

## 6. 占星術の一般語（標準英語をそのまま使う）
スペルだけ固定。`transit` / `progressed` / `natal` / `aspect`（conjunction / opposition / trine / square / sextile / quincunx）/ `house` / `retrograde` / `ingress` / `eclipse` / `node` / `orb` / `ASC` `MC` `DSC` `IC`。
特殊パターン：`Grand Trine`（グランドトライン）/ `T-Square`（Tスクエア）/ `Yod`（ヨッド）。
> 他言語でも占星術用語は各言語の慣用訳 or 英語を使い、Solara 独自語（§5）だけ固定。

---

## 7. トーン規則（★言語非依存の絶対ルール。全言語に適用）
個別語より、**翻訳者が吉凶/予測を再混入しないためのルール**を最優先で守る。

### 7.1 吉凶を出さない
- 🚫 禁止（例・EN）：`lucky / unlucky / fortunate / good day / bad day / best / worst / auspicious`
- ✅ 代替：`the energy present` / `soft & hard` / `grows stronger / softer` / `where … is strong`

### 7.2 予測・保証しない
- 🚫 禁止（例・EN）：`predict / forecast / guarantee / will happen / destined to`
- ✅ 代替：`rhythm / flow / tendency / a reading / one interpretation`

### 7.3 正典ディスクレーマ（言語ごとに一本に固定）
| 用途 | JP（master） | EN |
|---|---|---|
| 中立注記 | これは「良い・悪い」の判定ではありません。在るエネルギーの一例をお伝えするだけ。どう動くかは、あなたが選びます。 | This is not a judgment of "good" or "bad." It simply shows one of the energies present here. How you move with it is your choice. |
| AI フッター | ✦ AI 生成・娯楽目的。医療・法律・金融等の専門的な助言ではありません。 | ✦ AI-generated, for entertainment & self-reflection. Not professional medical, legal, or financial advice. |
| 重要注記 | Solara の占星術・タロット・相談は、すべて娯楽および自己探求のためのものです。専門的な助言（医療・法律・金融・心理）ではなく、将来を予測・保証するものでもありません。 | Solara's astrology, tarot, and consultations are for entertainment and self-exploration only. They are not professional advice (medical, legal, financial, or psychological), and do not predict or guarantee the future. |
| 取得失敗 | 解説の取得に失敗しました。通信状況を確認して、もう一度お試しください。 | We couldn't load the reading. Please check your connection and try again. |
| 再試行 | 再試行 | Try again |
| 拠点の中立 | 吉凶ではなく「強まる／やわらぐ」の傾きです。 | Not fortune or misfortune — just where energies grow stronger or softer. |

---

## 8. 多言語展開（将来：ES / PT / FR / DE / KO）

### 8.1 対象言語と状態
| 言語 | コード | UI語彙 | Gemini の声 (`STYLE_VOICE_<LANG>`) | 状態 |
|---|---|---|---|---|
| 日本語 | ja | ✅ master | ✅ `STYLE_VOICE_JP`（マスター） | 運用中 |
| 英語 | en | ✅ 確定（本正典） | ✅ `STYLE_VOICE_EN`（fortune/tarot/consultation 注入済） | Worker 済・**アプリ活性化は未**（§8.4） |
| スペイン語 | es | 🟡 カテゴリ/トーン確定 | ✅ `STYLE_VOICE_ES` | Gemini出力済（声+出力言語指示）・月儀式済／アプリUI全訳・活性化は未 |
| ポルトガル語 | pt | 🟡 カテゴリ/トーン確定 | ✅ `STYLE_VOICE_PT` | 同上 |
| フランス語 | fr | 🟡 カテゴリ/トーン確定 | ✅ `STYLE_VOICE_FR` | 同上 |
| ドイツ語 | de | 🟡 カテゴリ/トーン確定 | ✅ `STYLE_VOICE_DE` | 同上・🟡出荷前ネイティブ確認推奨 |
| 韓国語 | ko | 🟡 カテゴリ/トーン確定 | ✅ `STYLE_VOICE_KO` | 同上・🟡出荷前ネイティブ確認推奨 |

> **Gemini 出力の多言語化方式（2026-06-03 確定）**：fortune/tarot/consultation_v2 は、非 ja 言語では**英語の指示プロンプトを土台**にしつつ、`outputLangDirective(lang)`（「出力は必ず {言語} で」）＋言語別 `styleVoiceFor(lang)`（声）を注入する。Gemini は「英語で指示→対象言語で出力」を正確にこなすため、5言語ぶんのフルプロンプトを書かずにネイティブ出力＋光源の声を実現。未知 lang は英語へフォールバック。`relocation.js` は ja/en のみ（中立解説・声なし＝今回対象外）。

### 8.2 各言語が必要とするもの（チェックリスト）
1. `worker/src/style_voice.js` に **`STYLE_VOICE_<LANG>`**（§0.1 マスターから派生・§0.3 哲学を保つ）。
2. fortune.js / tarot.js / consultation_v2.js の **`lang==='<lang>'` 分岐**（ラベル表＋ヘルパー＋プロンプト＋声注入）。consultation_v2 は EN 実装（`*_EN` 群）が雛形。
3. `solara_i18n.dart` の語彙テーブルに **`<lang>` 値**（§2〜§5・§7.3 ディスクレーマ）。
4. §7 トーン規則の **言語別 禁止語/代替語**（その言語の「吉凶/予測」語）。

### 8.3 翻訳の進め方（重要）
- **占星解説・相談ナレーションは、各言語ネイティブの占い師感覚で再表現**（逐語訳は声が死ぬ）。§0.2 の大原則に従う。
- UI ラベル・ディスクレーマは正典の対訳で**一語一対**に固定（ブレ防止）。
- カバレッジが揃うまで `isEnLocale()` 同様、その言語は**明示切替時のみ**表示（半訳UIを出さない）。

### 8.4 🔴 活性化ギャップ（全言語共通）
- Worker に声を入れても、**アプリが API 呼出で `lang` を送らなければ生成は ja のまま**。
- 活性化には fortune/tarot/consultation の各 API リクエストに **`lang = 現在ロケール`** を渡す配線が要る（`isEnLocale()` 等を起点に）。EN/各言語 UI 本格ロールアウトと同時に行う。

---

## 9. 新しい言語を追加する手順（テンプレート）
1. 本正典 §8.1 の状態表に行を起こす。
2. `STYLE_VOICE_<LANG>` を作る（§0.1 マスター＋§0.3 哲学を再表現、§0.2 を厳守）。`STYLE_VOICE_EN` を手本に。
3. Worker 3ファイルに `lang` 分岐を追加（consultation は `*_EN` 群が雛形）。
4. `solara_i18n.dart` に `<lang>` 列を追加（§2〜§5・§7.3）。
5. §7 の禁止語/代替語をその言語向けに用意。
6. テスト（worker：声注入＋日本語/英語が混ざらない、Flutter：override で表示切替）。
7. アプリ側 `lang` 配線（§8.4）。
8. 本正典の §8.1 を ✅ に更新し、決定ログ（§10）に記す。

---

## 10. 決定ログ
- 話す → **Talk**（Connect/Communication は不採用）。
- 星読み（Horo）= **Star Reading** ／ 総称 読み解き = **Interpretation**。
- ホロスコープ = **Horoscope** ／ 出生図・チャート = **Birth Chart**。
- 豊かさ = **Abundance**（🔴 Money/Wealth 禁止）／ 仕事 = Work ／ 総合 = Overall ／ 称号 = Title ／ 二つ名 = Epithet。
- `STYLE_VOICE_JP` = **オーナー承認のマスターの声・無断変更不可**（2026-06-03）。
- `STYLE_VOICE_EN` 作成、fortune/tarot/consultation の英語プロンプトに注入（2026-06-03）。英語版 Stella 相談プロンプトを新規構築（JP 不変・EN 関数追加）。
- 多言語ターゲット確定：ES / PT / FR / DE / KO（将来）。本 v2 で「声・哲学・手順」を正典化。
- 月の儀式ストーリー（新月/満月/刻星化）の**全文**を ES/PT/FR/DE/KO で書き起こし（`cycle_story_texts.dart`・日本語マスターから・性別中立・区切り数一致）。あわせて**英語版が落としていたニュアンス**（新月「いつも見守っている」／刻星化「未来のあなたがこの苦しい物語を書き換えられる」）を日本語マスターから復元（2026-06-03）。⚠️ 表示の活性化（`supportedLocales` 登録）は未／de・ko は出荷前にネイティブ確認推奨。
- カテゴリ（総合/癒し/豊かさ/恋愛/仕事/話す/変化）＋トーン禁止語を ES/PT/FR/DE/KO で確定（§2）。`STYLE_VOICE_ES/PT/FR/DE/KO`（各言語ネイティブの光源の声）を作成し、fortune/tarot/consultation_v2 を**出力言語ディレクティブ方式**で全言語対応（§8.1 注記）。worker test 44件 green（2026-06-03）。
- **英語化 Phase 1 (UI chrome) 完了 → Phase 2 (content/data) 完了 → Phase 3 (lang活性化) 実施**（2026-06-04・ブランチ `feat/solara-en-localization` push 済）。
  - Phase 2: 純データ = ja const 保全 → `xEN` 併設（大物は別ファイル並列）→ `isEnLocale()` で選択。完了 = celestial_event_meanings / consultation_share / astro_zenith_messages / horo_aspect_description / Galaxy星座名 / planet_intro / title_data(+称号表示配線) / astro_glossary / daily_transit_data(728・最大)。**吉凶回避**の定型: 「良い・悪い」の判定でない → *"not a verdict of good or bad … you choose"*、始動=beginnings / 顕在化=coming into the open / 対峙=facing / 浸透=settling inward、money→**Abundance**。
  - Phase 3: 完成度ゲートを system 連動へ解除（端末英語→en）。AI 4経路（fortune/tarot/relocation/consultation）に `lang: currentLang()` を配線（従来 ja 固定）。Worker は EN 実装済を確認し `npx wrangler deploy` で本番反映（Version `a3b57063`）。
  - 残: 英語 E2E（実機/AAB）→ ストア英語化（Phase 4）→ 申請（Phase 5）。de/ko ネイティブ確認は出荷前。
