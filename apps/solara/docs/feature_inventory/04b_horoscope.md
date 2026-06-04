# 層 4b: Horoscope 画面

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 23 / 総行数: 6119
- class/mixin/extension/enum: 33
- 関数 (top-level + method の素拾い): 165
- Navigator.push 等: 0
- Popup/Dialog 呼出: 2
- Worker URL リテラル: 0

## ファイル別

### `lib/screens/horoscope/horo_aspect_list.dart` (185 行)

**imports:** dart=0 / package=2 / relative=7

- relative: `../../i18n/strings.g.dart`, `../../widgets/info_popup.dart`, `horo_antique_icons.dart`, `horo_aspect_description.dart`, `horo_desc_section.dart`, `horo_constants.dart`, `horo_panel_shared.dart`

**型定義 (1):**

- L17 `class HoroAspectList : StatelessWidget`

**関数 (1 public + 1 private):**

- L96 `build()`

  <details><summary>private 関数 1 件</summary>

  - L23 `_showAspectDescription()`

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


### `lib/screens/horoscope/horo_backdrop.dart` (119 行)

**型定義 (1):**

- L9 `extension _HoroBackdrop : HoroscopeScreenState`

**関数 (0 public + 2 private):**


  <details><summary>private 関数 2 件</summary>

  - L14 `_mysticalBackdrop()`
  - L85 `_buildNoProfile()`

  </details>


### `lib/screens/horoscope/horo_birth_panel.dart` (346 行)

**imports:** dart=0 / package=3 / relative=6

- relative: `../../i18n/strings.g.dart`, `../../utils/solara_storage.dart`, `../sanctuary/sanctuary_profile_editor.dart`, `horo_antique_icons.dart`, `horo_location_input.dart`, `horo_panel_shared.dart`

**型定義 (2):**

- L28 `class HoroBirthPanel : StatefulWidget`
- L54 `class _HoroBirthPanelState : State`

**関数 (5 public + 4 private):**

- L51 `createState()`
- L68 `initState()`
- L74 `didUpdateWidget()`
- L98 `dispose()`
- L142 `build()`

  <details><summary>private 関数 4 件</summary>

  - L82 `_initFromProfile()`
  - L105 `_apply()`
  - L301 `_labeled()`
  - L316 `_textField()`

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


### `lib/screens/horoscope/horo_bottom_sheet.dart` (242 行)

**ファイル先頭コメント:**

```
setState は part 元の State で定義されているが extension からの呼び出しでも
実態は同じインスタンス。analyzer は extension を State 外と判定するため抑制。
ignore_for_file: invalid_use_of_protected_member
```

**型定義 (1):**

- L12 `extension _HoroBottomSheet : HoroscopeScreenState`

**関数 (0 public + 6 private):**


  <details><summary>private 関数 6 件</summary>

  - L20 `_bsBottomInset()`
  - L23 `_bsHeight()`
  - L37 `_cycleBsState()`
  - L44 `_buildBottomSheet()`
  - L105 `_buildBSTabs()`
  - L163 `_buildBSContent()`

  </details>


### `lib/screens/horoscope/horo_chart_data.dart` (270 行)

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


### `lib/screens/horoscope/horo_filter_panel.dart` (136 行)

**imports:** dart=0 / package=2 / relative=4

- relative: `horo_antique_icons.dart`, `horo_panel_shared.dart`, `../../i18n/strings.g.dart`, `../../utils/solara_i18n.dart`

**型定義 (1):**

- L14 `class HoroFilterPanel : StatelessWidget`

**関数 (1 public + 3 private):**

- L35 `build()`

  <details><summary>private 関数 3 件</summary>

  - L80 `_filterSection()`
  - L106 `_filterChip()`
  - L121 `_exclusiveChip()`

  </details>


### `lib/screens/horoscope/horo_fortune_cards.dart` (335 行)

**imports:** dart=0 / package=2 / relative=7

- relative: `horo_constants.dart`, `horo_antique_icons.dart`, `../../i18n/strings.g.dart`, `../../utils/fortune_api.dart`, `../../widgets/ai_disclaimer_footer.dart`, `../../widgets/ai_report_button.dart`, `../../utils/solara_i18n.dart`

**型定義 (1):**

