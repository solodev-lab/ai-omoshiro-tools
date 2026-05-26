# 層 2a: API/Worker ラッパ

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 10 / 総行数: 2070
- class/mixin/extension/enum: 24
- 関数 (top-level + method の素拾い): 35
- Navigator.push 等: 0
- Popup/Dialog 呼出: 0
- Worker URL リテラル: 19

## ファイル別

### `lib/screens/map/map_astro.dart` (511 行)

**imports:** dart=2 / package=1 / relative=5

- relative: `../../utils/astro_math.dart`, `../../utils/direction_energy.dart`, `../../utils/solara_api.dart`, `../../utils/solara_storage.dart`, `map_constants.dart`

**型定義 (2):**

- L21 `class ChartResult`
  - CF Worker /astro/chart のレスポンス
- L190 `class ScoreResult`

**関数 (8 public + 3 private):**

- L67 `fetchChart()` — CF Worker にチャートを要求
- L262 `scoreAll()` — ChartResult → Map画面用16方位スコア
- L291 `getAB()`
- L300 `addT()`
- L302 `addP()`
- L329 `isAngle()`
- L414 `addCT()`
- L416 `addCP()`

  <details><summary>private 関数 3 件</summary>

  - L124 `_cosFall()`
  - L165 `_emptyComp()`
  - L237 `_addAspectComp()`

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


### `lib/utils/consultation_api.dart` (118 行)

**ファイル先頭コメント:**

```
Consultation API — クレジット系 (V2 と共有)

設計: project_solara_stella_free_credits.md

相談の本体 (候補生成 + Stella ナレーション) は V2 (consultation_v2_api.dart) に
移行済み。本ファイルには V2 でも使うクレジット系のみ残す:
  - ConsultationBlock (402 paywall 理由) + consultationBlockFromCode
  - ConsultationCreditStatus + fetchConsultationCredits
```

**imports:** dart=1 / package=2 / relative=2

- relative: `app_attest_client.dart`, `solara_api.dart`

**型定義 (3):**

- L24 `class ConsultationCreditEvents : ChangeNotifier`
  - クレジット残高変化のグローバル通知（singleton）。
- L31 `enum ConsultationBlock`
  - Free 試食クレジット切れ等で Worker が 402 を返したときのブロック理由。
- L61 `class ConsultationCreditStatus`
  - Stella 相談クレジットの現在状況 (無料週次残 + 購入残高)。

**関数 (3 public + 0 private):**

- L27 `notifyChanged()`
- L47 `consultationBlockFromCode()` — 402 paywall レスポンスの `error` コード → [ConsultationBlock]。
- L90 `fetchConsultationCredits()` — `/protected/consultation/credits` を呼んで現在のクレジット状況を取得する。


### `lib/utils/consultation_v2_api.dart` (373 行)

**ファイル先頭コメント:**

```
Consultation V2 API — POST /protected/astro/consultation2

設計: project_solara_consultation_full_integration.md (全要素統合)
Worker 側: apps/solara/worker/src/{consultation_engine,consultation_v2}.js

新方式: client は「誕生データ + 自宅座標 + 5問の答え + preset」(約1KB) だけ送り、
Worker がチャート/線/sectorEnergy/候補多様性/リロケハウスを全部計算して
Stella の言葉 (候補 1 つ + エビデンス + 初回のみ内的季節/intro/outro) を返す。
1 クレジット = 1 候補。「別の候補地」は excluded を足した再呼び出し (= +1 クレジット)。

旧 consultation_api.dart (client が候補を組む方式) は deployed app 用に温存。

HARD500 回避のため part 分割: リクエストモデルは consultation_v2_request.dart。
```

**imports:** dart=1 / package=1 / relative=4

- relative: `app_attest_client.dart`, `consultation_api.dart`, `solara_api.dart`, `solara_storage.dart`

**型定義 (7):**

- L31 `class ConsultationTimeWindowItem`
  - 時間帯リズムの 1 項目 (旅行の朝昼夜)。
- L48 `class ConsultationTimeWindow`
  - 時間帯 (現地の時間帯のみ・時計表示なし)。
- L95 `class ConsultationEvidenceKm`
  - エビデンスの距離行 (玄人向けに km を出す。本文には出さない)。
