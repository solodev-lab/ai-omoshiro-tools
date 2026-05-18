# 層 4d: Galaxy 画面

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 9 / 総行数: 3317
- class/mixin/extension/enum: 22
- 関数 (top-level + method の素拾い): 85
- Navigator.push 等: 0
- Popup/Dialog 呼出: 1
- Worker URL リテラル: 0

## ファイル別

### `lib/screens/galaxy/constellation_share_card_page.dart` (387 行)

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
- L359 `class _ShareCardRarityStars : StatelessWidget`

**関数 (3 public + 3 private):**

- L45 `createState()`
- L92 `build()`
- L365 `build()`

  <details><summary>private 関数 3 件</summary>

  - L54 `_share()`
  - L173 `_buildShareImage()`
  - L187 `_buildShareImageInner()`

  </details>


### `lib/screens/galaxy/galaxy_archive_filter.dart` (319 行)

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

**imports:** dart=0 / package=1 / relative=4

- relative: `../../models/galaxy_cycle.dart`, `../../theme/solara_colors.dart`, `../../utils/pro_status.dart`, `../../widgets/pro_unlock_dialog.dart`

**型定義 (5):**

- L29 `class GalaxyArchiveFilter`
  - Star Atlas のフィルタ状態。Atlas タブで保持 → カードリスト構築前に
- L101 `enum GalaxyArchiveSort`
- L107 `extension GalaxyArchiveSortLabel : GalaxyArchiveSort`
- L124 `class GalaxyArchiveFilterBar : StatefulWidget`
  - Star Atlas タブ上部に置く検索・フィルタバー。
- L140 `class _GalaxyArchiveFilterBarState : State`

**関数 (8 public + 4 private):**

- L47 `copyWith()`
- L65 `apply()` — `cycles` (新しい順を想定) に絞込 + 並べ替えを適用して返す。
- L137 `createState()`
- L144 `initState()`
- L150 `didUpdateWidget()`
- L159 `dispose()`
- L198 `build()`
- L319 `currentIsPro()` — 外部ヘルパー: ProStatus を参照するシンプル版。状態管理を持たないので

  <details><summary>private 関数 4 件</summary>

  - L164 `_proGuard()`
  - L172 `_onQueryChanged()`
  - L185 `_toggleRarity()`
  - L193 `_setSort()`

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


### `lib/screens/galaxy/galaxy_cycle_actions_sheet.dart` (272 行)

**ファイル先頭コメント:**

```
Galaxy Cycle 操作シート — C5 (Pro 機能、柱 3)

設計: apps/solara/docs/pro_candidates.md §7.3 + §3 C5

Star Atlas のカード長押しで表示される bottom sheet。
メニュー項目:
  - 通常再生 (Free) ※カードタップと同じだが UX 上ここにも置いておく
  - 形成演出を再生 (Pro)
  - エクスポート (テキストコピー / 画像共有、Pro)

Free ユーザーが Pro 項目をタップしたら showProUnlockDialog で誘導する。
```

**imports:** dart=1 / package=2 / relative=6

- relative: `../../models/galaxy_cycle.dart`, `../../models/lunar_intention.dart`, `../../theme/solara_colors.dart`, `../../utils/galaxy_cycle_export.dart`, `../../utils/pro_status.dart`, `../../widgets/pro_unlock_dialog.dart`

**型定義 (2):**

- L50 `class _CycleActionsSheet : StatelessWidget`
- L194 `class _ActionTile : StatelessWidget`

**関数 (4 public + 2 private):**

- L30 `showGalaxyCycleActionsSheet()` — [GalaxyCycle] に対する Pro メニューを bottom sheet で表示する。
- L35 `Function()`
- L91 `build()`
- L209 `build()`

  <details><summary>private 関数 2 件</summary>

  - L63 `_proGuard()`
  - L71 `_exportText()`

  </details>


### `lib/screens/galaxy/galaxy_replay_overlay.dart` (160 行)

**imports:** dart=2 / package=2 / relative=3

- relative: `../../models/galaxy_cycle.dart`, `../../utils/constellation_namer.dart`, `../../widgets/constellation_painter.dart`

**型定義 (1):**

- L17 `class GalaxyReplayOverlay : StatelessWidget`

**関数 (1 public + 1 private):**

- L45 `build()`

  <details><summary>private 関数 1 件</summary>

  - L36 `_handleTap()`

  </details>


### `lib/screens/galaxy/galaxy_sample_data.dart` (101 行)

**imports:** dart=1 / package=0 / relative=3

- relative: `../../models/daily_reading.dart`, `../../models/galaxy_cycle.dart`, `../../utils/constellation_namer.dart`

**関数 (1 public + 1 private):**

- L7 `injectGalaxySampleData()` — デモ用サンプルデータ: Cycleに25個の星 + Star Atlasに61全星座

  <details><summary>private 関数 1 件</summary>

  - L41 `_buildSampleFromTemplate()`

  </details>