- L22 `class HoroAstrologyView : StatelessWidget`

**関数 (1 public + 6 private):**

- L64 `build()`

  <details><summary>private 関数 6 件</summary>

  - L172 `_birthEditedBanner()`
  - L189 `_loadingBanner()`
  - L206 `_errorBanner()`
  - L229 `_skeletonLine()`
  - L237 `_skeletonBar()`
  - L249 `_lockedTeaserCard()`

  </details>


### `lib/screens/horoscope/horo_location_input.dart` (273 行)

**imports:** dart=1 / package=2 / relative=3

- relative: `../../i18n/strings.g.dart`, `../../utils/reverse_geocode.dart`, `../../utils/solara_api.dart`

**型定義 (2):**

- L17 `class HoroLocationInput : StatefulWidget`
- L49 `class _HoroLocationInputState : State`

**関数 (4 public + 8 private):**

- L46 `createState()`
- L58 `initState()`
- L72 `dispose()`
- L141 `build()`

  <details><summary>private 関数 8 件</summary>

  - L68 `_fmtInit()`
  - L82 `_notify()`
  - L86 `_onManualEdit()`
  - L92 `_runGeoLookup()`
  - L111 `_pasteCoords()`
  - L220 `_labeled()`
  - L233 `_autoBox()`
  - L246 `_coordField()`

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


### `lib/screens/horoscope/horo_panel_shared.dart` (310 行)

**imports:** dart=1 / package=2 / relative=4

- relative: `../../i18n/strings.g.dart`, `horo_antique_icons.dart`, `horo_astro_glyphs.dart`, `horo_constants.dart`

**型定義 (6):**

- L18 `class PlanetVectorIcon : StatelessWidget`
  - 惑星ベクターグリフ (チャートと同じデザイン)
