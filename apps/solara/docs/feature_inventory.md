# Solara Feature Inventory (人手版)

> Solara が「いま何を持っているか」を人手で整理した中核ドキュメント。
> 機械抽出の raw は [`feature_inventory/_index.md`](feature_inventory/_index.md) から各層に。
>
> **この文書のスコープ**: 課金要素検討の土台として、Solara の機能を層別に把握する。
> 関数 1 個ずつの中身は掘らない (「呼んでいる事実」のみ記録)。
>
> **更新フロー** (各層着手時):
> 1. `apps/solara/tools/feature_extractor/extract.py` 再実行
> 2. `feature_inventory/0X_*.md` を読みながら本ファイルに人手記述
> 3. 完了後 `extract.py` 再実行 → `feature_inventory/coverage_report.md` の #1/#2 で漏れチェック
>
> **構築進捗**:
> - [x] 層 0: Worker (バックエンド計算式) — 2026-05-14 完成
> - [ ] 層 1a: 純計算ユーティリティ
> - [ ] 層 1b: 静的データ辞書
> - [ ] 層 1c: モデルクラス
> - [ ] 層 2a: API/Worker ラッパ
> - [ ] 層 2b: 永続化/キャッシュ
> - [ ] 層 2c: グローバル singleton
> - [ ] 層 3a: 共通ウィジェット (純粋)
> - [ ] 層 3b: テーマ・装飾
> - [ ] 層 3c: 演出ウィジェット (animated)
> - [ ] 層 4a: Map 画面
> - [ ] 層 4b: Horoscope 画面
> - [ ] 層 4c: Observe (Tarot) 画面
> - [ ] 層 4d: Galaxy 画面
> - [ ] 層 4e: Sanctuary 画面
> - [ ] 層 4f: サブ画面 (Forecast / Locations / Philosophy / Font Preview)
> - [ ] 層 5: 連携層 (main / PopScope / IndexedStack)

---

## 層 0: Worker (バックエンド計算式)

### 0.1 概要

Solara のバックエンドは **Cloudflare Workers** で稼働。本番 URL: `https://solara-api.solodev-lab.com`。
クライアント側で `solaraWorkerBase` 定数を参照 ([utils/solara_api.dart:17](../lib/utils/solara_api.dart)、ハードコード禁止 = [`project_solara_worker_url.md`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_worker_url.md))。

主な役割は 4 種:

| 役割 | 例 | 設計上の特徴 |
|---|---|---|
| **天体計算 (純数学)** | `/astro/chart`, `/astro/forecast`, `/astro/daily-transits`, `/astro/events`, `/tz` | `astronomy-engine` npm に依存。理論上は Dart 完結も可能 (実際に `astro_houses.dart`, `astro_lines.dart` は Dart 移植済み)。**Pro 機能の境界としては「無料公開層」になりやすい** |
| **AI narrative 仲介 (Gemini)** | `/fortune`, `/tarot`, `/relocation`, ~~`/astro/line-narrative`~~ | Gemini API key 秘匿のため Worker 必須。**課金で守るべき最大の対象** — 1 リクエスト = Gemini コスト発生 |
| **検索プロキシ** | `/search` | Google Places (主) + Nominatim (フォールバック)。Google Places は月 1 万 req 無料枠 |
| **地図タイル中継** | `/tiles/osm/*` | OSM 系を Worker UA で取得、edge cache 24h。アプリ直叩きだと 403 (UA 不足) |

### 0.2 セキュリティ現状と次フェーズ

**現状** (2026-05-14):
- CORS は `solodev-lab.github.io`, `solodev-lab.com`, `localhost` のみ ([index.js:15-20](../worker/src/index.js))
- per-endpoint memory rate limit (forecast=6/min, tiles=600/min, default=30/min)
- forecast は KV 月次クォータ 60 req/IP/month

**Pro 公開時 (未実装、必須)** — [`project_solara_security_principles.md`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_security_principles.md):
- ルート物理分離 (`/public/*`, `/auth/*`, `/protected/*`)
- App Attest / Play Integrity でアプリ改変対策
- RevenueCat Trusted Entitlements `.enforced` でクライアント単独 isPro 判定禁止
- Gemini 呼出 4 系 (`/fortune`, `/tarot`, `/relocation`, future) を `/protected/*` 配下へ

### 0.3 エンドポイント一覧 (13 個)

