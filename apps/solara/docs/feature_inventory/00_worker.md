# 層 0: Worker (バックエンド計算式)

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 27
- エンドポイント総数: 32
- Gemini 呼出箇所: 2
- KV 使用: 4 行 / Durable Object 使用: 12 行

## ファイル別

### `worker/src/ai_report.js` (47 行)

**ファイル先頭コメント:**

```
AI 出力ユーザー報告 — Google Generative AI Apps Policy (2026-04-15 全面施行) 対応。

設計根拠: apps/solara/docs/store_compliance.md §3.1

Google Play は「AI 生成コンテンツを出すアプリは、ユーザーが不適切な出力を
アプリ内で** 報告できる UI を必須化」と要求。Solara は Stella 相談 / Tarot
Horo の 3 経路で Gemini を呼び出すため、各結果画面に「報告」ボタンを設置し、
押されたら本 endpoint へ送信する。

オーナー判断 (2026-05-28):
保存先 = console.warn 経由で Cloudflare Workers Logs のみ (永続保存はしない)。
- CF Dashboard > Workers > solara-api > Logs で「[AI_REPORT]」で検索可
- 保存期間: Free 3 日 / Paid 7 日。Solara 公開初期は報告量も少ない想定で十分。
- パターン検知が必要になったら、別途 DO 保存への昇格を検討。

文字数 cap:
- feature/reason: 32 文字 (enum 想定だが防御的に切る)
- freeText: 500 文字 (ユーザー自由記述)
- outputText: 2000 文字 (AI 出力本体、Solara の最長 Horo/Tarot/Stella 1 回答想定)
- 合計 ~2.5KB / 報告。CF Logs 1 行に収まる。

報告された PII 保護:
- appUserId は middleware が注入する RC 匿名 ID のみ。氏名・出生情報は送らない。
- 結果テキスト内に AI が生成したユーザー名等が混入する可能性は残るが、
報告経路でしか送られないため通常運用では問題なし。


@param {object} body { feature, reason, freeText, outputText, __appUserId }
@returns {{ok:true, ts:string}}
```

**export (1):** `handleAiReport`


### `worker/src/astro.js` (898 行)

**ファイル先頭コメント:**

```
Solara Astro Engine — Cloudflare Worker
Ported from: horoscope.html + shared/astro-math.js
Dependency: astronomy-engine (npm)
```

**export (4):** `computeChart`, `computePredictions`, `computeForecast`, `computeMonthEvents`


### `worker/src/astro_lines.js` (253 行)

**ファイル先頭コメント:**

```
Solara Astro Lines (Worker port) — Stella 相談 Phase 1。

lib/utils/astro_lines.dart を JS に忠実移植したもの。アストロカートグラフィ
(Jim Lewis 流) の 4 アングル本線 + アスペクト線を地球曲面に計算する。
数式・定数 (obliquity 23.4393 / Meeus GMST) は Dart 版と完全一致させ、
Map が描いている線と相談エンジンの線が同一になるようにする
(= エビデンスチップに出す占星術ファクターが画面と矛盾しない)。

各惑星 × 4 アングル (mc/ic/asc/dsc) × 3 アスペクトパス (conjunction / square
trine+sextile) = 120 本。frame (natal/transit/progressed/solarArc) ごとに呼ぶ。

線オブジェクト形:
{ planet, angle, aspect, frame, segments: [[{lat,lng},...]],
zenith?: {lat,lng}, nadir?: {lat,lng} }
```


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


### `worker/src/auth/apple_revoke.js` (182 行)

**ファイル先頭コメント:**

