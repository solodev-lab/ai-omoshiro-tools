# 層 4d: Galaxy 画面

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 10 / 総行数: 3766
- class/mixin/extension/enum: 22
- 関数 (top-level + method の素拾い): 84
- Navigator.push 等: 0
- Popup/Dialog 呼出: 2
- Worker URL リテラル: 0

## ファイル別

### `lib/screens/galaxy/constellation_share_card_page.dart` (415 行)

**ファイル先頭コメント:**

```
星座カード共有画面 — Free 機能 (柱 3 看板)

設計: apps/solara/docs/pro_candidates.md §7.3 + class_share_card.dart のパターン踏襲

用途:
  - 刻星化 (CatasterismFormationOverlay) 完了時に「共有」ボタンから起動
  - Star Atlas カードの ⋯ メニューからも将来的に呼べる
  - 縦長 1080×1920 (9:16) でレンダリング、OS 標準シェアシートで PNG を共有

設計原則 (class_share_card と統一):
  - textScaler 1.0 固定で端末フォントサイズの影響を受けない
  - 設計論理サイズ 360×640 で FittedBox スケール = 表示サイズ設定に不変
  - pixelRatio = 1080 / boundary.size.width で動的計算 = 常に 1080 幅出力

思想ガード:
  - 「吉凶判定しない」(design_philosophy) → レアリティの星 5 つを冗長な
    "Common/Rare" 名称なしで表示 (Star Atlas カードと同方針 2026-05-17)
```

**imports:** dart=2 / package=5 / relative=3

- relative: `../../models/galaxy_cycle.dart`, `../../utils/constellation_namer.dart`, `../../widgets/constellation_painter.dart`

**型定義 (2):**

- L34 `class ConstellationShareCardPage : StatefulWidget`
- L387 `class _ShareCardRarityStars : StatelessWidget`

**関数 (3 public + 3 private):**

- L50 `createState()`
- L97 `build()`
- L393 `build()`

  <details><summary>private 関数 3 件</summary>

  - L59 `_share()`
  - L178 `_buildShareImage()`
  - L192 `_buildShareImageInner()`

  </details>


### `lib/screens/galaxy/galaxy_archive_filter.dart` (315 行)

**ファイル先頭コメント:**

```
Galaxy Archive フィルタ・検索 — C2 (Pro 機能、柱 3)

設計: apps/solara/docs/pro_candidates.md §7.3 + §3 C2

柱 3 原則: Free は自分の記録 (全完了サイクル) を永久に見られる。
Pro が売るのは「記録を使う道具」= 検索・フィルタ・ソート・月別ハイライト。

役割:
  - Star Atlas タブ上部に表示される操作バー
  - Free: 検索/フィルタアイコンタップで showProUnlockDialog
  - Pro: 検索バー + レアリティチップ + ソート選択を有効化
  - 内部状態は `GalaxyArchiveFilter` クラスで保持し、外部 (atlas タブ) で適用

🔴 思想ガード (project_solara_design_philosophy):
  - 「吉凶判定しない」→ レアリティ高=「良」のような色ランク表現は避ける。
    チップ自体は静かなゴールド系のみ。
```

**imports:** dart=0 / package=1 / relative=3

- relative: `../../models/galaxy_cycle.dart`, `../../theme/solara_colors.dart`, `../../widgets/pro_unlock_dialog.dart`

**型定義 (5):**

- L28 `class GalaxyArchiveFilter`
  - Star Atlas のフィルタ状態。Atlas タブで保持 → カードリスト構築前に
- L100 `enum GalaxyArchiveSort`
- L106 `extension GalaxyArchiveSortLabel : GalaxyArchiveSort`
- L123 `class GalaxyArchiveFilterBar : StatefulWidget`
  - Star Atlas タブ上部に置く検索・フィルタバー。
- L139 `class _GalaxyArchiveFilterBarState : State`

**関数 (7 public + 4 private):**

- L46 `copyWith()`
- L64 `apply()` — `cycles` (新しい順を想定) に絞込 + 並べ替えを適用して返す。
- L136 `createState()`
- L143 `initState()`
- L149 `didUpdateWidget()`
- L158 `dispose()`
- L197 `build()`

  <details><summary>private 関数 4 件</summary>

  - L163 `_proGuard()`
  - L171 `_onQueryChanged()`
  - L184 `_toggleRarity()`
  - L192 `_setSort()`

  </details>


### `lib/screens/galaxy/galaxy_archive_filter_chips.dart` (199 行)

**ファイル先頭コメント:**

