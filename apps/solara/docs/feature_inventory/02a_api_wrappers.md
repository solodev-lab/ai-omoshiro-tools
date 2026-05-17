# 層 2a: API/Worker ラッパ

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 9 / 総行数: 1908
- class/mixin/extension/enum: 18
- 関数 (top-level + method の素拾い): 32
- Navigator.push 等: 0
- Popup/Dialog 呼出: 0
- Worker URL リテラル: 14

## ファイル別

### `lib/screens/map/map_astro.dart` (508 行)

**imports:** dart=2 / package=1 / relative=4

- relative: `../../utils/astro_math.dart`, `../../utils/direction_energy.dart`, `../../utils/solara_api.dart`, `map_constants.dart`

**型定義 (2):**

- L20 `class ChartResult`
  - CF Worker /astro/chart のレスポンス
- L187 `class ScoreResult`

**関数 (8 public + 3 private):**

- L66 `fetchChart()` — CF Worker にチャートを要求
- L259 `scoreAll()` — ChartResult → Map画面用16方位スコア
- L288 `getAB()`
- L297 `addT()`
- L299 `addP()`
- L326 `isAngle()`
- L411 `addCT()`
- L413 `addCP()`

  <details><summary>private 関数 3 件</summary>

  - L121 `_cosFall()`
  - L162 `_emptyComp()`
  - L234 `_addAspectComp()`

  </details>


### `lib/utils/celestial_events.dart` (313 行)

**imports:** dart=1 / package=2 / relative=1

- relative: `solara_api.dart`

**型定義 (3):**

- L14 `class CelestialEvents`
  - Loads and provides celestial event data for intention generation.
- L150 `class MonthEvents`
- L219 `class CelestialEvent`

**関数 (3 public + 1 private):**

- L18 `initialize()`
- L195 `eventSummary()` — Format active events as a summary string.
- L203 `copyWithEvents()` — API経由のリアル計算eventsで置換した新MonthEventsを返す

  <details><summary>private 関数 1 件</summary>

  - L64 `_getNewMoonDate()`

  </details>


### `lib/utils/consultation_api.dart` (141 行)

**ファイル先頭コメント:**

```
Consultation API — POST /astro/consultation (Stage 3)

設計: apps/solara/docs/pro_candidates.md §7.2 Stage 3
Worker 側: apps/solara/worker/src/consultation.js

Stage 2 (consultation_engine.dart) が組み立てた候補リストを送信し、
Stella の解釈 (intro / candidates[].narrative / outro) を受け取る。
```

**imports:** dart=1 / package=1 / relative=2

- relative: `consultation_engine.dart`, `solara_api.dart`

**型定義 (2):**

- L17 `class ConsultationCandidateReading`
  - API レスポンス内の候補別 Stella の解釈。
- L47 `class ConsultationReading`
  - API レスポンス全体。

**関数 (3 public + 0 private):**

- L39 `toJson()` — 履歴保存 (consultation_record) 用シリアライズ。
- L80 `toJson()` — 履歴保存 (consultation_record) 用シリアライズ。
- L101 `fetchConsultation()` — /astro/consultation を呼んで Stella の解釈を取得する。


### `lib/utils/daily_transits_api.dart` (241 行)

**ファイル先頭コメント:**

```
============================================================
Solara Daily Transits API

F1 (2026-04-29): 拠点 (自宅・職場等) における今日のトランジット惑星
アングル通過時刻を取得する。

Worker: /astro/daily-transits (POST)
設計: project_solara_design_philosophy.md
============================================================
```

**imports:** dart=1 / package=1 / relative=1

- relative: `solara_api.dart`

**型定義 (6):**

- L17 `class TransitAspect`
  - V2: その瞬間にトランジット惑星が natal 惑星と作るアスペクト。
- L46 `class TransitEvent`
  - 1イベント = ある惑星が4アングル(ASC/MC/DSC/IC)のどれか1つを通過した瞬間。
- L85 `class PlanetDailyTransits`
  - 1惑星 × 1日分の通過イベント (最大4個: ASC/MC/DSC/IC)。
- L105 `class LatitudeBandHit`
  - 緯度帯ヒット惑星 (Lewis 流の緯度効果)。
- L124 `class LatitudeBand`
  - 観測時刻における緯度帯セクション (zenith / nadir のヒット惑星 + オーブ)。
- L148 `class DailyTransitsResult`
  - /astro/daily-transits の完全レスポンス。

**関数 (2 public + 0 private):**

- L188 `flatTimeline()` — 全惑星の全イベントを時刻順にフラット化したリストを返す。
- L208 `fetchDailyTransits()` — 拠点における今日のトランジット通過時刻を取得する。


### `lib/utils/device_security_status.dart` (228 行)

**ファイル先頭コメント:**

