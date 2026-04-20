# Solara アーキテクチャ

> アプリ全体の構造と設計方針。
> 新しい画面や機能を追加する時はこのファイルを確認する。

---

## 全体構成

```
lib/ (77 .dart ファイル)
├── main.dart              ← アプリ起点。IndexedStackで5画面を管理
├── models/                ← データクラス
│   ├── daily_reading.dart    デイリーリーディング
│   ├── galaxy_cycle.dart     銀河サイクル・星座ドット
│   ├── lunar_intention.dart  月の意図・中間チェック・刻星化
│   └── tarot_card.dart       タロットカード
├── screens/               ← 各画面
│   ├── map_screen.dart       世界地図・運勢方位（メイン）
│   ├── map/                  ← Map サブウィジェット
│   │   ├── map_vp_panel.dart, map_astro.dart, map_fortune_sheet.dart
│   │   ├── map_planet_lines.dart, map_sectors.dart, map_layer_panel.dart
│   │   ├── map_constants.dart, map_widgets.dart, map_stella.dart
│   │   ├── map_styles.dart             タイル切替（OSM/CyclOSM × Light/Dark）
│   ├── horoscope_screen.dart ホロスコープ State本体 + build （part で拡張）
│   ├── horoscope/            ← Horoscope サブウィジェット
│   │   │  ─── horoscope_screen.dart の part 拡張 ───
│   │   ├── horo_chart_data.dart       チャート計算/アスペクト/パターン
│   │   ├── horo_backdrop.dart         星雲背景 + NoProfile画面
│   │   ├── horo_chart_view.dart       ホロスコープ円盤 + 凡例
│   │   ├── horo_bottom_sheet.dart     ボトムシート (タブ・コンテンツ)
│   │   │  ─── bottom_panels 分割 (barrel: horo_bottom_panels.dart) ───
│   │   ├── horo_panel_shared.dart     PlanetIcon / ZodiacIcon / Header / Checkmark
│   │   ├── horo_pattern_logic.dart    detectPatterns / predictPatternCompletions
│   │   ├── horo_birth_panel.dart      HoroBirthPanel
│   │   ├── horo_transit_panel.dart    HoroTransitPanel
│   │   ├── horo_planet_table.dart     HoroPlanetTable
│   │   ├── horo_filter_panel.dart     HoroFilterPanel
│   │   ├── horo_aspect_list.dart      HoroAspectList + 解説モーダル
│   │   ├── horo_prediction_panel.dart HoroPredictionPanel + 解説モーダル
│   │   │  ─── その他 ───
│   │   ├── horo_chart_painter.dart    チャート円盤 CustomPainter
│   │   ├── horo_fortune_cards.dart    運勢カード (星読みモード)
│   │   ├── horo_constants.dart        定数定義
│   │   ├── horo_antique_icons.dart    アンティーク風アイコン
│   │   ├── horo_astro_glyphs.dart     惑星/星座ベクターグリフ
│   │   ├── horo_aspect_description.dart  アスペクト説明テキスト
│   │   └── horo_ornament_painter.dart オーナメント装飾
│   ├── observe_screen.dart   タロット占い（メイン）
│   ├── observe/              ← Observe サブウィジェット
│   │   ├── observe_history.dart, observe_card_widgets.dart, observe_constants.dart
│   │   └── tarot_altar_scene.dart  斜め見下ろし占卓シーン（背景画像+5惑星浮遊+自転WebP+影+流れ星+太陽blaze）
│   ├── galaxy_screen.dart    銀河・星座（メイン）
│   ├── galaxy/               ← Galaxy サブウィジェット
│   │   ├── galaxy_constellation_builder.dart  星座生成ロジック
│   │   ├── galaxy_star_atlas.dart             Star Atlasタブ・カード
│   │   ├── galaxy_replay_overlay.dart         リプレイオーバーレイ
│   │   └── galaxy_sample_data.dart            デモ用サンプルデータ
│   ├── sanctuary_screen.dart プロフィール・設定（メイン）
│   └── sanctuary/            ← Sanctuary サブウィジェット
│       ├── sanctuary_profile_editor.dart, sanctuary_title_diagnosis.dart
│       ├── sanctuary_orb_overlay.dart, sanctuary_home_editor.dart
├── theme/                 ← 色・フォント定義
│   ├── solara_colors.dart, solara_theme.dart
├── utils/                 ← 計算・データ・永続化
│   ├── solara_storage.dart      SharedPreferencesラッパー
│   ├── solara_api.dart          CF Worker API呼び出し（TZ取得）
│   ├── fortune_api.dart         Fortune API呼び出し（Gemini占い文）
│   ├── moon_phase.dart          月相計算（Jean Meeusアルゴリズム）
│   ├── constellation_namer.dart 星座名生成・MST構築
│   ├── celestial_events.dart    天体イベント読み込み（API+キャッシュ+静的JSON）
│   ├── celestial_event_meanings.dart  天体イベント占星術的意味辞書（JP/EN）
│   ├── cycle_story_texts.dart   月齢サイクルストーリーテキスト（JP/EN）
│   ├── tarot_data.dart          タロットデータ読み込み
│   ├── title_data.dart          称号システム
│   └── app_locale.dart          言語切替（端末設定/JP/EN）グローバル Singleton
└── widgets/               ← 共通ウィジェット
    ├── solara_nav_bar.dart          ボトムナビゲーション
    ├── glass_panel.dart             フロストガラスパネル
    ├── moon_overlay.dart            re-export (下記3ファイル)
    ├── moon_overlay_shared.dart     mysticalMoonBackdrop + MoonScrollingStory (共通)
    ├── new_moon_overlay.dart        新月: ストーリー→テーマ選択→リビール演出+Set Intention
    ├── full_moon_overlay.dart       満月: ストーリー→3段階評価→リビール演出+自動確定
    ├── catasterism_overlay.dart     刻星化: ストーリー→手放せた/途中→発光+余韻+遷移
    ├── catasterism_formation_overlay.dart  刻星化アニメーション（4ステージ）
    ├── celestial_event_bar.dart     天体イベント横スクロールバー
    ├── dominant_fortune_overlay.dart ディスパッチャ: 5カテゴリ演出を enum で切替
    ├── fortune_overlays/            ← 5カテゴリの全画面演出（Map 初回タップ発火）
    │   ├── _common.dart                FortunePainterBuilder 抽象 + easing/stageAlpha 共有
    │   ├── love_painter.dart           恋愛: ハート放射 + 中心バースト + ゴッドレイ
    │   ├── money_painter.dart          金運: 金貨/金箔が上から降り画面下に積み上がる
    │   ├── healing_painter.dart        癒し: 花びら降り + 上部オーロラ帯 + 光の粒
    │   ├── communication_painter.dart  話す: 水平光ストリーム + 浮上音符（♪♫） + 光の粒
    │   └── work_painter.dart           仕事: 下から光の柱 + 上昇結晶 + スキャンライン
    ├── nav_icons.dart               ナビアイコン（CustomPainter x5）
    ├── constellation_painter.dart   星座描画（screen合成）
    ├── cycle_spiral_painter.dart    サイクルスパイラル描画
    └── spiral_painter.dart          スパイラル描画
```

