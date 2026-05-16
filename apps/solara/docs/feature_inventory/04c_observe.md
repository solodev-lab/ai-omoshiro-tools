# 層 4c: Observe (Tarot) 画面

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 6 / 総行数: 1777
- class/mixin/extension/enum: 15
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


### `lib/screens/observe/observe_question_field.dart` (181 行)

**型定義 (1):**

- L15 `extension _QuestionFieldWidgets : _ObserveScreenState`

**関数 (2 public + 0 private):**

- L20 `buildQuestionField()` — Pro 専用: 「相談者のテーマ」入力欄。
- L104 `buildQuestionFieldTeaser()` — Free 向け誘導: 質問欄を見せず、「Pro でテーマを添えられる」と説明する CTA。


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


### `lib/screens/observe_screen.dart` (556 行)

**imports:** dart=2 / package=1 / relative=12

- relative: `../models/daily_reading.dart`, `../models/tarot_card.dart`, `../utils/fortune_api.dart`, `../utils/moon_phase.dart`, `../utils/pro_status.dart`, `../utils/solara_storage.dart`, `../utils/tarot_data.dart`, `../widgets/pro_unlock_dialog.dart`, `observe/observe_constants.dart`, `observe/observe_card_widgets.dart`, `observe/observe_history.dart`, `observe/tarot_altar_scene.dart`

**型定義 (2):**

- L22 `class ObserveScreen : StatefulWidget`
  - Tarot Draw screen — matches tarot.html exactly.
- L28 `class _ObserveScreenState : State`

**関数 (4 public + 14 private):**

- L25 `createState()`
- L97 `initState()`
- L112 `dispose()`
- L292 `build()`

  <details><summary>private 関数 14 件</summary>

  - L48 `_startLoadingMessageRotation()`
  - L60 `_stopLoadingMessageRotation()`
  - L105 `_onProStatusChanged()`
  - L121 `_checkTodayReading()`
  - L146 `_loadHistory()`
  - L151 `_drawCard()`
  - L236 `_resetTodayReading()`
  - L260 `_generateReadingStatic()`
  - L277 `_startTypewriter()`
  - L312 `_buildInnerTabs()`
  - L326 `_innerTabBtn()`
  - L347 `_buildDrawPanel()`
  - L439 `_buildLoadingIndicator()`
  - L514 `_buildReadingPanel()`

  </details>

