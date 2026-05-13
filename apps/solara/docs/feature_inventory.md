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
> - [x] 層 1a: 純計算ユーティリティ — 2026-05-14 完成
> - [x] 層 1b: 静的データ辞書 — 2026-05-14 完成
> - [x] 層 1c: モデルクラス — 2026-05-14 完成
> - [x] 層 2a: API/Worker ラッパ — 2026-05-14 完成
> - [x] 層 2b: 永続化/キャッシュ — 2026-05-14 完成
> - [x] 層 2c: グローバル singleton — 2026-05-14 完成
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

## 層 1a: 純計算ユーティリティ

### 1a.1 概要

`lib/utils/` 配下の 8 ファイル / 計 2,512 行。**副作用なし** (http なし、storage なし、initialize なし)。
純数学計算と静的辞書ヘルパーが混在。

**機械分類の精度メモ**: 層 1a に分類された 8 ファイルのうち、
- `astro_glossary.dart`, `celestial_event_meanings.dart`, `planet_intro.dart` の 3 つは実態が「**大きな静的辞書 + 取得ヘルパー関数**」で、本来は層 1b (静的データ辞書) の方が意味的に適切。
- 機械分類ヒューリスティック (`Map<>` リテラル数と関数数の比) では区別しきれず 1a に入った。これは `extract.py` の将来改善ポイント (= 機械分類のオーバーライドテーブル導入 or 静的データ判定強化)。
- 今回は機械分類のまま記載するが、本章末尾で 5 + 3 に分けて整理する。

### 1a.2 ファイル別 役割 + 呼出元 (8 本)

| # | ファイル | 行 | 役割 | 主要 export | 呼出元 (画面層) | 性質 |
|---|---|---|---|---|---|---|
| 1 | [`astro_math.dart`](../lib/utils/astro_math.dart) | 30 | 角度の正規化 + 最小角距離。重複検出 ([code_audit](../tools/code_audit/audit.py) T1) で 4 ファイル散在を集約 | `normalize360`, `angDist` | astro_lines, astro_houses, [map_astro](../lib/screens/map/map_astro.dart), [horoscope_screen](../lib/screens/horoscope_screen.dart), [horo_pattern_logic](../lib/screens/horoscope/horo_pattern_logic.dart) | **基礎中の基礎、全層が依存** |
| 2 | [`astro_houses.dart`](../lib/utils/astro_houses.dart) | 208 | LST 復元 + ASC/MC/Placidus 12 ハウス Dart 完結。Phase M2 (リロケーション/ACG) 用 | `HousesResult`, `calcHousesRelocate`, `cusp`, `assignPlanetHouse` | [map_relocation_popup](../lib/screens/map/map_relocation_popup.dart), [horoscope_screen](../lib/screens/horoscope_screen.dart), [horo_relocation_panel](../lib/screens/horoscope/horo_relocation_panel.dart), [horo_planet_table](../lib/screens/horoscope/horo_planet_table.dart) | **Worker `/astro/chart` と機能重複** (両方で実装あり) |
| 3 | [`astro_lines.dart`](../lib/utils/astro_lines.dart) | 588 | 40 本アスペクト線計算 (球面三角法) + Haversine 近接検出 + GMST 計算 | `AstroFrame`, `AstroLine`, `NearbyAstroLine`, `astroFrameKey`, `gmstHoursFromUtc`, `solarArcPlanets`, `buildAstroLines`, `buildAstroLinesAt`, `findNearbyLinesScreen` | Map のみ ([map_screen](../lib/screens/map_screen.dart), map_relocation_popup, [map_line_narrative_sheet](../lib/screens/map/map_line_narrative_sheet.dart), [map_astro_lines](../lib/screens/map/map_astro_lines.dart), [map_astro_carto](../lib/screens/map/map_astro_carto.dart)) | **Pro 候補の素材** — 「アスペクトライン 120 本拡張」は本ファイル拡張で作れる (Worker 不要) |
| 4 | [`direction_energy.dart`](../lib/utils/direction_energy.dart) | 238 | Soft/Hard 独立 2 エネルギーの中核データ構造 + アスペクト寄与の集約ロジック | `DirectionEnergy`, `EnergyMode`, `AspectContribution`, `AggregatedAspect`, `classify`, `scaledBy`, `aggregateContributions` | Map のみ ([map_screen](../lib/screens/map_screen.dart), [map_fortune_sheet](../lib/screens/map/map_fortune_sheet.dart), [map_direction_popup](../lib/screens/map/map_direction_popup.dart), [map_astro](../lib/screens/map/map_astro.dart)) | **設計思想の核** ([project_solara_design_philosophy](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_design_philosophy.md))。`total = soft + hard` 禁止 |
| 5 | [`moon_phase.dart`](../lib/utils/moon_phase.dart) | 360 | Jean Meeus アルゴリズム月相計算 (14 補正項、±2-3 分精度) | `MoonPhase`, `findPreviousNewMoon`, `findNextNewMoon`, `findFullMoonInCycle`, `getPhaseDay`, `isNewMoon`, `isFullMoon`, `getCycleTotalDays`, `getCurrentDayIndex`, `getCycleId`, `getIllumination` 等 | [observe_screen](../lib/screens/observe_screen.dart) (Tarot)、[galaxy_screen](../lib/screens/galaxy_screen.dart)、[galaxy_constellation_builder](../lib/screens/galaxy/galaxy_constellation_builder.dart)、[cycle_spiral_painter](../lib/widgets/cycle_spiral_painter.dart) | Map で未使用、Observe/Galaxy 専用 |
| 6 | [`astro_glossary.dart`](../lib/utils/astro_glossary.dart) | 586 | 占星術専門用語の解説辞書 + popup 表示ヘルパー | `AstroGlossaryEntry`, `showAstroGlossaryDialog` | [astro_term_label](../lib/widgets/astro_term_label.dart), Map の各 popup 6 種 | **本来は 1b (静的辞書)** |
| 7 | [`celestial_event_meanings.dart`](../lib/utils/celestial_event_meanings.dart) | 52 | 天体イベント (ingress/retrograde/eclipse) の占星術的意味辞書 | `getEventMeaningJP` | [celestial_event_bar](../lib/widgets/celestial_event_bar.dart) のみ | **本来は 1b (静的辞書)** |
| 8 | [`planet_intro.dart`](../lib/utils/planet_intro.dart) | 559 | 10 惑星の Map マーカータップ説明テキスト (natal/transit/progressed 3 フレーム × 10 惑星) | `PlanetIntroFrame`, `PlanetIntro`, `frameOf` | [map_screen](../lib/screens/map_screen.dart), [map_planet_intro_popup](../lib/screens/map/map_planet_intro_popup.dart) | **本来は 1b (静的辞書)** |

