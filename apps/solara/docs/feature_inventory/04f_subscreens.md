# 層 4f: サブ画面 (Forecast / Locations / Philosophy / Font Preview)

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 18 / 総行数: 7599
- class/mixin/extension/enum: 66
- 関数 (top-level + method の素拾い): 191
- Navigator.push 等: 0
- Popup/Dialog 呼出: 5
- Worker URL リテラル: 0

## ファイル別

### `lib/screens/consultation/consultation_history_screen.dart` (518 行)

**ファイル先頭コメント:**

```
Consultation History Screen — Phase 2-4

設計: apps/solara/docs/pro_candidates.md §7.2 Stage 4 + §7.3 柱3

レイアウト:
  - AppBar (戻る / すべて削除)
  - ListView (新しい順、savedAt 降順)
  - 各行: 保存日時 + テーマ + モード + scope + 最初の候補名 + 自由記述抜粋
  - 行タップ → ConsultationResultScreen を読込み専用 (initialReading) で開く

柱 3 の原則:
  - Free でも全件閲覧できる (件数上限 200 は技術的フェイルセーフ)
  - 検索・フィルタは Pro 機能 (本画面では UI のみプレースホルダ、ゲートは課金後)
```

**imports:** dart=0 / package=1 / relative=5

- relative: `../../theme/solara_colors.dart`, `../../utils/consultation_record.dart`, `../../utils/solara_storage.dart`, `../../widgets/glass_panel.dart`, `consultation_result_screen.dart`

**型定義 (5):**

- L45 `class ConsultationHistoryScreen : StatefulWidget`
- L63 `class _ConsultationHistoryScreenState : State`
- L207 `class _EmptyState : StatelessWidget`
- L252 `class _HistoryCard : StatelessWidget`
- L495 `class _MetaChip : StatelessWidget`

**関数 (6 public + 5 private):**

- L59 `createState()`
- L68 `initState()`
- L135 `build()`
- L211 `build()`
- L342 `build()`
- L500 `build()`

  <details><summary>private 関数 5 件</summary>

  - L73 `_load()`
  - L85 `_delete()`
  - L94 `_confirmDeleteAll()`
  - L187 `_openDetail()`
  - L466 `_confirmDelete()`

  </details>


### `lib/screens/consultation/consultation_input_examples.dart` (451 行)

**ファイル先頭コメント:**

```
Consultation Input Screen — 相談例セクション
(part of 'consultation_input_screen.dart')

テーマ × モード × スコープで 3 例文を提示する _ConsultExamples 部品 +
例文データ (_consultExamples)。元 consultation_input_widgets.dart から
L393-834 を切り出し (ファイル肥大化対策、2026-05-16)。
```

**型定義 (2):**

- L353 `class _ConsultExamples : StatelessWidget`
- L401 `class _ExampleRow : StatelessWidget`

**関数 (2 public + 0 private):**

- L367 `build()`
- L407 `build()`


### `lib/screens/consultation/consultation_input_picker.dart` (484 行)

**ファイル先頭コメント:**

```
Consultation Input Screen — 具体地点ピッカー部品
(part of 'consultation_input_screen.dart')

scope='specific' 専用の inline 地点ピッカー (A) を提供する。
検索 + LOCATION quick-pick + 「地図で選ぶ」(B) を 1 ユニットに集約。
元 consultation_input_widgets.dart から L11-23 (_PickedSpecific) と
L836-1295 (_SpecificPicker 系) を切り出し (ファイル肥大化対策、2026-05-16)。
```

**型定義 (6):**

- L12 `class _PickedSpecific`
  - _SpecificPicker からの選択結果を持ち回す軽量レコード。
- L29 `class _SpecificPicker : StatefulWidget`
  - inline 地点ピッカー (A)。検索 + LOCATION quick-pick + 「地図で選ぶ」(B) を集約。
- L52 `class _SpecificPickerState : State`
- L298 `class _SearchHitRow : StatelessWidget`
- L382 `class _LocationChip : StatelessWidget`
- L417 `class _SelectedSpecificCard : StatelessWidget`