---

## ナビゲーション

```
SolaraHome (main.dart)
  └── IndexedStack
      ├── [0] MapScreen          ← 世界地図
      ├── [1] HoroscopeScreen    ← ホロスコープ
      ├── [2] ObserveScreen      ← タロット
      ├── [3] GalaxyScreen       ← 銀河
      └── [4] SanctuaryScreen    ← 設定・プロフィール
              ├→ Navigator.push → SanctuaryProfileEditorPage  (sanctuary/)
              ├→ Navigator.push → SanctuaryTitleDiagnosisPage (sanctuary/)
              └→ Navigator.push → SanctuaryHomeEditorPage     (sanctuary/)
```

- ボトムナビ: `SolaraNavBar`（カスタム実装）
- 5タブ固定。IndexedStackなので全画面が常にメモリに存在する
- Sanctuary内のみ Navigator.push でサブページ遷移

---

## 状態管理

### 現状: StatefulWidget + setState

**全画面が StatefulWidget**。Riverpodはpubspec.yamlに宣言されているが未使用。

```
画面の状態 → setState() で管理
永続データ → SolaraStorage (SharedPreferences) で保存/読込
画面間の連携 → GlobalKey<HoroscopeScreenState> でHoro画面に直接アクセス
```

### 各画面の主な状態

| 画面 | 主な状態変数 | mixin |
|------|------------|-------|
| Map | mapCtrl, searchOpen, layerPanelOpen, fortuneSheetOpen, sectorScores | TickerProviderStateMixin |
| Horo | profile, chartMode, bsTab, natalPlanets, secondaryPlanets, aspects, qualityFilters, patternVisible | なし |
| Tarot | innerTab, cardFlipped, drawnCard, pulseCtrl, flipCtrl, history | TickerProviderStateMixin |
| Galaxy | activeTab, cycleDays, rotX/Y, breathController, replayCycle | TickerProviderStateMixin |
| Sanctuary | profile, titleLight/Shadow, houseSystem, orbValues | なし |

