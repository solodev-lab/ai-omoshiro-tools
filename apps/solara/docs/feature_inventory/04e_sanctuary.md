# 層 4e: Sanctuary 画面

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 10 / 総行数: 5767
- class/mixin/extension/enum: 28
- 関数 (top-level + method の素拾い): 124
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


### `lib/screens/sanctuary/sanctuary_home_editor.dart` (241 行)

**imports:** dart=1 / package=2 / relative=4

- relative: `../../i18n/strings.g.dart`, `../../utils/solara_storage.dart`, `../../widgets/location_picker_minimap.dart`, `../../widgets/tap_to_unfocus.dart`

**型定義 (2):**

- L15 `class SanctuaryHomeEditorPage : StatefulWidget`
- L23 `class _SanctuaryHomeEditorPageState : State`

**関数 (4 public + 4 private):**

- L20 `createState()`
- L31 `initState()`
- L40 `dispose()`
- L92 `build()`

  <details><summary>private 関数 4 件</summary>

  - L45 `_search()`
  - L70 `_save()`
  - L208 `_input()`
  - L223 `_readonlyField()`

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


### `lib/screens/sanctuary/sanctuary_profile_editor.dart` (612 行)

**imports:** dart=1 / package=3 / relative=6

- relative: `../../i18n/strings.g.dart`, `../../utils/app_locale.dart`, `../../utils/solara_storage.dart`, `../../utils/solara_api.dart`, `../../widgets/location_picker_minimap.dart`, `../../widgets/tap_to_unfocus.dart`

**型定義 (3):**

- L19 `class SanctuaryProfileEditorPage : StatefulWidget`
- L27 `class _SanctuaryProfileEditorPageState : State`
- L586 `class DateSlashFormatter : TextInputFormatter`
  - Auto-inserts `/` after YYYY and MM for date input (YYYY/MM/DD format).

**関数 (5 public + 8 private):**

- L24 `createState()`
- L45 `initState()`
- L70 `dispose()`
- L174 `build()`
- L588 `formatEditUpdate()`

  <details><summary>private 関数 8 件</summary>

  - L81 `_searchPlace()`
  - L109 `_selectPlace()`
  - L123 `_resolveTimezone()`
  - L136 `_save()`
  - L500 `_langBtn()`
  - L543 `_birthSection()`
  - L561 `_inputDecoration()`
  - L572 `_readonlyField()`

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


### `lib/screens/sanctuary/sanctuary_title_diagnosis.dart` (1397 行)

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
  - L952 `_buildPartTrans()`
  - L1055 `_buildForging()`
  - L1180 `_toggleShadowSide()`
  - L1191 `_buildReveal()`
  - L1249 `_buildRevealLightSide()`
  - L1336 `_buildRevealShadowSide()`

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


### `lib/screens/sanctuary_screen.dart` (1703 行)

**imports:** dart=1 / package=3 / relative=25

- relative: `horoscope/horo_antique_icons.dart`, `../i18n/strings.g.dart`, `../utils/consultation_api.dart`, `../utils/consultation_credits.dart`, `../utils/moon_notification_service.dart`, `../utils/pro_status.dart`, `../utils/purchases_service.dart`, `../utils/solara_i18n.dart`, `../utils/solara_storage.dart`, `../utils/title_data.dart`, `../widgets/class_card.dart`, `../widgets/pro_unlock_dialog.dart`, `../widgets/sanctuary_account_section.dart`, `../widgets/tap_to_unfocus.dart`, `consultation/consultation_credit_sheet.dart`, `consultation/consultation_history_screen.dart`, `paywall_screen.dart`, `sanctuary/sanctuary_orb_overlay.dart`, `sanctuary/sanctuary_profile_editor.dart`, `sanctuary/sanctuary_reset_hour_picker.dart`, `sanctuary/sanctuary_title_diagnosis.dart`, `sanctuary/class_share_card.dart`, `sanctuary/sanctuary_home_editor.dart`, `sanctuary/sanctuary_legal_menu.dart`, `sanctuary/title_history_screen.dart`

**型定義 (7):**

- L32 `class SanctuaryScreen : StatefulWidget`
- L39 `class _SanctuaryScreenState : State`
- L1518 `extension _WidgetOpacity : Widget`
- L1527 `class _SettingsGroup : StatelessWidget`
- L1560 `class _SettingsItem : StatelessWidget`
- L1612 `class _NotificationToggleItem : StatefulWidget`
- L1620 `class _NotificationToggleItemState : State`

**関数 (10 public + 35 private):**

- L36 `createState()`
- L81 `initState()`
- L94 `dispose()`
- L470 `build()`
- L1519 `withOpacity()`
- L1533 `build()`
- L1568 `build()`
- L1616 `createState()`
- L1625 `initState()`
- L1661 `build()`

  <details><summary>private 関数 35 件</summary>

  - L100 `_onProChanged()`
  - L104 `_onCreditsChanged()`
  - L114 `_openCreditPurchase()`
  - L118 `_loadSettings()`
  - L142 `_loadProfile()`
  - L162 `_openProfileEditor()`
  - L202 `_openShareCard()`
  - L225 `_startDiagnosis()`
  - L290 `_showRediagnoseProGuide()`
  - L435 `_openHomeEditor()`
  - L452 `_syncHomeToVP()`
  - L548 `_buildTopHeader()`
  - L604 `_buildCreditRow()`
  - L667 `_buildProfileOrb()`
  - L730 `_buildProfileRow()`
  - L762 `_buildStellarProfileSection()`
  - L787 `_buildTitleDiagnosisSection()`
  - L956 `_buildTitleFlipCard()`
  - L1002 `_buildLegacyVCard()`
  - L1029 `_buildTitleVCard()`
  - L1095 `_buildRecordsSection()`
  - L1131 `_buildCosmicProSection()`
  - L1154 `_buildProUpgradeBanner()`
  - L1217 `_buildProActiveBanner()`
  - L1288 `_buildRestoreRow()`
  - L1312 `_openPaywall()`
  - L1321 `_restorePurchases()`
  - L1345 `_buildAstrologySection()`
  - L1375 `_buildHouseOption()`
  - L1408 `_orbSummary()`
  - L1421 `_openOrbOverlay()`
  - L1437 `_buildAppSection()`
  - L1469 `_pickDailyResetHour()`
  - L1630 `_load()`
  - L1635 `_toggle()`

  </details>

