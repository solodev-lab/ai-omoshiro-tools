# 層 4c: Observe (Tarot) 画面

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 11 / 総行数: 3072
- class/mixin/extension/enum: 24
- 関数 (top-level + method の素拾い): 76
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


### `lib/screens/observe/observe_category_selector.dart` (93 行)

**型定義 (1):**

- L24 `extension _ObserveCategorySelector : _ObserveScreenState`

**関数 (0 public + 2 private):**


  <details><summary>private 関数 2 件</summary>

  - L26 `_buildCategorySelector()`
  - L59 `_categoryChip()`

  </details>


### `lib/screens/observe/observe_constants.dart` (55 行)

**ファイル先頭コメント:**

```
══════════════════════════════════════════════════
Shared constants for Observe (Tarot) screen
══════════════════════════════════════════════════
```


### `lib/screens/observe/observe_history.dart` (423 行)

**imports:** dart=0 / package=1 / relative=12

- relative: `../../models/daily_reading.dart`, `../../models/galaxy_cycle.dart`, `../../models/tarot_card.dart`, `../../theme/solara_colors.dart`, `../../utils/pro_status.dart`, `../../utils/solara_storage.dart`, `../../utils/tarot_data.dart`, `../../widgets/memo_text_field.dart`, `observe_constants.dart`, `observe_history_filter.dart`, `observe_history_past.dart`, `observe_reading_button.dart`

**型定義 (2):**

- L20 `class ObserveHistoryPanel : StatefulWidget`
- L29 `class _ObserveHistoryPanelState : State`

**関数 (4 public + 9 private):**

- L26 `createState()`
- L41 `initState()`
- L58 `dispose()`
- L99 `build()`

  <details><summary>private 関数 9 件</summary>

  - L46 `_ensurePastCyclesLoaded()`
  - L63 `_onProChanged()`
  - L75 `_confirmClearHistory()`
  - L145 `_buildInnerTabBar()`
  - L156 `_innerTabBtn()`
  - L188 `_buildCurrentTabContent()`
  - L249 `_buildPastTabContent()`
  - L269 `_buildHistoryCard()`
  - L347 `_buildHistoryDetail()`

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


### `lib/screens/observe/observe_history_past.dart` (313 行)

**ファイル先頭コメント:**

```
過去サイクル履歴パネル — 月サイクルをまたいで GalaxyCycle に取り込まれた
過去 readings を、 cycle 別にグルーピングして閲覧する。

設計 (2026-05-19、 オーナー要望):
- 柱3 原則「Free でも自分の記録は永久に残る」徹底
- 現在サイクルの readings は ObserveHistoryPanel で見える
- 過去サイクルの readings は GalaxyCycle.readings に取り込まれて
  通常の HISTORY 画面からは見えなくなっていた → 本 widget で復活

注: MVP として SYNCHRONICITY メモは表示のみ (編集は後フェーズ)。
完了サイクルに含まれる reading の synchronicity は cycle.readings 内に
凍結状態で残るため、 編集には completed_cycles 全体の再書込が必要で、
オペレーションコストが高い。 まずは閲覧から。
```

**imports:** dart=0 / package=1 / relative=9

- relative: `../../models/daily_reading.dart`, `../../models/galaxy_cycle.dart`, `../../models/tarot_card.dart`, `../../theme/solara_colors.dart`, `../../utils/solara_storage.dart`, `../../utils/tarot_data.dart`, `../../widgets/memo_text_field.dart`, `observe_constants.dart`, `observe_reading_button.dart`

**型定義 (2):**

- L27 `class ObserveHistoryPastPanel : StatefulWidget`
- L36 `class _ObserveHistoryPastPanelState : State`

**関数 (2 public + 4 private):**

- L32 `createState()`
- L44 `build()`

  <details><summary>private 関数 4 件</summary>

  - L68 `_buildCycleCard()`
  - L147 `_buildReadingsList()`
  - L174 `_buildReadingRow()`
  - L244 `_buildReadingDetail()`

  </details>


### `lib/screens/observe/observe_question_field.dart` (200 行)

**型定義 (1):**

- L15 `extension _QuestionFieldWidgets : _ObserveScreenState`

