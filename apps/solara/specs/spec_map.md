# Map（世界地図・運勢方位）

**ソースファイル**: `mockup/index.html`
**HTML行数**: 2625行（うちJS約2615行）
**イベント数**: 60個
**API呼び出し**: 2箇所

---
## この画面の説明（日本語メモ）

> ここにオーナーが日本語で画面の説明を書く。
> 例：「世界地図が表示される。タップした場所の運勢が見れる。」

---
## 要素一覧（HTML上から順）

1. `<div #phone>`
  CSS: width:100%; height:100vh; min-height:100vh; background:#080C14; position:relative; overflow:hidden
  2. `<div .status-bar>` — テキスト:「SOLARA」
    CSS: height:44px; font-size:12px; font-weight:700; color:rgba(234,234,234,0.9); padding:0 28px; position:fixed
  3. `<button .replay>` — テキスト:「REPLAY」
    CSS: font-size:10px; color:#666; background:rgba(255,255,255,.05); padding:6px 14px; border-radius:20px; position:absolute
  4. `<div #searchTrigger>`
    CSS: width:40px; height:40px; font-size:18px; color:rgba(201,168,76,.6); background:rgba(10,10,25,.8); border-radius:50%
    5. `<svg>`
      6. `<circle>`
      7. `<line>`
  8. `<div #searchBar>`
    CSS: position:absolute; top:82px; left:16px; right:16px; display:none; gap:6px
    9. `<div>`
      10. `<input #searchInput>`
        CSS: width:100%; font-size:13px; color:#E8E0D0; background:rgba(15,15,30,.9); padding:10px 36px 10px 14px; border-radius:10px
      11. `<button .search-btn>`
        CSS: font-size:16px; color:rgba(201,168,76,.5); background:none; padding:4px 6px; position:absolute; top:50%
  12. `<div #ffLabel>`
    CSS: font-size:10px; color:#C9A84C; background:rgba(10,10,20,.7); padding:3px 10px; border-radius:10px; position:absolute
    13. `<span #ffTag>` — テキスト:「合計 / 総合」
    14. `<div #ffBars>`
      CSS: display:flex; flex-direction:column; gap:2px
  15. `<div #srPopup>`
    CSS: background:rgba(15,15,30,.85); padding:14px 16px; border-radius:12px; position:absolute; left:16px; right:16px
    16. `<button .sr-close>` — テキスト:「✕」
      CSS: font-size:16px; color:#555; background:none; position:absolute; top:8px; right:12px
    17. `<div #srName>`
      CSS: font-size:13px; color:#E8E0D0
    18. `<div #srSector>`
      CSS: font-size:12px
    19. `<div #srTabs>`
      CSS: display:flex; gap:0
    20. `<div #srAdvice>`
      CSS: min-height:32px; font-size:11px; color:rgba(232,224,208,.85)
  21. `<div #stella>`
    CSS: background:rgba(15,15,30,.75); padding:16px 20px; border-radius:16px; position:absolute; left:20px; right:20px
    22. `<div .stella-name>` — テキスト:「✨ Stella」
      CSS: font-size:10px; color:#6B5CE7
    23. `<div #stellaText>`
      CSS: font-size:13px
      24. `<span .hl>` — テキスト:「が今日の種。北東の風が、懐かしい誰かとの縁を運んでくるよ。」
  25. `<div #mapWrap>`
    CSS: position:absolute; top:50px; left:0; right:0; bottom:80px; overflow:hidden
    26. `<div #leafletMap>`
    27. `<div #grayVeil>`
      CSS: background:rgba(10,10,20,.25); position:absolute; top:0; left:0; right:0; bottom:0
    28. `<canvas #particleCanvas>`
      CSS: width:100%; height:100%; position:absolute; top:0; left:0; z-index:20
    29. `<div #screenFlash>`
      CSS: background:rgba(201,168,76,.15); position:absolute; top:0; left:0; right:0; bottom:0
    30. `<video #effectVideo>`
      CSS: position:absolute; z-index:18; opacity:0
    31. `<div #restOverlay>`
      CSS: position:absolute; top:0; left:0; right:0; bottom:0; display:none
      32. `<div .rest-inner>`
        CSS: max-width:260px; background:rgba(15,15,30,.85); padding:20px 28px; border-radius:16px
    33. `<div #preseed>`
      CSS: position:absolute; top:50%; left:50%; z-index:30
      34. `<div .preseed-icon>` — テキスト:「🌱」
        CSS: font-size:32px; opacity:.6
      35. `<div .preseed-text>` — テキスト:「今日の方位を探索してみよう」
        CSS: font-size:12px; color:#555
    36. `<div #vpBtn>` — テキスト:「📍」
      CSS: width:40px; height:40px; font-size:16px; background:rgba(10,10,25,.8); border-radius:50%; position:absolute
    37. `<div #vpPanel>`
      CSS: width:180px; background:rgba(12,12,26,.92); padding:12px; border-radius:14px; position:absolute; top:222px
      38. `<div .vp-tabs>`
        CSS: background:rgba(255,255,255,.03); padding:2px; border-radius:8px; display:flex; gap:2px
      39. `<div #vpContent>`
      40. `<div #locContent>`
      41. `<div #vpCoord>`
        CSS: font-size:9px; color:rgba(201,168,76,.5)
    42. `<div #layerBtn>`
      CSS: width:40px; height:40px; background:rgba(10,10,25,.8); border-radius:50%; position:absolute; top:130px
      43. `<div .layer-btn-bar>`
        CSS: width:18px; height:2px; border-radius:1px
      44. `<div .layer-btn-bar>`
        CSS: width:18px; height:2px; border-radius:1px
      45. `<div .layer-btn-bar>`
        CSS: width:18px; height:2px; border-radius:1px
    46. `<div #layerPanel>`
      CSS: width:100px; background:rgba(12,12,26,.92); padding:14px; border-radius:14px; position:absolute; top:175px
      47. `<div .lp-title>` — テキスト:「LAYERS」
        CSS: font-size:9px; color:#666
      48. `<div .lp-sec>`
      49. `<div .lp-sec>`
      50. `<div .lp-sec>`
      51. `<div .lp-sec>`
    52. `<div #fsPull>` — テキスト:「▲ 運勢方位」
      CSS: font-size:10px; color:#888; background:rgba(10,10,25,.8); padding:4px 18px 2px; border-radius:12px 12px 0 0; position:absolute
    53. `<div #fsSheet>`
      CSS: background:rgba(10,10,25,.95); border-radius:16px 16px 0 0; position:absolute; left:0; right:0; bottom:80px
      54. `<div .fs-handle>`
        CSS: width:36px; height:4px; background:rgba(255,255,255,.25); margin:10px auto 6px; border-radius:2px
      55. `<div #fsSrcTabs>`
        CSS: padding:0 8px; display:flex; gap:0
      56. `<div #fsLegend>`
        CSS: font-size:9px; color:#888; padding:4px 12px; display:flex; gap:10px
      57. `<div #fsCatTabs>`
        CSS: padding:0 8px; display:flex; gap:0
      58. `<div #fsBody>`
        CSS: height:185px; min-height:185px; padding:10px 14px 14px
    59. `<div .bottom-nav>`
      CSS: height:80px; background:linear-gradient(180deg, rgba(6,10,18,0.80) 0%, rgba(4,6,14,0.95) 100%); padding:10px 4px 0; position:fixed; left:0; right:0

