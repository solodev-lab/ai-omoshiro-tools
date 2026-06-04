# 層 1b: 静的データ辞書

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 15 / 総行数: 6022
- class/mixin/extension/enum: 20
- 関数 (top-level + method の素拾い): 56
- Navigator.push 等: 0
- Popup/Dialog 呼出: 1
- Worker URL リテラル: 0

## ファイル別

### `lib/screens/horoscope/horo_aspect_description.dart` (220 行)

**ファイル先頭コメント:**

```
══════════════════════════════════════════════════════════════
Aspect Description Data
惑星の意味 + アスペクトの性質 を組み合わせて読める文章を生成
══════════════════════════════════════════════════════════════

英語化Phase 2: 日本語マップを正典に planetInfoEN/aspectInfoEN/patternDescriptionsEN を
STYLE_VOICE_EN で併設。buildAspectDescription / patternDescriptionFor が isEnLocale()
で選択。Soft(調和)/Hard(緊張)は吉凶でなく質の違いとして中立に (lucky/predict 不使用)。
```

**imports:** dart=0 / package=0 / relative=1

- relative: `../../utils/solara_i18n.dart`

**関数 (1 public + 0 private):**

- L190 `buildAspectDescription()` — アスペクト説明を生成 (3セクション・ロケール連動)


### `lib/screens/horoscope/horo_constants.dart` (140 行)

**imports:** dart=0 / package=1 / relative=1

- relative: `../../utils/solara_i18n.dart`

**関数 (7 public + 0 private):**

- L15 `signLabel()` — 星座インデックス (0=牡羊…11=魚) → ロケール別表示名 (ja=漢字 / en=英名)。
- L28 `planetLabel()` — 惑星キー → ロケール別表示名 (ja=漢字 / en=英名)。horoscope 系画面で再利用。
- L98 `applyHoroOrbSettings()` — Sanctuary のオーブ設定を適用する。horoscope_screen から呼ばれる。
- L104 `horoAspectOrb()` — アスペクト種別キー (conjunction/trine/...) の有効 orb。
- L108 `horoPatternOrb()` — パターン orb キー (grandtrine/tsquare_opp/...) の有効 orb。
- L114 `horoOrbSignature()` — 現在のオーブ override の状態を表す署名文字列。
- L128 `patternLabel()` — patternStyles の 1 エントリ → ロケール別ラベル (ja=labelJP / en=label)。


### `lib/screens/map/daily_transit_data.dart` (1154 行)

**ファイル先頭コメント:**

```
============================================================
Daily Transit 画面用 データ定義
元: map_daily_transit_screen.dart 内の private const 群
2026-04-30 セッション最終整理でファイル分割（約220行）

含むもの:
  - AngleFilter enum + ラベル/セット/意味マップ
  - CategoryFilterTips (5カテゴリ × 外向き/内向き各4tips)
  - planetAngleBaseText (10惑星 × 4アングル = 40パターン基本意味)
  - categoryAppendix (5カテゴリ × カテゴリ別補足文)
  - categoryPlanetSets (worker と同一の担当惑星セット)

Solara 設計思想: project_solara_design_philosophy.md
  両面思想・吉凶判定なし・ユーザーが読み取って判断

英語化 Phase 2: 各 const の英語版は daily_transit_data_en.dart /
daily_transit_data_en2.dart に並列で持ち、末尾の *For アクセサが
isEnLocale() で選択する (JP フォールバック)。消費側はアクセサを呼ぶ。
============================================================
```

**imports:** dart=0 / package=0 / relative=3

- relative: `daily_transit_data_en.dart`, `daily_transit_data_en2.dart`, `../../utils/solara_i18n.dart`

**型定義 (3):**

- L27 `typedef CategoryTips`
  - カテゴリ tips ボックスの record 型 (categoryFilterTips の値型)。
- L39 `typedef TitledBody`
  - title + body の record 型 (categoryTipsIntent / angleDetailContent の値型)。
- L47 `enum AngleFilter`
  - アングルフィルタ識別子。

**関数 (4 public + 0 private):**

