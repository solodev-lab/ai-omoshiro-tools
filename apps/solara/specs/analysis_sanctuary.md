# Sanctuary（サンクチュアリ・プロフィール） — 機能分析レポート

**ソース**: `mockup/sanctuary.html`
**関数総数**: 62個
**エントリーポイント**: 50個
**到達可能な関数**: 60個
**到達不可能（未使用候補）**: 2個
**DOM操作の重複箇所**: 18箇所

---
## ⚠️ 同じ場所を操作する関数（重複候補）

> 同じDOM要素を複数の関数が操作している箇所。
> 古い方を削除するか、統合を検討してください。

### `#biBirthDate`

- **[✅ 実行中]** `openBirthInfo()` (L1011)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `saveBirthInfo()` (L1138)
  - 呼出元: なし
  - 操作: getById

### `#biBirthLat`

- **[✅ 実行中]** `openBirthInfo()` (L1011)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `setBirthMapLocation()` (L1067)
  - 呼出元: searchBirthPlace, openBirthInfo
  - 操作: getById
- **[✅ 実行中]** `saveBirthInfo()` (L1138)
  - 呼出元: なし
  - 操作: getById

### `#biBirthLng`

- **[✅ 実行中]** `openBirthInfo()` (L1011)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `setBirthMapLocation()` (L1067)
  - 呼出元: searchBirthPlace, openBirthInfo
  - 操作: getById
- **[✅ 実行中]** `saveBirthInfo()` (L1138)
  - 呼出元: なし
  - 操作: getById

### `#biBirthPlace`

- **[✅ 実行中]** `openBirthInfo()` (L1011)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `setBirthMapLocation()` (L1067)
  - 呼出元: searchBirthPlace, openBirthInfo
  - 操作: getById
- **[✅ 実行中]** `searchBirthPlace()` (L1105)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `saveBirthInfo()` (L1138)
  - 呼出元: なし
  - 操作: getById

### `#biBirthTime`

- **[✅ 実行中]** `openBirthInfo()` (L1011)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `toggleTimeUnknown()` (L1053)
  - 呼出元: openBirthInfo
  - 操作: getById
- **[✅ 実行中]** `saveBirthInfo()` (L1138)
  - 呼出元: なし
  - 操作: getById

### `#biMapResult`

- **[✅ 実行中]** `openBirthInfo()` (L1011)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `setBirthMapLocation()` (L1067)
  - 呼出元: searchBirthPlace, openBirthInfo
  - 操作: getById
- **[✅ 実行中]** `searchBirthPlace()` (L1105)
  - 呼出元: なし
  - 操作: getById

### `#biName`

- **[✅ 実行中]** `openBirthInfo()` (L1011)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `saveBirthInfo()` (L1138)
  - 呼出元: なし
  - 操作: getById

### `#biTimeUnknown`

- **[✅ 実行中]** `openBirthInfo()` (L1011)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `toggleTimeUnknown()` (L1053)
  - 呼出元: openBirthInfo
  - 操作: getById
- **[✅ 実行中]** `saveBirthInfo()` (L1138)
  - 呼出元: なし
  - 操作: getById

### `#birthOverlay`

- **[✅ 実行中]** `openBirthInfo()` (L1011)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `closeBirthInfo()` (L1049)
  - 呼出元: saveBirthInfo
  - 操作: getById

### `#hiHomeLat`

- **[✅ 実行中]** `openHomeInfo()` (L1196)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `setHomeMapLocation()` (L1230)
  - 呼出元: searchHomePlace, openHomeInfo
  - 操作: getById
- **[✅ 実行中]** `saveHomeInfo()` (L1301)
  - 呼出元: なし
  - 操作: getById

### `#hiHomeLng`

- **[✅ 実行中]** `openHomeInfo()` (L1196)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `setHomeMapLocation()` (L1230)
  - 呼出元: searchHomePlace, openHomeInfo
  - 操作: getById
- **[✅ 実行中]** `saveHomeInfo()` (L1301)
  - 呼出元: なし
  - 操作: getById

### `#hiHomeName`

- **[✅ 実行中]** `openHomeInfo()` (L1196)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `setHomeMapLocation()` (L1230)
  - 呼出元: searchHomePlace, openHomeInfo
  - 操作: getById
- **[✅ 実行中]** `searchHomePlace()` (L1268)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `saveHomeInfo()` (L1301)
  - 呼出元: なし
  - 操作: getById