```
Galaxy Archive フィルタバーのサブウィジェット — C2 (柱 3)

親: galaxy_archive_filter.dart (part-of 親で import するパッケージは
すべて親側で宣言済み)。本ファイルは widget 定義のみで、import は親に委譲する。

含まれる widget:
  - _SelectedRarityBanner: 「選択中: ★5 ★3 ... クリア」表示
  - _RarityChip: ★N チップ (multi-select、HitTestBehavior.opaque)
  - _SortChip: 並び順メニューチップ (Free 時 Pro Unlock dialog)
```

**型定義 (3):**

- L13 `class _SelectedRarityBanner : StatelessWidget`
- L66 `class _RarityChip : StatelessWidget`
- L124 `class _SortChip : StatelessWidget`

**関数 (3 public + 0 private):**

- L22 `build()`
- L80 `build()`
- L137 `build()`


### `lib/screens/galaxy/galaxy_constellation_builder.dart` (130 行)

**imports:** dart=1 / package=0 / relative=5

- relative: `../../models/daily_reading.dart`, `../../models/galaxy_cycle.dart`, `../../utils/constellation_namer.dart`, `../../utils/moon_phase.dart`, `../../utils/tarot_data.dart`


### `lib/screens/galaxy/galaxy_cycle_actions_sheet.dart` (242 行)

**ファイル先頭コメント:**

```
Galaxy Cycle 操作シート — C5 (柱 3)

設計: apps/solara/docs/pro_candidates.md §7.3 + §3 C5

Star Atlas のカード長押しで表示される bottom sheet。
メニュー項目:
  - 通常再生 ※カードタップと同じだが UX 上ここにも置いておく
  - 形成演出を再生
  - エクスポート (テキストコピー)

2026-05-31: 「形成演出を再生」「テキストとしてコピー」を Free に戻した
(オーナー指示)。全項目 Free。
```

**imports:** dart=1 / package=2 / relative=4

- relative: `../../models/galaxy_cycle.dart`, `../../models/lunar_intention.dart`, `../../theme/solara_colors.dart`, `../../utils/galaxy_cycle_export.dart`

**型定義 (2):**

- L49 `class _CycleActionsSheet : StatelessWidget`
- L164 `class _ActionTile : StatelessWidget`

**関数 (4 public + 1 private):**

- L29 `showGalaxyCycleActionsSheet()` — [GalaxyCycle] に対する Pro メニューを bottom sheet で表示する。
- L34 `Function()`
- L82 `build()`
- L179 `build()`

  <details><summary>private 関数 1 件</summary>

  - L62 `_exportText()`

  </details>


### `lib/screens/galaxy/galaxy_replay_overlay.dart` (215 行)

**imports:** dart=2 / package=2 / relative=3

- relative: `../../models/galaxy_cycle.dart`, `../../utils/constellation_namer.dart`, `../../widgets/constellation_painter.dart`

**型定義 (1):**

- L17 `class GalaxyReplayOverlay : StatelessWidget`

**関数 (1 public + 1 private):**

- L50 `build()`

  <details><summary>private 関数 1 件</summary>

  - L41 `_handleTap()`

  </details>


### `lib/screens/galaxy/galaxy_sample_data.dart` (101 行)

**imports:** dart=1 / package=0 / relative=3

- relative: `../../models/daily_reading.dart`, `../../models/galaxy_cycle.dart`, `../../utils/constellation_namer.dart`

**関数 (1 public + 1 private):**

- L7 `injectGalaxySampleData()` — デモ用サンプルデータ: Cycleに25個の星 + Star Atlasに61全星座

  <details><summary>private 関数 1 件</summary>

  - L41 `_buildSampleFromTemplate()`

  </details>


### `lib/screens/galaxy/galaxy_star_atlas.dart` (445 行)

**imports:** dart=1 / package=2 / relative=5

- relative: `../../models/galaxy_cycle.dart`, `../../utils/constellation_namer.dart`, `../../widgets/constellation_painter.dart`, `../horoscope/horo_antique_icons.dart`, `galaxy_archive_filter.dart`

**型定義 (7):**

- L27 `class GalaxyStarAtlasTab : StatefulWidget`
  - STAR ATLAS タブ本体。HTML の `.atlas-content` と中のグリッドを描画する。
- L47 `class _GalaxyStarAtlasTabState : State`
- L145 `class _AtlasHeader : StatelessWidget`
- L179 `class _ConstellationCard : StatelessWidget`
- L350 `class _RarityStarRow : StatelessWidget`
  - 5 つの星アイコンで rarity を表示する Row。
- L381 `class _NoMatchState : StatelessWidget`
- L406 `class _EmptyState : StatelessWidget`

