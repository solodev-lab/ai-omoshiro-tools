# 層 0: Worker (バックエンド計算式)

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 10
- エンドポイント総数: 16
- Gemini 呼出箇所: 2
- KV 使用: 4 行 / Durable Object 使用: 0 行

## ファイル別

### `worker/src/astro.js` (882 行)

**ファイル先頭コメント:**

```
Solara Astro Engine — Cloudflare Worker
Ported from: horoscope.html + shared/astro-math.js
Dependency: astronomy-engine (npm)
```

**export (4):** `computeChart`, `computePredictions`, `computeForecast`, `computeMonthEvents`


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


### `worker/src/index.js` (392 行)

**ファイル先頭コメント:**

```
Solara API — Cloudflare Worker
Endpoints: /astro/chart, /astro/predict, /search, /fortune, /health
```

**エンドポイント / ルート (16):**

| method | path | line |
| --- | --- | --- |
| ? | /astro/forecast | L195 |
| ? | /tiles/* | L197 |
| ? | /health | L208 |
| GET | /tiles/osm/* | L216 |
| POST | /astro/chart | L221 |
| POST | /astro/forecast | L231 |
| POST | /astro/predict | L247 |
| POST | /astro/daily-transits | L261 |
| GET | /tz | L271 |
| GET | /astro/events | L282 |
| GET | /search | L295 |
| POST | /fortune | L312 |
| POST | /tarot | L324 |
| POST | /relocation | L338 |
| POST | /astro/line-narrative | L356 |
| POST | /astro/consultation | L374 |

**KV 使用 (4 行):**

- 出現行: L75, L78, L83, L145


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


### `worker/src/tarot.js` (200 行)

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

