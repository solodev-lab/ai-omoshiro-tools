## できる事
1. 今日の一番のスコアを恋愛、仕事、豊かさ、対話、癒しからアクション表示
2. 日付バッジ（左上）から指定日の運勢方位 — タップでピッカー、✕ で今日リセット
3. Locations 画面（🗺ボタン）— 基準地点プルダウン＋カテゴリ別スコア＋日付ステッパー
4. 検索（🔍）— 検索地点毎のスコア（日付/ソース/カテゴリ切替追従）
5. Forecast（🔮）— 1〜5年の運勢予測ヒートマップ＋強運Top5＋運勢サイクル
6. **F1-c (2026-04-29): Daily Transit** — 右上 DailyTransitBadge → 拠点での各惑星×4アングル(ASC/MC/DSC/IC) 通過時刻 + natal アスペクト併記。本日/明日タブ切替
7. **2026-04-30 拡張**:
   - Daily Transit に **アングルフィルタ (ASC+MC / DSC+IC / 全角度) + カテゴリフィルタ + 行動指針 (10パターン)**
   - **VIEWPOINT 切替 dropdown** (出生地 + VPスロット) で場所別の通過時刻を即時表示
   - 個別イベント i ボタン → **惑星×アングル基本意味 (40) + カテゴリ補足 (5)** 詳細 dialog
   - 検索 = **Google Places (New) Text Search** に切替 (locationBias 15km, pageSize 20, 番号マーカー1〜20)
   - **A\*C\*G ラインタップ詳細シート** (静的辞書 → 「詳しく読む」AI解釈、Soft/Hard 別表示)
   - 左上スコアバータップで **カテゴリ循環切替** (扇状も連動)

---

## 設計思想（最優先）

> 詳細: `memory/project_solara_design_philosophy.md`

- **Soft / Hard は独立した別エネルギー**（1軸の両端ではない）
- 占い的吉凶判定をしない（「ラッキー」「アンラッキー」は出さない）
- 16方位スコアは**2エネルギー独立並列描画**（内側=ソフト銀月色 / 外側=ハード金陽色）
- カテゴリ名: 金運 → **豊かさ** に統一（2026-04-29）

---

## F1-c: Daily Transit（2026-04-29 完成）

### バッジ（右上）
- リセット時刻後初回 → 光る + カテゴリアイコン
- 同日2回目以降 → 静的カテゴリアイコン
- プロフィール無 → 控えめ🌱（無効）
- カテゴリアイコンは `CategoryIcon`（CustomPainter、Style D = 惑星シンボル+装飾）

### タップ → 全面UI（`MapDailyTransitScreen`）
1. （初回のみ）`DominantFortuneOverlay` で TOP カテゴリのアニメ → 0.5s 余韻
2. フェードイン → 全面表示
3. ヘッダ: 大型カテゴリアイコン(64px) + 「今日の TOP — label」 + i (2026-05-12 行末配置) + ✕
4. タブ: **本日 / 明日**（lazy load + キャッシュ）
5. タイムライン: 10惑星 × 4アングル を時刻順に並列
6. 各行: 時刻(1分単位固定) / 惑星 / 「金星 が 天頂(MC) 通過 ⓘ」 / アスペクトチップ群（横スクロール）
7. 各行下: 🗺 地図マーク (2026-05-12 追加、タップでその時刻 1 分単位を Map に飛ばす)
8. アスペクトチップ: タップで Horo 相タブ同等の詳細

### onJumpToTime 連携 (2026-05-12)
- Daily Transit 各行の 🗺 → `MapDailyTransitScreen.onJumpToTime(event.time)` 発火
- 親 (`map_screen.dart`) で `_selectedDate = time` + `_dailyTransitOpen = false`
  + `_loadProfileAndChart(targetDate: time)`
- `MapTimeSlider` の分表示は実分 (1 分単位、`_displayMinuteJst()`)
- step 操作 (▶◀) は 10 分 grid に合流 (`_committedMinuteJst()` = floor 10)
  - 例: 11:02 表示 → ▶ で 11:10 → 11:20 → ◀ で 11:10 → 11:00

### 観測点（拠点）優先順
1. Sanctuary 設定の home (homeLat, homeLng)
2. 出生地 (birthLat, birthLng)
3. 地図中心 (`_center`)