### `lib/screens/galaxy/galaxy_star_atlas.dart` (460 行)

**imports:** dart=1 / package=2 / relative=6

- relative: `../../models/galaxy_cycle.dart`, `../../utils/constellation_namer.dart`, `../../utils/pro_status.dart`, `../../widgets/constellation_painter.dart`, `../horoscope/horo_antique_icons.dart`, `galaxy_archive_filter.dart`

**型定義 (7):**

- L25 `class GalaxyStarAtlasTab : StatefulWidget`
  - STAR ATLAS タブ本体。HTML の `.atlas-content` と中のグリッドを描画する。
- L45 `class _GalaxyStarAtlasTabState : State`
- L167 `class _AtlasHeader : StatelessWidget`
- L201 `class _ConstellationCard : StatelessWidget`
- L365 `class _RarityStarRow : StatelessWidget`
  - 5 つの星アイコンで rarity を表示する Row。
- L396 `class _NoMatchState : StatelessWidget`
- L421 `class _EmptyState : StatelessWidget`

**関数 (9 public + 1 private):**

- L42 `createState()`
- L49 `initState()`
- L55 `dispose()`
- L72 `build()`
- L171 `build()`
- L215 `build()`
- L371 `build()`
- L400 `build()`
- L423 `build()`

  <details><summary>private 関数 1 件</summary>

  - L60 `_onProChanged()`

  </details>


### `lib/screens/galaxy_screen.dart` (1289 行)

**imports:** dart=3 / package=4 / relative=21

- relative: `horoscope/horo_antique_icons.dart`, `../models/daily_reading.dart`, `../models/galaxy_cycle.dart`, `../models/lunar_intention.dart`, `../utils/celestial_events.dart`, `../utils/constellation_namer.dart`, `../utils/moon_phase.dart`, `../utils/solara_storage.dart`, `../utils/tarot_data.dart`, `../widgets/catasterism_formation_overlay.dart`, `../widgets/celestial_event_bar.dart`, `../widgets/cycle_spiral_painter.dart`, `../widgets/info_popup.dart`, `../widgets/moon_overlay.dart`, `../widgets/tap_to_unfocus.dart`, `galaxy/constellation_share_card_page.dart`, `galaxy/galaxy_constellation_builder.dart`, `galaxy/galaxy_cycle_actions_sheet.dart`, `galaxy/galaxy_sample_data.dart`, `galaxy/galaxy_star_atlas.dart`, `galaxy/galaxy_replay_overlay.dart`

**型定義 (2):**

- L32 `class GalaxyScreen : StatefulWidget`
- L50 `class GalaxyScreenState : State`

**関数 (9 public + 35 private):**

- L47 `createState()`
- L122 `regenerateBackground()` — タブ切替でGalaxyに入ってきた時に、背景 (ネビュラ位置・色・星の位置)
- L133 `pauseMotion()` — main.dart から Galaxy タブ離脱時に呼ばれる。Timer 即停止 = raster 0% 化。
- L153 `initState()`
- L164 `jitter()`
- L182 `dispose()`
- L382 `build()`
- L698 `fmtTime()`
- L700 `fmtDate()`

  <details><summary>private 関数 35 件</summary>

  - L162 `_initNebulaPositions()`
  - L191 `_wakeMotion()`
  - L199 `_onMotionTick()`
  - L242 `_loadData()`
  - L317 `_loadArtImage()`
  - L332 `_checkMoonOverlay()`
  - L368 `_dismissTopOverlay()`
  - L506 `_buildTabBar()`
  - L516 `_buildTab()`
  - L559 `_buildCycleTab()`
  - L590 `_buildDayBadge()`
  - L614 `_buildMoonBadge()`
  - L639 `_buildStellaMessage()`
  - L742 `_onDragStart()`
  - L749 `_onDragUpdate()`
  - L760 `_onDragEnd()`
  - L765 `_onTapUp()`
  - L776 `_showDotPopup()`
  - L782 `_hideDotPopup()`
  - L786 `_buildDotPopup()`
  - L841 `_openReplay()`
  - L848 `_closeReplay()`
  - L857 `_openConstellationShare()`
  - L872 `_openCycleActions()`
  - L891 `_buildDebugTriggerRow()`
  - L908 `_buildDebugBtn()`
  - L932 `_debugTriggerNewMoon()`
  - L937 `_debugTriggerFullMoon()`
  - L952 `_debugTriggerCatasterism()`
  - L970 `_debugTriggerCycleCompletion()`
  - L1015 `_buildMoonOverlay()`
  - L1083 `_onCatasterismResult()`
  - L1098 `_onFormationComplete()`
  - L1110 `_moonPhaseDescription()`
  - L1153 `_showGalaxyUsageGuide()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1