| # | path | method | 用途 | Gemini | Flutter 呼出元 | 状態 |
|---|---|---|---|---|---|---|
| 1 | `/health` | GET | CF ヘルスチェック | - | (CF が叩く) | 健全・保持 |
| 2 | `/tiles/osm/*` | GET | OSM タイル中継 (`hot` のみ実利用、`standard`/`cyclosm` は allowlist 残置) | - | [map_styles.dart](../lib/screens/map/map_styles.dart), [map_screen.dart:368](../lib/screens/map_screen.dart) | 健全 |
| 3 | `/astro/chart` | POST | 出生図計算 (natal/transit/progressed + ASC/MC/DSC/IC + 全アスペクト) | - | [map_astro.dart](../lib/screens/map/map_astro.dart) (Map + Horo 共用の chart fetcher) | 健全・心臓 |
| 4 | `/astro/forecast` | POST | 日次スコア時系列計算 (1〜5 年) | - | [forecast_cache.dart](../lib/utils/forecast_cache.dart) | 健全 + KV 月次クォータ |
| 5 | `/astro/predict` | POST | (旧) 60 日アスペクト予測 | - | **(呼出なし)** | **死んだ endpoint** — [architecture.md:632](architecture.md) に「(未接続)」明記。test.js のみで参照 |
| 6 | `/astro/daily-transits` | POST | 1 日分の惑星 × 4 アングル (ASC/MC/DSC/IC) 通過時刻 + natal アスペクト併記 | - | [daily_transits_api.dart](../lib/utils/daily_transits_api.dart) | 健全 |
| 7 | `/astro/events` | GET | 月別天体イベント (ingress / retrograde / eclipse) | - | [celestial_events.dart](../lib/utils/celestial_events.dart) | 健全 |
| 8 | `/astro/line-narrative` | POST | (旧) A*C*G ラインの AI 解説 | あり | **(呼出なし)** | **死んだ endpoint** — [`project_solara_v7_integration.md`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_v7_integration.md) に「AI 解説撤去済み」。`line_narrative.js` ファイル本体も削除候補 |
| 9 | `/tz` | GET | 緯度経度 → IANA タイムゾーン名 | - | [solara_api.dart](../lib/utils/solara_api.dart) | 健全 |
| 10 | `/search` | GET | 場所名検索 (Google Places primary + Nominatim fallback) | - | [map_search.dart](../lib/screens/map/map_search.dart) | 健全 |
| 11 | `/fortune` | POST | カテゴリ別占い文 + リロケーション narrative 生成 | あり (gemini-2.5-flash) | [fortune_api.dart](../lib/utils/fortune_api.dart) | 健全 |
| 12 | `/tarot` | POST | タロットカード解説生成 (1 枚引き Phase A) | あり (TAROT_MODEL_PRIMARY env var) | [fortune_api.dart](../lib/utils/fortune_api.dart) | 健全 |
| 13 | `/relocation` | POST | リロケーション (出生地 → 現住所/引越し先) 解説生成 | あり | [fortune_api.dart](../lib/utils/fortune_api.dart) | 健全 |

### 0.4 死んだ endpoint の整理 (削除候補)

**Worker 側に残骸として存在するが、Flutter 側から呼ばれていない endpoint**:

#### `/astro/predict` (`computePredictions`)
- **証拠**:
  - [architecture.md:632](architecture.md) で「(未接続)」と明記
  - `lib/**` Grep 結果 = 0 件、`worker/test.js` のみで参照
- **削除アクション**:
  - [worker/src/astro.js:462-528](../worker/src/astro.js) の `computePredictions` 削除
  - [worker/src/index.js:5](../worker/src/index.js) の import から削除
  - [worker/src/index.js:246-253](../worker/src/index.js) のルート分岐削除
  - [worker/test.js:52-54](../worker/test.js) のテスト削除
  - [architecture.md:632](architecture.md) の表から行削除
- **インパクト**: 約 100 行削減。クライアント影響なし。

#### `/astro/line-narrative` (`handleLineNarrative`, `worker/src/line_narrative.js`)
- **証拠**:
  - [`project_solara_v7_integration.md`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_v7_integration.md) と [00_worker.md:13](feature_inventory/00_worker.md) の機械検出
  - Flutter 側 `map_line_narrative_sheet.dart` は 2026-05-11 以降「静的辞書のみ」に変更済み (= AI 呼出無し)
- **削除アクション**:
  - [worker/src/line_narrative.js](../worker/src/line_narrative.js) ファイル全削除 (266 行)
  - [worker/src/index.js:12](../worker/src/index.js) の import 削除
  - [worker/src/index.js:355](../worker/src/index.js) のルート分岐削除
- **インパクト**: 約 280 行削減。Gemini 呼出 1 系統撤去 (= 攻撃面減)。

**削除タイミング判断**: 課金実装 (Phase 1 Worker 物理分離) と同時に行う方が安全。それまでは「機能停止中だが Worker 側にコードが残っている」状態を許容。今すぐ削除しても害はないが、必須でもない。

### 0.5 ファイル別 役割表

