# Solara feature inventory — Coverage Report

> 機械抽出 ↔ ドキュメント / Worker ↔ Flutter の対整合チェック結果。
> このファイルは extract.py が再生成する。手で編集しないこと。

## #3 Worker ↔ Flutter エンドポイント対整合

- Worker 側に定義された path: **30**
- Flutter から呼ばれている path リテラル: **18**

### Worker → Flutter 漏れ (Worker にあるが Flutter から呼出無し)

- `/auth/integrity/decode-test`
- `/auth/integrity/diagnose`
- `/protected/astro/consultation`
- `/protected/astro/line-narrative`
- `/public/astro/predict`
- `/public/health`
- `/public/tiles/osm/*`
- `/webhooks/*`
- `/webhooks/revenuecat`

### Flutter → Worker 漏れ (Flutter が呼ぶが Worker に定義無し)

> 注意: Flutter リテラルにテンプレ展開 `${var}` を含むものは検出精度低。

- (該当なし)

### 一致 (= 健全)

- `/auth/*`
- `/auth/attest`
- `/auth/challenge`
- `/auth/integrity/challenge`
- `/auth/whoami`
- `/protected/*`
- `/protected/account/delete`
- `/protected/astro/consultation2`
- `/protected/consultation/credits`
- `/protected/fortune`
- `/protected/relocation`
- `/protected/report-ai-output`
- `/protected/tarot`
- `/public/*`
- `/public/astro/chart`
- `/public/astro/daily-transits`
- `/public/astro/events`
- `/public/astro/forecast`
- `/public/search`
- `/public/tiles/*`
- `/public/tz`

## #1 / #2 機械抽出 ↔ feature_inventory.md (人手版) の対整合

- 機械抽出した class/mixin/extension/enum: **439**
- inventory に登場する識別子 (大文字始まり ``backtick``囲み): **235**

### #1 機械にあるが Doc に書かれていない (255)

