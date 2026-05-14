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
> - [x] 層 3a: 共通ウィジェット (純粋) — 2026-05-14 完成
> - [x] 層 3b: テーマ・装飾 — 2026-05-14 完成
> - [x] 層 3c: 演出ウィジェット (animated) — 2026-05-14 完成
> - [x] 層 4a: Map 画面 — 2026-05-14 完成
> - [x] 層 4b: Horoscope 画面 — 2026-05-14 完成
> - [x] 層 4c: Observe (Tarot) 画面 — 2026-05-14 完成
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

`lib/utils/` 配下の 5 ファイル / 計 1,424 行。**副作用なし** (http なし、storage なし、initialize なし)。
画面間で広く共有される数学・データ変換のみ。**Dart 完結 = Worker 呼出ゼロ**。

**機械分類の精度** (✅ 2026-05-14 オーバーライド適用済): 当初は静的辞書ヘルパー 3 本 (`astro_glossary.dart`, `celestial_event_meanings.dart`, `planet_intro.dart`) も `Map<>` リテラル数ヒューリスティックで 1a に入っていたが、`extract.py` の `PATH_OVERRIDES` で 1b に明示移動。これにより 1a は「真の純計算ユーティリティのみ」を保持する状態に整理された。

### 1a.2 ファイル別 役割 + 呼出元 (5 本)

| # | ファイル | 行 | 役割 | 主要 export | 呼出元 (画面層) | 性質 |
|---|---|---|---|---|---|---|
| 1 | [`astro_math.dart`](../lib/utils/astro_math.dart) | 30 | 角度の正規化 + 最小角距離。重複検出 ([code_audit](../tools/code_audit/audit.py) T1) で 4 ファイル散在を集約 | `normalize360`, `angDist` | astro_lines, astro_houses, [map_astro](../lib/screens/map/map_astro.dart), [horoscope_screen](../lib/screens/horoscope_screen.dart), [horo_pattern_logic](../lib/screens/horoscope/horo_pattern_logic.dart) | **基礎中の基礎、全層が依存** |
| 2 | [`astro_houses.dart`](../lib/utils/astro_houses.dart) | 208 | LST 復元 + ASC/MC/Placidus 12 ハウス Dart 完結。Phase M2 (リロケーション/ACG) 用 | `HousesResult`, `calcHousesRelocate`, `cusp`, `assignPlanetHouse` | [map_relocation_popup](../lib/screens/map/map_relocation_popup.dart), [horoscope_screen](../lib/screens/horoscope_screen.dart), [horo_relocation_panel](../lib/screens/horoscope/horo_relocation_panel.dart), [horo_planet_table](../lib/screens/horoscope/horo_planet_table.dart) | **Worker `/astro/chart` と機能重複** (両方で実装あり) |
| 3 | [`astro_lines.dart`](../lib/utils/astro_lines.dart) | 588 | 40 本アスペクト線計算 (球面三角法) + Haversine 近接検出 + GMST 計算 | `AstroFrame`, `AstroLine`, `NearbyAstroLine`, `astroFrameKey`, `gmstHoursFromUtc`, `solarArcPlanets`, `buildAstroLines`, `buildAstroLinesAt`, `findNearbyLinesScreen` | Map のみ ([map_screen](../lib/screens/map_screen.dart), map_relocation_popup, [map_line_narrative_sheet](../lib/screens/map/map_line_narrative_sheet.dart), [map_astro_lines](../lib/screens/map/map_astro_lines.dart), [map_astro_carto](../lib/screens/map/map_astro_carto.dart)) | **Pro 候補の素材** — 「アスペクトライン 120 本拡張」は本ファイル拡張で作れる (Worker 不要) |
| 4 | [`direction_energy.dart`](../lib/utils/direction_energy.dart) | 238 | Soft/Hard 独立 2 エネルギーの中核データ構造 + アスペクト寄与の集約ロジック | `DirectionEnergy`, `EnergyMode`, `AspectContribution`, `AggregatedAspect`, `classify`, `scaledBy`, `aggregateContributions` | Map のみ ([map_screen](../lib/screens/map_screen.dart), [map_fortune_sheet](../lib/screens/map/map_fortune_sheet.dart), [map_direction_popup](../lib/screens/map/map_direction_popup.dart), [map_astro](../lib/screens/map/map_astro.dart)) | **設計思想の核** ([project_solara_design_philosophy](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_design_philosophy.md))。`total = soft + hard` 禁止 |
| 5 | [`moon_phase.dart`](../lib/utils/moon_phase.dart) | 360 | Jean Meeus アルゴリズム月相計算 (14 補正項、±2-3 分精度) | `MoonPhase`, `findPreviousNewMoon`, `findNextNewMoon`, `findFullMoonInCycle`, `getPhaseDay`, `isNewMoon`, `isFullMoon`, `getCycleTotalDays`, `getCurrentDayIndex`, `getCycleId`, `getIllumination` 等 | [observe_screen](../lib/screens/observe_screen.dart) (Tarot)、[galaxy_screen](../lib/screens/galaxy_screen.dart)、[galaxy_constellation_builder](../lib/screens/galaxy/galaxy_constellation_builder.dart)、[cycle_spiral_painter](../lib/widgets/cycle_spiral_painter.dart) | Map で未使用、Observe/Galaxy 専用 |

(旧 6〜8 行: `astro_glossary.dart` / `celestial_event_meanings.dart` / `planet_intro.dart` は層 1b にオーバーライド移動済 = 1b.2 表参照)

### 1a.3 課金検討に直結する示唆

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

### 1a.4 Worker との重複コード (運用上の注意)

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

### 1a.5 機械抽出への参照

層 1a の機械抽出 raw: [`feature_inventory/01a_pure_calc.md`](feature_inventory/01a_pure_calc.md)

---

## 層 1b: 静的データ辞書

### 1b.1 概要

`lib/utils/` 配下 + `screens/map/` + `screens/horoscope/` 由来の **11 ファイル / 計 3,830 行**。**静的データが主体** で関数は辞書取り出しヘルパーが中心。副作用なし (= 層 1a と同じく純粋)、ただし「計算」というより「世界観テキストの貯蔵庫」。

**機械分類の精度** (✅ 2026-05-14 オーバーライド適用済):
- ヒューリスティック検出だけだと 5 ファイルだったが、`PATH_OVERRIDES` で 1a → 1b に 3 本、4a → 1b に 1 本、4b → 1b に 2 本を明示移動 = 計 11 本
- 移動した 6 本: `astro_glossary.dart` / `celestial_event_meanings.dart` / `planet_intro.dart` (1a 由来) + `daily_transit_data.dart` (4a 由来) + `horo_constants.dart` / `horo_aspect_description.dart` (4b 由来)

### 1b.2 ファイル別 役割 + 呼出元 (11 本)

| # | ファイル | 行 | 内容 | 主要 export | 呼出元 (画面層) | 特記 |
|---|---|---|---|---|---|---|
| 1 | [`astro_zenith_messages.dart`](../lib/utils/astro_zenith_messages.dart) | 170 | 天頂点 (Zenith Point) 解説メッセージ辞書。MC ライン上で観測者真上に来る唯一の地点の解説 | `ZenithMessage` | [map_astro_carto](../lib/screens/map/map_astro_carto.dart) (ACG モード専用) | ACG 天頂マーカータップ時に表示 |
| 2 | [`constellation_namer.dart`](../lib/utils/constellation_namer.dart) | 626 | 星座名生成 v2 (形容詞 × 名詞)、Prim MST 構築、エッジ生成、レア度算出、HUE シフト | `ConstellationNamer`, `buildName`, `rarityPercentage`, `hueShift`, `adjColor`, `computeMST`, `buildEdges`, `isFlipX`, `artAssetPath` | Galaxy 5 ファイル + [constellation_painter](../lib/widgets/constellation_painter.dart), [catasterism_formation_overlay](../lib/widgets/catasterism_formation_overlay.dart) | **計算ロジック比率高め** — 1a 寄りの側面あり (機械分類が辞書判定したのは形容詞/名詞テーブルの大きさ)。Galaxy の世界観 (= 月相サイクルの「刻星化」演出) の心臓 |
| 3 | [`cycle_story_texts.dart`](../lib/utils/cycle_story_texts.dart) | 86 | 月齢サイクル (新月/満月/刻星化) のストーリーテキスト JP/EN | `CycleStoryTexts`, `getNewMoon`, `getFullMoon`, `getCatasterism` | [new_moon_overlay](../lib/widgets/new_moon_overlay.dart), [full_moon_overlay](../lib/widgets/full_moon_overlay.dart), [catasterism_overlay](../lib/widgets/catasterism_overlay.dart) | JP/EN ネイティブ別書き (翻訳ではない)。`_isJapanese()` で切替 |
| 4 | [`solara_manifesto.dart`](../lib/utils/solara_manifesto.dart) | 141 | Solara 設計思想テキスト (3 セクション: 世界観 / 2 エネルギー / 委ねる宣言) | `SolaraManifesto`, `SolaraManifestoSection`, `getSections` | [solara_philosophy_screen](../lib/screens/solara_philosophy_screen.dart) のみ | 「占い的吉凶判定をしない」を文章化したアプリの哲学的根幹 ([project_solara_design_philosophy](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_design_philosophy.md)) |
| 5 | [`title_data.dart`](../lib/utils/title_data.dart) | 395 | 144 称号システムデータ (12 太陽部位 × 12 月部位 + 25 class) + 太陽/月星座近似算出 | `TitleClass`, `getSunSign`, `getMoonSign` | [class_card](../lib/widgets/class_card.dart), [sanctuary_screen](../lib/screens/sanctuary_screen.dart), [sanctuary_title_diagnosis](../lib/screens/sanctuary/sanctuary_title_diagnosis.dart), [class_share_card](../lib/screens/sanctuary/class_share_card.dart) | **EN 版 144 称号未実装** ([project_solara_title_system](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_title_system.md)) |
| 6 | [`astro_glossary.dart`](../lib/utils/astro_glossary.dart) | 586 | 占星術専門用語の解説辞書 + popup 表示ヘルパー (50+ エントリ: asc/mc/house/aspect/relocation/transit_acg 等) | `AstroGlossaryEntry`, `astroGlossary`, `showAstroGlossaryDialog` | [astro_term_label](../lib/widgets/astro_term_label.dart)、Map の popup 6 種、[map_relocation_popup](../lib/screens/map/map_relocation_popup.dart)、[map_line_narrative_sheet](../lib/screens/map/map_line_narrative_sheet.dart) | (1a→1b オーバーライド済) `showInfoPopup` 経由で説明 popup を表示 |
| 7 | [`celestial_event_meanings.dart`](../lib/utils/celestial_event_meanings.dart) | 52 | 天体イベント (ingress/retrograde/eclipse/conjunction/node_shift) の占星術的意味辞書 | `getEventMeaningJP` | [celestial_event_bar](../lib/widgets/celestial_event_bar.dart) のみ | (1a→1b オーバーライド済) `/astro/events` 取得結果の表示用 |
| 8 | [`planet_intro.dart`](../lib/utils/planet_intro.dart) | 559 | 10 惑星の Map マーカータップ説明テキスト (natal/transit/progressed 3 フレーム × 10 惑星 = 30 パターン) | `PlanetIntroFrame`, `PlanetIntro`, `frameOf` | [map_screen](../lib/screens/map_screen.dart)、[map_planet_intro_popup](../lib/screens/map/map_planet_intro_popup.dart) | (1a→1b オーバーライド済) Map 惑星マーカータップ時の説明源 |
| 9 | [`daily_transit_data.dart`](../lib/screens/map/daily_transit_data.dart) | 1,013 | Daily Transit 画面用 静的データ大容量: `AngleFilter` enum + ラベル/セット/意味マップ + `CategoryFilterTips` (5 カテゴリ × 外向き/内向き各 4 tips) + `planetAngleBaseText` (10 惑星 × 4 アングル = 40 パターン基本意味) + `categoryAppendix` + `categoryPlanetSets` | `AngleFilter`、`angleFilterLabel/Set/Meaning`、`CategoryFilterTips`、`planetAngleBaseText`、`categoryAppendix`、`categoryPlanetSets` | [map_daily_transit_screen](../lib/screens/map/map_daily_transit_screen.dart) のみ | (4a→1b オーバーライド済) 物理的には `screens/map/` 配下だが、実態は静的辞書。Worker `fortune.js` の `categoryPlanetSets` と一致 (要同期保守) |
| 10 | [`horo_constants.dart`](../lib/screens/horoscope/horo_constants.dart) | 86 | Horoscope 系の共有静的データ: `signs` (12 星座記号)、`signNames`、`signColors`、`planetGlyphs` (10 惑星 Unicode 記号)、`planetNamesJP`、`fortuneCategories` (5 カテゴリ)、`aspectSymbol`、`aspectTypes` (8 種 × angle/orb/quality/color)、`planetGroups` (personal/social/generational/angle)、`angleNamesJP`、`patternOrbSettings`、`patternStyles`、`fortunePlanets` | (上記全部 const) | **13 ファイル横断** ([map_relocation_popup](../lib/screens/map/map_relocation_popup.dart), [map_line_narrative_sheet](../lib/screens/map/map_line_narrative_sheet.dart), Horo 系 9 ファイル, [galaxy_screen](../lib/screens/galaxy_screen.dart) ほか) | (4b→1b オーバーライド済) 物理的には `screens/horoscope/` 配下だが、実態は cross-screen 静的辞書。`fortunePlanets` は UI フィルタチップ用 (Fortune API 用は別) |
| 11 | [`horo_aspect_description.dart`](../lib/screens/horoscope/horo_aspect_description.dart) | 116 | アスペクト説明生成: `planetInfo` (14 惑星/アングル × theme/keywords) + `aspectInfo` (8 アスペクト × name/angle/quality/summary) 静的辞書 + `buildAspectDescription` 1 関数 (惑星 + アスペクトから 3 セクション解説生成) | `planetInfo`, `aspectInfo`, `buildAspectDescription` | [map_aspect_chip](../lib/screens/map/map_aspect_chip.dart) (Daily Transit)、[horo_aspect_list](../lib/screens/horoscope/horo_aspect_list.dart)、[horo_prediction_panel](../lib/screens/horoscope/horo_prediction_panel.dart) | (4b→1b オーバーライド済) Map+Horo 共用、`buildAspectDescription` は純関数 |

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