### Worker 側
- `/astro/daily-transits` POST
- `startTimeIso` 渡し → JST等のローカル日境界で正確に24h走査
- `natal` 渡し → V2: 各時刻のトランジット惑星 × natal惑星アスペクトを併記
- `orbs` 渡し → V2.2: Sanctuary のアスペクトオーブ設定を反映
- アスペクト種別: 8種（メジャー5 + マイナー3）

---

## 実装状況（2026-04-23 後半セッション 完了）

### Map 操作 UI（最新）

| 要素 | 機能 |
|---|---|
| 日付バッジ（左上、常時表示・大きめ）| 「今日」表示 → タップでピッカー、カスタム日 → ✕ でリセット |
| サイドボタン 5 個 | 🔍 検索 / ≡ Layer / 📍 VP / 🗺 Locations / 🔮 Forecast（48px等間隔） |
| 📅 日付ボタン削除 | 左上バッジに集約 |

### MAPSTYLE（ラベル変更前は STYLE）

- **Map / MapDark** の 2 種（OSM HOT × Light/Dark、現地語ラベル）
- 全タイルは Solara Worker `/tiles/osm/<source>/{z}/{x}/{y}.png` 経由（UA固定 + edge cache 24h）
- LANG 切替・Smart ハイブリッド・Jawg・CyclOSM は撤去済み
  - Jawg: 多言語ニーズ低 + 月25kビュー無料枠で十分（ユーザー数増えたら$25プラン再導入を検討）
  - CyclOSM: 2026-05-09 削除。本番 Worker の allowlist 不整合で 400 多発 + 商用利用ポリシー懸念（OSM usage policy）。再導入時は要 wrangler deploy + ストア審査リスク再評価
- ユーザー数増えたら多言語タイル再導入を検討（memory: project_solara_map_styles.md にスケール戦略あり）

### 惑星アイコン（ベクター描画）

- HORO と同じ `PlanetVectorIcon`（`horo_panel_shared.dart`）を Map マーカー内で使用
- OS フォント依存なし → Venus/Mars が絵文字化されず他惑星と同じ細線で揃う
- 色合いも HORO と統一: natal=ゴールド `#FFD370`、progressed=パープル `#B088FF`、transit=ライトブルー `#6BB5FF`
- 惑星ラインの edge tracking（Liang–Barsky 投影）でビューポート端に張り付く

### Locations 画面（拡張完了）

- ヘッダ直下に 3 操作メニュー：
  1. 日付ステッパー `[年▲▼] [月▲▼] [日▲▼]` + ✕ 今日リセット（手入力対応）
  2. 基準地点プルダウン（現在地 + VIEWPOINT スロット）
  3. 5カテゴリチップ（癒し/金運/恋愛/仕事/話す、再タップで総合に戻る）
- 行レイアウト：方位+距離→スコアバー、右端 40px 固定枠（HOMEバッジ or ⋯ メニュー）
- 日付変更は内部で `fetchChart + scoreAll` を再実行（親 `_selectedDate` には影響なし）
- 関連ウィジェットは `screens/locations/locations_date_stepper.dart` に分離

### Forecast 画面（永続キャッシュ + 整理）

- **基準地セクション削除**（地点に依存しない計算なので誤解防止）
- **運勢サイクル永続化**：`detectLifePeriods` の結果を `solara_forecast_periods_*` に保存。1年=1回計算、強制リフレッシュ時のみ再計算
- **強運Top5 永続化**：6 mode × 5日を `solara_forecast_top5_*` に保存。mode 切替で再計算なし
- 運勢サイクル設定: `topPct=0.15, minDays=7, maxGap=2`（カテゴリ毎 2〜4件想定）
- 表示ロジック: 「今日以降の最初の期間」を本番表示。「次へ ▶」ボタンで全期間循環（確認用・臨時）
- 選択日カードに「Mapで見る →」リンク追加
- 関連ウィジェット分離: `screens/forecast/forecast_life_periods.dart`, `forecast_top5.dart`

### 日付選択範囲（全画面統一）

- 今日 −10年 〜 今日 +20年（過去回顧 + 中長期予測）
- `showSolaraDatePicker`（Map バッジ）と Locations YMDステッパーの両方が同レンジ

### 未実装（将来タスク）

- Flutter i18n（UI の英語化、リリース直前まで保留）
- MAU 増加時の Jawg / 多言語タイル再導入
- Horo 画面への日付選択追加（現在は今日固定 + モック計算）

