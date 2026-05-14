# 層 2a: API/Worker ラッパ

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 7 / 総行数: 1440
- class/mixin/extension/enum: 14
- 関数 (top-level + method の素拾い): 22
- Navigator.push 等: 0
- Popup/Dialog 呼出: 0
- Worker URL リテラル: 8

## ファイル別

### `lib/screens/map/map_astro.dart` (508 行)

**imports:** dart=2 / package=1 / relative=4

- relative: `../../utils/astro_math.dart`, `../../utils/direction_energy.dart`, `../../utils/solara_api.dart`, `map_constants.dart`

**型定義 (2):**

- L20 `class ChartResult`
  - CF Worker /astro/chart のレスポンス
- L187 `class ScoreResult`

**関数 (8 public + 3 private):**

- L66 `fetchChart()` — CF Worker にチャートを要求
- L259 `scoreAll()` — ChartResult → Map画面用16方位スコア
- L288 `getAB()`
- L297 `addT()`
- L299 `addP()`
- L326 `isAngle()`
- L411 `addCT()`
- L413 `addCP()`

  <details><summary>private 関数 3 件</summary>

  - L121 `_cosFall()`
  - L162 `_emptyComp()`
  - L234 `_addAspectComp()`

  </details>

**Worker URL リテラル (1):**

- L17: `'$solaraWorkerBase/astro/chart'`


### `lib/utils/celestial_events.dart` (314 行)

**imports:** dart=1 / package=2 / relative=1

- relative: `solara_api.dart`

**型定義 (3):**

- L14 `class CelestialEvents`
  - Loads and provides celestial event data for intention generation.
- L151 `class MonthEvents`
- L220 `class CelestialEvent`

**関数 (3 public + 1 private):**

- L19 `initialize()`
- L196 `eventSummary()` — Format active events as a summary string.
- L204 `copyWithEvents()` — API経由のリアル計算eventsで置換した新MonthEventsを返す

  <details><summary>private 関数 1 件</summary>

  - L65 `_getNewMoonDate()`

  </details>

**Worker URL リテラル (1):**

- L42: `'$_workerBase/astro/events?year=$year&month=$month'`


### `lib/utils/daily_transits_api.dart` (241 行)

**ファイル先頭コメント:**

```
============================================================
Solara Daily Transits API

F1 (2026-04-29): 拠点 (自宅・職場等) における今日のトランジット惑星
アングル通過時刻を取得する。

Worker: /astro/daily-transits (POST)
設計: project_solara_design_philosophy.md
============================================================
```

**imports:** dart=1 / package=1 / relative=1

- relative: `solara_api.dart`

**型定義 (6):**

- L17 `class TransitAspect`
  - V2: その瞬間にトランジット惑星が natal 惑星と作るアスペクト。
- L46 `class TransitEvent`
  - 1イベント = ある惑星が4アングル(ASC/MC/DSC/IC)のどれか1つを通過した瞬間。
- L85 `class PlanetDailyTransits`
  - 1惑星 × 1日分の通過イベント (最大4個: ASC/MC/DSC/IC)。
- L105 `class LatitudeBandHit`
  - 緯度帯ヒット惑星 (Lewis 流の緯度効果)。
- L124 `class LatitudeBand`
  - 観測時刻における緯度帯セクション (zenith / nadir のヒット惑星 + オーブ)。
- L148 `class DailyTransitsResult`
  - /astro/daily-transits の完全レスポンス。

**関数 (2 public + 0 private):**

- L188 `flatTimeline()` — 全惑星の全イベントを時刻順にフラット化したリストを返す。
- L208 `fetchDailyTransits()` — 拠点における今日のトランジット通過時刻を取得する。

**Worker URL リテラル (1):**

- L14: `'$solaraWorkerBase/astro/daily-transits'`


### `lib/utils/fortune_api.dart` (250 行)

**ファイル先頭コメント:**

```
Fortune API - /fortune エンドポイント (Gemini生成の占い文取得)
関連: worker/src/fortune.js
```

**imports:** dart=1 / package=1 / relative=1

- relative: `solara_api.dart`

**型定義 (3):**

- L8 `class FortuneReading`
  - Fortune APIレスポンス
- L86 `class RelocationNarrative`
- L179 `class TarotReading`

**関数 (3 public + 0 private):**

- L41 `fetchFortune()` — /fortune を叩いて占い文を取得
- L138 `fetchRelocationNarrative()` — /relocation を叩いてリロケーション解説を取得。
- L205 `fetchTarotReading()` — /tarot を叩いて1枚引きの Reading を生成する。

**Worker URL リテラル (3):**

- L63: `'$solaraWorkerBase/fortune'`
- L158: `'$solaraWorkerBase/relocation'`
- L231: `'$solaraWorkerBase/tarot'`


### `lib/utils/reverse_geocode.dart` (50 行)

**imports:** dart=1 / package=1 / relative=0

**関数 (1 public + 0 private):**

- L23 `reverseGeocode()` — 緯度経度から地名（市町村名）を逆ジオコーディングで取得する。


### `lib/utils/solara_api.dart` (35 行)

**ファイル先頭コメント:**

```
Solara CF Worker API - 軽量なユーティリティ呼び出し
(チャート/イベント系は別ファイルに既存。ここは補助エンドポイント用)
```

**imports:** dart=1 / package=1 / relative=0

**関数 (1 public + 0 private):**

- L22 `fetchTimezoneName()` — 緯度経度から IANA TZ名 (DST対応の基準) を取得。

**Worker URL リテラル (2):**

- L17: `'https://solara-api.solodev-lab.com'`
- L24: `'$solaraWorkerBase/tz?lat=$lat&lng=$lng'`


### `lib/utils/tile_http_client.dart` (42 行)

**imports:** dart=1 / package=3 / relative=0