**関数 (7 public + 6 private):**

- L49 `createState()`
- L65 `initState()`
- L71 `dispose()`
- L143 `build()`
- L306 `build()`
- L388 `build()`
- L431 `build()`

  <details><summary>private 関数 6 件</summary>

  - L77 `_loadSlots()`
  - L86 `_onSearchChanged()`
  - L99 `_runSearch()`
  - L113 `_onHitTap()`
  - L128 `_onSlotTap()`
  - L135 `_openMapPicker()`

  </details>


### `lib/screens/consultation/consultation_input_screen.dart` (396 行)

**ファイル先頭コメント:**

```
Consultation Input Screen — Stage 1 UI

設計: apps/solara/docs/pro_candidates.md §7.2 Stage 1

入力フォーム:
  - モード 3 択 (migration / travel / daily=おでかけ)
  - テーマ 6 チップ単一選択 (love/money/work/communication/healing/newStart)
  - 地理スコープ 3 択 (specific / region / world)
    ※ daily モードは scope=bearings に自動固定
  - 範囲指定モード時: 大ブロック region picker (日本/北米/ヨーロッパ/...)
  - 自由記述 (任意、テキストエリア)
  - 「相談を始める」ボタン

入力完了 → Stage 2 エンジンで候補生成 → ConsultationResultScreen を push。

ファイル分割 (Solara の horoscope_screen.dart と同じ part-of パターン):
  - 本ファイル: orchestration + state management
  - consultation_input_widgets.dart:  選択肢定数 + Choice classes + 基本サブウィジェット
  - consultation_input_examples.dart: 相談例 (theme × mode × scope = 54 例文)
  - consultation_input_picker.dart:   _PickedSpecific + _SpecificPicker 系
```

**imports:** dart=1 / package=2 / relative=8

- relative: `../../theme/solara_colors.dart`, `../../utils/astro_lines.dart`, `../../utils/consultation_engine.dart`, `../../utils/world_cities.dart`, `../map/map_search.dart`, `../map/map_vp_panel.dart`, `consultation_place_picker_screen.dart`, `consultation_result_screen.dart`

**型定義 (3):**

- L41 `class ConsultationPresetTarget`
  - Map から「📍この場所で相談」で起動した時の preset (specific scope 用)。
- L57 `class ConsultationInputScreen : StatefulWidget`
- L80 `class _ConsultationInputScreenState : State`

**関数 (4 public + 4 private):**

- L76 `createState()`
- L93 `initState()`
- L103 `dispose()`
- L274 `build()`

  <details><summary>private 関数 4 件</summary>

  - L108 `_onModeChanged()`
  - L134 `_resolveRegionCountries()`
  - L218 `_openMapPicker()`
  - L237 `_submit()`

  </details>


### `lib/screens/consultation/consultation_input_widgets.dart` (461 行)

**ファイル先頭コメント:**

```
Consultation Input Screen — 基本サブウィジェット + 選択肢定数
(part of 'consultation_input_screen.dart')

Stage 1 入力画面の基本ウィジェット (テーマ/モード/スコープ選択 + 自由記述 +
自動補完カード + 送信ボタン) と、テーマ/モード/スコープ定数。
巨大化した相談例 (_consultExamples) と地点ピッカー (_SpecificPicker) は
別 part ファイルに分割した。

  consultation_input_screen.dart        ← orchestration + state
  consultation_input_widgets.dart       ← 本ファイル: 基本ウィジェット
  consultation_input_examples.dart      ← 例文 (theme×mode×scope=54)
  consultation_input_picker.dart        ← _PickedSpecific + _SpecificPicker

(Solara は horoscope_screen.dart と同じ part-of パターンを採用)
```

**型定義 (11):**