### 1a.3 真の純計算 vs 静的辞書ヘルパー の整理

機械分類を意味的に再整理すると:

#### A. 真の純計算 (5 本、計 1,424 行)
画面間で広く共有される数学/データ変換。**Dart 完結 = Worker 呼出ゼロ**。

| ファイル | 行 | 主要関数 | 性質 |
|---|---|---|---|
| `astro_math.dart` | 30 | `normalize360`, `angDist` | 全層の基礎 |
| `astro_houses.dart` | 208 | `calcHousesRelocate`, `assignPlanetHouse` | Worker 重複あり、リロケーション専用 |
| `astro_lines.dart` | 588 | `buildAstroLines`, `findNearbyLinesScreen` | Map (ACG) 専用、Pro 拡張候補 |
| `direction_energy.dart` | 238 | `aggregateContributions`, `classify` | Map スコア計算の核 |
| `moon_phase.dart` | 360 | `findNextNewMoon`, `getPhaseInt` | Observe/Galaxy 専用 |

#### B. 静的辞書 + ヘルパー (3 本、計 1,197 行、本来は層 1b)
データはほぼ静的、関数は「辞書から取り出すヘルパー」が主。

| ファイル | 行 | 内容 |
|---|---|---|
| `astro_glossary.dart` | 586 | 占星術用語辞書 + popup 表示ヘルパー |
| `celestial_event_meanings.dart` | 52 | 天体イベント意味の辞書 |
| `planet_intro.dart` | 559 | 10 惑星 × 3 フレーム のテキスト |

### 1a.4 課金検討に直結する示唆

**Pro 機能の素材としての価値**:

1. **`astro_lines.dart` 拡張 = Pro 機能の最有力候補** (Worker コスト 0)
   - 現状 40 本コンジャンクション → +ハード 90° + ソフト 120°/60° 追加で 120 本に拡張可能
   - メモリ ([project_solara_launch_checklist.md](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_launch_checklist.md)) Phase 3 で予定済み
   - **インパクト**: クライアント完結なので Gemini コスト無し、Worker 負荷増無し
   - **実装範囲**: 本ファイルに新規 aspect angle 定数 + `buildAstroLines` の loop 拡張

