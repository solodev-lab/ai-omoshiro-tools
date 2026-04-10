# Galaxy（銀河・星座） — 機能分析レポート

**ソース**: `mockup/galaxy.html`
**関数総数**: 38個
**エントリーポイント**: 18個
**到達可能な関数**: 24個
**到達不可能（未使用候補）**: 14個
**DOM操作の重複箇所**: 6箇所

---
## ⚠️ 同じ場所を操作する関数（重複候補）

> 同じDOM要素を複数の関数が操作している箇所。
> 古い方を削除するか、統合を検討してください。

### `#dotPopup`

- **[✅ 実行中]** `showDotPopup()` (L1554)
  - 呼出元: initSpiral3D
  - 操作: getById
- **[✅ 実行中]** `hideDotPopup()` (L1586)
  - 呼出元: initSpiral3D, showDotPopup
  - 操作: getById

### `#replayDate`

- **[✅ 実行中]** `openReplayModal()` (L1716)
  - 呼出元: renderGalaxyCards
  - 操作: getById
- **[✅ 実行中]** `anim()` (L1733)
  - 呼出元: openReplayModal
  - 操作: getById

### `#replayModal`

- **[✅ 実行中]** `openReplayModal()` (L1716)
  - 呼出元: renderGalaxyCards
  - 操作: getById
- **[✅ 実行中]** `closeReplayModal()` (L1751)
  - 呼出元: なし
  - 操作: getById

### `#replayName`

- **[✅ 実行中]** `openReplayModal()` (L1716)
  - 呼出元: renderGalaxyCards
  - 操作: getById
- **[✅ 実行中]** `anim()` (L1733)
  - 呼出元: openReplayModal
  - 操作: getById

### `#replaySymbol`

- **[✅ 実行中]** `openReplayModal()` (L1716)
  - 呼出元: renderGalaxyCards
  - 操作: getById
- **[✅ 実行中]** `anim()` (L1733)
  - 呼出元: openReplayModal
  - 操作: getById

### `#spiralCanvas`

- **[✅ 実行中]** `renderSpiral3D()` (L1335)
  - 呼出元: startSpiral3D, loop
  - 操作: getById
- **[✅ 実行中]** `initSpiral3D()` (L1500)
  - 呼出元: なし
  - 操作: getById

---
## ❌ 未使用関数（削除候補）

> どのイベントハンドラからも到達できない関数。
> 古い実装の残骸の可能性が高い。

- `mulberry32(a)` — L636
  > メモ:（この関数が何だったか覚えていたら書く）

- `getMoonCycleInfo()` — L654
  > メモ:（この関数が何だったか覚えていたら書く）

- `generateDaysData(total, active)` — L671
  > メモ:（この関数が何だったか覚えていたら書く）

- `getTemplatePositions(nounIdx, numAnchors, seed)` — L998
  > メモ:（この関数が何だったか覚えていたら書く）

- `placeCycleDots(majors, minors, nounIdx, seedCard, id)` — L1061
  > メモ:（この関数が何だったか覚えていたら書く）

- `forceNameDemoCycle(id, seedCard, readings, forceAdjIdx, forceNounIdx)` — L1097
  > メモ:（この関数が何だったか覚えていたら書く）

- `makeDemoReadings(seedCard, count, seed, minMajor)` — L1122
  > メモ:（この関数が何だったか覚えていたら書く）

- `preloadConstellationArt()` — L1187
  > メモ:（この関数が何だったか覚えていたら書く）

- `animBg()` — L1209
  > メモ:（この関数が何だったか覚えていたら書く）

- `makeStars()` — L1227
  - 操作対象: #starContainer, s.style
  > メモ:（この関数が何だったか覚えていたら書く）

- `updateMoonBadge()` — L1243
  - 操作対象: #dayLbl, #dayNum, #moonEmoji, #moonLabel, dayLblEl.textContent, dayNumEl.textContent, emojiEl.textContent, lblEl.textContent
  > メモ:（この関数が何だったか覚えていたら書く）

- `precomputeGoldenAnglePositions()` — L1298
  > メモ:（この関数が何だったか覚えていたら書く）

- `loadDailyVibes()` — L1787
  > メモ:（この関数が何だったか覚えていたら書く）

- `saveDailyVibe(score)` — L1791
  > メモ:（この関数が何だったか覚えていたら書く）

---
## 🎯 エントリーポイント（操作の起点）