---

## 過去の試行履歴

### Smart ハイブリッド + Jawg 多言語タイル（撤去済み）

2026-04-22〜23 で実装したが、以下の理由で 2026-04-23 後半セッションで撤去：
- 想定ほど日本語化されない（OSM 現地語で十分なケースが多い）
- ユーザー数次第で月 25k views を超えるリスクがあり過剰実装
- ユーザー数が増えた段階で再導入予定（$25/100kビュープラン or Jawg）

撤去内容: `MapStyle` enum から smartLight/jawgStreets/jawgDark、`map_hybrid_provider.dart`、Worker `/tiles/jawg/`、LANG セクション。Jawg トークンは CF secret に残置（再導入時の再利用用）。

### OpenFreeMap ベクタタイル（リバート済み）

vector_map_tiles 10.0.0-beta.2 を試したが Impeller GLES シェーダ互換性問題で実機クラッシュ。全面リバートしてラスタ方式維持。

---

## 実装状況（2026-04-22 セッション時点）

### ✅ Phase 0: 天体計算基盤（完了）
- Worker `solara-api`（`solara-api.solodev-lab.com`）稼働
- `/astro/chart` で Natal/Transit/Progressed + ASC/MC/DSC/IC + アスペクト
- mode='both' で Transit+Progressed 同時取得
- `map_astro.dart` scoreAll() で16方位スコア
- N方向ポリゴン破綻を修正済（nPolar 距離制限）

### ✅ Phase 1: Map操作系 + Forecast（完了）

| 機能 | 入口 | 主要ファイル |
|-----|-----|------------|
| 日付ピッカー統合 | Map画面 📅 | `map_screen.dart` / `map_astro.dart fetchChart` |
| Locations 一覧 | Map画面 🗺 | `screens/locations_screen.dart` |
| 検索強化（スコア付き・日付連動） | Map画面 🔍 | `screens/map/map_search.dart` |
| Forecast（1〜5年分） | Map画面 🔮 | `screens/forecast_screen.dart` |
| Worker 日次予測 | POST `/astro/forecast` | `worker/src/astro.js computeForecast` |
| クライアントキャッシュ＋月次差分 | — | `utils/forecast_cache.dart` |
| 「◯◯期」検出 | Forecast 画面 | `utils/forecast_cache.dart detectLifePeriods` |
| Rate Limit + KV 月次クォータ | Worker | `worker/src/index.js` (forecast=6/min, KV=60/month) |
| ヒートマップ 3モード切替 | Forecast 画面 | 相対/絶対/カテゴリ + 🟢↑高/🔴↑高 |
| ランク別表示 | Forecast 画面 | カテゴリモードの 1位/2位 セグメント |
| 年範囲 5年まで | Forecast 画面 | 今年/来年/再来年/3年後/4年後 |
| Top5 カテゴリ別 | Forecast 画面 | 総合＋5カテゴリの 6セグメント |
| 年間ベスト日 | Forecast 画面基準地カード | Mapジャンプ可 |

### ファイル分割（Phase 1 後）

Map画面のコードは以下に分割：

```
lib/screens/map_screen.dart (803行)  ← メインStatefulWidget
lib/screens/map/
  ├─ map_astro.dart        (375) — fetchChart + scoreAll
  ├─ map_constants.dart    (101) — dir16, カテゴリ色, 惑星メタデータ
  ├─ map_fortune_sheet.dart(323) — FortuneFilterLabel + FortuneSheet
  ├─ map_menu_chips.dart   (2026-05-09) — NavBar 直上 4 チップバー (Daily Transit/運勢方位/LOCATIONS/予報) + Daily Transit halo
  ├─ map_display_menu.dart (2026-05-09) — ☰表示ボタン展開 3階層タブメニュー (Map/惑星/ACG)
  ├─ map_viewpoint_menu.dart (2026-05-09) — 📍地点ボタン展開 VIEWPOINT/LOCATIONS タブパネル + スロット管理
  ├─ map_overlays.dart     (322) — 🔍 検索ボタン + ☰表示 + 📍地点 ボタン (3個に簡素化)
  ├─ map_planet_lines.dart (191) — 天体ライン描画
  ├─ map_search.dart       (360) — searchPlaces / SearchResultList / SearchFocusPopup
  ├─ map_sectors.dart      (176) — 16方位セクターポリゴン
  ├─ map_styles.dart       (116) — MapStyle enum + タイル定義
  ├─ map_vp_panel.dart     (短縮済) — VPSlot + SlotManager のみ (VPPanel widget は廃止)
  └─ map_widgets.dart      ( 87) — MapBtn 共通ボタン

lib/screens/
  ├─ locations_screen.dart (290) — 拠点一覧画面
  └─ forecast_screen.dart  (720) — Forecast 画面

lib/utils/
  └─ forecast_cache.dart   (280) — ForecastDay / ForecastCache / detectLifePeriods
```