2. **`astro_houses.dart` は Worker `/astro/chart` と機能重複**
   - 現状の Map では Worker 計算結果をそのまま使うことが多く、`astro_houses.dart` はリロケーション (本拠点 ≠ 出生地) でのみ稼働
   - Pro 機能化するなら「無制限リロケーション」が候補だが、現状でも稼働するため Pro 化の理由は弱い
   - **Worker 重複コードは保守コスト**: 今後どちらかに寄せる検討の余地あり (Dart 側に寄せれば Worker 軽量化 + オフライン耐性)

3. **`direction_energy.dart` の設計思想は譲れない**
   - `total` / `softRatio` 禁止 = UI で 1 軸表現に丸めない
   - 課金訴求文で「2 エネルギー独立評価」を売りにすることは可能 (差別化軸)
   - ただし「占い的吉凶判定をしない」のは無料機能にも適用 = Pro/Free の境界には使えない

4. **`moon_phase.dart` は Galaxy/Observe 専用**
   - Map 系の Pro 機能では使われない
   - Observe (Tarot) の Pro 拡張 (3 枚引き/5 枚引き、[project_tarot_v2_plan](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_tarot_v2_plan.md)) で月相加味の占い文を Gemini に投げる場合に活用余地

### 1a.5 Worker との重複コード (運用上の注意)

`astro_houses.dart` と `astro_lines.dart` は Worker 側の同等機能と並行実装になっている。
**検証済み精度** ([architecture.md](architecture.md)):
- 引越し計算: 全 6 ペア最大誤差 0.0122° (閾値 0.5° の 1/40)
- アスペクト線: 全 80 ケース最大誤差 0.01°

二重実装の理由 (記録):
- Phase M2 で Map タップ <50ms の高速応答を実現するため、 Worker 経由を避けて Dart 完結
- 検証用に Worker 側を残し、結果が一致することを `worker/verify_phase_m2*.py` で確認

**将来の判断ポイント**:
- 同期し続けるコスト vs どちらかを単一実装にするメリット
- 「Worker 純計算系を順次 Dart に寄せて Worker を AI 仲介専用にする」案は Pro 公開時のセキュリティ整理 (`/protected/*`) と整合する

### 1a.6 機械抽出への参照

層 1a の機械抽出 raw: [`feature_inventory/01a_pure_calc.md`](feature_inventory/01a_pure_calc.md)

---

## 層 1b: 静的データ辞書

### 1b.1 概要

`lib/utils/` 配下、**静的データが主体** で関数は辞書取り出しヘルパーが中心の 5 ファイル / 計 1,418 行。
副作用なし (= 層 1a と同じく純粋)、ただし「計算」というより「世界観テキストの貯蔵庫」。

機械分類で本層に入った 5 ファイルに加え、層 1a に分類された 3 ファイル (`astro_glossary`, `celestial_event_meanings`, `planet_intro`) も意味的にはこちら寄り (= 層 1a.3 参照)。

### 1b.2 ファイル別 役割 + 呼出元 (5 本)

