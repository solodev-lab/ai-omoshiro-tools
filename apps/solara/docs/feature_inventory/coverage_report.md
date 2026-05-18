# Solara feature inventory — Coverage Report

> 機械抽出 ↔ ドキュメント / Worker ↔ Flutter の対整合チェック結果。
> このファイルは extract.py が再生成する。手で編集しないこと。

## #3 Worker ↔ Flutter エンドポイント対整合

- Worker 側に定義された path: **20**
- Flutter から呼ばれている path リテラル: **13**

### Worker → Flutter 漏れ (Worker にあるが Flutter から呼出無し)

- `/protected/astro/line-narrative`
- `/public/astro/predict`
- `/public/health`
- `/public/tiles/osm/*`

### Flutter → Worker 漏れ (Flutter が呼ぶが Worker に定義無し)

> 注意: Flutter リテラルにテンプレ展開 `${var}` を含むものは検出精度低。

- (該当なし)

### 一致 (= 健全)

- `/auth/*`
- `/auth/attest`
- `/auth/whoami`
- `/protected/*`
- `/protected/astro/consultation`
- `/protected/fortune`
- `/protected/relocation`
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

- 機械抽出した class/mixin/extension/enum: **400**
- inventory に登場する識別子 (大文字始まり ``backtick``囲み): **209**

### #1 機械にあるが Doc に書かれていない (228)

- `CandidateLocation`
- `CandidateNearLine`
- `CityEntry`
- `ConstellationShareCardPage`
- `ConsultEntryPopup`
- `ConsultationCandidateReading`
- `ConsultationHistoryScreen`
- `ConsultationInputScreen`
- `ConsultationMode`
- `ConsultationPlacePickerScreen`
- `ConsultationPresetTarget`
- `ConsultationReading`
- `ConsultationRecord`
- `ConsultationResultScreen`
- `ConsultationScope`
- `DeviceSecurityStatus`
- `GalaxyArchiveFilter`
- `GalaxyArchiveFilterBar`
- `GalaxyArchiveSort`
- `GalaxyArchiveSortLabel`
- `LegalUrls`
- `MapTimeSliderState`
- `ObserveHistoryFilter`
- `ObserveHistoryFilterBar`
- `PaywallScreen`
- `ProStatus`
- `PurchasesService`
- `ReverseGeocodeResult`
- `SanctuaryAccountSection`
- `SolaraAuth`
- `SolaraAuthAccount`
- `SolaraAuthException`
- `SolaraAuthProvider`
- `TitleHistoryScreen`
- `_ActionTile`
- `_AggBuilder`
- `_AltarLayout`
- `_AltitudeBadge`
- `_AngleStyle`
- `_AntiqueIconPainter`
- `_AspectPass`
- `_AtlasHeader`
- `_BearingDef`
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
- `_ConsultExamples`
- `_ConsultationHistoryScreenState`
- `_ConsultationInputScreenState`
- `_ConsultationResultScreenState`
- `_ContribRow`
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
- `_ExampleRow`
- `_FailedBody`
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
- `_HoroRelocationPanelState`
- `_HoroTransitPanelState`
- `_HourNumberField`
- `_HourNumberFieldState`
- `_InfoPopupShell`
- `_IntroBlock`
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
- `_MenuInfoRow`
- `_MetaChip`
- `_ModeChoice`
- `_ModeRow`
- `_MoneyPainter`
- `_MoonScrollingStoryState`
- `_Mulberry32`
- `_NearestLineRow`
- `_NewMoonOverlayState`
- `_NoMatchState`
- `_Note`
- `_NotePair`
- `_NumberedPin`
- `_ObserveHistoryFilterBarState`
- `_ObserveHistoryPanelState`
- `_ObserveScreenState`
- `_OrbSectionLabel`
- `_OutroBlock`
- `_PageIndicator`
- `_PaywallScreenState`
- `_PaywallWidgets`
- `_Petal`
- `_PetalPalette`
- `_PickedSpecific`
- `_PlanetDef`
- `_PlanetGlyphPainter`
- `_PlanetIntroBody`
- `_PlanetSub`
- `_PopupBody`
- `_PresetLocationCard`
- `_QuestionFieldWidgets`
- `_RankedLine`
- `_RarityChip`
- `_RarityStarRow`
- `_Ray`
- `_RefreshButton`
- `_RegionPicker`
- `_RelocationProTeaser`
- `_RosePetal`
- `_SanctuaryAccountSectionState`
- `_SanctuaryHomeEditorPageState`
- `_SanctuaryIconPainter`
- `_SanctuaryOrbOverlayState`
- `_SanctuaryProfileEditorPageState`
- `_SanctuaryResetHourPickerState`
- `_SanctuaryScreenState`
- `_SanctuaryTitleDiagnosisPageState`
- `_ScopeChoice`
- `_ScopeRow`
- `_ScoredBearing`
- `_ScoredCity`
- `_ScrollableRowPanel`
- `_SearchBar`
- `_SearchBarOverlayState`
- `_SearchHitRow`
- `_Section`
- `_SectionCard`
- `_SelectedRarityBanner`
- `_SelectedSpecificCard`
- `_SelectionCard`
- `_Sentinel`
- `_SettingsGroup`
- `_SettingsItem`
- `_SettingsItemWithToggle`
- `_ShareCardRarityStars`
- … 残り 28 省略

