# 層 4d: Galaxy 画面

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 5 / 総行数: 1857
- class/mixin/extension/enum: 7
- 関数 (top-level + method の素拾い): 48
- Navigator.push 等: 0
- Popup/Dialog 呼出: 1
- Worker URL リテラル: 0

## ファイル別

### `lib/screens/galaxy/galaxy_constellation_builder.dart` (124 行)

**imports:** dart=1 / package=0 / relative=5

- relative: `../../models/daily_reading.dart`, `../../models/galaxy_cycle.dart`, `../../utils/constellation_namer.dart`, `../../utils/moon_phase.dart`, `../../utils/tarot_data.dart`


### `lib/screens/galaxy/galaxy_replay_overlay.dart` (148 行)

**imports:** dart=2 / package=2 / relative=3

- relative: `../../models/galaxy_cycle.dart`, `../../utils/constellation_namer.dart`, `../../widgets/constellation_painter.dart`

**型定義 (1):**

- L17 `class GalaxyReplayOverlay : StatelessWidget`

**関数 (1 public + 0 private):**

- L34 `build()`


### `lib/screens/galaxy/galaxy_sample_data.dart` (101 行)

**imports:** dart=1 / package=0 / relative=3

- relative: `../../models/daily_reading.dart`, `../../models/galaxy_cycle.dart`, `../../utils/constellation_namer.dart`

**関数 (1 public + 1 private):**

- L7 `injectGalaxySampleData()` — デモ用サンプルデータ: Cycleに25個の星 + Star Atlasに61全星座

  <details><summary>private 関数 1 件</summary>

  - L41 `_buildSampleFromTemplate()`

  </details>


### `lib/screens/galaxy/galaxy_star_atlas.dart` (317 行)

**imports:** dart=1 / package=2 / relative=4

- relative: `../../models/galaxy_cycle.dart`, `../../utils/constellation_namer.dart`, `../../widgets/constellation_painter.dart`, `../horoscope/horo_antique_icons.dart`

**型定義 (4):**

- L18 `class GalaxyStarAtlasTab : StatelessWidget`
  - STAR ATLAS タブ本体。HTML の `.atlas-content` と中のグリッドを描画する。
- L99 `class _AtlasHeader : StatelessWidget`
- L133 `class _ConstellationCard : StatelessWidget`
- L278 `class _EmptyState : StatelessWidget`

**関数 (4 public + 0 private):**

- L31 `build()`
- L103 `build()`
- L145 `build()`
- L280 `build()`


### `lib/screens/galaxy_screen.dart` (1167 行)

**imports:** dart=3 / package=4 / relative=18

- relative: `horoscope/horo_antique_icons.dart`, `../models/daily_reading.dart`, `../models/galaxy_cycle.dart`, `../models/lunar_intention.dart`, `../utils/celestial_events.dart`, `../utils/constellation_namer.dart`, `../utils/moon_phase.dart`, `../utils/solara_storage.dart`, `../utils/tarot_data.dart`, `../widgets/catasterism_formation_overlay.dart`, `../widgets/celestial_event_bar.dart`, `../widgets/cycle_spiral_painter.dart`, `../widgets/info_popup.dart`, `../widgets/moon_overlay.dart`, `galaxy/galaxy_constellation_builder.dart`, `galaxy/galaxy_sample_data.dart`, `galaxy/galaxy_star_atlas.dart`, `galaxy/galaxy_replay_overlay.dart`

**型定義 (2):**

- L29 `class GalaxyScreen : StatefulWidget`
- L36 `class GalaxyScreenState : State`

**関数 (9 public + 32 private):**

- L33 `createState()`
- L105 `regenerateBackground()` — タブ切替でGalaxyに入ってきた時に、背景 (ネビュラ位置・色・星の位置)
- L116 `pauseMotion()` — main.dart から Galaxy タブ離脱時に呼ばれる。Timer 即停止 = raster 0% 化。
- L136 `initState()`
- L147 `jitter()`
- L165 `dispose()`
- L341 `build()`
- L624 `fmtTime()`
- L626 `fmtDate()`

  <details><summary>private 関数 32 件</summary>

  - L145 `_initNebulaPositions()`
  - L174 `_wakeMotion()`
  - L182 `_onMotionTick()`
  - L225 `_loadData()`
  - L300 `_loadArtImage()`
  - L315 `_checkMoonOverlay()`
  - L432 `_buildTabBar()`
  - L442 `_buildTab()`
  - L485 `_buildCycleTab()`
  - L516 `_buildDayBadge()`
  - L540 `_buildMoonBadge()`
  - L565 `_buildStellaMessage()`
  - L668 `_onDragStart()`
  - L675 `_onDragUpdate()`
  - L686 `_onDragEnd()`
  - L691 `_onTapUp()`
  - L702 `_showDotPopup()`
  - L708 `_hideDotPopup()`
  - L712 `_buildDotPopup()`
  - L767 `_openReplay()`
  - L774 `_closeReplay()`
  - L783 `_buildDebugTriggerRow()`
  - L800 `_buildDebugBtn()`
  - L824 `_debugTriggerNewMoon()`
  - L829 `_debugTriggerFullMoon()`
  - L844 `_debugTriggerCatasterism()`
  - L862 `_debugTriggerCycleCompletion()`
  - L907 `_buildMoonOverlay()`
  - L961 `_onCatasterismResult()`
  - L976 `_onFormationComplete()`
  - L988 `_moonPhaseDescription()`
  - L1031 `_showGalaxyUsageGuide()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1