| # | ファイル | 行 | 内容 | 主要 export | 呼出元 (画面層) | 特記 |
|---|---|---|---|---|---|---|
| 1 | [`astro_zenith_messages.dart`](../lib/utils/astro_zenith_messages.dart) | 170 | 天頂点 (Zenith Point) 解説メッセージ辞書。MC ライン上で観測者真上に来る唯一の地点の解説 | `ZenithMessage` | [map_astro_carto](../lib/screens/map/map_astro_carto.dart) (ACG モード専用) | ACG 天頂マーカータップ時に表示 |
| 2 | [`constellation_namer.dart`](../lib/utils/constellation_namer.dart) | 626 | 星座名生成 v2 (形容詞 × 名詞)、Prim MST 構築、エッジ生成、レア度算出、HUE シフト | `ConstellationNamer`, `buildName`, `rarityPercentage`, `hueShift`, `adjColor`, `computeMST`, `buildEdges`, `isFlipX`, `artAssetPath` | Galaxy 5 ファイル + [constellation_painter](../lib/widgets/constellation_painter.dart), [catasterism_formation_overlay](../lib/widgets/catasterism_formation_overlay.dart) | **計算ロジック比率高め** — 1a 寄りの側面あり (機械分類が辞書判定したのは形容詞/名詞テーブルの大きさ)。Galaxy の世界観 (= 月相サイクルの「刻星化」演出) の心臓 |
| 3 | [`cycle_story_texts.dart`](../lib/utils/cycle_story_texts.dart) | 86 | 月齢サイクル (新月/満月/刻星化) のストーリーテキスト JP/EN | `CycleStoryTexts`, `getNewMoon`, `getFullMoon`, `getCatasterism` | [new_moon_overlay](../lib/widgets/new_moon_overlay.dart), [full_moon_overlay](../lib/widgets/full_moon_overlay.dart), [catasterism_overlay](../lib/widgets/catasterism_overlay.dart) | JP/EN ネイティブ別書き (翻訳ではない)。`_isJapanese()` で切替 |
| 4 | [`solara_manifesto.dart`](../lib/utils/solara_manifesto.dart) | 141 | Solara 設計思想テキスト (3 セクション: 世界観 / 2 エネルギー / 委ねる宣言) | `SolaraManifesto`, `SolaraManifestoSection`, `getSections` | [solara_philosophy_screen](../lib/screens/solara_philosophy_screen.dart) のみ | 「占い的吉凶判定をしない」を文章化したアプリの哲学的根幹 ([project_solara_design_philosophy](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_design_philosophy.md)) |
| 5 | [`title_data.dart`](../lib/utils/title_data.dart) | 395 | 144 称号システムデータ (12 太陽部位 × 12 月部位 + 25 class) + 太陽/月星座近似算出 | `TitleClass`, `getSunSign`, `getMoonSign` | [class_card](../lib/widgets/class_card.dart), [sanctuary_screen](../lib/screens/sanctuary_screen.dart), [sanctuary_title_diagnosis](../lib/screens/sanctuary/sanctuary_title_diagnosis.dart), [class_share_card](../lib/screens/sanctuary/class_share_card.dart) | **EN 版 144 称号未実装** ([project_solara_title_system](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_title_system.md)) |

### 1b.3 課金検討に直結する示唆

1. **`title_data.dart` の称号システムは Sanctuary タブの中核資産**
   - 144 称号 × class 25 = ユーザーごとの「あなただけの結果」を作る差別化要素
   - **EN 版未実装** がストア海外展開の遅延要因 ([feedback_i18n_last](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_i18n_last.md) ルールでリリース直前まで保留中)
   - 称号関連の Pro 拡張案 (例: 称号 SHARE カードの追加デザイン、月別称号変化追跡など) は本データを土台にできる

2. **`constellation_namer.dart` は Galaxy の心臓部 — Pro 候補としては弱い**
   - 既に「2026-04-25 v2 完成」状態、Pro/Free 境界に置きづらい (= Galaxy タブの基本体験)
   - 拡張余地: 「刻星化アルバム」「履歴の検索」など Pro 案 ([project_galaxy_spec](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_galaxy_spec.md))

3. **`solara_manifesto.dart` の世界観テキストは「課金訴求文」と直接対応**
   - 「占い的吉凶判定をしない、両面思想」= 既存占いアプリ群との差別化軸
   - ストア説明文・ペイウォール訴求文・公式 LP の表現に流用可能 (= マーケ素材として価値)

4. **`astro_zenith_messages.dart` は ACG モード専用 = 海外展開時の鍵**
   - 国内: マニア向け β機能
   - 海外: Solara のメイン売り (英米圏で A*C*G の歴史と認知あり、[`project_solara_astrocartography_m2`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_astrocartography_m2.md))
   - 天頂点ごとのカスタム解説は Pro 機能化候補 (例: 出生図に基づくパーソナライズ天頂点メッセージ)

### 1b.4 機械抽出への参照

層 1b の機械抽出 raw: [`feature_inventory/01b_static_data.md`](feature_inventory/01b_static_data.md)

---

## 層 1c: モデルクラス

### 1c.1 概要

`lib/models/` 配下の 4 ファイル / 計 337 行。永続化対象データの **plain Dart class** (Riverpod や json_serializable は未使用、手書きの `toJson` のみ)。
**全て Observe (Tarot) または Galaxy 専用** — Map / Horo / Sanctuary タブからは参照無し。

### 1c.2 ファイル別 役割 + 呼出元 (4 本)

