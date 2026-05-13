# 層 4f: サブ画面 (Forecast / Locations / Philosophy / Font Preview)

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 7 / 総行数: 2930
- class/mixin/extension/enum: 20
- 関数 (top-level + method の素拾い): 88
- Navigator.push 等: 0
- Popup/Dialog 呼出: 5
- Worker URL リテラル: 0

## ファイル別

### `lib/screens/font_preview_screen.dart` (138 行)

**imports:** dart=0 / package=2 / relative=0

**型定義 (3):**

- L6 `class FontPreviewScreen : StatefulWidget`
  - フォント比較画面 — 候補フォント8種を Horo と同じコンテキストで並べて比較
- L12 `class _FontPreviewScreenState : State`
- L134 `class _FontOption`

**関数 (2 public + 1 private):**

- L9 `createState()`
- L32 `build()`

  <details><summary>private 関数 1 件</summary>

  - L48 `_buildSample()`

  </details>


### `lib/screens/forecast/forecast_life_periods.dart` (219 行)

**imports:** dart=0 / package=1 / relative=3

- relative: `../../utils/forecast_cache.dart`, `../../widgets/info_popup.dart`, `../map/map_constants.dart`

**型定義 (1):**

- L28 `class ForecastLifePeriodsSection : StatelessWidget`
  - 「◯◯期」セクション — 永続保存された運勢サイクルを表示

**関数 (1 public + 2 private):**

- L38 `build()`

  <details><summary>private 関数 2 件</summary>

  - L88 `_periodRow()`
  - L140 `_showLifePeriodsInfo()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/forecast/forecast_top5.dart` (238 行)

**imports:** dart=0 / package=1 / relative=3

- relative: `../../utils/forecast_cache.dart`, `../../widgets/info_popup.dart`, `../map/map_constants.dart`

**型定義 (1):**

- L8 `class ForecastTop5Section : StatelessWidget`
  - 強運Top5 セクション — 永続保存された Top5 を mode 別に表示

**関数 (1 public + 4 private):**

- L30 `build()`

  <details><summary>private 関数 4 件</summary>

  - L57 `_modeSelector()`
  - L75 `_seg()`
  - L100 `_row()`
  - L134 `_showTop5Info()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/forecast_screen.dart` (1048 行)

**imports:** dart=0 / package=1 / relative=7

- relative: `../utils/forecast_cache.dart`, `../utils/solara_storage.dart`, `../widgets/info_popup.dart`, `../widgets/no_profile_guide.dart`, `forecast/forecast_life_periods.dart`, `forecast/forecast_top5.dart`, `map/map_constants.dart`

**型定義 (3):**

- L13 `class ForecastScreen : StatefulWidget`
  - Forecast 画面 — 1年予測（ヒートマップ + 選択日詳細 + 強運Top5）
- L31 `class _ForecastScreenState : State`
- L1019 `class _DayStepperButton : StatelessWidget`
  - 選択日詳細パネルの △ ボタン (左右で 1 日前後に動かす)。

**関数 (4 public + 30 private):**

- L28 `createState()`
- L63 `initState()`
- L131 `build()`
- L1030 `build()`

  <details><summary>private 関数 30 件</summary>

  - L68 `_initialize()`
  - L74 `_loadSettings()`
  - L82 `_setColorMode()`
  - L87 `_setHighColor()`
  - L92 `_load()`
  - L122 `_setYearOffset()`
  - L173 `_buildBody()`
  - L227 `_buildBasisCard()`
  - L278 `_fmt()`
  - L281 `_buildBestChip()`
  - L315 `_yearSeg()`
  - L339 `_buildHeatmap()`
  - L415 `_buildColorModeToggle()`
  - L456 `_rankSeg()`
  - L486 `_segment()`
  - L507 `_buildLegend()`
  - L534 `_catColorChips()`
  - L548 `_monthRow()`
  - L577 `_dayCell()`
  - L608 `_cellColor()`
  - L625 `_gradientColor()`
  - L636 `_categoryColor()`
  - L652 `_canShiftSelectedDay()`
  - L663 `_shiftSelectedDay()`
  - L670 `_buildSelectedDayDetail()`
  - L733 `_metric()`
  - L741 `_catBar()`
  - L778 `_buildFetchInfo()`
  - L792 `_showForecastUsageGuide()`
  - L918 `_showHeatmapInfo()`

  </details>

