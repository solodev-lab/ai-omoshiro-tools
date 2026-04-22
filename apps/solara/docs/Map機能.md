## できる事
1. 今日の一番のスコアを恋愛、仕事、金運、会話、癒しからアクション表示
2. VIEWPOINTから指定日の運勢方位（📅ボタン）
3. VIEWPOINTから見る指定日付のLocationsの運勢スコア（🗺ボタンでLocations一覧画面）
4. VIEWPOINTから見る指定日付の検索地点毎のスコア（🔍検索、日付/ソース切替追従）
5. 1年〜5年の運勢予測 Forecast（🔮ボタン、ヒートマップ＋Top5＋「◯◯期」抽出）

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