- L1112 `angleFilterLabelFor()` — アングルフィルタのラベル (en で all のみ英語化、他はコード共通)。
- L1118 `angleFilterShortMeaningFor()` — アングルフィルタの「意味」1行テキスト。
- L1124 `angleIndividualSubLabelFor()` — 個別アングルの表示用サブラベル。
- L1134 `planetAngleBaseTextFor()` — 惑星 × アングル の基本意味。


### `lib/utils/astro_glossary.dart` (657 行)

**ファイル先頭コメント:**

```
============================================================
Solara Astro Glossary — Phase M2 論点4 (β案 確定)

占星術専門用語の解説辞書。AstroTermLabel widget と組み合わせて、
用語の横にiアイコンを置き、タップでグラスモーフィズム解説を出す。

設計: project_solara_astrocartography_m2.md 論点4
  全て専門用語表記 + iアイコンで補助。
============================================================
```

**imports:** dart=0 / package=1 / relative=3

- relative: `../widgets/info_popup.dart`, `solara_i18n.dart`, `astro_glossary_en.dart`

**型定義 (1):**

- L17 `class AstroGlossaryEntry`

**関数 (1 public + 0 private):**

- L621 `showAstroGlossaryDialog()` — 用語解説 popup を表示する共通ヘルパー。

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/utils/astro_zenith_messages.dart` (352 行)

**ファイル先頭コメント:**

```
天頂点 (Zenith Point) 解説メッセージ辞書。
天頂点 = 各惑星のMCライン上で 緯度=惑星赤緯δ となる唯一の地点。
「観測者が立つと惑星が物理的に頭上(高度90°)に来る」場所。
MCライン全体の中でも特に強い「シャワー直下」「ノズル先端」のスポット。
Astro*Carto*Graphy モードで天頂点マーカータップ時に表示。

英語化Phase 2: 日本語マップを正典に、astroZenithMessagesEN/astroNadirMessagesEN を
STYLE_VOICE_EN で併設 (ファイル末尾)。zenithMessageFor() が isEnLocale() で選択。
Hard エネルギー (土星/冥王星等) は吉凶でなく「質の違い」として中立に再表現。
```

**imports:** dart=0 / package=0 / relative=1

- relative: `solara_i18n.dart`

**型定義 (1):**

- L13 `class ZenithMessage`


### `lib/utils/celestial_event_meanings.dart` (119 行)

**ファイル先頭コメント:**

```
天体イベントの占星術的意味辞書
key: "${type}_${planet}" or "${type}_${planet}_${sign}"
惑星×タイプで汎用解説。星座固有の意味が必要な場合は planet_sign キーで上書き。
```

**imports:** dart=0 / package=0 / relative=1

- relative: `solara_i18n.dart`

**関数 (1 public + 0 private):**

- L115 `getEventMeaning()` — CelestialEvent から意味を取得するヘルパー (ロケール連動)。


### `lib/utils/constellation_namer.dart` (626 行)

**imports:** dart=2 / package=0 / relative=0

**型定義 (1):**

- L8 `class ConstellationNamer`
  - Constellation name generator v2.

**関数 (8 public + 1 private):**

- L142 `buildName()` — Build name directly from adjIdx + nounIdx
- L230 `rarityPercentage()` — Hash-based rarity percentage (Phase 1: mathematical).
- L243 `hueShift()` — Get the hue shift for a given adjective index.
- L300 `adjColor()` — Get adjective color for a given adjective index.
- L386 `computeMST()` — Compute Minimum Spanning Tree using Prim's algorithm.
- L420 `buildEdges()` — Build constellation edge list based on MST + shape type.
- L614 `isFlipX()` — HTML: NOUN_ART_TRANSFORMS — only index 4 (crescent) is flipX
- L617 `artAssetPath()` — Get the asset path for a noun's constellation art

  <details><summary>private 関数 1 件</summary>

  - L248 `_hash()`

  </details>


### `lib/utils/consult_restore.dart` (50 行)

**ファイル先頭コメント:**

```
押下ルート (相談入力 / 相談結果画面) の画面復元レジストリ。

Android プロセス死対策のハイブリッド復元 (SolaraStorage.saveRestoreSnapshot) の
うち、`Navigator.push` で積まれたルートを扱う部分。低 RAM 端末 (A101FC 等) で
外部アプリ (Google マップ / 共有シート等) へ離脱中に OS が Solara を kill →
復帰時コールド再起動で押下ルートが失われる問題への対策。