- `AiConsentScreen`
- `AiDisclaimerFooter`
- `AiReportApi`
- `AiReportButton`
- `AppAttestClient`
- `ConstellationShareCardPage`
- `ConsultEntryPopup`
- `ConsultationEvidenceKm`
- `ConsultationHistoryScreen`
- `ConsultationInputScreen`
- `ConsultationPlacePickerScreen`
- `ConsultationPoint`
- `ConsultationPresetTarget`
- `ConsultationRecord`
- `ConsultationResultScreen`
- `ConsultationScope`
- `ConsultationTimeWindowItem`
- `ConsultationWhen`
- `DeviceSecurityStatus`
- `GalaxyArchiveFilter`
- `GalaxyArchiveFilterBar`
- `GalaxyArchiveSort`
- `GalaxyArchiveSortLabel`
- `LegalUrls`
- `MapTimeSliderState`
- `MemoTextField`
- `ObserveFullReadingButton`
- `ObserveHistoryFilter`
- `ObserveHistoryFilterBar`
- `ObserveHistoryPastPanel`
- `PaywallScreen`
- `ProStatus`
- `PurchasesService`
- `ReverseGeocodeResult`
- `SanctuaryAccountSection`
- `SolaraAuth`
- `SolaraAuthAccount`
- `SolaraAuthException`
- `SolaraAuthProvider`
- `TapToUnfocus`
- `TitleHistoryScreen`
- `_AboutReadingContent`
- `_ActionTile`
- `_AggBuilder`
- `_AiReportSheet`
- `_AiReportSheetState`
- `_AltarLayout`
- `_AltitudeBadge`
- `_AngleStyle`
- `_AntiqueIconPainter`
- `_AspectPass`
- `_AtlasHeader`
- `_CandidateCard`
- `_CandidateKindBadge`
- `_CatChip`
- `_CatasterismOverlayState`
- `_CategoryIconKindAsset`
- `_CategoryTipsBox`
- `_ChainConnector`
- `_CheckmarkPainter`
- `_Chip`
- `_ChipBody`
- `_ChipBtn`
- `_ChipButton`
- `_ChipColumn`
- `_ChipHalo`
- `_ClassShareCardPageState`
- `_CommunicationPainter`
- `_ConstellationCard`
- `_ConsultEntryPopupState`
- `_ConsultationBlockedBox`
- `_ConsultationHistoryScreenState`
- `_ConsultationInputLogic`
- `_ConsultationInputScreenState`
- `_ConsultationResultScreenState`
- `_ConsultationResultShare`
- `_ContribRow`
- `_CreditSheet`
- `_CreditSheetState`
- `_CycleActionsSheet`
- `_DailyTransitChip`
- `_DateNumberField`
- `_DateNumberFieldState`
- `_DayStepperButton`
- `_DayTab`
- `_DayTabBar`
- `_DominantFortuneOverlayState`
- `_ElementChipBtn`
- `_EmptyState`
- `_EnergyBar`
- `_EnergyChip`
- `_ErrorBox`
- `_ExampleChips`
- `_FailedBody`
- `_FallbackChip`
- `_FilterChip`
- `_FontOption`
- `_FontPreviewScreenState`
- `_Footer`
- `_FooterActions`
- `_FooterButton`
- `_ForecastScreenState`
- `_FormationPainter`
- `_FortuneRowsList`
- `_FortuneRowsListState`
- `_FramePill`
- `_FreeTextField`
- `_FullMoonOverlayState`
- `_GADot`
- `_GalaxyArchiveFilterBarState`
- `_GalaxyIconPainter`
- `_GalaxyStarAtlasTabState`
- `_Gear`
- `_GoldDust`
- `_GoldPalette`
- `_GoldPiece`
- `_Header`
- `_HealingPainter`
- `_Hero`
- `_HistoryCard`
- `_HoroBackdrop`
- `_HoroBirthPanelState`
- `_HoroBottomSheet`
- `_HoroChartData`
- `_HoroChartView`
- `_HoroIconPainter`
- `_HoroLocationInputState`
- `_HoroRelocationPanelState`
- `_HoroTransitPanelState`
- `_InfoPopupShell`
- `_LatitudeBandBox`
- `_LatitudeBandRow`
- `_LegalRow`
- `_LightMote`
- `_LoadingBody`
- `_LoadingSkeleton`
- `_LocationChip`
- `_LocationPickerMinimapState`
- `_LocationsScreenState`
- `_LovePainter`
- `_MainTab`
- `_MapDailyTransitScreenState`
- `_MapDisplayMenuState`
- `_MapIconPainter`
- `_MapLineNarrativeSheetState`
- `_MapViewpointMenuState`
- `_MedalPalette`
- `_Medallion`
- `_MemoTextFieldState`
- `_MenuInfoRow`
- `_MetaChip`
- `_ModeChoice`
- `_ModeRow`
- `_MoneyPainter`
- `_MoonScrollingStoryState`
- `_Mulberry32`
- `_NearestLineRow`
- `_NewMoonOverlayState`
- `_NoHomeNote`
- `_NoMatchState`
- `_Note`
- `_NotePair`
- `_NumberedPin`
- `_ObserveCategorySelector`
- `_ObserveHistoryFilterBarState`
- `_ObserveHistoryPanelState`
- `_ObserveHistoryPastPanelState`
- `_ObserveScreenState`
- `_OrbSectionLabel`
- `_PageIndicator`
- `_ParagraphSection`
- `_PaywallScreenState`
- `_PaywallWidgets`
- `_Petal`
- `_PetalPalette`
- `_PickedSpecific`
- `_PillChip`
- `_PlanetDef`
- `_PlanetGlyphPainter`
- `_PlanetIntroBody`
- `_PlanetSub`
- `_PopupBody`
- `_PresetLocationCard`
- `_QuestionFieldWidgets`
- `_RadiusChips`
- `_RankedLine`
- `_RarityChip`
- `_RarityStarRow`
- `_Ray`
- `_ReadingSheet`
- `_ReasonTile`
- `_RefreshButton`
- `_RegionPicker`
- `_RelocationProTeaser`
- `_ReportReason`
- `_RosePetal`
- `_SanctuaryAccountSectionState`
- `_SanctuaryHomeEditorPageState`
- `_SanctuaryIconPainter`
- `_SanctuaryOrbOverlayState`
- … 残り 55 省略