- L111 `class ConsultationEvidence`
  - エビデンス (占星術ファクターのみ。重み・選び方・プロンプトは出さない)。
- L147 `class ConsultationV2Candidate`
  - 1 候補地の Stella の読み (構造データ + ナレーション)。
- L212 `class ConsultationV2Reading`
  - 相談 V2 レスポンス全体 (成功時)。
- L275 `class ConsultationV2Result`
  - fetchConsultationV2 の戻り値。

**関数 (6 public + 0 private):**

- L43 `toJson()`
- L86 `toJson()`
- L107 `toJson()`
- L139 `toJson()`
- L195 `toJson()`
- L315 `fetchConsultationV2()` — /protected/astro/consultation2 を呼んで Stella の読み (候補 1 つ) を取得する。


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


### `lib/utils/legal_urls.dart` (56 行)

**ファイル先頭コメント:**

```
Solara 法務リンク定数 — Phase 2-6b

設計: docs/legal.md + launch_checklist Phase 0 (法的書類)

役割:
  - プライバシーポリシー / 利用規約 (EULA) / 特定商取引法に基づく表記 / 解約案内 の URL を一元化
  - 公開ブロッカー B5 (3.1.2): ペイウォールから EULA / プライバシーをクリック可能リンクで提示するため

現状 (2026-05-18):
  - 3 文書は solodev-lab.com 配下に静的公開 (legal/solara/ 配下)
  - 公開前に同じ URL に本物を up すれば、コード変更ゼロで反映される
  - 「解約方法」は iOS=設定アプリ deep link / Android=Play Store 該当ページ
    (どちらも `url_launcher.launchUrl(mode: externalApplication)` で開く)

🔴 特商法表記は Platform 分岐:
  - iOS = 個人事業主 林宏治 名義 (scta-ios.html)
  - Android = 法人 arrayu 株式会社 名義 (scta-android.html)
  - App Store と Google Play Developer Program の登録名義が異なるため両ストア審査の整合を取る

🔴 launch_checklist 連動:
  - Phase 0 完了時に同 URL に文書を公開してから審査提出する
  - Phase 0 未完で本番ビルドを出すと審査リジェクト (B5)、絶対に飛ばさない

🔴 i18n:
  - 当面 ja-JP のみ。ストアアップ前最終工程で EN 版 URL を追加 (feedback_i18n_last)
```

**imports:** dart=1 / package=0 / relative=0

**型定義 (1):**

- L29 `class LegalUrls`

**Worker URL リテラル (1):**

- L30: `'https://solodev-lab.com/legal/solara'`


### `lib/utils/reverse_geocode.dart` (100 行)

**imports:** dart=1 / package=1 / relative=0

**型定義 (1):**

- L35 `class ReverseGeocodeResult`
  - Nominatim Reverse の結果から取り出した詳細レコード。

**関数 (2 public + 0 private):**

- L23 `reverseGeocode()` — 緯度経度から地名（市町村名）を逆ジオコーディングで取得する。
- L68 `reverseGeocodeDetail()` — 緯度経度から逆ジオコーディングで region / country まで含む詳細を取得する。


### `lib/utils/solara_api.dart` (88 行)

**ファイル先頭コメント:**

```
Solara CF Worker API - 軽量なユーティリティ呼び出し
(チャート/イベント系は別ファイルに既存。ここは補助エンドポイント + URL 集約)
```

**imports:** dart=1 / package=1 / relative=0

**関数 (1 public + 0 private):**

- L75 `fetchTimezoneName()` — 緯度経度から IANA TZ名 (DST対応の基準) を取得。

**Worker URL リテラル (18):**

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
- L46: `'$solaraWorkerBase/auth/challenge'`
- L49: `'$solaraWorkerBase/auth/integrity/challenge'`
- L52: `'$solaraWorkerBase/protected/fortune'`
- L53: `'$solaraWorkerBase/protected/tarot'`
- L54: `'$solaraWorkerBase/protected/relocation'`
- L60: `'$solaraWorkerBase/protected/astro/consultation2'`
- L64: `'$solaraWorkerBase/protected/consultation/credits'`
- L70: `'$solaraWorkerBase/protected/account/delete'`


### `lib/utils/tile_http_client.dart` (42 行)

**imports:** dart=1 / package=3 / relative=0