`lib/utils/` 配下 + `screens/map/map_astro.dart` (オーバーライド経由) の **7 ファイル / 計 1,440 行**。**Worker ↔ Flutter の通信境界**。
ここを把握すれば「課金時に `/protected/*` に移すべき呼出元」が全部見える。

**機械分類の精度** (✅ 2026-05-14 オーバーライド適用済): `screens/map/map_astro.dart` (508 行、`/astro/chart` ラッパ) は当初 4a 検出だったが `PATH_OVERRIDES` で 2a に明示移動。Map と Horoscope が両方 import する横断利用ファイルが本層に正しく入る状態に整理された。

### 2a.2 ファイル別 役割 + 呼出 endpoint + 呼出元 (7 本)

| # | ファイル | 行 | 呼出先 endpoint | 呼出元 (主要) | 特記 |
|---|---|---|---|---|---|
| 1 | [`solara_api.dart`](../lib/utils/solara_api.dart) | 35 | `/tz` (GET) + `solaraWorkerBase` 定数 export | `sanctuary_profile_editor`, `horo_birth_panel`, Map 各所 | **`solaraWorkerBase` 定数の出元** ([`project_solara_worker_url.md`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_worker_url.md) ハードコード禁止)。`fetchTimezoneName` 1 関数のみ |
| 2 | [`fortune_api.dart`](../lib/utils/fortune_api.dart) | 250 | **`/fortune`, `/relocation`, `/tarot`** (POST × 3、全て Gemini 系) | [horoscope_screen](../lib/screens/horoscope_screen.dart), [observe_screen](../lib/screens/observe_screen.dart), [horo_fortune_cards](../lib/screens/horoscope/horo_fortune_cards.dart), [horo_relocation_panel](../lib/screens/horoscope/horo_relocation_panel.dart) | **課金で守るべき最大対象 = Gemini 呼出 3 系統がここに集中**。Pro 公開時に `/protected/*` 移行 + 回数制限の中心 |
| 3 | [`daily_transits_api.dart`](../lib/utils/daily_transits_api.dart) | 241 | `/astro/daily-transits` (POST) | [map_daily_transit_screen](../lib/screens/map/map_daily_transit_screen.dart), [map_aspect_chip](../lib/screens/map/map_aspect_chip.dart) | F1 機能、課金で「無制限拠点切替」の Pro 化候補 |
| 4 | [`celestial_events.dart`](../lib/utils/celestial_events.dart) | 314 | `/astro/events` (GET) | [main.dart](../lib/main.dart) (起動 initialize)、[new_moon_overlay](../lib/widgets/new_moon_overlay.dart)、[full_moon_overlay](../lib/widgets/full_moon_overlay.dart)、[celestial_event_bar](../lib/widgets/celestial_event_bar.dart)、[galaxy_screen](../lib/screens/galaxy_screen.dart) | **singleton 的に initialize**、機械分類は 2a だが層 2c 寄りの側面あり (= 層 2c.4 と整合) |
| 5 | [`reverse_geocode.dart`](../lib/utils/reverse_geocode.dart) | 50 | **Nominatim 直叩き** (`nominatim.openstreetmap.org/reverse`) | [map_vp_panel](../lib/screens/map/map_vp_panel.dart)、[horo_birth_panel](../lib/screens/horoscope/horo_birth_panel.dart) | **🔴 重要**: 唯一 Worker 経由でない外部 API 呼出。Nominatim は無料 + key 不要 + 1 req/sec 制限。Pro 公開時にレートリミット遵守 + UA 設定確認が必要 |
| 6 | [`tile_http_client.dart`](../lib/utils/tile_http_client.dart) | 42 | (Worker URL 自体は呼出さず、共有 HttpClient のみ提供) | [map_screen](../lib/screens/map_screen.dart) (`sharedTileHttpClient`)、[map_styles](../lib/screens/map/map_styles.dart) | **fd 枯渇対策** ([`feedback_http_fd_leak`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_http_fd_leak.md), [`project_solara_a101fc_fd_leak`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_a101fc_fd_leak.md))。maxConnectionsPerHost=6, idleTimeout=15s |
| 7 | [`screens/map/map_astro.dart`](../lib/screens/map/map_astro.dart) | 508 | **`/astro/chart`** (POST) + 16 方位スコア計算 | [map_screen](../lib/screens/map_screen.dart) (Map 描画の心臓)、[horoscope_screen](../lib/screens/horoscope_screen.dart) (`fetchChart` 共用) | (4a→2a オーバーライド済) **🔴 Map+Horo 共用の chart fetcher**。`ChartResult` (natal+transit+progressed+ASC/MC/DSC/IC + 全アスペクト)、`ScoreResult` (16 方位 × 5 カテゴリ Soft/Hard)、`fetchChart`、`scoreAll`、`isAngle`、`addT/addP/addCT/addCP`。リファクタ候補 (将来 `lib/utils/astro_chart_api.dart` への移動) |

### 2a.3 Worker endpoint との対応マップ (層 0 ↔ 層 2a)

| Worker endpoint | 層 2a ラッパ | Flutter 呼出元 |
|---|---|---|
| `/astro/chart` | `screens/map/map_astro.dart`'s `fetchChart` (2a オーバーライド済) | Map + Horoscope |
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
- **ラッパが `lib/utils/` にない呼出**: `/search` (map_search.dart は 4a)、`/tiles/*` (map_styles.dart は 4a)
  - = 課金実装時に「`screens/map/` 配下の Worker 呼出箇所」も同等にチェック必須
- **オーバーライドで 2a 入りした例外**: `/astro/chart` (map_astro.dart) は物理的に `screens/map/` だが層は 2a

### 2a.4 課金検討に直結する示唆

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

4. **`/astro/chart` ラッパが `screens/map/` に物理的にある = 設計上の歪み**
   - `screens/map/map_astro.dart` から Horoscope が import している = Map ↔ Horo の意外な結合
   - オーバーライドで層 2a に明示移動済だが、**物理 path は未移動** = リファクタ余地あり
   - 課金実装でリファクタする好機 (ラッパを `lib/utils/astro_chart_api.dart` に切り出し)

### 2a.5 機械抽出への参照

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

## 層 3a: 共通ウィジェット (純粋)

### 3a.1 概要

`lib/widgets/` 配下 + `screens/horoscope/horo_antique_icons.dart` (オーバーライド経由) の **23 ファイル / 計 5,907 行**。**`AnimationController` を持たない** widget 群 (= 機械分類のヒューリスティック)。
ただし `StatefulWidget` であっても `ScrollController` 等の純粋な state のみのもの (例: `MoonScrollingStory`, `LocationPickerMinimap`) は本層に含まれる。

**機械分類の精度** (✅ 2026-05-14 オーバーライド適用済): `screens/horoscope/horo_antique_icons.dart` (295 行、`AntiqueGlyph` widget + `_AntiqueIconPainter` CustomPainter) は cross-screen で 16 ファイルから参照 (Map / Galaxy / Horo / no_profile_guide / galaxy_star_atlas)。物理 path は `screens/horoscope/` 配下のままだが、`PATH_OVERRIDES` で 3a に明示移動。

23 ファイルは性質が大きく異なるので、本章では **機能群** 単位で整理する。

| 群 | 役割 | ファイル数 | 行 |
|---|---|---|---|
| A 基礎レイアウト/装飾 | popup・glass・overflow ・用語ラベル + アンティークアイコン | 5 | 609 |
| B ナビゲーション | bottom NavBar + 5 nav icon CustomPainter | 2 | 381 |
| C カテゴリアイコン | 6 種カテゴリの Gemini WebP アイコン | 1 | 80 |
| D 空状態/案内 | プロフィール未設定時のガイドカード | 1 | 51 |
| E Sanctuary 用 | 144 称号カード + ミニマップ座標選択 | 2 | 447 |
| F 月オーバーレイ共通部 | 新月/満月/刻星化 overlay の共通 building blocks | 2 | 266 |
| G Galaxy ペインター | 星座 + サイクルスパイラル + 装飾スパイラル | 3 | 736 |
| H Cycle 天体イベント表示 | 月別イベント横スクロールバー (Galaxy 下部) | 1 | 129 |
| I Map fortune オーバーレイ painter | 5 カテゴリ × CustomPainter + 共通 builder | 6 | 3,212 |

**合計**: 23 ファイル / 5,911 行 (機械抽出 5,907 + 4 は moon_overlay.dart の re-export ヘッダ)

### 3a.2 群別 ファイル一覧 + 呼出元 + 役割

#### A. 基礎レイアウト/装飾 (5 本、計 609 行)

| ファイル | 行 | 主要 export | 呼出元 | 役割 |
|---|---|---|---|---|
| [`info_popup.dart`](../lib/widgets/info_popup.dart) | 113 | `showInfoPopup`, `_InfoPopupShell` | 22 ファイル (Map / Horo / Forecast / Sanctuary / Galaxy / `astro_glossary.dart` 等) | **🔴 統一 popup ヘルパー** ([`project_solara_popup_pattern`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_popup_pattern.md))。新規 popup は必ず本関数経由 (AlertDialog/showModalBottomSheet 直書き禁止)。barrierDismissible + 右上 × + GlassPanel 互換 + 高さ画面-120px 上限 |
| [`glass_panel.dart`](../lib/widgets/glass_panel.dart) | 31 | `GlassPanel` | `map_daily_transit_screen`, `full_moon_overlay`, `new_moon_overlay`, `catasterism_overlay`, `map_direction_popup`, `solara_philosophy_screen` | 半透明暗パネル容器 (`color: 0xE60A0A14` + `glassBorder` 枠)。**2026-05-03 BackdropFilter 撤去** (Adreno saveLayer leak の Critical 対策 = [`feedback_html_costly_widgets`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_html_costly_widgets.md))。blur なしで後ろがうっすら透けるだけ |
| [`solara_safe_text.dart`](../lib/widgets/solara_safe_text.dart) | 81 | `SolaraSafeText` | (現状は本ファイルから他へ未利用、規約用ボイラープレート) | **🔴 Row/Column 内 Text の overflow 安全ラッパ** ([`feedback_text_overflow`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_text_overflow.md))。`Flexible(flex/fit, child: Text(maxLines, overflow:ellipsis))` をワンライナー化 |
| [`astro_term_label.dart`](../lib/widgets/astro_term_label.dart) | 85 | `AstroTermLabel` | `map_relocation_popup` + 各種 popup 内 (Map / Horo) | 用語 i ボタン (タップで `showAstroGlossaryDialog` 呼出 = 層 1a `astro_glossary.dart`)。`termKey` が辞書未登録なら i アイコン非表示。2026-05-11 child を Flexible でラップする overflow 修正済 |
| [`screens/horoscope/horo_antique_icons.dart`](../lib/screens/horoscope/horo_antique_icons.dart) | 295 | `AntiqueIcon` enum (12 種: reading/birthStar/crescent/compassStar/sunRays/asterisk/triangleOrnate/eightPointStar/ornateStarCrescent/cycleSpiral/flourishKey/forecast 等)、`AntiqueGlyph` widget、`_AntiqueIconPainter` CustomPainter (12 個の `_buildPath` / `_buildFills` 個別描画) | **16 ファイル横断** (Map: map_screen / map_relocation_popup 等、Horo: 11 ファイル、Galaxy: 2 ファイル、widgets/no_profile_guide ほか) | (4b→3a オーバーライド済) **アンティーク神秘画調アイコン集**。NoProfileGuide のアイコン、Horoscope 各 panel ヘッダ、Galaxy アトラス、Map ガイド等で使用 |

#### B. ナビゲーション (2 本、計 381 行)

| ファイル | 行 | 主要 export | 呼出元 | 役割 |
|---|---|---|---|---|
| [`solara_nav_bar.dart`](../lib/widgets/solara_nav_bar.dart) | 163 | `SolaraNavBar` (+ `baseHeight`, `totalHeight`, `systemNavInset` static) | [main.dart](../lib/main.dart) (`SolaraHome` 直配置)、[map_planet_lines.dart](../lib/screens/map/map_planet_lines.dart) (`totalHeight` で bottom 位置計算) | HTML `shared/styles.css` に正確に合わせる bottom NavBar (h=80 + 5 タブ Expanded 分割)。**2026-04-29 Android systemNav (3 ボタン △〇□) 対応**: 閾値 30px で 3 ボタン/ジェスチャー判定、3 ボタン時のみ追加高 (`systemNav - 12`) を加算。**2026-05-03 BackdropFilter 撤去**で alpha 高めの gradient に置換 (glass_panel と同じ Adreno 対策) |
| [`nav_icons.dart`](../lib/widgets/nav_icons.dart) | 218 | `SolaraNavIcons.map/horo/tarot/galaxy/sanctuary` (static factory) + 5 `_*IconPainter` (CustomPainter) | `solara_nav_bar.dart` のみ | 5 タブ用ベクター SVG 互換アイコン (HTML `shared/icons.js` exact)。Map = circle + cross-hairs + diamond、Horo = 同心円 + 十字、Tarot = card + star、Galaxy = ellipse + spiral arms + dots、Sanctuary = temple + door + circle window |

#### C. カテゴリアイコン (1 本、80 行)

| ファイル | 行 | 主要 export | 呼出元 | 役割 |
|---|---|---|---|---|
| [`category_icon.dart`](../lib/widgets/category_icon.dart) | 80 | `CategoryIconKind` enum、`CategoryIcon` widget、`DominantFortuneKindToCategoryIcon` extension、`_CategoryIconKindAsset` extension | `map_menu_chips`, `map_daily_transit_screen` | 6 種 (all/love/money/work/healing/communication) の Gemini 生成 WebP アンティーク神秘画 (`assets/menu_icons/{kind}.webp`)。**2026-05-10 CustomPaint (Style D) → WebP に置換** (ベクター描画は git history 復元可能)。`DominantFortuneKind` (層 3c) → `CategoryIconKind` への変換 extension あり |

#### D. 空状態/案内 (1 本、51 行)

| ファイル | 行 | 主要 export | 呼出元 | 役割 |
|---|---|---|---|---|
| [`no_profile_guide.dart`](../lib/widgets/no_profile_guide.dart) | 51 | `NoProfileGuide` | [forecast_screen](../lib/screens/forecast_screen.dart), [locations_screen](../lib/screens/locations_screen.dart), [map_screen](../lib/screens/map_screen.dart) | プロフィール未設定時 (SolaraProfile が null) のガイドカード。「設定する→」タップで `maybePop()` (シート閉) + `onNavigateToSanctuary?.call()`。**2026-05-04 集約**: Forecast/Locations にあった 1,195 char コピペを抽出 (map_screen / horo_backdrop は装飾異なるため別実装で残存) |

