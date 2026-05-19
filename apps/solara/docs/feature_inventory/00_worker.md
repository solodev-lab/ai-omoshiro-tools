# 層 0: Worker (バックエンド計算式)

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 18
- エンドポイント総数: 24
- Gemini 呼出箇所: 2
- KV 使用: 4 行 / Durable Object 使用: 7 行

## ファイル別

### `worker/src/astro.js` (882 行)

**ファイル先頭コメント:**

```
Solara Astro Engine — Cloudflare Worker
Ported from: horoscope.html + shared/astro-math.js
Dependency: astronomy-engine (npm)
```

**export (4):** `computeChart`, `computePredictions`, `computeForecast`, `computeMonthEvents`


### `worker/src/auth/app_attest.js` (14 行)

**ファイル先頭コメント:**

```
Apple App Attest 検証 — barrel re-export (設計 v3.0)。

旧 app_attest.js (360 行、verifyAttestation + verifyAssertion 同居) を
役割別に分割した結果のエントリポイント:
- attestation.js (~270 行): 端末初回登録、9 step + 時刻チェック
- assertion.js   (~80 行):  毎リクエスト署名検証、4 step + signCount 抽出

既存の import 文 (`import { verifyAttestation, verifyAssertion } from
'./auth/app_attest.js'`) を壊さないため、本ファイルは re-export のみ。
新規追加時は直接 attestation.js / assertion.js から import しても OK。
```


### `worker/src/auth/apple_root_ca.js` (109 行)

**ファイル先頭コメント:**

```
Apple App Attest 検証で使う定数とヘルパー。

- APPLE_ROOT_CA_PEM: 2045-03-15 まで有効な Apple App Attestation Root CA (ECDSA P-384 self-signed)
フィンガープリント SHA-256(DER) = 1CB9823BA28BA6AD2D33A006941DE2AE4F513EF1D4E831B9F7E0FA7B6242C932
原本: apps/solara/docs/Apple_App_Attestation_Root_CA.pem
- AAGUID_PRODUCTION / AAGUID_DEVELOPMENT: authData[37..52] と比較する 16 バイト
- APPLE_NONCE_OID: credCert の Apple 独自拡張 OID
- SUB_CA_SUBJECT_HINT: 中間 CA の subject に必ず含まれる文字列
```

**export (12):** `APPLE_ROOT_CA_PEM`, `AAGUID_PRODUCTION`, `AAGUID_DEVELOPMENT`, `APPLE_NONCE_OID`, `SUB_CA_SUBJECT_HINT`, `concatBytes`, `bytesEqual`, `bytesToHex`, `bytesToBase64`, `base64ToBytes`, `readUint32BE`, `readUint16BE`


### `worker/src/auth/assertion.js` (90 行)

**ファイル先頭コメント:**

```
Apple App Attest 「assertion」 検証 (4 step + Step 5/6 caller 責任、設計 v3.0)。

protected/* リクエスト時に DCAppAttestService.generateAssertion() で生成された
CBOR を受け取り、署名検証 + rpId 一致 + signCount 抽出。

設計 v1.8 §16.2 payload 正規化規約に従い、caller (Worker middleware) が
`request.arrayBuffer()` で取得した raw bytes を payload としてそのまま渡す。
Flutter 側は `jsonEncode(map) → utf8.encode → Uint8List` で同一 bytes を生成して
HTTP body に置く契約 (これがズレると全 assertion 失敗 = Firebase 0% verified pattern)。

Step 5 (signCount monotonic) と Step 6 (challenge inclusion) の扱い:
- Step 5: 本関数が `signCount` (= 受信した assertion 内の値) を返すので、
caller が DO の前回値と比較して strictly greater を確認 + DO 更新
- Step 6: 設計 v1.8 §16.3 で不採用 (signCount monotonic + DO consume で代替)

Reference implementation: node-app-attest (MIT, Copyright (c) 2024 David Übelacker)
https://github.com/uebelack/node-app-attest
```

**export (1):** `verifyAssertion`


### `worker/src/auth/attestation.js` (274 行)

**ファイル先頭コメント:**

