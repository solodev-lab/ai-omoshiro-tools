# 層 4e: Sanctuary 画面

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 10 / 総行数: 5706
- class/mixin/extension/enum: 28
- 関数 (top-level + method の素拾い): 124
- Navigator.push 等: 0
- Popup/Dialog 呼出: 5
- Worker URL リテラル: 0

## ファイル別

### `lib/screens/sanctuary/class_share_card.dart` (476 行)

**imports:** dart=2 / package=4 / relative=3

- relative: `../../utils/consult_restore.dart`, `../../utils/title_data.dart`, `../../widgets/class_card.dart`

**型定義 (2):**

- L24 `class ClassShareCardPage : StatefulWidget`
  - クラスカードのシェア用画面
- L57 `class _ClassShareCardPageState : State`

**関数 (4 public + 3 private):**

- L45 `createState()`
- L66 `initState()`
- L83 `dispose()`
- L155 `build()`

  <details><summary>private 関数 3 件</summary>

  - L114 `_share()`
  - L256 `_buildShareImage()`
  - L271 `_buildShareImageInner()`

  </details>


### `lib/screens/sanctuary/sanctuary_home_editor.dart` (240 行)

**imports:** dart=1 / package=2 / relative=3

- relative: `../../utils/solara_storage.dart`, `../../widgets/location_picker_minimap.dart`, `../../widgets/tap_to_unfocus.dart`

**型定義 (2):**

- L14 `class SanctuaryHomeEditorPage : StatefulWidget`
- L22 `class _SanctuaryHomeEditorPageState : State`

**関数 (4 public + 4 private):**

- L19 `createState()`
- L30 `initState()`
- L39 `dispose()`
- L91 `build()`

  <details><summary>private 関数 4 件</summary>

  - L44 `_search()`
  - L69 `_save()`
  - L207 `_input()`
  - L222 `_readonlyField()`

  </details>


### `lib/screens/sanctuary/sanctuary_legal_menu.dart` (153 行)

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

**imports:** dart=1 / package=3 / relative=2

- relative: `../../utils/legal_urls.dart`, `../../widgets/info_popup.dart`

**型定義 (1):**

- L119 `class _LegalRow : StatelessWidget`

**関数 (3 public + 2 private):**

- L32 `showSanctuaryLegalMenu()` — Sanctuary > ✦ App の「Terms & Privacy」エントリから開く法務情報 popup。
- L107 `openSubscriptionSettings()` — 端末のサブスクリプション設定 deep link を直接開く (Cosmic Pro 加入中の解約導線)。
- L125 `build()`

  <details><summary>private 関数 2 件</summary>

  - L77 `_openUrl()`
  - L98 `_openCancelGuide()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/sanctuary/sanctuary_orb_overlay.dart` (277 行)

**imports:** dart=0 / package=1 / relative=0

**型定義 (3):**

- L8 `class SanctuaryOrbOverlay : StatefulWidget`
- L16 `class _SanctuaryOrbOverlayState : State`
- L271 `class _OrbSectionLabel : StatelessWidget`

**関数 (4 public + 3 private):**

- L13 `createState()`
- L43 `initState()`
- L63 `build()`
- L275 `build()`

  <details><summary>private 関数 3 件</summary>

  - L48 `_reset()`
  - L180 `_orbRow()`
  - L258 `_orbPmBtn()`

  </details>


### `lib/screens/sanctuary/sanctuary_profile_editor.dart` (610 行)

**imports:** dart=1 / package=3 / relative=5

- relative: `../../utils/app_locale.dart`, `../../utils/solara_storage.dart`, `../../utils/solara_api.dart`, `../../widgets/location_picker_minimap.dart`, `../../widgets/tap_to_unfocus.dart`

**型定義 (3):**

- L17 `class SanctuaryProfileEditorPage : StatefulWidget`
- L25 `class _SanctuaryProfileEditorPageState : State`
- L584 `class DateSlashFormatter : TextInputFormatter`
  - Auto-inserts `/` after YYYY and MM for date input (YYYY/MM/DD format).

**関数 (5 public + 8 private):**

- L22 `createState()`
- L43 `initState()`
- L68 `dispose()`
- L172 `build()`
- L586 `formatEditUpdate()`

  <details><summary>private 関数 8 件</summary>

  - L79 `_searchPlace()`
  - L107 `_selectPlace()`
  - L121 `_resolveTimezone()`
  - L134 `_save()`
  - L498 `_langBtn()`
  - L541 `_birthSection()`
  - L559 `_inputDecoration()`
  - L570 `_readonlyField()`

  </details>


### `lib/screens/sanctuary/sanctuary_reset_hour_picker.dart` (192 行)

**imports:** dart=0 / package=1 / relative=0

**型定義 (2):**

- L12 `class SanctuaryResetHourPicker : StatefulWidget`
  - 時:分 ピッカー (時 + 分の 2 ドロップダウン、1 分単位)。
- L37 `class _SanctuaryResetHourPickerState : State`

**関数 (3 public + 1 private):**