#### E. Sanctuary 用 (2 本、計 447 行)

| ファイル | 行 | 主要 export | 呼出元 | 役割 |
|---|---|---|---|---|
| [`class_card.dart`](../lib/widgets/class_card.dart) | 306 | `ClassCard`, `ClassCardMode` enum | [sanctuary_screen](../lib/screens/sanctuary_screen.dart), [sanctuary_title_diagnosis](../lib/screens/sanctuary/sanctuary_title_diagnosis.dart), [class_share_card](../lib/screens/sanctuary/class_share_card.dart) | 25 クラスのアール・ヌーヴォー画風カード表示 (`assets/class-cards/<axis>_<court>_<nameen>.webp`)。Light/Shadow 両面、`titleLightJP` / `titleShadowJP` で「省察に長けた / 騎士」のように一言＋クラス名表示。軸別 5 色グロー (power=crimson, mind=sapphire, spirit=violet, shadow=amethyst, heart=rose-pink)。診断 reveal + シェアカード + 将来図鑑用 |
| [`location_picker_minimap.dart`](../lib/widgets/location_picker_minimap.dart) | 141 | `LocationPickerMinimap` | [sanctuary_profile_editor](../lib/screens/sanctuary/sanctuary_profile_editor.dart), [sanctuary_home_editor](../lib/screens/sanctuary/sanctuary_home_editor.dart) | Sanctuary 出生地/現住所入力で検索後の微調整用ミニマップ。**中央固定ピン + マップパン**で座標選択 (ピンドラッグでない = `IgnorePointer` で gesture を `FlutterMap` へ通す)。`didUpdateWidget` で親側 lat/lng が大きく変わったら map も追従 (≤ 0.0001 はループ防止で無視) |

#### F. 月オーバーレイ共通部 (2 本、計 266 行)

| ファイル | 行 | 主要 export | 呼出元 | 役割 |
|---|---|---|---|---|
| [`moon_overlay.dart`](../lib/widgets/moon_overlay.dart) | 4 | (re-export のみ) | [galaxy_screen](../lib/screens/galaxy_screen.dart) | 後方互換用 re-export ファイル。`new_moon_overlay` / `full_moon_overlay` / `catasterism_overlay` (3 つとも層 3c) を `export 'xxx.dart'` で集約 |
| [`moon_overlay_shared.dart`](../lib/widgets/moon_overlay_shared.dart) | 262 | `revealPoeticMessage`, `moonOverlaySelectableCard`, `moonOverlayPageStructure`, `measureMoonOverlayTapGeometry`, `mysticalMoonBackdrop`, `MoonScrollingStory` (Stateful) | `new_moon_overlay`, `full_moon_overlay`, `catasterism_overlay` (層 3c の月 overlay 3 種) | **月 / 刻星化 overlay の共通 building blocks** (2026-05-06 audit T2/T7 で集約)。詩的メッセージ + 選択カード + ページ構造 (story/selection/reveal 3 段 fade) + 幾何測定 + 神秘背景 + 自動スクロール物語 (30px/s, ShaderMask フェード) |

#### G. Galaxy ペインター (3 本、計 736 行)

| ファイル | 行 | 主要 export | 呼出元 | 役割 |
|---|---|---|---|---|
| [`cycle_spiral_painter.dart`](../lib/widgets/cycle_spiral_painter.dart) | 396 | `CycleSpiralPainter`, `_Vec3`, `_SpiralDot`, `_GADot`, `_Mulberry32` | [galaxy_screen](../lib/screens/galaxy_screen.dart) | **Galaxy 画面のメインペインター** — HTML `galaxy.html renderSpiral3D()` を Dart 移植。3 層 (Ghost spiral path / spiral anchor dots / reading dots at Golden Angle 55° anamorphic camera) + `_drawBackgroundStars` + `_drawStellaCore` + 接続スレッド + `hitTestDot` (タップ判定)。`breathPhase` で呼吸アニメ受け取り (本ファイルに AnimationController なし、親 galaxy_screen 側で駆動) |
| [`constellation_painter.dart`](../lib/widgets/constellation_painter.dart) | 249 | `ConstellationPainter`, `MiniConstellationPainter` | [galaxy_replay_overlay](../lib/screens/galaxy/galaxy_replay_overlay.dart), [galaxy_star_atlas](../lib/screens/galaxy/galaxy_star_atlas.dart), [catasterism_formation_overlay](../lib/widgets/catasterism_formation_overlay.dart) | 星座描画ペインター v2 (anamorphic 3D)。Major Arcana = MST edges + `NOUN_SHAPES`、Minor Arcana = field stars (独立浮遊)。`cameraAngle` 55°=分散 / 0°=整列、`progress` で漸進描画、`artImage` で星座イラスト合成、`flipX` で左右反転。`MiniConstellationPainter` は Star Atlas grid card 用の小型版 |
| [`spiral_painter.dart`](../lib/widgets/spiral_painter.dart) | 91 | `SpiralPainter` | [galaxy_screen](../lib/screens/galaxy_screen.dart) | シンプル 3 周スパイラル + 日数ドット (active/inactive) + Stella 中心グロー の装飾ペインター。`CycleSpiralPainter` (本格 3D 版) とは別の軽量版。**`MaskFilter.blur` を使うため** GPU 負荷あり ([`todo_solara_perf_audit`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/todo_solara_perf_audit.md) の監査候補) |

#### H. Cycle 天体イベント表示 (1 本、129 行)

| ファイル | 行 | 主要 export | 呼出元 | 役割 |
|---|---|---|---|---|
| [`celestial_event_bar.dart`](../lib/widgets/celestial_event_bar.dart) | 129 | `CelestialEventBar` | [galaxy_screen](../lib/screens/galaxy_screen.dart) | Galaxy/Cycle 画面下部に常時表示する天体イベント横スクロールバー。`/astro/events` から取った `CelestialEvent` リストを chip 表示、タップで `showInfoPopup` 経由でイベント占星術的意味を表示 (層 1a `celestial_event_meanings.dart` 参照)。イベント type → アイコン記号テーブル: ingress=➜, retrograde=℞, retrograde_end=↻, eclipse=◑, conjunction=☌, node_shift=☊ |

#### I. Map fortune オーバーレイ painter (6 本、計 3,212 行)

[`dominant_fortune_overlay.dart`](../lib/widgets/dominant_fortune_overlay.dart) (層 3c、`AnimationController` あり) が「今日の最高スコアカテゴリ」に応じて 5 painter を切り替え、**1 日の最初のタップで約 4 秒間** 全画面演出。本層 3a にあるのは Painter 本体 (state 持たない CustomPainter) + 共通 builder。

| ファイル | 行 | 主要 export | 呼出元 | 役割 |
|---|---|---|---|---|
| [`fortune_overlays/_common.dart`](../lib/widgets/fortune_overlays/_common.dart) | 40 | `FortunePainterBuilder` (abstract)、`easeOutCubic`, `easeOutBack`, `easeInOutQuad`, `stageAlpha` | 5 painter + `dominant_fortune_overlay` | 5 painter の親契約 + 共通イージング関数 (減速 / バウンド / 二次 / 3 段階 α カーブ) |
| [`fortune_overlays/communication_painter.dart`](../lib/widgets/fortune_overlays/communication_painter.dart) | 642 | `CommunicationPainterBuilder`、`_CommunicationPainter`、`_NotePair`, `_Note`, `_Stream`, `_Spark`, `_Sparkle` | `dominant_fortune_overlay` | **コミュニケーション**: ルーン文字・占星術記号・ラテン語片が羊皮紙の上を流れ、ノート pair が衝突して spark + sparkle |
| [`fortune_overlays/healing_painter.dart`](../lib/widgets/fortune_overlays/healing_painter.dart) | 498 | `HealingPainterBuilder`、`_HealingPainter`、`_PetalPalette`, `_Petal`, `_LightMote`, `_Sparkle` | `dominant_fortune_overlay` | **癒し**: 月桂樹とオリーブの葉が下→上へ螺旋で舞い上がり、aurora band + light mote |
| [`fortune_overlays/love_painter.dart`](../lib/widgets/fortune_overlays/love_painter.dart) | 581 | `LovePainterBuilder`、`_LovePainter`、`_PetalPalette`, `_RosePetal`, `_Sparkle`, `_Ray`, `_Vine` | `dominant_fortune_overlay` | **恋愛**: 中心に金の魔法陣 (sigil) が開き、薔薇の花弁が放射 + 蔓 vine + god rays |
| [`fortune_overlays/money_painter.dart`](../lib/widgets/fortune_overlays/money_painter.dart) | 693 | `MoneyPainterBuilder`、`_MoneyPainter`、`_GoldPalette`, `_GoldPiece`, `_GoldDust`, `_Sparkle` | `dominant_fortune_overlay` | **金運**: 金貨・金箔 (coin + flake) が上から落ちて積み上がる落ち物ゲーム風 + dust + sparkle |
| [`fortune_overlays/work_painter.dart`](../lib/widgets/fortune_overlays/work_painter.dart) | 758 | `WorkPainterBuilder`、`_WorkPainter`、`_MedalPalette`, `_Medallion`, `_Gear`, `_GoldDust`, `_Sparkle` | `dominant_fortune_overlay` | **仕事**: 金の勲章 medallion が回転浮遊 + 歯車 gear + final moment 演出 |

### 3a.3 機械分類の盲点

1. **`AnimationController` 有無での 3a / 3c 振り分けは概ね妥当**だが、`MoonScrollingStory` (3a) は `ScrollController.animateTo` で時間連動の動きがある (= 厳密には演出寄りの State)。それでも `AnimationController` でない点で本層採用は許容範囲。

2. **fortune_overlays/ 5 painter は CustomPainter で state を持たないため正しく 3a**。親の `DominantFortuneOverlay` (3c) が `AnimationController` の `t` を渡して描画させる構造。**画面演出として一塊で動く** = 課金検討では「動く演出」として 3c と一緒に扱う方が自然 (層 3c 章でも言及予定)。

3. **`category_icon.dart` の `DominantFortuneKindToCategoryIcon` extension** は `dominant_fortune_overlay.dart` (3c) の enum を変換するため、3a → 3c の依存方向で参照している。逆 (3c → 3a) は問題ないが、3a 同士で共有された enum を 3c に置くより `direction_energy.dart` (層 1a) に寄せる選択肢もある (将来検討)。

### 3a.4 課金検討に直結する示唆

1. **`showInfoPopup` (info_popup.dart) は全画面の説明 UX を握る中央集権ポイント**
   - 22 ファイルが本関数経由で popup を出す = ここを改修すれば全画面の popup 体験が一括で変わる
   - **Pro 機能の説明 UX** (例: 「この機能は Pro 限定」「アップグレード」訴求) は本 helper を拡張する形が自然 (新引数 `proGate: true` で「Pro バッジ + アップグレード CTA」を追加する案など)
   - barrier dismissible でユーザー摩擦少ない = ペイウォール訴求にも向いている

2. **`solara_nav_bar.dart` + `nav_icons.dart` = アプリの第一印象**
   - 5 タブ全部が無料層から見える状態 = どのタブも「初期体験」になる
   - Pro 機能をタブ単位で分けない設計 (タブは全員見えて、中の一部機能が Pro) は実装コスト低 + 訴求柔軟
   - **タブ内に「Pro バッジ」を出すなら本 widget の拡張が必要** (現状は 5 タブのみ、Pro バッジ表示の枠なし)

3. **`category_icon.dart` の WebP アセットは Pro 拡張の素材として強力**
   - Gemini 生成のアンティーク神秘画 = ストア訴求素材としての価値高
   - **Pro 限定カテゴリ追加** (例: career, family, spiritual, etc.) は本 widget + WebP アセット 1 枚追加で済む = 拡張容易

4. **`class_card.dart` (Sanctuary 144 称号) は無料機能の差別化の中心**
   - 25 クラス × 144 タイトルカード = ユーザー独自の「あなただけの結果」
   - **Pro 拡張案**: シェアカード追加デザイン、月別称号変化追跡、図鑑/コレクション (将来)
   - **EN 版未実装** ([`project_solara_title_system`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_title_system.md)) が海外展開のボトルネック

5. **fortune_overlays/ 5 painter (合計 3,212 行) は Solara 演出の半分を占める = リソース集中分野**
   - 5 カテゴリの「1 日 1 回演出」は無料機能で十分インパクトあり、Pro 化対象としては弱い
   - **Pro 拡張案**: 演出のバリエーション追加 (例: 月別テーマ painter)、または「演出を毎回再生」設定の Pro 化 (Free は 1 日 1 回固定)
   - **保守性**: 5 painter が各 500〜750 行で類似構造 = 共通 builder ([`_common.dart`](../lib/widgets/fortune_overlays/_common.dart)) が抽象化できる余地は残存

6. **`solara_safe_text.dart` は overflow 対策の規約ファイル**
   - 現状他ファイルから参照ゼロだが、これは「規約として置いてある」状態 ([`feedback_text_overflow`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_text_overflow.md))
   - i18n フェーズ ([`feedback_i18n_last`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_i18n_last.md)) で EN テキスト追加時に活用すべき (英語は日本語より長くなる傾向 = overflow 再発リスク)

7. **`glass_panel.dart` + `solara_nav_bar.dart` の Adreno saveLayer leak 対策は Pro 公開前提**
   - 2026-05-03 に BackdropFilter 撤去済 = 公開時の Critical 安定性問題は解消済
   - 将来 BackdropFilter を再導入する場合は本ファイル経由で集中管理 (= 散発再導入で同じバグ再発を防げる)

### 3a.5 機械抽出への参照

層 3a の機械抽出 raw: [`feature_inventory/03a_widgets_pure.md`](feature_inventory/03a_widgets_pure.md)

---

## 層 3b: テーマ・装飾

### 3b.1 概要

`lib/theme/` 配下 2 本 + `screens/map/map_constants.dart` (オーバーライド経由) の **3 ファイル / 計 300 行**。**色定数と HTML 一致定数の貯蔵庫**。
他層 (widgets / screens / painters) は本層を import して色 / 線スタイル / 惑星シンボルを引く構造で、Solara の見た目の **唯一の源泉**。

