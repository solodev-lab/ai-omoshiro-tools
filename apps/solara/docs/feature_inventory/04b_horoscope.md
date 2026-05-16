# 層 4b: Horoscope 画面

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 22 / 総行数: 5543
- class/mixin/extension/enum: 30
- 関数 (top-level + method の素拾い): 141
- Navigator.push 等: 0
- Popup/Dialog 呼出: 2
- Worker URL リテラル: 0

## ファイル別

### `lib/screens/horoscope/horo_aspect_list.dart` (184 行)

**imports:** dart=0 / package=2 / relative=6

- relative: `../../widgets/info_popup.dart`, `horo_antique_icons.dart`, `horo_aspect_description.dart`, `horo_desc_section.dart`, `horo_constants.dart`, `horo_panel_shared.dart`

**型定義 (1):**

- L16 `class HoroAspectList : StatelessWidget`

**関数 (1 public + 1 private):**

- L95 `build()`

  <details><summary>private 関数 1 件</summary>

  - L22 `_showAspectDescription()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/horoscope/horo_astro_glyphs.dart` (173 行)

**imports:** dart=1 / package=0 / relative=0

**関数 (1 public + 10 private):**

- L14 `planetGlyph()` — Planet glyph paths by key

  <details><summary>private 関数 10 件</summary>

  - L35 `_sun()`
  - L42 `_moon()`
  - L52 `_mercury()`
  - L68 `_venus()`
  - L80 `_mars()`
  - L93 `_jupiter()`
  - L108 `_saturn()`
  - L123 `_uranus()`
  - L141 `_neptune()`
  - L160 `_pluto()`

  </details>


### `lib/screens/horoscope/horo_backdrop.dart` (114 行)

**型定義 (1):**

- L9 `extension _HoroBackdrop : HoroscopeScreenState`

**関数 (0 public + 2 private):**


  <details><summary>private 関数 2 件</summary>

  - L14 `_mysticalBackdrop()`
  - L85 `_buildNoProfile()`

  </details>


### `lib/screens/horoscope/horo_birth_panel.dart` (435 行)

**imports:** dart=1 / package=3 / relative=6

- relative: `../../utils/reverse_geocode.dart`, `../../utils/solara_api.dart`, `../../utils/solara_storage.dart`, `../sanctuary/sanctuary_profile_editor.dart`, `horo_antique_icons.dart`, `horo_panel_shared.dart`

**型定義 (2):**

- L30 `class HoroBirthPanel : StatefulWidget`
- L56 `class _HoroBirthPanelState : State`

**関数 (5 public + 7 private):**

- L53 `createState()`
- L72 `initState()`
- L78 `didUpdateWidget()`
- L104 `dispose()`
- L176 `build()`

  <details><summary>private 関数 7 件</summary>

  - L86 `_initFromProfile()`
  - L114 `_scheduleGeoLookup()`
  - L119 `_runGeoLookup()`
  - L139 `_apply()`
  - L377 `_labeled()`
  - L392 `_inputBox()`
  - L405 `_textField()`

  </details>


### `lib/screens/horoscope/horo_bottom_panels.dart` (14 行)

**ファイル先頭コメント:**

```
══════════════════════════════════════════════════════════════
Barrel file — splits of the original 1282-line horo_bottom_panels.dart
Keep this file so existing imports (`import 'horo_bottom_panels.dart'`)
continue to work after the split.
══════════════════════════════════════════════════════════════
```


### `lib/screens/horoscope/horo_bottom_sheet.dart` (224 行)

**ファイル先頭コメント:**

```
setState は part 元の State で定義されているが extension からの呼び出しでも
実態は同じインスタンス。analyzer は extension を State 外と判定するため抑制。
ignore_for_file: invalid_use_of_protected_member
```

**型定義 (1):**

- L12 `extension _HoroBottomSheet : HoroscopeScreenState`

**関数 (0 public + 5 private):**


  <details><summary>private 関数 5 件</summary>

  - L16 `_bsHeight()`
  - L25 `_cycleBsState()`
  - L32 `_buildBottomSheet()`
  - L93 `_buildBSTabs()`
  - L151 `_buildBSContent()`

  </details>