設計: 各画面が mount 時に capture コールバックを register し、dispose 時に
unregister する「登録スタック」。SolaraHome が paused 時に captureTop() で
最前面 (最後に登録され、まだ生存している) 画面のスナップショットを取得する。
登録スタック方式なので、入力→結果の push 連鎖や、結果を pop して入力へ戻る
ケースも追加配線なしで自然に扱える (RouteObserver 不要)。

capture は「今この瞬間の復元スナップショット (復元不要なら null)」を返す純関数。
SolaraHome が paused のタイミングで pull するので、画面側に lifecycle 監視を
持たせる必要がない (SharedPreferences への書き込みは SolaraHome に一本化)。
```

**型定義 (2):**

- L17 `class ConsultRestore`
- L46 `class _Entry`

**関数 (2 public + 0 private):**

- L24 `register()` — 画面 mount 時に呼ぶ。返ってきた token を dispose 時に [unregister] へ渡す。
- L31 `unregister()` — 画面 dispose 時に呼ぶ。


### `lib/utils/consultation_record.dart` (257 行)

**ファイル先頭コメント:**

```
Consultation Record — 自動保存 + 履歴 (V2: 全要素統合)

設計: project_solara_consultation_full_integration.md

1 件の相談 = 入力メタ (theme/mode/scope/withWhom/wish) + 枠 (innerSeason/
intro/outro) + 蓄積した候補群 (1 枚ずつ「別の候補地」で増える) + 各候補の
エビデンスを 1 つにまとめた永続化単位。

柱 3 の原則: Free でも自分の記録を永久に失わない。
検索・フィルタ等の「記録を使う道具」は Pro 機能。
```

**imports:** dart=0 / package=0 / relative=1

- relative: `consultation_v2_api.dart`

**型定義 (1):**

- L14 `class ConsultationRecord`

**関数 (4 public + 0 private):**

- L96 `copyWith()` — お気に入りフラグ等を差し替えた複製を返す。
- L161 `toReadings()` — 読み込み専用表示 (履歴詳細) のために reading 群を再構成する。
- L181 `displayName()` — 履歴カード等の見出し用候補名 (方角は「○の方角」、座標のみは「この地点」)。
- L196 `toJson()`


### `lib/utils/consultation_v2_request.dart` (359 行)

**ファイル先頭コメント:**

```
Consultation V2 リクエストモデル — consultation_v2_api.dart の part。

最小入力 (約1KB): 誕生データ + 自宅座標 + 5問の答え + preset。
Worker (consultation_engine.js runConsultationPipeline) の契約に対応する。
```

**型定義 (4):**

- L10 `class ConsultationWhen`
  - 「いつ」(when)。場面ごとに意味が変わる時間指定。
- L75 `class ConsultationPoint`
  - 具体地点 (具体地点スコープ)。地図タップ=座標のみ / 検索=店名+種類付き。
- L123 `class ConsultationScope`
  - 「どこで」(scope)。候補地点プールの作り方。
- L192 `class ConsultationRequest`
  - 相談リクエスト (最小入力 約1KB)。Worker が全計算する。

**関数 (5 public + 0 private):**

- L48 `toJson()`
- L100 `toJson()`
- L165 `toJson()`
- L279 `copyWith()`
- L306 `toJson()`


### `lib/utils/cycle_story_texts.dart` (254 行)

**ファイル先頭コメント:**

```
月齢サイクルのストーリーテキスト（JP/EN）
翻訳ではなく、それぞれの言語でネイティブに書かれたテキスト。
```

**型定義 (1):**

- L5 `class CycleStoryTexts`

**関数 (10 public + 3 private):**

- L45 `catasterismJP()`
- L57 `catasterismEN()`
- L90 `catasterismES()`
- L115 `catasterismPT()`
- L140 `catasterismFR()`
- L165 `catasterismDE()`
- L190 `catasterismKO()`
- L213 `getNewMoon()`
- L237 `getFullMoon()`
- L252 `getCatasterism()`

  <details><summary>private 関数 3 件</summary>

  - L202 `_lang()`
  - L225 `_fullMoon()`
  - L240 `_catasterism()`

  </details>


### `lib/utils/fortune_api.dart` (314 行)

**ファイル先頭コメント:**

```
Fortune API - /fortune エンドポイント (Stella の声を取得)
関連: worker/src/fortune.js