### 画面間データ共有

```
Sanctuary で プロフィール保存
  → SolaraStorage.saveProfile()
  → SharedPreferences に書き込み

Horo タブ選択時
  → main.dart が _horoKey.currentState?.loadProfile() を呼ぶ
  → SolaraStorage.loadProfile() で最新を読み込み

Map / Galaxy も同様に SolaraStorage 経由で読み込み
```

---

## テーマ・デザイントークン

### 色定義 (solara_colors.dart)

| 定数名 | 値 | 用途 |
|--------|-----|------|
| solaraGold | #F6BD60 | メインアクセント色 |
| solaraGoldLight | #F9D976 | ゴールドの明るい版 |
| celestialBlueDark | #080C14 | 背景（最も暗い） |
| celestialBlueLight | #0C1D3A | 背景（中間） |
| textPrimary | #EAEAEA | 主要テキスト |
| textSecondary | #ACACAC | 補助テキスト |
| glassFill | white 5% | ガラスパネル背景 |
| glassBorder | white 10% | ガラスパネル枠線 |

加えて:
- 4元素の色（火/水/風/地）: start/end/glow の3段階
- 10惑星の色: 太陽〜冥王星
- タロットスート色: ワンド/カップ/ソード/ペンタクル

### フォント (solara_theme.dart)

- 本文: DM Sans（Google Fonts）
- 見出し: Cormorant Garamond（HTML仕様、Flutterでは未適用の可能性あり）

---

## 外部パッケージ利用状況

| パッケージ | 使用場所 | 用途 |
|-----------|---------|------|
| flutter_map + latlong2 | map_screen.dart | 地図表示 |
| google_fonts | solara_theme.dart | フォント |
| shared_preferences | solara_storage.dart | データ永続化 |
| http | map_screen / sanctuary / map_astro / celestial_events / fortune_api / solara_api | Nominatim地名検索 + CF Worker全API |
| flutter_riverpod | **未使用** | pubspecに宣言のみ |
| riverpod_annotation | **未使用** | pubspecに宣言のみ |

---

## 独自ロジック（コアアルゴリズム）

### 月相計算 (moon_phase.dart)
- Jean Meeus "Astronomical Algorithms" Chapter 49 準拠
- 精度: ±2-3分
- 機能: 新月/満月の日時算出、月齢計算、サイクルID生成

### マップタイル切替 (map/map_styles.dart)
- 4プリセット: `osmHotLight` / `osmHotDark` / `cyclosmLight` / `cyclosmDark`
- タイル源: OpenStreetMap Humanitarian (OSM France) + CyclOSM (OSM France)
- Dark版: CSS `filter: invert(1) hue-rotate(180deg)` 相当の2段 ColorFiltered（白背景→黒、赤道路→赤保持）
- 永続化: `shared_preferences` キー `solara_map_style`
- 選択UI: LayerPanel の STYLE セクション
- 商用/アップデート計画: MapTiler独自スタイル（紫夜空テーマ）への移行予定（memory: project_solara_map_styles.md）

### Dominant Fortune Overlay (dominant_fortune_overlay.dart + fortune_overlays/)
- Map画面で1日最初のタップで発火する全画面演出（2.4秒）。今日のトップカテゴリに応じて5種を切替
- アーキテクチャ: `FortunePainterBuilder` 抽象クラス（`_common.dart`）を各カテゴリが継承。Builderは粒子データを initState で1回生成してキャッシュ、毎フレーム `buildPainter(t)` で CustomPainter を返す
- enum `DominantFortuneKind`: love / money / healing / communication / work
- Map本体 onTap → `_onMapTap()` → SharedPreferences `solara_overlay_shown_dominant_fortune_YYYY-MM-DD` でチェック → `DominantFortuneOverlay` を Stack 末尾に挿入
- 各カテゴリの演出方針:
  - **love**: 中心バースト+ハート放射 + ゴッドレイ + スパークル
  - **money**: 上から金貨/金箔が降ってきて画面下に22カラムで積み上がる（落ち物ゲーム風）
  - **healing**: 花びら降り + 上部オーロラ帯 + 光の粒（中心バーストなし）
  - **communication**: 水平光ストリーム + 浮上音符♪♫ + 光の粒（中心バーストなし）
  - **work**: 下から光の柱が立ち上がり + 上昇結晶 + 横切るスキャンライン（中心バーストなし）
- パフォーマンス: `MaskFilter.blur` 不使用（放射グラデで代替）、BlendMode.plus で加算発光
- デバッグフラグ（map_screen.dart 冒頭）:
  - `_debugAlwaysShowOverlay` = true で日付チェック無効化（本番は false）
  - `_debugCycleOverlayKinds` = true でタップ毎に5種を循環表示（本番は false）