- L34 `createState()`
- L45 `initState()`
- L52 `build()`

  <details><summary>private 関数 1 件</summary>

  - L156 `_dropdown()`

  </details>


### `lib/screens/sanctuary/sanctuary_title_diagnosis.dart` (1374 行)

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
  - L1313 `_buildRevealShadowSide()`

  </details>

**Popup/Dialog 呼出 (2):**

- 集計: `showInfoPopup`×2


### `lib/screens/sanctuary/title_history_screen.dart` (505 行)

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

**imports:** dart=0 / package=2 / relative=7

- relative: `../../theme/solara_colors.dart`, `../../utils/consult_restore.dart`, `../../utils/solara_storage.dart`, `../../utils/title_data.dart`, `../../widgets/info_popup.dart`, `../../widgets/memo_text_field.dart`, `../../widgets/tap_to_unfocus.dart`

**型定義 (5):**

- L30 `class TitleHistoryScreen : StatefulWidget`
- L40 `class _TitleHistoryScreenState : State`
- L254 `class _EmptyState : StatelessWidget`
- L297 `class _ChainConnector : StatelessWidget`
- L315 `class _TitleChainRow : StatelessWidget`

**関数 (7 public + 4 private):**

- L37 `createState()`
- L48 `initState()`
- L57 `dispose()`
- L181 `build()`
- L258 `build()`
- L301 `build()`
- L329 `build()`

  <details><summary>private 関数 4 件</summary>

  - L62 `_load()`
  - L74 `_confirmClearAll()`
  - L110 `_showGuide()`
  - L320 `_formatDate()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


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


### `lib/screens/sanctuary_screen.dart` (1678 行)

**imports:** dart=1 / package=3 / relative=23

- relative: `horoscope/horo_antique_icons.dart`, `../utils/consultation_api.dart`, `../utils/consultation_credits.dart`, `../utils/moon_notification_service.dart`, `../utils/pro_status.dart`, `../utils/purchases_service.dart`, `../utils/solara_storage.dart`, `../utils/title_data.dart`, `../widgets/class_card.dart`, `../widgets/pro_unlock_dialog.dart`, `../widgets/sanctuary_account_section.dart`, `../widgets/tap_to_unfocus.dart`, `consultation/consultation_credit_sheet.dart`, `consultation/consultation_history_screen.dart`, `paywall_screen.dart`, `sanctuary/sanctuary_orb_overlay.dart`, `sanctuary/sanctuary_profile_editor.dart`, `sanctuary/sanctuary_reset_hour_picker.dart`, `sanctuary/sanctuary_title_diagnosis.dart`, `sanctuary/class_share_card.dart`, `sanctuary/sanctuary_home_editor.dart`, `sanctuary/sanctuary_legal_menu.dart`, `sanctuary/title_history_screen.dart`

**型定義 (7):**

- L30 `class SanctuaryScreen : StatefulWidget`
- L37 `class _SanctuaryScreenState : State`
- L1493 `extension _WidgetOpacity : Widget`
- L1502 `class _SettingsGroup : StatelessWidget`
- L1535 `class _SettingsItem : StatelessWidget`
- L1587 `class _NotificationToggleItem : StatefulWidget`
- L1595 `class _NotificationToggleItemState : State`

**関数 (10 public + 35 private):**

- L34 `createState()`
- L77 `initState()`
- L90 `dispose()`
- L454 `build()`
- L1494 `withOpacity()`
- L1508 `build()`
- L1543 `build()`
- L1591 `createState()`
- L1600 `initState()`
- L1636 `build()`

  <details><summary>private 関数 35 件</summary>

  - L96 `_onProChanged()`
  - L100 `_onCreditsChanged()`
  - L110 `_openCreditPurchase()`
  - L114 `_loadSettings()`
  - L138 `_loadProfile()`
  - L156 `_openProfileEditor()`
  - L188 `_openShareCard()`
  - L208 `_startDiagnosis()`
  - L269 `_showRediagnoseProGuide()`
  - L419 `_openHomeEditor()`
  - L436 `_syncHomeToVP()`
  - L532 `_buildTopHeader()`
  - L588 `_buildCreditRow()`
  - L650 `_buildProfileOrb()`
  - L713 `_buildProfileRow()`
  - L745 `_buildStellarProfileSection()`
  - L770 `_buildTitleDiagnosisSection()`
  - L942 `_buildTitleFlipCard()`
  - L983 `_buildLegacyVCard()`
  - L1006 `_buildTitleVCard()`
  - L1072 `_buildRecordsSection()`
  - L1108 `_buildCosmicProSection()`
  - L1131 `_buildProUpgradeBanner()`
  - L1194 `_buildProActiveBanner()`
  - L1265 `_buildRestoreRow()`
  - L1289 `_openPaywall()`
  - L1298 `_restorePurchases()`
  - L1322 `_buildAstrologySection()`
  - L1352 `_buildHouseOption()`
  - L1385 `_orbSummary()`
  - L1398 `_openOrbOverlay()`
  - L1414 `_buildAppSection()`
  - L1446 `_pickDailyResetHour()`
  - L1605 `_load()`
  - L1610 `_toggle()`

  </details>

