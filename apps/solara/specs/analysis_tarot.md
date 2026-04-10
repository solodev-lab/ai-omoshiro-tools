# Tarot（タロット占い） — 機能分析レポート

**ソース**: `mockup/tarot.html`
**関数総数**: 24個
**エントリーポイント**: 12個
**到達可能な関数**: 24個
**到達不可能（未使用候補）**: 0個
**DOM操作の重複箇所**: 14箇所

---
## ⚠️ 同じ場所を操作する関数（重複候補）

> 同じDOM要素を複数の関数が操作している箇所。
> 古い方を削除するか、統合を検討してください。

### `#card3d`

- **[✅ 実行中]** `initCardTap()` (L1088)
  - 呼出元: init
  - 操作: getById
- **[✅ 実行中]** `checkTodayDraw()` (L1261)
  - 呼出元: init
  - 操作: getById

### `#cardElement`

- **[✅ 実行中]** `initCardTap()` (L1088)
  - 呼出元: init
  - 操作: getById
- **[✅ 実行中]** `checkTodayDraw()` (L1261)
  - 呼出元: init
  - 操作: getById

### `#cardEmoji`

- **[✅ 実行中]** `initCardTap()` (L1088)
  - 呼出元: init
  - 操作: getById
- **[✅ 実行中]** `checkTodayDraw()` (L1261)
  - 呼出元: init
  - 操作: getById

### `#cardFront`

- **[✅ 実行中]** `initCardTap()` (L1088)
  - 呼出元: init
  - 操作: getById
- **[✅ 実行中]** `checkTodayDraw()` (L1261)
  - 呼出元: init
  - 操作: getById

### `#cardKeyword`

- **[✅ 実行中]** `initCardTap()` (L1088)
  - 呼出元: init
  - 操作: getById
- **[✅ 実行中]** `checkTodayDraw()` (L1261)
  - 呼出元: init
  - 操作: getById

### `#cardNameEn`

- **[✅ 実行中]** `initCardTap()` (L1088)
  - 呼出元: init
  - 操作: getById
- **[✅ 実行中]** `checkTodayDraw()` (L1261)
  - 呼出元: init
  - 操作: getById

### `#cardNameJp`

- **[✅ 実行中]** `initCardTap()` (L1088)
  - 呼出元: init
  - 操作: getById
- **[✅ 実行中]** `checkTodayDraw()` (L1261)
  - 呼出元: init
  - 操作: getById

### `#cardPlanet`

- **[✅ 実行中]** `initCardTap()` (L1088)
  - 呼出元: init
  - 操作: getById
- **[✅ 実行中]** `checkTodayDraw()` (L1261)
  - 呼出元: init
  - 操作: getById

### `#cardScene`

- **[✅ 実行中]** `initCardTap()` (L1088)
  - 呼出元: init
  - 操作: getById
- **[✅ 実行中]** `checkTodayDraw()` (L1261)
  - 呼出元: init
  - 操作: getById

### `#drawnMsg`

- **[✅ 実行中]** `initCardTap()` (L1088)
  - 呼出元: init
  - 操作: getById
- **[✅ 実行中]** `checkTodayDraw()` (L1261)
  - 呼出元: init
  - 操作: getById

### `#moodSlider`

- **[✅ 実行中]** `updateMoodDisplay()` (L1520)
  - 呼出元: loadSavedMood
  - 操作: getById
- **[✅ 実行中]** `loadSavedMood()` (L1532)
  - 呼出元: init
  - 操作: getById

### `#stellaMsg`

- **[✅ 実行中]** `initCardTap()` (L1088)
  - 呼出元: init
  - 操作: getById
- **[✅ 実行中]** `checkTodayDraw()` (L1261)
  - 呼出元: init
  - 操作: getById

### `#stellaText`

- **[✅ 実行中]** `initCardTap()` (L1088)
  - 呼出元: init
  - 操作: getById