/protected/* 呼び出しは AppAttestClient.postProtected 経由 (設計 v2.1)。
middleware が log_only モードなら bypass、enforced モードなら attestation 必須。
```

**imports:** dart=1 / package=0 / relative=2

- relative: `app_attest_client.dart`, `solara_api.dart`

**型定義 (3):**

- L12 `class FortuneReading`
  - Fortune APIレスポンス
- L110 `class RelocationAngleNarrative`
- L204 `class TarotReading`

**関数 (4 public + 0 private):**

- L36 `toJson()`
- L51 `fetchFortune()` — /fortune を叩いて占い文を取得
- L164 `fetchRelocationAngleNarrative()` — /relocation を叩いてアングル近接の動的解説を取得 (全員無料)。
- L243 `fetchTarotReading()` — /tarot を叩いて1枚引きの Reading を生成する。


### `lib/utils/planet_intro.dart` (984 行)

**ファイル先頭コメント:**

```
============================================================
Solara Planet Introduction — Map 画面の惑星マーカータップ説明

Phase: 2026-05-07 全 10 惑星対応完了
  第1弾: 月 / 金星 / 木星 / 土星
  第2弾: 太陽 / 水星 / 火星 / 天王星 / 海王星 / 冥王星

トーン規約 (Solara らしさ):
  - 詩的な短文と改行のリズム
  - 「あなた」呼称・優しく語りかける
  - 占星術用語より、体験的な比喩 (光・風・種・地層など)
  - 「司る」「課題」より「授ける」「贈る」「灯す」
  - 静かな伴走感 (Stella/Solara が見守っているニュアンス)

フレームの定義:
  natal      = 出生時のホロスコープ → 生まれ持って授かったもの
  transit    = 今この瞬間の空 → 訪れる風・潮の流れ
  progressed = 内なる暦 (1日=1年法) → ゆっくり熟成する内面
============================================================
```

**imports:** dart=0 / package=0 / relative=1

- relative: `solara_i18n.dart`

**型定義 (2):**

- L23 `class PlanetIntroFrame`
- L46 `class PlanetIntro`

**関数 (1 public + 0 private):**

- L81 `frameOf()` — frame キー ('natal' / 'transit' / 'progressed') から該当 frame を返す。


### `lib/utils/solara_manifesto.dart` (141 行)

**ファイル先頭コメント:**

```
============================================================
Solara Manifesto — 設計思想の言語化

占い的吉凶判定をしない、両面思想（陰陽・Jungian）でSolaraは構成される。
ガイドページ章0（E5）から表示される、アプリの哲学的根幹。

設計根拠: project_solara_design_philosophy.md (2026-04-29 オーナー確定)

構成:
  - sections: タイトル付きセクション3つ
    1. 「☯ Solaraが信じる世界観」(opening)
    2. 「2つのエネルギー」(soft/hardの説明)
    3. 「Solaraからあなたへ」(closing — 判断はユーザーに委ねる宣言)

注意: このテキストはユーザーが推敲する前提のドラフト。
      推敲後は同ファイルの定数を直接編集する。
============================================================
```

**型定義 (2):**

- L20 `class SolaraManifestoSection`
- L30 `class SolaraManifesto`

**関数 (1 public + 1 private):**

- L139 `getSections()`

  <details><summary>private 関数 1 件</summary>

  - L137 `_isJapanese()`

  </details>


### `lib/utils/title_data.dart` (395 行)

**ファイル先頭コメント:**

```
Solara Title System data — matches SPEC.md exactly.
144 titles = 12 sun parts × 12 moon parts + 25 classes
```

**型定義 (1):**

- L10 `class TitleClass`

**関数 (2 public + 0 private):**

- L361 `getSunSign()` — HTML: getSunSign(dateStr) — birthDate → 太陽星座
- L375 `getMoonSign()` — HTML: getMoonSign(dateStr, timeStr) — birthDate+Time → 月星座（近似計算）