### #2 Doc に書いてあるがコードに存在しない (ゴースト記述) (51)

> 注: Flutter SDK や外部ライブラリの型もここに乗る (誤検出)。
> 真のゴーストはアプリ独自型のみ。実際の Doc 修正対象は手で絞り込む。

- `ACACAC`
- `ACTIVE_EVENT_TYPES`
- `APPLE_SIWA_KEY_ID`
- `APPLE_SIWA_PRIVATE_KEY`
- `APPLE_SIWA_SERVICE_ID`
- `AnimationController`
- `BottomNavigationBar`
- `C8D4E8`
- `CHART_STYLE`
- `CONSULTATION_CREDIT_PRODUCTS`
- `CONSULTATION_FREE_MODES`
- `CONSULTATION_FREE_WEEKLY`
- `CONSULTATION_PRO_WEEKLY`
- `CategoryFilterTips`
- `ConsultationCreditEvents`
- `ConsultationReading`
- `CustomPaint`
- `D6915C`
- `DELETE`
- `EAEAEA`
- `F6BD60`
- `F9D976`
- `FORECAST_KV`
- `FlutterMap`
- `Front`
- `GEMINI_API_KEY`
- `GOOGLE_PLACES_KEY`
- `GlobalKey`
- `HoroInfoRow`
- `IgnorePointer`
- `ListView`
- `MaterialApp`
- `NON_RENEWING_PURCHASE`
- `NOUN_SHAPES`
- `PATH_OVERRIDES`
- `REVENUECAT_SECRET_KEY`
- `RawScrollbar`
- `RepaintBoundary`
- `SUBSCRIPTION_EXTENDED`
- `ScrollController`
- `SearchHourAngle`
- `SearchRiseSet`
- `SolaraSafeText`
- `SpiralPainter`
- `StatefulWidget`
- `TAROT_MODEL_FALLBACK`
- `TAROT_MODEL_PRIMARY`
- `ThemeData`
- `TickerMode`
- `Timer`
- `ValueListenableBuilder`

## #4 画面 ↔ 機能集合

### 層 4a: Map 画面

- ファイル数: 23
- Worker URL 呼出: (なし)
- Popup/Dialog: `showInfoPopup`×14, `showLineNarrativeSheet`×3, `showSolaraDatePicker`×1
- Navigator.push 等: 0 箇所

### 層 4b: Horoscope 画面

- ファイル数: 23
- Worker URL 呼出: (なし)
- Popup/Dialog: `showInfoPopup`×2
- Navigator.push 等: 0 箇所

### 層 4c: Observe (Tarot) 画面

- ファイル数: 12
- Worker URL 呼出: (なし)
- Popup/Dialog: `showInfoPopup`×1
- Navigator.push 等: 0 箇所

### 層 4d: Galaxy 画面

- ファイル数: 10
- Worker URL 呼出: (なし)
- Popup/Dialog: `showInfoPopup`×1
- Navigator.push 等: 0 箇所

### 層 4e: Sanctuary 画面

- ファイル数: 10
- Worker URL 呼出: (なし)
- Popup/Dialog: `showInfoPopup`×4
- Navigator.push 等: 0 箇所

### 層 4f: サブ画面 (Forecast / Locations / Philosophy / Font Preview)

- ファイル数: 29
- Worker URL 呼出: (なし)
- Popup/Dialog: `showInfoPopup`×7
- Navigator.push 等: 0 箇所

## #5 import 依存グラフ (Pro 化影響範囲特定用)

> 正規表現ベースのため関数単位の call graph は作れない。
> 代わりに **ファイル単位の import 依存グラフ** を構築。
> 「あるファイルを変更したら誰が影響を受けるか」(= 逆依存) が分かれば
> Pro ゲート挿入の影響範囲は特定できる。

