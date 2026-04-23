## できる事
1. 今日の一番のスコアを恋愛、仕事、金運、会話、癒しからアクション表示
2. 日付バッジ（左上）から指定日の運勢方位 — タップでピッカー、✕ で今日リセット
3. Locations 画面（🗺ボタン）— 基準地点プルダウン＋カテゴリ別スコア＋日付ステッパー
4. 検索（🔍）— 検索地点毎のスコア（日付/ソース/カテゴリ切替追従）
5. Forecast（🔮）— 1〜5年の運勢予測ヒートマップ＋強運Top5＋運勢サイクル

---

## 実装状況（2026-04-23 後半セッション 完了）

### Map 操作 UI（最新）

| 要素 | 機能 |
|---|---|
| 日付バッジ（左上、常時表示・大きめ）| 「今日」表示 → タップでピッカー、カスタム日 → ✕ でリセット |
| サイドボタン 5 個 | 🔍 検索 / ≡ Layer / 📍 VP / 🗺 Locations / 🔮 Forecast（48px等間隔） |
| 📅 日付ボタン削除 | 左上バッジに集約 |

### MAPSTYLE（ラベル変更前は STYLE）

- **Map / MapDark / Cycle / CycleDark** の 4 種（OSM HOT + CyclOSM、現地語ラベル）
- 全タイルは Solara Worker `/tiles/osm/<source>/{z}/{x}/{y}.png` 経由（UA固定 + edge cache 24h）
- LANG 切替・Smart ハイブリッド・Jawg は撤去済み（多言語ニーズ低 + 月25kビュー無料枠で十分）
- ユーザー数増えたら Jawg/$25 プラン再導入を検討（Worker 側コード参考用に削除済みだが履歴に残置）

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
  ├─ map_layer_panel.dart  (153) — レイヤー表示切替パネル
  ├─ map_overlays.dart     (349) — SideButtons/SearchBar/Badges/VP Pin/RestOverlay 等
  ├─ map_planet_lines.dart (191) — 天体ライン描画
  ├─ map_search.dart       (360) — searchPlaces / SearchResultList / SearchFocusPopup
  ├─ map_sectors.dart      (176) — 16方位セクターポリゴン
  ├─ map_stella.dart       ( 57) — Stella / StellaMinimized / Preseed
  ├─ map_styles.dart       (116) — MapStyle enum + タイル定義
  ├─ map_vp_panel.dart     (435) — VPPanel + SlotManager + VPSlot
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
