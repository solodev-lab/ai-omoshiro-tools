# 層 1b: 静的データ辞書

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 15 / 総行数: 5582
- class/mixin/extension/enum: 19
- 関数 (top-level + method の素拾い): 38
- Navigator.push 等: 0
- Popup/Dialog 呼出: 1
- Worker URL リテラル: 0

## ファイル別

### `lib/screens/horoscope/horo_aspect_description.dart` (116 行)

**ファイル先頭コメント:**

```
══════════════════════════════════════════════════════════════
Aspect Description Data
惑星の意味 + アスペクトの性質 を組み合わせて読める文章を生成
══════════════════════════════════════════════════════════════
```

**関数 (1 public + 0 private):**

- L94 `buildAspectDescription()` — アスペクト説明を生成 (3セクション)


### `lib/screens/horoscope/horo_constants.dart` (119 行)

**imports:** dart=0 / package=1 / relative=0

**関数 (4 public + 0 private):**

- L81 `applyHoroOrbSettings()` — Sanctuary のオーブ設定を適用する。horoscope_screen から呼ばれる。
- L87 `horoAspectOrb()` — アスペクト種別キー (conjunction/trine/...) の有効 orb。
- L91 `horoPatternOrb()` — パターン orb キー (grandtrine/tsquare_opp/...) の有効 orb。
- L97 `horoOrbSignature()` — 現在のオーブ override の状態を表す署名文字列。


### `lib/screens/map/daily_transit_data.dart` (1013 行)

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
============================================================
```

**型定義 (1):**

- L23 `enum AngleFilter`
  - アングルフィルタ識別子。


### `lib/utils/astro_glossary.dart` (647 行)

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

**imports:** dart=0 / package=1 / relative=1

- relative: `../widgets/info_popup.dart`

**型定義 (1):**

- L15 `class AstroGlossaryEntry`

**関数 (1 public + 0 private):**

- L611 `showAstroGlossaryDialog()` — 用語解説 popup を表示する共通ヘルパー。

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/utils/astro_zenith_messages.dart` (170 行)

**ファイル先頭コメント:**

```
天頂点 (Zenith Point) 解説メッセージ辞書。
天頂点 = 各惑星のMCライン上で 緯度=惑星赤緯δ となる唯一の地点。
「観測者が立つと惑星が物理的に頭上(高度90°)に来る」場所。
MCライン全体の中でも特に強い「シャワー直下」「ノズル先端」のスポット。
Astro*Carto*Graphy モードで天頂点マーカータップ時に表示。
```

**型定義 (1):**

- L7 `class ZenithMessage`


### `lib/utils/celestial_event_meanings.dart` (52 行)

**ファイル先頭コメント:**

```
天体イベントの占星術的意味辞書
key: "${type}_${planet}" or "${type}_${planet}_${sign}"
惑星×タイプで汎用解説。星座固有の意味が必要な場合は planet_sign キーで上書き。
```

**関数 (1 public + 0 private):**

- L49 `getEventMeaningJP()` — CelestialEvent から意味を取得するヘルパー


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


### `lib/utils/consultation_record.dart` (180 行)

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

**関数 (3 public + 0 private):**

- L98 `toReadings()` — 読み込み専用表示 (履歴詳細) のために reading 群を再構成する。
- L118 `displayName()` — 履歴カード等の見出し用候補名 (方角は「○の方角」、座標のみは「この地点」)。
- L133 `toJson()`


### `lib/utils/consultation_v2_request.dart` (241 行)

**ファイル先頭コメント:**

```
Consultation V2 リクエストモデル — consultation_v2_api.dart の part。

最小入力 (約1KB): 誕生データ + 自宅座標 + 5問の答え + preset。
Worker (consultation_engine.js runConsultationPipeline) の契約に対応する。
```

**型定義 (4):**

- L10 `class ConsultationWhen`
  - 「いつ」(when)。場面ごとに意味が変わる時間指定。
- L40 `class ConsultationPoint`
  - 具体地点 (具体地点スコープ)。地図タップ=座標のみ / 検索=店名+種類付き。
- L66 `class ConsultationScope`
  - 「どこで」(scope)。候補地点プールの作り方。
- L114 `class ConsultationRequest`
  - 相談リクエスト (最小入力 約1KB)。Worker が全計算する。

**関数 (5 public + 0 private):**

- L31 `toJson()`
- L57 `toJson()`
- L104 `toJson()`
- L195 `copyWith()`
- L220 `toJson()`


### `lib/utils/cycle_story_texts.dart` (86 行)

**ファイル先頭コメント:**

```
月齢サイクルのストーリーテキスト（JP/EN）
翻訳ではなく、それぞれの言語でネイティブに書かれたテキスト。
```

**型定義 (1):**

- L5 `class CycleStoryTexts`

**関数 (5 public + 1 private):**

- L45 `catasterismJP()`
- L57 `catasterismEN()`
- L72 `getNewMoon()`
- L75 `getFullMoon()`
- L80 `getCatasterism()`

  <details><summary>private 関数 1 件</summary>

  - L69 `_isJapanese()`

  </details>


### `lib/utils/fortune_api.dart` (293 行)

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
- L93 `class RelocationNarrative`
- L185 `class TarotReading`

**関数 (3 public + 0 private):**

- L45 `fetchFortune()` — /fortune を叩いて占い文を取得
- L145 `fetchRelocationNarrative()` — /relocation を叩いてリロケーション解説を取得。
- L224 `fetchTarotReading()` — /tarot を叩いて1枚引きの Reading を生成する。


### `lib/utils/planet_intro.dart` (559 行)

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

**型定義 (2):**

- L21 `class PlanetIntroFrame`
- L31 `class PlanetIntro`

**関数 (1 public + 0 private):**

- L56 `frameOf()` — frame キー ('natal' / 'transit' / 'progressed') から該当 frame を返す。


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


### `lib/utils/world_cities.dart` (944 行)

**ファイル先頭コメント:**

```
GENERATED FILE — DO NOT EDIT BY HAND
Source: apps/solara/tools/generate_world_cities.py
Regenerate: python apps/solara/tools/generate_world_cities.py

Solara (ii) Stella 相談 Stage 2 用 キュレート都市リスト。
設計: docs/pro_candidates.md §7.2 Stage 2

各 CityEntry は consultation_engine.dart の候補生成に使う。
```

**型定義 (1):**

- L10 `class CityEntry`