### #5a 層間依存マトリクス (行 = import する側、列 = される側)

| from\to | 1a | 1b | 1c | 2a | 2b | 2c | 3a | 3b | 3c | 4a | 4b | 4c | 4d | 4e | 4f | 5 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1a | 2 | · | · | 1 | 2 | · | · | · | · | · | · | · | · | · | · | · |
| 1b | · | · | · | 2 | 1 | · | 1 | · | · | · | · | · | · | · | · | · |
| 1c | · | · | 1 | · | · | · | · | · | · | · | · | · | · | · | · | · |
| 2a | 2 | 1 | · | 6 | 4 | · | · | 1 | · | · | · | · | · | · | · | · |
| 2b | 2 | 3 | 5 | 5 | 4 | · | · | · | · | · | · | · | · | · | · | · |
| 2c | · | · | 1 | 1 | · | · | · | · | · | · | · | · | · | · | · | · |
| 3a | 2 | 4 | 2 | 2 | 1 | 1 | 8 | 7 | 4 | 1 | · | · | · | · | 1 | · |
| 3b | · | · | · | · | · | · | · | 1 | · | · | · | · | · | · | · | · |
| 3c | · | 5 | 4 | 2 | 4 | · | 12 | 4 | · | · | · | · | · | · | · | · |
| 4a | 10 | 11 | · | 13 | 8 | · | 19 | 23 | 3 | 30 | 2 | · | · | · | 3 | · |
| 4b | 5 | 13 | · | 3 | 5 | · | 16 | · | · | · | 31 | · | · | 2 | · | · |
| 4c | 1 | 1 | 15 | 1 | 7 | 5 | 9 | 6 | · | · | · | 17 | · | · | 1 | · |
| 4d | 3 | 6 | 13 | 1 | 5 | 2 | 12 | 2 | 1 | · | · | · | 9 | · | · | · |
| 4e | 1 | 4 | · | 3 | 7 | 1 | 15 | 1 | · | · | · | · | · | 9 | 3 | · |
| 4f | 2 | 3 | · | 7 | 16 | 3 | 18 | 11 | · | 6 | · | · | · | · | 27 | · |
| 5 | 1 | · | · | 2 | 5 | 2 | 1 | 1 | · | 1 | 1 | 1 | 1 | 1 | 1 | · |

> 健全な依存方向は「番号が大きい層 → 小さい層」(上位が下位に依存)。
> 番号が小さい層から大きい層への矢印 (左下三角) は逆流依存の疑い。

### #5b ハブファイル Top 20 (逆依存が多い = 変更影響大)

> これらを Pro ゲート化・改修するときは影響範囲が広い。慎重に。

| ファイル | 層 | 被 import 数 |
| --- | --- | --- |
| `lib/theme/solara_colors.dart` | 3b | 36 |
| `lib/utils/solara_storage.dart` | 2b | 31 |
| `lib/widgets/info_popup.dart` | 3a | 24 |
| `lib/screens/map/map_constants.dart` | 3b | 20 |
| `lib/utils/pro_status.dart` | 2b | 19 |
| `lib/utils/solara_api.dart` | 2a | 15 |
| `lib/models/galaxy_cycle.dart` | 1c | 14 |
| `lib/screens/horoscope/horo_antique_icons.dart` | 3a | 14 |
| `lib/models/daily_reading.dart` | 1c | 12 |
| `lib/widgets/pro_unlock_dialog.dart` | 3a | 12 |
| `lib/widgets/tap_to_unfocus.dart` | 3a | 11 |
| `lib/screens/horoscope/horo_constants.dart` | 1b | 10 |
| `lib/screens/horoscope/horo_panel_shared.dart` | 4b | 9 |
| `lib/models/tarot_card.dart` | 1c | 8 |
| `lib/utils/constellation_namer.dart` | 1b | 8 |
| `lib/utils/tarot_data.dart` | 2c | 8 |
| `lib/models/lunar_intention.dart` | 1c | 7 |
| `lib/screens/map/map_vp_panel.dart` | 4a | 7 |
| `lib/widgets/glass_panel.dart` | 3a | 7 |
| `lib/screens/observe/observe_constants.dart` | 4c | 6 |

