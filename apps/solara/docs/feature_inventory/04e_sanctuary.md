# 層 4e: Sanctuary 画面

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 9 / 総行数: 4865
- class/mixin/extension/enum: 26
- 関数 (top-level + method の素拾い): 99
- Navigator.push 等: 0
- Popup/Dialog 呼出: 3
- Worker URL リテラル: 0

## ファイル別

### `lib/screens/sanctuary/class_share_card.dart` (447 行)

**imports:** dart=2 / package=4 / relative=2

- relative: `../../utils/title_data.dart`, `../../widgets/class_card.dart`

**型定義 (2):**

- L23 `class ClassShareCardPage : StatefulWidget`
  - クラスカードのシェア用画面
- L52 `class _ClassShareCardPageState : State`

**関数 (2 public + 3 private):**

- L40 `createState()`
- L124 `build()`

  <details><summary>private 関数 3 件</summary>

  - L83 `_share()`
  - L227 `_buildShareImage()`
  - L242 `_buildShareImageInner()`

  </details>


### `lib/screens/sanctuary/sanctuary_home_editor.dart` (227 行)

**imports:** dart=1 / package=2 / relative=2

- relative: `../../utils/solara_storage.dart`, `../../widgets/location_picker_minimap.dart`

**型定義 (2):**

- L13 `class SanctuaryHomeEditorPage : StatefulWidget`
- L21 `class _SanctuaryHomeEditorPageState : State`

**関数 (4 public + 4 private):**

- L18 `createState()`
- L29 `initState()`
- L38 `dispose()`
- L90 `build()`

  <details><summary>private 関数 4 件</summary>

  - L43 `_search()`
  - L68 `_save()`
  - L194 `_input()`
  - L209 `_readonlyField()`

  </details>


### `lib/screens/sanctuary/sanctuary_orb_overlay.dart` (272 行)

**imports:** dart=0 / package=1 / relative=0

**型定義 (3):**

- L8 `class SanctuaryOrbOverlay : StatefulWidget`
- L16 `class _SanctuaryOrbOverlayState : State`
- L266 `class _OrbSectionLabel : StatelessWidget`

**関数 (4 public + 3 private):**

- L13 `createState()`
- L43 `initState()`
- L63 `build()`
- L270 `build()`

  <details><summary>private 関数 3 件</summary>

  - L48 `_reset()`
  - L180 `_orbRow()`
  - L253 `_orbPmBtn()`

  </details>


### `lib/screens/sanctuary/sanctuary_profile_editor.dart` (585 行)

**imports:** dart=1 / package=3 / relative=4

- relative: `../../utils/app_locale.dart`, `../../utils/solara_storage.dart`, `../../utils/solara_api.dart`, `../../widgets/location_picker_minimap.dart`

**型定義 (3):**

- L16 `class SanctuaryProfileEditorPage : StatefulWidget`
- L24 `class _SanctuaryProfileEditorPageState : State`
- L559 `class DateSlashFormatter : TextInputFormatter`
  - Auto-inserts `/` after YYYY and MM for date input (YYYY/MM/DD format).

**関数 (5 public + 8 private):**

- L21 `createState()`
- L42 `initState()`
- L67 `dispose()`
- L171 `build()`
- L561 `formatEditUpdate()`

  <details><summary>private 関数 8 件</summary>

  - L78 `_searchPlace()`
  - L106 `_selectPlace()`
  - L120 `_resolveTimezone()`
  - L133 `_save()`
  - L481 `_langBtn()`
  - L516 `_birthSection()`
  - L534 `_inputDecoration()`
  - L545 `_readonlyField()`

  </details>


### `lib/screens/sanctuary/sanctuary_reset_hour_picker.dart` (190 行)

**imports:** dart=0 / package=1 / relative=0

**型定義 (2):**

- L12 `class SanctuaryResetHourPicker : StatefulWidget`
  - 時:分 ピッカー (時 + 分の 2 ドロップダウン、1 分単位)。
- L35 `class _SanctuaryResetHourPickerState : State`

**関数 (3 public + 1 private):**

- L32 `createState()`
- L43 `initState()`
- L50 `build()`

  <details><summary>private 関数 1 件</summary>

  - L154 `_dropdown()`

  </details>


### `lib/screens/sanctuary/sanctuary_title_diagnosis.dart` (1385 行)

**imports:** dart=1 / package=3 / relative=5

- relative: `../../utils/solara_storage.dart`, `../../utils/title_data.dart`, `../../widgets/class_card.dart`, `../../widgets/info_popup.dart`, `title_how_it_works.dart`

**型定義 (2):**

- L18 `class SanctuaryTitleDiagnosisPage : StatefulWidget`
- L37 `class _SanctuaryTitleDiagnosisPageState : State`

**関数 (4 public + 18 private):**

