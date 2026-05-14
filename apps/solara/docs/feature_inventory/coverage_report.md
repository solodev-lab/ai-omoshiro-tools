# Solara feature inventory — Coverage Report

> 機械抽出 ↔ ドキュメント / Worker ↔ Flutter の対整合チェック結果。
> このファイルは extract.py が再生成する。手で編集しないこと。

## #3 Worker ↔ Flutter エンドポイント対整合

- Worker 側に定義された path: **14**
- Flutter から呼ばれている path リテラル: **11**

### Worker → Flutter 漏れ (Worker にあるが Flutter から呼出無し)

- `/astro/line-narrative`
- `/astro/predict`
- `/health`

### Flutter → Worker 漏れ (Flutter が呼ぶが Worker に定義無し)

> 注意: Flutter リテラルにテンプレ展開 `${var}` を含むものは検出精度低。

- (該当なし)

### 一致 (= 健全)

- `/astro/chart`
- `/astro/daily-transits`
- `/astro/events`
- `/astro/forecast`
- `/fortune`
- `/relocation`
- `/search`
- `/tarot`
- `/tiles/*`
- `/tiles/osm/*`
- `/tz`

## #1 / #2 機械抽出 ↔ feature_inventory.md (人手版) の対整合

- 機械抽出した class/mixin/extension/enum: **304**
- inventory に登場する識別子 (大文字始まり ``backtick``囲み): **196**

### #1 機械にあるが Doc に書かれていない (142)

- `DailyTransitsResult`
- `FortuneReading`
- `LatitudeBand`
- `LatitudeBandHit`
- `MapTimeSliderState`
- `MonthEvents`
- `PlanetDailyTransits`
- `RelocationNarrative`
- `SolaraNavIcons`
- `SolaraProfile`
- `SolaraTheme`
- `TarotReading`
- `TransitAspect`
- `TransitEvent`
- `_AcgEntryFooter`
- `_ActionTile`
- `_AggBuilder`
- `_AltarLayout`
- `_AltitudeBadge`
- `_AngleStyle`
- `_AntiqueIconPainter`
- `_AtlasHeader`
- `_CatChip`
- `_CatasterismOverlayState`
- `_CategoryIconKindAsset`
- `_CategoryTipsBox`
- `_CheckmarkPainter`
- `_Chip`
- `_ChipBody`
- `_ChipButton`
- `_ChipColumn`
- `_ChipHalo`
- `_ClassShareCardPageState`
- `_CommunicationPainter`
- `_ConstellationCard`
- `_ContribRow`
- `_DailyTransitChip`
- `_DateNumberField`
- `_DateNumberFieldState`
- `_DayStepperButton`
- `_DayTab`
- `_DayTabBar`
- `_DominantFortuneOverlayState`
- `_EmptyState`
- `_EnergyBar`
- `_FailedBody`
- `_FontOption`
- `_FontPreviewScreenState`
- `_Footer`
- `_ForecastScreenState`
- `_FormationPainter`
- `_FortuneRowsList`
- `_FortuneRowsListState`
- `_FramePill`
- `_FullMoonOverlayState`
- `_GADot`
- `_GalaxyIconPainter`
- `_Gear`
- `_GoldDust`
- `_GoldPalette`
- `_GoldPiece`
- `_Header`
- `_HealingPainter`
- `_Hero`
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
- `_LatitudeBandBox`
- `_LatitudeBandRow`
- `_LightMote`
- `_LoadingBody`
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
- `_MoneyPainter`
- `_MoonScrollingStoryState`
- `_Mulberry32`
- `_NewMoonOverlayState`
- `_Note`
- `_NotePair`
- `_ObserveHistoryPanelState`
- `_ObserveScreenState`
- `_OrbSectionLabel`
- `_Petal`
- `_PetalPalette`
- `_PlanetDef`
- `_PlanetGlyphPainter`
- `_PlanetIntroBody`
- `_PlanetSub`
- `_PopupBody`
- `_RankedLine`
- `_Ray`
- `_RosePetal`
- `_SanctuaryHomeEditorPageState`
- `_SanctuaryIconPainter`
- `_SanctuaryOrbOverlayState`
- `_SanctuaryProfileEditorPageState`
- `_SanctuaryResetHourPickerState`
- `_SanctuaryScreenState`
- `_SanctuaryTitleDiagnosisPageState`
- `_ScrollableRowPanel`
- `_SearchBarOverlayState`
- `_SectionCard`
- `_SettingsGroup`
- `_SettingsItem`
- `_SettingsItemWithToggle`
- `_SlotStats`
- `_SolaraHomeState`
- `_Spark`
- `_Sparkle`
- `_SpiralDot`
- `_SpreadItem`
- `_StaticChip`
- `_Stream`
- `_SubPill`
- `_SyncInput`
- `_SyncInputState`
- `_TarotAltarSceneState`
- `_TarotIconPainter`
- `_TimelineBody`
- `_TimelineRow`
- `_Vec3`
- `_Vine`
- `_WidgetOpacity`
- `_WorkPainter`

### #2 Doc に書いてあるがコードに存在しない (ゴースト記述) (34)

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
- `StatefulWidget`
- `TAROT_MODEL_FALLBACK`
- `TAROT_MODEL_PRIMARY`
- `ThemeData`
- `TickerMode`
- `Timer`
- `ValueListenableBuilder`

## #4 画面 ↔ 機能集合

### 層 4a: Map 画面

- ファイル数: 22
- Worker URL 呼出: ['/search', '/tiles/osm/hot/', '/tiles/osm/hot/0/0/0']
- Popup/Dialog: `showInfoPopup`×14, `showLineNarrativeSheet`×3, `showSolaraDatePicker`×1
- Navigator.push 等: 0 箇所

### 層 4b: Horoscope 画面

- ファイル数: 22
- Worker URL 呼出: (なし)
- Popup/Dialog: `showInfoPopup`×2
- Navigator.push 等: 0 箇所

### 層 4c: Observe (Tarot) 画面

- ファイル数: 5
- Worker URL 呼出: (なし)
- Popup/Dialog: (なし)
- Navigator.push 等: 0 箇所

### 層 4d: Galaxy 画面

- ファイル数: 5
- Worker URL 呼出: (なし)
- Popup/Dialog: `showInfoPopup`×1
- Navigator.push 等: 0 箇所

### 層 4e: Sanctuary 画面

- ファイル数: 8
- Worker URL 呼出: (なし)
- Popup/Dialog: `showInfoPopup`×3
- Navigator.push 等: 0 箇所

### 層 4f: サブ画面 (Forecast / Locations / Philosophy / Font Preview)

- ファイル数: 7
- Worker URL 呼出: (なし)
- Popup/Dialog: `showInfoPopup`×5
- Navigator.push 等: 0 箇所