### #5c 孤立ファイル (2) — 誰からも import されない

> `lib/main.dart` (エントリ点) は除外済。残りは「画面のトップ」か
> 「死蔵コード候補」。後者なら削除候補。

- `lib/screens/font_preview_screen.dart` (層 4f)
- `lib/screens/solara_philosophy_screen.dart` (層 4f)

## #6 ハッシュ stamp — 前回 extract.py 実行からの変更ファイル

> 各ソースの SHA1 を `_stamps.json` に記録し、差分を検出。
> 変更されたファイルが属する層は、人手版インベントリ章の見直し対象。

- 追加: **5** / 削除: **0** / 変更: **15**

### 変更されたファイル (層別)

- **層 0**: `worker/src/consultation_v2.js`, `worker/src/fortune.js`, `worker/src/index.js`
- **層 2a**: `lib/utils/legal_urls.dart`, `lib/utils/solara_api.dart`
- **層 2b**: `lib/utils/solara_storage.dart`
- **層 3a**: `lib/widgets/location_picker_minimap.dart`
- **層 4a**: `lib/screens/map/map_styles.dart`, `lib/screens/map_screen.dart`
- **層 4b**: `lib/screens/horoscope/horo_fortune_cards.dart`
- **層 4c**: `lib/screens/observe_screen.dart`
- **層 4f**: `lib/screens/consultation/consultation_place_picker_screen.dart`, `lib/screens/consultation/consultation_result_card.dart`, `lib/screens/consultation/consultation_result_screen.dart`
- **層 5**: `lib/main.dart`

### 追加されたファイル

- `lib/screens/ai_consent_screen.dart` (層 4f)
- `lib/utils/ai_report_api.dart` (層 1a)
- `lib/widgets/ai_disclaimer_footer.dart` (層 3a)
- `lib/widgets/ai_report_button.dart` (層 3a)
- `worker/src/ai_report.js` (層 0)

## #7 astro_glossary 用語辞書対整合

> `astro_glossary.dart` の定義キー ↔ コード内の参照 (`termKey:` /
> `astroGlossary[...]`) を突合。死蔵エントリと壊れた用語ラベルを検出。

- 定義キー数: **46** / 参照キー数 (リテラルのみ): **10**

> ⚠️ 検出できるのは **リテラル参照のみ** (`termKey: 'asc'` / `astroGlossary['asc']`)。
> 次のケースは検出不可なので #7a を「確定した死蔵」と即断しないこと:
>  - `map_line_narrative_sheet.dart` の `_glossaryKey` getter (動的計算)
>  - `AstroTermLabel(termKey: someVariable)` のような変数渡し
> #7a は **死蔵候補** であり、削除前に grep で変数経由参照を確認すること。

### #7a 定義済みだが未参照 (36) — 死蔵 glossary エントリ候補

> 上記⚠️の通り、変数経由参照は検出できていない。確定前に要 grep。

- `altitude_event`
- `aspect_lines_full`
- `aspect_sextile`
- `aspect_square`
- `aspect_trine`
- `category_tips_intent`
- `dsc`
- `fortune_all`
- `fortune_communication`
- `fortune_healing`
- `fortune_love`
- `fortune_money`
- `fortune_work`
- `house_1`
- `house_10`
- `house_11`
- `house_12`
- `house_2`
- `house_3`
- `house_4`
- `house_5`
- `house_6`
- `house_7`
- `house_8`
- `house_9`
- `ic`
- `latitude_band_now`
- `mc`
- `placidus`
- `planet_lines`
- `relocate_layer`
- `relocation`
- `sector_score_16`
- `top_category_logic`
- `transit_angles`
- `two_energies`

### #7b 参照されているが未定義 (0) — 壊れた用語ラベル

- (該当なし)