**Popup/Dialog 呼出 (2):**

- 集計: `showInfoPopup`×2


### `lib/screens/locations/locations_date_stepper.dart` (391 行)

**imports:** dart=0 / package=2 / relative=0

**型定義 (5):**

- L9 `class LocationsDateStepper : StatelessWidget`
  - Locations 画面の日付ステッパー（年▲▼ 月▲▼ 日▲▼ + 「今日」リセット）。
- L206 `class _DateNumberField : StatefulWidget`
  - 数値を直接タイプして編集できるフィールド（年/月/日 共通）。
- L223 `class _DateNumberFieldState : State`
- L304 `class _HourNumberField : StatefulWidget`
  - 時 (hour) を直接タイプして編集できるフィールド。
- L314 `class _HourNumberFieldState : State`

**関数 (11 public + 7 private):**

- L53 `build()`
- L220 `createState()`
- L228 `initState()`
- L236 `didUpdateWidget()`
- L260 `dispose()`
- L268 `build()`
- L311 `createState()`
- L319 `initState()`
- L328 `didUpdateWidget()`
- L353 `dispose()`
- L361 `build()`

  <details><summary>private 関数 7 件</summary>

  - L129 `_hourStepperBlock()`
  - L159 `_stepperBlock()`
  - L189 `_stepBtn()`
  - L244 `_onFocusChange()`
  - L248 `_commit()`
  - L336 `_onFocusChange()`
  - L340 `_commit()`

  </details>


### `lib/screens/locations_screen.dart` (737 行)

**imports:** dart=1 / package=2 / relative=8

- relative: `../utils/solara_storage.dart`, `../widgets/info_popup.dart`, `../widgets/no_profile_guide.dart`, `locations/locations_date_stepper.dart`, `map/map_astro.dart`, `map/map_constants.dart`, `map/map_search.dart`, `map/map_vp_panel.dart`

**型定義 (3):**

- L15 `class LocationsScreen : StatefulWidget`
  - Locations 一覧画面 — 登録済み拠点を16方位スコア付きで管理。
- L38 `class _LocationsScreenState : State`
- L624 `class _SlotStats`

**関数 (3 public + 18 private):**

- L35 `createState()`
- L66 `initState()`
- L274 `build()`

  <details><summary>private 関数 18 件</summary>

  - L71 `_load()`
  - L131 `_shiftDate()`
  - L141 `_setYmd()`
  - L160 `_setHour()`
  - L168 `_shiftHour()`
  - L175 `_resetToday()`
  - L185 `_setDate()`
  - L218 `_addCurrent()`
  - L230 `_delete()`
  - L235 `_rename()`
  - L344 `_buildRefPointSelector()`
  - L424 `_buildCategorySelector()`
  - L468 `_emptyState()`
  - L493 `_buildList()`
  - L502 `_buildRow()`
  - L582 `_scoreBar()`
  - L618 `_fmtKm()`
  - L634 `_showLocationsUsageGuide()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/solara_philosophy_screen.dart` (159 行)

**ファイル先頭コメント:**

```
============================================================
Solara Philosophy Screen — 設計思想ガイド（章0）

E5: 流派ガイドページの最初の章として、Solaraの設計思想
（ソフト/ハード独立2エネルギー、占い的吉凶判定をしない、
  両面思想）をユーザーに伝える。

データソース: lib/utils/solara_manifesto.dart
設計根拠: project_solara_design_philosophy.md
============================================================
```

**imports:** dart=0 / package=1 / relative=3

- relative: `../theme/solara_colors.dart`, `../utils/solara_manifesto.dart`, `../widgets/glass_panel.dart`

**型定義 (4):**

- L17 `class SolaraPhilosophyScreen : StatelessWidget`
- L61 `class _Hero : StatelessWidget`
- L102 `class _SectionCard : StatelessWidget`
- L143 `class _Footer : StatelessWidget`

**関数 (4 public + 0 private):**

- L21 `build()`
- L65 `build()`
- L107 `build()`
- L147 `build()`

