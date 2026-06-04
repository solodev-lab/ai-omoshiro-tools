# 層 4e: Sanctuary 画面

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 11 / 総行数: 5948
- class/mixin/extension/enum: 29
- 関数 (top-level + method の素拾い): 129
- Navigator.push 等: 0
- Popup/Dialog 呼出: 5
- Worker URL リテラル: 0

## ファイル別

### `lib/screens/sanctuary/class_share_card.dart` (501 行)

**imports:** dart=2 / package=4 / relative=5

- relative: `../../i18n/strings.g.dart`, `../../utils/consult_restore.dart`, `../../utils/solara_i18n.dart`, `../../utils/title_data.dart`, `../../widgets/class_card.dart`

**型定義 (2):**

- L26 `class ClassShareCardPage : StatefulWidget`
  - クラスカードのシェア用画面
- L63 `class _ClassShareCardPageState : State`

**関数 (4 public + 3 private):**

- L51 `createState()`
- L72 `initState()`
- L91 `dispose()`
- L170 `build()`

  <details><summary>private 関数 3 件</summary>

  - L122 `_share()`
  - L271 `_buildShareImage()`
  - L286 `_buildShareImageInner()`

  </details>


### `lib/screens/sanctuary/sanctuary_home_editor.dart` (243 行)

**imports:** dart=1 / package=2 / relative=5

- relative: `../../i18n/strings.g.dart`, `../../utils/app_locale.dart`, `../../utils/solara_storage.dart`, `../../widgets/location_picker_minimap.dart`, `../../widgets/tap_to_unfocus.dart`

**型定義 (2):**

- L17 `class SanctuaryHomeEditorPage : StatefulWidget`
- L25 `class _SanctuaryHomeEditorPageState : State`

**関数 (4 public + 4 private):**

- L22 `createState()`
- L33 `initState()`
- L42 `dispose()`
- L94 `build()`

  <details><summary>private 関数 4 件</summary>

  - L47 `_search()`
  - L72 `_save()`
  - L210 `_input()`
  - L225 `_readonlyField()`

  </details>


### `lib/screens/sanctuary/sanctuary_legal_menu.dart` (154 行)

**ファイル先頭コメント:**

```
Solara Sanctuary 法務リンクメニュー (Phase 2 launch_checklist)

役割:
  Sanctuary > ✦ App セクションの「Terms & Privacy」エントリから開く法務情報 popup。
  ペイウォール外からも EULA / プライバシー / 特商法 / 解約方法へアクセス可能にする。

設計:
  - popup は project_solara_popup_pattern.md の統一仕様に従い `showInfoPopup` 経由
  - URL は LegalUrls (utils/legal_urls.dart) 単一情報源を参照、ハードコード禁止
  - 解約方法のみ iOS/Android で deep link 切替 (PaywallScreen と同じロジック)

設計思想:
  launch_checklist Phase 2 残: プライバシー/EULA/特商法 Sanctuary 単独リンク [WIP] → [x]
  公開ブロッカー B5 (Apple Review 3.1.2) は Paywall 内 4 リンクで充足済。本ファイルは
  ストア公開後の継続アクセス手段 (ユーザーが Paywall 通らなくなっても法務情報を見られる) の確保。
```

**imports:** dart=1 / package=3 / relative=3

- relative: `../../i18n/strings.g.dart`, `../../utils/legal_urls.dart`, `../../widgets/info_popup.dart`

**型定義 (1):**

- L120 `class _LegalRow : StatelessWidget`

**関数 (3 public + 2 private):**

- L33 `showSanctuaryLegalMenu()` — Sanctuary > ✦ App の「Terms & Privacy」エントリから開く法務情報 popup。
- L108 `openSubscriptionSettings()` — 端末のサブスクリプション設定 deep link を直接開く (Cosmic Pro 加入中の解約導線)。
- L126 `build()`

  <details><summary>private 関数 2 件</summary>

  - L78 `_openUrl()`
  - L99 `_openCancelGuide()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/sanctuary/sanctuary_orb_overlay.dart` (279 行)

**imports:** dart=0 / package=1 / relative=1

- relative: `../../i18n/strings.g.dart`

**型定義 (3):**

- L10 `class SanctuaryOrbOverlay : StatefulWidget`
- L18 `class _SanctuaryOrbOverlayState : State`
- L273 `class _OrbSectionLabel : StatelessWidget`

**関数 (4 public + 3 private):**

- L15 `createState()`
- L45 `initState()`
- L65 `build()`
- L277 `build()`

  <details><summary>private 関数 3 件</summary>

  - L50 `_reset()`
  - L182 `_orbRow()`
  - L260 `_orbPmBtn()`

  </details>


### `lib/screens/sanctuary/sanctuary_profile_editor.dart` (552 行)

**imports:** dart=1 / package=3 / relative=6