| # | ファイル | 行 | class | 用途 | 呼出元 |
|---|---|---|---|---|---|
| 1 | [`daily_reading.dart`](../lib/models/daily_reading.dart) | 41 | `DailyReading` | タロット 1 日 1 引きキャッシュ (cardId, reversed, reading, stella, drawnAt) | [tarot_data](../lib/utils/tarot_data.dart), [solara_storage](../lib/utils/solara_storage.dart), Observe 系 3 ファイル |
| 2 | [`galaxy_cycle.dart`](../lib/models/galaxy_cycle.dart) | 119 | `ConstellationDot`, `GalaxyCycle` | 銀河の 1 サイクル分のデータ (新月→満月→刻星化、星座ドット配列) | [solara_storage](../lib/utils/solara_storage.dart), Galaxy 系 5 ファイル + cycle/constellation widgets |
| 3 | [`lunar_intention.dart`](../lib/models/lunar_intention.dart) | 105 | `LunarIntention`, `MidpointCheck`, `CatasterismResult` | 新月で選んだ意図 + 満月の中間チェック + 刻星化評価 | [solara_storage](../lib/utils/solara_storage.dart), Galaxy 系 + moon overlay widgets |
| 4 | [`tarot_card.dart`](../lib/models/tarot_card.dart) | 72 | `TarotCard` | 78 枚タロットカードの定義 (id, nameJP, keyword, element, planet, suit, number 等) | [tarot_data](../lib/utils/tarot_data.dart), Observe 系 |

### 1c.3 課金検討に直結する示唆

1. **永続化対象 = ユーザーの「履歴」「経験」=Solara の最大の差別化資産**
   - DailyReading, GalaxyCycle, LunarIntention, CatasterismResult はユーザーごとの体験ログ
   - クラウドバックアップ機能 (Pro 候補) はこれらの保存先 = どれを優先的にバックアップするかが設計判断
   - 削除/エクスポート/インポートも本クラス群を中心に組み立てる

2. **`TarotCard` は静的データ (78 枚固定) で、Pro 拡張対象ではない**
   - Pro 拡張は「3 枚引き / 5 枚引きスプレッド」「カード履歴の検索」など別所
   - 本 class 自体は変更不要

3. **`LunarIntention` + `CatasterismResult` は Galaxy 体験の核 — 静かな差別化**
   - 「占いをしない、意図と振り返りの記録」という Solara 独自の体験設計の中心
   - Pro 拡張: 過去サイクルのアルバム、月別ハイライト、テキストエクスポート (`getCatasterismMD` 等) が候補

4. **モデル層がここまで小さい (337 行) = 設計が素直で保守容易**
   - 永続化スキーマ拡張の影響範囲が把握しやすい
   - 課金で新たな永続化対象 (例: Pro 限定の有料カード履歴) を追加する場合、本層に class を 1〜2 個足すだけで済む

### 1c.4 機械抽出への参照

層 1c の機械抽出 raw: [`feature_inventory/01c_models.md`](feature_inventory/01c_models.md)

---

## 層 2a: API/Worker ラッパ

### 2a.1 概要

`lib/utils/` 配下、**http import あり** の 6 ファイル / 計 932 行。**Worker ↔ Flutter の通信境界**。
ここを把握すれば「課金時に `/protected/*` に移すべき呼出元」が全部見える。

### 2a.2 ファイル別 役割 + 呼出 endpoint + 呼出元 (6 本)

