# 層 0: Worker (バックエンド計算式)

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 14
- エンドポイント総数: 22
- Gemini 呼出箇所: 2
- KV 使用: 4 行 / Durable Object 使用: 4 行

## ファイル別

### `worker/src/astro.js` (882 行)

**ファイル先頭コメント:**

```
Solara Astro Engine — Cloudflare Worker
Ported from: horoscope.html + shared/astro-math.js
Dependency: astronomy-engine (npm)
```

**export (4):** `computeChart`, `computePredictions`, `computeForecast`, `computeMonthEvents`


### `worker/src/auth/app_attest.js` (360 行)

**ファイル先頭コメント:**

```
Apple App Attest サーバー検証。

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

**export (2):** `verifyAttestation`, `verifyAssertion`


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


### `worker/src/auth/attestation_state.js` (225 行)

**ファイル先頭コメント:**

```
Apple App Attest 用 Durable Object (SQLite-backed)。

設計 v1.8 §6.1 に従い、1 instance (`idFromName('global')`) に 3 表を集約:
- attestations: 端末ごとの公開鍵 + counter
- challenges:   server 発行 challenge の強整合管理 (one-time use)
- user_quota:   per-user rate limit (Layer C、Free=5/日 Pro=100/日)

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
→ {ok: true, remaining} or 429 {remaining: 0}

Caller (Worker middleware) はこれらを順番に叩いて検証する。
```

**Durable Object 使用 (1 行):**

- 出現行: L4

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


### `worker/src/index.js` (614 行)

**ファイル先頭コメント:**

```
Solara API — Cloudflare Worker

🔴 ルート物理分離 (project_solara_security_principles.md §2):
public/*     誰でも OK    純数学計算 (`/astro/chart` 等)、マップタイル、検索
auth/*       Sign in 系   whoami / App Attest 登録 (現状 stub)
protected/*  重防御       Gemini 呼び出し全部 (`/fortune`/`/tarot`/`/relocation`
`/astro/consultation`/`/astro/line-narrative`)。
将来 attestation + entitlement + per-user rate limit。

旧 top-level ルート (`/fortune` `/astro/chart` 等) は撤廃。Flutter クライアント側も
同セッションで新 path に書き換え済（`apps/solara/lib/utils/solara_api.dart` 参照）。
```

**エンドポイント / ルート (22):**

| method | path | line |
| --- | --- | --- |
| ? | /public/astro/forecast | L403 |
| ? | /public/tiles/* | L404 |
| ? | /public/health | L412 |
| GET | /public/tiles/osm/* | L417 |
| POST | /public/astro/chart | L422 |
| POST | /public/astro/forecast | L430 |
| POST | /public/astro/predict | L445 |
| POST | /public/astro/daily-transits | L453 |
| GET | /public/tz | L461 |
| GET | /public/astro/events | L470 |
| GET | /public/search | L481 |
| GET | /auth/whoami | L503 |
| POST | /auth/challenge | L506 |
| POST | /auth/attest | L509 |
| POST | /protected/fortune | L523 |
| POST | /protected/tarot | L533 |
| POST | /protected/relocation | L543 |
| POST | /protected/astro/line-narrative | L555 |
| POST | /protected/astro/consultation | L565 |
| ? | /public/* | L600 |
| ? | /auth/* | L602 |
| ? | /protected/* | L604 |

**KV 使用 (4 行):**

- 出現行: L89, L92, L97, L161

**Durable Object 使用 (3 行):**

- 出現行: L203, L203, L203


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