### スコア計算方針

- アスペクト重み: 0.4〜1.0（conjunction/sextile/square/trine/quincunx/opposition）
- Transit/Natal=0.6、Progressed/Natal=0.5、Transit/Progressed=0.4 の掛率
- 16方位 spread=22.5°、cos falloff
- `_fortunePairs` で 5カテゴリ（love/money/healing/work/communication）別スコア
- Scoreモデルは Flutter 側 `scoreAll()` と Worker 側 `scoreOneDate()` で完全一致

### 「◯◯期」検出ロジック

- 各カテゴリの年間スコアを降順ソート → 上位25%を閾値に
- 閾値以上が 7日以上連続（2日以内の凹みは吸収）で「期」として抽出
- カテゴリごと最長1期を採用
- 絵文字ラベル: 💗モテ期/💰金運期/🌿癒し期/⚙仕事期/💬発信期

### インフラ

- **Cloudflare Workers 無料枠**（10万req/day）内で動作
- `/astro/forecast` は Rate Limit 6req/min、KV ベース 60req/月/IP
- **Gemini API Key は Places API と別物**（必要時は `GOOGLE_PLACES_KEY` を追加）
- データ量: 1年分キャッシュ≈ 120KB JSON、5年で ≈ 600KB

### 視認性・UX

- OSM 明るい地図でのセクター視認性: HSL 明度×0.45/彩度×1.2 で自動暗色化
- カメラリセット問題解消: `_hasInitialCenter` フラグ導入（VP 切替後の日付変更で VP を保持）
- FortuneFilterLabel sub-pixel overflow: ClipRRect + IntrinsicWidth 除去で解消
- Heat map 色慣習: 🟢↑高（信号機式）/ 🔴↑高（日本株価式）切替


---

## 端末 back ボタン挙動 (2026-05-10 追加)

Android 端末の戻るボタン (△ / 戻すジェスチャ) で overlay/popup を上から順に閉じる。
全 overlay が閉じている時のみアプリ全体の back に伝播する。

### 優先順位 (back 1 回 = 1 つ閉じる)

1. **Daily Transit popup** (Map > Daily チップから開く)
2. **Fortune Sheet** (Map > Fortune チップから開く運勢方位 BottomSheet)
3. **Zenith popup** (天頂タップ。 ACG モード中も発火)
4. **Relocation popup** (ACG モード中のライン tap で開く)
5. **時刻バー展開** (上部時刻バーの ⏰ トグルで展開)
6. **ACG モード** (Astro*Carto*Graphy)
7. **表示メニュー / 地点メニュー** (左サイド ☰ / 📍)
8. **検索バー** (= `_searchOpen` / `_searchFocus` / `_searchHits` を一括クリア)

ここまで全部閉じると `main.dart` SolaraHome の root `PopScope` に伝播:
- Map 以外のタブ (Horo/Tarot/Galaxy/Sanctuary) → **Map タブに戻る**
- Map タブで何もない → **アプリ終了**

### 実装の要点

- `lib/main.dart` SolaraHome: タブ管理用 root PopScope (canPop = `_currentIndex == 0`)
- `lib/screens/map_screen.dart`: overlay 8 個分の優先順位付き分岐 PopScope
- `lib/screens/map/map_time_slider.dart`: `MapTimeSliderState` を public 化、 `onExpandedChanged`
  callback で親に展開状態通知 → 親 PopScope の canPop が再計算される
- `android/.../MainActivity.kt`: 過去の `OnBackInvokedDispatcher` 抑制 override (no-op
  registerOnBackInvokedCallback 等) は **PopScope を完全無効化していたため撤回**。
  空 class に戻し dispatcher の標準動作で PopScope 機能を有効化。

### Navigator 経由の popup は標準処理

