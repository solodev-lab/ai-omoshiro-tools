# 層 1b: 静的データ辞書

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 13 / 総行数: 4956
- class/mixin/extension/enum: 12
- 関数 (top-level + method の素拾い): 28
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


### `lib/utils/astro_glossary.dart` (626 行)

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

- L590 `showAstroGlossaryDialog()` — 用語解説 popup を表示する共通ヘルパー。

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


### `lib/utils/consultation_record.dart` (109 行)

**ファイル先頭コメント:**

```
Consultation Record — Phase 2-4 自動保存 + 履歴

設計: apps/solara/docs/pro_candidates.md §7.2 Stage 4 + §7.3 柱3

1 件の相談 = 入力 (theme/mode/scope/freeText/候補) + 出力 (Stella reading)
+ メタ (id, savedAt) を 1 つにまとめた永続化単位。

柱 3 の原則: Free でも自分の記録を永久に失わない。
検索・フィルタ等の「記録を使う道具」は Pro 機能。
```

**imports:** dart=0 / package=0 / relative=2

- relative: `consultation_api.dart`, `consultation_engine.dart`

**型定義 (1):**

- L14 `class ConsultationRecord`

**関数 (1 public + 0 private):**

- L76 `toJson()`


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