| ファイル | 行 | 役割 | エクスポート | 外部依存 |
|---|---|---|---|---|
| [`index.js`](../worker/src/index.js) | 373 | メインルーター + CORS + Rate Limit + KV クォータ + OSM タイル中継 | (`fetch` handler) | `caches.default`, `FORECAST_KV` (任意 binding) |
| [`astro.js`](../worker/src/astro.js) | 882 | 天体計算エンジン (純数学) | `computeChart`, ~~`computePredictions`~~, `computeForecast`, `computeMonthEvents` | `astronomy-engine` npm |
| [`daily_transits.js`](../worker/src/daily_transits.js) | 273 | 拠点での 1 日分の惑星 × 4 アングル通過時刻 | `computeDailyTransits` | `astronomy-engine` (`SearchHourAngle`, `SearchRiseSet`) |
| [`fortune.js`](../worker/src/fortune.js) | 294 | Gemini 占い文生成 + カテゴリスコア計算 (`computeCategoryScore`) | `computeCategoryScore`, `callGemini`, `handleFortune` | Gemini API (`GEMINI_API_KEY`) |
| [`tarot.js`](../worker/src/tarot.js) | 200 | Gemini タロット解説生成 (モデル切替対応) | `handleTarot` | Gemini API (`GEMINI_API_KEY`), env `TAROT_MODEL_PRIMARY` / `_FALLBACK` |
| [`relocation.js`](../worker/src/relocation.js) | 183 | Gemini リロケーション解説生成 | `handleRelocation` | Gemini API (`GEMINI_API_KEY`) |
| [`search.js`](../worker/src/search.js) | 144 | Google Places (New) primary + Nominatim fallback | `searchPlace` | `GOOGLE_PLACES_KEY` (任意, 未設定なら Nominatim 直行) |
| [`tzlookup.js`](../worker/src/tzlookup.js) | 90 | bbox ヒューリスティック + 経度ベース fallback の IANA tz 推定 | `lookupTimezone` | (なし、自前テーブル) |
| ~~[`line_narrative.js`](../worker/src/line_narrative.js)~~ | 266 | ~~A*C*G ライン AI 解説~~ | ~~`handleLineNarrative`~~ | (削除候補) |

### 0.6 計算系の区分け (課金検討用)

層 0 の計算は **「Worker のみ実装」「Worker + Dart 並行実装」「Dart のみ実装」** の 3 種類が混在。Pro 機能境界を引くときに重要:

| 計算 | Worker | Dart 移植 | 備考 |
|---|---|---|---|
| Natal chart (出生図) | `computeChart` | (一部のみ) | 完全 Dart 移植は未完。現状は Worker 必須 |
| 12 ハウス (Placidus) + ASC/MC 任意座標再計算 | (computeChart 内) | [`astro_houses.dart`](../lib/utils/astro_houses.dart) | Phase M2 で Dart 完結 (リロケーション/ACG 用)。**Worker と Dart 両方で実装あり** |
| アスペクトライン (40 本コンジャンクション) | (computeChart 内) | [`astro_lines.dart`](../lib/utils/astro_lines.dart) | Phase M2 で Dart 完結 (ACG 描画のため)。**両方で実装あり** |
| Forecast (日次スコア時系列) | `computeForecast` | (なし) | Worker 必須、計算コストが高く KV クォータ対象 |
| Daily transits | `computeDailyTransits` | (なし) | Worker 必須 (`astronomy-engine` の SearchHourAngle/SearchRiseSet 依存) |
| 天体イベント (ingress/retrograde/eclipse) | `computeMonthEvents` | (なし) | Worker 必須 |
| Timezone lookup | `lookupTimezone` | (なし) | Worker 必須 (テーブルが大きい) |
| AI narrative 4 系 | `/fortune`, `/tarot`, `/relocation`, ~~`/line-narrative`~~ | (Gemini なので原理上クライアント実装不可) | **課金で守る最大対象** |
| Place 検索 | `/search` | (なし) | Google Places key 秘匿のため Worker 必須 |
| Map タイル | `/tiles/osm/*` | (なし) | UA 設定のため Worker 経由必須 |

**示唆**:
- Pro 機能を「クライアント完結」で作れば Worker コスト = 0 (例: 追加のアスペクトライン本数 120 本へ拡張 = `astro_lines.dart` だけで作れる)
- 一方、Pro 機能を AI narrative 拡張で作ると Gemini コスト線形増。**回数制限 (Free 5/day, Pro 100/day 等) で守らないと月額黒字化が崩れる**

### 0.7 Worker 側の運用ノート (重要)

- **CORS**: 開発時に `localhost` が許可されているので、ローカルでテスト可能
- **環境変数 (`wrangler secret put`)**:
  - `GEMINI_API_KEY` — 占い 4 系全部で使用
  - `GOOGLE_PLACES_KEY` — search、未設定なら Nominatim 直行
  - `TAROT_MODEL_PRIMARY`, `TAROT_MODEL_FALLBACK` — tarot モデル切替 (廃止リスク対策)
- **KV bindings**: `FORECAST_KV` — forecast 月次クォータ用。未設定なら `checkKvForecastQuota` は no-op
- **テスト**: [`worker/test.js`](../worker/test.js) で `computeChart` / `computePredictions` の単体実行可能 (`node test.js`)。**ただし `/astro/predict` 用テストは死んだ endpoint のため削除推奨**

### 0.8 機械抽出への参照

層 0 の機械抽出 raw: [`feature_inventory/00_worker.md`](feature_inventory/00_worker.md)
対整合チェック結果: [`feature_inventory/coverage_report.md`](feature_inventory/coverage_report.md)

---

(層 1a 以降は次セッション以降で追記)