| 種類 | 関数 | 詳細 |
|------|------|------|
| HTML属性 | `switchInner()` | switchInner( |
| HTML属性 | `closeFormationOverlay()` | closeFormationOverlay() |
| HTML属性 | `closeReplayModal()` | closeReplayModal() |
| addEventListener | `e()` | click |
| トップレベル呼出 | `renderSpiral3D()` |  |
| トップレベル呼出 | `loop()` |  |
| トップレベル呼出 | `anim()` |  |
| トップレベル呼出 | `renderGalaxyCards()` |  |
| トップレベル呼出 | `loadSavedCycles()` |  |
| トップレベル呼出 | `initSpiral3D()` |  |
| トップレベル呼出 | `startSpiral3D()` |  |

---
## 📍 DOM要素と操作する関数の対応表

> 各DOM要素を「誰が」操作しているかの一覧。

- `#dayLbl` ← `updateMoonBadge()`
- `#dayNum` ← `updateMoonBadge()`
- `#dotPopup` ← `showDotPopup()`, `hideDotPopup()` ⚠️
- `#galaxyGrid` ← `renderGalaxyCards()`
- `#moonEmoji` ← `updateMoonBadge()`
- `#moonLabel` ← `updateMoonBadge()`
- `#overlayFormation` ← `closeFormationOverlay()`
- `#popupCardName` ← `showDotPopup()`
- `#popupDay` ← `showDotPopup()`
- `#popupEmoji` ← `showDotPopup()`
- `#popupKeyword` ← `showDotPopup()`
- `#popupPlanet` ← `showDotPopup()`
- `#popupQuote` ← `showDotPopup()`
- `#replayCanvas` ← `openReplayModal()`
- `#replayDate` ← `openReplayModal()`, `anim()` ⚠️
- `#replayModal` ← `openReplayModal()`, `closeReplayModal()` ⚠️
- `#replayName` ← `openReplayModal()`, `anim()` ⚠️
- `#replaySubtitle` ← `openReplayModal()`
- `#replaySymbol` ← `openReplayModal()`, `anim()` ⚠️
- `#replayTitle` ← `openReplayModal()`
- `#spiralCanvas` ← `renderSpiral3D()`, `initSpiral3D()` ⚠️
- `#starContainer` ← `makeStars()`

---
## 📋 全関数一覧

### ❌ `mulberry32(a)` — L636
- 呼出先: なし
- 呼出元: getTemplatePositions, makeDemoReadings, placeCycleDots, precomputeGoldenAnglePositions

### ❌ `getMoonCycleInfo()` — L654
- 呼出先: なし
- 呼出元: なし

### ❌ `generateDaysData(total, active)` — L671
- 呼出先: なし
- 呼出元: なし

### ✅ `cardToColor(dd)` — L716
- 呼出先: なし
- 呼出元: renderSpiral3D

### ✅ `hexToRgba(hex, alpha)` — L729
- 呼出先: なし
- 呼出元: drawCycleOnCanvas, forceNameDemoCycle, renderSpiral3D

### ✅ `rarityStarsHTML(stars)` — L794
- 呼出先: なし
- 呼出元: openReplayModal, renderGalaxyCards

### ✅ `computeMST(points)` — L818
- 呼出先: なし
- 呼出元: buildConstellationEdges

### ✅ `buildConstellationEdges(anchorPoints, shapeType)` — L850
- 呼出先: computeMST
- 呼出元: drawCycleOnCanvas

### ❌ `getTemplatePositions(nounIdx, numAnchors, seed)` — L998
- 呼出先: mulberry32
- 呼出元: placeCycleDots

### ❌ `placeCycleDots(majors, minors, nounIdx, seedCard, id)` — L1061
- 呼出先: getTemplatePositions, mulberry32
- 呼出元: forceNameDemoCycle

### ❌ `forceNameDemoCycle(id, seedCard, readings, forceAdjIdx, forceNounIdx)` — L1097
- 呼出先: hexToRgba, placeCycleDots
- 呼出元: なし

### ❌ `makeDemoReadings(seedCard, count, seed, minMajor)` — L1122
- 呼出先: mulberry32
- 呼出元: なし

### ❌ `preloadConstellationArt()` — L1187
- 呼出先: なし
- 呼出元: なし

### ❌ `animBg()` — L1209
- 呼出先: なし
- 呼出元: なし

### ❌ `makeStars()` — L1227
- 呼出先: なし
- 呼出元: なし
- DOM操作: #starContainer, s.style

### ❌ `updateMoonBadge()` — L1243
- 呼出先: なし
- 呼出元: なし
- DOM操作: #dayLbl, #dayNum, #moonEmoji, #moonLabel, dayLblEl.textContent, dayNumEl.textContent, emojiEl.textContent, lblEl.textContent

### ✅ `switchInner(tab)` — L1262
- 呼出先: startSpiral3D
- 呼出元: closeFormationOverlay
- DOM操作: .inner-tab-btn, b.classList

### ✅ `rot3D(x, y, z)` — L1280
- 呼出先: なし
- 呼出元: projectGA3D, renderSpiral3D

### ✅ `proj3D(x, y, z, fov, cx, cy)` — L1288
- 呼出先: なし
- 呼出元: renderSpiral3D

### ❌ `precomputeGoldenAnglePositions()` — L1298
- 呼出先: mulberry32
- 呼出元: なし

### ✅ `projectGA3D(nx, ny, nz, W, H, cx, cy, camAngle, FOV)` — L1323
- 呼出先: rot3D
- 呼出元: renderSpiral3D

### ✅ `renderSpiral3D()` — L1335
- 呼出先: cardToColor, hexToRgba, proj3D, projectGA3D, rot3D
- 呼出元: loop, startSpiral3D
- DOM操作: #spiralCanvas

### ✅ `startSpiral3D()` — L1490
- 呼出先: loop, renderSpiral3D
- 呼出元: switchInner

### ✅ `loop()` — L1491
- 呼出先: renderSpiral3D
- 呼出元: startSpiral3D

### ✅ `initSpiral3D()` — L1500
- 呼出先: hideDotPopup, showDotPopup
- 呼出元: なし
- DOM操作: #spiralCanvas, c.style, canvas.style

### ✅ `showDotPopup(day, px, py, canvas)` — L1554
- 呼出先: hideDotPopup
- 呼出元: initSpiral3D
- DOM操作: #dotPopup, #popupCardName, #popupDay, #popupEmoji, #popupKeyword, #popupPlanet, #popupQuote, popup.classList, popup.style

### ✅ `hideDotPopup()` — L1586
- 呼出先: なし
- 呼出元: initSpiral3D, showDotPopup
- DOM操作: #dotPopup

### ✅ `projectConstellation3D(nx, ny, nz, S, camAngle)` — L1594
- 呼出先: なし
- 呼出元: drawCycleOnCanvas

### ✅ `drawCycleOnCanvas(canvas, cycle, progress, size, camAngle)` — L1609
- 呼出先: buildConstellationEdges, hexToRgba, projectConstellation3D
- 呼出元: anim, openReplayModal, renderGalaxyCards

### ✅ `renderGalaxyCards()` — L1683
- 呼出先: drawCycleOnCanvas, openReplayModal, rarityStarsHTML
- 呼出元: closeFormationOverlay
- DOM操作: #galaxyGrid, canvas.style, card.style, grid.innerHTML, meta.innerHTML

### ✅ `openReplayModal(cycleId)` — L1716
- 呼出先: anim, drawCycleOnCanvas, rarityStarsHTML
- 呼出元: renderGalaxyCards
- DOM操作: #replayCanvas, #replayDate, #replayModal, #replayName, #replaySubtitle, #replaySymbol, #replayTitle

### ✅ `anim()` — L1733
- 呼出先: drawCycleOnCanvas
- 呼出元: openReplayModal
- DOM操作: #replayDate, #replayName, #replaySymbol

### ✅ `closeReplayModal()` — L1751
- 呼出先: なし
- 呼出元: なし
- DOM操作: #replayModal

### ✅ `closeFormationOverlay()` — L1763
- 呼出先: renderGalaxyCards, saveCycles, switchInner
- 呼出元: なし
- DOM操作: #overlayFormation

### ❌ `loadDailyVibes()` — L1787
- 呼出先: なし
- 呼出元: saveDailyVibe

### ❌ `saveDailyVibe(score)` — L1791
- 呼出先: loadDailyVibes
- 呼出元: なし

### ✅ `loadSavedCycles()` — L1801
- 呼出先: なし
- 呼出元: なし

### ✅ `saveCycles()` — L1816
- 呼出先: なし
- 呼出元: closeFormationOverlay
