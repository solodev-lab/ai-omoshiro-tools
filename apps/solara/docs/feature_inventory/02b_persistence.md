# 層 2b: 永続化/キャッシュ

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 9 / 総行数: 2406
- class/mixin/extension/enum: 14
- 関数 (top-level + method の素拾い): 110
- Navigator.push 等: 0
- Popup/Dialog 呼出: 0
- Worker URL リテラル: 0

## ファイル別

### `lib/utils/app_attest_client.dart` (456 行)

**ファイル先頭コメント:**

```
Solara App Attest / Play Integrity クライアント (Flutter ↔ Worker /auth/* /protected/*)

役割:
  iOS (App Attest):
    - 起動時に keyId を SharedPreferences から復元、なければ Worker で attest
    - /protected/* 呼び出し時の HTTP header に X-AppAttest-KeyId/Assertion を付与
    - DCError.invalidInput/invalidKey 時の key 再生成リトライ
  Android (Play Integrity Standard、S5 追加):
    - 起動時に prepareTokenProvider(cloudProjectNumber) で warmup (≈1 時間有効)
    - /protected/* 呼び出しごとに /auth/integrity/challenge で nonce 取得 →
      clientData = {nonce, uid, ts} を JSON 化 → verify(clientData) で token 取得 →
      X-PlayIntegrity-Token / -ClientData / -NonceId をヘッダー注入
  - iOS Simulator / Web / kDebugMode / Cloud Project Number 未設定では bypass

Worker 側仕様: apps/solara/worker/src/index.js
  POST /auth/challenge            → {challengeId, challenge: base64(32B), ttlSec}
  POST /auth/attest               body: {keyId, challengeId, attestation: base64}
  POST /auth/integrity/challenge  → {nonceId, nonce: base64(32B), ttlSec}  (S4 追加)
  /protected/* headers (iOS):     X-AppAttest-KeyId, X-AppAttest-Assertion
  /protected/* headers (Android): X-PlayIntegrity-Token, X-PlayIntegrity-ClientData, X-PlayIntegrity-NonceId

設計: apps/solara/docs/app_attest_design.md (iOS v2.0+)
     apps/solara/docs/play_integrity_design.md (Android v0.7+)
```

**imports:** dart=2 / package=5 / relative=2

- relative: `purchases_service.dart`, `solara_api.dart`

**型定義 (1):**

- L58 `class AppAttestClient`
  - AppAttestClient シングルトン。

**関数 (10 public + 7 private):**

