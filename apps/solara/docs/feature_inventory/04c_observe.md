# 層 4c: Observe (Tarot) 画面

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 12 / 総行数: 3585
- class/mixin/extension/enum: 25
- 関数 (top-level + method の素拾い): 82
- Navigator.push 等: 0
- Popup/Dialog 呼出: 1
- Worker URL リテラル: 0

## ファイル別

### `lib/screens/observe/observe_card_widgets.dart` (209 行)

**imports:** dart=1 / package=1 / relative=4

- relative: `../../i18n/strings.g.dart`, `../../models/tarot_card.dart`, `../../utils/solara_i18n.dart`, `observe_constants.dart`

**型定義 (4):**

- L12 `class Observe3DCard : StatelessWidget`
- L49 `class ObserveCardBack : StatelessWidget`
- L112 `class ObserveCardFront : StatelessWidget`
- L144 `class ObserveCardInfo : StatelessWidget`

**関数 (4 public + 0 private):**

- L25 `build()`
- L53 `build()`
- L118 `build()`
- L150 `build()`


### `lib/screens/observe/observe_category_selector.dart` (203 行)

**型定義 (1):**

- L27 `extension _ObserveCategorySelector : ObserveScreenState`

**関数 (0 public + 6 private):**


  <details><summary>private 関数 6 件</summary>

  - L29 `_buildCategorySelector()`
  - L71 `_categoryChip()`
  - L121 `_onCategoryChipTap()`
  - L142 `_showOverallNoCostToast()`
  - L169 `_showCategoryConfirmPopup()`
  - L194 `_handleBuyFromCategoryPopup()`

  </details>


### `lib/screens/observe/observe_constants.dart` (56 行)

**ファイル先頭コメント:**

```
══════════════════════════════════════════════════
Shared constants for Observe (Tarot) screen
══════════════════════════════════════════════════
```

**imports:** dart=0 / package=0 / relative=1

- relative: `../../utils/solara_i18n.dart`

**関数 (2 public + 0 private):**

- L34 `observePlanetName()` — 惑星キー → ロケール別表示名 (ja=漢字 / en=英名)。
- L52 `elementName()` — エレメントキー → ロケール別表示名 (ja=漢字 / en=英名)。


### `lib/screens/observe/observe_history.dart` (423 行)

**imports:** dart=0 / package=1 / relative=12

- relative: `../../i18n/strings.g.dart`, `../../models/daily_reading.dart`, `../../models/galaxy_cycle.dart`, `../../models/tarot_card.dart`, `../../theme/solara_colors.dart`, `../../utils/solara_storage.dart`, `../../utils/tarot_data.dart`, `../../widgets/memo_text_field.dart`, `observe_constants.dart`, `observe_history_filter.dart`, `observe_history_past.dart`, `observe_reading_button.dart`

**型定義 (2):**

- L20 `class ObserveHistoryPanel : StatefulWidget`
- L42 `class _ObserveHistoryPanelState : State`

**関数 (2 public + 8 private):**

- L39 `createState()`
- L89 `build()`

  <details><summary>private 関数 8 件</summary>

  - L53 `_ensurePastCyclesLoaded()`
  - L65 `_confirmClearHistory()`
  - L135 `_buildInnerTabBar()`
  - L146 `_innerTabBtn()`
  - L181 `_buildCurrentTabContent()`
  - L242 `_buildPastTabContent()`
  - L262 `_buildHistoryCard()`
  - L347 `_buildHistoryDetail()`

  </details>


### `lib/screens/observe/observe_history_filter.dart` (393 行)

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

**imports:** dart=0 / package=1 / relative=5

- relative: `../../i18n/strings.g.dart`, `../../models/daily_reading.dart`, `../../utils/tarot_data.dart`, `../../widgets/pro_unlock_dialog.dart`, `observe_constants.dart`

**型定義 (6):**

- L20 `class ObserveHistoryFilter`
  - 履歴フィルタ状態 (immutable)。
