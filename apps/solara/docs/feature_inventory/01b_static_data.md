# 層 1b: 静的データ辞書

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 5 / 総行数: 1418
- class/mixin/extension/enum: 6
- 関数 (top-level + method の素拾い): 19
- Navigator.push 等: 0
- Popup/Dialog 呼出: 0
- Worker URL リテラル: 0

## ファイル別

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

