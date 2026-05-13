# 層 1c: モデルクラス

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 4 / 総行数: 337
- class/mixin/extension/enum: 7
- 関数 (top-level + method の素拾い): 8
- Navigator.push 等: 0
- Popup/Dialog 呼出: 0
- Worker URL リテラル: 0

## ファイル別

### `lib/models/daily_reading.dart` (41 行)

**型定義 (1):**

- L1 `class DailyReading`

**関数 (1 public + 0 private):**

- L20 `toJson()`


### `lib/models/galaxy_cycle.dart` (119 行)

**imports:** dart=0 / package=0 / relative=1

- relative: `daily_reading.dart`

**型定義 (2):**

- L3 `class ConstellationDot`
- L41 `class GalaxyCycle`

**関数 (2 public + 1 private):**

- L20 `toJson()`
- L84 `toJson()`

  <details><summary>private 関数 1 件</summary>

  - L76 `_monthName()`

  </details>


### `lib/models/lunar_intention.dart` (105 行)

**ファイル先頭コメント:**

```
Represents a user's chosen intention for a lunar cycle.
```

**型定義 (3):**

- L2 `class LunarIntention`
  - Represents a user's chosen intention for a lunar cycle.
- L67 `class MidpointCheck`
  - Full moon midpoint check-in.
- L88 `class CatasterismResult`
  - End-of-cycle catasterism self-assessment (刻星化).

**関数 (4 public + 0 private):**

- L21 `copyWith()`
- L36 `toJson()`
- L73 `toJson()`
- L94 `toJson()`


### `lib/models/tarot_card.dart` (72 行)

**型定義 (1):**

- L1 `class TarotCard`