- L91 `class _Sentinel`
- L99 `class ObserveHistoryFilterBar : StatefulWidget`
  - Natal Tarot 履歴フィルタバー。
- L116 `class _ObserveHistoryFilterBarState : State`
- L297 `class _ChipBtn : StatelessWidget`
- L344 `class _ElementChipBtn : StatelessWidget`

**関数 (9 public + 5 private):**

- L40 `copyWith()`
- L65 `apply()` — DailyReading の list を絞り込む。順序は元の list の通り。
- L112 `createState()`
- L120 `initState()`
- L126 `didUpdateWidget()`
- L135 `dispose()`
- L171 `build()`
- L310 `build()`
- L357 `build()`

  <details><summary>private 関数 5 件</summary>

  - L140 `_proGuard()`
  - L146 `_setQuery()`
  - L148 `_toggleElement()`
  - L154 `_toggleMajor()`
  - L162 `_toggleReversed()`

  </details>


### `lib/screens/observe/observe_history_past.dart` (310 行)

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

**imports:** dart=0 / package=1 / relative=10

- relative: `../../i18n/strings.g.dart`, `../../models/daily_reading.dart`, `../../models/galaxy_cycle.dart`, `../../models/tarot_card.dart`, `../../theme/solara_colors.dart`, `../../utils/solara_storage.dart`, `../../utils/tarot_data.dart`, `../../widgets/memo_text_field.dart`, `observe_constants.dart`, `observe_reading_button.dart`

**型定義 (2):**

- L28 `class ObserveHistoryPastPanel : StatefulWidget`
- L37 `class _ObserveHistoryPastPanelState : State`

**関数 (2 public + 4 private):**

- L33 `createState()`
- L45 `build()`

  <details><summary>private 関数 4 件</summary>

  - L67 `_buildCycleCard()`
  - L144 `_buildReadingsList()`
  - L171 `_buildReadingRow()`
  - L241 `_buildReadingDetail()`

  </details>


### `lib/screens/observe/observe_question_field.dart` (198 行)

**型定義 (1):**

- L15 `extension _QuestionFieldWidgets : ObserveScreenState`

**関数 (2 public + 0 private):**

- L26 `buildQuestionField()` — Pro 専用: 「相談者のテーマ」入力欄。
- L123 `buildQuestionFieldTeaser()` — Free 向け誘導: 質問欄を見せず、「Pro でテーマを添えられる」と説明する CTA。


### `lib/screens/observe/observe_reading_button.dart` (61 行)

**ファイル先頭コメント:**

```
「📖 占いの全文を読みやすく表示」ボタン共通実装 (2026-05-19)。

observe_history.dart (現在サイクル HISTORY) と observe_history_past.dart
(過去サイクル HISTORY) の両方で使うため、 重複コードを 1 つに集約。

役割: タップで observe_reading_sheet を起動 (READING 全文を独立シート表示)。
  2026-06-03: Pro 限定を撤去し、Free でも使えるよう開放 (オーナー指示)。
```

**imports:** dart=0 / package=1 / relative=5

- relative: `../../i18n/strings.g.dart`, `../../models/daily_reading.dart`, `../../models/tarot_card.dart`, `../../theme/solara_colors.dart`, `observe_reading_sheet.dart`

**型定義 (1):**

- L17 `class ObserveFullReadingButton : StatelessWidget`

**関数 (1 public + 0 private):**

- L27 `build()`


### `lib/screens/observe/observe_reading_sheet.dart` (184 行)

**ファイル先頭コメント:**

```
タロット履歴 — 「📖 占いの全文を読みやすく表示」シート (Free 開放 2026-06-03)

設計:
  - HISTORY 詳細展開でも READING 本文は表示されるが、一覧で全文を見ると
    圧迫感がある。希望者だけ集中して読める読書モードを提供する。
  - 縦スクロール 1 ページ、フォント大きめ・行間広め。
  - 装飾は最小限 (カード名 + 日付ヘッダ + READING 本文 + close)。

呼出: observe/observe_history.dart の _FullReadingButton から
      showObserveReadingSheet(context, card, reading) で起動。
```