- L67 `class _ThemeChoice`
- L74 `class _ModeChoice`
- L81 `class _ScopeChoice`
- L90 `class _Section : StatelessWidget`
- L118 `class _ThemeGrid : StatelessWidget`
- L161 `class _ModeRow : StatelessWidget`
- L227 `class _ScopeRow : StatelessWidget`
- L301 `class _RegionPicker : StatelessWidget`
- L343 `class _FreeTextField : StatelessWidget`
- L386 `class _PresetLocationCard : StatelessWidget`
- L423 `class _SubmitBar : StatelessWidget`

**関数 (8 public + 1 private):**

- L96 `build()`
- L124 `build()`
- L167 `build()`
- L239 `build()`
- L307 `build()`
- L348 `build()`
- L391 `build()`
- L429 `build()`

  <details><summary>private 関数 1 件</summary>

  - L52 `_scopeChoicesFor()`

  </details>


### `lib/screens/consultation/consultation_place_picker_screen.dart` (348 行)

**ファイル先頭コメント:**

```
Consultation Place Picker Screen — Stage 1 「地図で選ぶ」 (Hybrid B)

設計: apps/solara/docs/pro_candidates.md §7.2 Stage 1
       + chat 議論 (2026-05-16) 「A + B ハイブリッド」案

役割:
  - Consultation Input 画面の inline picker (A) から「🗺 地図で選ぶ」で push
  - flutter_map で全画面の地図を表示し、検索 / マップタップで地点選択
  - 決定で ConsultationPresetTarget を返す (Navigator.pop の引数)
  - キャンセル / 戻る で null を返す

map_screen との関係:
  - map_screen.dart (~2700 行) は触らない (独立画面)
  - flutter_map package を直接使い、Solara の地図テーマ (osmHotDark) と
    共通の TileLayer ビルダ (buildStyledTileLayer) のみ流用
  - 検索は map_search.dart の searchPlaces / SearchHit を流用
  - 逆ジオコーディングは reverse_geocode.dart の reverseGeocodeDetail を使う

UI 構造:
  ┌─ AppBar (戻る / タイトル) ────────────────────┐
  │  [検索 ____________________]  ✕              │
  │  [候補1] [候補2] [候補3]                      │  ← suggestions overlay
  ├──────────────────────────────────────────────┤
  │                                              │
  │     flutter_map (全画面、osmHotDark)         │
  │       タップで点選択 → ピン                   │
  │       検索結果は番号付きピン                  │
  │                                              │
  ├──────────────────────────────────────────────┤
  │  ✓ 京都 (京都府 / JP)                        │  ← 選択中カード
  │  35.011°N, 135.768°E                         │
  │  [ キャンセル ]   [ ✓ この地点で相談 ]       │
  └──────────────────────────────────────────────┘
```

**imports:** dart=1 / package=3 / relative=5

- relative: `../../theme/solara_colors.dart`, `../../utils/reverse_geocode.dart`, `../map/map_search.dart`, `../map/map_styles.dart`, `consultation_input_screen.dart`

**型定義 (1):**

- L52 `class ConsultationPlacePickerScreen : StatefulWidget`
  - 地点選択画面 (B、フルスクリーン)。

**関数 (3 public + 8 private):**

- L66 `createState()`
- L97 `dispose()`
- L231 `build()`

  <details><summary>private 関数 8 件</summary>

  - L106 `_onSearchChanged()`
  - L119 `_runSearch()`
  - L142 `_onHitTap()`
  - L156 `_shortName()`
  - L166 `_selectPoint()`
  - L198 `_onMapTap()`
  - L203 `_clearSelection()`
  - L214 `_confirm()`

  </details>


### `lib/screens/consultation/consultation_place_picker_widgets.dart` (411 行)

**ファイル先頭コメント:**

```
Consultation Place Picker — サブウィジェット
(part of 'consultation_place_picker_screen.dart')

flutter_map ベースの地点選択画面のサブウィジェット群:
  - _SearchBar: 検索ボックス + サジェスト一覧 (番号バッジ付き)
  - _NumberedPin: 検索結果の地図上ピン
  - _SelectionCard: 画面下の選択中カード ＋ キャンセル / 確定ボタン

親 consultation_place_picker_screen.dart は orchestration + State + map 配置のみ
担う (ファイル肥大化対策、2026-05-16 分割)。
```