```
Apple App Attest 「attestation」 検証 (9 step、設計 v3.0)。

端末初回起動時に DCAppAttestService.attestKey() で生成された CBOR を受け取り、
9 step で検証 → 成功時 publicKeyPem を返す (caller は DO 永続化)。

Reference implementation: node-app-attest (MIT, Copyright (c) 2024 David Übelacker)
https://github.com/uebelack/node-app-attest
Apple X509Certificate を @peculiar/x509 に置き換え、Buffer/Node 依存を Workers
(nodejs_compat) 互換に整理した派生実装。

Apple 公式仕様:
https://developer.apple.com/documentation/devicecheck/validating-apps-that-connect-to-your-server

戻り値の方針:
- 成功時: { ok: true, publicKeyPem, environment, receipt }
- 失敗時: { ok: false, error: '<verify_error_code>' } を return (例外を投げない)
設計 v1.4 Q1 (詳細エラーコード) に合致。
```

**export (1):** `verifyAttestation`


### `worker/src/auth/attestation_state.js` (386 行)

**ファイル先頭コメント:**

```
Apple App Attest + RevenueCat エンタイトルメント用 Durable Object (SQLite-backed)。

設計 v1.8 §6.1 + v2.2 (RevenueCat Webhook 統合) に従い、1 instance
(`idFromName('global')`) に 5 表を集約:
- attestations:      端末ごとの公開鍵 + counter (App Attest)
- challenges:        server 発行 challenge の強整合管理 (one-time use)
- user_quota:        per-user rate limit (Layer C、Free=5/日 Pro=100/日)
- user_entitlements: appUserId × entitlementId の Pro 状態 (RevenueCat Webhook で書込)
- webhook_events:    Webhook event_id の idempotent 受信ログ (重複送信耐性)

単一 DO instance への集約理由:
- DAU 1,500 想定で同時刻書き込み <100/sec → DO の sequential write 内に余裕で収まる
- 複数 instance に sharding すると billing と運用コスト上昇
- 将来バズった場合のみ keyId-prefix sharding に切替 (= 256 instance に分散)

外部 HTTP API (`fetch(request)`):
POST /challenge-create  body: {challengeId, challengeBytes, expiresAt}
POST /challenge-consume body: {challengeId, now}  → {challengeBytes} or 404
POST /attestation-store body: {keyId, publicKeyPem, rpId, aaguid, now}
POST /attestation-get   body: {keyId}              → {publicKeyPem, counter} or 404
POST /attestation-bump-counter body: {keyId, signCount, now}  → {ok} or 409 (signCount <= prev)
POST /quota-check-and-bump body: {keyId, dayBucket, limit, now}
→ {ok: tru
```

**Durable Object 使用 (1 行):**

- 出現行: L5

**export (1):** `AttestationState`


### `worker/src/auth/cbor.js` (131 行)

**ファイル先頭コメント:**

```
Apple App Attest CBOR subset デコーダ。

App Attest が使う CBOR は以下に限定されるので、フル仕様 (RFC 8949) は実装しない:
- major 0: unsigned int (0..2^32-1)
- major 2: byte string (Uint8Array で返す、最大 2^32 bytes)
- major 3: text string (string で返す、UTF-8)
- major 4: array (Array で返す)
- major 5: map (plain object で返す、key は string のみサポート)

不要 (App Attest で出現しない):
- major 1 (negative int) / 6 (tag) / 7 (special: float, true/false, null)
- 2^32 を超える長さの byte/text (App Attest の receipt は ~5KB、cert ~1KB、authData ~200B)
- 8 byte length encoding (additional info 27)

Reference implementation: node-app-attest (MIT, Copyright (c) 2024 David Übelacker)
https://github.com/uebelack/node-app-attest

Buffer 非依存 (Workers 互換、Uint8Array のみ)。
```

**export (2):** `CborError`, `decodeFirst`


### `worker/src/auth/entitlement_cache.js` (80 行)

**ファイル先頭コメント:**

```
Worker instance ローカルの entitlement キャッシュ。

目的:
protected/* 1 リクエストごとに DO へ entitlement-get する代わりに、
60s TTL のメモリ Map で間引く (= DO billing と latency 両方を下げる)。

整合性:
- cold start ごとに空。Worker instance が短命のため十分。
- Webhook 受信 instance は INSERT 直後に clearMemoryEntitlementCache を呼ぶ。
- 他 instance は最悪 60s で次回 read 時に DO から最新を取得 (eventual)。
- false positive (Pro じゃないのに Pro 判定) は最大 60s 発生し得る。
refund/cancellation 直後 60s は Pro 維持 = 攻撃には使えない、UX 影響だけ。

形状: Map<appUserId, {snapshot, fetchedAt}>
snapshot: {isActive, expiresAt, environment, productId, periodType} or null (= 404)
fetchedAt: ms
```

