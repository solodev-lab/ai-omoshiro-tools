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
- inventory に登場する識別子 (大文字始まり ``backtick``囲み): **19**

### #1 機械にあるが Doc に書かれていない (292)

- `AcgFrameDef`
- `AngleFilter`
- `AntiqueGlyph`
- `AntiqueIcon`
- `AppLocale`
- `AstroCartoBanner`
- `AstroCartoCategoryPills`
- `AstroCartoFramePills`
- `AstroCartoSubPills`
- `AstroFrameStyle`
- `AstroNadirMarker`
- `AstroTermLabel`
- `AstroZenithMarker`
- `AstroZenithPopup`
- `BirthMarker`
- `CatasterismFormationOverlay`
- `CatasterismOverlay`
- `CatasterismResult`
- `CategoryIcon`
- `CategoryIconKind`
- `CelestialEvent`
- `CelestialEventBar`
- `CelestialEvents`
- `ChartLineStyle`
- `ChartResult`
- `ClassCard`
- `ClassCardMode`
- `ClassShareCardPage`
- `CommunicationPainterBuilder`
- `ConstellationDot`
- `ConstellationNamer`
- `ConstellationPainter`
- `CycleSpiralPainter`
- `CycleStoryTexts`
- `DailyReading`
- `DailyTransitsResult`
- `DateSlashFormatter`
- `DominantFortuneKind`
- `DominantFortuneKindToCategoryIcon`
- `DominantFortuneOverlay`
- `FontPreviewScreen`
- `ForecastCache`
- `ForecastDay`
- `ForecastLifePeriodsSection`
- `ForecastRepo`
- `ForecastScreen`
- `ForecastTop5Section`
- `FortuneFilterLabel`
- `FortunePainterBuilder`
- `FortuneReading`
- `FortuneSheet`
- `FullMoonOverlay`
- `GalaxyCycle`
- `GalaxyReplayOverlay`
- `GalaxyScreen`
- `GalaxyScreenState`
- `GalaxyStarAtlasTab`
- `GlassPanel`
- `HealingPainterBuilder`
- `HoroAspectCheckmark`
- `HoroAspectList`
- `HoroAstrologyView`
- `HoroBirthPanel`
- `HoroChartWheelPainter`
- `HoroDescSection`
- `HoroFilterPanel`
- `HoroHourMinuteDropdown`
- `HoroInfoRow`
- `HoroLegendItem`
- `HoroOrnamentPainter`
- `HoroPlanetTable`
- `HoroPredictionPanel`
- `HoroRelocationPanel`
- `HoroTransitPanel`
- `HoroscopeScreen`
- `HoroscopeScreenState`
- `HouseShift`
- `LatitudeBand`
- `LatitudeBandHit`
- `LegendDot`
- `LifePeriod`
- `LocationMarkerPopup`
- `LocationPickerMinimap`
- `LocationsDateStepper`
- `LocationsScreen`
- `LovePainterBuilder`
- `LunarIntention`
- `MapAspectChip`
- `MapBtn`
- `MapDailyTransitScreen`
- `MapDisplayMenu`
- `MapLineNarrativeSheet`
- `MapMenuChips`
- `MapRelocationPopup`
- `MapScreen`
- `MapScreenState`
- `MapSideButtons`
- `MapStyle`
- `MapStyleConfig`
- `MapTimeSlider`
- `MapTimeSliderState`
- `MapViewpointMenu`
- `MidpointCheck`
- `MiniConstellationPainter`
- `MoneyPainterBuilder`
- `MonthEvents`
- `MoonScrollingStory`
- `NewMoonOverlay`
- `NoProfileGuide`
- `Observe3DCard`
- `ObserveCardBack`
- `ObserveCardFront`
- `ObserveCardInfo`
- `ObserveHistoryPanel`
- `ObserveScreen`
- `PlanetDailyTransits`
- `PlanetLineData`
- `PlanetMeta`
- `PlanetSymbolsLayer`
- `PlanetVectorIcon`
- `RelocationNarrative`
- `RestOverlay`
- `SanctuaryHomeEditorPage`
- `SanctuaryOrbOverlay`
- `SanctuaryProfileEditorPage`
- `SanctuaryResetHourPicker`
- `SanctuaryScreen`
- `SanctuaryTitleDiagnosisPage`
- `ScoreResult`
- `SearchBarOverlay`
- `SearchFocusPopup`
- `SearchHit`
- `SearchResultList`
- `SearchVpChipRow`
- `SelectedDateBadge`
- `SlotManager`
- `SlotMarker`
- `SolaraApp`
- `SolaraColors`
- `SolaraHome`
- `SolaraManifesto`
- `SolaraManifestoSection`
- `SolaraNavBar`
- `SolaraNavIcons`
- `SolaraPhilosophyScreen`
- `SolaraProfile`
- `SolaraSafeText`
- `SolaraStorage`
- `SolaraTheme`
- `SpiralPainter`
- `StatusBadge`
- `TarotAltarScene`
- `TarotCard`
- `TarotData`
- `TarotReading`
- `TitleClass`
- `TitleHowItWorksContent`
- `TransitAspect`
- `TransitEvent`
- `VPSlot`
- `VpPinVisual`
- `WorkPainterBuilder`
- `ZenithMessage`
- `ZodiacImageIcon`
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
- … 残り 92 省略

### #2 Doc に書いてあるがコードに存在しない (ゴースト記述) (7)

> 注: Flutter SDK や外部ライブラリの型もここに乗る (誤検出)。
> 真のゴーストはアプリ独自型のみ。実際の Doc 修正対象は手で絞り込む。

- `FORECAST_KV`
- `GEMINI_API_KEY`
- `GOOGLE_PLACES_KEY`
- `SearchHourAngle`
- `SearchRiseSet`
- `TAROT_MODEL_FALLBACK`
- `TAROT_MODEL_PRIMARY`

## #4 画面 ↔ 機能集合

### 層 4a: Map 画面

- ファイル数: 25
- Worker URL 呼出: ['/astro/chart', '/search', '/tiles/osm/hot/', '/tiles/osm/hot/0/0/0']
- Popup/Dialog: `showInfoPopup`×14, `showLineNarrativeSheet`×3, `showSolaraDatePicker`×1
- Navigator.push 等: 0 箇所

### 層 4b: Horoscope 画面

- ファイル数: 25
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