- L117 `initialize()` — 起動時 1 回だけ呼ぶ (main.dart で unawaited)。
- L228 `addHeaders()` — /protected/* 呼び出し直前に header を注入。
- L359 `withAppUserIdMerged()` — 呼び出し側で body Map を構築している場合に使う公開 helper。
- L364 `postProtected()` — `/protected/*` への POST を attestation header 付きで送る wrapper。
- L383 `reattestOnFailure()` — 401 で middleware に弾かれた時のリトライ用。
- L409 `debugPayloadSha256()` — payload bytes の SHA-256 (debug 用、Worker 側計算値との一致確認に使う)。
- L424 `addAndroidHeadersForTest()`
- L430 `addIosHeadersForTest()`
- L442 `initializeAndroidForTest()`
- L446 `resetForTest()`

  <details><summary>private 関数 7 件</summary>

  - L119 `_doInitialize()`
  - L136 `_initializeIos()`
  - L154 `_attestNewKey()`
  - L194 `_initializeAndroid()`
  - L254 `_addIosHeaders()`
  - L303 `_addAndroidHeaders()`
  - L349 `_withAppUserId()`

  </details>


### `lib/utils/app_locale.dart` (41 行)

**imports:** dart=0 / package=2 / relative=0

**型定義 (1):**

- L8 `class AppLocale`
  - アプリ内の言語切替 (オーバーライド) を管理する global singleton。

**関数 (2 public + 0 private):**

- L18 `load()` — 起動時に SharedPreferences から復元
- L29 `setOverride()` — 言語を変更して保存 (null=端末設定に戻す)


### `lib/utils/consultation_share.dart` (154 行)

**ファイル先頭コメント:**

```
Consultation Share — シェアエクスポート (V2: 全要素統合)

設計: project_solara_consultation_full_integration.md

2 つのエクスポート手段:
  1. テキストコピー: 蓄積した候補群を plain text に整形 → Clipboard
  2. 画像共有: 結果画面の RepaintBoundary を PNG 化 → SharePlus

シェアは Pro 限定 (結果画面側で Pro ゲート)。
```

**imports:** dart=2 / package=4 / relative=2

- relative: `consultation_record.dart`, `consultation_v2_api.dart`

**関数 (3 public + 0 private):**

- L47 `formatConsultationAsText()` — 相談結果を plain text に整形する。
- L108 `shareConsultationImage()` — RepaintBoundary を PNG 化して OS 標準シェアシートで共有する。
- L139 `formatConsultationCaption()` — シェア用のキャプション短縮版 (画像と一緒に添える text)。


### `lib/utils/forecast_cache.dart` (399 行)

**imports:** dart=1 / package=2 / relative=2

- relative: `solara_api.dart`, `solara_storage.dart`

**型定義 (4):**

- L8 `class ForecastDay`
  - Forecast 1日分のスコア。Worker `/astro/forecast` の day item と同形。
- L47 `class LifePeriod`
  - 運勢サイクル（「◯◯期」）1件分。
- L153 `class ForecastCache`
  - Forecast キャッシュ項目
- L198 `class ForecastRepo`

**関数 (8 public + 7 private):**

- L35 `toJson()`
- L62 `toJson()`
- L84 `detectLifePeriods()` — ForecastDay 列から各カテゴリの「◯◯期」を検出する。
- L164 `toJson()`
- L191 `profileHashOf()` — 出生情報のハッシュ。プロフィール変更を検知するために使う。
- L286 `loadCached()` — キャッシュから読み込む（profileHash が一致する場合のみ有効）
- L298 `cooldownRemaining()` — クールダウン残時間（0ならfetch可）。年オフセットごとに独立。
- L331 `fetchFull()` — Worker /astro/forecast を呼び出して暦年(1/1〜12/31)分を取得。

  <details><summary>private 関数 7 件</summary>

  - L200 `_cKey()`
  - L202 `_coolKey()`
  - L204 `_periodsKey()`
  - L206 `_top5StorageKey()`
  - L310 `_saveCache()`
  - L315 `_markFetched()`
  - L321 `_daysInYear()`

  </details>


### `lib/utils/fortune_cache.dart` (62 行)

**imports:** dart=1 / package=1 / relative=3

- relative: `fortune_api.dart`, `forecast_cache.dart`, `solara_storage.dart`

**型定義 (1):**

- L19 `class FortuneCacheRepo`
  - Horo「今日の占い」の永続キャッシュ。

**関数 (1 public + 2 private):**

- L49 `save()` — カテゴリ別 readings を保存する (値が null のカテゴリは除外)。

  <details><summary>private 関数 2 件</summary>

  - L22 `_dateStr()`
  - L25 `_key()`

  </details>


### `lib/utils/galaxy_cycle_export.dart` (126 行)

**ファイル先頭コメント:**

```
Galaxy Cycle エクスポート — C5 (Pro 機能、柱 3)

設計: apps/solara/docs/pro_candidates.md §7.3 + §3 C5

役割:
  - 完了した [GalaxyCycle] を Markdown / 画像で外部書き出し
  - LunarIntention (内包する CatasterismResult) があれば併記
  - 画像は RepaintBoundary → PNG 1080px (consultation_share と同パターン)

柱 3 原則: 「記録は Free でも全件閲覧」「Pro が売るのは記録を使う道具」。
エクスポートは「記録を使う道具」側なので Pro ゲート対象。
(ゲート自体は呼出側で showProUnlockDialog 経由で済ませる、本ファイルは pure utility。)
```

**imports:** dart=2 / package=4 / relative=2

- relative: `../models/galaxy_cycle.dart`, `../models/lunar_intention.dart`

**関数 (3 public + 1 private):**

- L27 `formatGalaxyCycleAsMarkdown()` — 1 サイクルを Markdown に整形する。Stella や Solara 内で完結する書式で、
- L75 `formatGalaxyCycleCaption()` — シェア用の短いキャプション (画像と一緒に添える text)。
- L89 `shareGalaxyCycleImage()` — RepaintBoundary を PNG 化して OS 標準シェアシートで共有する。

  <details><summary>private 関数 1 件</summary>

  - L120 `_isoDate()`

  </details>


### `lib/utils/pro_status.dart` (96 行)

**ファイル先頭コメント:**

```
Solara Pro 状態管理 — Phase 2-6a (暫定) + Phase 2 RASP 連携

設計: apps/solara/docs/pro_candidates.md §7 + project_solara_security_principles.md

役割:
  - SharedPreferences に Pro フラグを保存し、UI が同期で参照できる cache を持つ
  - ChangeNotifier 経由で Pro 切替を全画面に即時反映
  - DeviceSecurityStatus と連動: 端末セキュリティ侵害時は **isPro を false に倒す**

状態の二段構え:
  `isPro`     = effective state (UI 表示・ゲート判定で使う)
                = `_isPro && !DeviceSecurityStatus.instance.isCompromised`
  `isProRaw`  = RC エンタイトルメント生の値 (Sanctuary DEV toggle / Paywall 内
                「現在 Pro 中」表示で使う、セキュリティ侵害判定を含まない)

現状 (Phase 2-6a):
  - 暫定的にクライアント単独でフラグ管理 (DEV ビルドでは Sanctuary から toggle 可能)
  - 本番ビルドでは default false 固定、ユーザーが操作する手段はない
  - 機能ゲートの「配線」だけ済ませる目的

Phase 2-6b 以降 (RevenueCat 接続後):
  - RevenueCat callback で `setPro` を呼んで本物の購読状態を反映
  - Worker 側で署名検証もする (project_solara_security_principles の原則 1
    「クライアント単独 isPro 禁止」を守るため、機密機能は Worker でも再チェック)

🔴 セキュリティ原則 (security_principles.md):
  - クライアント側 isPro だけでロックを完結させない
  - Stella 相談の Worker 呼出は最終的に Sign in + サーバ側 Pro 検証で守る
  - 本ファイルは「UI の出し分け」までを担当する
```

**imports:** dart=0 / package=2 / relative=1

- relative: `device_security_status.dart`

**型定義 (1):**

- L36 `class ProStatus : ChangeNotifier`

**関数 (3 public + 0 private):**

- L66 `load()` — SharedPreferences から読み出して内部キャッシュを更新する。
- L78 `setPro()` — Pro 状態を更新する。永続化 + リスナー通知。
- L89 `resetForTest()`


### `lib/utils/solara_auth.dart` (417 行)

**ファイル先頭コメント:**

```
Solara 認証サービス — Phase 2-9 Sign in 統合

設計:
  - launch_checklist Phase 2「Sign in 統合」
  - project_solara_security_principles 原則 3「App User ID は Sign in with Apple/Google の uid」
  - Apple Guideline 5.4: Google 提供時は Apple 必須 (iOS のみ)

役割:
  - Sign in with Apple / Google を抽象化し、現在のアカウント情報を提供
  - 成功時に PurchasesService.logIn(uid) を呼び、RevenueCat の appUserID を切替え
  - サインアウト時に PurchasesService.logOut を呼ぶ
  - ChangeNotifier で UI に反映

設計判断:
  - Sign in は **任意**。Free ユーザーは未サインインのまま全機能使える
  - Pro 購入も anonymous appUserID で可能 (StoreKit/Play Billing が紐付け、復元は OS が担保)
  - サインインで端末跨ぎ復元が安定する旨を UI で案内し、推奨に留める
  - Android では Apple Sign in は不可 (service ID + redirect URI が必要、本フェーズでは非対応)。
    Apple 公式パッケージは Android 対応だが、サーバー側 service 設定が必要なため初期は iOS のみ

🔴 API キー注入 (--dart-define):
  --dart-define=SOLARA_GOOGLE_IOS_CLIENT_ID=xxxxx.apps.googleusercontent.com
  --dart-define=SOLARA_GOOGLE_SERVER_CLIENT_ID=xxxxx.apps.googleusercontent.com
  未設定でも GoogleSignIn.initialize() は呼ばれるが、ネイティブ設定 (GoogleService-Info.plist /
  google-services.json) があれば動く。クライアント ID を渡すと優先される
```

**imports:** dart=3 / package=4 / relative=3

- relative: `app_attest_client.dart`, `purchases_service.dart`, `solara_api.dart`

**型定義 (4):**

- L40 `enum SolaraAuthProvider`
- L43 `class SolaraAuthAccount`
  - 認証済アカウント情報。
- L98 `class SolaraAuthException : Exception`
  - 認証エラー (UI が型で分岐できるよう薄い wrapper)。
- L106 `class SolaraAuth : ChangeNotifier`

**関数 (8 public + 7 private):**

- L64 `toJson()`
- L103 `toString()`
- L129 `load()` — 起動時に 1 度呼ぶ。SharedPreferences から復元 + provider 別の silent restore。
- L191 `signInWithApple()` — Apple サインイン (iOS / macOS 推奨)。
- L237 `signInWithGoogle()` — Google サインイン (iOS / Android / macOS / Web)。
- L256 `signOut()` — 現在のアカウントを取り外す。
- L289 `deleteAccount()` — アカウント削除 (App Store ガイドライン 5.1.1(v) — Sign in を提供する以上、
- L407 `resetForTest()`

  <details><summary>private 関数 7 件</summary>

  - L154 `_verifyOrClear()`
  - L313 `_purgeServerAccountData()`
  - L335 `_ensureGoogleInitialized()`
  - L349 `_onGoogleEvent()`
  - L365 `_adoptGoogleAccount()`
  - L375 `_commitAccount()`
  - L388 `_clearLocalSession()`

  </details>


### `lib/utils/solara_storage.dart` (655 行)

**imports:** dart=1 / package=2 / relative=4

- relative: `../models/daily_reading.dart`, `../models/galaxy_cycle.dart`, `../models/lunar_intention.dart`, `consultation_record.dart`

**型定義 (2):**

- L10 `class SolaraProfile`
  - User profile data.
- L101 `class SolaraStorage`
  - Persistence wrapper for Solara data.

**関数 (47 public + 1 private):**

- L41 `toJson()`
- L71 `copyWith()`
- L126 `loadForecastColorMode()` — ヒートマップ色モード: 'relative' | 'absolute' | 'category'
- L131 `saveForecastColorMode()`
- L137 `loadForecastHighColor()` — 高スコア側の色: 'green' | 'red'
- L142 `saveForecastHighColor()`
- L148 `loadForecastYearOffset()` — Forecast 画面で最後に見た年オフセット（0-4）
- L153 `saveForecastYearOffset()`
- L160 `loadMapStyleId()`
- L165 `saveMapStyleId()`
- L172 `loadProfile()`
- L179 `saveProfile()`
- L196 `saveCurrentReadings()`
- L202 `addReading()`
- L214 `clearReadings()`
- L220 `updateSynchronicity()` — Update synchronicity text for a specific reading date.
- L233 `updateReading()` — Update an existing reading (matched by date) with new reading text.
- L247 `removeReadingByDate()` — Remove a reading by date (used for the dev "reset today" button).
- L270 `saveTitleData()`
- L301 `addTitleHistoryEntry()` — 称号診断結果を履歴に追加する。
- L333 `clearTitleHistory()` — 履歴全削除 (Sanctuary 設定からの「すべて削除」用)。
- L341 `updateTitleHistoryNote()` — 指定 savedAt のエントリにメモを書き込む (200 字 cap、超過は切詰)。
- L355 `getTodayReading()`
- L365 `loadLastFreeTarotDay()` — 無料タロット (全体運) を最後に引いた「論理日」(YYYY-MM-DD)。未記録なら null。
- L373 `markFreeTarotDrawn()` — 無料タロット (全体運) を「今日」引いたものとして記録する。
- L386 `hasDrawnFreeTarotToday()` — 無料タロット (全体運) を「今日 (論理日)」もう引いたか。
- L394 `clearFreeTarotDay()` — テスト用: 無料タロットの引き記録をクリア (再ドロー可能に戻す)。
- L411 `saveCompletedCycle()`
- L429 `updateCompletedCycleReadingSynchronicity()` — 過去サイクルに含まれる reading の synchronicity (自由メモ) を更新する。
- L444 `clearCurrentReadings()`
- L451 `loadIntention()`
- L459 `saveIntention()`
- L469 `loadDailyResetHour()` — 1日の基準時刻（0-23時）。この時刻を跨ぐと「今日」が更新される。
- L475 `saveDailyResetHour()`
- L482 `loadDailyResetMinute()` — 1日の基準時刻 (分、0-59)。1 分単位ピッカーの導入で追加。
- L488 `saveDailyResetMinute()`
- L503 `loadHouseSystem()` — ハウスシステム設定を読み込む (未保存は 'placidus')。同期キャッシュも更新。
- L511 `saveHouseSystem()` — ハウスシステム設定を保存する。同期キャッシュも即時更新。
- L553 `logicalTodayKey()` — リセット時刻 (「1日の開始時刻」設定) を考慮した「今日」の論理日キー
- L566 `wasOverlayShownToday()` — Track which overlay was shown today to avoid re-showing.
- L573 `markOverlayShown()`
- L581 `getNotTodayCount()` — Not today 押下回数（サイクルID単位で保存）
- L586 `incrementNotTodayCount()`
- L616 `addConsultationRecord()` — 履歴を 1 件追加 (新しい順で先頭、上限超過分は古いものから削除)。
- L628 `setConsultationFavorite()` — id 指定でお気に入りフラグを設定。見つからない場合は no-op。
- L637 `deleteConsultationRecord()` — id 指定で 1 件削除。見つからない場合は no-op。
- L644 `clearConsultationHistory()` — 履歴全削除 (Sanctuary 設定からの「すべて削除」用)。

  <details><summary>private 関数 1 件</summary>

  - L649 `_writeConsultationHistory()`

  </details>

