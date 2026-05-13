# 層 2b: 永続化/キャッシュ

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 3 / 総行数: 907
- class/mixin/extension/enum: 7
- 関数 (top-level + method の素拾い): 51
- Navigator.push 等: 0
- Popup/Dialog 呼出: 0
- Worker URL リテラル: 1

## ファイル別

### `lib/utils/app_locale.dart` (41 行)

**imports:** dart=0 / package=2 / relative=0

**型定義 (1):**

- L8 `class AppLocale`
  - アプリ内の言語切替 (オーバーライド) を管理する global singleton。

**関数 (2 public + 0 private):**

- L18 `load()` — 起動時に SharedPreferences から復元
- L29 `setOverride()` — 言語を変更して保存 (null=端末設定に戻す)


### `lib/utils/forecast_cache.dart` (462 行)

**imports:** dart=1 / package=2 / relative=2

- relative: `solara_api.dart`, `solara_storage.dart`

**型定義 (4):**

- L8 `class ForecastDay`
  - Forecast 1日分のスコア。Worker `/astro/forecast` の day item と同形。
- L47 `class LifePeriod`
  - 運勢サイクル（「◯◯期」）1件分。
- L153 `class ForecastCache`
  - Forecast キャッシュ項目
- L196 `class ForecastRepo`

**関数 (9 public + 7 private):**

- L35 `toJson()`
- L62 `toJson()`
- L84 `detectLifePeriods()` — ForecastDay 列から各カテゴリの「◯◯期」を検出する。
- L164 `toJson()`
- L189 `profileHashOf()` — 出生情報のハッシュ。プロフィール変更を検知するために使う。
- L284 `loadCached()` — キャッシュから読み込む（profileHash が一致する場合のみ有効）
- L296 `cooldownRemaining()` — クールダウン残時間（0ならfetch可）。年オフセットごとに独立。
- L324 `fetchFull()` — Worker /astro/forecast を呼び出して全365日取得。
- L394 `refreshIncremental()` — 月次差分更新。

  <details><summary>private 関数 7 件</summary>

  - L198 `_cKey()`
  - L200 `_coolKey()`
  - L202 `_periodsKey()`
  - L204 `_top5StorageKey()`
  - L308 `_saveCache()`
  - L313 `_markFetched()`
  - L458 `_todayKey()`

  </details>

**Worker URL リテラル (1):**

- L177: `'$solaraWorkerBase/astro/forecast'`


### `lib/utils/solara_storage.dart` (404 行)

**imports:** dart=1 / package=1 / relative=3

- relative: `../models/daily_reading.dart`, `../models/galaxy_cycle.dart`, `../models/lunar_intention.dart`

**型定義 (2):**

- L8 `class SolaraProfile`
  - User profile data.
- L99 `class SolaraStorage`
  - Persistence wrapper for Solara data.

**関数 (32 public + 1 private):**

- L39 `toJson()`
- L69 `copyWith()`
- L115 `loadForecastColorMode()` — ヒートマップ色モード: 'relative' | 'absolute' | 'category'
- L120 `saveForecastColorMode()`
- L126 `loadForecastHighColor()` — 高スコア側の色: 'green' | 'red'
- L131 `saveForecastHighColor()`
- L137 `loadForecastYearOffset()` — Forecast 画面で最後に見た年オフセット（0-4）
- L142 `saveForecastYearOffset()`
- L149 `loadMapStyleId()`
- L154 `saveMapStyleId()`
- L161 `loadProfile()`
- L168 `saveProfile()`
- L185 `saveCurrentReadings()`
- L191 `addReading()`
- L203 `clearReadings()`
- L209 `updateSynchronicity()` — Update synchronicity text for a specific reading date.
- L222 `updateReading()` — Update an existing reading (matched by date) with new reading text.
- L236 `removeReadingByDate()` — Remove a reading by date (used for the dev "reset today" button).
- L253 `saveTitleData()`
- L258 `getTodayReading()`
- L281 `saveCompletedCycle()`
- L289 `clearCurrentReadings()`
- L296 `loadIntention()`
- L304 `saveIntention()`
- L314 `loadDailyResetHour()` — 1日の基準時刻（0-23時）。この時刻を跨ぐと「今日」が更新される。
- L320 `saveDailyResetHour()`
- L327 `loadDailyResetMinute()` — 1日の基準時刻 (分、0-59)。1 分単位ピッカーの導入で追加。
- L333 `saveDailyResetMinute()`
- L379 `wasOverlayShownToday()` — Track which overlay was shown today to avoid re-showing.
- L386 `markOverlayShown()`
- L394 `getNotTodayCount()` — Not today 押下回数（サイクルID単位で保存）
- L399 `incrementNotTodayCount()`

  <details><summary>private 関数 1 件</summary>

  - L366 `_logicalTodayKey()`

  </details>