**export (4):** `getCachedEntitlement`, `setCachedEntitlement`, `clearMemoryEntitlementCache`, `_resetEntitlementCacheForTest`


### `worker/src/consultation.js` (330 行)

**ファイル先頭コメント:**

```
Solara (ii) Stella 相談 — Stage 3 (Gemini API バックエンド)

設計: apps/solara/docs/pro_candidates.md §7.2 Stage 3

クライアント (Stage 2 = consultation_engine.dart) が組み立てた候補リストを
受け取り、Gemini Flash を裏方として Stella が「悩み (テーマ + 自由記述) に
照らした解釈」を生成して返す。Stella は方角・エネルギーだけ示す。
店舗名・固有名詞は返さない。

注: Gemini はあくまでバックエンドの実装で、ユーザーには「Stella」として
振る舞う。プロンプトでも Stella と自称する。

入力 body:
{
theme: 'love'|'money'|'work'|'communication'|'healing'|'newStart',
mode:  'migration'|'travel'|'daily',
scope: 'specific'|'region'|'world'|'bearings',
freeText?: string,                       // 任意。自由記述 (悩み詳細)
candidates: [{                            // 1..3 件、Stage 2 出力
name, nameEN, lat, lng, country, region,
bearing?: 'N'|'NE'|...,                // daily モード時のみ
nearLines: [{planet, angle, aspect, distanceKm}, ...]
}],
excluded?: string[],                      // リフレッシュ用、既出候補名
lang?: 'ja'                               // v1 は ja 固定
}

出力:
{
intro: string,                            // 50-100 字
candidates: [{ name, energyLabels[], narrative }],
outro: string,                            // 100-130 字
model: string,                            // 実際に使ったモデル名
fallback?: boolean                        // Stella が届かない時 true (静的テンプレ)
}

設計思想ガー
```

**export (1):** `handleConsultation`


### `worker/src/daily_transits.js` (273 行)

**ファイル先頭コメント:**

```
Solara Daily Transits — Cyclo*Carto*Graphy at fixed location.

F1 (2026-04-29): ユーザーの拠点 (自宅 / 職場 等) から見て、
各トランジット惑星が 4 アングル (ASC/MC/DSC/IC) を通過する時刻を1日分計算する。

設計: project_solara_design_philosophy.md
- 「動き出す時刻」を伝えるためのデータレイヤー。
- 「ラッキータイム」「アンラッキータイム」とは言わない。
- その時刻に在るエネルギーを事実として伝える。

数学:
- MC 通過: planet's hour_angle = 0 (upper culmination)
- IC 通過: planet's hour_angle = 12h (lower culmination)
- ASC 通過: rising time (Astronomy.SearchRiseSet direction = +1)
- DSC 通過: setting time (direction = -1)

astronomy-engine API:
- Astronomy.SearchHourAngle(body, observer, hourAngle, startTime, direction)
- Astronomy.SearchRiseSet(body, observer, direction, startTime, limitDays)
```

**export (1):** `computeDailyTransits`


### `worker/src/fortune.js` (318 行)

**ファイル先頭コメント:**

```
Fortune Reading — Stella の占い文生成 (Gemini API バックエンド)

入力: category, natal, transit?, aspects, patterns, lang('ja'|'en')
出力: { reading, advice, direction }

GEMINI_API_KEY は wrangler secret put GEMINI_API_KEY で設定
モデル: gemini-2.5-flash (テキスト生成、低コスト)

── Fortune カテゴリ定義 ──
houses: そのカテゴリで重視する伝統占星術のハウス番号
1H=自己, 2H=所有/才能/収入, 3H=対話/兄弟/短距離, 4H=家庭/基盤,
5H=恋愛/楽しみ/創造, 6H=日常業務/健康, 7H=パートナー/結婚, 8H=共有資産/変容,
9H=哲学/遠距離/学問, 10H=社会的地位/キャリア, 11H=友人/ネットワーク, 12H=潜在意識/隠れた事
```

**Gemini API 呼出 (1):**

- L100: `generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;`

**export (3):** `computeCategoryScore`, `callGemini`, `handleFortune`


### `worker/src/index.js` (700 行)

**ファイル先頭コメント:**