### #2 Doc に書いてあるがコードに存在しない (ゴースト記述) (37)

> 注: Flutter SDK や外部ライブラリの型もここに乗る (誤検出)。
> 真のゴーストはアプリ独自型のみ。実際の Doc 修正対象は手で絞り込む。

- `ACACAC`
- `AnimationController`
- `BottomNavigationBar`
- `C8D4E8`
- `CHART_STYLE`
- `CategoryFilterTips`
- `CustomPaint`
- `D6915C`
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
- `NOUN_SHAPES`
- `PATH_OVERRIDES`
- `RawScrollbar`
- `RepaintBoundary`
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

- ファイル数: 22
- Worker URL 呼出: (なし)
- Popup/Dialog: `showInfoPopup`×2
- Navigator.push 等: 0 箇所

### 層 4c: Observe (Tarot) 画面

- ファイル数: 7
- Worker URL 呼出: (なし)
- Popup/Dialog: (なし)
- Navigator.push 等: 0 箇所

### 層 4d: Galaxy 画面

- ファイル数: 9
- Worker URL 呼出: (なし)
- Popup/Dialog: `showInfoPopup`×1
- Navigator.push 等: 0 箇所

### 層 4e: Sanctuary 画面

- ファイル数: 10
- Worker URL 呼出: (なし)
- Popup/Dialog: `showInfoPopup`×4
- Navigator.push 等: 0 箇所

### 層 4f: サブ画面 (Forecast / Locations / Philosophy / Font Preview)

- ファイル数: 18
- Worker URL 呼出: (なし)
- Popup/Dialog: `showInfoPopup`×5
- Navigator.push 等: 0 箇所

## #5 import 依存グラフ (Pro 化影響範囲特定用)

> 正規表現ベースのため関数単位の call graph は作れない。
> 代わりに **ファイル単位の import 依存グラフ** を構築。
> 「あるファイルを変更したら誰が影響を受けるか」(= 逆依存) が分かれば
> Pro ゲート挿入の影響範囲は特定できる。

### #5a 層間依存マトリクス (行 = import する側、列 = される側)

