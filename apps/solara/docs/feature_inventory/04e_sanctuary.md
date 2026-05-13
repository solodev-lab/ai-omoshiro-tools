# 層 4e: Sanctuary 画面

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 8 / 総行数: 4335
- class/mixin/extension/enum: 21
- 関数 (top-level + method の素拾い): 88
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


### `lib/screens/sanctuary/sanctuary_orb_overlay.dart` (266 行)

**imports:** dart=0 / package=1 / relative=0

**型定義 (3):**

- L8 `class SanctuaryOrbOverlay : StatefulWidget`
- L16 `class _SanctuaryOrbOverlayState : State`
- L260 `class _OrbSectionLabel : StatelessWidget`

**関数 (4 public + 3 private):**

- L13 `createState()`
- L43 `initState()`
- L63 `build()`
- L264 `build()`

  <details><summary>private 関数 3 件</summary>

  - L48 `_reset()`
  - L174 `_orbRow()`
  - L247 `_orbPmBtn()`

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


### `lib/screens/sanctuary_screen.dart` (1034 行)

**imports:** dart=1 / package=3 / relative=9

- relative: `../utils/solara_storage.dart`, `../utils/title_data.dart`, `../widgets/class_card.dart`, `sanctuary/sanctuary_orb_overlay.dart`, `sanctuary/sanctuary_profile_editor.dart`, `sanctuary/sanctuary_reset_hour_picker.dart`, `sanctuary/sanctuary_title_diagnosis.dart`, `sanctuary/class_share_card.dart`, `sanctuary/sanctuary_home_editor.dart`

**型定義 (6):**

- L16 `class SanctuaryScreen : StatefulWidget`
- L23 `class _SanctuaryScreenState : State`
- L882 `extension _WidgetOpacity : Widget`
- L891 `class _SettingsGroup : StatelessWidget`
- L924 `class _SettingsItem : StatelessWidget`
- L972 `class _SettingsItemWithToggle : StatelessWidget`

**関数 (7 public + 20 private):**

- L20 `createState()`
- L55 `initState()`
- L234 `build()`
- L883 `withOpacity()`
- L897 `build()`
- L932 `build()`
- L980 `build()`

  <details><summary>private 関数 20 件</summary>

  - L61 `_loadSettings()`
  - L85 `_loadProfile()`
  - L103 `_openProfileEditor()`
  - L135 `_openShareCard()`
  - L155 `_startDiagnosis()`
  - L199 `_openHomeEditor()`
  - L216 `_syncHomeToVP()`
  - L298 `_buildProfileRow()`
  - L340 `_buildStellarProfileSection()`
  - L366 `_buildTitleDiagnosisSection()`
  - L525 `_buildTitleFlipCard()`
  - L566 `_buildLegacyVCard()`
  - L589 `_buildTitleVCard()`
  - L653 `_buildCosmicProSection()`
  - L727 `_buildAstrologySection()`
  - L757 `_buildHouseOption()`
  - L791 `_orbSummary()`
  - L797 `_openOrbOverlay()`
  - L813 `_buildAppSection()`
  - L849 `_pickDailyResetHour()`

  </details>