### `lib/screens/horoscope/horo_chart_data.dart` (215 行)

**型定義 (1):**

- L9 `extension _HoroChartData : HoroscopeScreenState`

**関数 (0 public + 7 private):**


  <details><summary>private 関数 7 件</summary>

  - L10 `_generateMockChart()`
  - L26 `_generateTransitPlanets()`
  - L41 `_generateProgressedPlanets()`
  - L60 `_recalcAspects()`
  - L95 `_addAspect()`
  - L113 `_approxSunLon()`
  - L119 `_aspectPassesFilter()`

  </details>


### `lib/screens/horoscope/horo_chart_painter.dart` (702 行)

**imports:** dart=2 / package=2 / relative=1

- relative: `horo_astro_glyphs.dart`

**型定義 (3):**

- L17 `class HoroLegendItem : StatelessWidget`
- L48 `class HoroChartWheelPainter : CustomPainter`
- L697 `class _SpreadItem`
  - 内部用: 惑星配置広げアルゴリズムの各点

**関数 (3 public + 6 private):**

- L28 `build()`
- L98 `paint()`
- L684 `shouldRepaint()`

  <details><summary>private 関数 6 件</summary>

  - L95 `_lonToAngle()`
  - L540 `_drawCenterSerif()`
  - L557 `_drawVectorGlyph()`
  - L593 `_spreadOverlappingPlanets()`
  - L671 `_angDistSigned()`
  - L678 `_defaultHouses()`

  </details>


### `lib/screens/horoscope/horo_chart_view.dart` (191 行)

**型定義 (1):**

- L8 `extension _HoroChartView : HoroscopeScreenState`

**関数 (0 public + 3 private):**


  <details><summary>private 関数 3 件</summary>

  - L10 `_buildZodiacImages()`
  - L42 `_buildChartScrollView()`
  - L170 `_buildChartLegend()`

  </details>


### `lib/screens/horoscope/horo_desc_section.dart` (31 行)

**imports:** dart=0 / package=2 / relative=0

**型定義 (1):**

- L13 `class HoroDescSection : StatelessWidget`
  - アスペクト/パターン解説の「ラベル + 本文」セクション。

**関数 (1 public + 0 private):**

- L21 `build()`


### `lib/screens/horoscope/horo_filter_panel.dart` (134 行)

**imports:** dart=0 / package=2 / relative=2

- relative: `horo_antique_icons.dart`, `horo_panel_shared.dart`

**型定義 (1):**

- L12 `class HoroFilterPanel : StatelessWidget`

**関数 (1 public + 3 private):**

- L33 `build()`

  <details><summary>private 関数 3 件</summary>

  - L78 `_filterSection()`
  - L104 `_filterChip()`
  - L119 `_exclusiveChip()`

  </details>


### `lib/screens/horoscope/horo_fortune_cards.dart` (350 行)

**imports:** dart=0 / package=2 / relative=3

- relative: `horo_constants.dart`, `horo_antique_icons.dart`, `../../utils/fortune_api.dart`

**型定義 (1):**

- L38 `class HoroAstrologyView : StatelessWidget`

**関数 (1 public + 6 private):**

- L80 `build()`

  <details><summary>private 関数 6 件</summary>

  - L187 `_birthEditedBanner()`
  - L204 `_loadingBanner()`
  - L221 `_errorBanner()`
  - L244 `_skeletonLine()`
  - L252 `_skeletonBar()`
  - L264 `_lockedTeaserCard()`

  </details>


### `lib/screens/horoscope/horo_ornament_painter.dart` (139 行)

**imports:** dart=1 / package=1 / relative=0

**型定義 (1):**

- L9 `class HoroOrnamentPainter : CustomPainter`

**関数 (2 public + 5 private):**

- L24 `paint()`
- L137 `shouldRepaint()`

  <details><summary>private 関数 5 件</summary>

  - L17 `_lonToAngle()`
  - L47 `_drawDecorativeRing()`
  - L81 `_drawStarMarkers()`
  - L92 `_drawSixPointStar()`
  - L122 `_drawInnerHalo()`

  </details>


