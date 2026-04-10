# Map（世界地図・運勢方位） — 機能分析レポート

**ソース**: `mockup/index.html`
**関数総数**: 65個
**エントリーポイント**: 55個
**到達可能な関数**: 60個
**到達不可能（未使用候補）**: 5個
**DOM操作の重複箇所**: 0箇所

---
## ⚠️ 同じ場所を操作する関数（重複候補）

（重複なし）

---
## ❌ 未使用関数（削除候補）

> どのイベントハンドラからも到達できない関数。
> 古い実装の残骸の可能性が高い。

- `tripleChart()` — L1584
  > メモ:（この関数が何だったか覚えていたら書く）

- `hs(y)` — L2386
  > メモ:（この関数が何だったか覚えていたら書く）

- `he(y)` — L2386
  > メモ:（この関数が何だったか覚えていたら書く）

- `SlotManager(cfg)` — L2400
  > メモ:（この関数が何だったか覚えていたら書く）

- `vpMsg(txt)` — L2559
  - 操作対象: .vp-msg, m.textContent
  > メモ:（この関数が何だったか覚えていたら書く）

---
## 🎯 エントリーポイント（操作の起点）

| 種類 | 関数 | 詳細 |
|------|------|------|
| HTML属性 | `restart()` | restart() |
| HTML属性 | `openSearch()` | openSearch() |
| HTML属性 | `doSearch()` | doSearch() |
| HTML属性 | `closeSR()` | closeSR() |
| HTML属性 | `toggleVP()` | toggleVP() |
| HTML属性 | `switchVPTab()` | switchVPTab( |
| HTML属性 | `vpGeo()` | vpGeo() |
| HTML属性 | `vpSave()` | vpSave() |
| HTML属性 | `locSave()` | locSave() |
| HTML属性 | `toggleLP()` | toggleLP() |
| HTML属性 | `toggleLT()` | toggleLT(this) |
| HTML属性 | `toggleGT()` | toggleGT(this) |
| HTML属性 | `setFortune()` | setFortune( |
| HTML属性 | `toggleFS()` | toggleFS() |
| HTML属性 | `if()` | if(fsOpen)toggleFS() |
| HTML属性 | `switchSrc()` | switchSrc( |
| HTML属性 | `switchCat()` | switchCat( |
| HTML属性 | `switchSRTab()` | switchSRTab(this) |
| HTML属性 | `flashSec()` | flashSec(\ |
| addEventListener | `closeLPOut()` | pointerdown |
| addEventListener | `dismissVeil()` | pointerdown |
| addEventListener | `init()` | resize |
| トップレベル呼出 | `addPlanetLines()` |  |
| トップレベル呼出 | `createSectors()` |  |
| トップレベル呼出 | `updateFFLabel()` |  |
| トップレベル呼出 | `applyVis()` |  |
| トップレベル呼出 | `vpRender()` |  |
| トップレベル呼出 | `updateSymPos()` |  |
| トップレベル呼出 | `startAnim()` |  |
| トップレベル呼出 | `init()` |  |

---
## 📍 DOM要素と操作する関数の対応表

> 各DOM要素を「誰が」操作しているかの一覧。

- `#mapWrap` ← `init()`
- `#particleCanvas` ← `init()`

---
## 📋 全関数一覧

### ✅ `emptyComp()` — L1501
- 呼出先: なし
- 呼出元: getActiveScores, renderFS, scoreAll, updateFFLabel

### ❌ `tripleChart()` — L1584
- 呼出先: なし
- 呼出元: なし

### ✅ `qBucket(q)` — L1613
- 呼出先: なし
- 呼出元: scoreAll

### ✅ `cosFall(dist,spread)` — L1614
- 呼出先: なし
- 呼出元: scoreAll

### ✅ `findAspects(map1,map2,wMult,prefix)` — L1617
- 呼出先: なし
- 呼出元: scoreAll

### ✅ `scoreAll()` — L1636
- 呼出先: angleBonus, cosFall, emptyComp, findAspects, isAngleKey, qBucket
- 呼出元: init, rebuild

### ✅ `angleBonus(p2key)` — L1654
- 呼出先: なし
- 呼出元: scoreAll

### ✅ `isAngleKey(k)` — L1666
- 呼出先: なし
- 呼出元: scoreAll

### ✅ `normLng(ptLng,refLng)` — L1731
- 呼出先: なし
- 呼出元: buildCompass, buildSectorPts, turfLine

### ✅ `turfLine(center,bearing,maxKm,steps)` — L1733
- 呼出先: normLng
- 呼出元: addPlanetLines, buildCompass

### ✅ `clampLat(l)` — L1740
- 呼出先: なし
- 呼出元: buildSectorPts

### ✅ `init()` — L1747
- 呼出先: addPlanetLines, applyVis, buildCompass, createSectors, rebuild, scoreAll, updateFFLabel, vpLoadLast, vpRender
- 呼出元: なし
- DOM操作: #mapWrap, #particleCanvas, c.style

### ✅ `buildCompass(center)` — L1792
- 呼出先: normLng, turfLine
- 呼出元: init, rebuild

### ✅ `rebuild(nc,fly)` — L1821
- 呼出先: addPlanetLines, applyVis, buildCompass, createSectors, scoreAll, updateFFLabel, vpRender, vpSaveLast
- 呼出元: init, vpGeo

### ✅ `getSectorColor()` — L1850
- 呼出先: なし
- 呼出元: scoreToStyle

### ✅ `scoreToStyle(score,rank,clr)` — L1854
- 呼出先: getSectorColor
- 呼出元: applyVis, createSectors, flashSec

### ✅ `computeRanks(scores)` — L1861
- 呼出先: なし
- 呼出元: applyVis, createSectors, flashSec

### ✅ `createSectors()` — L1866
- 呼出先: buildSectorPts, computeRanks, scoreToStyle
- 呼出元: init, onImpact, rebuild

### ✅ `buildSectorPts(cp,startB,endB,radius,refLng)` — L1910
- 呼出先: clampLat, normLng
- 呼出元: createSectors

### ✅ `addPlanetLines()` — L1932
- 呼出先: turfLine, updateSymPos
- 呼出元: init, onImpact, rebuild

### ✅ `updateSymPos()` — L1964
- 呼出先: なし
- 呼出元: addPlanetLines

### ✅ `Particle(x,y,vx,vy,color,size,life,decay)` — L2009
- 呼出先: なし
- 呼出元: spawnConverge

### ✅ `spawnConverge(tx,ty,n)` — L2014
- 呼出先: Particle, startAnim
- 呼出元: onImpact

### ✅ `startAnim()` — L2023
- 呼出先: animate
- 呼出元: onImpact, spawnConverge

### ✅ `animate()` — L2024
- 呼出先: drawSparkles, onImpact, playEffect
- 呼出元: startAnim

### ✅ `drawSparkles(ctx)` — L2060
- 呼出先: なし
- 呼出元: animate

### ✅ `onImpact(x,y)` — L2097
- 呼出先: addPlanetLines, createSectors, spawnConverge, startAnim
- 呼出元: animate
- DOM操作: fl.style

### ✅ `playEffect(x,y)` — L2117
- 呼出先: なし
- 呼出元: animate
- DOM操作: v.classList, v.style

### ✅ `openSearch()` — L2130
- 呼出先: なし
- 呼出元: なし

### ✅ `closeSearch()` — L2131
- 呼出先: なし
- 呼出元: doSearch, restart

### ✅ `doSearch()` — L2135
- 呼出先: closeSearch, detectSector, showSR
- 呼出元: なし

### ✅ `detectSector(lat,lng)` — L2148
- 呼出先: なし
- 呼出元: doSearch

### ✅ `showSR(name,msg,type,dir)` — L2215
- 呼出先: showSRAdvice, switchSRTab
- 呼出元: doSearch
- DOM操作: s.style, s.textContent, tabs.innerHTML

### ✅ `switchSRTab(el)` — L2228
- 呼出先: showSRAdvice
- 呼出元: showSR
- DOM操作: .sr-tab, el.classList, t.classList

### ✅ `showSRAdvice(cat)` — L2234
- 呼出先: なし
- 呼出元: showSR, switchSRTab
- DOM操作: adv.textContent

### ✅ `closeSR()` — L2244
- 呼出先: なし
- 呼出元: なし

### ✅ `toggleLP()` — L2252
- 呼出先: なし
- 呼出元: なし
- DOM操作: b.classList, p.classList

### ✅ `closeLPOut(e)` — L2254
- 呼出先: なし
- 呼出元: なし
- DOM操作: b.classList, p.classList

### ✅ `toggleLT(el)` — L2255
- 呼出先: applyVis
- 呼出元: なし
- DOM操作: el.classList

### ✅ `toggleGT(el)` — L2256
- 呼出先: applyVis
- 呼出元: なし
- DOM操作: el.classList

### ✅ `setFortune(cat)` — L2258
- 呼出先: applyVis
- 呼出元: なし
- DOM操作: .fp-item, el.classList, ov.classList

### ✅ `applyVis()` — L2270
- 呼出先: computeRanks, getActiveScores, scoreToStyle
- 呼出元: init, rebuild, setFortune, switchCat, switchSrc, toggleGT, toggleLT

### ✅ `getActiveScores()` — L2302
- 呼出先: emptyComp
- 呼出元: applyVis, flashSec

### ✅ `toggleFS()` — L2312
- 呼出先: renderFS
- 呼出元: flashSec, he

### ✅ `switchSrc(tab)` — L2318
- 呼出先: applyVis, renderFS, updateFFLabel
- 呼出元: なし
- DOM操作: #fsSrcTabs .fs-tab, el.classList, lg.innerHTML

### ✅ `switchCat(tab)` — L2328
- 呼出先: applyVis, renderFS, updateFFLabel
- 呼出元: なし
- DOM操作: #fsCatTabs .fs-tab, el.classList

### ✅ `renderFS()` — L2333
- 呼出先: emptyComp, flashSec, pct
- 呼出元: switchCat, switchSrc, toggleFS
- DOM操作: body.innerHTML

### ✅ `pct(v)` — L2339
- 呼出先: なし
- 呼出元: renderFS

### ✅ `flashSec(dir)` — L2357
- 呼出先: computeRanks, getActiveScores, scoreToStyle, toggleFS
- 呼出元: renderFS

### ✅ `updateFFLabel()` — L2370
- 呼出先: emptyComp
- 呼出元: init, rebuild, switchCat, switchSrc
- DOM操作: bars.innerHTML, tag.textContent

### ❌ `hs(y)` — L2386
- 呼出先: なし
- 呼出元: なし

### ❌ `he(y)` — L2386
- 呼出先: toggleFS
- 呼出元: なし

### ❌ `SlotManager(cfg)` — L2400
- 呼出先: なし
- 呼出元: なし

### ✅ `vpLoadLast()` — L2545
- 呼出先: なし
- 呼出元: init

### ✅ `vpSaveLast(c)` — L2546
- 呼出先: なし
- 呼出元: rebuild

### ✅ `toggleVP()` — L2548
- 呼出先: vpRender
- 呼出元: なし
- DOM操作: b.classList, p.classList

### ✅ `vpGeo()` — L2551
- 呼出先: rebuild
- 呼出元: なし

### ✅ `vpSave()` — L2556
- 呼出先: なし
- 呼出元: なし

### ✅ `locSave()` — L2557
- 呼出先: なし
- 呼出元: なし

### ❌ `vpMsg(txt)` — L2559
- 呼出先: なし
- 呼出元: なし
- DOM操作: .vp-msg, m.textContent

### ✅ `vpRender()` — L2566
- 呼出先: なし
- 呼出元: init, rebuild, switchVPTab, toggleVP
- DOM操作: coord.textContent

### ✅ `locRender()` — L2570
- 呼出先: なし
- 呼出元: switchVPTab

### ✅ `switchVPTab(tab)` — L2572
- 呼出先: locRender, vpRender
- 呼出元: なし
- DOM操作: .vp-tab, t.classList

### ✅ `restart()` — L2585
- 呼出先: closeSearch
- 呼出元: なし
- DOM操作: v.classList

### ✅ `dismissVeil()` — L2599
- 呼出先: なし
- 呼出元: なし
- DOM操作: p.classList, v.classList