- relative: `../../i18n/strings.g.dart`, `../../utils/app_locale.dart`, `../../utils/solara_storage.dart`, `../../utils/solara_api.dart`, `../../widgets/location_picker_minimap.dart`, `../../widgets/tap_to_unfocus.dart`

**型定義 (3):**

- L19 `class SanctuaryProfileEditorPage : StatefulWidget`
- L27 `class _SanctuaryProfileEditorPageState : State`
- L526 `class DateSlashFormatter : TextInputFormatter`
  - Auto-inserts `/` after YYYY and MM for date input (YYYY/MM/DD format).

**関数 (5 public + 7 private):**

- L24 `createState()`
- L45 `initState()`
- L70 `dispose()`
- L176 `build()`
- L528 `formatEditUpdate()`

  <details><summary>private 関数 7 件</summary>

  - L81 `_searchPlace()`
  - L111 `_selectPlace()`
  - L125 `_resolveTimezone()`
  - L138 `_save()`
  - L483 `_birthSection()`
  - L501 `_inputDecoration()`
  - L512 `_readonlyField()`

  </details>


### `lib/screens/sanctuary/sanctuary_reset_hour_picker.dart` (193 行)

**imports:** dart=0 / package=1 / relative=1

- relative: `../../i18n/strings.g.dart`

**型定義 (2):**

- L14 `class SanctuaryResetHourPicker : StatefulWidget`
  - 時:分 ピッカー (時 + 分の 2 ドロップダウン、1 分単位)。
- L38 `class _SanctuaryResetHourPickerState : State`

**関数 (3 public + 1 private):**

- L35 `createState()`
- L46 `initState()`
- L53 `build()`

  <details><summary>private 関数 1 件</summary>

  - L157 `_dropdown()`

  </details>


### `lib/screens/sanctuary/sanctuary_settings_pickers.dart` (206 行)

**imports:** dart=0 / package=1 / relative=3

- relative: `../../i18n/strings.g.dart`, `../../utils/app_locale.dart`, `../../utils/app_text_scale.dart`

**型定義 (1):**

- L166 `class _PickerOption : StatelessWidget`

**関数 (5 public + 1 private):**

- L17 `languageValueLabel()` — 言語設定の現在値ラベル (設定行の右側表示用)。
- L29 `fontSizeValueLabel()` — 文字サイズ設定の現在値ラベル。
- L41 `showLanguagePicker()` — 言語ピッカー (端末追従 / 日本語 / English)。選択で即 [AppLocale.setOverride]。
- L89 `showFontSizePicker()` — 文字サイズピッカー (標準 / 大きめ / 最大) + 注意書き。
- L179 `build()`

  <details><summary>private 関数 1 件</summary>

  - L150 `_sheetTitle()`

  </details>


### `lib/screens/sanctuary/sanctuary_title_diagnosis.dart` (1410 行)

**imports:** dart=1 / package=3 / relative=8

- relative: `../../i18n/strings.g.dart`, `../../i18n/strings.g.dart`, `../../utils/solara_i18n.dart`, `../../utils/solara_storage.dart`, `../../utils/title_data.dart`, `../../widgets/class_card.dart`, `../../widgets/info_popup.dart`, `title_how_it_works.dart`

**型定義 (2):**

- L23 `class SanctuaryTitleDiagnosisPage : StatefulWidget`
- L42 `class _SanctuaryTitleDiagnosisPageState : State`

**関数 (4 public + 18 private):**

- L39 `createState()`
- L153 `initState()`
- L171 `dispose()`
- L580 `build()`

  <details><summary>private 関数 18 件</summary>

  - L142 `_shuffleCards()`
  - L179 `_beginRounds()`
  - L188 `_selectCard()`
  - L262 `_finishDiagnosis()`
  - L408 `_pickByAstroSeed()`
  - L421 `_accept()`
  - L432 `_acceptPrevious()`
  - L447 `_showPreviousComparison()`
  - L601 `_buildSummoning()`
  - L679 `_buildIntro()`
  - L881 `_showHowItWorks()`
  - L889 `_buildRound()`
  - L965 `_buildPartTrans()`
  - L1068 `_buildForging()`
  - L1193 `_toggleShadowSide()`
  - L1204 `_buildReveal()`
  - L1262 `_buildRevealLightSide()`
  - L1349 `_buildRevealShadowSide()`

  </details>

**Popup/Dialog 呼出 (2):**

- 集計: `showInfoPopup`×2


### `lib/screens/sanctuary/title_history_screen.dart` (504 行)

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

**imports:** dart=0 / package=2 / relative=9

- relative: `../../i18n/strings.g.dart`, `../../theme/solara_colors.dart`, `../../utils/consult_restore.dart`, `../../utils/solara_i18n.dart`, `../../utils/solara_storage.dart`, `../../utils/title_data.dart`, `../../widgets/info_popup.dart`, `../../widgets/memo_text_field.dart`, `../../widgets/tap_to_unfocus.dart`

**型定義 (5):**