```
Apple Sign In Token Revocation (App Store Review Guideline 5.1.1(v) 厳密解釈対応)。

用途:
ユーザーがアプリ内アカウント削除を行ったときに、Apple ID 側との連携も完全に
失効させる (= Apple ID の「Apple ID を使用しているサインイン履歴」から Solara が消える)。

Apple 公式:
- https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api/revoke_tokens
- https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api/generate_and_validate_tokens

必須 secret / env (wrangler.toml + secret put):
- APPLE_SIWA_SERVICE_ID  : Apple Developer Console で発行する Sign in with Apple
用 Service ID (例 "com.solodevlab.solara.signin")。
Bundle ID とは別の identifier。public。wrangler.toml vars。
- APPLE_SIWA_KEY_ID      : Authentication Key (P8) の 10 桁 ID。public。wrangler.toml vars。
- APPLE_TEAM_ID          : 既存。wrangler.toml vars。
- APPLE_SIWA_PRIVATE_KEY : .p8 ファイルの中身 (PEM、"BEGIN PRIVATE KEY" 含む)。
wrangler secret put で登録。

鍵が未設定の場合は revoke を no-op で skip (= 公開前にコード先行 deploy 可能)。

Apple revoke endpoint (公式固定)。
```

**export (3):** `_setFetchForTest`, `buildAppleClientSecret`, `revokeAppleToken`


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


### `worker/src/auth/assertion.js` (91 行)

**ファイル先頭コメント:**

```
Apple App Attest 「assertion」 検証 (4 step + Step 5/6 caller 責任、設計 v3.0)。

protected/* リクエスト時に DCAppAttestService.generateAssertion() で生成された
CBOR を受け取り、署名検証 + rpId 一致 + signCount 抽出。

本関数は汎用: 渡された `payload` bytes を SHA-256 して nonce を作り署名検証する。
caller (index.js verifyAppleAssertionFlow) が「何を payload として渡すか」で規約が決まる。

🔴 設計 v3.1 (2026-05-22) でリプレイ防止を counter → リクエスト毎チャレンジに変更:
- caller は `clientData` (= JSON({challenge, uid, ts}) のヘッダー文字列) の utf8 を
payload として渡す。プラグインが SHA256(utf8(clientData)) で署名するため一致する。
- リプレイ防止は caller 側の「使い捨て challenge 単回消費」で行う (本関数が返す
signCount は参照しない = counter 厳密増加は廃止。並行リクエストで誤 401 になる盲点)。
- 旧 v1.8: payload = HTTP body raw bytes + signCount monotonic。clientDataHash の
base64/raw 取り違えで fail_nonce_mismatch、並行で sign_count_not_greater が出た。

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


### `worker/src/auth/attestation_state.js` (945 行)

**ファイル先頭コメント:**

```
Apple App Attest + RevenueCat エンタイトルメント + Play Integrity 用 Durable Object (SQLite-backed)。

設計 v1.8 §6.1 + v2.2 (RevenueCat Webhook 統合) + Play Integrity v0.6 §5 に従い、
1 instance (`idFromName('global')`) に 6 表を集約:
- attestations:      端末ごとの公開鍵 + counter (App Attest)
- challenges:        App Attest 用 server 発行 challenge の強整合管理 (one-time use、BLOB)
- user_quota:        per-user rate limit (Layer C、Free=5/日 Pro=100/日)
- user_entitlements: appUserId × entitlementId の Pro 状態 (RevenueCat Webhook で書込)
- webhook_events:    Webhook event_id の idempotent 受信ログ (重複送信耐性)
- integrity_nonces:  Play Integrity Standard request 用 nonce (one-time use、TEXT base64)
- consultation_credits: Stella 相談の Free 試食クレジット (端末ごと週次カウンター)
- consultation_pro_credits: Stella 相談の Pro 週次キャップカウンター (端末ごと週次、別表)
- consultation_purchased: Stella 相談の購入クレジット残高 (アカウント appUserId ごと、消費型 IAP)
- fortune_readings:  Horo「今日の占い」の 1 日 1 回固定キャッシュ
((appUserId, local_date, category) で一意。プロフィール変更で
再生成されない=「変更しない事にする」設計。Free=overall 1 件、
Pro=5 カテゴリ。日付境界はユーザの local TZ。)