**関数 (2 public + 0 private):**

- L26 `buildQuestionField()` — Pro 専用: 「相談者のテーマ」入力欄。
- L123 `buildQuestionFieldTeaser()` — Free 向け誘導: 質問欄を見せず、「Pro でテーマを添えられる」と説明する CTA。


### `lib/screens/observe/observe_reading_button.dart` (90 行)

**ファイル先頭コメント:**

```
「📖 占いの全文を読みやすく表示」ボタン共通実装 (2026-05-19)。

observe_history.dart (現在サイクル HISTORY) と observe_history_past.dart
(過去サイクル HISTORY) の両方で使うため、 重複コードを 1 つに集約。

役割:
  - Pro: タップで observe_reading_sheet を起動 (READING 全文を独立シート表示)
  - Free: タップで Pro Unlock dialog 表示
```

**imports:** dart=0 / package=1 / relative=6

- relative: `../../models/daily_reading.dart`, `../../models/tarot_card.dart`, `../../theme/solara_colors.dart`, `../../utils/pro_status.dart`, `../../widgets/pro_unlock_dialog.dart`, `observe_reading_sheet.dart`

**型定義 (1):**

- L19 `class ObserveFullReadingButton : StatelessWidget`

**関数 (1 public + 0 private):**

- L29 `build()`


### `lib/screens/observe/observe_reading_sheet.dart` (183 行)

**ファイル先頭コメント:**

```
タロット履歴 — 「📖 占いの全文を読みやすく表示」シート (Pro 限定)

設計:
  - HISTORY 詳細展開でも READING 本文は表示されるが、一覧で全文を見ると
    圧迫感がある。希望者だけ集中して読める読書モードを提供する。
  - 縦スクロール 1 ページ、フォント大きめ・行間広め。
  - 装飾は最小限 (カード名 + 日付ヘッダ + READING 本文 + close)。

呼出: observe/observe_history.dart の _FullReadingButton から
      showObserveReadingSheet(context, card, reading) で起動。
```

**imports:** dart=0 / package=1 / relative=4

- relative: `../../models/daily_reading.dart`, `../../models/tarot_card.dart`, `../../theme/solara_colors.dart`, `observe_constants.dart`

**型定義 (1):**

- L33 `class _ReadingSheet : StatelessWidget`

**関数 (2 public + 0 private):**

- L19 `showObserveReadingSheet()`
- L39 `build()`


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


### `lib/screens/observe_screen.dart` (620 行)

**imports:** dart=2 / package=1 / relative=14

- relative: `../models/daily_reading.dart`, `../models/tarot_card.dart`, `../utils/fortune_api.dart`, `../utils/moon_phase.dart`, `../utils/pro_status.dart`, `../utils/solara_storage.dart`, `../utils/tarot_data.dart`, `../widgets/pro_unlock_dialog.dart`, `../widgets/tap_to_unfocus.dart`, `consultation/consultation_credit_sheet.dart`, `observe/observe_constants.dart`, `observe/observe_card_widgets.dart`, `observe/observe_history.dart`, `observe/tarot_altar_scene.dart`

**型定義 (2):**

- L25 `class ObserveScreen : StatefulWidget`
  - Tarot Draw screen — matches tarot.html exactly.
- L31 `class _ObserveScreenState : State`

**関数 (4 public + 16 private):**

- L28 `createState()`
- L113 `initState()`
- L128 `dispose()`
- L349 `build()`

  <details><summary>private 関数 16 件</summary>

  - L52 `_selectCategory()`
  - L64 `_startLoadingMessageRotation()`
  - L76 `_stopLoadingMessageRotation()`
  - L121 `_onProStatusChanged()`
  - L137 `_checkTodayReading()`
  - L162 `_loadHistory()`
  - L167 `_drawCard()`
  - L283 `_handleTarotCreditExhausted()`
  - L293 `_resetTodayReading()`
  - L317 `_generateReadingStatic()`
  - L334 `_startTypewriter()`
  - L373 `_buildInnerTabs()`
  - L387 `_innerTabBtn()`
  - L408 `_buildDrawPanel()`
  - L503 `_buildLoadingIndicator()`
  - L578 `_buildReadingPanel()`

  </details>