**機械分類の精度** (✅ 2026-05-14 オーバーライド適用済):
- 当初プラン ([`project_solara_feature_extractor`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_feature_extractor.md)) では「theme/ + antique_icons + astro_glyphs 2 本」とあったが、`antique_icons.dart` / `astro_glyphs.dart` 単体ファイルは存在しない (`antique_icons` は [horo_antique_icons.dart](../lib/screens/horoscope/horo_antique_icons.dart) として Horoscope 画面層 4b に内包)
- `screens/map/map_constants.dart` (122 行、HTML `CHART_STYLE` + `TAROT.planets` 純定数) は当初 4a 検出だったが `PATH_OVERRIDES` で 3b に明示移動

### 3b.2 ファイル別 役割 + 呼出元 (3 本)

| # | ファイル | 行 | 主要 export | 呼出元 (画面層) | 性質 |
|---|---|---|---|---|---|
| 1 | [`solara_colors.dart`](../lib/theme/solara_colors.dart) | 110 | `SolaraColors` (static const Color 群 + `planetColor`, `elementColor` ヘルパー) | **19 ファイル** (widgets 9 + screens 9 + theme 1) で 143 occurrences | **色の唯一の源泉**。Soft/Hard 独立 2 エネルギー色、惑星 10 色、エレメント 4 色、月相、glass、spiral 全て格納 |
| 2 | [`solara_theme.dart`](../lib/theme/solara_theme.dart) | 68 | `SolaraTheme.dark` (ThemeData) + `_textTheme` (DM Sans + Noto Sans JP fallback) | [main.dart:40](../lib/main.dart) のみ (`MaterialApp.theme: SolaraTheme.dark`) | アプリ全体の ThemeData。**日本語フォールバック規約あり**: `fontFamilyFallback: [Noto Sans JP]` を `TextTheme.apply` で全 TextStyle に伝搬 |
| 3 | [`screens/map/map_constants.dart`](../lib/screens/map/map_constants.dart) | 122 | `ChartLineStyle` (natal/progressed/transit の線スタイル)、`PlanetMeta` (惑星シンボル + 色) | Map 系 (map_screen, map_astro_lines, map_planet_lines, map_relocation_popup, map_line_narrative_sheet, map_direction_popup ほか) | (4a→3b オーバーライド済) HTML `CHART_STYLE` と `TAROT.planets` の Dart 移植純定数。物理的には `screens/map/` 配下 |

### 3b.3 SolaraColors 色定数の構造 (`planetColor`, `elementColor`)

| 群 | 色定数 | 用途 |
|---|---|---|
| **Primary** | `solaraGoldLight` (`F9D976`), `solaraGold` (`F6BD60`), `celestialBlueLight`, `celestialBlueDark` | アプリのブランド 4 色。Gold は強調・active、Blue は背景 |
| **Typography** | `textPrimary` (`EAEAEA`), `textSecondary` (`ACACAC`) | 本文・補助文字色 |
| **🔴 Energy 2 軸** | `energySoft` (銀月色 `C8D4E8`) + `Light/Dark/Glow` 計 4 色、`energyHard` (金陽色 `D6915C`) + `Light/Dark/Glow` 計 4 色 | [`project_solara_design_philosophy`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_design_philosophy.md) の独立 2 エネルギーを色で表現。**赤=悪 / 緑=良 を絶対回避**。両方とも「正のエネルギー」 |
| **Frosted Glass** | `glassFill` (5% 白)、`glassBorder` (10% 白) | popup / panel の半透明境界 |
| **Elements** | `fire/water/air/earth` × `Start/End/Glow` 計 12 色 | 4 元素の gradient 用 |
| **Spiral** | `spiralLine`、`spiralDotActive/Inactive/Dim` | Galaxy スパイラル装飾 |
| **Planet (10 色)** | `planetSun`〜`planetPluto` | 10 惑星色。`planetColor('sun')` ヘルパーで文字列→Color |
| **Element (4 色)** | `elementWands/Cups/Swords/Pentacles` | Tarot 78 枚デッキ用。`elementColor('fire')` ヘルパーで文字列→Color (Wands ↔ fire マッピング) |
| **Moon event** | `fullMoonRing`、`newMoonCore` | 満月リング光・新月コア紫 |

**ヘルパー関数 2 本** (関数として export されている数少ない要素):
- `planetColor(String planet)` → 10 惑星色テーブル参照、未知文字列なら `solaraGold` フォールバック
- `elementColor(String element)` → 4 元素色テーブル参照、未知なら `textSecondary` フォールバック (`planetColor`/`elementColor` は Map 系・Observe 系・Galaxy 系 10 ファイルで使用)

### 3b.4 SolaraTheme の構造

`SolaraTheme.dark` (ThemeData) は以下を設定:

| プロパティ | 値 |
|---|---|
| `brightness` | `Brightness.dark` (全画面 dark mode 固定) |
| `scaffoldBackgroundColor` | `celestialBlueDark` (`0xFF080C14`) |
| `textTheme` | DM Sans (latin) + Noto Sans JP fallback、5 段階 (headlineLarge/Medium、bodyLarge/Medium、labelSmall) |
| `bottomNavigationBarTheme` | active=`F9D976` Gold、inactive=`rgba(255,255,255,0.35)`、label fontSize 9 + letterSpacing 0.5 (HTML 一致) |
| `colorScheme` | primary=`solaraGold`、surface=`celestialBlueDark`、onSurface=`textPrimary` |

**日本語フォールバック規約**: Latin は DM Sans、それ以外 (日本語) は Noto Sans JP。`TextTheme.apply(fontFamilyFallback: [japaneseFallback])` で 5 段階全てに伝搬。個別の Text/RichText で `fontFamily` を明示しても日本語文字は自動で Noto Sans JP に切替。

### 3b.5 機械分類の精度 + 課金検討に直結する示唆

1. **層 3b は機械分類どおり「ほぼ全画面が依存する基礎」**
   - `solara_colors.dart` は 19 ファイルから 143 回参照。グローバル定数ファイルとして適切な位置にある
   - `solara_theme.dart` は main.dart 1 箇所からの参照だが、`ThemeData` 経由で全 Widget に行き渡る

2. **Pro 機能の境界とは独立 = 「無料公開層」**
   - 色とテーマは Free/Pro 共通の UI 基盤
   - **Pro バッジ専用色** (例: `proGold`, `proGlow`) を本ファイルに追加するなら本層が自然な置き場所
   - 同様に「Pro 限定演出のアクセント色」も `solara_colors.dart` に集中させると保守が楽

3. **🔴 Soft/Hard 2 エネルギー色は譲れない世界観 — 課金訴求にも使える**
   - 「赤=悪 緑=良」回避の独自設計 ([`project_solara_design_philosophy`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_design_philosophy.md))
   - ストア説明文や Pro 訴求文に「両面評価 — 銀月色と金陽色の独立 2 エネルギー」と書くと既存占いアプリ群との差別化軸として効く
   - 色定数で表現されているので、Marketing 素材 (LP、ストア screenshot) で同じ色を使えば一貫性出る

4. **`SolaraTheme.dark` のみで `light` テーマは未実装**
   - 全画面 dark mode 固定 = アプリの世界観 (= 夜空、星座、月相)
   - **Pro 機能で `light` テーマ追加は世界観と齟齬** = 推奨しない
   - 代わりに「Pro 限定: シーズン別アクセント (Spring/Autumn/Winter)」のような派生 dark テーマなら拡張可能

5. **i18n フェーズで `Noto Sans JP fallback` の追加検討**
   - EN リリース時、英語 latin は DM Sans のみで完結する
   - 中国語・韓国語など他言語展開時は本ファイルに `Noto Sans SC/KR` fallback 追加が必要
   - ただし [`feedback_i18n_last`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_i18n_last.md) の規約で、i18n は公開直前まで保留

6. **`bottomNavigationBarTheme` 設定は実質未使用**
   - 現状の bottom NavBar は層 3a `SolaraNavBar` (カスタム widget) で描画していて、Material の `BottomNavigationBar` は使っていない
   - `ThemeData.bottomNavigationBarTheme` 設定は HTML 一致目的で残しているが、実用上は dead 設定
   - **削除しても害なし**だが、将来 Material BottomNavigationBar を使う可能性があれば残置可

### 3b.6 機械抽出への参照

層 3b の機械抽出 raw: [`feature_inventory/03b_theme.md`](feature_inventory/03b_theme.md)

---

## 層 3c: 演出ウィジェット (animated)

### 3c.1 概要

`lib/widgets/` 配下、**`AnimationController` を持つ** 5 ファイル / 計 2,160 行。
全画面 overlay として「**特定の瞬間にだけ被さる演出 widget**」を担う。本層には 2 系統が共存:

| 系統 | 用途 | 出現条件 | ファイル |
|---|---|---|---|
| **Map fortune 演出** | 今日の最高スコアカテゴリに応じた全画面演出 | Map 画面で 1 日の最初のタップ時 (4 秒間) | `dominant_fortune_overlay.dart` |
| **Galaxy moon 演出** | サイクル節目 (新月/満月/刻星化) の体験画面 | Galaxy 画面で月相が新月/満月/刻星化日に当たる時 | `new_moon_overlay.dart`, `full_moon_overlay.dart`, `catasterism_overlay.dart`, `catasterism_formation_overlay.dart` |

層 3a の moon overlay 共通部品 ([`moon_overlay_shared.dart`](../lib/widgets/moon_overlay_shared.dart)) と層 3a の 5 fortune painter (`fortune_overlays/*`) を **本層 5 widget が AnimationController + StatefulWidget でラップ駆動** している関係。

### 3c.2 ファイル別 役割 + AnimationController 数 + 呼出元 (5 本)

| # | ファイル | 行 | AnimCtrl 数 | 主要 export | 呼出元 | 性質 |
|---|---|---|---|---|---|---|
| 1 | [`dominant_fortune_overlay.dart`](../lib/widgets/dominant_fortune_overlay.dart) | 85 | **1** (4 秒) | `DominantFortuneKind` enum (love/money/healing/communication/work)、`DominantFortuneOverlay`、`kindFromKey` | [map_screen.dart](../lib/screens/map_screen.dart) (`_activeOverlay` で表示制御 + `_debugCycleOrder` で 5 種循環テスト) + 補助で [map_menu_chips](../lib/screens/map/map_menu_chips.dart), [map_daily_transit_screen](../lib/screens/map/map_daily_transit_screen.dart), [category_icon](../lib/widgets/category_icon.dart) (enum import のみ) | 層 3a `fortune_overlays/*` 5 painter のディスパッチャ。`_createBuilder(kind)` で 5 種 builder を切替、`AnimationController` の値を `CustomPaint` に渡す。`IgnorePointer` で gesture 透過。完了で `onComplete` callback (= 通常 4s) |
| 2 | [`new_moon_overlay.dart`](../lib/widgets/new_moon_overlay.dart) | 564 | **6** (fade/page/reveal/message/events/action) | `NewMoonOverlay` (`month`, `cycleId`, `onDismiss`, `onIntentionSet` 引数) | [galaxy_screen](../lib/screens/galaxy_screen.dart) (月相が新月日に当たる時) + 再 export 経由 [moon_overlay.dart](../lib/widgets/moon_overlay.dart) | **3 フェーズ** (物語 → 4 択選択 → 詩的リビール)。`LunarIntention` を `SolaraStorage.setLunarIntention` で永続化、`CelestialEvents.fetchCycleEvents` で当該サイクル天体イベントも取得 |
| 3 | [`full_moon_overlay.dart`](../lib/widgets/full_moon_overlay.dart) | 481 | **4** (fade/page/reveal/message) + `Timer` 自動クローズ | `FullMoonOverlay` (`intention`, `month`, `onDismiss` 引数) | [galaxy_screen](../lib/screens/galaxy_screen.dart) (月相が満月日に当たる時) + 再 export 経由 | **3 フェーズ** (物語 → 3 段階評価 → 詩的リビール → 3 秒余韻で自動確定)。新月で設定した `intention.choice` の中間チェック (🌊 まだ取り組み中 / ✨ 進展あり / 🌟 軽くなった) を `SolaraStorage.setMidpointCheck` で永続化 |
| 4 | [`catasterism_overlay.dart`](../lib/widgets/catasterism_overlay.dart) | 445 | **4** (fade/page/exit/glow) | `CatasterismOverlay` (`intention`, `totalDays`, `onDismiss`, `onResult?` 引数) | [galaxy_screen](../lib/screens/galaxy_screen.dart) (新月前日 = サイクル終端日) + 再 export 経由 | **3 フェーズ** (物語 → 2 択選択 → グロウパルス → フェードアウト)。「手放せた / まだ途中」の 2 値判定を `_glowCtl` で発光演出 + 600ms forward + 100ms peak + 600ms reverse で表現。次画面 `CatasterismFormationOverlay` への切替トリガを発火 |
| 5 | [`catasterism_formation_overlay.dart`](../lib/widgets/catasterism_formation_overlay.dart) | 585 | **2** (main 8 秒 / fade 1ms 値 1.0) + `_FormationPainter` CustomPainter | `CatasterismFormationOverlay` (`cycle`, `artImage?`, `onComplete` 引数)、`_FormationPainter` | [galaxy_screen](../lib/screens/galaxy_screen.dart) (catasterism_overlay の完了直後) | **🌟 8 秒 4 ステージ演出** (`SPEC.md` 準拠): CONVERGENCE 0-2s 集来 / IGNITION 2-3s 点灯 / LINKING 3-5s 連結 / COMPLETE 5-8s 完成。12 星座シンボル (`assets/zodiac-symbols/*.webp`) + 背景 (`assets/catasterism_bg.webp`) を preload、`GalaxyCycle` の MST edges を漸進描画 |

### 3c.3 共通設計パターン (4 系 moon/catasterism overlay)

`new_moon` / `full_moon` / `catasterism` 3 widget は **同形のフェーズ構造** を持ち、層 3a [`moon_overlay_shared.dart`](../lib/widgets/moon_overlay_shared.dart) の共通部品で集約済 (2026-05-06 audit T2/T7):