| # | ファイル | 行 | 呼出先 endpoint | 呼出元 (主要) | 特記 |
|---|---|---|---|---|---|
| 1 | [`solara_api.dart`](../lib/utils/solara_api.dart) | 35 | `/tz` (GET) + `solaraWorkerBase` 定数 export | `sanctuary_profile_editor`, `horo_birth_panel`, Map 各所 | **`solaraWorkerBase` 定数の出元** ([`project_solara_worker_url.md`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_worker_url.md) ハードコード禁止)。`fetchTimezoneName` 1 関数のみ |
| 2 | [`fortune_api.dart`](../lib/utils/fortune_api.dart) | 250 | **`/fortune`, `/relocation`, `/tarot`** (POST × 3、全て Gemini 系) | [horoscope_screen](../lib/screens/horoscope_screen.dart), [observe_screen](../lib/screens/observe_screen.dart), [horo_fortune_cards](../lib/screens/horoscope/horo_fortune_cards.dart), [horo_relocation_panel](../lib/screens/horoscope/horo_relocation_panel.dart) | **課金で守るべき最大対象 = Gemini 呼出 3 系統がここに集中**。Pro 公開時に `/protected/*` 移行 + 回数制限の中心 |
| 3 | [`daily_transits_api.dart`](../lib/utils/daily_transits_api.dart) | 241 | `/astro/daily-transits` (POST) | [map_daily_transit_screen](../lib/screens/map/map_daily_transit_screen.dart), [map_aspect_chip](../lib/screens/map/map_aspect_chip.dart) | F1 機能、課金で「無制限拠点切替」の Pro 化候補 |
| 4 | [`celestial_events.dart`](../lib/utils/celestial_events.dart) | 314 | `/astro/events` (GET) | [main.dart](../lib/main.dart) (起動 initialize)、[new_moon_overlay](../lib/widgets/new_moon_overlay.dart)、[full_moon_overlay](../lib/widgets/full_moon_overlay.dart)、[celestial_event_bar](../lib/widgets/celestial_event_bar.dart)、[galaxy_screen](../lib/screens/galaxy_screen.dart) | **singleton 的に initialize**、機械分類は 2a だが層 2c 寄りの側面あり (= 層 2c.4 と整合) |
| 5 | [`reverse_geocode.dart`](../lib/utils/reverse_geocode.dart) | 50 | **Nominatim 直叩き** (`nominatim.openstreetmap.org/reverse`) | [map_vp_panel](../lib/screens/map/map_vp_panel.dart)、[horo_birth_panel](../lib/screens/horoscope/horo_birth_panel.dart) | **🔴 重要**: 唯一 Worker 経由でない外部 API 呼出。Nominatim は無料 + key 不要 + 1 req/sec 制限。Pro 公開時にレートリミット遵守 + UA 設定確認が必要 |
| 6 | [`tile_http_client.dart`](../lib/utils/tile_http_client.dart) | 42 | (Worker URL 自体は呼出さず、共有 HttpClient のみ提供) | [map_screen](../lib/screens/map_screen.dart) (`sharedTileHttpClient`)、[map_styles](../lib/screens/map/map_styles.dart) | **fd 枯渇対策** ([`feedback_http_fd_leak`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_http_fd_leak.md), [`project_solara_a101fc_fd_leak`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_a101fc_fd_leak.md))。maxConnectionsPerHost=6, idleTimeout=15s |

### 2a.3 機械分類の盲点 — `screens/map/map_astro.dart` は実態が層 2a

機械分類で **`screens/map/map_astro.dart` は層 4a (Map 画面)** に入っているが、中身は:
- `/astro/chart` (POST) を呼び出す **`fetchChart` API ラッパ関数** + レスポンス class (`ChartResult` 等)
- Map + Horoscope 両方から呼ばれる横断利用 (Map: 直接、Horo: 同じ関数を import)

意味的には「層 2a (API ラッパ)」が正しい。screens/ ディレクトリにあるため機械分類で 4a 判定されている。

**改善案**: `lib/screens/map/map_astro.dart` を `lib/utils/astro_api.dart` (新規名) にリネームすれば、機械分類が正しく 2a に入り、Horoscope 側からも自然 import 可能。今は機械分類のオーバーライド対象として記録 (`extract.py` への明示テーブル化候補)。

### 2a.4 Worker endpoint との対応マップ (層 0 ↔ 層 2a)

| Worker endpoint | 層 2a ラッパ | Flutter 呼出元 |
|---|---|---|
| `/astro/chart` | `map_astro.dart`'s `fetchChart` (実態は 2a) | Map + Horoscope |
| `/astro/forecast` | [`forecast_cache.dart`](../lib/utils/forecast_cache.dart) (機械分類 2b、永続化込み) | Forecast 画面 |
| `/astro/predict` | **(ラッパなし)** | **死んだ endpoint** (層 0.4 で削除候補) |
| `/astro/daily-transits` | `daily_transits_api.dart` | Map Daily Transit |
| `/astro/events` | `celestial_events.dart` | main + Galaxy + 月相 overlay |
| `/astro/line-narrative` | **(ラッパなし、撤去済み)** | **死んだ endpoint** (層 0.4) |
| `/tz` | `solara_api.dart` | Sanctuary + Horo Birth |
| `/search` | (`map_search.dart` 直叩き、層 4a 分類) | Map 検索 |
| `/fortune` | `fortune_api.dart` | Horo + Observe |
| `/tarot` | `fortune_api.dart` | Observe |
| `/relocation` | `fortune_api.dart` | Horo (リロケーション) |
| `/tiles/osm/*` | `map_styles.dart` 直叩き (4a 分類) + `tile_http_client.dart` 共有 client | Map タイル描画 |
| `/health` | (Flutter 呼出なし) | CF が叩く |