### `#hiMapResult`

- **[✅ 実行中]** `openHomeInfo()` (L1196)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `setHomeMapLocation()` (L1230)
  - 呼出元: searchHomePlace, openHomeInfo
  - 操作: getById
- **[✅ 実行中]** `searchHomePlace()` (L1268)
  - 呼出元: なし
  - 操作: getById

### `#homeOverlay`

- **[✅ 実行中]** `openHomeInfo()` (L1196)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `closeHomeInfo()` (L1226)
  - 呼出元: saveHomeInfo
  - 操作: getById

### `#houseSelectPanel`

- **[✅ 実行中]** `toggleHouseSelect()` (L1335)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `setHouseSystem()` (L1340)
  - 呼出元: なし
  - 操作: getById

### `#orbOverlay`

- **[✅ 実行中]** `openOrbOverlay()` (L1429)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `closeOrbOverlay()` (L1453)
  - 呼出元: saveOrbOverlay
  - 操作: getById

### `#tdShareCanvas`

- **[✅ 実行中]** `renderShareCard()` (L2316)
  - 呼出元: shareTitle
  - 操作: getById
- **[✅ 実行中]** `renderShareCardFallback()` (L2424)
  - 呼出元: shareTitle
  - 操作: getById

### `#titleDiagOverlay`

- **[✅ 実行中]** `startDiagnosis()` (L1879)
  - 呼出元: なし
  - 操作: getById
- **[✅ 実行中]** `closeDiagnosis()` (L1897)
  - 呼出元: acceptTitle
  - 操作: getById

---
## ❌ 未使用関数（削除候補）

> どのイベントハンドラからも到達できない関数。
> 古い実装の残骸の可能性が高い。

- `animBg()` — L896
  > メモ:（この関数が何だったか覚えていたら書く）

- `makeStars()` — L914
  - 操作対象: #starContainer, s.style
  > メモ:（この関数が何だったか覚えていたら書く）

---
## 🎯 エントリーポイント（操作の起点）

