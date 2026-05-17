# 層 2b: 永続化/キャッシュ

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 7 / 総行数: 1777
- class/mixin/extension/enum: 12
- 関数 (top-level + method の素拾い): 80
- Navigator.push 等: 0
- Popup/Dialog 呼出: 0
- Worker URL リテラル: 0

## ファイル別

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
Consultation Share — Phase 2-5 シェアエクスポート

設計: apps/solara/docs/pro_candidates.md §7.2 Stage 4

2 つのエクスポート手段:
  1. テキストコピー: ConsultationReading を plain text に整形 → Clipboard
  2. 画像共有: 結果画面の RepaintBoundary を PNG 化 → SharePlus

Phase 2-5 (v1): UI のみ、Pro ゲート未配線。設計上は Pro 機能。
Phase 2-6 (課金基盤後): Pro チェックで非 Pro はゲートする。
```

**imports:** dart=2 / package=4 / relative=1

- relative: `consultation_api.dart`

**関数 (3 public + 0 private):**

- L46 `formatConsultationAsText()` — 相談結果を plain text に整形する。
- L105 `shareConsultationImage()` — RepaintBoundary を PNG 化して OS 標準シェアシートで共有する。
- L140 `formatConsultationCaption()` — シェア用のキャプション短縮版 (画像と一緒に添える text)。


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


### `lib/utils/solara_auth.dart` (357 行)

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

**imports:** dart=3 / package=4 / relative=1

- relative: `purchases_service.dart`

**型定義 (4):**

- L38 `enum SolaraAuthProvider`
- L41 `class SolaraAuthAccount`
  - 認証済アカウント情報。
- L96 `class SolaraAuthException : Exception`
  - 認証エラー (UI が型で分岐できるよう薄い wrapper)。
- L104 `class SolaraAuth : ChangeNotifier`

**関数 (7 public + 6 private):**

- L62 `toJson()`
- L101 `toString()`
- L127 `load()` — 起動時に 1 度呼ぶ。SharedPreferences から復元 + provider 別の silent restore。
- L189 `signInWithApple()` — Apple サインイン (iOS / macOS 推奨)。
- L235 `signInWithGoogle()` — Google サインイン (iOS / Android / macOS / Web)。
- L254 `signOut()` — 現在のアカウントを取り外す。
- L347 `resetForTest()`

  <details><summary>private 関数 6 件</summary>

  - L152 `_verifyOrClear()`
  - L275 `_ensureGoogleInitialized()`
  - L289 `_onGoogleEvent()`
  - L305 `_adoptGoogleAccount()`
  - L315 `_commitAccount()`
  - L328 `_clearLocalSession()`

  </details>


### `lib/utils/solara_storage.dart` (541 行)

**imports:** dart=1 / package=1 / relative=4

- relative: `../models/daily_reading.dart`, `../models/galaxy_cycle.dart`, `../models/lunar_intention.dart`, `consultation_record.dart`

**型定義 (2):**

- L9 `class SolaraProfile`
  - User profile data.
- L100 `class SolaraStorage`
  - Persistence wrapper for Solara data.

**関数 (37 public + 2 private):**

- L40 `toJson()`
- L70 `copyWith()`
- L122 `loadForecastColorMode()` — ヒートマップ色モード: 'relative' | 'absolute' | 'category'
- L127 `saveForecastColorMode()`
- L133 `loadForecastHighColor()` — 高スコア側の色: 'green' | 'red'
- L138 `saveForecastHighColor()`
- L144 `loadForecastYearOffset()` — Forecast 画面で最後に見た年オフセット（0-4）
- L149 `saveForecastYearOffset()`
- L156 `loadMapStyleId()`
- L161 `saveMapStyleId()`
- L168 `loadProfile()`
- L175 `saveProfile()`
- L192 `saveCurrentReadings()`
- L198 `addReading()`
- L210 `clearReadings()`
- L216 `updateSynchronicity()` — Update synchronicity text for a specific reading date.
- L229 `updateReading()` — Update an existing reading (matched by date) with new reading text.
- L243 `removeReadingByDate()` — Remove a reading by date (used for the dev "reset today" button).
- L266 `saveTitleData()`
- L297 `addTitleHistoryEntry()` — 称号診断結果を履歴に追加する。
- L329 `clearTitleHistory()` — 履歴全削除 (Sanctuary 設定からの「すべて削除」用)。
- L334 `getTodayReading()`
- L357 `saveCompletedCycle()`
- L365 `clearCurrentReadings()`
- L372 `loadIntention()`
- L380 `saveIntention()`
- L390 `loadDailyResetHour()` — 1日の基準時刻（0-23時）。この時刻を跨ぐと「今日」が更新される。
- L396 `saveDailyResetHour()`
- L403 `loadDailyResetMinute()` — 1日の基準時刻 (分、0-59)。1 分単位ピッカーの導入で追加。
- L409 `saveDailyResetMinute()`
- L461 `wasOverlayShownToday()` — Track which overlay was shown today to avoid re-showing.
- L468 `markOverlayShown()`
- L476 `getNotTodayCount()` — Not today 押下回数（サイクルID単位で保存）
- L481 `incrementNotTodayCount()`
- L511 `addConsultationRecord()` — 履歴を 1 件追加 (新しい順で先頭、上限超過分は古いものから削除)。
- L523 `deleteConsultationRecord()` — id 指定で 1 件削除。見つからない場合は no-op。
- L530 `clearConsultationHistory()` — 履歴全削除 (Sanctuary 設定からの「すべて削除」用)。

  <details><summary>private 関数 2 件</summary>

  - L448 `_logicalTodayKey()`
  - L535 `_writeConsultationHistory()`

  </details>