- **[✅ 実行中]** `saveHistory()` (L1158)
  - 呼出元: initCardTap
  - 操作: getById
- **[✅ 実行中]** `checkTodayDraw()` (L1261)
  - 呼出元: init
  - 操作: getById

### `#tapHint`

- **[✅ 実行中]** `initCardTap()` (L1088)
  - 呼出元: init
  - 操作: getById
- **[✅ 実行中]** `checkTodayDraw()` (L1261)
  - 呼出元: init
  - 操作: getById

---
## ❌ 未使用関数（削除候補）

（全関数が到達可能 — 未使用なし）

---
## 🎯 エントリーポイント（操作の起点）

| 種類 | 関数 | 詳細 |
|------|------|------|
| HTML属性 | `clearHistory()` | clearHistory() |
| HTML属性 | `toggleHistoryCard()` | toggleHistoryCard( |
| HTML属性 | `saveSynchronicity()` | saveSynchronicity( |
| トップレベル呼出 | `renderHistory()` |  |
| トップレベル呼出 | `updateMoodDisplay()` |  |
| トップレベル呼出 | `resizeCanvas()` |  |
| トップレベル呼出 | `checkTodayDraw()` |  |
| トップレベル呼出 | `initCardTap()` |  |
| トップレベル呼出 | `loadSavedMood()` |  |
| トップレベル呼出 | `init()` |  |

---
## 📍 DOM要素と操作する関数の対応表

> 各DOM要素を「誰が」操作しているかの一覧。

- `#card3d` ← `initCardTap()`, `checkTodayDraw()` ⚠️
- `#cardElement` ← `initCardTap()`, `checkTodayDraw()` ⚠️
- `#cardEmoji` ← `initCardTap()`, `checkTodayDraw()` ⚠️
- `#cardFront` ← `initCardTap()`, `checkTodayDraw()` ⚠️
- `#cardKeyword` ← `initCardTap()`, `checkTodayDraw()` ⚠️
- `#cardNameEn` ← `initCardTap()`, `checkTodayDraw()` ⚠️
- `#cardNameJp` ← `initCardTap()`, `checkTodayDraw()` ⚠️
- `#cardPlanet` ← `initCardTap()`, `checkTodayDraw()` ⚠️
- `#cardScene` ← `initCardTap()`, `checkTodayDraw()` ⚠️
- `#customLocInput` ← `getLocationLabel()`
- `#drawnMsg` ← `initCardTap()`, `checkTodayDraw()` ⚠️
- `#historyList` ← `renderHistory()`
- `#moodSlider` ← `updateMoodDisplay()`, `loadSavedMood()` ⚠️
- `#moodValDesc` ← `updateMoodDisplay()`
- `#moodValNum` ← `updateMoodDisplay()`
- `#readingTyping` ← `typewriteReading()`
- `#stellaMsg` ← `initCardTap()`, `checkTodayDraw()` ⚠️
- `#stellaText` ← `initCardTap()`, `saveHistory()`, `checkTodayDraw()` ⚠️
- `#tapHint` ← `initCardTap()`, `checkTodayDraw()` ⚠️
- `#tarotReadingAdvice` ← `showTarotReading()`
- `#tarotReadingBody` ← `showTarotReading()`
- `#tarotReadingPanel` ← `showTarotReading()`

---
## 📋 全関数一覧

### ✅ `generateStellaMsg(card, planetJP)` — L1030
- 呼出先: なし
- 呼出元: initCardTap

### ✅ `getToday()` — L1051
- 呼出先: なし
- 呼出元: checkTodayDraw, saveHistory

### ✅ `getNowTime()` — L1055
- 呼出先: なし
- 呼出元: saveHistory

### ✅ `getCardInfo(card)` — L1059
- 呼出先: なし
- 呼出元: initCardTap

### ✅ `getLocationLabel()` — L1075
- 呼出先: なし
- 呼出元: saveHistory
- DOM操作: #customLocInput

### ✅ `initCardTap()` — L1088
- 呼出先: generateStellaMsg, getCardInfo, saveHistory, showTarotReading, spawnParticles
- 呼出元: init
- DOM操作: #card3d, #cardElement, #cardEmoji, #cardFront, #cardKeyword, #cardNameEn, #cardNameJp, #cardPlanet, #cardScene, #drawnMsg, #stellaMsg, #stellaText, #tapHint, .phone-frame, scene.style

### ✅ `loadHistory()` — L1153
- 呼出先: なし
- 呼出元: checkTodayDraw, renderHistory, saveHistory, saveSynchronicity

### ✅ `saveHistory(card, info)` — L1158
- 呼出先: getLocationLabel, getNowTime, getToday, loadHistory, renderHistory
- 呼出元: initCardTap
- DOM操作: #stellaText

### ✅ `renderHistory()` — L1185
- 呼出先: loadHistory, saveSynchronicity, toggleHistoryCard
- 呼出元: clearHistory, init, saveHistory
- DOM操作: #historyList, container.innerHTML

### ✅ `toggleHistoryCard(i)` — L1221
- 呼出先: なし
- 呼出元: renderHistory

### ✅ `saveSynchronicity(index, value)` — L1225
- 呼出先: loadHistory
- 呼出元: renderHistory
- DOM操作: saved.classList

### ✅ `clearHistory()` — L1236
- 呼出先: renderHistory
- 呼出元: なし

### ✅ `checkTodayDraw()` — L1261
- 呼出先: getToday, loadHistory, showTarotReading
- 呼出元: init
- DOM操作: #card3d, #cardElement, #cardEmoji, #cardFront, #cardKeyword, #cardNameEn, #cardNameJp, #cardPlanet, #cardScene, #drawnMsg, #stellaMsg, #stellaText, #tapHint

### ✅ `resizeCanvas()` — L1317
- 呼出先: なし
- 呼出元: init
- DOM操作: .phone-frame

### ✅ `spawnParticles(cx, cy)` — L1323
- 呼出先: animLoop
- 呼出元: initCardTap

### ✅ `animLoop()` — L1341
- 呼出先: なし
- 呼出元: spawnParticles

### ✅ `getTarotCacheKey(card)` — L1397
- 呼出先: なし
- 呼出元: showTarotReading

### ✅ `showTarotReading(card, info)` — L1404
- 呼出先: getTarotCacheKey, showFallbackReading, typewriteReading
- 呼出元: checkTodayDraw, initCardTap
- DOM操作: #tarotReadingAdvice, #tarotReadingBody, #tarotReadingPanel, advice.textContent, body.innerHTML, body.textContent, panel.classList

### ✅ `typewriteReading(panel, body, advice, text, adviceText)` — L1464
- 呼出先: なし
- 呼出元: showFallbackReading, showTarotReading
- DOM操作: #readingTyping, advice.textContent, body.innerHTML, panel.classList, typingEl.classList

### ✅ `showFallbackReading(card, info, panel, body, advice)` — L1483
- 呼出先: typewriteReading
- 呼出元: showTarotReading

### ✅ `getMoodDesc(v)` — L1513
- 呼出先: なし
- 呼出元: updateMoodDisplay

### ✅ `updateMoodDisplay()` — L1520
- 呼出先: getMoodDesc
- 呼出元: loadSavedMood
- DOM操作: #moodSlider, #moodValDesc, #moodValNum, descEl.textContent, numEl.textContent

### ✅ `loadSavedMood()` — L1532
- 呼出先: updateMoodDisplay
- 呼出元: init
- DOM操作: #moodSlider

### ✅ `init()` — L1549
- 呼出先: checkTodayDraw, initCardTap, loadSavedMood, renderHistory, resizeCanvas
- 呼出元: なし