| 段階 | 内容 | 使用部品 |
|---|---|---|
| 物語 | 縦スクロール詩的テキスト (30 px/s 自動 + 手動で中断可) | `MoonScrollingStory` (3a) |
| 遷移 | 中点 (`_pageCtl.value >= 0.5`) で `_showStory=false` クロスフェード | `moonOverlayPageStructure` (3a) |
| 選択 | カード列タップ (new_moon=4 択 / full_moon=3 段階 / catasterism=2 値) | `moonOverlaySelectableCard` (3a) |
| 幾何測定 | `GlobalKey` から `localToGlobal` + size 取得 | `measureMoonOverlayTapGeometry` (3a) |
| リビール | 詩的メッセージ fadeIn | `revealPoeticMessage` (3a) |
| 永続化 | `LunarIntention` / `MidpointCheck` / `CatasterismResult` モデル (層 1c) | `SolaraStorage.*` (層 2b) |

**= 4 系 overlay の保守性が高い** 構造。新規 overlay 追加 (例: Pro 限定「半月チェック」) も本パターンに従えば既存部品で 80% 賄える。

### 3c.4 機械分類の精度 + 課金検討に直結する示唆

1. **`DominantFortuneOverlay` は層 3a の 5 painter 駆動主**
   - 機械分類は `AnimationController` 有無で正しく 3c
   - 実装上は 85 行と最も薄いが、3a 5 painter (3,212 行) を起動するキーストーン
   - **Pro 拡張案**: 演出を「毎回再生」設定 (Free は 1 日 1 回固定) は本ファイルの `onComplete` トリガを `map_screen` 側で制御変更すれば実装可

2. **🔴 Galaxy moon 演出 4 種 = Solara の最大差別化体験**
   - 「占いをしない、節目で自己と対話する」体験 ([`project_solara_design_philosophy`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_design_philosophy.md)) を体現
   - 新月で意図を立てる → 満月で中間チェック → 刻星化 (新月前日) で完了判定 → 形成演出 (星座) の 4 段サイクル
   - **無料機能の心臓部** = Pro 化対象としては不適切 (これを Pro 化すると Solara の独自性が見えなくなる)
   - 代わりに「過去サイクルアルバム」「履歴の検索」「カスタム背景画像」が Pro 拡張案 ([`project_galaxy_spec`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_galaxy_spec.md))

3. **`CatasterismFormationOverlay` の 8 秒演出は最も重い**
   - 12 星座シンボル + 背景画像を preload、`AnimationController` 60fps で 8s = 480 frame 描画
   - `_FormationPainter` (252 行) の `paint` 関数が重い可能性 ([`todo_solara_perf_audit`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/todo_solara_perf_audit.md))
   - **「サイクル完了の最大ご褒美」演出**として演出投資に値する重み
   - Pro 拡張案: 「形成演出を任意のタイミングで再生 (履歴アルバム)」

4. **3 系 moon overlay の AnimationController 数 (6+4+4) = メモリ・GPU 負荷**
   - `dispose()` 漏れがあれば fd 枯渇等の致命傷 ([`feedback_http_fd_leak`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_http_fd_leak.md) / [`project_solara_a101fc_fd_leak`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_a101fc_fd_leak.md))
   - 各 widget の `dispose()` で全 controller 解放を確認済 (本セッション読み合わせで確認、漏れなし)
   - Pro 拡張で AnimationController を増やす場合は dispose 必須

5. **永続化が層 2b `solara_storage.dart` に集中**
   - new_moon: `setLunarIntention`, `setNotTodayCount`
   - full_moon: `setMidpointCheck`
   - catasterism: `setCatasterismResult`
   - **クラウドバックアップ Pro** ([`solara_storage.dart`](../lib/utils/solara_storage.dart) で議論) のバックアップ対象としてこれらが最優先候補

6. **`DominantFortuneOverlay` の `kindFromKey` 関数は柔軟性源**
   - 文字列 → enum 変換ヘルパー、外部入力 (例: notification payload) からの起動を想定
   - **Pro 公開時の deep link 対応**: 「Pro 限定 push 通知から特定 overlay 起動」は本関数で実装容易

### 3c.5 機械抽出への参照

層 3c の機械抽出 raw: [`feature_inventory/03c_widgets_anim.md`](feature_inventory/03c_widgets_anim.md)

---

## 層 4a: Map 画面

### 4a.1 概要

`lib/screens/map/` 配下 + `lib/screens/map_screen.dart` の **22 ファイル / 計 12,283 行** (オーバーライド適用後)。Solara で**最大規模の画面**であり、**Pro 機能の核が最も集中する層**。

**機械分類の精度** (✅ 2026-05-14 オーバーライド適用済): 当初は 25 ファイル / 13,926 行だったが、`PATH_OVERRIDES` で 3 本を他層に明示移動:
- `map_astro.dart` (508) → 層 2a (`/astro/chart` ラッパ、Map+Horo 共用)
- `map_constants.dart` (122) → 層 3b (HTML 一致純定数)
- `daily_transit_data.dart` (1,013) → 層 1b (静的テキスト辞書)

Map 画面は単に「地図を表示する」だけでなく、以下の機能を全部内包する複合体:

| 機能領域 | 概要 |
|---|---|
| 地図描画 | 4 種タイル切替 (OSM hot/standard/cyclosm Light/Dark)、ズーム制御、タイル fd 制御 |
| 16 方位スコア計算 | `/astro/chart` から取った出生図 + 拠点 + 時刻で 16 方位 × 5 カテゴリ Soft/Hard スコアを計算 |
| アスペクトラインオーバーレイ | 4 frame (natal/transit/progressed/solarArc) × 40 本コンジャンクションライン (= ACG モード) |
| Daily Transit (F1-c) | 「今日の動き」= 10 惑星 × 4 アングル (ASC/MC/DSC/IC) 通過時刻 + natal アスペクト併記 |
| 検索 + 拠点管理 | Google Places 検索 → スコア注入 → 候補から拠点保存 (`VPSlot`)、独立 `📍 地点メニュー` |
| 詳細 popup 群 | 方角タップ / 惑星マーカータップ / 引越し popup / ACG ライン popup |
| 時間操作 | ±365 日 + 時分のタイムスライダー、LIVE ボタン |

**Pro 公開時の最大対象 = `/fortune` (Gemini) + `/relocation` (Gemini) を呼ぶラッパが本層内に複数あり**。

### 4a.2 機能群別ファイル分類 (22 本)

22 ファイルを 10 群に整理 (旧 A は全削除、旧 J は 2 本に減):

| 群 | 役割 | 数 | 行 |
|---|---|---|---|
| ~~A~~ | ~~計算データ + 描画定数~~ — オーバーライドで層 2a/3b へ移動 | 0 | 0 |
| B UI 基礎部品 | 円形ボタン、Legend、タイル選択、扇状セクター | 3 | 376 |
| C HUD オーバーレイ | 左サイド 3 ボタン、検索バー、選択日バッジ、VP Pin、下部チップバー、時刻スライダー | 3 | 1,261 |
| D 検索系 | Google Places 検索 + 結果リスト + フォーカス popup + スコア注入 | 1 | 590 |
| E アスペクトライン + ACG | 4 frame × 40 本ライン + 天頂/天底マーカー + ACG モード UI | 3 | 1,686 |
| F マーカー + ロケーション | 出生地/スロットマーカー + VP Slot 永続化 + 📍 地点メニュー | 3 | 1,061 |
| G 表示メニュー | ☰ 表示ボタン展開、L1/L2 タブ、4 frame ON/OFF | 1 | 410 |
| H 詳細 popup | 方角 / 惑星 / 引越し / ACG ライン 4 種 | 4 | 1,409 |
| I 運勢シート | カテゴリスコア表示 + sources × categories グリッド | 1 | 775 |
| J Daily Transit (別画面) | F1-c タイムライン + アスペクトチップ (daily_transit_data は 1b に移動) | 2 | 2,020 |
| K 統合ハブ | map_screen.dart (56 関数、本層 22 ファイル + 他層 ラッパを統合) | 1 | 2,695 |

### 4a.3 群 A: 計算データ + 描画定数 (オーバーライド済、0 本)