| 種類 | 関数 | 詳細 |
|------|------|------|
| HTML属性 | `openBirthInfo()` | openBirthInfo() |
| HTML属性 | `openHomeInfo()` | openHomeInfo() |
| HTML属性 | `startDiagnosis()` | startDiagnosis() |
| HTML属性 | `toggleHouseSelect()` | toggleHouseSelect() |
| HTML属性 | `setHouseSystem()` | setHouseSystem( |
| HTML属性 | `openOrbOverlay()` | openOrbOverlay() |
| HTML属性 | `closeBirthInfo()` | closeBirthInfo() |
| HTML属性 | `toggleTimeUnknown()` | toggleTimeUnknown() |
| HTML属性 | `searchBirthPlace()` | searchBirthPlace() |
| HTML属性 | `saveBirthInfo()` | saveBirthInfo() |
| HTML属性 | `resetOrbs()` | resetOrbs() |
| HTML属性 | `closeOrbOverlay()` | closeOrbOverlay() |
| HTML属性 | `saveOrbOverlay()` | saveOrbOverlay() |
| HTML属性 | `closeHomeInfo()` | closeHomeInfo() |
| HTML属性 | `searchHomePlace()` | searchHomePlace() |
| HTML属性 | `saveHomeInfo()` | saveHomeInfo() |
| HTML属性 | `beginRounds()` | beginRounds() |
| HTML属性 | `closeDiagnosis()` | closeDiagnosis() |
| HTML属性 | `acceptTitle()` | acceptTitle() |
| HTML属性 | `retryDiagnosis()` | retryDiagnosis() |
| HTML属性 | `shareTitle()` | shareTitle() |
| HTML属性 | `stepOrb()` | stepOrb(\ |
| HTML属性 | `updateOrbVal()` | updateOrbVal(\ |
| addEventListener | `positionDefaultMarks()` | resize |
| トップレベル呼出 | `renderProfileDisplay()` |  |
| トップレベル呼出 | `toggleTimeUnknown()` |  |
| トップレベル呼出 | `renderTitleDisplay()` |  |
| トップレベル呼出 | `closeBirthInfo()` |  |
| トップレベル呼出 | `closeHomeInfo()` |  |
| トップレベル呼出 | `initHouseUI()` |  |
| トップレベル呼出 | `updateOrbSummary()` |  |
| トップレベル呼出 | `closeOrbOverlay()` |  |
| トップレベル呼出 | `resetTD()` |  |
| トップレベル呼出 | `applyWildcard()` |  |
| トップレベル呼出 | `computeResults()` |  |
| トップレベル呼出 | `saveTitleData()` |  |
| トップレベル呼出 | `startForging()` |  |
| トップレベル呼出 | `startReveal()` |  |
| トップレベル呼出 | `closeDiagnosis()` |  |

---
## 📍 DOM要素と操作する関数の対応表

> 各DOM要素を「誰が」操作しているかの一覧。

- `#biBirthDate` ← `openBirthInfo()`, `saveBirthInfo()` ⚠️
- `#biBirthLat` ← `openBirthInfo()`, `setBirthMapLocation()`, `saveBirthInfo()` ⚠️
- `#biBirthLng` ← `openBirthInfo()`, `setBirthMapLocation()`, `saveBirthInfo()` ⚠️
- `#biBirthPlace` ← `openBirthInfo()`, `setBirthMapLocation()`, `searchBirthPlace()`, `saveBirthInfo()` ⚠️
- `#biBirthTime` ← `openBirthInfo()`, `toggleTimeUnknown()`, `saveBirthInfo()` ⚠️
- `#biMapResult` ← `openBirthInfo()`, `setBirthMapLocation()`, `searchBirthPlace()` ⚠️
- `#biMapSearchBtn` ← `searchBirthPlace()`
- `#biName` ← `openBirthInfo()`, `saveBirthInfo()` ⚠️
- `#biNoonHint` ← `toggleTimeUnknown()`
- `#biTimeUnknown` ← `openBirthInfo()`, `toggleTimeUnknown()`, `saveBirthInfo()` ⚠️
- `#birthOverlay` ← `openBirthInfo()`, `closeBirthInfo()` ⚠️
- `#hiHomeLat` ← `openHomeInfo()`, `setHomeMapLocation()`, `saveHomeInfo()` ⚠️
- `#hiHomeLng` ← `openHomeInfo()`, `setHomeMapLocation()`, `saveHomeInfo()` ⚠️
- `#hiHomeName` ← `openHomeInfo()`, `setHomeMapLocation()`, `searchHomePlace()`, `saveHomeInfo()` ⚠️
- `#hiMapResult` ← `openHomeInfo()`, `setHomeMapLocation()`, `searchHomePlace()` ⚠️
- `#hiMapSearchBtn` ← `searchHomePlace()`
- `#homeOverlay` ← `openHomeInfo()`, `closeHomeInfo()` ⚠️
- `#houseCheck_placidus` ← `initHouseUI()`
- `#houseCheck_whole_sign` ← `initHouseUI()`
- `#houseSelectPanel` ← `toggleHouseSelect()`, `setHouseSystem()` ⚠️
- `#houseSystemVal` ← `initHouseUI()`
- `#orbOverlay` ← `openOrbOverlay()`, `closeOrbOverlay()` ⚠️
- `#orbSummaryVal` ← `updateOrbSummary()`
- `#starContainer` ← `makeStars()`
- `#tdCards` ← `renderRound()`
- `#tdForgeOrb` ← `startForging()`
- `#tdForgeParticles` ← `startForging()`
- `#tdPartLabel` ← `renderRound()`
- `#tdPartTransText` ← `showRound()`
- `#tdProgressFill` ← `renderRound()`
- `#tdProgressText` ← `renderRound()`
- `#tdQuestion` ← `renderRound()`
- `#tdQuestionEN` ← `renderRound()`
- `#tdRetryBtn` ← `startReveal()`
- `#tdRevealActions` ← `startReveal()`
- `#tdRevealClass` ← `startReveal()`
- `#tdRevealLight` ← `startReveal()`
- `#tdRevealMain` ← `startReveal()`
- `#tdRevealMainEN` ← `startReveal()`
- `#tdRevealShadow` ← `startReveal()`
- `#tdScreenRound` ← `renderRound()`
- `#tdShareCanvas` ← `renderShareCard()`, `renderShareCardFallback()` ⚠️
- `#titleDiagOverlay` ← `startDiagnosis()`, `closeDiagnosis()` ⚠️
- `#titleNeedProfile` ← `renderTitleDisplay()`
- `#titleRediagnose` ← `renderTitleDisplay()`
- `#titleResultWrapper` ← `renderTitleDisplay()`
- `#titleStartBtn` ← `renderTitleDisplay()`
- `#vcardBgLight` ← `renderTitleDisplay()`
- `#vcardBgShadow` ← `renderTitleDisplay()`
- `#vcardClassIconLight` ← `renderTitleDisplay()`
- `#vcardClassIconShadow` ← `renderTitleDisplay()`
- `#vcardLightClassName` ← `renderTitleDisplay()`
- `#vcardLightDesc` ← `renderTitleDisplay()`
- `#vcardLightTitle` ← `renderTitleDisplay()`
- `#vcardOverlayLight` ← `renderTitleDisplay()`
- `#vcardOverlayShadow` ← `renderTitleDisplay()`
- `#vcardShadowClassName` ← `renderTitleDisplay()`
- `#vcardShadowDesc` ← `renderTitleDisplay()`
- `#vcardShadowTitle` ← `renderTitleDisplay()`
- `#vcardZodiacLight` ← `renderTitleDisplay()`
- `#vcardZodiacShadow` ← `renderTitleDisplay()`

---
## 📋 全関数一覧

### ❌ `animBg()` — L896
- 呼出先: なし
- 呼出元: なし

### ❌ `makeStars()` — L914
- 呼出先: なし
- 呼出元: なし
- DOM操作: #starContainer, s.style

### ✅ `loadProfile()` — L950
- 呼出先: なし
- 呼出元: computeResults, openBirthInfo, openHomeInfo, renderProfileDisplay, renderTitleDisplay, saveBirthInfo, saveHomeInfo, shareTitle, startDiagnosis

### ✅ `saveProfileData(p)` — L954
- 呼出先: なし
- 呼出元: saveBirthInfo, saveHomeInfo

### ✅ `renderProfileDisplay()` — L958
- 呼出先: formatDate, loadProfile
- 呼出元: saveBirthInfo, saveHomeInfo

### ✅ `formatDate(d)` — L977
- 呼出先: なし
- 呼出元: renderProfileDisplay

### ✅ `syncHomeToStorage(key, profile)` — L982
- 呼出先: なし
- 呼出元: syncHomeToVP

### ✅ `syncHomeToVP(profile)` — L995
- 呼出先: syncHomeToStorage
- 呼出元: saveHomeInfo

### ✅ `openBirthInfo()` — L1011
- 呼出先: loadProfile, setBirthMapLocation, toggleTimeUnknown
- 呼出元: なし
- DOM操作: #biBirthDate, #biBirthLat, #biBirthLng, #biBirthPlace, #biBirthTime, #biMapResult, #biName, #biTimeUnknown, #birthOverlay, res.textContent

### ✅ `closeBirthInfo()` — L1049
- 呼出先: なし
- 呼出元: saveBirthInfo
- DOM操作: #birthOverlay

### ✅ `toggleTimeUnknown()` — L1053
- 呼出先: なし
- 呼出元: openBirthInfo
- DOM操作: #biBirthTime, #biNoonHint, #biTimeUnknown, hint.classList

### ✅ `setBirthMapLocation(lat, lng, doReverse)` — L1067
- 呼出先: なし
- 呼出元: openBirthInfo, searchBirthPlace
- DOM操作: #biBirthLat, #biBirthLng, #biBirthPlace, #biMapResult, res.textContent

### ✅ `searchBirthPlace()` — L1105
- 呼出先: setBirthMapLocation
- 呼出元: なし
- DOM操作: #biBirthPlace, #biMapResult, #biMapSearchBtn, btn.textContent, res.textContent

### ✅ `saveBirthInfo()` — L1138
- 呼出先: closeBirthInfo, getMoonSign, getSunSign, loadProfile, renderProfileDisplay, renderTitleDisplay, saveProfileData
- 呼出元: なし
- DOM操作: #biBirthDate, #biBirthLat, #biBirthLng, #biBirthPlace, #biBirthTime, #biName, #biTimeUnknown

### ✅ `openHomeInfo()` — L1196
- 呼出先: loadProfile, setHomeMapLocation
- 呼出元: なし
- DOM操作: #hiHomeLat, #hiHomeLng, #hiHomeName, #hiMapResult, #homeOverlay, res.textContent

### ✅ `closeHomeInfo()` — L1226
- 呼出先: なし
- 呼出元: saveHomeInfo
- DOM操作: #homeOverlay

### ✅ `setHomeMapLocation(lat, lng, doReverse)` — L1230
- 呼出先: なし
- 呼出元: openHomeInfo, searchHomePlace
- DOM操作: #hiHomeLat, #hiHomeLng, #hiHomeName, #hiMapResult, res.textContent

### ✅ `searchHomePlace()` — L1268
- 呼出先: setHomeMapLocation
- 呼出元: なし
- DOM操作: #hiHomeName, #hiMapResult, #hiMapSearchBtn, btn.textContent, res.textContent

### ✅ `saveHomeInfo()` — L1301
- 呼出先: closeHomeInfo, loadProfile, renderProfileDisplay, saveProfileData, syncHomeToVP
- 呼出元: なし
- DOM操作: #hiHomeLat, #hiHomeLng, #hiHomeName

### ✅ `initHouseUI()` — L1329
- 呼出先: なし
- 呼出元: setHouseSystem
- DOM操作: #houseCheck_placidus, #houseCheck_whole_sign, #houseSystemVal

### ✅ `toggleHouseSelect()` — L1335
- 呼出先: なし
- 呼出元: なし
- DOM操作: #houseSelectPanel, panel.style

### ✅ `setHouseSystem(val)` — L1340
- 呼出先: initHouseUI
- 呼出元: なし
- DOM操作: #houseSelectPanel

### ✅ `buildOrbRows(container, items, store, storeKey)` — L1390
- 呼出先: formatOrbVal, stepOrb, updateOrbVal
- 呼出元: openOrbOverlay, resetOrbs

### ✅ `formatOrbVal(v)` — L1409
- 呼出先: なし
- 呼出元: buildOrbRows, stepOrb

### ✅ `resetOrbs()` — L1411
- 呼出先: buildOrbRows
- 呼出元: なし

### ✅ `stepOrb(storeKey, key, delta)` — L1419
- 呼出先: formatOrbVal
- 呼出元: buildOrbRows

### ✅ `openOrbOverlay()` — L1429
- 呼出先: buildOrbRows
- 呼出元: なし
- DOM操作: #orbOverlay

### ✅ `positionDefaultMarks()` — L1438
- 呼出先: なし
- 呼出元: なし
- DOM操作: .orb-default-mark, mark.style

### ✅ `closeOrbOverlay()` — L1453
- 呼出先: なし
- 呼出元: saveOrbOverlay
- DOM操作: #orbOverlay

### ✅ `updateOrbVal(storeKey, key, val)` — L1457
- 呼出先: なし
- 呼出元: buildOrbRows

### ✅ `saveOrbOverlay()` — L1468
- 呼出先: closeOrbOverlay, updateOrbSummary
- 呼出元: なし

### ✅ `updateOrbSummary()` — L1475
- 呼出先: なし
- 呼出元: saveOrbOverlay
- DOM操作: #orbSummaryVal

### ✅ `getSunSign(dateStr)` — L1816
- 呼出先: なし
- 呼出元: computeResults, saveBirthInfo, shareTitle

### ✅ `getMoonSign(dateStr, timeStr)` — L1828
- 呼出先: なし
- 呼出元: computeResults, saveBirthInfo, shareTitle

### ✅ `resetTD()` — L1860
- 呼出先: なし
- 呼出元: closeDiagnosis, retryDiagnosis, startDiagnosis

### ✅ `showTDScreen(id)` — L1873
- 呼出先: なし
- 呼出元: beginRounds, retryDiagnosis, showRound, startDiagnosis, startForging, startReveal
- DOM操作: .td-screen

### ✅ `startDiagnosis()` — L1879
- 呼出先: loadProfile, resetTD, showTDScreen
- 呼出元: なし
- DOM操作: #titleDiagOverlay

### ✅ `closeDiagnosis()` — L1897
- 呼出先: resetTD
- 呼出元: acceptTitle
- DOM操作: #titleDiagOverlay

### ✅ `beginRounds()` — L1902
- 呼出先: showRound, showTDScreen
- 呼出元: なし

### ✅ `showRound(idx)` — L1910
- 呼出先: renderRound, showTDScreen
- 呼出元: beginRounds, retryDiagnosis, selectCard
- DOM操作: #tdPartTransText

### ✅ `renderRound(idx, r, displayNum)` — L1929
- 呼出先: animateCardsIn, getLeadingAxis, selectCard
- 呼出元: showRound
- DOM操作: #tdCards, #tdPartLabel, #tdProgressFill, #tdProgressText, #tdQuestion, #tdQuestionEN, #tdScreenRound, container.innerHTML, roundScreen.classList

### ✅ `animateCardsIn()` — L1975
- 呼出先: なし
- 呼出元: renderRound
- DOM操作: .td-card, el.classList

### ✅ `selectCard(roundIdx, cardIdx)` — L1984
- 呼出先: applyWildcard, computeResults, showRound
- 呼出元: renderRound
- DOM操作: .td-card

### ✅ `getLeadingAxis()` — L2023
- 呼出先: なし
- 呼出元: renderRound

### ✅ `applyWildcard()` — L2038
- 呼出先: なし
- 呼出元: selectCard

### ✅ `determineFinalAxis()` — L2052
- 呼出先: なし
- 呼出元: computeResults

### ✅ `determineCourt()` — L2074
- 呼出先: なし
- 呼出元: computeResults

### ✅ `computeResults()` — L2086
- 呼出先: determineCourt, determineFinalAxis, getMoonSign, getSunSign, loadProfile, saveTitleData, startForging
- 呼出元: selectCard

### ✅ `saveTitleData()` — L2109
- 呼出先: なし
- 呼出元: computeResults

### ✅ `loadTitleData()` — L2121
- 呼出先: なし
- 呼出元: renderTitleDisplay, shareTitle

### ✅ `startForging()` — L2132
- 呼出先: showTDScreen, startReveal
- 呼出元: computeResults
- DOM操作: #tdForgeOrb, #tdForgeParticles, container.innerHTML, orb.style, p.style

### ✅ `startReveal()` — L2168
- 呼出先: showTDScreen
- 呼出元: startForging
- DOM操作: #tdRetryBtn, #tdRevealActions, #tdRevealClass, #tdRevealLight, #tdRevealMain, #tdRevealMainEN, #tdRevealShadow, .td-reveal-line

### ✅ `acceptTitle()` — L2193
- 呼出先: closeDiagnosis, renderTitleDisplay
- 呼出元: なし

### ✅ `retryDiagnosis()` — L2198
- 呼出先: resetTD, showRound, showTDScreen
- 呼出元: なし
- DOM操作: .td-reveal-main,.td-reveal-main-en,.td-reveal-line,.td-reveal-class,.td-reveal-light,.td-reveal-shadow,.td-reveal-actions

### ✅ `loadShareImage(src)` — L2257
- 呼出先: なし
- 呼出元: shareTitle

### ✅ `shareTitle()` — L2268
- 呼出先: determineFinalAxisFromScores, getMoonSign, getSunSign, loadProfile, loadShareImage, loadTitleData, renderShareCard, renderShareCardFallback
- 呼出元: なし
- DOM操作: .td-share-btn, shareBtn.textContent

### ✅ `renderShareCard(bgImg, classImg, sunImg, moonImg, info)` — L2316
- 呼出先: downloadCanvas, drawCover
- 呼出元: shareTitle
- DOM操作: #tdShareCanvas

### ✅ `renderShareCardFallback(data, cls, txt, axis, sunSign, moonSign, axisStyle)` — L2424
- 呼出先: downloadCanvas
- 呼出元: shareTitle
- DOM操作: #tdShareCanvas

### ✅ `drawCover(ctx, img, w, h)` — L2484
- 呼出先: なし
- 呼出元: renderShareCard

### ✅ `downloadCanvas(canvas)` — L2502
- 呼出先: なし
- 呼出元: renderShareCard, renderShareCardFallback

### ✅ `determineFinalAxisFromScores(scores)` — L2509
- 呼出先: なし
- 呼出元: renderTitleDisplay, shareTitle

### ✅ `renderTitleDisplay()` — L2528
- 呼出先: determineFinalAxisFromScores, loadProfile, loadTitleData
- 呼出元: acceptTitle, saveBirthInfo
- DOM操作: #titleNeedProfile, #titleRediagnose, #titleResultWrapper, #titleStartBtn, #vcardBgLight, #vcardBgShadow, #vcardClassIconLight, #vcardClassIconShadow, #vcardLightClassName, #vcardLightDesc, #vcardLightTitle, #vcardOverlayLight, #vcardOverlayShadow, #vcardShadowClassName, #vcardShadowDesc, #vcardShadowTitle, #vcardZodiacLight, #vcardZodiacShadow, wrapper.classList, wrapper.style
