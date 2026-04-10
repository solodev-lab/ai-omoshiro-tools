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
        25. `<div .chart-container>`
          CSS: position:relative; display:flex; flex-direction:column
          26. `<div .chart-watermark>` — テキスト:「SOLARA」
            CSS: font-size:14px; font-weight:700; color:rgba(246,189,96,0.18); position:absolute; top:42%; left:50%
          27. `<svg #horoscopeChart>`
          28. `<div #chartLegend>`
            CSS: font-size:11px; color:#888; display:flex; gap:16px
      29. `<div .right-column>`
        CSS: display:none !important
        30. `<div #birthPanel>`
          CSS: background:rgba(255,255,255,0.03); padding:20px; border-radius:16px
          31. `<h3 .desktop-only>` — テキスト:「⚙ BIRTH DATA」
            CSS: display:none !important
          32. `<div .form-group>`
            33. `<label>` — テキスト:「氏名 NAME」
            34. `<input #inputName>`
            35. `<div .form-row>`
              CSS: display:flex; gap:8px
              36. `<div .form-group>`
                37. `<label>` — テキスト:「生年月日 DATE」
                38. `<input #inputDate>`
                39. `<div .form-group>`
                  40. `<label>` — テキスト:「出生時刻 TIME」
                  41. `<input #inputTime>`
                42. `<div .form-group>`
                  43. `<label>` — テキスト:「出生地 BIRTHPLACE」
                  44. `<select #inputPlaceSelect>`
                    45. `<option>` — テキスト:「手動入力」
                  46. `<div #birthVpHint>` — テキスト:「💡 Map画面で場所を保存すると選択できます」
                    CSS: font-size:10px; color:#888
                  47. `<input #inputPlace>`
                  48. `<div #birthCustomLatLng>`
                    CSS: display:flex; gap:8px
                    49. `<div .form-group>`
                      50. `<label>` — テキスト:「緯度 LAT」
                      51. `<input #inputLat>`
                      52. `<div .form-group>`
                        53. `<label>` — テキスト:「経度 LNG」
                        54. `<input #inputLng>`
                      55. `<button .btn-generate>` — テキスト:「ホロスコープ生成」
                        CSS: width:100%; font-size:13px; font-weight:600; color:#0A0A14; background:linear-gradient(135deg, #F6BD60, #E8A840); padding:10px
                    56. `<div #transitPanel>`
                      CSS: background:rgba(255,255,255,0.03); padding:20px; border-radius:16px
                      57. `<h3 #transitPanelTitle>` — テキスト:「☾ TRANSIT DATA」
                        CSS: display:none !important
                      58. `<div .form-row>`
                        CSS: display:flex; gap:8px
                        59. `<div .form-group>`
                          60. `<label>` — テキスト:「日付 DATE」
                          61. `<input #transitDate>`
                          62. `<div .form-group>`
                            63. `<label>` — テキスト:「時刻 TIME」
                            64. `<input #transitTime>`
                          65. `<div .form-group>`
                            66. `<label>` — テキスト:「場所 LOCATION」
                            67. `<select #transitLocation>`
                              68. `<option>` — テキスト:「手動入力」
                            69. `<div #transitVpHint>` — テキスト:「💡 Map画面で場所を保存すると選択できます」
                              CSS: font-size:10px; color:#888
                          70. `<div #transitCustomLatLng>`
                            CSS: display:flex; gap:8px
                            71. `<div .form-group>`
                              72. `<label>` — テキスト:「緯度 LAT」
                              73. `<input #transitLat>`
                              74. `<div .form-group>`
                                75. `<label>` — テキスト:「経度 LNG」
                                76. `<input #transitLng>`
                              77. `<button #transitBtn>` — テキスト:「トランジット更新」
                                CSS: width:100%; font-size:13px; font-weight:600; color:#0A0A14; background:linear-gradient(135deg, #F6BD60, #E8A840); padding:10px
                            78. `<div #planetsPanel>`
                              CSS: background:rgba(255,255,255,0.03); padding:20px; border-radius:16px
                              79. `<h3 .desktop-only>` — テキスト:「☉ PLANET POSITIONS」
                                CSS: display:none !important
                              80. `<div #planetTable>`
                            81. `<div #analysisContainer>`
                              CSS: background:rgba(255,255,255,0.03); border-radius:16px; overflow:hidden
                              82. `<div .analysis-header>`
                                CSS: padding:14px 20px; display:flex
                                83. `<h3>` — テキスト:「⚙ ANALYSIS」
                                84. `<span #analysisToggle>` — テキスト:「▼」
                                  CSS: font-size:14px; color:#F6BD60
                              85. `<div #analysisBody>`
                                CSS: padding:16px 20px; opacity:1; overflow:hidden
                                86. `<div #aspectFilterPanel>`
                                  CSS: background:rgba(255,255,255,0.03); padding:20px; border-radius:16px
                                  87. `<div>`
                                    88. `<span>` — テキスト:「ASPECT FILTER」
                                    89. `<button .filter-reset-btn>` — テキスト:「RESET」
                                      CSS: font-size:10px; color:#666; background:transparent; padding:4px 12px; border-radius:6px
                                  90. `<div .filter-section>`
                                    91. `<div .filter-section-title>`
                                      CSS: font-size:10px; color:#888; display:flex; gap:6px
                                      92. `<span .filter-label>` — テキスト:「アスペクト性質」
                                        CSS: font-size:9px; font-weight:600; color:#aaa; background:rgba(255,255,255,0.08); padding:1px 6px; border-radius:4px
                                    93. `<div .filter-chips>`
                                      CSS: display:flex; gap:4px
                                      94. `<div .filter-chip>` — テキスト:「ソフト（調和）」
                                        CSS: font-size:11px; color:#888; background:rgba(255,255,255,0.03); padding:4px 10px; border-radius:6px
                                      95. `<div .filter-chip>` — テキスト:「ハード（緊張）」
                                        CSS: font-size:11px; color:#888; background:rgba(255,255,255,0.03); padding:4px 10px; border-radius:6px
                                      96. `<div .filter-chip>` — テキスト:「中立」
                                        CSS: font-size:11px; color:#888; background:rgba(255,255,255,0.03); padding:4px 10px; border-radius:6px
                                  97. `<div .filter-section>`
                                    98. `<div .filter-section-title>`
                                      CSS: font-size:10px; color:#888; display:flex; gap:6px
                                      99. `<span .filter-label>` — テキスト:「運勢カテゴリ」
                                        CSS: font-size:9px; font-weight:600; color:#aaa; background:rgba(255,255,255,0.08); padding:1px 6px; border-radius:4px
                                    100. `<div .filter-chips>`
                                      CSS: display:flex; gap:4px
                                      101. `<div .filter-chip>` — テキスト:「癒し」
                                        CSS: font-size:11px; color:#888; background:rgba(255,255,255,0.03); padding:4px 10px; border-radius:6px
                                      102. `<div .filter-chip>` — テキスト:「金運」
                                        CSS: font-size:11px; color:#888; background:rgba(255,255,255,0.03); padding:4px 10px; border-radius:6px
                                      103. `<div .filter-chip>` — テキスト:「恋愛運」
                                        CSS: font-size:11px; color:#888; background:rgba(255,255,255,0.03); padding:4px 10px; border-radius:6px
                                      104. `<div .filter-chip>` — テキスト:「仕事運」
                                        CSS: font-size:11px; color:#888; background:rgba(255,255,255,0.03); padding:4px 10px; border-radius:6px
                                      105. `<div .filter-chip>` — テキスト:「コミュニケーション」
                                        CSS: font-size:11px; color:#888; background:rgba(255,255,255,0.03); padding:4px 10px; border-radius:6px
                                  106. `<div #patternFilterSection>`
                                    107. `<div .filter-section-title>`
                                      CSS: font-size:10px; color:#888; display:flex; gap:6px
                                      108. `<span .filter-label>` — テキスト:「惑星グループ」
                                        CSS: font-size:9px; font-weight:600; color:#aaa; background:rgba(255,255,255,0.08); padding:1px 6px; border-radius:4px
                                    109. `<div .filter-chips>`
                                      CSS: display:flex; gap:4px
                                      110. `<div .filter-chip>` — テキスト:「個人天体」
                                        CSS: font-size:11px; color:#888; background:rgba(255,255,255,0.03); padding:4px 10px; border-radius:6px
                                      111. `<div .filter-chip>` — テキスト:「社会天体」
                                        CSS: font-size:11px; color:#888; background:rgba(255,255,255,0.03); padding:4px 10px; border-radius:6px
                                      112. `<div .filter-chip>` — テキスト:「世代天体」
                                        CSS: font-size:11px; color:#888; background:rgba(255,255,255,0.03); padding:4px 10px; border-radius:6px
                                  113. `<div #predictionPanel>`
                                    114. `<div #predictionList>`
                            115. `<div #aspectsContainer>`
                              CSS: background:rgba(255,255,255,0.03); border-radius:16px; overflow:hidden
                              116. `<div .analysis-header>`
                                CSS: padding:14px 20px; display:flex
                                117. `<h3 #aspectsContainerTitle>` — テキスト:「△ ASPECTS」
                                118. `<span #aspectsToggle>` — テキスト:「▼」
                                  CSS: font-size:14px; color:#F6BD60
                              119. `<div #aspectsBody>`
                                CSS: padding:16px 20px; opacity:1; overflow:hidden
                                120. `<div #aspectPanelMain>`
                                  121. `<div #aspectInfo>`
                        122. `<div #bottomSheet>`
                          CSS: background:rgba(12,12,22,0.97); border-radius:16px 16px 0 0; position:fixed; left:0; right:0; bottom:70px
                          123. `<div #bsDragHandle>`
                            CSS: padding:10px 0 6px; display:flex
                          124. `<div #bsMiniLabel>`
                            CSS: font-size:11px; color:#F6BD60; padding:2px 16px 10px; display:none; opacity:0.9
                            125. `<span .bs-mini-chevron>` — テキスト:「ホロスコープ設定」
                          126. `<div #bsTabs>`
                            CSS: padding:0 8px; display:flex; gap:0
                            127. `<button .bs-tab>` — テキスト:「⚙ 誕生」
                              CSS: font-size:11px; color:#777; background:none; padding:8px 4px
                            128. `<button #bsTransitTab>` — テキスト:「☾ 経過」
                              CSS: font-size:11px; color:#777; background:none; padding:8px 4px
                            129. `<button .bs-tab>` — テキスト:「☉ 天体」
                              CSS: font-size:11px; color:#777; background:none; padding:8px 4px
                            130. `<button .bs-tab>` — テキスト:「⚙ 絞込」
                              CSS: font-size:11px; color:#777; background:none; padding:8px 4px
                            131. `<button .bs-tab>` — テキスト:「△ 相」
                              CSS: font-size:11px; color:#777; background:none; padding:8px 4px
                          132. `<div #bsBody>`
                            CSS: padding:12px 14px 24px
                            133. `<div #bsBirth>`
                              CSS: display:none
                            134. `<div #bsTransit>`
                              CSS: display:none
                            135. `<div #bsFortune>`
                              CSS: display:none
                            136. `<div #bsPlanets>`
                              CSS: display:none
                            137. `<div #bsFilter>`
                              CSS: display:none
                            138. `<div #bsAspects>`
                              CSS: display:none
                        139. `<div .bottom-nav>`
                          CSS: height:80px; background:linear-gradient(180deg, rgba(6,10,18,0.80) 0%, rgba(4,6,14,0.95) 100%); padding:10px 4px 0; position:fixed; left:0; right:0

**要素総数（depth≤20）**: 139個

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
