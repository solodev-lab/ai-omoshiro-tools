# Horoscope（ホロスコープチャート）

**ソースファイル**: `mockup/horoscope.html`
**HTML行数**: 2946行（うちJS約1825行）
**イベント数**: 58個
**API呼び出し**: 1箇所

---
## この画面の説明（日本語メモ）

> ここにオーナーが日本語で画面の説明を書く。
> 例：「世界地図が表示される。タップした場所の運勢が見れる。」

---
## 要素一覧（HTML上から順）

1. `<div #chartMenuBtn>`
  CSS: width:40px; height:40px; background:rgba(12,12,26,0.92); border-radius:10px; position:fixed; top:12px
  2. `<div .chart-menu-bar>`
    CSS: width:18px; height:2px; background:#F6BD60; border-radius:1px
  3. `<div .chart-menu-bar>`
    CSS: width:18px; height:2px; background:#F6BD60; border-radius:1px
  4. `<div .chart-menu-bar>`
    CSS: width:18px; height:2px; background:#F6BD60; border-radius:1px
5. `<div #chartMenuPanel>`
  CSS: background:rgba(12,12,26,0.97); padding:8px; border-radius:14px; position:fixed; top:58px; right:12px
  6. `<button #cmItem0>` — テキスト:「1重 NATAL」
    CSS: width:100%; font-size:13px; color:#ACACAC; background:none; padding:10px 14px; border-radius:8px
  7. `<button #cmItem1>` — テキスト:「2重 N+T」
    CSS: width:100%; font-size:13px; color:#ACACAC; background:none; padding:10px 14px; border-radius:8px
  8. `<button #cmItem2>` — テキスト:「2重 N+P」
    CSS: width:100%; font-size:13px; color:#ACACAC; background:none; padding:10px 14px; border-radius:8px
  9. `<button #cmItem3>` — テキスト:「✦ 星読み」
    CSS: width:100%; font-size:13px; color:#ACACAC; background:none; padding:10px 14px; border-radius:8px
10. `<div .tab-nav>`
  CSS: display:none !important
  11. `<button .tab-btn>` — テキスト:「1重 NATAL」
    CSS: font-size:13px; color:#888; background:transparent; padding:10px 20px; border-radius:8px
  12. `<button .tab-btn>` — テキスト:「2重 N+T」
    CSS: font-size:13px; color:#888; background:transparent; padding:10px 20px; border-radius:8px
  13. `<button .tab-btn>` — テキスト:「2重 N+P」
    CSS: font-size:13px; color:#888; background:transparent; padding:10px 20px; border-radius:8px
  14. `<button .tab-btn>` — テキスト:「✦ 星読み」
    CSS: font-size:13px; color:#888; background:transparent; padding:10px 20px; border-radius:8px
    15. `<br>`
      16. `<span>` — テキスト:「Astrology」
  17. `<div #astrologyView>`
    18. `<div #astrologyCardsAll>`
  19. `<div #noProfileBanner>`
    20. `<span>` — テキスト:「✦ SANCTUARYでプロフィールを設定すると、あなた専用」
    21. `<br>`
      22. `<a>` — テキスト:「設定する →」
    23. `<div .main-layout>`
      CSS: flex-direction:column
      24. `<div .left-column>`
        CSS: width:100%; max-width:600px; position:relative; top:auto
      25. `<div .right-column>`
        CSS: display:none !important

**要素総数（depth≤3）**: 25個

---
## インタラクション一覧（イベントハンドラ）

1. **analysisBody** の `DOMContentLoaded` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

2. **chartMenuBtn** の `touchstart` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

3. **bottomSheet** の `touchstart` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

4. **window** の `DOMContentLoaded` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

5. **document** の `click` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

6. **handle** の `touchstart` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

7. **document** の `touchmove` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

8. **document** の `touchend` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

9. **handle** の `mousedown` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

10. **document** の `mousemove` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

11. **document** の `mouseup` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

12. **window** の `resize` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

13. **wrap** の `touchstart` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