以下は `showDialog` / `showModalBottomSheet` で Navigator stack に push されているため、
PopScope 統合は不要 (Flutter 標準で back 自動処理):
- `showLineNarrativeSheet` (ACG ライン詳細、2026-05-11 以降は静的辞書のみ。AI 解説撤去済み。`showInfoPopup` ベース)
- `showInfoPopup` (各種説明 popup)
- `LocationsScreen` / `ForecastScreen` (Navigator.push)

---

## メニューチップ v2 (2026-05-10 採用)

下部 NavBar 直上の 4 チップ (Daily / Fortune / Locations / Forecast) のアイコンを
woodblock simple 風アンティーク神秘画 (Gemini 3.1 Flash Image 生成) に置換。

### 設計

- **中央モチーフ大型化** (~80% canvas) で 32px 表示時の識別性確保
- **太線 woodblock 風** (細線 filigree からの転換)
- **外周は単純な点線リング 1 本** (旧 v1 の二重リング + 12 zodiac tick + filigree 装飾を撤廃)
- **惑星シンボル (♀♃♄☽☿) 廃止** (1 つの惑星でカテゴリを定義しないため)
- **円形 alpha マスク** で四隅透過 (チップ背景グラデーションに自然になじむ)

### アイコン一覧 (`assets/menu_icons/*.webp`)

| アセット | モチーフ | アクセント色 |
|---|---|---|
| `unsealed.webp` | 9芒星 + 中央封蝋 | 銀紫 (#B8B0C8) |
| `all.webp` | 8芒星 (汎用 / Daily トップ未確定) | 純金のみ |
| `love.webp` | ハート + 薔薇蔓 | dusty rose (#C99A9A) |
| `money.webp` | 月桂樹冠 + 中央星 | muted amber (#B8985A) |
| `work.webp` | 大樹 (Tree of Life) | dusty slate (#7B8B9E) |
| `healing.webp` | 三日月 + 葉 + 水滴 | silver-blue (#A8B8C8) |
| `communication.webp` | 翼 + 中央羽軸 | verdigris (#7BA098) |
| `fortune.webp` | 16方位コンパスローズ | aged copper (#9A6F4A) |
| `location.webp` | 地図ピン | sepia (#A88E66) |
| `forecast.webp` | 12 spoke 円 + 時計針 | parchment (#BFA070) |

### 生成・変換

- 生成: `mockup/generate_menu_icons_v2.py` (Gemini 3.1 Flash Image、 `gemini-3.1-flash-image-preview`)
- WebP化: `mockup/convert_menu_icons_to_webp.py` (1024px PNG → 256px WebP + 円形 alpha mask)
- 元絵保護: `mockup/share-assets/menu-icons/v2/` (PNG)、 `_backup/` に旧版退避
- 採用 webp 計 206KB (10 枚)

### Daily チップの状態分岐

- **disabled** (プロフィール未設定): 🌱 emoji
- **unseen** (未開封): `unsealed.webp` (9芒星) + halo 発光
- **seen** (開封済): `topCategory.webp` (love/money/work/healing/communication/all)

---

## 時刻ステッパー仕様 (2026-05-10 拡張)

### 日付ロールオーバー

- `23:XX → ▶ → 翌日 00:XX` (分維持)
- `00:XX → ◀ → 前日 23:XX`
- `_stepHour` で raw 値が 0..23 範囲外の時 `_commitDayShiftAndTime(dayDelta, ...)` で日付・時・分を一括 commit。

### 分用 ◀▶ (10 分刻み)

- 時刻バー右側スペース (76px) に ◀ / ▶ を配置。 ⏰ トグルの真下。
- `_stepMinute(±10)`: `totalMin = HH*60 + MM ± 10` を 1440 で正規化、 wrap 時に時/日付に連鎖。
- 表示も `"HH:00"` から `"HH:MM"` に拡張。
- `_committedMinuteJst()` は `(minute ~/ 10) * 10` で 10 分単位 floor (現在時刻が `12:34` のような中途半端な値にならない)。

### chart cache key

`map_screen.dart::_loadProfileAndChart` の cacheKey に minute (10 分単位 floor) を追加:

```
旧: YYYY-MM-DDThh
新: YYYY-MM-DDThh:mm  (mm は 10 分 bucket)
```

これで分用 ◀▶ で進めるたびに chart が再 fetch され、 月 (約 0.08°/10min) や GMST (約 2.5°/10min) で
惑星線位置・スコアが実際に動く。
