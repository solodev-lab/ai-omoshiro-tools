# Sanctuary（サンクチュアリ・プロフィール）

**ソースファイル**: `mockup/sanctuary.html`
**HTML行数**: 2611行（うちJS約1727行）
**イベント数**: 28個
**API呼び出し**: 4箇所

---
## この画面の説明（日本語メモ）

> ここにオーナーが日本語で画面の説明を書く。
> 例：「世界地図が表示される。タップした場所の運勢が見れる。」

---
## 要素一覧（HTML上から順）

1. `<div #phone>`
  CSS: width:100%; min-height:100vh; background:#080C14; position:relative; overflow:hidden
  2. `<canvas #bgCanvas>`
    CSS: width:100%; height:100%; position:absolute; z-index:0
  3. `<div #starContainer>`
  4. `<div .status-bar>`
    CSS: height:44px; font-size:12px; font-weight:700; color:rgba(234,234,234,0.9); padding:0 28px; position:fixed
    5. `<span>` — テキスト:「9:41」
    6. `<span>` — テキスト:「✦ SOLARA ✦」
    7. `<span>` — テキスト:「87%🔋」
  8. `<div .main-area>`
    CSS: background:radial-gradient(ellipse at 50% 0%, #0f2850 0%, #080C14 55%),
    radial-gradient(ellipse at 30% 100%, #060e20 0%, transparent 65%); position:relative; display:flex; flex-direction:column; z-index:10
    9. `<div .sanctuary-content>`
      CSS: width:100%; max-width:600px; padding:56px 20px 100px; margin:0 auto; position:relative; display:flex
      10. `<div .profile-row>`
        CSS: display:flex; gap:14px
      11. `<div .settings-group>`
        CSS: display:flex; flex-direction:column; gap:10px
      12. `<div #titleSection>`
        CSS: display:flex; flex-direction:column; gap:10px
      13. `<div #birthOverlay>`
        CSS: background:rgba(4,8,16,0.95); position:fixed; display:none; z-index:500

**要素総数（depth≤3）**: 13個

---
## インタラクション一覧（イベントハンドラ）

1. **bgCanvas** の `resize` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

2. **window** の `resize` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

3. **(HTML属性)** の `click` イベント → `openBirthInfo()`
   > 動作メモ:（ここに日本語で何が起きるか書く）

---
## 関数一覧（インラインJS）

1. `animBg()` — 説明:（ここに日本語で書く）
2. `makeStars()` — 説明:（ここに日本語で書く）
3. `loadProfile()` — 説明:（ここに日本語で書く）
4. `saveProfileData(p)` — 説明:（ここに日本語で書く）
5. `renderProfileDisplay()` — 説明:（ここに日本語で書く）
6. `formatDate(d)` — 説明:（ここに日本語で書く）
7. `syncHomeToStorage(key, profile)` — 説明:（ここに日本語で書く）
8. `syncHomeToVP(profile)` — 説明:（ここに日本語で書く）
9. `openBirthInfo()` — 説明:（ここに日本語で書く）
10. `closeBirthInfo()` — 説明:（ここに日本語で書く）
11. `toggleTimeUnknown()` — 説明:（ここに日本語で書く）
12. `setBirthMapLocation(lat, lng, doReverse)` — 説明:（ここに日本語で書く）
13. `searchBirthPlace()` — 説明:（ここに日本語で書く）
14. `saveBirthInfo()` — 説明:（ここに日本語で書く）
15. `openHomeInfo()` — 説明:（ここに日本語で書く）
16. `closeHomeInfo()` — 説明:（ここに日本語で書く）
17. `setHomeMapLocation(lat, lng, doReverse)` — 説明:（ここに日本語で書く）
18. `searchHomePlace()` — 説明:（ここに日本語で書く）
19. `saveHomeInfo()` — 説明:（ここに日本語で書く）
20. `initHouseUI()` — 説明:（ここに日本語で書く）
21. `toggleHouseSelect()` — 説明:（ここに日本語で書く）
22. `setHouseSystem(val)` — 説明:（ここに日本語で書く）
23. `buildOrbRows(container, items, store, storeKey)` — 説明:（ここに日本語で書く）
24. `formatOrbVal(v)` — 説明:（ここに日本語で書く）
25. `resetOrbs()` — 説明:（ここに日本語で書く）
26. `stepOrb(storeKey, key, delta)` — 説明:（ここに日本語で書く）
27. `openOrbOverlay()` — 説明:（ここに日本語で書く）
28. `positionDefaultMarks()` — 説明:（ここに日本語で書く）
29. `closeOrbOverlay()` — 説明:（ここに日本語で書く）
30. `updateOrbVal(storeKey, key, val)` — 説明:（ここに日本語で書く）
31. `saveOrbOverlay()` — 説明:（ここに日本語で書く）
32. `updateOrbSummary()` — 説明:（ここに日本語で書く）
33. `getSunSign(dateStr)` — 説明:（ここに日本語で書く）
34. `getMoonSign(dateStr, timeStr)` — 説明:（ここに日本語で書く）
35. `resetTD()` — 説明:（ここに日本語で書く）
36. `showTDScreen(id)` — 説明:（ここに日本語で書く）
37. `startDiagnosis()` — 説明:（ここに日本語で書く）
38. `closeDiagnosis()` — 説明:（ここに日本語で書く）
39. `beginRounds()` — 説明:（ここに日本語で書く）
40. `showRound(idx)` — 説明:（ここに日本語で書く）
41. `renderRound(idx, r, displayNum)` — 説明:（ここに日本語で書く）
42. `animateCardsIn()` — 説明:（ここに日本語で書く）
43. `selectCard(roundIdx, cardIdx)` — 説明:（ここに日本語で書く）
44. `getLeadingAxis()` — 説明:（ここに日本語で書く）
45. `applyWildcard()` — 説明:（ここに日本語で書く）
46. `determineFinalAxis()` — 説明:（ここに日本語で書く）
47. `determineCourt()` — 説明:（ここに日本語で書く）
48. `computeResults()` — 説明:（ここに日本語で書く）
49. `saveTitleData()` — 説明:（ここに日本語で書く）
50. `loadTitleData()` — 説明:（ここに日本語で書く）
51. `startForging()` — 説明:（ここに日本語で書く）
52. `startReveal()` — 説明:（ここに日本語で書く）
53. `acceptTitle()` — 説明:（ここに日本語で書く）
54. `retryDiagnosis()` — 説明:（ここに日本語で書く）
55. `loadShareImage(src)` — 説明:（ここに日本語で書く）
56. `shareTitle()` — 説明:（ここに日本語で書く）
57. `renderShareCard(bgImg, classImg, sunImg, moonImg, info)` — 説明:（ここに日本語で書く）
58. `renderShareCardFallback(data, cls, txt, axis, sunSign, moonSign, axisStyle)` — 説明:（ここに日本語で書く）
59. `drawCover(ctx, img, w, h)` — 説明:（ここに日本語で書く）
60. `downloadCanvas(canvas)` — 説明:（ここに日本語で書く）
61. `determineFinalAxisFromScores(scores)` — 説明:（ここに日本語で書く）
62. `renderTitleDisplay()` — 説明:（ここに日本語で書く）

---
## API呼び出し

1. `https://nominatim.openstreetmap.org/reverse?format=json&lat=`
   > 用途:（ここに日本語で書く）

2. `https://nominatim.openstreetmap.org/search?format=json&q=`
   > 用途:（ここに日本語で書く）

3. `https://nominatim.openstreetmap.org/reverse?format=json&lat=`
   > 用途:（ここに日本語で書く）

4. `https://nominatim.openstreetmap.org/search?format=json&q=`
   > 用途:（ここに日本語で書く）

---
## 使用CSS変数

| 変数名 | 値 |
|--------|-----|
| `--font-body` | `'DM Sans', 'Segoe UI', sans-serif` |
