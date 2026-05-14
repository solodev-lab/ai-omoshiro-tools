# 層 1a: 純計算ユーティリティ

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 5 / 総行数: 1315
- class/mixin/extension/enum: 11
- 関数 (top-level + method の素拾い): 50
- Navigator.push 等: 0
- Popup/Dialog 呼出: 0
- Worker URL リテラル: 0

## ファイル別

### `lib/utils/astro_houses.dart` (208 行)

**imports:** dart=1 / package=0 / relative=1

- relative: `astro_math.dart`

**型定義 (1):**

- L28 `class HousesResult`
  - 任意座標で再計算した ASC / MC / 12 ハウス cusps。

**関数 (3 public + 8 private):**

- L57 `calcHousesRelocate()` — natalMc + natalLng (chart fetch時の lng) から LST を逆算し、
- L155 `cusp()`
- L196 `assignPlanetHouse()` — 黄経 [planetLon] が houses (12 cusps) のどのハウスに入るか判定 (1-12)。

  <details><summary>private 関数 8 件</summary>

  - L18 `_toRad()`
  - L19 `_toDeg()`
  - L21 `_clamp()`
  - L74 `_housesFromLst()`
  - L110 `_recoverLstFromMc()`
  - L117 `_calcAscendant()`
  - L131 `_calcMc()`
  - L141 `_placidusCusps()`

  </details>


### `lib/utils/astro_lines.dart` (479 行)

**imports:** dart=2 / package=1 / relative=1

- relative: `astro_math.dart`

**型定義 (4):**