- L47 `class _PlanetGlyphPainter : CustomPainter`
- L74 `class ZodiacImageIcon : StatelessWidget`
  - 星座画像シンボル (assets/zodiac-symbols/*.webp + 黒透過)
- L145 `class HoroAspectCheckmark : StatelessWidget`
- L158 `class _CheckmarkPainter : CustomPainter`
- L224 `class HoroHourMinuteDropdown : StatelessWidget`

**関数 (12 public + 1 private):**

- L27 `build()`
- L52 `paint()`
- L69 `shouldRepaint()`
- L79 `build()`
- L101 `horoAntiqueHeader()` — Helper: antique-style panel header row (icon + label).
- L117 `horoPlanetOrAngleName()` — Helper: 名前解決 (planet/angle両対応)
- L122 `horoActivePatternKey()` — アクティブパターン (detectPatterns の結果) 1件を一意に識別するキー。
- L132 `horoPredictionKey()` — 予測 (predictPatternCompletions の結果) 1件を一意に識別するキー。
- L150 `build()`
- L163 `paint()`
- L212 `shouldRepaint()`
- L241 `build()`

  <details><summary>private 関数 1 件</summary>

  - L263 `_dropdownBox()`

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


### `lib/screens/horoscope/horo_prediction_panel.dart` (236 行)

**imports:** dart=0 / package=2 / relative=7

- relative: `../../i18n/strings.g.dart`, `../../widgets/info_popup.dart`, `horo_antique_icons.dart`, `horo_aspect_description.dart`, `horo_desc_section.dart`, `horo_constants.dart`, `horo_panel_shared.dart`

**型定義 (1):**

- L21 `class HoroPredictionPanel : StatelessWidget`
  - Prediction panel widget

**関数 (1 public + 3 private):**

- L36 `build()`

  <details><summary>private 関数 3 件</summary>

  - L59 `_showPatternDescription()`
  - L106 `_activeItem()`
  - L163 `_predictionItem()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/horoscope/horo_relocation_angles.dart` (196 行)

**ファイル先頭コメント:**

```
拠点(リロケーション) — アングル近接 (A案・度数距離) の計算 + 静的フォールバック文。

設計 (2026-06-02, feature_inventory §0.2.53):
  引っ越しても惑星の黄経は動かないが、ハウスのカスプ(= アングル ASC/MC/DSC/IC)は緯度経度で
  ずれる。各惑星から「最も近いアングルへの度数距離」を 出生地チャート vs 現住所チャート で
  比較し、近づいた/遠ざかったを連続量で捉える。ハウスが変わらなくても必ず変化が出る
  (= 旧ハウス差分版の「変化なし」だらけ問題が原理的に消える)。
  占星術の正統: アングルに近い惑星 (angular planet) ほど強く働く。ASC/MC 変化の印象とも一貫。
  B案(ライン近接・地理km)と違い「図の度数空間」で測るため「地球の裏のライン」問題は起きない。

  解説本文は Worker /relocation (Gemini, thinkingBudget:0・全員無料) で動的生成する。
  本ファイルは ① 幾何計算 ② Gemini へ渡す構造化ファクト ③ 取得前/失敗時の静的フォールバック文。
  吉凶禁止 (強まる/やわらぐ・前に出る/落ち着く の中立表現のみ。good/bad/lucky を使わない)。
```

**imports:** dart=0 / package=0 / relative=2

- relative: `../../utils/astro_houses.dart`, `../../utils/solara_i18n.dart`

**型定義 (2):**

- L57 `class RelocationAngleDelta`
  - 1惑星のアングル近接デルタ。
- L99 `class RelocationAngleSignChange`
  - アングル自身の星座変化 (ASC/MC/DSC/IC)。引越の印象的なヘッドライン。

**関数 (5 public + 1 private):**

- L39 `relocationAngleDomainLabel()` — アングルキー → ロケール別の領域ラベル (ja / en)。
- L88 `toPayload()` — Worker /relocation へ渡す構造化ファクト (Gemini はこれを文章化するだけ)。
- L110 `toPayload()`
- L119 `computeRelocationAngleDeltas()` — 出生地/現住所のチャート (ハウスカスプ12・ASC・MC) と惑星黄経から、10天体の
- L175 `computeRelocationAngleSignChanges()` — ASC/MC/DSC/IC の星座が出生地→現住所で変わったものだけ返す。

  <details><summary>private 関数 1 件</summary>

  - L50 `_angularDist()`

  </details>


### `lib/screens/horoscope/horo_relocation_lines.dart` (184 行)

**ファイル先頭コメント:**

```
拠点(リロケーション) — ライン近接デルタの計算 + 静的意味文の合成。

設計 (2026-06-02, feature_inventory §0.2.52):
  出生地と現住所では緯度経度が違う → 各惑星ラインへの距離が必ず変わる。
  「ハウスが変わったか」(近距離では大抵変化なし) ではなく、
  「どの惑星ラインに近づいた / 遠ざかったか」を主役にする。「変化なし」が原理的に消える。

  全て静的: astro_lines.dart の buildAstroLines + minDistanceKmToLine で距離を出し、
  惑星の性質 × アングルの領域 × 方向 × 度合い を定型文に合成する (Gemini 不使用 = ¥0)。
  占星術の吉凶禁止に沿い「強まる / やわらぐ」の中立表現のみ (good/bad/lucky を使わない)。

範囲: 7惑星 (太陽/月/水星/金星/火星/木星/土星) × 4アングル (MC/IC/ASC/DSC) = 28本 (本線のみ)。
  外惑星(天王星/海王星/冥王星)とアスペクト線は重い/抽象的なため初版では除外。
```

**imports:** dart=0 / package=1 / relative=3

- relative: `../../utils/astro_lines.dart`, `../../utils/solara_i18n.dart`, `horo_constants.dart`

**型定義 (1):**

- L86 `class RelocationLineDelta`
  - 1本のラインについて、出生地→現住所での距離変化。

**関数 (4 public + 3 private):**

- L113 `computeRelocationLineDeltas()` — 出生地・現住所の座標から、7惑星×4アングル=28本の距離デルタを計算し
- L144 `relocationMagnitudeAdverb()` — |delta| (km) を 3 段階の副詞に。閾値は実機チューニング可。
- L151 `relocationLineDeltaSentence()` — ライン近接デルタの 1 文 (中立表現)。
- L173 `relocationHouseChangeComment()` — ハウス変化の 1 文 (変化があった惑星のみ・中立表現)。

  <details><summary>private 関数 3 件</summary>

  - L46 `_planetNature()`
  - L63 `_angleDomain()`
  - L81 `_houseDomain()`

  </details>


### `lib/screens/horoscope/horo_relocation_panel.dart` (538 行)

**imports:** dart=0 / package=2 / relative=4

- relative: `../../i18n/strings.g.dart`, `../../utils/fortune_api.dart`, `horo_constants.dart`, `horo_relocation_angles.dart`

**型定義 (2):**

- L23 `class HoroRelocationPanel : StatefulWidget`
- L51 `class _HoroRelocationPanelState : State`

**関数 (4 public + 14 private):**

- L48 `createState()`
- L78 `initState()`
- L86 `didUpdateWidget()`
- L170 `build()`

  <details><summary>private 関数 14 件</summary>

  - L99 `_recompute()`
  - L122 `_buildFetchKey()`
  - L127 `_maybeFetch()`
  - L164 `_retry()`
  - L208 `_buildHeader()`
  - L240 `_buildSectionTitle()`
  - L252 `_buildSummary()`
  - L271 `_buildLoadingBlock()`
  - L299 `_buildFailureBlock()`
  - L355 `_buildAngleChangeCard()`
  - L395 `_buildPlanetCard()`
  - L490 `_buildNeedChartHint()`
  - L509 `_buildSamePlaceHint()`
  - L528 `_buildFootnote()`

  </details>


### `lib/screens/horoscope/horo_transit_panel.dart` (189 行)

**imports:** dart=0 / package=1 / relative=5

- relative: `../../i18n/strings.g.dart`, `../sanctuary/sanctuary_profile_editor.dart`, `horo_antique_icons.dart`, `horo_location_input.dart`, `horo_panel_shared.dart`

**型定義 (2):**

- L21 `class HoroTransitPanel : StatefulWidget`
- L47 `class _HoroTransitPanelState : State`

**関数 (4 public + 0 private):**

- L44 `createState()`
- L58 `initState()`
- L73 `dispose()`
- L79 `build()`


### `lib/screens/horoscope_screen.dart` (945 行)

**imports:** dart=2 / package=2 / relative=18

- relative: `../utils/astro_houses.dart`, `../utils/astro_math.dart`, `../utils/pro_status.dart`, `../utils/solara_storage.dart`, `../utils/fortune_api.dart`, `../utils/fortune_cache.dart`, `../i18n/strings.g.dart`, `../utils/solara_i18n.dart`, `../widgets/pro_unlock_dialog.dart`, `../widgets/tap_to_unfocus.dart`, `horoscope/horo_constants.dart`, `horoscope/horo_chart_painter.dart`, `horoscope/horo_fortune_cards.dart`, `horoscope/horo_bottom_panels.dart`, `horoscope/horo_ornament_painter.dart`, `horoscope/horo_antique_icons.dart`, `horoscope/horo_relocation_panel.dart`, `map/map_astro.dart`

**型定義 (2):**

- L32 `class HoroscopeScreen : StatefulWidget`
- L45 `class HoroscopeScreenState : State`

**関数 (7 public + 19 private):**

- L36 `createState()`
- L218 `initState()`
- L272 `dispose()`
- L303 `wakeAnimations()` — 「再覚醒」: anim 再開 + 30s タイマー再起動。
- L317 `pauseAnimations()` — main.dart からタブ離脱時に呼ばれる。Anim + 寿命タイマー両方停止 = raster 0%。
- L348 `loadProfile()`
- L742 `build()`

  <details><summary>private 関数 19 件</summary>

  - L162 `_planetHouse()`
  - L181 `_currentCacheKey()`
  - L200 `_refreshCacheKey()`
  - L244 `_onProStatusChanged()`
  - L260 `_showFortuneProUnlock()`
  - L284 `_resetAnimLifeTimer()`
  - L294 `_stopAnimations()`
  - L326 `_startRotTimer()`
  - L339 `_syncRotationByMode()`
  - L373 `_onTransitUpdate()`
  - L389 `_applyWorkingProfile()`
  - L410 `_fetchRealChart()`
  - L549 `_resetWorkingProfile()`
  - L556 `_profilesEqual()`
  - L585 `_loadFortunes()`
  - L859 `_menuItem()`
  - L872 `_buildHouseModeToggle()`
  - L900 `_toggleSegment()`
  - L935 `_setRelocateMode()`

  </details>