**型定義 (3):**

- L14 `class _SearchBar : StatelessWidget`
- L196 `class _NumberedPin : StatelessWidget`
- L221 `class _SelectionCard : StatelessWidget`

**関数 (3 public + 1 private):**

- L32 `build()`
- L201 `build()`
- L264 `build()`

  <details><summary>private 関数 1 件</summary>

  - L247 `_coordLabel()`

  </details>


### `lib/screens/consultation/consultation_result_screen.dart` (472 行)

**ファイル先頭コメント:**

```
Consultation Result Screen — Stage 4 UI

設計: apps/solara/docs/pro_candidates.md §7.2 Stage 4

レイアウト:
  - AppBar (戻る / share プレースホルダ / 閉じる)
  - intro (固定、上部)
  - PageView × N 候補 (横スワイプ + HapticFeedback.selectionClick)
    候補カード: 名前 + energyLabels chips + narrative (縦スクロール)
  - outro (固定、下部)
  - 「もう一度候補を出す」ボタン (refresh callback がある場合のみ)

状態: loading / loaded / error / refreshing

Phase 2-4 で対応:
  - 自動保存 (solara_storage に request + response 永続化)
  - 履歴閲覧画面
  - 「📍地図で確認」連動 (公開後 v1.x)
  - share ボタンの実体化
```

**imports:** dart=0 / package=2 / relative=9

- relative: `../../theme/solara_colors.dart`, `../../utils/consultation_api.dart`, `../../utils/consultation_engine.dart`, `../../utils/consultation_record.dart`, `../../utils/consultation_share.dart`, `../../utils/pro_status.dart`, `../../utils/solara_storage.dart`, `../../widgets/glass_panel.dart`, `../../widgets/pro_unlock_dialog.dart`

**型定義 (2):**

- L36 `class ConsultationResultScreen : StatefulWidget`
- L89 `class _ConsultationResultScreenState : State`

**関数 (4 public + 8 private):**

- L85 `createState()`
- L107 `initState()`
- L121 `dispose()`
- L372 `build()`

  <details><summary>private 関数 8 件</summary>

  - L126 `_runFetch()`
  - L150 `_fetch()`
  - L174 `_refresh()`
  - L221 `_maybePersist()`
  - L246 `_openShareSheet()`
  - L332 `_copyText()`
  - L350 `_shareImage()`
  - L426 `_buildBody()`

  </details>


### `lib/screens/consultation/consultation_result_widgets.dart` (446 行)

**ファイル先頭コメント:**

```
Consultation Result Screen — Stage 4 サブウィジェット部
(part of '../consultation_result_screen.dart')

Stage 4 結果画面の内部ウィジェットを分離。consultation_result_screen.dart は
orchestration + state management 専担、本ファイルは presentation を担当する。
(Solara は horoscope_screen.dart と同じ part-of パターンを採用)
```

**型定義 (10):**

- L11 `enum _ShareChoice`
  - シェアシートで選ばれた選択肢。
- L15 `class _LoadingSkeleton : StatelessWidget`
- L43 `class _ErrorBox : StatelessWidget`
- L90 `class _IntroBlock : StatelessWidget`
- L136 `class _OutroBlock : StatelessWidget`
- L166 `class _PageIndicator : StatelessWidget`
- L198 `class _RefreshButton : StatelessWidget`
- L239 `class _CandidateCard : StatelessWidget`
- L347 `class _EnergyChip : StatelessWidget`
- L375 `class _CandidateKindBadge : StatelessWidget`
  - 候補種別バッジ (方角 / 場所)。

**関数 (9 public + 0 private):**

- L19 `build()`
- L49 `build()`
- L96 `build()`
- L141 `build()`
- L172 `build()`
- L204 `build()`
- L267 `build()`
- L352 `build()`
- L384 `build()`