### 星座名生成 (constellation_namer.dart)
- 20形容詞 × 61名詞 = 1,220ユニーク名（日英）
- MST（Primのアルゴリズム）で星座線を構築
- レアリティ: Common/Uncommon/Rare/Legendary/Mythic
- 61個のアンカー座標テンプレート

### 称号システム (title_data.dart)
- 太陽星座12 × 月星座12 × 5軸 × 5宮廷 = 多数の組み合わせ
- 光の称号（表）+ 影の称号（裏）

---

## 既知の課題

### ⚠️ Riverpod が未使用
pubspec.yaml に宣言されているが、コード内で一切使われていない。
- **選択肢A**: Riverpod を導入して状態管理を統一する（大規模リファクタ）
- **選択肢B**: Riverpod を pubspec から削除する（現状のsetState維持）
- **推奨**: リリース前はB（現状維持）。リリース後に画面間連携が複雑化したらA

### ⚠️ 画面ファイルが大きい（2026-04-21 時点）
全画面が分割済み。`tools/verify_code.py` で定期チェック。現状:

| ファイル | 行数 | 状態 |
|---------|-----:|------|
| lib/screens/map_screen.dart | 658 | WARN |
| lib/widgets/fortune_overlays/money_painter.dart | 633 | WARN |
| lib/widgets/fortune_overlays/work_painter.dart | 624 | WARN |
| lib/widgets/fortune_overlays/communication_painter.dart | 435 | OK |
| lib/widgets/fortune_overlays/healing_painter.dart | 426 | OK |
| lib/widgets/fortune_overlays/love_painter.dart | 320 | OK |
| lib/screens/galaxy_screen.dart | 840 | WARN |
| lib/screens/sanctuary_screen.dart | 811 | WARN |
| lib/screens/horoscope/horo_chart_painter.dart | 703 | WARN |
| lib/utils/constellation_namer.dart | 627 | WARN |
| lib/widgets/new_moon_overlay.dart | 603 | WARN |
| lib/widgets/catasterism_formation_overlay.dart | 586 | WARN |
| lib/screens/sanctuary/sanctuary_profile_editor.dart | 573 | WARN |
| lib/widgets/full_moon_overlay.dart | 511 | WARN |

500行未満に収めるのを目標に、機能追加時に分割する。

**直近の分割成果 (2026-04-21):**
- `dominant_fortune_overlay.dart` 639 → 85行ディスパッチャ + `fortune_overlays/` 配下6ファイル分割（5カテゴリ演出 + 共通ヘルパ）

**過去の分割成果:**
- `horoscope_screen.dart` 1053 → 409 + 4 part 分割
- `horo_bottom_panels.dart` 1283 → 14行バレル + 8 ファイル分割
- moon overlay 3ファイルから共通ロジック抽出 (`moon_overlay_shared.dart`) で各 ~130行削減

### ✅ CF Worker 本番稼働中 (2026-04-15)
Cloudflare Worker 本番デプロイ済み: `https://solara-api.solodev-lab.com`
(fallback: `https://solara-api.kojifo369.workers.dev`)

| エンドポイント | メソッド | 説明 | Flutter 呼出元 |
|---|---|---|---|
| `/health` | GET | ヘルスチェック | - |
| `/astro/chart` | POST | ネイタル/トランジット/プログレス計算 + アスペクト + パターン | `map_astro.dart#fetchChart` |
| `/astro/predict` | POST | 3ヶ月予測 | (未接続) |
| `/astro/events` | GET | 月別天体イベント (ingress/retrograde/eclipse) | `celestial_events.dart#fetchMonthEvents` |
| `/tz` | GET | 緯度経度→IANA TZ名 (C案, DST対応) | `solara_api.dart#fetchTimezoneName` |
| `/search` | GET | Nominatim placelookup proxy | (未接続) |
| `/fortune` | POST | Gemini 2.5 Flash 生成の占い文 (5カテゴリ) | `fortune_api.dart#fetchFortune` |

**Secrets (Cloudflare暗号化ストア):**
- `GEMINI_API_KEY` — Fortune LLM 生成用 (wrangler secret put で設定済み)

**Fortune 処理フロー:**
```
HoroscopeScreen._loadFortunes()
  → 5カテゴリ並列 fetchFortune()
  → Worker /fortune に chart + aspects + patterns 送信
  → Gemini 2.5 Flash (503時は 2.0 Flash fallback) でJSON生成
  → { reading, advice, direction, score } を返却
  → HoroAstrologyView で表示 (loading/error/retry対応)
```