単一 DO instance への集約理由:
- DAU 1,500 想定で同時刻書き込み <100/sec → DO の sequential write 内に余裕で収まる
- 複数 instance に sharding すると billing と運用コスト上昇
- 将来バズった場合のみ keyId-prefix sharding に切替 (=
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


### `worker/src/auth/play_integrity.js` (336 行)

**ファイル先頭コメント:**

```
Play Integrity (Android) サーバー検証 — Standard request 方式 (設計 v1.1 §4)。

役割: `/protected/*` middleware の Android 経路。Apple App Attest と対称。

🚨 v1.1 アーキテクチャ訂正 (2026-05-20、R8 実機失敗):
Standard request の token は JWE ではなく Google 独自の protobuf 形式で、
Self-managed key で local decode できない** (公式 docs 確認、JWEInvalid)。
→ Q2 訂正: Self-managed key (Workers 自前 decode) → Google decodeIntegrityToken API。
Self-managed key は Classic request 専用、Standard は Google decode 必須。

12 step 検証フロー (詳細は apps/solara/docs/play_integrity_design.md §4):
Step 1   /auth/integrity/challenge で nonce 発行 (本ファイル範囲外、S4 で /index.js に実装)
Step 2   X-PlayIntegrity-Token + ClientData + NonceId 受領
Step 3   clientData JSON parse (nonce/uid/ts 必須)
Step 4   clientData.ts ±5min (client clock drift)
Step 5   DO consume → clientData.nonce 一致 (S3 は注入関数で抽象化、S4 で実 DO)
Step 6-7 Google decodeIntegrityToken API で復号 + verdict 取得 (v1.1 で jose 自前 decode から置換)
Step 8   payload parse (timestampMillis/versionCode は string、v0.5 訂正)
Step 9   requestHash binding = base64(sha256(clientData)) (Standard 方式の核)
Step 10  Number(payload.timestamp) ±5min + packageName 確認
Step 11  PLAY_RECOGNIZED + MEETS_DEVICE_INTEGRITY + cert allowlist 評価
Step 12  uid binding (= __app
```

**export (8):** `DEFAULT_ANDROID_PACKAGE_NAME`, `TS_DRIFT_MS`, `MIN_NONCE_LENGTH`, `getGoogleAccessToken`, `decodeIntegrityToken`, `_resetAccessTokenCacheForTest`, `verifyPlayIntegrityFlow`, `__test`


### `worker/src/auth/rc_rest.js` (257 行)

**ファイル先頭コメント:**

```
RevenueCat REST API クライアント (server-side source-of-truth 再検証用)。

用途:
DO `user_entitlements` 表が webhook 遅延等で古い場合に、RC 本体 API に直接問い合わせて
entitlement 状態を取り直す。`gateConsultation` で「クライアント主張 Pro × DO non-Pro」
のときだけ呼ぶ (= 通常リクエストには影響しない)。

設計:
- V1 API (`GET /v1/subscribers/{app_user_id}`) を使う。
`expires_date` と `grace_period_expires_date` が entitlement 直下に出るため、
V2 より素直に grace を扱える。
- Bearer 認証: `REVENUECAT_SECRET_KEY` (sk_xxx)。wrangler secret put 済み。
- 結果を 30 秒だけ Worker instance のメモリ Map に memcache する
(= 同 appUserId への連続リクエスト時に RC API へバーストしない)。
- 失敗時は安全側に倒す: `{ isPro: false, reason: ... }` を返し、呼び出し側は
「再検証できなかった」と扱う (= 結果として Free 扱い経路には進まず、425 になる)。

設計参考:
- https://www.revenuecat.com/docs/api-v1#operation/get-the-latest-subscriber-info
- https://www.revenuecat.com/docs/customers/customer-info (server fetch ガイダンス)
- https://www.revenuecat.com/docs/subscription-guidance/how-grace-periods-work

RC 公式ホスト (固定)。
```

**export (4):** `_setFetchForTest`, `_resetRcRestCacheForTest`, `reverifyEntitlementViaRC`, `deleteSubscriberViaRC`


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


### `worker/src/consultation_engine.js` (1014 行)

**ファイル先頭コメント:**

```
Solara Stella 相談 — 計算パイプライン (秘伝)。Phase 1。

設計: memory project_solara_consultation_full_integration.md

役割: client から「誕生データ + 自宅座標 + 5問の答え + preset」だけ (約1KB) を
受け取り、Worker 側で**全部**計算する (秘匿アーキ最終確定 2026-05-23)。
1. 影響プール構築 (テーマ絞り ACG 線 + 天頂/天底帯, natal+transit+progressed,
旅行は期間内 ≤3 日サンプリング)
2. scope 別 候補プール (具体地点 / おでかけ近傍の実在の町 / 半径 / 地域 / 自国内 / 世界)
— D1 グローバル都市プール (cities1000) を bounding-box / 人口フロア+LIMIT で引く。
D1 binding (env.DB) が無ければ従来の worldCities (762) にフォールバック。
3. 候補スコアリング (多線合成 compositeStrength + アスペクト合成 aspectStrength + signature)
4. レンズ選択 (1回目=多線合成最強 / 2回目=アスペクト線主役の再合成 / 3回目以降=ランダム,
静かな場は正直フォールバック・枯渇は案Y=非消費, excluded で 1 枚ずつ前進)
5. 候補別リロケハウス (astro.js Placidus 流用, 出生時刻不明は省略)
6. 時間帯 (現地太陽時 = UTC + 経度/15 → 朝昼夜)
7. 内的季節 (進行の月サイン+ハウス / 進行の太陽サイン, SA は節目フラグだけ)
8. 出生時刻不明 degrade (軽い読み禁止: データが減るだけで品質は落とさない)

本モジュールは**語らない** (吉凶禁止・narrative なし)。構造化した素材を返し、
Phase 2 (Gemini プロンプト) が Stella の言葉にする。

Solara 設計思想 ([[project_solara_design_philosophy]]):
Soft (trine/sextile) と Hard (square) は独立 2 エネルギー。total/吉凶に潰さない。
ファクターは quality (soft/hard/neutral) を保ったまま返す。
```

**export (2):** `runConsultationPipeline`, `_internal`


### `worker/src/consultation_v2.js` (411 行)

**ファイル先頭コメント:**

```
Solara Stella 相談 V2 — Gemini ナレーション層 (Phase 2)。

設計: project_solara_consultation_full_integration.md

Phase 1 の秘伝計算 (consultation_engine.runConsultationPipeline) が返す
構造化素材を、Stella の言葉 (Gemini Flash 裏方) に変換する。
旧 consultation.js (deployed・client が候補を組む方式) には手を入れない。
これは新方式 (client 最小入力 → 全サーバー計算) 用の新ハンドラ。

出力:
初回 (isFirst) のみ innerSeason / intro / outro。
毎回 candidate{ name, characterHeadline, energyLabels[], narrative, timeWindow }
+ evidence{ factors[], km[], note } + model / fallback。
1 クレジット = 1 候補。「別の候補地」は excluded を足して再呼び出し (Phase 3)。

文体・表現ルール (確定 2026-05-23、全文 narrative に適用):
- 時間 = 時計+TZ なし。現地の時間帯のみ (旅行先=旅行先の現地時間)。
- 場所の呼び方 = 提示粒度に合わせる (座標のみ→「この地点」/ 店舗→店名+種類 / 都市→都市名)。
- narrative 本文に km を出さない (有無・質で語る)。km はエビデンス専用。
- 1 候補に関係し合う ~2 ファクター。可能なら Soft 1 + Hard 1 で「幅」(捏造はしない)。
- 冒頭の呼びかけ禁止。専門用語 (進行の月/ハウス等) を出さない。
- 読心禁止 (原則5): 他人の私的な心を断定せず「あなたの意識・動き・いつ」へ変換。
- 吉凶禁止 (原則2/原則1): Soft/Hard 独立、good/bad/lucky を使わせない。
```

**export (2):** `handleConsultationV2`, `_internal`


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


### `worker/src/fortune.js` (446 行)

**ファイル先頭コメント:**

```
Fortune Reading — Stella の占い文生成 (Gemini API バックエンド)

入力: category, natal, planetHouses?, aspects(N-N), transitAspects(N-T),
progressedAspects(N-P), patterns, date, userName?, lang('ja'|'en')
出力: { reading, advice }

3層構造 (トランジット主役): natal=土台(ハウス/生来の相), N-T=今日の主役,
N-P=今の人生の章(背景)。クロス相は {natal, moving, type, quality}。

GEMINI_API_KEY は wrangler secret put GEMINI_API_KEY で設定
モデル: gemini-2.5-flash (テキスト生成、低コスト)
```

**Gemini API 呼出 (1):**

- L106: `generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;`

**Durable Object 使用 (4 行):**

- 出現行: L336, L338, L338, L338

**export (4):** `computeCategoryScore`, `callGemini`, `stripTransitLabel`, `handleFortune`


### `worker/src/index.js` (1648 行)

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

**エンドポイント / ルート (32):**

| method | path | line |
| --- | --- | --- |
| ? | /protected/consultation/credits | L968 |
| ? | /public/astro/forecast | L1189 |
| ? | /public/tiles/* | L1190 |
| ? | /webhooks/* | L1191 |
| ? | /public/health | L1199 |
| GET | /public/tiles/osm/* | L1204 |
| POST | /public/astro/chart | L1209 |
| POST | /public/astro/forecast | L1217 |
| POST | /public/astro/predict | L1232 |
| POST | /public/astro/daily-transits | L1240 |
| GET | /public/tz | L1248 |
| GET | /public/astro/events | L1257 |
| GET | /public/search | L1268 |
| GET | /auth/whoami | L1290 |
| POST | /auth/challenge | L1293 |
| POST | /auth/attest | L1296 |
| POST | /auth/integrity/challenge | L1300 |
| GET | /auth/integrity/diagnose | L1309 |
| POST | /auth/integrity/decode-test | L1322 |
| POST | /protected/account/delete | L1437 |
| POST | /protected/fortune | L1441 |
| POST | /protected/tarot | L1451 |
| POST | /protected/relocation | L1479 |
| POST | /protected/astro/line-narrative | L1491 |
| POST | /protected/astro/consultation | L1501 |
| POST | /protected/astro/consultation2 | L1529 |
| POST | /protected/consultation/credits | L1561 |
| POST | /protected/report-ai-output | L1575 |
| ? | /public/* | L1630 |
| ? | /auth/* | L1632 |
| ? | /protected/* | L1634 |
| ? | /webhooks/revenuecat | L1636 |

**KV 使用 (4 行):**

- 出現行: L132, L135, L140, L220

**Durable Object 使用 (4 行):**

- 出現行: L262, L262, L262, L1584

**export (2):** `isQuotaExemptPath`, `_internal`


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


### `worker/src/style_voice.js` (17 行)

**ファイル先頭コメント:**

```
占い師「光源」の文体ガイド (オーナー文体サンプルから蒸留・2026-05-30 試作比較で確定)。

Stella相談 / Horo星読み / タロット の日本語プロンプトに共通注入する単一ソース。
各機能の構成ルール (名前/挨拶/前置き禁止・専門用語の扱い 等) を最優先し、
それに反しない範囲で "語り口" だけを寄せる。プロンプトの「ルール群の直後・出力JSONの直前」に置く。

注入対象は lang==='ja' のみ (英語プロンプトには入れない)。consultation_v2 は ja 専用。
```

**export (1):** `STYLE_VOICE_JP`


### `worker/src/tarot.js` (293 行)

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

- L64: `generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;`

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


### `worker/src/webhooks/revenuecat.js` (380 行)

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

- 出現行: L108, L108, L108

**export (2):** `handleRevenueCatWebhook`, `_internal`


### `worker/src/world_cities.js` (921 行)

**ファイル先頭コメント:**

```
GENERATED FILE — DO NOT EDIT BY HAND
Source: apps/solara/tools/generate_world_cities.py
Regenerate: python apps/solara/tools/generate_world_cities.py

Solara (ii) Stella 相談 Phase 1 (Worker 計算パイプライン) 用 都市プール。
Dart 版 lib/utils/world_cities.dart と完全に同一データ (同じ生成元)。
consultation_engine.js の候補生成 (region/world scope ランキング) に使う。
キュレート都市リスト (762 件)。
```

**export (2):** `worldCities`, `worldCityRegionGroups`