### `lib/screens/font_preview_screen.dart` (138 行)

**imports:** dart=0 / package=2 / relative=0

**型定義 (3):**

- L6 `class FontPreviewScreen : StatefulWidget`
  - フォント比較画面 — 候補フォント8種を Horo と同じコンテキストで並べて比較
- L12 `class _FontPreviewScreenState : State`
- L134 `class _FontOption`

**関数 (2 public + 1 private):**

- L9 `createState()`
- L32 `build()`

  <details><summary>private 関数 1 件</summary>

  - L48 `_buildSample()`

  </details>


### `lib/screens/forecast/forecast_life_periods.dart` (219 行)

**imports:** dart=0 / package=1 / relative=3

- relative: `../../utils/forecast_cache.dart`, `../../widgets/info_popup.dart`, `../map/map_constants.dart`

**型定義 (1):**

- L28 `class ForecastLifePeriodsSection : StatelessWidget`
  - 「◯◯期」セクション — 永続保存された運勢サイクルを表示

**関数 (1 public + 2 private):**

- L38 `build()`

  <details><summary>private 関数 2 件</summary>

  - L88 `_periodRow()`
  - L140 `_showLifePeriodsInfo()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/forecast/forecast_top5.dart` (238 行)

**imports:** dart=0 / package=1 / relative=3

- relative: `../../utils/forecast_cache.dart`, `../../widgets/info_popup.dart`, `../map/map_constants.dart`

**型定義 (1):**

- L8 `class ForecastTop5Section : StatelessWidget`
  - 強運Top5 セクション — 永続保存された Top5 を mode 別に表示

**関数 (1 public + 4 private):**

- L30 `build()`

  <details><summary>private 関数 4 件</summary>

  - L57 `_modeSelector()`
  - L75 `_seg()`
  - L100 `_row()`
  - L134 `_showTop5Info()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/forecast_screen.dart` (1067 行)

**imports:** dart=0 / package=1 / relative=9

- relative: `../utils/forecast_cache.dart`, `../utils/pro_status.dart`, `../utils/solara_storage.dart`, `../widgets/info_popup.dart`, `../widgets/no_profile_guide.dart`, `../widgets/pro_unlock_dialog.dart`, `forecast/forecast_life_periods.dart`, `forecast/forecast_top5.dart`, `map/map_constants.dart`

**型定義 (3):**

- L15 `class ForecastScreen : StatefulWidget`
  - Forecast 画面 — 1年予測（ヒートマップ + 選択日詳細 + 強運Top5）
- L33 `class _ForecastScreenState : State`
- L1038 `class _DayStepperButton : StatelessWidget`
  - 選択日詳細パネルの △ ボタン (左右で 1 日前後に動かす)。

**関数 (4 public + 30 private):**

- L30 `createState()`
- L65 `initState()`
- L150 `build()`
- L1049 `build()`

  <details><summary>private 関数 30 件</summary>

  - L70 `_initialize()`
  - L76 `_loadSettings()`
  - L90 `_setColorMode()`
  - L95 `_setHighColor()`
  - L100 `_load()`
  - L130 `_setYearOffset()`
  - L192 `_buildBody()`
  - L246 `_buildBasisCard()`
  - L297 `_fmt()`
  - L300 `_buildBestChip()`
  - L334 `_yearSeg()`
  - L358 `_buildHeatmap()`
  - L434 `_buildColorModeToggle()`
  - L475 `_rankSeg()`
  - L505 `_segment()`
  - L526 `_buildLegend()`
  - L553 `_catColorChips()`
  - L567 `_monthRow()`
  - L596 `_dayCell()`
  - L627 `_cellColor()`
  - L644 `_gradientColor()`
  - L655 `_categoryColor()`
  - L671 `_canShiftSelectedDay()`
  - L682 `_shiftSelectedDay()`
  - L689 `_buildSelectedDayDetail()`
  - L752 `_metric()`
  - L760 `_catBar()`
  - L797 `_buildFetchInfo()`
  - L811 `_showForecastUsageGuide()`
  - L937 `_showHeatmapInfo()`

  </details>