旧群 A の 2 ファイルは ✅ 2026-05-14 オーバーライドで他層に明示移動済:
- `map_astro.dart` (508 行) → 層 2a (`/astro/chart` ラッパ + scoreAll、Map+Horo 共用) — 詳細は [`2a.2 表`](#2a.2) 行 7
- `map_constants.dart` (122 行) → 層 3b (HTML `CHART_STYLE` + `PlanetMeta` 純定数) — 詳細は [`3b.2 表`](#3b.2) 行 3

これにより本層 4a は「真の Map 画面 UI のみ」を保持する状態に整理された。

### 4a.4 群 B: UI 基礎部品 (3 本、376 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`map_widgets.dart`](../lib/screens/map/map_widgets.dart) | 51 | `MapBtn`、`LegendDot` | 円形ボタン (search/layer/vp) + Legend ドット。HTML `.search-trigger / .layer-btn / .vp-btn` 一致 |
| [`map_styles.dart`](../lib/screens/map/map_styles.dart) | 152 | `MapStyle` enum、`MapStyleConfig`、`mapStyleFromId`、`buildStyledTileLayer` | **🔴 タイル 4 種切替** ([`project_solara_map_styles`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_map_styles.md))。`/tiles/osm/hot/*` の Worker 経由 + `sharedTileHttpClient` 使用 ([`feedback_http_fd_leak`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_http_fd_leak.md) 対策) |
| [`map_sectors.dart`](../lib/screens/map/map_sectors.dart) | 173 | `buildSectors`、`buildCompass`、`buildDirLabels` | **16 方位扇状セクター + 8 方向コンパス + 方位ラベル** ([`project_solara_geo_sector`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_geo_sector.md))。`activeCategory` の色 1 色 + alpha のみ可変、red/green 吉凶塗りは禁止 |

### 4a.5 群 C: HUD オーバーレイ (3 本、1,261 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`map_overlays.dart`](../lib/screens/map/map_overlays.dart) | 481 | `MapSideButtons`、`SearchBarOverlay`、`SearchVpChipRow`、`SelectedDateBadge`、`StatusBadge`、`VpPinVisual`、`RestOverlay`、`buildVpPinMarker`、`showSolaraDatePicker` | Map の HUD 集 9 種。左サイド 3 ボタン (🔍 検索 / ☰ 表示 / 📍 地点) は 2026-05-09 第二弾で配置確定 |
| [`map_menu_chips.dart`](../lib/screens/map/map_menu_chips.dart) | 307 | `MapMenuChips`、`_StaticChip`、`_DailyTransitChip`、`_ChipHalo` | **下部 4 チップ** (Daily / Fortune / Locations / Forecast)。Daily Transit チップは未開封状態判定あり (`_DailyTransitChip`) |
| [`map_time_slider.dart`](../lib/screens/map/map_time_slider.dart) | 473 | `MapTimeSlider` (Stateful) + public `MapTimeSliderState.closeTimeRow` | **タイムスライダー** ±365 日 (1 日刻み) + 時分 (10 分 grid step、表示は実分、`_displayMinuteJst` / `_committedMinuteJst` 分離 = 2026-05-12 Daily Transit 拡張)。LIVE ボタンで今日復帰。PopScope から `closeTimeRow` を呼ばれる |

### 4a.6 群 D: 検索系 (1 本、590 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`map_search.dart`](../lib/screens/map/map_search.dart) | 590 | `SearchHit`、`SearchResultList`、`SearchFocusPopup`、`directionFrom`、`distanceKmFrom`、`annotateHitsWithScores` | **🔴 Worker `/search` 呼出** (Google Places primary + Nominatim fallback)。検索結果に「現在中心からの方位スコア + 支配カテゴリ」を `annotateHitsWithScores` で注入してから表示。`SearchFocusPopup` で VIEWPOINT / LOCATION 個別登録ボタン |

### 4a.7 群 E: アスペクトライン + ACG モード (3 本、1,686 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`map_planet_lines.dart`](../lib/screens/map/map_planet_lines.dart) | 285 | `PlanetLineData`、`PlanetSymbolsLayer`、`buildPlanetLineData`、`buildPlanetPolylines` | 10 惑星の MC ライン (経度線) 計算 + 描画。`PlanetSymbolsLayer` は HTML `updateSymPos` の edge tracking 再現 (惑星シンボルが画面端で追従) |
| [`map_astro_lines.dart`](../lib/screens/map/map_astro_lines.dart) | 588 | `AstroFrameStyle`、`astroFrameStyles`、`AstroNadirMarker`、`AstroZenithMarker`、`buildAstroPolylines`、`buildAstroLatitudeBandPolylines`、`buildAstroZenithMarkers`、`buildAstroNadirMarkers` | **4 frame style 定義** (Natal=ゴールド、Transit=オレンジ、Prog=緑、SArc=紫) + アスペクトライン → Polyline 変換 + 天頂帯/天底帯 (latitude band) 描画 + 装飾マーカー (Lewis 理論天頂/天底点) |
| [`map_astro_carto.dart`](../lib/screens/map/map_astro_carto.dart) | 813 | `AstroCartoBanner`、`AcgFrameDef`、`AstroCartoFramePills`、`AstroCartoSubPills`、`_FramePill`、`_SubPill`、`_ScrollableRowPanel`、`AstroCartoCategoryPills`、`AstroZenithPopup` | **🔴 ACG (A*C*G) モード UI**。第 1 層 4 frame ピル + 第 2 層 sub ピル (天頂/天底/天頂帯/天底帯) + カテゴリピル + 天頂点詳細 popup。Astrocarto モードは Solara の海外市場向け売り ([`project_solara_astrocartography_m2`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_astrocartography_m2.md), [`project_solara_lewis_full_impl_plan`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_lewis_full_impl_plan.md)) |

### 4a.8 群 F: マーカー + ロケーション (3 本、1,061 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`map_location_markers.dart`](../lib/screens/map/map_location_markers.dart) | 295 | `BirthMarker`、`SlotMarker`、`LocationMarkerPopup`、`buildLocationMarkers`、`slotMarker` | 出生地 🌟 (多層グロー) + VP / Locations スロットマーカー + タップ詳細 bottom sheet |
| [`map_vp_panel.dart`](../lib/screens/map/map_vp_panel.dart) | 120 | `VPSlot`、`SlotManager` (singleton 的) | **🔴 VP スロット永続化**。HTML `SlotManager` の Dart 移植 + `syncHome` (プロフィール home を先頭スロットに同期) + `saveCurrentLocation` (reverse geocoding で地名取得) |
| [`map_viewpoint_menu.dart`](../lib/screens/map/map_viewpoint_menu.dart) | 646 | `MapViewpointMenu` (Stateful) | 📍 地点ボタン展開メニュー (2026-05-09 第三弾)。スロット一覧 + 保存 + リネーム + アイコン変更 + 並べ替え + 削除 |

### 4a.9 群 G: 表示メニュー (1 本、410 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`map_display_menu.dart`](../lib/screens/map/map_display_menu.dart) | 410 | `MapDisplayMenu` (Stateful)、`_MainTab` / `_PlanetSub` enum、`_MenuInfoRow`、`_ChipButton` | **☰ 表示メニュー** (2026-05-09 確定)。L1 タブ (Map/Planet/Astro) × L2 ボタン群 (16 方位/コンパス/MAPSTYLE / 惑星選択 / 4 frame ON/OFF / aspectAll / CHART / FORTUNE)。i ボタン付きで各カテゴリ説明 popup |

### 4a.10 群 H: 詳細 popup (4 本、1,409 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`map_direction_popup.dart`](../lib/screens/map/map_direction_popup.dart) | 374 | `showDirectionEnergyPopup`、`_PopupBody`、`_EnergyBar`、`_ContribRow` | **🔴 方角タップ詳細 popup**。Soft / Hard 独立 2 バー + 主要寄与アスペクト attribution ([`project_solara_design_philosophy`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_design_philosophy.md) 中核実装、吉凶判定なし) |
| [`map_planet_intro_popup.dart`](../lib/screens/map/map_planet_intro_popup.dart) | 239 | `showPlanetIntroPopup`、`_PlanetIntroBody` | 惑星マーカータップ説明 (層 1a `planet_intro.dart` 辞書 = 10 惑星 × 3 frame の説明テキスト) |
| [`map_relocation_popup.dart`](../lib/screens/map/map_relocation_popup.dart) | 564 | `MapRelocationPopup` | **🔴 引越し popup** (Phase M0 完成、[`project_solara_relocation_m0`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_relocation_m0.md))。Dart 完結 (`astro_houses.dart` + `astro_lines.dart`)。出生地 → タップ地点の ASC/MC + 12 ハウス + アスペクトライン詳細 |
| [`map_line_narrative_sheet.dart`](../lib/screens/map/map_line_narrative_sheet.dart) | 232 | `MapLineNarrativeSheet`、`showLineNarrativeSheet` | ACG ライン (natal/transit) タップ詳細。**Gemini AI 解説は 2026-05-11 撤去**、静的辞書 (`aspect_lines`、`transit_acg`) ベースに統一 ([`project_solara_v7_integration`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_v7_integration.md)) |

### 4a.11 群 I: 運勢シート (1 本、775 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`map_fortune_sheet.dart`](../lib/screens/map/map_fortune_sheet.dart) | 775 | `FortuneFilterLabel`、`FortuneSheet`、`pctValue`、`showCategoryInfoPopup`、`_FortuneRowsList` (Stateful) | **下部運勢シート** = カテゴリスコアの sources × categories グリッド。`RawScrollbar` + `ListView` で `ScrollController` 共有。`showCategoryInfoPopup` で Map の使い方 + カテゴリ × 関連惑星ペアの説明 |

### 4a.12 群 J: Daily Transit (別画面、2 本、2,020 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`map_daily_transit_screen.dart`](../lib/screens/map/map_daily_transit_screen.dart) | 1,799 | `MapDailyTransitScreen` (Stateful) + 14 内部 widget (タブバー / ヘッダ / カテゴリ tips / タイムライン本体 / 行 / 高度バッジ / 緯度帯ボックス…)、`showDailyUsageGuidePopup` | **🔴 F1-c フル UI** (2026-04-29 オーナー設計)。10 惑星 × 4 アングル (ASC/MC/DSC/IC) のタイムライン + 各行 🗺 ジャンプ + 「今日の TOP」カテゴリ表示 + L3 Lewis 高度バッジ / 緯度帯。**HARD ファイル分割対象**だが pre-existing |
| [`map_aspect_chip.dart`](../lib/screens/map/map_aspect_chip.dart) | 221 | `MapAspectChip` | Daily Transit 行内の compact アスペクトチップ。soft=銀月色 / hard=金陽色 / tense=金陽色 / neutral=金色。タップで Horo 相タブ相当の詳細解説 popup |

(旧 `daily_transit_data.dart` 1,013 行は ✅ オーバーライドで層 1b に移動済 — 詳細は [`1b.2 表`](#1b.2) 行 9)

### 4a.13 群 K: 統合ハブ (1 本、2,695 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`map_screen.dart`](../lib/screens/map_screen.dart) | 2,695 | `MapScreen` (Stateful)、`MapScreenState` (public state, GlobalKey 経由 `reloadProfile` 公開) | **🔴 Map 統合ハブ**。56 関数 (public 8 + private 48)。30 ファイル import (Map 内 25 + utils 5 + screens 3)。Daily Transit / Forecast / Locations から呼ばれる onClose / onJumpToTime / onJumpToDate コールバックも全て本ファイルで配線。**HARD ファイル分割対象** (pre-existing、別タスク) |

主要な `_*` 関数群:
- ライフサイクル: `_bootstrap`, `_warmupTileConnection`, `_onTileError`, `_loadMapStyle`, `_loadProfileAndChart`, `_moveToInitialCenter`
- 検索: `_doSearch`, `_frameSearchArea`, `_restoreSearchListView`, `_selectSearchHit`, `_buildFocusedHitMarker`, `_buildSearchHitMarkers`, `_reannotateSearchResults`, `_clearAllSearch`
- スコア表示: `_displayScores`, `_sectorRankAlphaMul`, `_cycleActiveCategory`
- ACG モード: `_enterAstroCartoMode`, `_exitAstroCartoMode`, `_filteredFrames`, `_visibleAstroLines`, `_zenith/nadirMarkerFrames`, `_zenith/nadirBandFrames`
- 描画再構築: `_rebuild`, `_kickPaintInvalidation` (= [`project_solara_map_paint_invalidation`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_map_paint_invalidation.md) 必須対策)
- popup ヘルパー: `_buildZenithPopup`, `_buildRelocationPopup`, `_buildNoProfileGuide`, `_showSearchVpHelpPopup`
- メニュー連携: `_onDisplayMenuTap`, `_onViewpointMenuTap`, `_onSearchTap`, `_onDailyBadgeTap`, `_onOverlayComplete`, `_onDailyTransitClose`
- VP / 拠点: `_setVpOnly`, `_setVpToCurrentLocationOnly`, `_reloadLocationSlots`, `_findNearbyAstroLines`, `_geolocate`

### 4a.14 Worker / 外部呼出 (5 endpoint)

| endpoint | ファイル | 用途 |
|---|---|---|
| `/astro/chart` | [`screens/map/map_astro.dart:17`](../lib/screens/map/map_astro.dart) (2a オーバーライド済) | natal+transit+progressed+ASC/MC/DSC/IC + 全アスペクト計算 |
| `/search` | [`map_search.dart:11`](../lib/screens/map/map_search.dart) | Google Places primary + Nominatim fallback |
| `/tiles/osm/hot/*` | [`map_styles.dart:60,69`](../lib/screens/map/map_styles.dart) (2 リテラル — `osmHot` Light/Dark で別 URL) | OSM Worker 中継タイル (`/tiles/osm/hot/{z}/{x}/{y}.png`) |
| `/tiles/osm/hot/0/0/0.png` | [`map_screen.dart:368`](../lib/screens/map_screen.dart) | `_warmupTileConnection` で起動時 1 枚 prefetch |

**`/fortune` (Gemini) は本層では呼ばない** — Map から触れるのは Forecast / Horoscope 経由のみ。本層の Worker 呼出は天体計算 + 検索 + タイルの 3 種で全部 ([`project_solara_security_principles`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_security_principles.md) の `/public/*` 配下想定)。

### 4a.15 機械分類の盲点 + 重要な実態 (✅ オーバーライド適用済)

1. ~~**`screens/map/map_astro.dart` は実態が層 2a**~~ — ✅ 2026-05-14 `PATH_OVERRIDES` で 2a に明示移動済。物理 path は `screens/map/` 配下のまま、リファクタ時に `lib/utils/astro_chart_api.dart` へ移すと自然
2. ~~**`map_constants.dart` は実態が層 3b 寄り**~~ — ✅ 同オーバーライドで 3b に明示移動済
3. **`map_screen.dart` 2,695 行 + `map_daily_transit_screen.dart` 1,799 行は HARD 違反** (`code_audit/audit.py` の 500 行閾値超過) — pre-existing で別タスク
4. ~~**`daily_transit_data.dart` 1,013 行は静的テキスト辞書、実態は層 1b 寄り**~~ — ✅ 同オーバーライドで 1b に明示移動済
5. **Stella 枠は撤去済** ([`project_solara_stella_revival`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_stella_revival.md)) — `map_overlays.dart` の `RestOverlay` のみ残置。常駐再追加禁止

### 4a.16 重要な仕様メモリへの参照 (確定仕様は HTML が正)

Map 関連の確定仕様 / 注意点 / 過去教訓を保持するメモリ:

| メモリ | 内容 |
|---|---|
| [`project_solara_geo_sector`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_geo_sector.md) | やってはいけないこと・廃止済み仕組み (16 方位扇状セクター、red/green 吉凶塗り禁止) |
| [`project_solara_map_render_protocol`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_map_render_protocol.md) | **🔴 Map 描画エラー対処プロトコル**。タイル抜け/未表示の対応、公式機構、アンチパターン |
| [`project_solara_map_nan_red_screen`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_map_nan_red_screen.md) | **🔴 Map ズームアウト時の赤画面 (LatLng NaN) 対策** 3 層防御 (minZoom 2.5 + cameraConstraint + onPositionChanged 検知) |
| [`project_solara_map_paint_invalidation`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_map_paint_invalidation.md) | **🔴 Map 黒画面対策**。5 層目 `_kickPaintInvalidation` (新規 `_mapCtrl.move` には必ずペアで呼ぶ、撤回禁止) |
| [`project_solara_map_styles`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_map_styles.md) | マップタイル 4 種切替実装済 + 将来 MapTiler 独自紫夜空テーマ計画 |
| [`project_solara_a101fc_fd_leak`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_a101fc_fd_leak.md) | 🟢 A101FC fd 枯渇問題は 2026-05-06 Impeller ON で完全解消 |
| [`project_solara_lewis_full_impl_plan`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_lewis_full_impl_plan.md) | ACG/CCG Lewis 理論完全実装ロードマップ 6 フェーズ、合計 26-34h |
| [`project_solara_astrocartography_m2`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_astrocartography_m2.md) | Phase M2 真のアストロカートグラフィー設計 (議論スターター) |
| [`project_solara_relocation_m0`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_relocation_m0.md) | Phase M0 リロケーション + Phase A 静的解説完成状態 |
| [`feedback_forecast_map_separate`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_forecast_map_separate.md) | FORECAST と Map スコアは別計算、Map ジャンプリンク追加しない |
| [`project_solara_i18n_score_bar_labels`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_i18n_score_bar_labels.md) | i18n フェーズで Map スコアバー srcLabels/categoryLabels を英訳する確定案 (B 案) |

### 4a.17 課金検討に直結する示唆

層 4a は **Solara で Pro 機能が最も集中する層**。Map 全体が「無料で見える基盤 + Pro で深まる体験」の戦略の中心。

1. **🔴 Pro 機能の最有力候補ベスト 3 (本層 + 関連層から導出)**
   - **(a) アスペクトライン拡張 (40 → 120 本)** — 層 1a `astro_lines.dart` + 本層 `map_astro_lines.dart` を拡張。Worker コスト 0、クライアント完結。ハード 90° + ソフト 120°/60° 追加で 3 倍
   - **(b) Daily Transit (F1-c) 無制限拠点切替** — 現状 `_selectVp` で `vpSlot` 切替時に再 fetch。Free は home + 現在地 2 拠点制限、Pro は無制限スロット (`SlotManager.slots` 上限解除)
   - **(c) ACG モード 4 frame 同時表示 = Pro 限定** — 現状全員見えているが、Pro 化候補。`map_screen.dart._enterAstroCartoMode` で isPro チェック追加

2. **Gemini 呼出は本層に無いが、Forecast/Horoscope から本層に戻ってくる連携あり**
   - `_openForecast`, `_openLocations` で別画面遷移 → そこから `/fortune`, `/relocation` を呼ぶ
   - **Map 単体は `/public/*` で十分**、Pro ゲートは Forecast/Horoscope 側に置く

3. **タイル消費 = 月額コスト要因**
   - `/tiles/osm/hot/*` は edge cache 24h で抑えられるが、ヘビーユーザーは月数千 req
   - Free は標準 OSM のみ、Pro は MapTiler 独自紫夜空テーマ ([`project_solara_map_styles`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_map_styles.md) 将来計画) で差別化 = MapTiler 月額の Pro 課金で回収

4. **永続化 (`VPSlot` / `SlotManager`) はクラウドバックアップ Pro の中心 (Map 側)**
   - 拠点 (出生地 / 自宅 / 旅行先) は **ユーザーの最大の個人データ** = 引越し時の引き継ぎ需要
   - `solara_storage.dart` (層 2b) の `exportAll/importAll` 拡張時に本層の `SlotManager` も含める

5. **`map_screen.dart` 2,695 行 + 56 関数の HARD 違反は Pro 公開前に分割推奨**
   - 候補: ACG モード制御 (`_enterAstroCartoMode` 周辺) を `map_acg_controller.dart` へ
   - 候補: 検索系 (`_doSearch`, `_frameSearchArea`, `_restoreSearchListView`...) を `map_search_controller.dart` へ
   - 候補: build subtree (`_buildBody` 880 行) を分割
   - **緊急度低 (動作には影響なし)**、保守性向上の課金実装段階で着手

6. **Phase M2 残作業の Pro 化判断**
   - [`project_solara_lewis_full_impl_plan`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_lewis_full_impl_plan.md) の L1〜L6 のうち、L3 Lewis 緯度帯 + L4 オーブ塗り は実装済 (`map_astro_lines.dart` + Daily Transit `_LatitudeBandBox`)
   - 残作業 L5/L6 (惑星イベント深化 + オーブ深化) は **Pro 限定で追加**する選択肢あり
   - 「無料は基本 ACG、Pro は Lewis 完全実装 (オーブ塗り / 緯度帯重畳)」の差別化が成立

7. **`map_planet_lines.dart` の `PlanetSymbolsLayer` は HTML 移植が完了済 = 独自性源**
   - 惑星シンボル edge tracking (画面端で惑星が追従) は商用 ACG アプリでも珍しい実装
   - Pro 訴求文素材として価値

8. **検索 (`map_search.dart`) の `annotateHitsWithScores` は無料機能の差別化**
   - Google Places の検索結果に「現在中心からの方位スコア + 支配カテゴリ」を自動注入
   - 競合の地図アプリ + 占いアプリには無い体験 = 無料層の魅力強化に投資する箇所

### 4a.18 機械抽出への参照

層 4a の機械抽出 raw: [`feature_inventory/04a_map.md`](feature_inventory/04a_map.md)

---

## 層 4b: Horoscope 画面

### 4b.1 概要

`lib/screens/horoscope/` 配下 + `lib/screens/horoscope_screen.dart` の **22 ファイル / 計 5,257 行** (オーバーライド適用後)。Map (4a) と並ぶ大規模画面だが、規模は約 4 割 (Map = 13,926 行 vs Horo = 5,257 行)。

**機械分類の精度** (✅ 2026-05-14 オーバーライド適用済): 当初は 25 ファイル / 5,754 行だったが、`PATH_OVERRIDES` で 3 本を他層に明示移動:
- `horo_antique_icons.dart` (295) → 層 3a (16 ファイル横断のアンティークアイコン widget)
- `horo_constants.dart` (86) → 層 1b (signs/planetGlyphs/aspectSymbol/aspectTypes/fortunePlanets 等、13 ファイル横断)
- `horo_aspect_description.dart` (116) → 層 1b (planetInfo/aspectInfo 静的辞書 + `buildAspectDescription` 関数、Map+Horo 共用)

Horoscope の機能領域:

| 機能領域 | 概要 |
|---|---|
| 出生図表示 | 12 星座輪 + 10 惑星 + 4 アングル + アスペクト線描画 (HoroChartWheelPainter) |
| 占いカード生成 | Gemini `/fortune` 経由でカテゴリ別占い文を表示 (5 カテゴリ: 恋愛/豊かさ/仕事/対話/全体) |
| アスペクト一覧 + 解説 | 全アスペクトをリスト表示、タップで `buildAspectDescription` (1b) で解説生成 |
| パターン予測 | Grand Trine / T-Square / Yod の検出 (`detectPatterns`) + 未来予測 (`predictPatternCompletions`) |
| リロケーション | 出生地 → 現住所のチャートを Dart で再計算 + Phase A 静的テンプレ + Phase B Gemini `/relocation` |
| Transit / Progressed 切替 | 現在の星位を natal に重ねる、または進行宮を表示 |
| 出生情報編集 | 地名・日時・座標を直接入力 + reverse geocoding 連動 |

**Pro 公開時の最大対象**: `/fortune` と `/relocation` (Gemini) 呼出が本層に集中。Pro 化候補は **占いカード回数制限 + リロケーション無制限**。

### 4b.2 機能群別ファイル分類 (22 本)

22 ファイルを 8 機能群に整理:

| 群 | 役割 | 数 | 行 |
|---|---|---|---|
| A 統合ハブ | horoscope_screen.dart (24 関数、12 import) | 1 | 754 |
| B 画面分割 extension | `_HoroBackdrop` / `_HoroBottomSheet` / `_HoroChartView` (HoroscopeScreenState 拡張) | 3 | 529 |
| C チャート描画 | チャート輪 + 装飾リング + 惑星グリフ | 3 | 1,014 |
| D データ生成ロジック | `_HoroChartData` extension + pattern_logic 純関数 | 2 | 410 |
| E 共有 UI 部品 | 惑星アイコン / 星座アイコン / アスペクトチェック / 時分ドロップダウン / 情報行 / 解説セクション | 3 | 373 |
| F パネル群 | 出生情報 / リロケーション / 占いカード / パターン予測 / Transit / フィルタ / 惑星表 / アスペクト一覧 | 8 | 1,967 |
| G 静的データ (Horo 内部) | リロケーション解説テンプレ (Phase A) | 1 | 196 |
| H barrel | bottom_panels barrel (旧 1,282 行ファイル分割の互換) | 1 | 14 |

### 4b.3 群 A: 統合ハブ (1 本、754 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`horoscope_screen.dart`](../lib/screens/horoscope_screen.dart) | 754 | `HoroscopeScreen` (Stateful)、`HoroscopeScreenState` (public state、`wakeAnimations` / `pauseAnimations` / `loadProfile` を外部公開) | **Horoscope 統合ハブ**。24 関数 (public 7 + private 17)、12 import (Horo 内 7 + utils 4 + map_astro 1)。Map と同じ `/astro/chart` を `map_astro.dart` の `fetchChart` 経由で呼ぶ (= 層 2a で記述した Map+Horo 共用境界)。`pauseAnimations` で Anim + 寿命タイマー停止 = raster 0% (タブ離脱時の負荷低減) |

主要な `_*` 関数群:
- ライフサイクル: `_resetAnimLifeTimer`, `_stopAnimations`, `_startRotTimer`, `_syncRotationByMode`
- データ取得: `_currentCacheKey`, `_refreshCacheKey`, `_fetchRealChart` (map_astro の fetchChart を呼ぶ), `_loadFortunes` (fortune_api.dart の fortune fetch)
- 状態管理: `_applyWorkingProfile`, `_resetWorkingProfile`, `_profilesEqual`, `_onTransitUpdate`
- UI ヘルパー: `_planetHouse`, `_menuItem`, `_buildHouseModeToggle`, `_toggleSegment`, `_setRelocateMode`

### 4b.4 群 B: 画面分割 extension (3 本、529 行)

`HoroscopeScreenState` を Dart の `extension` 構文で 3 ファイルに分割。各 extension は同じ State インスタンスにアクセスする (analyzer 抑制コメント `invalid_use_of_protected_member` 付き)。

| ファイル | 行 | extension | 役割 |
|---|---|---|---|
| [`horo_backdrop.dart`](../lib/screens/horoscope/horo_backdrop.dart) | 114 | `_HoroBackdrop` | 神秘的背景 (`_mysticalBackdrop`) + プロフィール未設定ガイド (`_buildNoProfile`) |
| [`horo_bottom_sheet.dart`](../lib/screens/horoscope/horo_bottom_sheet.dart) | 224 | `_HoroBottomSheet` | bottom sheet 高さ算出 + タブ切替 + content build (Aspect/Pattern/Transit/Relocate 4 タブ) |
| [`horo_chart_view.dart`](../lib/screens/horoscope/horo_chart_view.dart) | 191 | `_HoroChartView` | 12 星座画像配置 + チャート横スクロール (ピンチズーム) + レジェンド |

### 4b.5 群 C: チャート描画 (3 本、1,014 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`horo_chart_painter.dart`](../lib/screens/horoscope/horo_chart_painter.dart) | 702 | `HoroChartWheelPainter`、`HoroLegendItem`、`_SpreadItem` | **🔴 Horoscope のメイン描画**。12 星座輪 + 10 惑星配置 + 4 アングル + アスペクト線 + ハウス分割。`_spreadOverlappingPlanets` で密集惑星の自動スプレッド (重なり回避)、`_drawVectorGlyph` でベクター惑星グリフ描画 |
| [`horo_ornament_painter.dart`](../lib/screens/horoscope/horo_ornament_painter.dart) | 139 | `HoroOrnamentPainter` | チャート外周の装飾リング + 6 芒星マーカー + 内側ハロ |
| [`horo_astro_glyphs.dart`](../lib/screens/horoscope/horo_astro_glyphs.dart) | 173 | `planetGlyph(String key)` + 10 惑星 private path builder | 10 惑星のベクター Path (`_sun`〜`_pluto`)。チャート描画と panel_shared から使用 |

### 4b.6 群 D: データ生成ロジック (2 本、410 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`horo_chart_data.dart`](../lib/screens/horoscope/horo_chart_data.dart) | 214 | `_HoroChartData` extension | モックチャート生成 + transit/progressed 惑星算出 + アスペクト再計算 (`_recalcAspects`、`_addAspect`、`_approxSunLon`、`_aspectPassesFilter`) |
| [`horo_pattern_logic.dart`](../lib/screens/horoscope/horo_pattern_logic.dart) | 196 | `hasPersonal`、`enoughNatal`、`triKey`、`mockLon` | パターン検出ロジックの純関数。Grand Trine / T-Square / Yod の検出 + パターン完了予測 |

### 4b.7 群 E: 共有 UI 部品 (3 本、373 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`horo_panel_shared.dart`](../lib/screens/horoscope/horo_panel_shared.dart) | 307 | `PlanetVectorIcon`、`ZodiacImageIcon`、`HoroAspectCheckmark`、`HoroHourMinuteDropdown`、`horoAntiqueHeader`、`horoPlanetOrAngleName`、`horoActivePatternKey`、`horoPredictionKey` | Horo panel 系の共有部品集。`PlanetVectorIcon` (惑星グリフ表示)、`ZodiacImageIcon` (星座 webp + 黒透過)、`HoroAspectCheckmark` (☑ 描画)、`HoroHourMinuteDropdown` (時分入力 dropdown) |
| [`horo_desc_section.dart`](../lib/screens/horoscope/horo_desc_section.dart) | 31 | `HoroDescSection` | 「ラベル + 本文」セクション共通枠 (アスペクト/パターン解説で使用) |
| [`horo_info_row.dart`](../lib/screens/horoscope/horo_info_row.dart) | 35 | `HoroInfoRow` | 「ラベル + 値」情報行 (panel 共通) |

### 4b.8 群 F: パネル群 (8 本、1,967 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`horo_birth_panel.dart`](../lib/screens/horoscope/horo_birth_panel.dart) | 435 | `HoroBirthPanel` (Stateful) | **🔴 出生情報入力フォーム** (インライン化済 [`project_solara_horo_birth_inline_form`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_horo_birth_inline_form.md))。地名・日時・座標 + reverse geocoding 連動 (`_scheduleGeoLookup` / `_runGeoLookup`)。Sanctuary editor と分離 |
| [`horo_relocation_panel.dart`](../lib/screens/horoscope/horo_relocation_panel.dart) | 422 | `HouseShift`、`HoroRelocationPanel` (Stateful) | **🔴 リロケーション panel** ([`project_solara_relocation_m0`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_relocation_m0.md))。Dart `astro_houses.dart` で現住所チャート再計算 + Phase A 静的テンプレ (`horo_relocation_templates.dart`) + Phase B Gemini `/relocation` (`fortune_api.dart`)。ASC/MC 変化 + 12 ハウス全惑星のシフト表示 |
| [`horo_fortune_cards.dart`](../lib/screens/horoscope/horo_fortune_cards.dart) | 240 | `HoroAstrologyView` | **🔴 Gemini 占いカード表示**。`fortune_api.dart` 経由 `/fortune` で 5 カテゴリ占い文取得 + skeleton loading + error/edit バナー |
| [`horo_prediction_panel.dart`](../lib/screens/horoscope/horo_prediction_panel.dart) | 235 | `HoroPredictionPanel` | パターン予測 panel。アクティブなパターン + 未来予測を `buildAspectDescription` (1b) で解説生成、`showInfoPopup` で詳細表示 |
| [`horo_transit_panel.dart`](../lib/screens/horoscope/horo_transit_panel.dart) | 157 | `HoroTransitPanel` (Stateful) | Transit (現在の星位) を natal に重ねる panel |
| [`horo_planet_table.dart`](../lib/screens/horoscope/horo_planet_table.dart) | 160 | `HoroPlanetTable` | 10 惑星 + ASC/MC + 12 ハウス一覧表 (`_planetHouse` で位置算出) |
| [`horo_aspect_list.dart`](../lib/screens/horoscope/horo_aspect_list.dart) | 184 | `HoroAspectList` | 全アスペクト一覧。タップで `_showAspectDescription` → `buildAspectDescription` (1b) 解説 popup |
| [`horo_filter_panel.dart`](../lib/screens/horoscope/horo_filter_panel.dart) | 134 | `HoroFilterPanel` | アスペクト/パターン絞込チップ (フィルタ + exclusive chip 排他選択) |

### 4b.9 群 G: 静的データ (Horo 内部) (1 本、196 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`horo_relocation_templates.dart`](../lib/screens/horoscope/horo_relocation_templates.dart) | 196 | (惑星 × ハウス) 解説テンプレ const Map | Phase A 静的テンプレ (将来 Gemini 動的生成と同データ構造で互換)。`horo_relocation_panel.dart` のみが import (`fortune_api.dart` はコメント参照のみ) = Horoscope-only 静的データ |

### 4b.10 群 H: barrel (1 本、14 行)

| ファイル | 行 | 役割 |
|---|---|---|
| [`horo_bottom_panels.dart`](../lib/screens/horoscope/horo_bottom_panels.dart) | 14 | 旧 1,282 行 `horo_bottom_panels.dart` の分割互換 barrel。既存 import 互換のため残置 |

### 4b.11 Worker / 外部呼出

**本層は直接の Worker URL リテラルを持たない** (機械抽出で 0 リテラル確認済)。経由する Worker は層 2a 経由:

| 経由 | endpoint | 用途 |
|---|---|---|
| `map_astro.dart` (2a) | `/astro/chart` | natal+transit+progressed+ASC/MC/DSC/IC + 全アスペクト取得 (Map と同じ fetcher) |
| `fortune_api.dart` (2a) | `/fortune` (Gemini) | 5 カテゴリ占い文生成 |
| `fortune_api.dart` (2a) | `/relocation` (Gemini) | リロケーション解説生成 (Phase B) |
| `solara_api.dart` (2a) | `/tz` | 出生地のタイムゾーン解決 (horo_birth_panel) |
| `reverse_geocode.dart` (2a) | Nominatim 直叩き | 出生地座標→地名 (horo_birth_panel) |

= **Gemini 呼出 2 系統 (`/fortune` + `/relocation`) が Horoscope に集中**。Map (4a) は Gemini ゼロ、Horoscope が Gemini 中央。

### 4b.12 機械分類の盲点 + 重要な実態 (✅ オーバーライド適用済)

1. ~~**`horo_antique_icons.dart` は実態が層 3a**~~ — ✅ 2026-05-14 `PATH_OVERRIDES` で 3a に明示移動済。16 ファイル cross-cutting (Map/Galaxy/Horo/no_profile_guide/galaxy_star_atlas)
2. ~~**`horo_constants.dart` は実態が層 1b**~~ — ✅ 同オーバーライドで 1b に明示移動済。13 ファイル cross-screen (Map relocation/line_narrative + Horo 9 + Galaxy も)
3. ~~**`horo_aspect_description.dart` は実態が層 1b**~~ — ✅ 同オーバーライドで 1b に明示移動済。Map (map_aspect_chip) + Horo (3 ファイル) 共用
4. **`horoscope_screen.dart` 754 行は code_audit の WARN 範囲** (HARD 閾値 500 行は超える) — pre-existing で別タスク
5. **`horo_chart_painter.dart` 702 行も WARN/HARD 境界** — チャート描画は責任明確で許容範囲。分割すると `_spreadOverlappingPlanets` 等の連携が複雑化

### 4b.13 重要な仕様メモリへの参照

| メモリ | 内容 |
|---|---|
| [`project_solara_horo_birth_inline_form`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_horo_birth_inline_form.md) | Horo Birth Panel インライン入力フォーム化 (Sanctuary と完全分離・別画面 push 廃止) |
| [`project_solara_relocation_m0`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_relocation_m0.md) | Phase M0 リロケーション + Phase A 静的解説完成状態 |
| [`project_solara_message_tone`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_message_tone.md) | Solara 世界観テキスト文体ルール (Stella=ですます / 真理=体言止) — Horoscope 占いカードに適用 |

### 4b.14 課金検討に直結する示唆

1. **🔴 Gemini 呼出 2 系統が本層に集中 = 課金で守るべき中央**
   - `/fortune` (5 カテゴリ占い文) + `/relocation` (引越し解説) は両方とも `fortune_api.dart` (2a) 経由
   - **回数制限の自然な実装ポイント**: Free は 1 日 1 回 (全カテゴリ一括)、Pro は無制限再生成 + 過去履歴閲覧
   - 既存 KV 月次クォータ (`forecast` だけ実装) と同様の per-IP/per-user カウンタを `/fortune` + `/relocation` にも導入

2. **リロケーション Pro 化候補**
   - Phase A 静的テンプレは無料、Phase B Gemini 動的解説は Pro 限定
   - 既に Phase A/B 並走実装済 ([`project_solara_relocation_m0`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_relocation_m0.md)) なので、Pro ゲートだけ追加すれば差別化が成立
   - 「無料は型通りの解説、Pro はあなた専用の AI 解説」が訴求しやすい

3. **パターン検出 (`horo_pattern_logic.dart`) は Solara 独自の差別化**
   - Grand Trine / T-Square / Yod 検出 + 未来予測は商用占いアプリでも珍しい
   - 無料機能の魅力強化に投資する箇所 = Pro 化対象としては弱い

4. **`horo_chart_painter.dart` の HoroChartWheelPainter は Horoscope の心臓**
   - 12 星座輪 + 惑星スプレッド (`_spreadOverlappingPlanets`) は HTML 移植完了済
   - **Pro 拡張案**: 星座 + 惑星のカスタム配色 (デフォルト + Pro 限定 5 テーマ)、12 星座 webp 高精細版差し替え

5. **占いカード (`horo_fortune_cards.dart`) の skeleton loading は UX 投資**
   - Gemini 応答 3〜5 秒待機中に skeleton 表示で離脱率低減
   - Pro 機能で「カード保存 / シェア / 過去履歴閲覧」を追加すると価値が上がる

6. **`horoscope_screen.dart` 754 行は分割候補だが緊急度低**
   - 既に `_HoroBackdrop` / `_HoroBottomSheet` / `_HoroChartView` extension で 519 行を切り出し済 (本来は 1,273 行相当)
   - さらに分割するなら `_HoroFortune` (fortune loading) / `_HoroAnim` (lifecycle) 追加が候補

### 4b.15 機械抽出への参照

層 4b の機械抽出 raw: [`feature_inventory/04b_horoscope.md`](feature_inventory/04b_horoscope.md)

---

## 層 4c: Observe (Tarot) 画面

### 4c.1 概要

`lib/screens/observe/` 配下 + `lib/screens/observe_screen.dart` の **5 ファイル / 計 1,564 行**。Solara の Tarot タブ (画面名 "Observe" = HTML `tarot.html` の Dart 移植)。

**機械分類の精度** (✅ オーバーライド不要): 5 ファイル全て Observe-only、cross-cutting なし。`observe_constants.dart` (TAROT_READINGS templates、要素別 4 種) も Observe 内のみで参照 = 層維持。

Observe の機能領域:

| 機能領域 | 概要 |
|---|---|
| 1 日 1 引きタロット | 78 枚デッキから 1 枚引き、`DailyReading` (層 1c) に永続化 |
| カード表示演出 | 3D 反転 (`Observe3DCard`)、要素別タロット解説 (火/水/風/地) |
| Gemini 解説生成 | `/tarot` 経由でカードに応じた解説文を生成 (Phase A、要素別テンプレ fallback) |
| 履歴閲覧 | 過去引いたカードの一覧 (`ObserveHistoryPanel`) + 同期入力 |
| 占卓演出 | 5 惑星配置 + 流れ星 + 太陽 blaze の背景シーン (`TarotAltarScene`) |

**Pro 公開時の最大対象**: `/tarot` (Gemini) 呼出が本層に集中、現状は 1 日 1 回固定 = 永続化規律。Pro 化候補は **3 枚引き / 5 枚引きスプレッド** ([`project_tarot_v2_plan`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_tarot_v2_plan.md))。

### 4c.2 ファイル別 役割 + 呼出元 (5 本)

| # | ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|---|
| 1 | [`observe_screen.dart`](../lib/screens/observe_screen.dart) | 524 | `ObserveScreen` (Stateful)、`_ObserveScreenState` | **🔴 Observe 統合ハブ**。17 関数 (public 4 + private 13)、10 import (utils 4 + models 2 + observe 内 4)。`/tarot` (Gemini) を `fortune_api.dart` の `fetchTarotReading` 経由で呼出、失敗時は `_generateReadingStatic` (要素別テンプレ fallback)。`_startTypewriter` で解説文を typewriter 演出 |
| 2 | [`tarot_altar_scene.dart`](../lib/screens/observe/tarot_altar_scene.dart) | 500 | `TarotAltarScene` (Stateful、TickerProvider)、`_TarotAltarSceneState`、`_PlanetDef`、`_AltarLayout` | **占卓背景シーン** ([`project_solara_tarot_altar`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_tarot_altar.md))。5 惑星楕円配置 (北=Moon / 東=Venus 等)、`_scheduleNextMeteor` / `_triggerMeteor` で流れ星演出、`_buildSunBlaze` で太陽光、`_planetSprite` で惑星描画 |
| 3 | [`observe_history.dart`](../lib/screens/observe/observe_history.dart) | 287 | `ObserveHistoryPanel` (Stateful)、`_SyncInput` (Stateful) | 過去引いたタロット履歴 panel。`_confirmClearHistory` で全消去、`_buildHistoryCard` / `_buildHistoryDetail` でカード一覧。`_SyncInput` は同期コード入力用 (将来の引き継ぎ機能用) |
| 4 | [`observe_card_widgets.dart`](../lib/screens/observe/observe_card_widgets.dart) | 198 | `Observe3DCard`、`ObserveCardBack`、`ObserveCardFront`、`ObserveCardInfo` | **3D カード演出 4 種**。`Observe3DCard` は Y 軸反転 (flip) widget、`ObserveCardBack` / `Front` は表裏、`ObserveCardInfo` は要素 + 惑星 + 番号表示 |
| 5 | [`observe_constants.dart`](../lib/screens/observe/observe_constants.dart) | 55 | `tarotReadings` (要素別 4 種 × 2 テンプレ = 8 文)、`planetInfo` (10 惑星 × symbol/nameJP/color)、`elementColors` / `elementNames` / `elementEmojis` (4 元素 × 3 表現) | **静的データ**。Gemini fallback 用のテンプレ文 + 4 元素テーブル。`observe_screen` のみが参照 = Observe-only |

### 4c.3 Worker / 外部呼出

| endpoint | ファイル | 用途 |
|---|---|---|
| `/tarot` (POST、Gemini) | 経由: [`fortune_api.dart`](../lib/utils/fortune_api.dart) (2a) → `fetchTarotReading` | カード + 要素 + 月相 + Stella コンテキストから Gemini で解説文生成。失敗時 null fallback → 要素別テンプレ |

**本層は直接の Worker URL リテラルなし** (機械抽出で 0 リテラル確認済)。Map (4a) は Worker 5 リテラル / Horo (4b) は 0 / Observe (4c) も 0 = Gemini 呼出は全て `fortune_api.dart` (2a) 経由で統一。

### 4c.4 依存関係 (層を跨ぐ参照)

| 依存先 | 用途 |
|---|---|
| `models/tarot_card.dart` (1c) | 78 枚カード定義 (`TarotCard`) |
| `models/daily_reading.dart` (1c) | 1 日 1 引きキャッシュ (`DailyReading`) |
| `utils/tarot_data.dart` (2c) | 78 枚デッキ起動時 initialize singleton |
| `utils/fortune_api.dart` (2a) | `/tarot` Gemini 呼出 |
| `utils/moon_phase.dart` (1a) | カード解説生成時の月相コンテキスト |
| `utils/solara_storage.dart` (2b) | 履歴永続化 (`getDailyReading` / `saveDailyReading` / `clearReadingHistory`) |

### 4c.5 機械分類の盲点 + 重要な実態

1. **5 ファイル全て Observe-only = 機械分類が正しい状態** — `_classify_screen` で `screens/observe/` → 4c 判定が機能している
2. **`tarot_altar_scene.dart` (500 行) は AnimationController あり** だが、画面専用の演出シーンなので 4c が正しい (= 3c 横断 widget とは異なる)
3. **`observe_screen.dart` 524 行は code_audit の WARN 範囲**だが、`_buildDrawPanel` / `_buildReadingPanel` / `_buildLoadingIndicator` 3 build subtree でちょうど 500 行を超えるレベル。許容範囲

### 4c.6 重要な仕様メモリへの参照

| メモリ | 内容 |
|---|---|
| [`project_tarot_v2_plan`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_tarot_v2_plan.md) | タロットアプリ v2 計画 (本格占いプラットフォーム化、カード画像生成、選択式 UI、複合占術) — **Pro 拡張の主要設計** |
| [`project_solara_tarot_cards`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_tarot_cards.md) | Tarot 未実装 Phase 2 (トランジットタロット・拠点設定 UI) |
| [`project_solara_tarot_altar`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_tarot_altar.md) | Tarot 占卓シーン現状設定 (5 惑星配置・楕円半径・流れ星仕様・生成スクリプト) |
| [`project_seimei_tarot`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_seimei_tarot.md) | 独自占術「姓名×タロット」設計 (母音重視 9 分類、変換テーブル、動画集客構想) |

### 4c.7 課金検討に直結する示唆

層 4c は **Pro 機能の差別化最有力候補**。Tarot は商用占いアプリで最も人気のジャンル、Solara はここで独自路線 (両面思想 + AI 解説 + 月相連動) を打ち出せる位置。

1. **🔴 Pro 機能の最有力候補ベスト 3 (本層から導出)**
   - **(a) 3 枚引き / 5 枚引きスプレッド** ([`project_tarot_v2_plan`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_tarot_v2_plan.md)) — Free は 1 日 1 引き、Pro は無制限 + 多枚引き。`_drawCard` の枚数制御 + UI 追加で実装可
   - **(b) 任意カード手動選択 (選択式 UI)** — 同上 v2 計画。「気になるカードを選んで読む」体験は商用差別化軸
   - **(c) 過去履歴の検索 + フィルタ** — 現状 `ObserveHistoryPanel` は時系列のみ。Pro は要素別 / 期間別 / キーワード検索追加

2. **`/tarot` Gemini 呼出の回数制限 = Free/Pro の自然な境界**
   - 現状 1 日 1 回固定 (`_checkTodayReading` で永続化)
   - Free は 1 日 1 回維持、Pro は無制限再生成 (= 引き直し)
   - `fortune_api.dart` の Gemini 呼出に per-IP/per-user カウンタを追加 (Horoscope の `/fortune` と同じ仕組み)

3. **独自占術「姓名 × タロット」** ([`project_seimei_tarot`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_seimei_tarot.md))
   - 母音重視 9 分類 + 変換テーブルで姓名と日付からカードを推定
   - 動画集客構想付き = **Pro 限定の独自占術** として位置付ければ集客効果も
   - 現状未実装、新規 panel + utils 関数で実装可

4. **`tarot_altar_scene.dart` の占卓背景は無料機能の魅力源**
   - 5 惑星 + 流れ星 + 太陽 blaze の演出は商用 Tarot アプリでも珍しい
   - Pro 化対象としては弱いが、無料層の魅力強化に投資する箇所
   - Pro 拡張案: 「占卓を月相 / 時刻で変える」(満月時は満月、新月時は新月の背景)

5. **`tarotReadings` 静的テンプレは「Gemini 失敗時の fallback」**
   - 要素別 4 種 × 2 テンプレ = 8 文のみ、繰り返し感あり
   - **Pro 拡張案**: テンプレ拡張 (要素 × 月相 × 引き枚数で多様化)、または Pro は常に Gemini 動的、Free は静的テンプレ + Gemini 1 日 1 回

6. **`Observe3DCard` の 3D flip は HTML 移植完了済 = 独自性源**
   - Y 軸反転 + perspective transform で物理感のあるカードフリップ
   - Pro 拡張案: 反転速度 / 効果音 / カード素材 (デフォルト + Pro 5 種) のカスタマイズ

7. **`DailyReading` モデル (1c) のクラウドバックアップ Pro**
   - 過去履歴は **ユーザーの最大の体験ログ** = 引き継ぎ需要
   - 機種変更時に履歴消失すると離脱リスク = Pro 課金で守る価値

### 4c.8 機械抽出への参照

層 4c の機械抽出 raw: [`feature_inventory/04c_observe.md`](feature_inventory/04c_observe.md)

---

(層 4d 以降は次セッション以降で追記。層 4 は 1 セッション 1 画面の予定)
