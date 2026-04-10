# Tarot（タロット占い）

**ソースファイル**: `mockup/tarot.html`
**HTML行数**: 1569行（うちJS約1559行）
**イベント数**: 4個
**API呼び出し**: 1箇所

---
## この画面の説明（日本語メモ）

> ここにオーナーが日本語で画面の説明を書く。
> 例：「世界地図が表示される。タップした場所の運勢が見れる。」

---
## 要素一覧（HTML上から順）

1. `<div .phone-frame>`
  CSS: width:100%; height:100vh; background:radial-gradient(ellipse at 50% 0%, #0f2850 0%, #080C14 55%),
    radial-gradient(ellipse at 30% 100%, #060e20 0%, transparent 65%); position:relative; overflow:hidden
  2. `<div .status-bar>` — テキスト:「S O L A R A」
    CSS: height:44px; font-size:12px; font-weight:700; color:rgba(234,234,234,0.9); background:#0A0A14; padding:0 28px
  3. `<div .inner-tab-nav>`
    CSS: height:40px; background:rgba(15, 15, 30, 0.9); display:flex; z-index:90
    4. `<button .inner-tab-btn>` — テキスト:「🃏 TAROT DRAW」
      CSS: font-size:12px; font-weight:500; color:#555; background:none; position:relative
    5. `<button .inner-tab-btn>` — テキスト:「📜 HISTORY」
      CSS: font-size:12px; font-weight:500; color:#555; background:none; position:relative
  6. `<div .content-area>`
    CSS: position:absolute; top:90px; left:0; right:0; bottom:80px
    7. `<div #drawPanel>`
      CSS: display:none
      8. `<div .draw-panel>`
        CSS: width:100%; max-width:500px; padding:20px 20px 30px; margin:0 auto; display:flex; flex-direction:column
    9. `<div #historyPanel>`
      CSS: display:none
      10. `<div .history-panel>`
        CSS: padding:16px 16px 30px
  11. `<canvas #particleCanvas>`
    CSS: width:100%; height:100%; position:absolute; top:0; left:0; z-index:200
  12. `<div .bottom-nav>`
    CSS: height:80px; background:linear-gradient(180deg, rgba(6,10,18,0.80) 0%, rgba(4,6,14,0.95) 100%); padding:10px 4px 0; position:fixed; left:0; right:0

**要素総数（depth≤3）**: 12個

---
## インタラクション一覧（イベントハンドラ）

1. **.loc-btn** の `click` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

2. **btn** の `click` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

3. **(HTML属性)** の `click` イベント → `clearHistory()`
   > 動作メモ:（ここに日本語で何が起きるか書く）

---
## 関数一覧（インラインJS）

1. `generateStellaMsg(card, planetJP)` — 説明:（ここに日本語で書く）
2. `getToday()` — 説明:（ここに日本語で書く）
3. `getNowTime()` — 説明:（ここに日本語で書く）
4. `getCardInfo(card)` — 説明:（ここに日本語で書く）
5. `selectLocation(loc)` — 説明:（ここに日本語で書く）
6. `getLocationLabel()` — 説明:（ここに日本語で書く）
7. `initCardTap()` — 説明:（ここに日本語で書く）
8. `loadHistory()` — 説明:（ここに日本語で書く）
9. `saveHistory(card, info)` — 説明:（ここに日本語で書く）
10. `renderHistory()` — 説明:（ここに日本語で書く）
11. `toggleHistoryCard(i)` — 説明:（ここに日本語で書く）
12. `saveSynchronicity(index, value)` — 説明:（ここに日本語で書く）
13. `clearHistory()` — 説明:（ここに日本語で書く）
14. `checkTodayDraw()` — 説明:（ここに日本語で書く）
15. `resizeCanvas()` — 説明:（ここに日本語で書く）
16. `spawnParticles(cx, cy)` — 説明:（ここに日本語で書く）
17. `animLoop()` — 説明:（ここに日本語で書く）
18. `getTarotCacheKey(card)` — 説明:（ここに日本語で書く）
19. `showTarotReading(card, info)` — 説明:（ここに日本語で書く）
20. `typewriteReading(panel, body, advice, text, adviceText)` — 説明:（ここに日本語で書く）
21. `showFallbackReading(card, info, panel, body, advice)` — 説明:（ここに日本語で書く）
22. `getMoodDesc(v)` — 説明:（ここに日本語で書く）
23. `updateMoodDisplay()` — 説明:（ここに日本語で書く）
24. `loadSavedMood()` — 説明:（ここに日本語で書く）
25. `init()` — 説明:（ここに日本語で書く）

---
## API呼び出し

1. `${TAROT_API_URL}（変数）`
   > 用途:（ここに日本語で書く）

---
## 使用CSS変数

| 変数名 | 値 |
|--------|-----|
| `--bg-deep` | `#080C14` |
| `--font-body` | `'DM Sans', 'Segoe UI', sans-serif` |