**要素総数（depth≤3）**: 59個

---
## インタラクション一覧（イベントハンドラ）

1. **particleCanvas** の `pointerdown` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

2. **.sr-tab** の `pointerdown` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

3. **.fp-item** の `touchstart` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

4. **.vp-icon-picker** の `pointerdown` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

5. **.vp-msg** の `pointerdown` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

6. **document** の `pointerdown` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

7. **document** の `keydown` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

9. **el** の `touchstart` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

10. **el** の `touchend` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

11. **el** の `mousedown` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

12. **el** の `mouseup` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

14. **window** の `load` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

15. **window** の `resize` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

16. **(HTML属性)** の `click` イベント → `restart()`
   > 動作メモ:（ここに日本語で何が起きるか書く）

---
## 関数一覧（インラインJS）

1. `tripleChart()` — 説明:（ここに日本語で書く）
2. `qBucket(q)` — 説明:（ここに日本語で書く）
3. `cosFall(dist,spread)` — 説明:（ここに日本語で書く）
4. `findAspects(map1,map2,wMult,prefix)` — 説明:（ここに日本語で書く）
5. `scoreAll()` — 説明:（ここに日本語で書く）
6. `angleBonus(p2key)` — 説明:（ここに日本語で書く）
7. `normLng(ptLng,refLng)` — 説明:（ここに日本語で書く）
8. `turfLine(center,bearing,maxKm,steps)` — 説明:（ここに日本語で書く）
9. `clampLat(l)` — 説明:（ここに日本語で書く）
10. `init()` — 説明:（ここに日本語で書く）
11. `buildCompass(center)` — 説明:（ここに日本語で書く）
12. `rebuild(nc,fly)` — 説明:（ここに日本語で書く）
13. `getSectorColor()` — 説明:（ここに日本語で書く）
14. `scoreToStyle(score,rank,clr)` — 説明:（ここに日本語で書く）
15. `computeRanks(scores)` — 説明:（ここに日本語で書く）
16. `createSectors()` — 説明:（ここに日本語で書く）
17. `buildSectorPts(cp,startB,endB,radius,refLng)` — 説明:（ここに日本語で書く）
18. `addPlanetLines()` — 説明:（ここに日本語で書く）
19. `updateSymPos()` — 説明:（ここに日本語で書く）
20. `Particle(x,y,vx,vy,color,size,life,decay)` — 説明:（ここに日本語で書く）
21. `spawnImpact(x,y,n)` — 説明:（ここに日本語で書く）
22. `spawnConverge(tx,ty,n)` — 説明:（ここに日本語で書く）
23. `launchMeteor(tx,ty)` — 説明:（ここに日本語で書く）
24. `startAnim()` — 説明:（ここに日本語で書く）
25. `animate()` — 説明:（ここに日本語で書く）
26. `drawSparkles(ctx)` — 説明:（ここに日本語で書く）
27. `onImpact(x,y)` — 説明:（ここに日本語で書く）
28. `playEffect(x,y)` — 説明:（ここに日本語で書く）
29. `openSearch()` — 説明:（ここに日本語で書く）
30. `closeSearch()` — 説明:（ここに日本語で書く）
31. `doSearch()` — 説明:（ここに日本語で書く）
32. `detectSector(lat,lng)` — 説明:（ここに日本語で書く）
33. `showSR(name,msg,type,dir)` — 説明:（ここに日本語で書く）
34. `switchSRTab(el)` — 説明:（ここに日本語で書く）
35. `showSRAdvice(cat)` — 説明:（ここに日本語で書く）
36. `closeSR()` — 説明:（ここに日本語で書く）
37. `toggleLP()` — 説明:（ここに日本語で書く）
38. `closeLPOut(e)` — 説明:（ここに日本語で書く）
39. `toggleLT(el)` — 説明:（ここに日本語で書く）
40. `toggleGT(el)` — 説明:（ここに日本語で書く）
41. `setFortune(cat)` — 説明:（ここに日本語で書く）
42. `applyVis()` — 説明:（ここに日本語で書く）
43. `getActiveScores()` — 説明:（ここに日本語で書く）
44. `toggleFS()` — 説明:（ここに日本語で書く）
45. `switchSrc(tab)` — 説明:（ここに日本語で書く）
46. `switchCat(tab)` — 説明:（ここに日本語で書く）
47. `renderFS()` — 説明:（ここに日本語で書く）
48. `pct(v)` — 説明:（ここに日本語で書く）
49. `flashSec(dir)` — 説明:（ここに日本語で書く）
50. `updateFFLabel()` — 説明:（ここに日本語で書く）
51. `hs(y)` — 説明:（ここに日本語で書く）
52. `he(y)` — 説明:（ここに日本語で書く）
53. `SlotManager(cfg)` — 説明:（ここに日本語で書く）
54. `vpLoadLast()` — 説明:（ここに日本語で書く）
55. `vpSaveLast(c)` — 説明:（ここに日本語で書く）
56. `toggleVP()` — 説明:（ここに日本語で書く）
57. `vpGeo()` — 説明:（ここに日本語で書く）
58. `vpSave()` — 説明:（ここに日本語で書く）
59. `locSave()` — 説明:（ここに日本語で書く）
60. `vpMsg(txt)` — 説明:（ここに日本語で書く）
61. `vpRender()` — 説明:（ここに日本語で書く）
62. `locRender()` — 説明:（ここに日本語で書く）
63. `switchVPTab(tab)` — 説明:（ここに日本語で書く）
64. `restart()` — 説明:（ここに日本語で書く）
65. `dismissVeil()` — 説明:（ここに日本語で書く）

---
## API呼び出し

1. `https://nominatim.openstreetmap.org/search?format=json&q=`
   > 用途:（ここに日本語で書く）

2. `https://nominatim.openstreetmap.org/reverse?format=json&lat=`
   > 用途:（ここに日本語で書く）

---
## 使用CSS変数

| 変数名 | 値 |
|--------|-----|
| `--bg-deep` | `#080C14` |
| `--font-body` | `'DM Sans', 'Segoe UI', sans-serif` |
| `--pc` | `（未定義）` |
| `--tc` | `（未定義）` |