**観察**:
- **Worker 経由でない直叩き**: `reverse_geocode.dart` (Nominatim)
- **ラッパが層 2a の utils/ にない呼出**: `/astro/chart` (map_astro.dart)、`/search` (map_search.dart)、`/tiles/*` (map_styles.dart)
  - = 課金実装時に「`screens/map/` 配下の Worker 呼出箇所」も同等にチェック必須

### 2a.5 課金検討に直結する示唆

1. **Gemini 呼出 3 系統が `fortune_api.dart` に集中** → 一括で `/protected/*` 移行可能、扱いやすい
   - 回数制限 (Free 5/day, Pro 100/day 等) の実装も本ファイル + Worker `/fortune`, `/tarot`, `/relocation` の中央で行う
   - **本ファイルの行数 (250 行) = Pro 課金の中心**

2. **`reverse_geocode.dart` (Nominatim 直叩き) は Pro 公開時に判断が必要**
   - 案 A: そのまま (= Nominatim 利用規約遵守、 UA 設定確認のみ)
   - 案 B: Worker 経由化 (`/reverse-geocode` 新規) で UA / レートリミット制御を Worker 側に集約
   - **私の推奨**: 案 B (= 攻撃面・運用面を Worker に集約)。実装コスト ~1h

3. **`celestial_events.dart` の起動 initialize は Free でも稼働させる必要**
   - main.dart で `await CelestialEvents.initialize()` = 起動時に必ず呼ばれる
   - 「無料ユーザーも天体イベントバーは表示」想定なので、`/astro/events` は `/public/*` 配下

4. **`/astro/chart` ラッパが utils/ に無いのは設計上の歪み**
   - `screens/map/map_astro.dart` から Horoscope が import している = Map ↔ Horo の意外な結合
   - 課金実装でリファクタする好機 (ラッパを `lib/utils/astro_chart_api.dart` に切り出し)

### 2a.6 機械抽出への参照

層 2a の機械抽出 raw: [`feature_inventory/02a_api_wrappers.md`](feature_inventory/02a_api_wrappers.md)

---

## 層 2b: 永続化/キャッシュ

### 2b.1 概要

`lib/utils/` 配下、**shared_preferences 等の storage import あり** の 3 ファイル / 計 907 行。
**Solara のほぼ全画面が依存** (Grep で 25 ファイルが import) = 永続化はアプリの中央集権。

### 2b.2 ファイル別 役割 + 呼出元 (3 本)

| # | ファイル | 行 | 役割 | 呼出元 |
|---|---|---|---|---|
| 1 | [`solara_storage.dart`](../lib/utils/solara_storage.dart) | 404 | **永続化中央集権ファイル**。SolaraProfile, Reading 履歴, Intention, dailyResetHour/Minute, Map style, Forecast 設定, overlay state, notTodayCount 等 32 public 関数 | main.dart + 全画面 (Sanctuary / Map / Horo / Observe / Galaxy / Forecast / Locations) + moon overlay 系 widgets |
| 2 | [`forecast_cache.dart`](../lib/utils/forecast_cache.dart) | 462 | **`/astro/forecast` 呼出 + 永続化キャッシュ + クールダウン + ◯◯期検出**。`ForecastDay`, `LifePeriod`, `ForecastCache`, `ForecastRepo`、`detectLifePeriods` (運勢サイクル抽出ロジック) | [forecast_screen](../lib/screens/forecast_screen.dart), [forecast_life_periods](../lib/screens/forecast/forecast_life_periods.dart), [forecast_top5](../lib/screens/forecast/forecast_top5.dart), [galaxy_screen](../lib/screens/galaxy_screen.dart) (?) |
| 3 | [`app_locale.dart`](../lib/utils/app_locale.dart) | 41 | 言語切替 (端末/JP/EN) の global singleton。SharedPreferences で永続化 | main.dart (`AppLocale.instance.load()`) + 言語表示する全画面 |

### 2b.3 機械分類の盲点 — `forecast_cache.dart` は実態が 2a/2b ハイブリッド

`forecast_cache.dart` は **`/astro/forecast` 呼出 (API ラッパ) + キャッシュ (永続化) + 解析 (`detectLifePeriods`)** を 1 ファイルで全部やっている。
本来は分けるべきだが、現状の Solara はこの一体型を採用。 機械分類は shared_preferences import を理由に 2b 判定したが、API ラッパとしての側面 (= 層 2a) も持つ。

これは設計判断の話で、リファクタ候補 (分割) ではあるが、現状の 462 行で 1 ファイル管理は許容範囲。

### 2b.4 課金検討に直結する示唆