- L32 `class TitleHistoryScreen : StatefulWidget`
- L42 `class _TitleHistoryScreenState : State`
- L245 `class _EmptyState : StatelessWidget`
- L288 `class _ChainConnector : StatelessWidget`
- L306 `class _TitleChainRow : StatelessWidget`

**関数 (7 public + 4 private):**

- L39 `createState()`
- L50 `initState()`
- L59 `dispose()`
- L172 `build()`
- L249 `build()`
- L292 `build()`
- L320 `build()`

  <details><summary>private 関数 4 件</summary>

  - L64 `_load()`
  - L76 `_confirmClearAll()`
  - L111 `_showGuide()`
  - L311 `_formatDate()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/sanctuary/title_how_it_works.dart` (183 行)

**imports:** dart=0 / package=1 / relative=1

- relative: `../../i18n/strings.g.dart`

**型定義 (1):**

- L13 `class TitleHowItWorksContent : StatelessWidget`
  - 称号システムの仕組み説明 popup の中身。

**関数 (1 public + 1 private):**

- L17 `build()`

  <details><summary>private 関数 1 件</summary>

  - L124 `_section()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/sanctuary_screen.dart` (1723 行)

**imports:** dart=1 / package=3 / relative=28

- relative: `horoscope/horo_antique_icons.dart`, `../i18n/strings.g.dart`, `../utils/app_locale.dart`, `../utils/app_text_scale.dart`, `../utils/consultation_api.dart`, `../utils/consultation_credits.dart`, `../utils/moon_notification_service.dart`, `../utils/pro_status.dart`, `../utils/purchases_service.dart`, `../utils/solara_i18n.dart`, `../utils/solara_storage.dart`, `../utils/title_data.dart`, `../widgets/class_card.dart`, `../widgets/pro_unlock_dialog.dart`, `../widgets/sanctuary_account_section.dart`, `../widgets/tap_to_unfocus.dart`, `consultation/consultation_credit_sheet.dart`, `consultation/consultation_history_screen.dart`, `paywall_screen.dart`, `sanctuary/sanctuary_orb_overlay.dart`, `sanctuary/sanctuary_profile_editor.dart`, `sanctuary/sanctuary_reset_hour_picker.dart`, `sanctuary/sanctuary_settings_pickers.dart`, `sanctuary/sanctuary_title_diagnosis.dart`, `sanctuary/class_share_card.dart`, `sanctuary/sanctuary_home_editor.dart`, `sanctuary/sanctuary_legal_menu.dart`, `sanctuary/title_history_screen.dart`

**型定義 (7):**

- L36 `class SanctuaryScreen : StatefulWidget`
- L43 `class _SanctuaryScreenState : State`
- L1538 `extension _WidgetOpacity : Widget`
- L1547 `class _SettingsGroup : StatelessWidget`
- L1580 `class _SettingsItem : StatelessWidget`
- L1632 `class _NotificationToggleItem : StatefulWidget`
- L1640 `class _NotificationToggleItemState : State`

**関数 (10 public + 35 private):**

- L40 `createState()`
- L85 `initState()`
- L98 `dispose()`
- L474 `build()`
- L1539 `withOpacity()`
- L1553 `build()`
- L1588 `build()`
- L1636 `createState()`
- L1645 `initState()`
- L1681 `build()`

  <details><summary>private 関数 35 件</summary>

  - L104 `_onProChanged()`
  - L108 `_onCreditsChanged()`
  - L118 `_openCreditPurchase()`
  - L122 `_loadSettings()`
  - L146 `_loadProfile()`
  - L166 `_openProfileEditor()`
  - L206 `_openShareCard()`
  - L229 `_startDiagnosis()`
  - L294 `_showRediagnoseProGuide()`
  - L439 `_openHomeEditor()`
  - L456 `_syncHomeToVP()`
  - L555 `_buildTopHeader()`
  - L611 `_buildCreditRow()`
  - L674 `_buildProfileOrb()`
  - L737 `_buildProfileRow()`
  - L769 `_buildStellarProfileSection()`
  - L794 `_buildTitleDiagnosisSection()`
  - L963 `_buildTitleFlipCard()`
  - L1009 `_buildLegacyVCard()`
  - L1036 `_buildTitleVCard()`
  - L1102 `_buildRecordsSection()`
  - L1138 `_buildCosmicProSection()`
  - L1161 `_buildProUpgradeBanner()`
  - L1224 `_buildProActiveBanner()`
  - L1295 `_buildRestoreRow()`
  - L1319 `_openPaywall()`
  - L1328 `_restorePurchases()`
  - L1352 `_buildAstrologySection()`
  - L1382 `_buildHouseOption()`
  - L1415 `_orbSummary()`
  - L1428 `_openOrbOverlay()`
  - L1444 `_buildAppSection()`
  - L1489 `_pickDailyResetHour()`
  - L1650 `_load()`
  - L1655 `_toggle()`

  </details>

