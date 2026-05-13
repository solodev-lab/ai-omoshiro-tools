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

(層 1b 以降は次セッション以降で追記)