- L34 `createState()`
- L143 `initState()`
- L161 `dispose()`
- L562 `build()`

  <details><summary>private 関数 18 件</summary>

  - L132 `_shuffleCards()`
  - L169 `_beginRounds()`
  - L178 `_selectCard()`
  - L252 `_finishDiagnosis()`
  - L393 `_pickByAstroSeed()`
  - L406 `_accept()`
  - L416 `_acceptPrevious()`
  - L431 `_showPreviousComparison()`
  - L583 `_buildSummoning()`
  - L661 `_buildIntro()`
  - L863 `_showHowItWorks()`
  - L871 `_buildRound()`
  - L929 `_buildPartTrans()`
  - L1032 `_buildForging()`
  - L1157 `_toggleShadowSide()`
  - L1168 `_buildReveal()`
  - L1226 `_buildRevealLightSide()`
  - L1319 `_buildRevealShadowSide()`

  </details>

**Popup/Dialog 呼出 (2):**

- 集計: `showInfoPopup`×2


### `lib/screens/sanctuary/title_history_screen.dart` (385 行)

**ファイル先頭コメント:**

```
称号 (クラス) 変遷ギャラリー — C4 (Pro 機能、柱 3)

設計: apps/solara/docs/pro_candidates.md §7.3 + §3 C4

役割:
  - 過去に診断された「クラス」(axis × court) の変遷を時系列で並べる
  - 二つ名 (出生固定・永久・取り直し不可) は表示しない、ここはクラス専用
  - Free でも閲覧可能 (柱 3 原則「Free でも記録は永久」)
  - 「取り直し」自体の Pro 化は Sanctuary 画面側で別ゲート

ストレージ:
  - SolaraStorage.loadTitleHistory() / clearTitleHistory()
  - 60 件上限 (月 1 回前提で 5 年分)

思想ガード:
  - 「吉凶判定しない」(project_solara_design_philosophy)
    → 旧クラスを「以前は…」と弱めて表示しない、現在と等価に並べる
```

**imports:** dart=0 / package=2 / relative=3

- relative: `../../theme/solara_colors.dart`, `../../utils/solara_storage.dart`, `../../utils/title_data.dart`

**型定義 (5):**

- L26 `class TitleHistoryScreen : StatefulWidget`
- L36 `class _TitleHistoryScreenState : State`
- L147 `class _EmptyState : StatelessWidget`
- L190 `class _ChainConnector : StatelessWidget`
- L208 `class _TitleChainRow : StatelessWidget`

**関数 (6 public + 3 private):**

- L33 `createState()`
- L41 `initState()`
- L93 `build()`
- L151 `build()`
- L194 `build()`
- L222 `build()`

  <details><summary>private 関数 3 件</summary>

  - L46 `_load()`
  - L58 `_confirmClearAll()`
  - L213 `_formatDate()`

  </details>


### `lib/screens/sanctuary/title_how_it_works.dart` (201 行)

**imports:** dart=0 / package=1 / relative=0

**型定義 (1):**

- L11 `class TitleHowItWorksContent : StatelessWidget`
  - 称号システムの仕組み説明 popup の中身。

**関数 (1 public + 1 private):**

- L15 `build()`

  <details><summary>private 関数 1 件</summary>

  - L142 `_section()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/sanctuary_screen.dart` (1173 行)

**imports:** dart=1 / package=3 / relative=13

- relative: `../utils/pro_status.dart`, `../utils/solara_storage.dart`, `../utils/title_data.dart`, `../widgets/class_card.dart`, `../widgets/pro_unlock_dialog.dart`, `consultation/consultation_history_screen.dart`, `sanctuary/sanctuary_orb_overlay.dart`, `sanctuary/sanctuary_profile_editor.dart`, `sanctuary/sanctuary_reset_hour_picker.dart`, `sanctuary/sanctuary_title_diagnosis.dart`, `sanctuary/class_share_card.dart`, `sanctuary/sanctuary_home_editor.dart`, `sanctuary/title_history_screen.dart`

**型定義 (6):**

- L20 `class SanctuaryScreen : StatefulWidget`
- L27 `class _SanctuaryScreenState : State`
- L1021 `extension _WidgetOpacity : Widget`
- L1030 `class _SettingsGroup : StatelessWidget`
- L1063 `class _SettingsItem : StatelessWidget`
- L1111 `class _SettingsItemWithToggle : StatelessWidget`

**関数 (7 public + 22 private):**

- L24 `createState()`
- L63 `initState()`
- L251 `build()`
- L1022 `withOpacity()`
- L1036 `build()`
- L1071 `build()`
- L1119 `build()`

  <details><summary>private 関数 22 件</summary>

  - L69 `_loadSettings()`
  - L93 `_loadProfile()`
  - L111 `_openProfileEditor()`
  - L143 `_openShareCard()`
  - L163 `_startDiagnosis()`
  - L216 `_openHomeEditor()`
  - L233 `_syncHomeToVP()`
  - L321 `_buildProfileRow()`
  - L363 `_buildStellarProfileSection()`
  - L389 `_buildTitleDiagnosisSection()`
  - L564 `_buildTitleFlipCard()`
  - L605 `_buildLegacyVCard()`
  - L628 `_buildTitleVCard()`
  - L694 `_buildRecordsSection()`
  - L728 `_buildCosmicProSection()`
  - L806 `_buildDevProToggle()`
  - L859 `_buildAstrologySection()`
  - L889 `_buildHouseOption()`
  - L923 `_orbSummary()`
  - L936 `_openOrbOverlay()`
  - L952 `_buildAppSection()`
  - L988 `_pickDailyResetHour()`

  </details>

