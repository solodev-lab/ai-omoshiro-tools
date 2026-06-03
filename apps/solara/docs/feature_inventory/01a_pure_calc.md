# 層 1a: 純計算ユーティリティ

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 9 / 総行数: 1857
- class/mixin/extension/enum: 16
- 関数 (top-level + method の素拾い): 68
- Navigator.push 等: 0
- Popup/Dialog 呼出: 0
- Worker URL リテラル: 0

## ファイル別

### `lib/utils/ai_report_api.dart` (52 行)

**ファイル先頭コメント:**

```
AI 出力ユーザー報告 API クライアント (Google Generative AI Apps Policy 対応)。

設計根拠: apps/solara/docs/store_compliance.md §3.1

Worker 側 endpoint (`POST /protected/report-ai-output`) は CF Logs に
console.warn で出力するのみ。永続保存はしない (オーナー判断 2026-05-28)。
詳細は worker/src/ai_report.js を参照。

UI 側 (widgets/ai_report_button.dart) からの呼出専用。失敗してもユーザー体験は
致命的ではないため、bool で成否を返すのみ (例外は捕捉して false)。

`/protected/*` 呼び出しは AppAttestClient.postProtected 経由 (設計 v2.1)。
middleware が log_only モードなら bypass、enforced モードなら attestation 必須。
```

**imports:** dart=1 / package=0 / relative=2

- relative: `app_attest_client.dart`, `solara_api.dart`

**型定義 (1):**

- L18 `class AiReportApi`

**関数 (1 public + 0 private):**

- L29 `reportAiOutput()` — AI 出力を運営に報告する。


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


### `lib/utils/astro_lines.dart` (535 行)

**imports:** dart=2 / package=1 / relative=1

- relative: `astro_math.dart`

**型定義 (5):**

- L43 `enum AstroFrame`
  - アストロカートグラフィの惑星フレーム (Tier A #5 / CCG)。
- L65 `class AstroLine`
  - アストロカートグラフィの 1 本のライン。
- L245 `class _AspectPass`
  - B1 アスペクトラインのパス定義。
- L425 `class NearbyAstroLine`
  - 近接ラインの結果。距離付き。
- L498 `class _RankedLine`

**関数 (8 public + 9 private):**

- L45 `astroFrameKey()`
- L130 `gmstHoursFromUtc()` — 任意UTC時刻から GMST (時間, 0..24) を計算。Tier A #5 / CCG 用。
- L141 `solarArcPlanets()` — natal + progressed から Solar Arc (ソーラーアーク方向) の惑星位置を導出。
- L267 `buildAstroLines()` — 全 120本のアストロラインを計算 (natal フレーム)。
- L297 `buildAstroLinesAt()` — 任意フレーム × 任意 GMST のアストロライン 120本を計算 (Tier A #5 / CCG 汎用)。
- L432 `haversineKm()` — 2 点の Haversine 距離 (km)。consultation_engine.dart 等の再利用用 public。
- L436 `minDistanceKmToLine()` — 1 本の AstroLine 上の最近接点までの最短 Haversine 距離 (km)。
- L514 `findNearbyLinesScreen()` — 画面pixel距離で近接アスペクト線を検出する (Astro*Carto*Graphy モード専用)。

  <details><summary>private 関数 9 件</summary>

  - L52 `_toRad()`
  - L53 `_toDeg()`
  - L56 `_normLng()`
  - L61 `_clamp()`
  - L113 `_gmstHoursFromBaseline()`
  - L401 `_haversineKm()`
  - L413 `_minDistanceKmToLine()`
  - L453 `_pointToSegmentPx()`
  - L474 `_minPixelDistanceToLine()`

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


### `lib/utils/moon_event_status.dart` (58 行)

**imports:** dart=0 / package=0 / relative=3

- relative: `../models/lunar_intention.dart`, `moon_phase.dart`, `solara_storage.dart`

**型定義 (2):**

- L6 `enum MoonEventKind`
  - 月のサイクル儀式の 3 イベント種別。
- L13 `class MoonEventStatus`
  - 月イベント (新月・満月・刻星化) が「今この瞬間に保留中か」を判定する単一の真実。

**関数 (1 public + 0 private):**

- L25 `pendingToday()` — 今 ([now] = 端末ローカル時刻) 保留中で、かつ「まだ今日 overlay を表示していない」


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


### `lib/utils/purchases_service.dart` (308 行)

**ファイル先頭コメント:**

```
Solara RevenueCat ラッパー — Phase 2-6b

設計:
  - launch_checklist Phase 2「サブスク基盤」
  - project_solara_security_principles 原則 1「クライアント単独 isPro 禁止」
  - pro_candidates §7.2 Phase 2-6b

役割:
  - purchases_flutter 10.x を init し、entitlement 更新で ProStatus.setPro を呼ぶ
  - Offerings / 購入 / 復元 の API を 1 箇所に集約
  - API キー未設定 / 未対応 OS では no-op (DEV トグルにフォールバック)

🔴 RevenueCat 「.enforced」モードは現行 SDK には無い (.disabled / .informational のみ)。
   本クラスでは informational で SDK 検証を有効化し、`verification == failed` の時は
   Pro 判定しない方式で security_principles 原則 1 を担保する。
   将来 Worker 側 /auth/whoami が出来たら、API 呼出時にサーバ再検証で二重チェックする。

🔴 Sign in with Apple/Google の uid 連携 (Purchases.logIn) は Phase 2「Sign in 統合」で実装。
   本フェーズでは anonymous appUserID で運用 (公開前に必ず Sign in を入れる)。

🔴 API キーは --dart-define で渡す (リポジトリにコミットしない):
   --dart-define=SOLARA_RC_IOS_KEY=appl_xxxx
   --dart-define=SOLARA_RC_ANDROID_KEY=goog_xxxx
   未設定なら configure をスキップし `isConfigured = false`。
```

**imports:** dart=0 / package=3 / relative=1

- relative: `pro_status.dart`

**型定義 (1):**

- L32 `class PurchasesService`

**関数 (10 public + 1 private):**

- L126 `init()` — 起動時に 1 度だけ呼ぶ。
- L198 `isEntitledFrom()`
- L208 `getOfferings()` — 配信中の Offerings を取得。未配信 / オフライン時は null。
- L222 `getCreditOffering()` — 消費型 Stella クレジットの Offering を取得 (未配信 / 未 configure は null)。
- L237 `purchasePackage()` — パッケージを購入。成功時は listener 経由で ProStatus が更新される。
- L258 `restorePurchases()` — 復元。RevenueCat が同一 appUserID 配下の過去購入を再リンクする。
- L273 `logIn()` — Sign in 完了後に uid を渡す (`SolaraAuth._commitAccount` から呼ばれる)。
- L280 `logOut()` — サインアウト時に呼ぶ。SDK が新しい anonymous uid を発行するので再 cache。
- L293 `setLastCustomerInfoForTest()`
- L300 `disposeForTest()`

  <details><summary>private 関数 1 件</summary>

  - L182 `_onCustomerInfo()`

  </details>


### `lib/utils/solara_i18n.dart` (68 行)

**imports:** dart=0 / package=0 / relative=1

- relative: `app_locale.dart`

**関数 (3 public + 0 private):**

- L18 `isEnLocale()` — 現在 English 表示にすべきか。AppLocale override == 'en' のときのみ true。
- L57 `tr()` — key → 現在ロケールの文字列。未登録キーは key をそのまま返す (開発時に気づける)。
- L65 `categoryLabel()` — 内部カテゴリ id (all/overall/healing/money/love/work/career/communication/newStart)