**Popup/Dialog 呼出 (2):**

- 集計: `showInfoPopup`×2


### `lib/screens/locations/locations_date_stepper.dart` (391 行)

**imports:** dart=0 / package=2 / relative=0

**型定義 (5):**

- L9 `class LocationsDateStepper : StatelessWidget`
  - Locations 画面の日付ステッパー（年▲▼ 月▲▼ 日▲▼ + 「今日」リセット）。
- L206 `class _DateNumberField : StatefulWidget`
  - 数値を直接タイプして編集できるフィールド（年/月/日 共通）。
- L223 `class _DateNumberFieldState : State`
- L304 `class _HourNumberField : StatefulWidget`
  - 時 (hour) を直接タイプして編集できるフィールド。
- L314 `class _HourNumberFieldState : State`

**関数 (11 public + 7 private):**

- L53 `build()`
- L220 `createState()`
- L228 `initState()`
- L236 `didUpdateWidget()`
- L260 `dispose()`
- L268 `build()`
- L311 `createState()`
- L319 `initState()`
- L328 `didUpdateWidget()`
- L353 `dispose()`
- L361 `build()`

  <details><summary>private 関数 7 件</summary>

  - L129 `_hourStepperBlock()`
  - L159 `_stepperBlock()`
  - L189 `_stepBtn()`
  - L244 `_onFocusChange()`
  - L248 `_commit()`
  - L336 `_onFocusChange()`
  - L340 `_commit()`

  </details>


### `lib/screens/locations_screen.dart` (737 行)

**imports:** dart=1 / package=2 / relative=8

- relative: `../utils/solara_storage.dart`, `../widgets/info_popup.dart`, `../widgets/no_profile_guide.dart`, `locations/locations_date_stepper.dart`, `map/map_astro.dart`, `map/map_constants.dart`, `map/map_search.dart`, `map/map_vp_panel.dart`

**型定義 (3):**

- L15 `class LocationsScreen : StatefulWidget`
  - Locations 一覧画面 — 登録済み拠点を16方位スコア付きで管理。
- L38 `class _LocationsScreenState : State`
- L624 `class _SlotStats`

**関数 (3 public + 18 private):**

- L35 `createState()`
- L66 `initState()`
- L274 `build()`

  <details><summary>private 関数 18 件</summary>

  - L71 `_load()`
  - L131 `_shiftDate()`
  - L141 `_setYmd()`
  - L160 `_setHour()`
  - L168 `_shiftHour()`
  - L175 `_resetToday()`
  - L185 `_setDate()`
  - L218 `_addCurrent()`
  - L230 `_delete()`
  - L235 `_rename()`
  - L344 `_buildRefPointSelector()`
  - L424 `_buildCategorySelector()`
  - L468 `_emptyState()`
  - L493 `_buildList()`
  - L502 `_buildRow()`
  - L582 `_scoreBar()`
  - L618 `_fmtKm()`
  - L634 `_showLocationsUsageGuide()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/paywall_screen.dart` (220 行)

**ファイル先頭コメント:**

```
Solara ペイウォール画面 — Phase 2-6b

設計:
  - launch_checklist Phase 2「ペイウォール UI 🚨 公開ブロッカー B5 (3.1.2 全項目 + 特商法 5 項目必須)」
  - project_solara_security_principles 原則 4「公開前必須の法務 3 点セット」
  - feedback_i18n_last: 当面 ja-JP のみ。EN 版はストアアップ前最終工程

必須項目 (B5):
  ✦ サブスクタイトル ✦ 期間 (月額/年額) ✦ 価格 (税込) ✦ コンテンツ概要
  ✦ 自動更新明記 ✦ 解約方法リンク ✦ EULA ✦ プライバシーポリシー
  ✦ Free Trial 明記 ✦ 購入を復元

振舞:
  - Offerings 取得成功 → 月額 / 年額の 2 カード、タップで購入
  - Offerings 取得失敗 (API キー未設定 / 未配信 / オフライン) → 「ストア準備中」案内
  - 購入完了 → entitlement listener が ProStatus 更新 → pop で前画面に戻る
```