```
Solara API — Cloudflare Worker

🔴 ルート物理分離 (project_solara_security_principles.md §2):
public/*     誰でも OK    純数学計算 (`/astro/chart` 等)、マップタイル、検索
auth/*       Sign in 系   whoami / App Attest 登録
protected/*  重防御       Gemini 呼び出し全部 (`/fortune`/`/tarot`/`/relocation`
`/astro/consultation`/`/astro/line-narrative`)。
attestation + entitlement (RevenueCat 連携) +
per-user rate limit (Free=5 Pro=100 /日)。
webhooks/*   外部連携      RevenueCat Webhook (Pro 状態の真の出所)。

旧 top-level ルート (`/fortune` `/astro/chart` 等) は撤廃。Flutter クライアント側も
同セッションで新 path に書き換え済（`apps/solara/lib/utils/solara_api.dart` 参照）。
```

**エンドポイント / ルート (24):**

| method | path | line |
| --- | --- | --- |
| ? | /public/astro/forecast | L484 |
| ? | /public/tiles/* | L485 |
| ? | /webhooks/* | L486 |
| ? | /public/health | L494 |
| GET | /public/tiles/osm/* | L499 |
| POST | /public/astro/chart | L504 |
| POST | /public/astro/forecast | L512 |
| POST | /public/astro/predict | L527 |
| POST | /public/astro/daily-transits | L535 |
| GET | /public/tz | L543 |
| GET | /public/astro/events | L552 |
| GET | /public/search | L563 |
| GET | /auth/whoami | L585 |
| POST | /auth/challenge | L588 |
| POST | /auth/attest | L591 |
| POST | /protected/fortune | L605 |
| POST | /protected/tarot | L615 |
| POST | /protected/relocation | L625 |
| POST | /protected/astro/line-narrative | L637 |
| POST | /protected/astro/consultation | L647 |
| ? | /public/* | L682 |
| ? | /auth/* | L684 |
| ? | /protected/* | L686 |
| ? | /webhooks/revenuecat | L688 |

**KV 使用 (4 行):**

- 出現行: L103, L106, L111, L175

**Durable Object 使用 (3 行):**

- 出現行: L217, L217, L217


### `worker/src/line_narrative.js` (268 行)

**ファイル先頭コメント:**

```
Astro*Carto*Graphy Line Narrative — Stella の線解説 (Gemini API バックエンド)

A*C*G ライン（natal / transit 2フレーム × 10惑星 × 4アングル）の
タップ詳細解説を Stella が動的生成する。

注: 2026-05-11 撤去済 (クライアント呼出なし)。ファイルは互換のため残置。

入力:
{
frame: 'natal' | 'transit',  // 4フレームのうち β対応は2つ
planet: 'venus' | ...,
angle: 'ASC' | 'MC' | 'DSC' | 'IC',
tappedLat, tappedLng, tappedPlaceName,
natalSummary: {                 // 文脈ヒント（任意）
ascSign: 0-11, mcSign: 0-11,
sunSign: 0-11, moonSign: 0-11
},
transitDate: ISO8601,           // frame='transit' のとき
userName, lang: 'ja' | 'en'
}
出力:
{
title, narrative, softNote, hardNote, lang
}

設計思想: project_solara_design_philosophy.md
- Soft/Hard は独立2エネルギー、吉凶判定禁止
- 「ラッキー」「アンラッキー」「良い/悪い」禁止
- 「在る・効く・動く」で表現

フォールバック: クライアント側で API 失敗時は静的辞書 (astro_glossary)
```

**export (1):** `handleLineNarrative`


### `worker/src/relocation.js` (183 行)

**ファイル先頭コメント:**

```
Relocation Narrative — Stella のリロケーション解説生成 (Gemini API バックエンド)

入力: { shifts: [{planet, fromHouse, toHouse}],
ascChange: {fromSign, toSign} | null,
mcChange: {fromSign, toSign} | null,
birthPlaceName, homeName, userName, lang }
出力: { shifts: [{planet, narrative}],
ascNarrative, mcNarrative, summary, lang }

Phase B: 静的テンプレート (horo_relocation_templates.dart) を動的解説で上書き。
フォールバック: API失敗時は呼出側 (Dart) で null を受け、静的テンプレ表示。
```

**export (1):** `handleRelocation`


### `worker/src/search.js` (144 行)

**ファイル先頭コメント:**

```
Place Name Search — Google Places API (New) primary → Nominatim fallback

Google Places (New): https://places.googleapis.com/v1/places:searchText
- 月10,000 req/月 無料枠 (Essentials SKU)
- 駅・建物・カフェ等のPOI検索が高精度
- X-Goog-FieldMask で取得フィールドを制限してコスト削減

Nominatim: https://nominatim.openstreetmap.org/search
- 完全無料、1 req/sec
- Google が key 未設定 / API 失敗時の最終フォールバック

オーナー判断 (2026-04-30): Google を優先に切替
理由: 駅名・ランドマーク・カフェ等POIに強い、住所表記が綺麗、海外精度も高い
コスト: β段階 (~月100人 × 月20回検索) は無料枠の20%、本番初期ぎりぎり、
本番拡大で月$100-200 課金見込み
```

**export (1):** `searchPlace`


### `worker/src/tarot.js` (252 行)

**ファイル先頭コメント:**

```
Tarot Reading — Stella のタロット占い文生成 (Gemini API バックエンド)

入力:
cardId (0-77), reversed (bool), nameJP, keyword, element, planet?,
moonPhase (0-29.53), userName?, lang ('ja'|'en')

出力: { reading }
reading: 3〜5文の鑑定（〜250文字）

GEMINI_API_KEY は wrangler secret put GEMINI_API_KEY で設定済み
モデル: env vars TAROT_MODEL_PRIMARY/FALLBACK で指定（廃止リスク対策）
```

**Gemini API 呼出 (1):**

- L44: `generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;`

**export (1):** `handleTarot`


### `worker/src/tzlookup.js` (90 行)

**ファイル先頭コメント:**

```
IANA TimeZone lookup from lat/lng.
Uses bounding-box heuristic for common regions, falls back to longitude-based offset.

目的: Solara の出生チャート計算で、DST 考慮の正確な UTC 変換を実現する。
精度: 主要国 (JP/US/CN/KR/IN/AU/UK/EU/etc) は IANA TZ名 を返す。
境界や小国: `Etc/GMT±X` 固定オフセット fallback。

より高精度が必要な場合は tz-lookup npm パッケージ採用を検討。

[minLat, maxLat, minLng, maxLng, IANA TZ name]
優先度順 (最初にマッチしたものを採用)
```

**export (1):** `lookupTimezone`


### `worker/src/webhooks/revenuecat.js` (268 行)

**ファイル先頭コメント:**

```
RevenueCat Webhook 受信 (`POST /webhooks/revenuecat`)

設計:
- apps/solara/docs/revenuecat_webhook.md (本実装と同時新規)
- project_solara_launch_checklist.md Phase 1 「Webhook 受信」
- project_solara_security_principles.md 原則 1「クライアント単独 isPro 禁止」

認証:
- `Authorization: Bearer <REVENUECAT_WEBHOOK_AUTH>` を constant-time 比較
- 値は RevenueCat ダッシュボード Integrations → Webhooks で Solara が設定する任意文字列

状態管理:
- Pro エンタイトルメント状態は `AttestationState` Durable Object に統合
(1 instance 集約、`webhook_events` 表で event_id 冪等性保証)

イベント体系 (RevenueCat 公式 + サブスクライフサイクル):
active 化:
INITIAL_PURCHASE / RENEWAL / PRODUCT_CHANGE / UNCANCELLATION
NON_RENEWING_PURCHASE / TEMPORARY_ENTITLEMENT_GRANT
active 維持 (キャンセル予約 / 課金問題は期限内有効):
CANCELLATION (auto_renew=false だが expiration まで有効)
BILLING_ISSUE (grace period 内)
inactive 化:
EXPIRATION / REFUND
旧 user 失効 + 新 user に付与:
TRANSFER
何もしない:
SUBSCRIBER_ALIAS (anonymous→authenticated alias 通知、entitlement は別 event で来る)
TEST (RC ダッシュボードのテスト送信)

戻り値:
200 {ok: true, ...}        正常処理
200 {ok: true, ignored: …} 未知 event / Solara entitlement 対象外
401 {error: 'unauthorized'} Bearer 認証失敗
400 {error: 'invalid_…'}   Body 形式異常
500 ...                    DO エラー (RC は失敗時に再送する)

🔴 Cache invalidation:
middleware 
```

**Durable Object 使用 (3 行):**

- 出現行: L105, L105, L105

**export (2):** `handleRevenueCatWebhook`, `_internal`

