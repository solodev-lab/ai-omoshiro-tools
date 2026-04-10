# Tarot（タロット占い）

**ソースファイル**: `mockup/tarot.html`
**HTML行数**: 1561行（うちJS約1551行）
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
        9. `<div #cardScene>`
          CSS: width:200px; height:320px
          10. `<div #card3d>`
            CSS: width:100%; height:100%; position:relative
            11. `<div .card-face>`
              CSS: width:100%; height:100%; background:linear-gradient(135deg, #1a1a3e, #0d0d2b); border-radius:14px; position:absolute; display:flex
              12. `<div .card-back-pattern>`
                CSS: width:160px; height:260px; background:radial-gradient(ellipse at center, rgba(107, 92, 231, 0.08) 0%, transparent 70%); border-radius:8px; position:relative; display:flex
                13. `<div .card-back-symbol>` — テキスト:「✨」
                  CSS: font-size:48px; opacity:0.6
                14. `<div .card-back-corners>`
                  CSS: border-radius:4px; position:absolute
                15. `<span .card-back-star>` — テキスト:「✦」
                  CSS: font-size:10px; color:#C9A84C; position:absolute; opacity:0.3
                16. `<span .card-back-star>` — テキスト:「✦」
                  CSS: font-size:10px; color:#C9A84C; position:absolute; opacity:0.3
                17. `<span .card-back-star>` — テキスト:「✦」
                  CSS: font-size:10px; color:#C9A84C; position:absolute; opacity:0.3
                18. `<span .card-back-star>` — テキスト:「✦」
                  CSS: font-size:10px; color:#C9A84C; position:absolute; opacity:0.3
            19. `<div #cardFront>`
              CSS: width:100%; height:100%; background:linear-gradient(180deg, #1a1a3e 0%, #0d0d2b 100%); padding:16px; border-radius:14px; position:absolute
              20. `<div #cardElement>`
                CSS: font-size:11px; color:#aaa; display:flex; gap:2px
              21. `<div #cardEmoji>`
                CSS: font-size:56px
              22. `<div #cardNameEn>`
                CSS: font-size:14px; font-weight:600; color:#C9A84C
              23. `<div #cardNameJp>`
                CSS: font-size:18px; font-weight:300; color:#E8E0D0
              24. `<div #cardKeyword>`
                CSS: font-size:13px; color:#999
              25. `<div #cardPlanet>`
                CSS: font-size:11px; color:#888; display:flex; gap:6px
        26. `<div #tapHint>` — テキスト:「👆 タップしてカードを引く」
          CSS: height:16px; font-size:11px; color:#555
        27. `<div #drawnMsg>`
          CSS: min-height:20px; font-size:13px; color:#666
        28. `<div #stellaMsg>`
          CSS: width:100%; background:rgba(15, 15, 30, 0.5); padding:16px; border-radius:14px; opacity:0
          29. `<div .stella-label>` — テキスト:「✨ Stella」
            CSS: font-size:10px; color:#C9A84C
          30. `<div #stellaText>`
            CSS: font-size:13px; color:#ccc
        31. `<div #tarotReadingPanel>`
          CSS: width:100%; background:rgba(15, 15, 30, 0.6); padding:18px 16px; border-radius:16px; display:none
          32. `<div .reading-header>`
            CSS: display:flex; gap:10px
            33. `<div .reading-icon>` — テキスト:「🔮」
              CSS: width:36px; height:36px; font-size:18px; background:rgba(201, 168, 76, 0.12); border-radius:50%; display:flex
            34. `<div .reading-title>` — テキスト:「✦ TAROT READING」
              CSS: font-size:13px; font-weight:700; color:#C9A84C
          35. `<div #tarotReadingBody>`
            CSS: font-size:13px; color:rgba(232, 224, 208, 0.85)
          36. `<div #tarotReadingAdvice>`
            CSS: font-size:12px; color:#C9A84C; background:rgba(201, 168, 76, 0.06); padding:12px 14px; border-radius:12px
    37. `<div #historyPanel>`
      CSS: display:none
      38. `<div .history-panel>`
        CSS: padding:16px 16px 30px
        39. `<div .history-header>`
          CSS: padding:0 2px; display:flex
          40. `<div .history-title>` — テキスト:「NATAL TAROT HISTORY」
            CSS: font-size:12px; color:#666
          41. `<button .history-clear>` — テキスト:「CLEAR」
            CSS: font-size:10px; color:#444; background:none; padding:4px 8px
        42. `<div #historyList>`
  43. `<canvas #particleCanvas>`
    CSS: width:100%; height:100%; position:absolute; top:0; left:0; z-index:200
  44. `<div .bottom-nav>`
    CSS: height:80px; background:linear-gradient(180deg, rgba(6,10,18,0.80) 0%, rgba(4,6,14,0.95) 100%); padding:10px 4px 0; position:fixed; left:0; right:0

**要素総数（depth≤20）**: 44個

---
## インタラクション一覧（イベントハンドラ）

1. **customLocInput** の `click` イベント
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
5. `getLocationLabel()` — 説明:（ここに日本語で書く）
6. `initCardTap()` — 説明:（ここに日本語で書く）
7. `loadHistory()` — 説明:（ここに日本語で書く）
8. `saveHistory(card, info)` — 説明:（ここに日本語で書く）
9. `renderHistory()` — 説明:（ここに日本語で書く）
10. `toggleHistoryCard(i)` — 説明:（ここに日本語で書く）
11. `saveSynchronicity(index, value)` — 説明:（ここに日本語で書く）
12. `clearHistory()` — 説明:（ここに日本語で書く）
13. `checkTodayDraw()` — 説明:（ここに日本語で書く）
14. `resizeCanvas()` — 説明:（ここに日本語で書く）
15. `spawnParticles(cx, cy)` — 説明:（ここに日本語で書く）
16. `animLoop()` — 説明:（ここに日本語で書く）
17. `getTarotCacheKey(card)` — 説明:（ここに日本語で書く）
18. `showTarotReading(card, info)` — 説明:（ここに日本語で書く）
19. `typewriteReading(panel, body, advice, text, adviceText)` — 説明:（ここに日本語で書く）
20. `showFallbackReading(card, info, panel, body, advice)` — 説明:（ここに日本語で書く）
21. `getMoodDesc(v)` — 説明:（ここに日本語で書く）
22. `updateMoodDisplay()` — 説明:（ここに日本語で書く）
23. `loadSavedMood()` — 説明:（ここに日本語で書く）
24. `init()` — 説明:（ここに日本語で書く）

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
