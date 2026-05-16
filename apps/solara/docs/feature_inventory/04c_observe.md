# 層 4c: Observe (Tarot) 画面

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 7 / 総行数: 2274
- class/mixin/extension/enum: 21
- 関数 (top-level + method の素拾い): 63
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


### `lib/screens/observe/observe_history.dart` (383 行)

**imports:** dart=0 / package=1 / relative=7

- relative: `../../models/daily_reading.dart`, `../../models/tarot_card.dart`, `../../utils/pro_status.dart`, `../../utils/solara_storage.dart`, `../../utils/tarot_data.dart`, `observe_constants.dart`, `observe_history_filter.dart`

**型定義 (4):**

- L15 `class ObserveHistoryPanel : StatefulWidget`
- L24 `class _ObserveHistoryPanelState : State`
- L319 `class _SyncInput : StatefulWidget`
- L329 `class _SyncInputState : State`

**関数 (8 public + 5 private):**

- L21 `createState()`
- L29 `initState()`
- L35 `dispose()`
- L76 `build()`
- L326 `createState()`
- L334 `initState()`
- L340 `dispose()`
- L354 `build()`

  <details><summary>private 関数 5 件</summary>

  - L40 `_onProChanged()`
  - L52 `_confirmClearHistory()`
  - L165 `_buildHistoryCard()`
  - L243 `_buildHistoryDetail()`
  - L345 `_onChanged()`

  </details>


### `lib/screens/observe/observe_history_filter.dart` (397 行)

**ファイル先頭コメント:**

```
Natal Tarot 履歴フィルタ — C3 (Pro 機能、柱 3)

設計: apps/solara/docs/pro_candidates.md §7.3 + §3 C3

役割:
  - ObserveHistoryPanel 上部に置く検索 + フィルタチップ
  - Pro: キーワード検索 / アルカナ (Major/Minor) / エレメント / 正逆位置
  - Free: バー自体は表示するが操作で showProUnlockDialog
  - フィルタ適用ロジックは `ObserveHistoryFilter.apply` で集中管理
```

**imports:** dart=0 / package=1 / relative=6

- relative: `../../models/daily_reading.dart`, `../../models/tarot_card.dart`, `../../utils/pro_status.dart`, `../../utils/tarot_data.dart`, `../../widgets/pro_unlock_dialog.dart`, `observe_constants.dart`

**型定義 (6):**

- L21 `class ObserveHistoryFilter`
  - 履歴フィルタ状態 (immutable)。
- L92 `class _Sentinel`
- L100 `class ObserveHistoryFilterBar : StatefulWidget`
  - Natal Tarot 履歴フィルタバー。
- L117 `class _ObserveHistoryFilterBarState : State`
- L298 `class _ChipBtn : StatelessWidget`
- L343 `class _ElementChipBtn : StatelessWidget`

**関数 (11 public + 5 private):**

- L41 `copyWith()`
- L66 `apply()` — DailyReading の list を絞り込む。順序は元の list の通り。
- L113 `createState()`
- L121 `initState()`
- L127 `didUpdateWidget()`
- L136 `dispose()`
- L173 `build()`
- L311 `build()`
- L356 `build()`
- L392 `observeHistoryIsPro()` — 外部からも参照しやすいよう pro 状態を取れるショートカット (テストで mock しやすい)。
- L397 `cardForId()`

  <details><summary>private 関数 5 件</summary>

  - L141 `_proGuard()`
  - L148 `_setQuery()`
  - L150 `_toggleElement()`
  - L156 `_toggleMajor()`
  - L164 `_toggleReversed()`

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


### `lib/screens/observe_screen.dart` (560 行)

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
- L296 `build()`

  <details><summary>private 関数 14 件</summary>

  - L48 `_startLoadingMessageRotation()`
  - L60 `_stopLoadingMessageRotation()`
  - L105 `_onProStatusChanged()`
  - L121 `_checkTodayReading()`
  - L146 `_loadHistory()`
  - L151 `_drawCard()`
  - L240 `_resetTodayReading()`
  - L264 `_generateReadingStatic()`
  - L281 `_startTypewriter()`
  - L316 `_buildInnerTabs()`
  - L330 `_innerTabBtn()`
  - L351 `_buildDrawPanel()`
  - L443 `_buildLoadingIndicator()`
  - L518 `_buildReadingPanel()`

  </details>