**Timezone (C案) 処理フロー:**
```
Sanctuary Profile Editor で出生地選択
  → lat/lng 確定
  → fetchTimezoneName() で /tz 呼出
  → IANA TZ名 (例: Asia/Tokyo) を birthTzName に保存
  → fetchChart 時 birthTzName を送信
  → Worker側 Intl.DateTimeFormat で DST自動考慮の UTC変換
```

### ⚠️ GlobalKey による画面間通信
HoroscopeScreenState が public で、GlobalKey 経由で外部からメソッドを呼んでいる。
- Riverpod 導入時にこのパターンを解消する
- 現状は動いているのでリリース前は触らない

### Tarot 占卓シーン (observe/tarot_altar_scene.dart)
Tarot Draw 画面の背景。Stack 5 レイヤー構成:
```
① 深宇宙 RadialGradient
② 占卓画像 (assets/tarot_scene/altar.png, 1024×1024、contain配置)
③ 影レイヤー (5惑星の影、真下 + 中央方向バイアス)
③ 惑星レイヤー (5惑星、自転WebP + ふわふわ浮遊、Sun は3層パルスblaze)
④ 流れ星 (20-90秒間隔、左上→右下 or 右上→左下、600ms)
⑤ 前景 (タブ/カード/パネル、widget.child)
```
- 影 = 「真下 +0.6×size」基準 +「南成分で上へ-0.4×size」+「東西成分で反対側へ-0.25×size」
- 占卓の 12 ハウス ローマ数字は **画像に焼き込み済み**（Python スクリプトで合成）
- 惑星自転 WebP は `mockup/generate_planet_rotations.py` で生成（equirectangularテクスチャ→球体マッピング）

### i18n / Localizations
`MaterialApp` に `flutter_localizations` の delegate 3種を必ず指定する:
```dart
localizationsDelegates: const [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
],
```
これが無いと `locale: Locale('ja')` 指定時に TextField 等が
`No MaterialLocalizations found` でレンダリング失敗する。

---

## 画像生成・後処理スクリプト (apps/solara/mockup/)

全て Gemini 3.1 Flash Image を使用、`.env` の `GEMINI_API_KEY` を読み込み:

| スクリプト | 用途 |
|---|---|
| `generate_tarot_altar.py` | 占卓背景（1024×1024 1:1、45°斜め見下ろし） |
| `generate_tarot_planets.py` | 10惑星静止画 (1:1) |
| `generate_planet_textures.py` | equirectangularテクスチャマップ (2:1) |
| `generate_planet_rotations.py` | 自転WebPアニメ（NumPy球体マッピング、60フレーム/6秒ループ） |
| `generate_tarot_shooting_stars.py` | 流れ星3種 (16:9) |
| `alpha_from_black.py` | 惑星透明化（楕円マスク、Saturnのみ楕円×輝度合成） |
| `alpha_shooting_star.py` | 流れ星透明化（輝度ベース） |
| `draw_house_numerals_on_altar.py` | 占卓画像にローマ数字を焼き込む（Pillow） |
| `backup_util.py` | `--force` 上書き前の自動バックアップユーティリティ |
| `snapshot_tarot_scene.py` | 現在のアセットをまとめて `_backup/<timestamp>/` に退避 |

全生成スクリプトは `--force` 実行時に既存ファイルを `_backup/<timestamp>_<name>` に退避してから上書きする（CLAUDE.md の元絵保護ルール準拠）。

---

## コード検証ツール

```
cd apps/solara
python tools/verify_code.py
```

チェック内容:
1. ファイル行数（500行超で WARN、900行超で CRIT）
2. 未使用 import（ヒューリスティック、false-positive あり）
3. print/debugPrint 残り
4. TODO/FIXME/XXX
5. 未使用 private シンボル

Flutter 標準の静的解析は `flutter analyze` で行う。

---

## 新機能追加時のルール

### 新しい画面を追加する場合
1. `lib/screens/` に `xxx_screen.dart` を作成
2. `StatefulWidget` で作る（現状のパターンに合わせる）
3. `main.dart` の IndexedStack に追加
4. `SolaraNavBar` にタブを追加
5. この `architecture.md` を更新する

### 新しいデータを保存する場合
1. `SolaraStorage` に新しいキーとメソッドを追加
2. `data_schema.md` にスキーマを記録
3. マイグレーションが必要な場合は `schema_version` を上げる

### 新しい外部APIを追加する場合
1. `security.md` のチェックリストを確認
2. APIキーはCF Worker経由で使う（Flutterにハードコードしない）
3. `data_schema.md` のAPI一覧に追記