**imports:** dart=1 / package=4 / relative=4

- relative: `../theme/solara_colors.dart`, `../utils/legal_urls.dart`, `../utils/pro_status.dart`, `../utils/purchases_service.dart`

**型定義 (2):**

- L32 `class PaywallScreen : StatefulWidget`
- L39 `class _PaywallScreenState : State`

**関数 (4 public + 7 private):**

- L36 `createState()`
- L47 `initState()`
- L54 `dispose()`
- L168 `build()`

  <details><summary>private 関数 7 件</summary>

  - L59 `_onProStatusChanged()`
  - L66 `_loadOfferings()`
  - L79 `_purchase()`
  - L111 `_restore()`
  - L135 `_showSnack()`
  - L145 `_openUrl()`
  - L153 `_openCancelGuide()`

  </details>


### `lib/screens/paywall_widgets.dart` (443 行)

**ファイル先頭コメント:**

```
Paywall Screen — プラン表示 / 機能リスト / 法的リンク のサブウィジェット
(part of 'paywall_screen.dart')

役割:
  - Stage 1 ペイウォール画面の表示パーツを分割保管
  - 親 (`_PaywallScreenState`) のメソッドとしてアクセス可能 (part-of)

内訳:
  - _buildHero                : ゴールドグラデのタイトル + 一文紹介
  - _buildFeatureList         : Pro で開く 5 機能の icon + 説明
  - _buildPlansSection        : Loading / 配信あり (月額/年額) / 配信無し
  - _buildStoreUnavailable    : Offerings 未配信 / 取得失敗時の準備中バナー
  - _buildPlanCard            : 単一プラン (年額 / 月額) のカード UI + 購入導線
  - _periodLabel / _introPeriodLabel : PackageType / PeriodUnit → 日本語ラベル

(Solara は consultation_input_screen.dart と同じ part-of パターンを採用)
```

**型定義 (1):**

- L20 `extension _PaywallWidgets : _PaywallScreenState`

**関数 (0 public + 13 private):**


  <details><summary>private 関数 13 件</summary>

  - L21 `_buildHero()`
  - L56 `_buildFeatureList()`
  - L76 `_featureRow()`
  - L122 `_buildPlansSection()`
  - L154 `_buildStoreUnavailable()`
  - L198 `_buildPlanCard()`
  - L309 `_periodLabel()`
  - L330 `_introPeriodLabel()`
  - L346 `_buildErrorPanel()`
  - L375 `_buildAutoRenewNotice()`
  - L391 `_buildLegalLinks()`
  - L407 `_legalLink()`
  - L422 `_buildRestoreButton()`

  </details>


### `lib/screens/solara_philosophy_screen.dart` (159 行)

**ファイル先頭コメント:**

```
============================================================
Solara Philosophy Screen — 設計思想ガイド（章0）

E5: 流派ガイドページの最初の章として、Solaraの設計思想
（ソフト/ハード独立2エネルギー、占い的吉凶判定をしない、
  両面思想）をユーザーに伝える。

データソース: lib/utils/solara_manifesto.dart
設計根拠: project_solara_design_philosophy.md
============================================================
```

**imports:** dart=0 / package=1 / relative=3

- relative: `../theme/solara_colors.dart`, `../utils/solara_manifesto.dart`, `../widgets/glass_panel.dart`

**型定義 (4):**

- L17 `class SolaraPhilosophyScreen : StatelessWidget`
- L61 `class _Hero : StatelessWidget`
- L102 `class _SectionCard : StatelessWidget`
- L143 `class _Footer : StatelessWidget`

**関数 (4 public + 0 private):**

- L21 `build()`
- L65 `build()`
- L107 `build()`
- L147 `build()`