**imports:** dart=0 / package=1 / relative=5

- relative: `../../i18n/strings.g.dart`, `../../models/daily_reading.dart`, `../../models/tarot_card.dart`, `../../theme/solara_colors.dart`, `observe_constants.dart`

**型定義 (1):**

- L34 `class _ReadingSheet : StatelessWidget`

**関数 (2 public + 0 private):**

- L20 `showObserveReadingSheet()`
- L40 `build()`


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


### `lib/screens/observe/tarot_category_popup.dart` (277 行)

**ファイル先頭コメント:**

```
Tarot カテゴリ選択 確認ポップアップ

全体運以外のカテゴリ chip をタップしたときに表示する。
- 現在のクレジット残 (無料 / 購入) を提示
- 「引く」 = カテゴリ確定 (この後ユーザーがカードをタップして 1 クレジット消費)
- 「キャンセル」/ × / 外タップ = 全体運に戻す (呼出側で判定)
- 「クレジットを購入」 = 追加クレジット購入シート (呼出側で開く)

showInfoPopup 経由 (popup 統一規約)。呼出側は returned bool で proceed/cancel を判定。
設計参考: consultation_start_popup.dart

関連: project_solara_stella_free_credits.md (1 クレジット = AI 占い 1 回)
```

**imports:** dart=0 / package=1 / relative=4

- relative: `../../i18n/strings.g.dart`, `../../theme/solara_colors.dart`, `../../utils/consultation_api.dart`, `../../widgets/info_popup.dart`

**型定義 (1):**

- L46 `class _TarotCategoryPopupBody : StatelessWidget`

**関数 (2 public + 0 private):**

- L27 `showTarotCategoryPopup()` — カテゴリ確認ポップアップを開く。
- L60 `build()`

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/observe_screen.dart` (771 行)

**imports:** dart=2 / package=1 / relative=20

- relative: `../models/daily_reading.dart`, `../models/tarot_card.dart`, `../utils/fortune_api.dart`, `../utils/moon_phase.dart`, `../utils/pro_status.dart`, `../utils/solara_storage.dart`, `../utils/tarot_data.dart`, `../i18n/strings.g.dart`, `../utils/solara_i18n.dart`, `../widgets/ai_disclaimer_footer.dart`, `../widgets/ai_report_button.dart`, `../widgets/pro_unlock_dialog.dart`, `../widgets/tap_to_unfocus.dart`, `../theme/solara_colors.dart`, `../utils/consultation_credits.dart`, `consultation/consultation_credit_sheet.dart`, `observe/observe_card_widgets.dart`, `observe/observe_history.dart`, `observe/tarot_altar_scene.dart`, `observe/tarot_category_popup.dart`

**型定義 (2):**

- L31 `class ObserveScreen : StatefulWidget`
  - Tarot Draw screen — matches tarot.html exactly.
- L37 `class ObserveScreenState : State`

**関数 (5 public + 18 private):**

- L34 `createState()`
- L139 `initState()`
- L164 `restoreState()` — 復元: HISTORY タブ + サブタブ (現在/過去サイクル) を再現する。
- L175 `dispose()`
- L448 `build()`

  <details><summary>private 関数 18 件</summary>

  - L70 `_applyCategorySelection()`
  - L77 `_applyTarotCreditBalance()`
  - L94 `_startLoadingMessageRotation()`
  - L106 `_stopLoadingMessageRotation()`
  - L147 `_onProStatusChanged()`
  - L184 `_checkTodayReading()`
  - L225 `_loadHistory()`
  - L230 `_drawCard()`
  - L308 `_fetchReading()`
  - L414 `_retryReading()`
  - L423 `_handleTarotCreditExhausted()`
  - L433 `_startTypewriter()`
  - L474 `_buildInnerTabs()`
  - L488 `_innerTabBtn()`
  - L509 `_buildDrawPanel()`
  - L585 `_buildLoadingIndicator()`
  - L662 `_buildReadingError()`
  - L717 `_buildReadingPanel()`

  </details>

