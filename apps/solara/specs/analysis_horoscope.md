# Horoscope（ホロスコープチャート） — 機能分析レポート

**ソース**: `mockup/horoscope.html`
**関数総数**: 86個
**エントリーポイント**: 72個
**到達可能な関数**: 86個
**到達不可能（未使用候補）**: 0個
**DOM操作の重複箇所**: 24箇所

---
## ⚠️ 同じ場所を操作する関数（重複候補）

> 同じDOM要素を複数の関数が操作している箇所。
> 古い方を削除するか、統合を検討してください。

### `#aspectInfo`

- **[✅ 実行中]** `renderAspectInfo()` (L2336)
  - 呼出元: renderChart
  - 操作: getById
- **[✅ 実行中]** `buildBSAspectsContent()` (L2735)
  - 呼出元: refreshActiveBS, switchBSTab
  - 操作: getById

### `#aspectsContainerTitle`

- **[✅ 実行中]** `renderAspectInfo()` (L2336)
  - 呼出元: renderChart
  - 操作: getById
- **[✅ 実行中]** `buildBSAspectsContent()` (L2735)
  - 呼出元: refreshActiveBS, switchBSTab
  - 操作: getById

### `#bottomSheet`

- **[✅ 実行中]** `setChartMode()` (L1670)
  - 呼出元: setChartModeMenu
  - 操作: getById
- **[✅ 実行中]** `initBottomSheet()` (L2469)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `setBSState()` (L2521)
  - 呼出元: initBottomSheet, switchBSTab
  - 操作: getById
- **[✅ 実行中]** `updateBSBodyHeight()` (L2546)
  - 呼出元: setBSState, initBottomSheet
  - 操作: getById

### `#bsBody`

- **[✅ 実行中]** `setBSState()` (L2521)
  - 呼出元: initBottomSheet, switchBSTab
  - 操作: getById
- **[✅ 実行中]** `updateBSBodyHeight()` (L2546)
  - 呼出元: setBSState, initBottomSheet
  - 操作: getById

### `#bsDragHandle`

- **[✅ 実行中]** `initBottomSheet()` (L2469)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `updateBSBodyHeight()` (L2546)
  - 呼出元: setBSState, initBottomSheet
  - 操作: getById

### `#bsTabs`

- **[✅ 実行中]** `setBSState()` (L2521)
  - 呼出元: initBottomSheet, switchBSTab
  - 操作: getById
- **[✅ 実行中]** `updateBSBodyHeight()` (L2546)
  - 呼出元: setBSState, initBottomSheet
  - 操作: getById

### `#chartMenuPanel`

- **[✅ 実行中]** `toggleChartMenu()` (L1643)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `setChartModeMenu()` (L1648)
  - 呼出元: なし
  - 操作: getById

### `#horoscopeChart`

- **[✅ 実行中]** `renderChart()` (L2008)
  - 呼出元: toggleExclusive, onTransitLocationChange, resetFilters, generateFromInput, applyBSTransit, toggleFilter
  - 操作: getById
- **[✅ 実行中]** `updateHouseSystemLabel()` (L2227)
  - 呼出元: renderChart
  - 操作: getById
- **[✅ 実行中]** `showZodiacName()` (L2413)
  - 呼出元: renderChart
  - 操作: getById

### `#inputDate`

- **[✅ 実行中]** `fillForm()` (L1634)
  - 呼出元: loadFortuneCacheOrGenerate
  - 操作: getById
- **[✅ 実行中]** `generateFromInput()` (L1961)
  - 呼出元: applyBSBirth
  - 操作: getById

### `#inputLat`

- **[✅ 実行中]** `fillForm()` (L1634)
  - 呼出元: loadFortuneCacheOrGenerate
  - 操作: getById
- **[✅ 実行中]** `onBirthPlaceChange()` (L1874)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `generateFromInput()` (L1961)
  - 呼出元: applyBSBirth
  - 操作: getById

### `#inputLng`

- **[✅ 実行中]** `fillForm()` (L1634)
  - 呼出元: loadFortuneCacheOrGenerate
  - 操作: getById
- **[✅ 実行中]** `onBirthPlaceChange()` (L1874)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `generateFromInput()` (L1961)
  - 呼出元: applyBSBirth
  - 操作: getById

### `#inputName`