### `lib/screens/horoscope/horo_panel_shared.dart` (307 行)

**imports:** dart=1 / package=2 / relative=3

- relative: `horo_antique_icons.dart`, `horo_astro_glyphs.dart`, `horo_constants.dart`

**型定義 (6):**

- L17 `class PlanetVectorIcon : StatelessWidget`
  - 惑星ベクターグリフ (チャートと同じデザイン)
- L46 `class _PlanetGlyphPainter : CustomPainter`
- L73 `class ZodiacImageIcon : StatelessWidget`
  - 星座画像シンボル (assets/zodiac-symbols/*.webp + 黒透過)
- L144 `class HoroAspectCheckmark : StatelessWidget`
- L157 `class _CheckmarkPainter : CustomPainter`
- L223 `class HoroHourMinuteDropdown : StatelessWidget`

**関数 (12 public + 1 private):**

- L26 `build()`
- L51 `paint()`
- L68 `shouldRepaint()`
- L78 `build()`
- L100 `horoAntiqueHeader()` — Helper: antique-style panel header row (icon + label).
- L116 `horoPlanetOrAngleName()` — Helper: 名前解決 (planet/angle両対応)
- L121 `horoActivePatternKey()` — アクティブパターン (detectPatterns の結果) 1件を一意に識別するキー。
- L131 `horoPredictionKey()` — 予測 (predictPatternCompletions の結果) 1件を一意に識別するキー。
- L149 `build()`
- L162 `paint()`
- L211 `shouldRepaint()`
- L240 `build()`

  <details><summary>private 関数 1 件</summary>

  - L262 `_dropdownBox()`

  </details>


### `lib/screens/horoscope/horo_pattern_logic.dart` (205 行)

**imports:** dart=0 / package=0 / relative=2

- relative: `../../utils/astro_math.dart`, `horo_constants.dart`

**関数 (4 public + 0 private):**

- L33 `hasPersonal()`
- L36 `enoughNatal()`
- L38 `triKey()`
- L131 `mockLon()`


### `lib/screens/horoscope/horo_planet_table.dart` (160 行)

**imports:** dart=0 / package=2 / relative=4

- relative: `../../utils/astro_houses.dart`, `horo_antique_icons.dart`, `horo_constants.dart`, `horo_panel_shared.dart`

**型定義 (1):**

- L14 `class HoroPlanetTable : StatelessWidget`

**関数 (1 public + 2 private):**

- L52 `build()`

  <details><summary>private 関数 2 件</summary>

  - L39 `_planetHouse()`
  - L119 `_planetRow()`

  </details>


### `lib/screens/horoscope/horo_prediction_panel.dart` (235 行)

**imports:** dart=0 / package=2 / relative=6

- relative: `../../widgets/info_popup.dart`, `horo_antique_icons.dart`, `horo_aspect_description.dart`, `horo_desc_section.dart`, `horo_constants.dart`, `horo_panel_shared.dart`

**型定義 (1):**

- L20 `class HoroPredictionPanel : StatelessWidget`
  - Prediction panel widget

**関数 (1 public + 3 private):**

- L35 `build()`

  <details><summary>private 関数 3 件</summary>

  - L58 `_showPatternDescription()`
  - L105 `_activeItem()`
  - L162 `_predictionItem()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/horoscope/horo_relocation_panel.dart` (467 行)

**imports:** dart=0 / package=2 / relative=6

- relative: `../../utils/astro_houses.dart`, `../../utils/fortune_api.dart`, `../../utils/pro_status.dart`, `../../widgets/pro_unlock_dialog.dart`, `horo_constants.dart`, `horo_relocation_templates.dart`

**型定義 (3):**

- L31 `class HouseShift`
- L38 `class HoroRelocationPanel : StatefulWidget`
- L66 `class _HoroRelocationPanelState : State`

**関数 (5 public + 11 private):**

- L63 `createState()`
- L73 `initState()`
- L80 `dispose()`
- L103 `didUpdateWidget()`
- L180 `build()`

  <details><summary>private 関数 11 件</summary>

  - L86 `_onProStatusChanged()`
  - L110 `_buildFetchKey()`
  - L119 `_maybeFetch()`
  - L130 `_computeAllPositions()`
  - L151 `_fetchNarrative()`
  - L225 `_buildHeader()`
  - L254 `_buildSummaryBlock()`
  - L278 `_buildLoadingHint()`
  - L303 `_buildAngleBlock()`
  - L367 `_buildShiftBlock()`
  - L441 `_buildCompareRow()`

  </details>


### `lib/screens/horoscope/horo_relocation_pro_teaser.dart` (96 行)

**型定義 (1):**

- L14 `extension _RelocationProTeaser : _HoroRelocationPanelState`

**関数 (1 public + 0 private):**

- L18 `buildProTeaser()` — Free ユーザー向け Pro 誘導カード。


### `lib/screens/horoscope/horo_relocation_templates.dart` (196 行)

**ファイル先頭コメント:**

```
リロケーション解説テンプレート
(惑星 × 移動先ハウス) の組み合わせから「現住所で活性化する側面」を生成。
Phase A: 静的テンプレート (将来 Stella 動的生成に切替予定 → 同データ構造で互換)。
惑星日本語名は horo_constants.dart の planetNamesJP を使用。
```


### `lib/screens/horoscope/horo_transit_panel.dart` (157 行)

**imports:** dart=0 / package=1 / relative=3

- relative: `../sanctuary/sanctuary_profile_editor.dart`, `horo_antique_icons.dart`, `horo_panel_shared.dart`

**型定義 (2):**

- L19 `class HoroTransitPanel : StatefulWidget`
- L35 `class _HoroTransitPanelState : State`

**関数 (4 public + 0 private):**

- L32 `createState()`
- L42 `initState()`
- L55 `dispose()`
- L61 `build()`


### `lib/screens/horoscope_screen.dart` (814 行)

**imports:** dart=2 / package=2 / relative=14

- relative: `../utils/astro_houses.dart`, `../utils/astro_math.dart`, `../utils/pro_status.dart`, `../utils/solara_storage.dart`, `../utils/fortune_api.dart`, `../widgets/pro_unlock_dialog.dart`, `horoscope/horo_constants.dart`, `horoscope/horo_chart_painter.dart`, `horoscope/horo_fortune_cards.dart`, `horoscope/horo_bottom_panels.dart`, `horoscope/horo_ornament_painter.dart`, `horoscope/horo_antique_icons.dart`, `horoscope/horo_relocation_panel.dart`, `map/map_astro.dart`

**型定義 (2):**

- L28 `class HoroscopeScreen : StatefulWidget`
- L41 `class HoroscopeScreenState : State`

**関数 (7 public + 19 private):**

- L32 `createState()`
- L182 `initState()`
- L236 `dispose()`
- L267 `wakeAnimations()` — 「再覚醒」: anim 再開 + 30s タイマー再起動。
- L281 `pauseAnimations()` — main.dart からタブ離脱時に呼ばれる。Anim + 寿命タイマー両方停止 = raster 0%。
- L312 `loadProfile()`
- L624 `build()`

  <details><summary>private 関数 19 件</summary>

  - L126 `_planetHouse()`
  - L145 `_currentCacheKey()`
  - L164 `_refreshCacheKey()`
  - L208 `_onProStatusChanged()`
  - L224 `_showFortuneProUnlock()`
  - L248 `_resetAnimLifeTimer()`
  - L258 `_stopAnimations()`
  - L290 `_startRotTimer()`
  - L303 `_syncRotationByMode()`
  - L337 `_onTransitUpdate()`
  - L348 `_applyWorkingProfile()`
  - L366 `_fetchRealChart()`
  - L494 `_resetWorkingProfile()`
  - L501 `_profilesEqual()`
  - L530 `_loadFortunes()`
  - L728 `_menuItem()`
  - L741 `_buildHouseModeToggle()`
  - L769 `_toggleSegment()`
  - L804 `_setRelocateMode()`

  </details>