1. **`solara_storage.dart` がアプリ状態の全てを握っている = クラウドバックアップ Pro 候補の中心**
   - 32 個の load/save 関数全部がバックアップ対象になりうる
   - Pro 機能: 「設定とサイクル履歴の自動バックアップ」「機種変更時の引き継ぎ」
   - 実装手段: 本クラスに `exportAll() / importAll()` を追加、Firebase Auth + Firestore か CF Worker KV 経由

2. **`forecast_cache.dart` の KV 月次クォータ (Worker 側 60/IP/month) が Pro 課金の自然な境界**
   - Free: 月 60 回まで (1 日 2 回程度)
   - Pro: 無制限 (rate limit のみ)
   - 実装は `checkKvForecastQuota` ([worker/src/index.js:73](../worker/src/index.js)) の bypass 条件追加だけ

3. **`detectLifePeriods` (運勢サイクル検出) は無料機能の差別化要素**
   - 365 日分のスコアから「◯◯期」を自動抽出する独自アルゴリズム ([architecture.md](architecture.md))
   - Pro 機能で「過去 5 年の◯◯期一覧」「来年予測の精密化」拡張案が考えられる

4. **`app_locale.dart` は i18n フェーズで本格稼働**
   - 現状: jp/en の 2 言語 ([main.dart:42](../lib/main.dart))
   - 実装は singleton で問題なし。Pro 公開で英語版リリース ([feedback_i18n_last](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_i18n_last.md)) と直結

### 2b.5 機械抽出への参照

層 2b の機械抽出 raw: [`feature_inventory/02b_persistence.md`](feature_inventory/02b_persistence.md)

---

## 層 2c: グローバル singleton

### 2c.1 概要

`lib/utils/` 配下、**initialize/load で起動時に bundled asset を読む 1 ファイル / 55 行**。

機械分類は厳密には 1 ファイルだが、意味的には:
- 層 2a の **`celestial_events.dart`** (起動 initialize、`/astro/events` キャッシュ)
- 層 2b の **`app_locale.dart`** (起動 load、SharedPreferences)

も singleton 的振る舞いで、本層と類似の役割。Solara のグローバル singleton は実質 3 つあると見るのが正確。

### 2c.2 ファイル別 役割 + 呼出元 (1 + 概念上 2)

| # | ファイル | 行 | 役割 | 呼出元 |
|---|---|---|---|---|
| 1 | [`tarot_data.dart`](../lib/utils/tarot_data.dart) | 55 | 78 枚タロットデッキを bundled JSON asset から起動時 `initialize()` で読み込む。`getCard(id)` で照会 | main.dart (`TarotData.initialize()`) + Observe 系 (tarot_card.dart 検索) |
| (準) | [`celestial_events.dart`](../lib/utils/celestial_events.dart) | 314 | 機械分類は 2a だが singleton + initialize 構造 | (層 2a.2 参照) |
| (準) | [`app_locale.dart`](../lib/utils/app_locale.dart) | 41 | 機械分類は 2b だが singleton 構造 | (層 2b.2 参照) |

### 2c.3 main.dart 起動シーケンスとの対応

[`main.dart:15-27`](../lib/main.dart) で起動時に呼ばれる 3 つ:
1. `await TarotData.initialize()` — 78 枚 JSON 読み込み
2. `await CelestialEvents.initialize()` — 静的天体イベント JSON + キャッシュ初期化
3. `await AppLocale.instance.load()` — SharedPreferences から言語オーバーライド復元

**起動順序のリスク**:
- 3 つとも `await` で順次実行 (並列ではない) → 起動が約 200〜500ms 遅延
- Pro 公開時に「初回起動 splash」(層 4e 関連 [`project_solara_stella_revival`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_stella_revival.md)) を実装する場合、本シーケンス完了まで splash を出す形が自然

### 2c.4 課金検討に直結する示唆

1. **3 つの singleton は全て無料機能の前提** → Pro 公開で `/protected/*` 化対象外
2. **`tarot_data.dart` の TarotCard データは静的固定** → Pro 化対象ではない (= 層 1c.3 と同じ)
3. **singleton パターンの統一**: 現状 instance + Notifier (AppLocale) と static class (TarotData, CelestialEvents) が混在。Riverpod 等の状態管理導入時に整理候補

### 2c.5 機械抽出への参照

層 2c の機械抽出 raw: [`feature_inventory/02c_globals.md`](feature_inventory/02c_globals.md)

---

(層 3a 以降は次セッション以降で追記)