```
Solara 端末セキュリティ状態 (RASP) — Phase 2 launch_checklist

設計:
  - launch_checklist Phase 2「RASP」3 項目
  - project_solara_security_principles 5 原則の補強
  - freerasp ^7.5.1 (talsec) を使用

役割:
  - 起動時に freerasp を init し、root/jailbreak/hook/debugger/emulator 等を
    継続監視するリスナーを attach する
  - 重大な脅威 (`_severeThreats`) を検知したら `isCompromised = true` で
    ChangeNotifier listener に通知する
  - 軽微な脅威 (devMode/screenshot 等) は記録のみで Pro 無効化はしない

🔴 Apple/Google ストア審査対応:
  - **無料機能はそのまま使える**ように設計する (Free を block すると審査でリジェクト)
  - Pro 機能のみ disable する (showProUnlockDialog 経由で「セキュリティ確認に
    失敗」表示、Pro 購入導線も出さない = 課金後 block で User trust 失う事を避ける)

🔴 設定値 (--dart-define、CI/local の双方で):
  --dart-define=SOLARA_FREERASP_ANDROID_HASH=<base64-sha256>  (release keystore cert hash)
  --dart-define=SOLARA_FREERASP_IOS_TEAM_ID=<TEAM>            (Apple Developer Team ID)
  --dart-define=SOLARA_FREERASP_WATCHER_MAIL=<email>          (任意、talsec backend reports)
  いずれか未設定で current platform を満たせない場合は **start をスキップ** (no-op)。

🔴 検証手順:
  - debug build: kDebugMode で start() を skip するため発火しない (テスト noise 回避)
  - 実 release build (R8 + obfuscate + 署名済) を root 化端末/Frida/emulator で
    起動 → 各 threat callback が発火することを実機確認 (TestFlight 配信前必須)
```

**imports:** dart=1 / package=2 / relative=0

**型定義 (1):**

- L36 `class DeviceSecurityStatus : ChangeNotifier`

**関数 (3 public + 3 private):**

- L106 `start()` — 起動時に 1 度だけ呼ぶ。
- L210 `resetForTest()`
- L225 `debugTriggerCompromised()`

  <details><summary>private 関数 3 件</summary>

  - L138 `_buildConfig()`
  - L163 `_buildCallback()`
  - L190 `_onThreat()`

  </details>


### `lib/utils/fortune_api.dart` (266 行)

**ファイル先頭コメント:**

```
Fortune API - /fortune エンドポイント (Stella の声を取得)
関連: worker/src/fortune.js
```

**imports:** dart=1 / package=1 / relative=1

- relative: `solara_api.dart`

**型定義 (3):**

- L9 `class FortuneReading`
  - Fortune APIレスポンス
- L91 `class RelocationNarrative`
- L184 `class TarotReading`

**関数 (3 public + 0 private):**

- L42 `fetchFortune()` — /fortune を叩いて占い文を取得
- L143 `fetchRelocationNarrative()` — /relocation を叩いてリロケーション解説を取得。
- L210 `fetchTarotReading()` — /tarot を叩いて1枚引きの Reading を生成する。


### `lib/utils/reverse_geocode.dart` (100 行)

**imports:** dart=1 / package=1 / relative=0

**型定義 (1):**

- L35 `class ReverseGeocodeResult`
  - Nominatim Reverse の結果から取り出した詳細レコード。

**関数 (2 public + 0 private):**

- L23 `reverseGeocode()` — 緯度経度から地名（市町村名）を逆ジオコーディングで取得する。
- L68 `reverseGeocodeDetail()` — 緯度経度から逆ジオコーディングで region / country まで含む詳細を取得する。


### `lib/utils/solara_api.dart` (69 行)

**ファイル先頭コメント:**

```
Solara CF Worker API - 軽量なユーティリティ呼び出し
(チャート/イベント系は別ファイルに既存。ここは補助エンドポイント + URL 集約)
```

**imports:** dart=1 / package=1 / relative=0

**関数 (1 public + 0 private):**

- L56 `fetchTimezoneName()` — 緯度経度から IANA TZ名 (DST対応の基準) を取得。

**Worker URL リテラル (14):**

- L17: `'https://solara-api.solodev-lab.com'`
- L29: `'$solaraWorkerBase/public/tz'`
- L30: `'$solaraWorkerBase/public/astro/chart'`
- L31: `'$solaraWorkerBase/public/astro/events'`
- L32: `'$solaraWorkerBase/public/astro/forecast'`
- L34: `'$solaraWorkerBase/public/astro/daily-transits'`
- L35: `'$solaraWorkerBase/public/search'`
- L40: `'$solaraWorkerBase/public/tiles/osm'`
- L43: `'$solaraWorkerBase/auth/whoami'`
- L44: `'$solaraWorkerBase/auth/attest'`
- L47: `'$solaraWorkerBase/protected/fortune'`
- L48: `'$solaraWorkerBase/protected/tarot'`
- L49: `'$solaraWorkerBase/protected/relocation'`
- L51: `'$solaraWorkerBase/protected/astro/consultation'`


### `lib/utils/tile_http_client.dart` (42 行)

**imports:** dart=1 / package=3 / relative=0

