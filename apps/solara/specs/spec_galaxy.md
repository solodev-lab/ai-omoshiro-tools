# Galaxy（銀河・星座）

**ソースファイル**: `mockup/galaxy.html`
**HTML行数**: 1861行（うちJS約1345行）
**イベント数**: 14個
**API呼び出し**: 0箇所

---
## この画面の説明（日本語メモ）

> ここにオーナーが日本語で画面の説明を書く。
> 例：「世界地図が表示される。タップした場所の運勢が見れる。」

---
## 要素一覧（HTML上から順）

1. `<div #phone>`
  CSS: width:100%; min-height:100vh; background:radial-gradient(ellipse at 50% 0%, #0f2850 0%, #080C14 55%),
    radial-gradient(ellipse at 30% 100%, #060e20 0%, transparent 65%); position:relative; overflow:hidden
  2. `<canvas #bgCanvas>`
    CSS: width:100%; height:100%; position:absolute; z-index:0
  3. `<div #starContainer>`
  4. `<div .screen>`
    CSS: position:absolute; display:none; flex-direction:column; z-index:10
    5. `<div .main-area>`
      CSS: position:fixed; top:0; left:0; right:0; bottom:80px; display:flex
      6. `<div .inner-tabs>`
        CSS: padding:0 20px; display:flex; gap:0
        7. `<button .inner-tab-btn>` — テキスト:「🌀 Cycle」
          CSS: font-size:12px; font-weight:700; font-family:'DM Sans', 'Segoe UI', sans-serif; color:rgba(255,255,255,0.35); background:none; padding:10px 0
        8. `<button .inner-tab-btn>` — テキスト:「✦ Star Atlas」
          CSS: font-size:12px; font-weight:700; font-family:'DM Sans', 'Segoe UI', sans-serif; color:rgba(255,255,255,0.35); background:none; padding:10px 0
      9. `<div #panel-cycle>`
        CSS: display:none; flex-direction:column; overflow:hidden
        10. `<div .cycle-content>`
          CSS: position:relative; display:flex; flex-direction:column; overflow:hidden
          11. `<div #moonBadge>`
            CSS: background:rgba(192,200,224,0.10); padding:8px 14px; border-radius:22px; position:absolute; top:8px; left:20px
            12. `<div #moonEmoji>` — テキスト:「🌓」
              CSS: font-size:20px
            13. `<div #moonLabel>` — テキスト:「First Quarter」
              CSS: font-size:9px; color:rgba(192,200,224,0.65)
          14. `<div .day-badge>`
            CSS: background:rgba(249,217,118,0.12); padding:8px 14px; border-radius:22px; position:absolute; top:8px; right:20px
            15. `<div #dayNum>` — テキスト:「1」
              CSS: font-size:22px; font-weight:700; color:#F9D976
            16. `<div #dayLbl>` — テキスト:「of 30」
              CSS: font-size:9px; color:rgba(249,217,118,0.65)
          17. `<div .spiral-area>`
            CSS: position:relative
            18. `<canvas #spiralCanvas>`
              CSS: width:100%; height:100%; display:block
            19. `<div #dotPopup>`
              CSS: width:200px; background:rgba(8,12,20,0.95); padding:14px 16px; border-radius:18px; position:absolute; z-index:60
              20. `<div #popupDay>` — テキスト:「DAY 7」
                CSS: font-size:10px; font-weight:700; color:#F9D976
              21. `<div .popup-card>`
                CSS: display:flex; gap:8px
                22. `<div #popupEmoji>` — テキスト:「⚡」
                  CSS: font-size:22px
                23. `<div #popupCardName>` — テキスト:「The Chariot」
                  CSS: font-size:12px; font-weight:700; color:#EAEAEA
              24. `<div #popupPlanet>` — テキスト:「Planet: Moon」
                CSS: font-size:11px; color:rgba(172,172,172,0.8)
              25. `<div #popupKeyword>` — テキスト:「Keyword: Willpower」
                CSS: font-size:11px; font-weight:300; color:rgba(249,217,118,0.7)
              26. `<div #popupQuote>` — テキスト:「"Your momentum is cosmic."」
                CSS: font-size:11px; font-weight:300; color:rgba(172,172,172,0.7)
      27. `<div #panel-atlas>`
        CSS: display:none; flex-direction:column; overflow:hidden
        28. `<div .atlas-content>`
          CSS: padding:0 16px 100px; display:flex; flex-direction:column; gap:20px
          29. `<div>`
            30. `<div .screen-h1>` — テキスト:「Star Atlas」
              CSS: font-size:24px; font-weight:700; font-family:'Cormorant Garamond', 'Georgia', serif; color:#EAEAEA
            31. `<div .screen-h2>` — テキスト:「Your completed cosmic cycles」
              CSS: font-size:13px; font-weight:300; font-family:'DM Sans', 'Segoe UI', sans-serif; color:#ACACAC
          32. `<div #galaxyGrid>`
            CSS: display:grid; gap:12px
      33. `<div .stella-msg>`
        CSS: background:rgba(255,255,255,0.06); padding:12px 16px 14px; margin:0 16px 6px; border-radius:20px; position:relative
        34. `<div .bubble-by>` — テキスト:「✦ Stella」
          CSS: font-size:10px; font-weight:700; color:#F9D976
        35. `<div .bubble-msg>` — テキスト:「"Your cosmic spiral grows brig」
          CSS: font-size:13px; font-weight:300; color:#EAEAEA
  36. `<div .bottom-nav>`
    CSS: height:80px; background:linear-gradient(180deg, rgba(6,10,18,0.80) 0%, rgba(4,6,14,0.95) 100%); padding:10px 4px 0; position:fixed; left:0; right:0
37. `<div #overlayFormation>`
  CSS: background:rgba(4,8,16,0.97); position:absolute; display:none; flex-direction:column; z-index:300
  38. `<canvas #formationCanvas>`
    CSS: width:100%; height:100%; position:absolute
  39. `<div #formationUI>`
    CSS: position:absolute; left:0; right:0; bottom:120px; display:flex; flex-direction:column
    40. `<div #formationStage>` — テキスト:「CONVERGENCE」
      CSS: font-size:12px; font-weight:700; color:rgba(249,217,118,0.6)
    41. `<div #formationSymbol>` — テキスト:「👑」
      CSS: font-size:44px
    42. `<div #formationName>` — テキスト:「The Golden Crown」
      CSS: font-size:28px; font-weight:700; padding:0 24px
    43. `<div #formationQuote>` — テキスト:「"Your alignment forged a crown」
      CSS: font-size:13px; font-weight:300; color:rgba(172,172,172,0.8); padding:0 28px
  44. `<button #formationClose>` — テキスト:「View in Star Atlas ✦」
    CSS: font-size:15px; font-weight:700; font-family:'DM Sans', 'Segoe UI', sans-serif; color:#0C1D3A; background:linear-gradient(135deg, #F9D976, #F6BD60); padding:14px 36px
45. `<div #replayModal>`
  CSS: background:rgba(2,4,10,0.96); position:absolute; display:none; flex-direction:column; z-index:400
  46. `<div .replay-inner>`
    CSS: width:340px; display:flex; flex-direction:column; gap:20px
    47. `<div>`
      48. `<div #replayTitle>` — テキスト:「The Golden Crown」
        CSS: font-size:20px; font-weight:700
      49. `<div #replaySubtitle>` — テキスト:「Cycle Replay — 30 Days」
        CSS: font-size:12px; color:#ACACAC
    50. `<canvas #replayCanvas>`
      CSS: background:rgba(6,10,18,0.8); border-radius:20px
    51. `<div>`
      52. `<div #replaySymbol>` — テキスト:「👑」
        CSS: font-size:22px
      53. `<div #replayName>` — テキスト:「The Golden Crown」
        CSS: font-size:16px; font-weight:700; color:#EAEAEA
      54. `<div #replayDate>` — テキスト:「Jan 3 — Jan 30, 2026」
        CSS: font-size:12px; color:#ACACAC
    55. `<button .replay-close>` — テキスト:「← Back to Star Atlas」
      CSS: font-size:13px; font-family:'DM Sans', 'Segoe UI', sans-serif; color:#ACACAC; background:none; padding:10px 28px; border-radius:12px

**要素総数（depth≤20）**: 55個

---
## インタラクション一覧（イベントハンドラ）

1. **bgCanvas** の `click` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

2. **spiralCanvas** の `wheel` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

3. **canvas** の `click` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

4. **canvas** の `mousedown` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

5. **window** の `mousemove` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

6. **window** の `mouseup` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

7. **canvas** の `wheel` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

8. **canvas** の `touchstart` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

9. **canvas** の `touchmove` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

10. **canvas** の `touchend` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

11. **(HTML属性)** の `click` イベント → `switchInner(`
   > 動作メモ:（ここに日本語で何が起きるか書く）

---
## 関数一覧（インラインJS）

1. `mulberry32(a)` — 説明:（ここに日本語で書く）
2. `getMoonCycleInfo()` — 説明:（ここに日本語で書く）
3. `generateDaysData(total, active)` — 説明:（ここに日本語で書く）
4. `cardToColor(dd)` — 説明:（ここに日本語で書く）
5. `hexToRgba(hex, alpha)` — 説明:（ここに日本語で書く）
6. `rarityStarsHTML(stars)` — 説明:（ここに日本語で書く）
7. `computeMST(points)` — 説明:（ここに日本語で書く）
8. `buildConstellationEdges(anchorPoints, shapeType)` — 説明:（ここに日本語で書く）
9. `getTemplatePositions(nounIdx, numAnchors, seed)` — 説明:（ここに日本語で書く）
10. `placeCycleDots(majors, minors, nounIdx, seedCard, id)` — 説明:（ここに日本語で書く）
11. `forceNameDemoCycle(id, seedCard, readings, forceAdjIdx, forceNounIdx)` — 説明:（ここに日本語で書く）
12. `makeDemoReadings(seedCard, count, seed, minMajor)` — 説明:（ここに日本語で書く）
13. `preloadConstellationArt()` — 説明:（ここに日本語で書く）
14. `animBg()` — 説明:（ここに日本語で書く）
15. `makeStars()` — 説明:（ここに日本語で書く）
16. `updateMoonBadge()` — 説明:（ここに日本語で書く）
17. `switchInner(tab)` — 説明:（ここに日本語で書く）
18. `rot3D(x, y, z)` — 説明:（ここに日本語で書く）
19. `proj3D(x, y, z, fov, cx, cy)` — 説明:（ここに日本語で書く）
20. `precomputeGoldenAnglePositions()` — 説明:（ここに日本語で書く）
21. `projectGA3D(nx, ny, nz, W, H, cx, cy, camAngle, FOV)` — 説明:（ここに日本語で書く）
22. `renderSpiral3D()` — 説明:（ここに日本語で書く）
23. `startSpiral3D()` — 説明:（ここに日本語で書く）
24. `loop()` — 説明:（ここに日本語で書く）
25. `initSpiral3D()` — 説明:（ここに日本語で書く）
26. `showDotPopup(day, px, py, canvas)` — 説明:（ここに日本語で書く）
27. `hideDotPopup()` — 説明:（ここに日本語で書く）
28. `projectConstellation3D(nx, ny, nz, S, camAngle)` — 説明:（ここに日本語で書く）
29. `drawCycleOnCanvas(canvas, cycle, progress, size, camAngle)` — 説明:（ここに日本語で書く）
30. `renderGalaxyCards()` — 説明:（ここに日本語で書く）
31. `openReplayModal(cycleId)` — 説明:（ここに日本語で書く）
32. `anim()` — 説明:（ここに日本語で書く）
33. `closeReplayModal()` — 説明:（ここに日本語で書く）
34. `closeFormationOverlay()` — 説明:（ここに日本語で書く）
35. `loadDailyVibes()` — 説明:（ここに日本語で書く）
36. `saveDailyVibe(score)` — 説明:（ここに日本語で書く）
37. `loadSavedCycles()` — 説明:（ここに日本語で書く）
38. `saveCycles()` — 説明:（ここに日本語で書く）
39. `remaining(anchorPoints.map((p, i)` — 説明:（ここに日本語で書く）
40. `remaining(leaves.filter(l)` — 説明:（ここに日本語で書く）
41. `cx(anchorPoints.reduce((s, p)` — 説明:（ここに日本語で書く）
42. `cy(anchorPoints.reduce((s, p)` — 説明:（ここに日本語で書く）
43. `nearestIdx(0, nearestDist = Infinity;
    anchorPoints.forEach((p, i)` — 説明:（ここに日本語で書く）
44. `step(template.length / numAnchors;
    return Array.from({length: numAnchors}, (_, i)` — 説明:（ここに日本語で書く）
45. `baseColor(ADJ_COLORS[forceAdjIdx];

  const majors = [], minors = [];
  readings.forEach(r)` — 説明:（ここに日本語で書く）
46. `DEMO_SPECS([
  [ 0, 16, 10], [ 1, 12,  9], [ 2,  3, 17], [ 3,  0, 19], [ 4,  2, 18], [ 5, 18,  0],
  [ 6,  4,  8], [ 7,  5,  7], [ 8,  0, 11], [ 9, 17,  5], [10,  6,  2], [11, 13, 13], [12, 10, 21],
  [13, 10, 15], [14,  4,  7], [15,  2, 16], [16, 14,  3], [17,  6,  3], [18, 13, 12],
  [19,  4,  7], [20,  2, 16], [21,  3, 4],  [22,  9, 20], [23, 15, 14], [24,  1,  5],
  [25,  0, 19], [26, 17,  6], [27,  8,  4], [28,  2, 15], [29, 18,  9], [30,  9, 21],
  [31,  4,  8], [32, 13, 16], [33,  0, 11], [34, 19, 15], [35, 12,  1], [36, 15,  9],
  [37, 14, 10], [38,  0, 16], [39,  0, 12], [40,  2, 20], [41,  1,  0],
  [42, 14,  8], [43, 16, 11], [44, 10, 13], [45, 17,  7], [46,  5, 18], [47,  9, 20],
  [48,  0,  6], [49, 12, 14], [50,  0,  6], [51,  2, 17],
  [52,  6,  3], [53,  3, 19], [54,  8, 13], [55,  1, 14], [56, 19,  0],
  [57, 17, 17], [58, 18, 10], [59,  2, 13], [60,  8,  0],
];

// Nouns with 10+ template points need more anchors
const HIGH_ANCHOR_NOUNS = {8:1,9:1,10:1,11:1,17:1,27:1,28:1,36:1,40:1,50:1,57:1,60:1};

const GALAXY_CYCLES = DEMO_SPECS.map((spec, i)` — 説明:（ここに日本語で書く）
47. `BREATH_PHASES(Array.from({length: TOTAL}, (_, i)` — 説明:（ここに日本語で書く）
48. `BREATH_PERIODS(Array.from({length: TOTAL}, (_, i)` — 説明:（ここに日本語で書く）
49. `mx(e.clientX - rect.left, my = e.clientY - rect.top;
    let nearest = null, minDist = 28;
    sp.dotPositions.forEach(dp)` — 説明:（ここに日本語で書く）
50. `ltDist(0;
  canvas.addEventListener('touchstart', e)` — 説明:（ここに日本語で書く）
51. `anchors([], fields = [];
  cycle.dots.forEach(d)` — 説明:（ここに日本語で書く）
52. `shapeType(NOUN_SHAPES[cycle.nounIdx] || 'open';
  const anchorPts = anchors.map(a)` — 説明:（ここに日本語で書く）
53. `anchorCount(cycle.dots.filter(d)` — 説明:（ここに日本語で書く）
54. `nc(window._lastFormedCycle;
    if (!GALAXY_CYCLES.find(c)` — 説明:（ここに日本語で書く）
55. `existing(vibes.find(v)` — 説明:（ここに日本語で書く）

---
## API呼び出し

（API呼び出しなし）

---
## 使用CSS変数

| 変数名 | 値 |
|--------|-----|
| `--font-body` | `'DM Sans', 'Segoe UI', sans-serif` |
