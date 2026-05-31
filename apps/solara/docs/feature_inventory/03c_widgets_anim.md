# 層 3c: 演出ウィジェット (animated)

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 6 / 総行数: 2516
- class/mixin/extension/enum: 13
- 関数 (top-level + method の素拾い): 63
- Navigator.push 等: 0
- Popup/Dialog 呼出: 0
- Worker URL リテラル: 0

## ファイル別

### `lib/widgets/catasterism_formation_overlay.dart` (775 行)

**imports:** dart=2 / package=2 / relative=5

- relative: `../models/galaxy_cycle.dart`, `../theme/solara_colors.dart`, `../utils/constellation_namer.dart`, `../utils/solara_storage.dart`, `../utils/title_data.dart`

**型定義 (2):**

- L50 `class CatasterismFormationOverlay : StatefulWidget`
  - 刻星化 (Catasterism) 完了演出オーバーレイ
- L515 `class _FormationPainter : CustomPainter`
  - 4ステージ専用Painter

**関数 (7 public + 5 private):**

- L74 `createState()`
- L88 `initState()`
- L220 `dispose()`
- L241 `build()`
- L543 `paint()`
- L555 `toScreen()`
- L773 `shouldRepaint()`

  <details><summary>private 関数 5 件</summary>

  - L134 `_resolveBgCandidates()`
  - L177 `_loadBgImage()`
  - L204 `_preloadZodiacImages()`
  - L226 `_stageLabel()`
  - L233 `_stageLabelJP()`

  </details>


### `lib/widgets/catasterism_overlay.dart` (445 行)

**imports:** dart=0 / package=2 / relative=6

- relative: `../models/lunar_intention.dart`, `../theme/solara_colors.dart`, `../utils/cycle_story_texts.dart`, `../utils/solara_storage.dart`, `glass_panel.dart`, `moon_overlay_shared.dart`

**型定義 (2):**

- L15 `class CatasterismOverlay : StatefulWidget`
- L33 `class _CatasterismOverlayState : State`

**関数 (4 public + 6 private):**

- L30 `createState()`
- L48 `initState()`
- L103 `dispose()`
- L112 `build()`

  <details><summary>private 関数 6 件</summary>

  - L77 `_transitionToChoice()`
  - L84 `_onReleasedTap()`
  - L140 `_buildStoryContent()`
  - L202 `_buildChoiceContent()`
  - L354 `_buildChoice()`
  - L430 `_submit()`

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


### `lib/widgets/full_moon_overlay.dart` (481 行)

**imports:** dart=2 / package=2 / relative=7

- relative: `../models/lunar_intention.dart`, `../theme/solara_colors.dart`, `../utils/celestial_events.dart`, `../utils/cycle_story_texts.dart`, `../utils/solara_storage.dart`, `glass_panel.dart`, `moon_overlay_shared.dart`

**型定義 (2):**

- L17 `class FullMoonOverlay : StatefulWidget`
- L33 `class _FullMoonOverlayState : State`

**関数 (4 public + 10 private):**

- L30 `createState()`
- L58 `initState()`
- L92 `dispose()`
- L134 `build()`

  <details><summary>private 関数 10 件</summary>

  - L86 `_transitionToRating()`
  - L108 `_onRatingTap()`
  - L122 `_runRevealSequence()`
  - L151 `_buildStoryContent()`
  - L210 `_buildRatingList()`
  - L312 `_buildRevealLayout()`
  - L377 `_titleBlock()`
  - L412 `_ratingCardWidget()`
  - L466 `_revealMessage()`
  - L472 `_submitRating()`

  </details>


### `lib/widgets/new_moon_overlay.dart` (564 行)

**imports:** dart=1 / package=2 / relative=7

- relative: `../models/lunar_intention.dart`, `../theme/solara_colors.dart`, `../utils/celestial_events.dart`, `../utils/cycle_story_texts.dart`, `../utils/solara_storage.dart`, `glass_panel.dart`, `moon_overlay_shared.dart`

**型定義 (2):**

- L16 `class NewMoonOverlay : StatefulWidget`
- L34 `class _NewMoonOverlayState : State`

**関数 (4 public + 13 private):**

- L31 `createState()`
- L63 `initState()`
- L119 `dispose()`
- L156 `build()`

  <details><summary>private 関数 13 件</summary>

  - L102 `_transitionToChoice()`
  - L107 `_loadNotTodayCount()`
  - L112 `_loadCycleEvents()`
  - L130 `_onChoiceTap()`
  - L144 `_runRevealSequence()`
  - L173 `_buildStoryContent()`
  - L230 `_buildChoiceList()`
  - L325 `_buildRevealLayout()`
  - L443 `_titleBlock()`
  - L481 `_choiceCardWidget()`
  - L517 `_revealMessage()`
  - L524 `_revealEvents()`
  - L548 `_setIntention()`

  </details>


### `lib/widgets/solara_splash.dart` (166 行)

**imports:** dart=1 / package=2 / relative=0

**型定義 (2):**

- L18 `class SolaraSplash : StatefulWidget`
  - コールド起動時に [child] (= SolaraHome / Map) の上へ一瞬だけ被せる
- L26 `class _SolaraSplashState : State`

**関数 (4 public + 1 private):**

- L23 `createState()`
- L41 `initState()`
- L73 `dispose()`
- L79 `build()`

  <details><summary>private 関数 1 件</summary>

  - L101 `_splashLayer()`

  </details>