- L41 `enum AstroFrame`
  - アストロカートグラフィの惑星フレーム (Tier A #5 / CCG)。
- L63 `class AstroLine`
  - アストロカートグラフィの 1 本のライン。
- L377 `class NearbyAstroLine`
  - 近接ラインの結果。距離付き。
- L442 `class _RankedLine`

**関数 (6 public + 9 private):**

- L43 `astroFrameKey()`
- L115 `gmstHoursFromUtc()` — 任意UTC時刻から GMST (時間, 0..24) を計算。Tier A #5 / CCG 用。
- L126 `solarArcPlanets()` — natal + progressed から Solar Arc (ソーラーアーク方向) の惑星位置を導出。
- L233 `buildAstroLines()` — 全 40本のアストロラインを計算 (natal フレーム)。
- L263 `buildAstroLinesAt()` — 任意フレーム × 任意 GMST のアスペクト線 40本を計算 (Tier A #5 / CCG 汎用)。
- L458 `findNearbyLinesScreen()` — 画面pixel距離で近接アスペクト線を検出する (Astro*Carto*Graphy モード専用)。

  <details><summary>private 関数 9 件</summary>

  - L50 `_toRad()`
  - L51 `_toDeg()`
  - L54 `_normLng()`
  - L59 `_clamp()`
  - L98 `_gmstHoursFromBaseline()`
  - L353 `_haversineKm()`
  - L365 `_minDistanceKmToLine()`
  - L397 `_pointToSegmentPx()`
  - L418 `_minPixelDistanceToLine()`

  </details>


### `lib/utils/astro_math.dart` (30 行)

**ファイル先頭コメント:**

```
══════════════════════════════════════════════════
Astro 数学ユーティリティ

重複検出 (audit T1 #4 / #5, 2026-05-05) で、4 ファイルに同一実装の角度
ユーティリティが散在していたため集約:
  - angDist:     horo_chart_data.dart (_angDist),
                 horo_pattern_logic.dart (local angDist x2),
                 map_astro.dart (_angDist)
  - normalize360: utils/astro_lines.dart (_norm360),
                  utils/astro_houses.dart (_norm360),
                  map_astro.dart (_norm360)

すべて引数を直接 % 360 で正規化する純関数で副作用なし。
黄経はもちろん、トランジット/プログレス/アスペクト等あらゆる角度演算で
共通利用される基礎関数なので、独立 util ファイルに切り出す。
══════════════════════════════════════════════════
```

**関数 (2 public + 0 private):**

- L20 `normalize360()` — 角度 d を 0..360 に正規化する。
- L27 `angDist()` — 2 つの角度の最小角距離 (0..180)。


### `lib/utils/direction_energy.dart` (238 行)

**ファイル先頭コメント:**

```
============================================================
Solara DirectionEnergy — Soft/Hard 独立2エネルギー

設計思想: project_solara_design_philosophy.md (2026-04-29 オーナー確定)

🔴 重要原則 🔴
  - ソフトとハードは独立した別エネルギー（1軸の両端ではない）
  - プラスマイナスではない、両方とも正の存在量
  - total / softRatio は意図的に持たない
    （合算/割合は1次元化を招き、設計思想に反する）

🔴 実装禁止 🔴
  - `double get total => soft + hard;` を追加しない
  - `double get softRatio => soft / (soft + hard);` を追加しない
  - UIで両エネルギーを1つの値に丸めて表示しない

🔴 実装すべき 🔴
  - soft / hard を独立した絶対値として保持
  - UI は2エネルギーを並列表示（バー2本、または S40/H25 形式）
  - 色は「赤=悪 緑=良」を避ける（ハード=金陽色、ソフト=銀月色 等）
============================================================
```

**型定義 (5):**

- L31 `class DirectionEnergy`
  - 16方位や時刻における2つの独立したエネルギー存在量。
- L79 `enum EnergyMode`
  - エネルギーの組み合わせによる性質分類。
- L113 `class AspectContribution`
  - 1アスペクトの方角への寄与量。
- L157 `class AggregatedAspect`
  - 集約済みアスペクト寄与。E4 ポップアップ用。
- L204 `class _AggBuilder`

**関数 (6 public + 0 private):**

- L48 `classify()` — 性質分類（4象限）。優劣ではなく、エネルギーの組み合わせの違い。
- L70 `toString()`
- L142 `scaledBy()` — 同じアスペクトを別の方角に寄与させる際の cosFall スケーリング。
- L182 `aggregateContributions()` — 寄与アスペクトリストを groupKey で集約し、magnitude の降順でソート。
- L222 `merge()`
- L228 `build()`


### `lib/utils/moon_phase.dart` (360 行)

**ファイル先頭コメント:**

```
Lunar phase utilities based on Jean Meeus "Astronomical Algorithms"
Chapter 49 — Phases of the Moon.

Precision: ±2-3 minutes for new/full moon times (vs ±17 hours with
simple Metonic cycle approximation).

Uses 14 correction terms for New Moon and Full Moon.
```

**imports:** dart=1 / package=0 / relative=0

**型定義 (1):**

- L11 `class MoonPhase`

**関数 (11 public + 5 private):**

- L193 `findPreviousNewMoon()` — Find the most recent New Moon on or before [date].
- L220 `findNextNewMoon()` — Find the next New Moon after [date].
- L232 `findFullMoonInCycle()` — Find the Full Moon nearest to [date] within the current cycle.
- L242 `getPhaseDay()` — Returns fractional moon phase day (0.0 = new moon, ~14.76 = full moon).
- L256 `getPhaseInt()` — Returns integer phase day (0-29) for display.
- L263 `isNewMoon()` — Is today a New Moon day? (within ±1 day of exact new moon)
- L270 `isFullMoon()` — Is today the Full Moon day? (the single closest day to exact full moon)
- L290 `getCycleTotalDays()` — How many total days in the current cycle.
- L297 `getCurrentDayIndex()` — Which day (0-based) in the current cycle is [date].
- L305 `getCycleId()` — Generate a unique cycle ID from the new moon date.
- L355 `getIllumination()` — Get the illumination fraction (0.0 to 1.0).

  <details><summary>private 関数 5 件</summary>

  - L23 `_computePhaseJDE()`
  - L153 `_jdeToDateTime()`
  - L162 `_dateTimeToDecimalYear()`
  - L171 `_deg2rad()`
  - L187 `_localDateAsUtc()`

  </details>

