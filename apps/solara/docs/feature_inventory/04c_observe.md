# 層 4c: Observe (Tarot) 画面

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 5 / 総行数: 1763
- class/mixin/extension/enum: 14
- 関数 (top-level + method の素拾い): 44
- Navigator.push 等: 0
- Popup/Dialog 呼出: 0
- Worker URL リテラル: 0

## ファイル別

### `lib/screens/observe/observe_card_widgets.dart` (198 行)

**imports:** dart=1 / package=1 / relative=2

- relative: `../../models/tarot_card.dart`, `observe_constants.dart`

**型定義 (4):**

- L10 `class Observe3DCard : StatelessWidget`
- L53 `class ObserveCardBack : StatelessWidget`
- L111 `class ObserveCardFront : StatelessWidget`
- L143 `class ObserveCardInfo : StatelessWidget`

**関数 (4 public + 0 private):**

- L29 `build()`
- L61 `build()`
- L117 `build()`
- L149 `build()`


### `lib/screens/observe/observe_constants.dart` (55 行)

**ファイル先頭コメント:**

```
══════════════════════════════════════════════════
Shared constants for Observe (Tarot) screen
══════════════════════════════════════════════════
```


### `lib/screens/observe/observe_history.dart` (287 行)

**imports:** dart=0 / package=1 / relative=5

- relative: `../../models/daily_reading.dart`, `../../models/tarot_card.dart`, `../../utils/solara_storage.dart`, `../../utils/tarot_data.dart`, `observe_constants.dart`

**型定義 (4):**

- L13 `class ObserveHistoryPanel : StatefulWidget`
- L22 `class _ObserveHistoryPanelState : State`
- L223 `class _SyncInput : StatefulWidget`
- L233 `class _SyncInputState : State`

**関数 (6 public + 4 private):**

- L19 `createState()`
- L50 `build()`
- L230 `createState()`
- L238 `initState()`
- L244 `dispose()`
- L258 `build()`

  <details><summary>private 関数 4 件</summary>

  - L26 `_confirmClearHistory()`
  - L101 `_buildHistoryCard()`
  - L161 `_buildHistoryDetail()`
  - L249 `_onChanged()`

  </details>


### `lib/screens/observe/tarot_altar_scene.dart` (500 行)

**imports:** dart=1 / package=1 / relative=0

**型定義 (4):**

- L18 `class TarotAltarScene : StatefulWidget`
  - Background scene for the Tarot Draw screen.
- L26 `class _TarotAltarSceneState : State`
- L467 `class _PlanetDef`
- L480 `class _AltarLayout`

**関数 (4 public + 6 private):**

- L23 `createState()`
- L38 `initState()`
- L94 `dispose()`
- L101 `build()`

  <details><summary>private 関数 6 件</summary>

  - L52 `_scheduleNextMeteor()`
  - L61 `_triggerMeteor()`
  - L211 `_buildPlanets()`
  - L305 `_planetSprite()`
  - L346 `_buildSunBlaze()`
  - L431 `_buildMeteor()`

  </details>


### `lib/screens/observe_screen.dart` (723 行)

**imports:** dart=2 / package=1 / relative=12

- relative: `../models/daily_reading.dart`, `../models/tarot_card.dart`, `../utils/fortune_api.dart`, `../utils/moon_phase.dart`, `../utils/pro_status.dart`, `../utils/solara_storage.dart`, `../utils/tarot_data.dart`, `../widgets/pro_unlock_dialog.dart`, `observe/observe_constants.dart`, `observe/observe_card_widgets.dart`, `observe/observe_history.dart`, `observe/tarot_altar_scene.dart`

**型定義 (2):**

- L20 `class ObserveScreen : StatefulWidget`
  - Tarot Draw screen — matches tarot.html exactly.
- L26 `class _ObserveScreenState : State`

**関数 (4 public + 16 private):**

- L23 `createState()`
- L95 `initState()`
- L110 `dispose()`
- L290 `build()`

  <details><summary>private 関数 16 件</summary>

  - L46 `_startLoadingMessageRotation()`
  - L58 `_stopLoadingMessageRotation()`
  - L103 `_onProStatusChanged()`
  - L119 `_checkTodayReading()`
  - L144 `_loadHistory()`
  - L149 `_drawCard()`
  - L234 `_resetTodayReading()`
  - L258 `_generateReadingStatic()`
  - L275 `_startTypewriter()`
  - L310 `_buildInnerTabs()`
  - L324 `_innerTabBtn()`
  - L345 `_buildDrawPanel()`
  - L440 `_buildQuestionField()`
  - L524 `_buildQuestionFieldTeaser()`
  - L606 `_buildLoadingIndicator()`
  - L681 `_buildReadingPanel()`

  </details>