| from\to | 1a | 1b | 1c | 2a | 2b | 2c | 3a | 3b | 3c | 4a | 4b | 4c | 4d | 4e | 4f | 5 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1a | 3 | 1 | · | · | 1 | · | · | · | · | · | · | · | · | · | · | · |
| 1b | 1 | · | · | 1 | · | · | 1 | · | · | · | · | · | · | · | · | · |
| 1c | · | · | 1 | · | · | · | · | · | · | · | · | · | · | · | · | · |
| 2a | 3 | · | · | 5 | · | · | · | 1 | · | · | · | · | · | · | · | · |
| 2b | 1 | 1 | 5 | 3 | 1 | · | · | · | · | · | · | · | · | · | · | · |
| 2c | · | · | 1 | · | · | · | · | · | · | · | · | · | · | · | · | · |
| 3a | 1 | 4 | 2 | 2 | 1 | 1 | 8 | 6 | 4 | 1 | · | · | · | · | 1 | · |
| 3b | · | · | · | · | · | · | · | 1 | · | · | · | · | · | · | · | · |
| 3c | · | 5 | 4 | 2 | 4 | · | 12 | 4 | · | · | · | · | · | · | · | · |
| 4a | 10 | 11 | · | 13 | 7 | · | 18 | 23 | 3 | 31 | 2 | · | · | · | 3 | · |
| 4b | 5 | 10 | · | 6 | 4 | · | 13 | · | · | · | 29 | · | · | 2 | · | · |
| 4c | 1 | · | 7 | 1 | 5 | 3 | 2 | · | · | · | · | 9 | · | · | · | · |
| 4d | 2 | 6 | 13 | 1 | 5 | 2 | 11 | 2 | 1 | · | · | · | 8 | · | · | · |
| 4e | 1 | 4 | · | 2 | 7 | · | 9 | 1 | · | · | · | · | · | 9 | 2 | · |
| 4f | 4 | 4 | · | 4 | 11 | · | 11 | 10 | · | 6 | · | · | · | · | 13 | · |
| 5 | 1 | · | · | 2 | 3 | 1 | 1 | 1 | · | 1 | 1 | 1 | 1 | 1 | · | · |

> 健全な依存方向は「番号が大きい層 → 小さい層」(上位が下位に依存)。
> 番号が小さい層から大きい層への矢印 (左下三角) は逆流依存の疑い。

### #5b ハブファイル Top 20 (逆依存が多い = 変更影響大)

> これらを Pro ゲート化・改修するときは影響範囲が広い。慎重に。

| ファイル | 層 | 被 import 数 |
| --- | --- | --- |
| `lib/theme/solara_colors.dart` | 3b | 28 |
| `lib/utils/solara_storage.dart` | 2b | 23 |
| `lib/widgets/info_popup.dart` | 3a | 21 |
| `lib/screens/map/map_constants.dart` | 3b | 20 |
| `lib/utils/pro_status.dart` | 2b | 17 |
| `lib/screens/horoscope/horo_antique_icons.dart` | 3a | 13 |
| `lib/models/galaxy_cycle.dart` | 1c | 12 |
| `lib/utils/solara_api.dart` | 2a | 11 |
| `lib/widgets/pro_unlock_dialog.dart` | 3a | 11 |
| `lib/screens/horoscope/horo_constants.dart` | 1b | 10 |
| `lib/models/daily_reading.dart` | 1c | 9 |
| `lib/screens/horoscope/horo_panel_shared.dart` | 4b | 9 |
| `lib/utils/astro_lines.dart` | 1a | 8 |
| `lib/utils/constellation_namer.dart` | 1b | 8 |
| `lib/models/lunar_intention.dart` | 1c | 7 |
| `lib/screens/map/map_vp_panel.dart` | 4a | 7 |
| `lib/utils/tarot_data.dart` | 2c | 7 |
| `lib/widgets/glass_panel.dart` | 3a | 7 |
| `lib/utils/astro_glossary.dart` | 1b | 6 |
| `lib/utils/title_data.dart` | 1b | 6 |

### #5c 孤立ファイル (2) — 誰からも import されない

> `lib/main.dart` (エントリ点) は除外済。残りは「画面のトップ」か
> 「死蔵コード候補」。後者なら削除候補。

- `lib/screens/font_preview_screen.dart` (層 4f)
- `lib/screens/solara_philosophy_screen.dart` (層 4f)

## #6 ハッシュ stamp — 前回 extract.py 実行からの変更ファイル

> 各ソースの SHA1 を `_stamps.json` に記録し、差分を検出。
> 変更されたファイルが属する層は、人手版インベントリ章の見直し対象。

- 追加: **0** / 削除: **0** / 変更: **3**

### 変更されたファイル (層別)

- **層 2a**: `lib/utils/legal_urls.dart`
- **層 4b**: `lib/screens/horoscope/horo_birth_panel.dart`
- **層 4e**: `lib/screens/sanctuary/sanctuary_profile_editor.dart`

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