- **[✅ 実行中]** `fillForm()` (L1634)
  - 呼出元: loadFortuneCacheOrGenerate
  - 操作: getById
- **[✅ 実行中]** `generateFromInput()` (L1961)
  - 呼出元: applyBSBirth
  - 操作: getById

### `#inputPlace`

- **[✅ 実行中]** `fillForm()` (L1634)
  - 呼出元: loadFortuneCacheOrGenerate
  - 操作: getById
- **[✅ 実行中]** `onBirthPlaceChange()` (L1874)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `generateFromInput()` (L1961)
  - 呼出元: applyBSBirth
  - 操作: getById

### `#inputTime`

- **[✅ 実行中]** `fillForm()` (L1634)
  - 呼出元: loadFortuneCacheOrGenerate
  - 操作: getById
- **[✅ 実行中]** `generateFromInput()` (L1961)
  - 呼出元: applyBSBirth
  - 操作: getById

### `#mTransitLocation`

- **[✅ 実行中]** `buildBSTransitContent()` (L2627)
  - 呼出元: initBottomSheet
  - 操作: getById
- **[✅ 実行中]** `onMobileTransitLocChange()` (L2674)
  - 呼出元: syncBSTransitForm, buildBSTransitContent
  - 操作: getById

### `#noProfileBanner`

- **[✅ 実行中]** `setChartMode()` (L1670)
  - 呼出元: setChartModeMenu
  - 操作: getById
- **[✅ 実行中]** `initTransitDefaults()` (L1936)
  - 呼出元: なし
  - 操作: getById

### `#planetTable`

- **[✅ 実行中]** `renderPlanetTable()` (L2251)
  - 呼出元: renderChart
  - 操作: getById
- **[✅ 実行中]** `buildBSPlanetsContent()` (L2705)
  - 呼出元: refreshActiveBS, switchBSTab
  - 操作: getById

### `#predictionPanel`

- **[✅ 実行中]** `renderChart()` (L2008)
  - 呼出元: toggleExclusive, onTransitLocationChange, resetFilters, generateFromInput, applyBSTransit, toggleFilter
  - 操作: getById
- **[✅ 実行中]** `renderPredictions()` (L2359)
  - 呼出元: renderChart
  - 操作: getById

### `#svgHouseLabel`

- **[✅ 実行中]** `renderChart()` (L2008)
  - 呼出元: toggleExclusive, onTransitLocationChange, resetFilters, generateFromInput, applyBSTransit, toggleFilter
  - 操作: getById
- **[✅ 実行中]** `updateHouseSystemLabel()` (L2227)
  - 呼出元: renderChart
  - 操作: getById

### `#transitDate`

- **[✅ 実行中]** `getTransitDateTime()` (L1913)
  - 呼出元: generateFromInput, renderChart
  - 操作: getById
- **[✅ 実行中]** `initTransitDefaults()` (L1936)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `renderChart()` (L2008)
  - 呼出元: toggleExclusive, onTransitLocationChange, resetFilters, generateFromInput, applyBSTransit, toggleFilter
  - 操作: getById

### `#transitLat`

- **[✅ 実行中]** `onTransitLocationChange()` (L1895)
  - 呼出元: applyBSTransit, initTransitDefaults
  - 操作: getById
- **[✅ 実行中]** `getTransitLocation()` (L1920)
  - 呼出元: renderChart
  - 操作: getById

### `#transitLng`

- **[✅ 実行中]** `onTransitLocationChange()` (L1895)
  - 呼出元: applyBSTransit, initTransitDefaults
  - 操作: getById
- **[✅ 実行中]** `getTransitLocation()` (L1920)
  - 呼出元: renderChart
  - 操作: getById

### `#transitLocation`

- **[✅ 実行中]** `onTransitLocationChange()` (L1895)
  - 呼出元: applyBSTransit, initTransitDefaults
  - 操作: getById
- **[✅ 実行中]** `getTransitLocation()` (L1920)
  - 呼出元: renderChart
  - 操作: getById
- **[✅ 実行中]** `initTransitDefaults()` (L1936)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `renderChart()` (L2008)
  - 呼出元: toggleExclusive, onTransitLocationChange, resetFilters, generateFromInput, applyBSTransit, toggleFilter
  - 操作: getById
- **[✅ 実行中]** `buildBSTransitContent()` (L2627)
  - 呼出元: initBottomSheet
  - 操作: getById

