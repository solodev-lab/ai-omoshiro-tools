# 層 3c: 演出ウィジェット (animated)

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 5 / 総行数: 2402
- class/mixin/extension/enum: 11
- 関数 (top-level + method の素拾い): 58
- Navigator.push 等: 0
- Popup/Dialog 呼出: 0
- Worker URL リテラル: 0

## ファイル別

### `lib/widgets/catasterism_formation_overlay.dart` (779 行)

**imports:** dart=2 / package=2 / relative=6

- relative: `../models/galaxy_cycle.dart`, `../theme/solara_colors.dart`, `../utils/constellation_namer.dart`, `../utils/solara_i18n.dart`, `../utils/solara_storage.dart`, `../utils/title_data.dart`

**型定義 (2):**

- L51 `class CatasterismFormationOverlay : StatefulWidget`
  - 刻星化 (Catasterism) 完了演出オーバーレイ
- L519 `class _FormationPainter : CustomPainter`
  - 4ステージ専用Painter

**関数 (7 public + 5 private):**

- L75 `createState()`
- L89 `initState()`
- L221 `dispose()`
- L242 `build()`
- L547 `paint()`
- L559 `toScreen()`
- L777 `shouldRepaint()`

  <details><summary>private 関数 5 件</summary>

  - L135 `_resolveBgCandidates()`
  - L178 `_loadBgImage()`
  - L205 `_preloadZodiacImages()`
  - L227 `_stageLabel()`
  - L234 `_stageLabelJP()`

  </details>


### `lib/widgets/catasterism_overlay.dart` (467 行)

**imports:** dart=0 / package=2 / relative=7

- relative: `../models/lunar_intention.dart`, `../theme/solara_colors.dart`, `../utils/cycle_story_texts.dart`, `../utils/solara_i18n.dart`, `../utils/solara_storage.dart`, `glass_panel.dart`, `moon_overlay_shared.dart`

**型定義 (2):**

- L16 `class CatasterismOverlay : StatefulWidget`
- L34 `class _CatasterismOverlayState : State`

**関数 (4 public + 6 private):**

- L31 `createState()`
- L49 `initState()`
- L104 `dispose()`
- L113 `build()`

  <details><summary>private 関数 6 件</summary>

  - L78 `_transitionToChoice()`
  - L85 `_onReleasedTap()`
  - L141 `_buildStoryContent()`
  - L203 `_buildChoiceContent()`
  - L374 `_buildChoice()`
  - L452 `_submit()`

  </details>


### `lib/widgets/dominant_fortune_overlay.dart` (85 行)

**imports:** dart=0 / package=1 / relative=6

- relative: `fortune_overlays/_common.dart`, `fortune_overlays/communication_painter.dart`, `fortune_overlays/healing_painter.dart`, `fortune_overlays/love_painter.dart`, `fortune_overlays/money_painter.dart`, `fortune_overlays/work_painter.dart`

**型定義 (3):**

- L11 `enum DominantFortuneKind`
  - 今日の最高スコアカテゴリに応じた全画面演出。
- L24 `class DominantFortuneOverlay : StatefulWidget`
- L38 `class _DominantFortuneOverlayState : State`

**関数 (4 public + 1 private):**

- L35 `createState()`
- L46 `initState()`
- L67 `dispose()`
- L73 `build()`

  <details><summary>private 関数 1 件</summary>

  - L56 `_createBuilder()`

  </details>


### `lib/widgets/full_moon_overlay.dart` (490 行)

**imports:** dart=2 / package=2 / relative=8

- relative: `../models/lunar_intention.dart`, `../theme/solara_colors.dart`, `../utils/celestial_events.dart`, `../utils/cycle_story_texts.dart`, `../utils/solara_i18n.dart`, `../utils/solara_storage.dart`, `glass_panel.dart`, `moon_overlay_shared.dart`

**型定義 (2):**

- L18 `class FullMoonOverlay : StatefulWidget`
- L34 `class _FullMoonOverlayState : State`

**関数 (4 public + 10 private):**

- L31 `createState()`
- L59 `initState()`
- L93 `dispose()`
- L135 `build()`

  <details><summary>private 関数 10 件</summary>

  - L87 `_transitionToRating()`
  - L109 `_onRatingTap()`
  - L123 `_runRevealSequence()`
  - L152 `_buildStoryContent()`
  - L211 `_buildRatingList()`
  - L318 `_buildRevealLayout()`
  - L383 `_titleBlock()`
  - L419 `_ratingCardWidget()`
  - L475 `_revealMessage()`
  - L481 `_submitRating()`

  </details>


### `lib/widgets/new_moon_overlay.dart` (581 行)

**imports:** dart=1 / package=2 / relative=10

- relative: `../i18n/strings.g.dart`, `../models/lunar_intention.dart`, `../theme/solara_colors.dart`, `../utils/celestial_events.dart`, `../utils/cycle_story_texts.dart`, `../utils/moon_notification_service.dart`, `../utils/solara_i18n.dart`, `../utils/solara_storage.dart`, `glass_panel.dart`, `moon_overlay_shared.dart`

**型定義 (2):**

- L19 `class NewMoonOverlay : StatefulWidget`
- L37 `class _NewMoonOverlayState : State`

**関数 (4 public + 13 private):**

- L34 `createState()`
- L66 `initState()`
- L122 `dispose()`
- L159 `build()`

  <details><summary>private 関数 13 件</summary>

  - L105 `_transitionToChoice()`
  - L110 `_loadNotTodayCount()`
  - L115 `_loadCycleEvents()`
  - L133 `_onChoiceTap()`
  - L147 `_runRevealSequence()`
  - L176 `_buildStoryContent()`
  - L233 `_buildChoiceList()`
  - L329 `_buildRevealLayout()`
  - L447 `_titleBlock()`
  - L487 `_choiceCardWidget()`
  - L526 `_revealMessage()`
  - L533 `_revealEvents()`
  - L557 `_setIntention()`

  </details>