**関数 (7 public + 0 private):**

- L44 `createState()`
- L51 `build()`
- L149 `build()`
- L193 `build()`
- L356 `build()`
- L385 `build()`
- L408 `build()`


### `lib/screens/galaxy/galaxy_stella_messages.dart` (288 行)

**imports:** dart=1 / package=0 / relative=1

- relative: `../../utils/moon_phase.dart`

**関数 (1 public + 0 private):**

- L16 `moonHealingMessage()` — 月齢 (端末ローカル) を 3 日ごと 10 区分に分け、その区分の月相に沿った


### `lib/screens/galaxy_screen.dart` (1416 行)

**imports:** dart=3 / package=4 / relative=26

- relative: `horoscope/horo_antique_icons.dart`, `../i18n/strings.g.dart`, `../models/daily_reading.dart`, `../models/galaxy_cycle.dart`, `../models/lunar_intention.dart`, `../utils/celestial_events.dart`, `../utils/constellation_namer.dart`, `../utils/solara_i18n.dart`, `../utils/moon_event_status.dart`, `../utils/moon_phase.dart`, `../utils/solara_storage.dart`, `../utils/tarot_data.dart`, `../widgets/catasterism_formation_overlay.dart`, `../widgets/celestial_event_bar.dart`, `../widgets/cycle_spiral_painter.dart`, `../widgets/info_popup.dart`, `../widgets/moon_overlay.dart`, `../widgets/tap_to_unfocus.dart`, `map/map_constants.dart`, `galaxy/constellation_share_card_page.dart`, `galaxy/galaxy_constellation_builder.dart`, `galaxy/galaxy_stella_messages.dart`, `galaxy/galaxy_cycle_actions_sheet.dart`, `galaxy/galaxy_sample_data.dart`, `galaxy/galaxy_star_atlas.dart`, `galaxy/galaxy_replay_overlay.dart`

**型定義 (2):**

- L37 `class GalaxyScreen : StatefulWidget`
- L55 `class GalaxyScreenState : State`

**関数 (11 public + 36 private):**

- L52 `createState()`
- L130 `regenerateBackground()` — タブ切替でGalaxyに入ってきた時に、背景 (ネビュラ位置・色・星の位置)
- L141 `pauseMotion()` — main.dart から Galaxy タブ離脱時に呼ばれる。Timer 即停止 = raster 0% 化。
- L157 `recheckMoonEvents()` — タブ入室 / アプリ復帰時に、月イベント (新月・満月・刻星化) の発火判定だけを
- L190 `initState()`
- L201 `jitter()`
- L219 `dispose()`
- L411 `build()`
- L730 `fmtTime()`
- L732 `fmtDate()`
- L1158 `restoreGalaxyState()` — captureRestore のスナップショットから終了画面を再現する (コールド起動時)。

  <details><summary>private 関数 36 件</summary>

  - L199 `_initNebulaPositions()`
  - L228 `_wakeMotion()`
  - L236 `_onMotionTick()`
  - L279 `_loadData()`
  - L354 `_loadArtImage()`
  - L374 `_checkMoonOverlay()`
  - L397 `_dismissTopOverlay()`
  - L537 `_buildTabBar()`
  - L547 `_buildTab()`
  - L590 `_buildCycleTab()`
  - L621 `_buildDayBadge()`
  - L656 `_buildMoonBadge()`
  - L681 `_buildStellaMessage()`
  - L772 `_onDragStart()`
  - L779 `_onDragUpdate()`
  - L790 `_onDragEnd()`
  - L795 `_onTapUp()`
  - L806 `_showDotPopup()`
  - L812 `_hideDotPopup()`
  - L816 `_buildDotPopup()`
  - L869 `_openReplay()`
  - L876 `_closeReplay()`
  - L887 `_openConstellationShare()`
  - L903 `_openCycleActions()`
  - L923 `_buildDebugTriggerRow()`
  - L940 `_buildDebugBtn()`
  - L964 `_debugTriggerNewMoon()`
  - L969 `_debugTriggerFullMoon()`
  - L984 `_debugTriggerCatasterism()`
  - L1002 `_debugTriggerCycleCompletion()`
  - L1047 `_buildMoonOverlay()`
  - L1117 `_onCatasterismResult()`
  - L1132 `_onFormationComplete()`
  - L1194 `_moonPhaseDescription()`
  - L1221 `_showMoonEventsGuide()`
  - L1299 `_showGalaxyUsageGuide()`

  </details>

**Popup/Dialog 呼出 (2):**

- 集計: `showInfoPopup`×2