### `#transitTime`

- **[✅ 実行中]** `getTransitDateTime()` (L1913)
  - 呼出元: generateFromInput, renderChart
  - 操作: getById
- **[✅ 実行中]** `initTransitDefaults()` (L1936)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `renderChart()` (L2008)
  - 呼出元: toggleExclusive, onTransitLocationChange, resetFilters, generateFromInput, applyBSTransit, toggleFilter
  - 操作: getById

---
## ❌ 未使用関数（削除候補）

（全関数が到達可能 — 未使用なし）

---
## 🎯 エントリーポイント（操作の起点）

| 種類 | 関数 | 詳細 |
|------|------|------|
| HTML属性 | `toggleChartMenu()` | toggleChartMenu() |
| HTML属性 | `setChartModeMenu()` | setChartModeMenu( |
| HTML属性 | `setChartMode()` | setChartMode( |
| HTML属性 | `onBirthPlaceChange()` | onBirthPlaceChange() |
| HTML属性 | `generateFromInput()` | generateFromInput() |
| HTML属性 | `onTransitLocationChange()` | onTransitLocationChange() |
| HTML属性 | `renderChart()` | renderChart() |
| HTML属性 | `toggleAnalysis()` | toggleAnalysis() |
| HTML属性 | `resetFilters()` | resetFilters() |
| HTML属性 | `toggleFilter()` | toggleFilter(this) |
| HTML属性 | `toggleExclusive()` | toggleExclusive(this) |
| HTML属性 | `toggleAspects()` | toggleAspects() |
| HTML属性 | `setBSState()` | setBSState( |
| HTML属性 | `switchBSTab()` | switchBSTab( |
| HTML属性 | `showZodiacName()` | showZodiacName(evt, |
| HTML属性 | `toggleAspectVisibility()` | toggleAspectVisibility(\ |
| HTML属性 | `onMobileBirthPlaceChange()` | onMobileBirthPlaceChange() |
| HTML属性 | `applyBSBirth()` | applyBSBirth() |
| HTML属性 | `onMobileTransitLocChange()` | onMobileTransitLocChange() |
| HTML属性 | `applyBSTransit()` | applyBSTransit() |
| HTML属性 | `goFortune()` | goFortune( |
| HTML属性 | `fortunePrev()` | fortunePrev() |
| HTML属性 | `fortuneNext()` | fortuneNext() |
| トップレベル呼出 | `renderChart()` |  |
| トップレベル呼出 | `buildTodayView()` |  |
| トップレベル呼出 | `updateBSTransitTab()` |  |
| トップレベル呼出 | `resetFilters()` |  |
| トップレベル呼出 | `onTransitLocationChange()` |  |
| トップレベル呼出 | `refreshActiveBS()` |  |
| トップレベル呼出 | `redrawAspectLines()` |  |
| トップレベル呼出 | `updateBSBodyHeight()` |  |
| トップレベル呼出 | `buildBSBirthContent()` |  |
| トップレベル呼出 | `buildBSTransitContent()` |  |
| トップレベル呼出 | `generateFromInput()` |  |
| トップレベル呼出 | `onMobileTransitLocChange()` |  |
| トップレベル呼出 | `updateFortuneUI()` |  |
| トップレベル呼出 | `initTransitDefaults()` |  |
| トップレベル呼出 | `initBottomSheet()` |  |
| トップレベル呼出 | `loadFortuneCacheOrGenerate()` |  |
| トップレベル呼出 | `initFortuneSwipe()` |  |

---
## 📍 DOM要素と操作する関数の対応表

> 各DOM要素を「誰が」操作しているかの一覧。

- `#analysisBody` ← `toggleAnalysis()`
- `#analysisToggle` ← `toggleAnalysis()`
- `#aspectFilterPanel` ← `buildBSFilterContent()`
- `#aspectInfo` ← `renderAspectInfo()`, `buildBSAspectsContent()` ⚠️
- `#aspectLines` ← `redrawAspectLines()`
- `#aspectsBody` ← `toggleAspects()`
- `#aspectsContainerTitle` ← `renderAspectInfo()`, `buildBSAspectsContent()` ⚠️
- `#aspectsToggle` ← `toggleAspects()`
- `#astrologyCardsAll` ← `buildTodayView()`
- `#astrologyView` ← `setChartMode()`
- `#birthCustomLatLng` ← `onBirthPlaceChange()`
- `#bottomSheet` ← `setChartMode()`, `initBottomSheet()`, `setBSState()`, `updateBSBodyHeight()` ⚠️
- `#bsAspects` ← `buildBSAspectsContent()`
- `#bsBirth` ← `buildBSBirthContent()`
- `#bsBody` ← `setBSState()`, `updateBSBodyHeight()` ⚠️
- `#bsDragHandle` ← `initBottomSheet()`, `updateBSBodyHeight()` ⚠️
- `#bsFilter` ← `buildBSFilterContent()`
- `#bsFortune` ← `buildBSFortuneContent()`
- `#bsMiniLabel` ← `setBSState()`
- `#bsPlanets` ← `buildBSPlanetsContent()`
- `#bsTabs` ← `setBSState()`, `updateBSBodyHeight()` ⚠️
- `#bsTransit` ← `buildBSTransitContent()`
- `#bsTransitTab` ← `updateBSTransitTab()`
- `#chartLegend` ← `renderLegend()`
- `#chartMenuPanel` ← `toggleChartMenu()`, `setChartModeMenu()` ⚠️
- `#horoscopeChart` ← `renderChart()`, `updateHouseSystemLabel()`, `showZodiacName()` ⚠️
- `#inputDate` ← `fillForm()`, `generateFromInput()` ⚠️
- `#inputLat` ← `fillForm()`, `onBirthPlaceChange()`, `generateFromInput()` ⚠️
- `#inputLng` ← `fillForm()`, `onBirthPlaceChange()`, `generateFromInput()` ⚠️
- `#inputName` ← `fillForm()`, `generateFromInput()` ⚠️
- `#inputPlace` ← `fillForm()`, `onBirthPlaceChange()`, `generateFromInput()` ⚠️
- `#inputPlaceSelect` ← `onBirthPlaceChange()`
- `#inputTime` ← `fillForm()`, `generateFromInput()` ⚠️
- `#mBirthVpHint` ← `buildBSBirthContent()`
- `#mInputLat` ← `onMobileBirthPlaceChange()`
- `#mInputLng` ← `onMobileBirthPlaceChange()`
- `#mInputPlace` ← `onMobileBirthPlaceChange()`
- `#mInputPlaceSelect` ← `onMobileBirthPlaceChange()`
- `#mTransitCustom` ← `onMobileTransitLocChange()`
- `#mTransitLat` ← `onMobileTransitLocChange()`
- `#mTransitLng` ← `onMobileTransitLocChange()`
- `#mTransitLocation` ← `buildBSTransitContent()`, `onMobileTransitLocChange()` ⚠️
- `#mTransitVpHint` ← `buildBSTransitContent()`
- `#noProfileBanner` ← `setChartMode()`, `initTransitDefaults()` ⚠️
- `#planetTable` ← `renderPlanetTable()`, `buildBSPlanetsContent()` ⚠️
- `#predictionList` ← `renderPredictions()`
- `#predictionPanel` ← `renderChart()`, `renderPredictions()` ⚠️
- `#svgHouseLabel` ← `renderChart()`, `updateHouseSystemLabel()` ⚠️
- `#transitBtn` ← `setChartMode()`
- `#transitCustomLatLng` ← `onTransitLocationChange()`
- `#transitDate` ← `getTransitDateTime()`, `initTransitDefaults()`, `renderChart()` ⚠️
- `#transitLat` ← `onTransitLocationChange()`, `getTransitLocation()` ⚠️
- `#transitLng` ← `onTransitLocationChange()`, `getTransitLocation()` ⚠️
- `#transitLocation` ← `onTransitLocationChange()`, `getTransitLocation()`, `initTransitDefaults()`, `renderChart()`, `buildBSTransitContent()` ⚠️
- `#transitPanel` ← `setChartMode()`
- `#transitPanelTitle` ← `setChartMode()`
- `#transitTime` ← `getTransitDateTime()`, `initTransitDefaults()`, `renderChart()` ⚠️
- `#zodiacTooltip` ← `showZodiacName()`

---
## 📋 全関数一覧

### ✅ `loadLocations()` — L1181
- 呼出先: なし
- 呼出元: buildBSBirthContent, buildBSTransitContent, buildVPOptionsHTML, getTransitLocation, initTransitDefaults, onBirthPlaceChange, onMobileBirthPlaceChange, onMobileTransitLocChange, onTransitLocationChange, populateVPSelect

### ✅ `makeUTCDate(dateStr, timeStr, tzHours)` — L1211
- 呼出先: なし
- 呼出元: generateFromInput, getTransitDateTime, renderChart

### ✅ `getEclipticLongitude(body, date)` — L1219
- 呼出先: なし
- 呼出元: calcAllPlanets, predictPatternCompletions, scanTransit

### ✅ `calcAllPlanets(date)` — L1226
- 呼出先: getEclipticLongitude
- 呼出元: generateFromInput, renderChart

### ✅ `calcHousesPlacidus(mc, asc, lat, obliquity)` — L1235
- 呼出先: placidusCusp
- 呼出元: calcHouses

### ✅ `placidusCusp(house)` — L1249
- 呼出先: なし
- 呼出元: calcHousesPlacidus

### ✅ `calcHousesWholeSigns(asc)` — L1283
- 呼出先: なし
- 呼出元: calcHouses

### ✅ `calcHousesEqual(asc)` — L1291
- 呼出先: なし
- 呼出元: calcHouses

### ✅ `calcHouses(mc, asc, lat, obliquity)` — L1298
- 呼出先: calcHousesEqual, calcHousesPlacidus, calcHousesWholeSigns
- 呼出元: renderChart

### ✅ `calcProgressedDate(birthDate, currentDate)` — L1306
- 呼出先: なし
- 呼出元: generateFromInput, renderChart

### ✅ `collectAspects(p1, p2, isCross, label)` — L1318
- 呼出先: なし
- 呼出元: renderChart

### ✅ `detectPatterns(aspects, natal, secondary)` — L1348
- 呼出先: countNatal, hasPersonal, isDuplicate
- 呼出元: generateFromInput, renderChart

### ✅ `countNatal(arr)` — L1357
- 呼出先: なし
- 呼出元: detectPatterns

### ✅ `hasPersonal(arr)` — L1358
- 呼出先: なし
- 呼出元: detectPatterns

### ✅ `isDuplicate(list, trio)` — L1359
- 呼出先: なし
- 呼出元: detectPatterns

### ✅ `predictPatternCompletions(natal, birthDate, daysAhead)` — L1419
- 呼出先: getEclipticLongitude, scanTransit
- 呼出元: generateFromInput

### ✅ `scanTransit(targetDeg, patternType, ni, nj)` — L1424
- 呼出先: getEclipticLongitude
- 呼出元: predictPatternCompletions

### ✅ `getPlanetGroup(idx)` — L1484
- 呼出先: なし
- 呼出元: aspectPassesFilter

### ✅ `aspectPassesFilter(a)` — L1491
- 呼出先: getPlanetGroup
- 呼出元: buildAspectLinesHTML, renderAspectInfo

### ✅ `toggleFilter(el)` — L1506
- 呼出先: renderChart
- 呼出元: なし
- DOM操作: el.classList

### ✅ `toggleExclusive(el)` — L1515
- 呼出先: renderChart
- 呼出元: なし
- DOM操作: c.classList, el.classList

### ✅ `toggleAnalysis()` — L1533
- 呼出先: なし
- 呼出元: なし
- DOM操作: #analysisBody, #analysisToggle, body.classList, toggle.classList

### ✅ `toggleAspects()` — L1540
- 呼出先: なし
- 呼出元: なし
- DOM操作: #aspectsBody, #aspectsToggle, body.classList, toggle.classList

### ✅ `resetFilters()` — L1547
- 呼出先: renderChart
- 呼出元: buildBSFilterContent, setChartMode
- DOM操作: .filter-chip, c.classList

### ✅ `buildPatternPolygons(patterns, natal, asc, cx, cy, r)` — L1565
- 呼出先: なし
- 呼出元: buildAspectLinesHTML

### ✅ `buildAspectLinesHTML(aspects, asc, cx, cy, r, patterns, natal)` — L1598
- 呼出先: aspectPassesFilter, buildPatternPolygons, getAspectKey
- 呼出元: redrawAspectLines, renderChart

### ✅ `redrawAspectLines()` — L1618
- 呼出先: buildAspectLinesHTML
- 呼出元: toggleAspectVisibility
- DOM操作: #aspectLines, temp.innerHTML

### ✅ `fillForm(user)` — L1634
- 呼出先: なし
- 呼出元: loadFortuneCacheOrGenerate
- DOM操作: #inputDate, #inputLat, #inputLng, #inputName, #inputPlace, #inputTime

### ✅ `toggleChartMenu()` — L1643
- 呼出先: なし
- 呼出元: なし
- DOM操作: #chartMenuPanel, panel.classList

### ✅ `setChartModeMenu(mode)` — L1648
- 呼出先: setChartMode
- 呼出元: なし
- DOM操作: #chartMenuPanel, el.classList

### ✅ `setChartMode(mode)` — L1670
- 呼出先: buildTodayView, resetFilters, updateBSTransitTab
- 呼出元: setChartModeMenu
- DOM操作: #astrologyView, #bottomSheet, #noProfileBanner, #transitBtn, #transitPanel, #transitPanelTitle, .main-layout, .tab-btn, astrologyView.style, banner.style, bottomSheet.style, btn.classList, btn.style, btn.textContent, mainLayout.style, title.innerHTML, tp.style

### ✅ `aspectsToText(aspects, filterPlanets)` — L1716
- 呼出先: なし
- 呼出元: buildTodayView

### ✅ `patternsToText(patterns)` — L1735
- 呼出先: なし
- 呼出元: buildTodayView

### ✅ `getFortuneCache()` — L1748
- 呼出先: なし
- 呼出元: buildTodayView

### ✅ `setFortuneCache(data)` — L1758
- 呼出先: なし
- 呼出元: buildTodayView

### ✅ `renderFortuneCard(cat, text, direction)` — L1764
- 呼出先: なし
- 呼出元: buildTodayView

### ✅ `buildTodayView()` — L1779
- 呼出先: aspectsToText, getFortuneCache, patternsToText, renderFortuneCard, setFortuneCache
- 呼出元: setChartMode
- DOM操作: #astrologyCardsAll, el.innerHTML

### ✅ `buildVPOptionsHTML()` — L1838
- 呼出先: loadLocations
- 呼出元: buildBSBirthContent, buildBSTransitContent

### ✅ `populateVPSelect(selectId, hintId)` — L1849
- 呼出先: loadLocations
- 呼出元: initTransitDefaults
- DOM操作: hint.style, opt.textContent

### ✅ `onBirthPlaceChange()` — L1874
- 呼出先: loadLocations
- 呼出元: なし
- DOM操作: #birthCustomLatLng, #inputLat, #inputLng, #inputPlace, #inputPlaceSelect, latLng.style, placeInput.style

### ✅ `onTransitLocationChange()` — L1895
- 呼出先: loadLocations, renderChart
- 呼出元: applyBSTransit, initTransitDefaults
- DOM操作: #transitCustomLatLng, #transitLat, #transitLng, #transitLocation, custom.style

### ✅ `getTransitDateTime()` — L1913
- 呼出先: makeUTCDate
- 呼出元: generateFromInput, renderChart
- DOM操作: #transitDate, #transitTime

### ✅ `getTransitLocation()` — L1920
- 呼出先: loadLocations
- 呼出元: renderChart
- DOM操作: #transitLat, #transitLng, #transitLocation

### ✅ `initTransitDefaults()` — L1936
- 呼出先: loadLocations, onTransitLocationChange, populateVPSelect
- 呼出元: なし
- DOM操作: #noProfileBanner, #transitDate, #transitLocation, #transitTime, banner.style

### ✅ `generateFromInput()` — L1961
- 呼出先: calcAllPlanets, calcProgressedDate, detectPatterns, getTransitDateTime, makeUTCDate, predictPatternCompletions, renderChart
- 呼出元: applyBSBirth
- DOM操作: #inputDate, #inputLat, #inputLng, #inputName, #inputPlace, #inputTime

### ✅ `formatDegree(lon)` — L1986
- 呼出先: なし
- 呼出元: renderChart, renderPlanetTable

### ✅ `getHouseNumber(lon, houses)` — L1995
- 呼出先: なし
- 呼出元: renderPlanetTable

### ✅ `getAspectKey(a)` — L2005
- 呼出先: なし
- 呼出元: buildAspectLinesHTML, renderAspectInfo, renderAspectList

### ✅ `renderChart()` — L2008
- 呼出先: buildAspectLinesHTML, calcAllPlanets, calcHouses, calcProgressedDate, collectAspects, detectPatterns, formatDegree, getTransitDateTime, getTransitLocation, makeUTCDate, placePlanet, refreshActiveBS, renderAspectInfo, renderLegend, renderPlanetTable, renderPredictions, showZodiacName, updateHouseSystemLabel
- 呼出元: applyBSTransit, generateFromInput, onTransitLocationChange, resetFilters, toggleExclusive, toggleFilter
- DOM操作: #horoscopeChart, #predictionPanel, #svgHouseLabel, #transitDate, #transitLocation, #transitTime, predictionPanel.style, svg.innerHTML

### ✅ `placePlanet(lon, r, color, glyph, fontSize)` — L2169
- 呼出先: なし
- 呼出元: renderChart

### ✅ `updateHouseSystemLabel()` — L2227
- 呼出先: なし
- 呼出元: renderChart
- DOM操作: #horoscopeChart, #svgHouseLabel, t.textContent

### ✅ `renderPlanetTable(natal, secondary, secColor, secLabel, asc, mc, dsc, ic, houses)` — L2251
- 呼出先: formatDegree, getHouseNumber
- 呼出元: renderChart
- DOM操作: #planetTable, c.innerHTML

### ✅ `toggleAspectVisibility(key)` — L2291
- 呼出先: redrawAspectLines
- 呼出元: renderAspectList
- DOM操作: .aspect-check, check.style, check.textContent, row.style

### ✅ `renderAspectList(container, allAspects, filteredAspects)` — L2305
- 呼出先: getAspectKey, toggleAspectVisibility
- 呼出元: renderAspectInfo
- DOM操作: container.innerHTML

### ✅ `renderAspectInfo(aspects, patterns)` — L2336
- 呼出先: aspectPassesFilter, getAspectKey, renderAspectList
- 呼出元: renderChart
- DOM操作: #aspectInfo, #aspectsContainerTitle, containerTitle.innerHTML

### ✅ `renderPredictions(predictions, detectedPatterns)` — L2359
- 呼出先: なし
- 呼出元: renderChart
- DOM操作: #predictionList, #predictionPanel, list.innerHTML, panel.style

### ✅ `showZodiacName(evt, idx)` — L2413
- 呼出先: なし
- 呼出元: renderChart
- DOM操作: #horoscopeChart, #zodiacTooltip, txt.textContent

### ✅ `renderLegend(secColor, secLabel)` — L2448
- 呼出先: なし
- 呼出元: renderChart
- DOM操作: #chartLegend, c.innerHTML

### ✅ `isMobileView()` — L2467
- 呼出先: なし
- 呼出元: initBottomSheet, refreshActiveBS

### ✅ `initBottomSheet()` — L2469
- 呼出先: buildBSBirthContent, buildBSTransitContent, isMobileView, setBSState, switchBSTab, updateBSBodyHeight
- 呼出元: なし
- DOM操作: #bottomSheet, #bsDragHandle, sheet.style

### ✅ `setBSState(state)` — L2521
- 呼出先: updateBSBodyHeight
- 呼出元: initBottomSheet, switchBSTab
- DOM操作: #bottomSheet, #bsBody, #bsMiniLabel, #bsTabs, bsBody.style, bsTabs.style, miniLabel.style, sheet.style

### ✅ `updateBSBodyHeight()` — L2546
- 呼出先: なし
- 呼出元: initBottomSheet, setBSState
- DOM操作: #bottomSheet, #bsBody, #bsDragHandle, #bsTabs, body.style

### ✅ `switchBSTab(tab)` — L2556
- 呼出先: buildBSAspectsContent, buildBSFilterContent, buildBSFortuneContent, buildBSPlanetsContent, setBSState, syncBSBirthForm, syncBSTransitForm
- 呼出元: initBottomSheet
- DOM操作: .bs-section, .bs-tab, s.classList, section.classList, t.classList

### ✅ `updateBSTransitTab()` — L2574
- 呼出先: なし
- 呼出元: refreshActiveBS, setChartMode
- DOM操作: #bsTransitTab, tab.classList, tab.innerHTML

### ✅ `buildBSBirthContent()` — L2586
- 呼出先: applyBSBirth, buildVPOptionsHTML, loadLocations, onMobileBirthPlaceChange
- 呼出元: initBottomSheet
- DOM操作: #bsBirth, #mBirthVpHint, el.innerHTML, hint.style

### ✅ `syncBSBirthForm()` — L2605
- 呼出先: g
- 呼出元: switchBSTab

### ✅ `applyBSBirth()` — L2616
- 呼出先: g, generateFromInput
- 呼出元: buildBSBirthContent

### ✅ `buildBSTransitContent()` — L2627
- 呼出先: applyBSTransit, buildVPOptionsHTML, loadLocations, onMobileTransitLocChange
- 呼出元: initBottomSheet
- DOM操作: #bsTransit, #mTransitLocation, #mTransitVpHint, #transitLocation, el.innerHTML, hint.style

### ✅ `syncBSTransitForm()` — L2650
- 呼出先: g, onMobileTransitLocChange
- 呼出元: switchBSTab

### ✅ `onMobileBirthPlaceChange()` — L2659
- 呼出先: loadLocations
- 呼出元: buildBSBirthContent
- DOM操作: #mInputLat, #mInputLng, #mInputPlace, #mInputPlaceSelect

### ✅ `onMobileTransitLocChange()` — L2674
- 呼出先: loadLocations
- 呼出元: buildBSTransitContent, syncBSTransitForm
- DOM操作: #mTransitCustom, #mTransitLat, #mTransitLng, #mTransitLocation, custom.style

### ✅ `applyBSTransit()` — L2692
- 呼出先: g, onTransitLocationChange, renderChart
- 呼出元: buildBSTransitContent

### ✅ `g(id)` — L2693
- 呼出先: なし
- 呼出元: applyBSBirth, applyBSTransit, syncBSBirthForm, syncBSTransitForm

### ✅ `buildBSPlanetsContent()` — L2705
- 呼出先: なし
- 呼出元: refreshActiveBS, switchBSTab
- DOM操作: #bsPlanets, #planetTable, el.innerHTML

### ✅ `buildBSFilterContent()` — L2711
- 呼出先: resetFilters, syncFilterChips
- 呼出元: refreshActiveBS, switchBSTab
- DOM操作: #aspectFilterPanel, #bsFilter, el.innerHTML

### ✅ `syncFilterChips(container)` — L2720
- 呼出先: なし
- 呼出元: buildBSFilterContent
- DOM操作: .filter-chip, c.classList

### ✅ `buildBSAspectsContent()` — L2735
- 呼出先: なし
- 呼出元: refreshActiveBS, switchBSTab
- DOM操作: #aspectInfo, #aspectsContainerTitle, #bsAspects, el.innerHTML

### ✅ `refreshActiveBS()` — L2751
- 呼出先: buildBSAspectsContent, buildBSFilterContent, buildBSPlanetsContent, isMobileView, updateBSTransitTab
- 呼出元: renderChart

### ✅ `renderFortuneCardsTo(targetTrackId, targetDotsId)` — L2814
- 呼出先: goFortune, updateFortuneUI
- 呼出元: buildBSFortuneContent
- DOM操作: dots.innerHTML, track.innerHTML

### ✅ `goFortune(idx)` — L2840
- 呼出先: updateFortuneUI
- 呼出元: fortuneNext, fortunePrev, renderFortuneCardsTo

### ✅ `fortunePrev()` — L2844
- 呼出先: goFortune
- 呼出元: buildBSFortuneContent, initFortuneSwipe

### ✅ `fortuneNext()` — L2845
- 呼出先: goFortune
- 呼出元: buildBSFortuneContent, initFortuneSwipe

### ✅ `updateFortuneUI()` — L2847
- 呼出先: なし
- 呼出元: goFortune, renderFortuneCardsTo
- DOM操作: .fortune-dots .fortune-dot, d.classList, lbl.textContent, track.style

### ✅ `buildBSFortuneContent()` — L2866
- 呼出先: fortuneNext, fortunePrev, renderFortuneCardsTo
- 呼出元: switchBSTab
- DOM操作: #bsFortune, el.innerHTML

### ✅ `initFortuneSwipe()` — L2881
- 呼出先: fortuneNext, fortunePrev
- 呼出元: なし
- DOM操作: .fortune-cards-wrap

### ✅ `loadFortuneCacheOrGenerate()` — L2916
- 呼出先: fillForm
- 呼出元: なし