14. **wrap** の `touchmove` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

15. **wrap** の `touchend` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

16. **wrap** の `mousedown` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

17. **window** の `mousemove` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

18. **window** の `mouseup` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

20. **(HTML属性)** の `click` イベント → `toggleChartMenu()`
   > 動作メモ:（ここに日本語で何が起きるか書く）

---
## 関数一覧（インラインJS）

1. `loadLocations()` — 説明:（ここに日本語で書く）
2. `makeUTCDate(dateStr, timeStr, tzHours)` — 説明:（ここに日本語で書く）
3. `getEclipticLongitude(body, date)` — 説明:（ここに日本語で書く）
4. `calcAllPlanets(date)` — 説明:（ここに日本語で書く）
5. `calcHousesPlacidus(mc, asc, lat, obliquity)` — 説明:（ここに日本語で書く）
6. `placidusCusp(house)` — 説明:（ここに日本語で書く）
7. `calcHousesWholeSigns(asc)` — 説明:（ここに日本語で書く）
8. `calcHousesEqual(asc)` — 説明:（ここに日本語で書く）
9. `calcHouses(mc, asc, lat, obliquity)` — 説明:（ここに日本語で書く）
10. `calcProgressedDate(birthDate, currentDate)` — 説明:（ここに日本語で書く）
11. `collectAspects(p1, p2, isCross, label)` — 説明:（ここに日本語で書く）
12. `detectPatterns(aspects, natal, secondary)` — 説明:（ここに日本語で書く）
13. `countNatal(arr)` — 説明:（ここに日本語で書く）
14. `hasPersonal(arr)` — 説明:（ここに日本語で書く）
15. `isDuplicate(list, trio)` — 説明:（ここに日本語で書く）
16. `predictPatternCompletions(natal, birthDate, daysAhead)` — 説明:（ここに日本語で書く）
17. `scanTransit(targetDeg, patternType, ni, nj)` — 説明:（ここに日本語で書く）
18. `getPlanetGroup(idx)` — 説明:（ここに日本語で書く）
19. `aspectPassesFilter(a)` — 説明:（ここに日本語で書く）
20. `toggleFilter(el)` — 説明:（ここに日本語で書く）
21. `toggleExclusive(el)` — 説明:（ここに日本語で書く）
22. `toggleAnalysis()` — 説明:（ここに日本語で書く）
23. `toggleAspects()` — 説明:（ここに日本語で書く）
24. `resetFilters()` — 説明:（ここに日本語で書く）
25. `buildPatternPolygons(patterns, natal, asc, cx, cy, r)` — 説明:（ここに日本語で書く）
26. `buildAspectLinesHTML(aspects, asc, cx, cy, r, patterns, natal)` — 説明:（ここに日本語で書く）
27. `redrawAspectLines()` — 説明:（ここに日本語で書く）
28. `fillForm(user)` — 説明:（ここに日本語で書く）
29. `toggleChartMenu()` — 説明:（ここに日本語で書く）
30. `setChartModeMenu(mode)` — 説明:（ここに日本語で書く）
31. `setChartMode(mode)` — 説明:（ここに日本語で書く）
32. `aspectsToText(aspects, filterPlanets)` — 説明:（ここに日本語で書く）
33. `patternsToText(patterns)` — 説明:（ここに日本語で書く）
34. `getFortuneCache()` — 説明:（ここに日本語で書く）
35. `setFortuneCache(data)` — 説明:（ここに日本語で書く）
36. `renderFortuneCard(cat, text, direction)` — 説明:（ここに日本語で書く）
37. `buildTodayView()` — 説明:（ここに日本語で書く）
38. `buildVPOptionsHTML()` — 説明:（ここに日本語で書く）
39. `populateVPSelect(selectId, hintId)` — 説明:（ここに日本語で書く）
40. `onBirthPlaceChange()` — 説明:（ここに日本語で書く）
41. `onTransitLocationChange()` — 説明:（ここに日本語で書く）
42. `getTransitDateTime()` — 説明:（ここに日本語で書く）
43. `getTransitLocation()` — 説明:（ここに日本語で書く）
44. `initTransitDefaults()` — 説明:（ここに日本語で書く）
45. `generateFromInput()` — 説明:（ここに日本語で書く）
46. `formatDegree(lon)` — 説明:（ここに日本語で書く）
47. `getHouseNumber(lon, houses)` — 説明:（ここに日本語で書く）
48. `getAspectKey(a)` — 説明:（ここに日本語で書く）
49. `renderChart()` — 説明:（ここに日本語で書く）
50. `placePlanet(lon, r, color, glyph, fontSize)` — 説明:（ここに日本語で書く）
51. `updateHouseSystemLabel()` — 説明:（ここに日本語で書く）
52. `renderPlanetTable(natal, secondary, secColor, secLabel, asc, mc, dsc, ic, houses)` — 説明:（ここに日本語で書く）
53. `toggleAspectVisibility(key)` — 説明:（ここに日本語で書く）
54. `renderAspectList(container, allAspects, filteredAspects)` — 説明:（ここに日本語で書く）
55. `renderAspectInfo(aspects, patterns)` — 説明:（ここに日本語で書く）
56. `renderPredictions(predictions, detectedPatterns)` — 説明:（ここに日本語で書く）
57. `showZodiacName(evt, idx)` — 説明:（ここに日本語で書く）
58. `renderLegend(secColor, secLabel)` — 説明:（ここに日本語で書く）
59. `isMobileView()` — 説明:（ここに日本語で書く）
60. `initBottomSheet()` — 説明:（ここに日本語で書く）
61. `setBSState(state)` — 説明:（ここに日本語で書く）
62. `updateBSBodyHeight()` — 説明:（ここに日本語で書く）
63. `switchBSTab(tab)` — 説明:（ここに日本語で書く）
64. `updateBSTransitTab()` — 説明:（ここに日本語で書く）
65. `buildBSBirthContent()` — 説明:（ここに日本語で書く）
66. `syncBSBirthForm()` — 説明:（ここに日本語で書く）
67. `applyBSBirth()` — 説明:（ここに日本語で書く）
68. `buildBSTransitContent()` — 説明:（ここに日本語で書く）
69. `syncBSTransitForm()` — 説明:（ここに日本語で書く）
70. `onMobileBirthPlaceChange()` — 説明:（ここに日本語で書く）
71. `onMobileTransitLocChange()` — 説明:（ここに日本語で書く）
72. `applyBSTransit()` — 説明:（ここに日本語で書く）
73. `buildBSPlanetsContent()` — 説明:（ここに日本語で書く）
74. `buildBSFilterContent()` — 説明:（ここに日本語で書く）
75. `syncFilterChips(container)` — 説明:（ここに日本語で書く）
76. `buildBSAspectsContent()` — 説明:（ここに日本語で書く）
77. `refreshActiveBS()` — 説明:（ここに日本語で書く）
78. `renderFortuneCardsTo(targetTrackId, targetDotsId)` — 説明:（ここに日本語で書く）
79. `goFortune(idx)` — 説明:（ここに日本語で書く）
80. `fortunePrev()` — 説明:（ここに日本語で書く）
81. `fortuneNext()` — 説明:（ここに日本語で書く）
82. `updateFortuneUI()` — 説明:（ここに日本語で書く）
83. `buildBSFortuneContent()` — 説明:（ここに日本語で書く）
84. `initFortuneSwipe()` — 説明:（ここに日本語で書く）
85. `loadFortuneCacheOrGenerate()` — 説明:（ここに日本語で書く）

---
## API呼び出し

1. `${apiUrl}（変数）`
   > 用途:（ここに日本語で書く）

---
## 使用CSS変数

| 変数名 | 値 |
|--------|-----|
| `--bg-deep` | `#080C14` |
| `--chip-color` | `（未定義）` |
| `--font-body` | `'DM Sans', 'Segoe UI', sans-serif` |
