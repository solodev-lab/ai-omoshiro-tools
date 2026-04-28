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
│   ├── map_screen.dart       世界地図・運勢方位（メイン、Phase M2 完成版 967 行）
│   │                           Phase M2 でアスペクト線 (40本) + 引越しレイヤー追加
│   ├── map/                  ← Map サブウィジェット
│   │   ├── map_vp_panel.dart, map_astro.dart, map_fortune_sheet.dart
│   │   ├── map_planet_lines.dart, map_sectors.dart, map_stella.dart
│   │   ├── map_constants.dart, map_widgets.dart
│   │   ├── map_layer_panel.dart        Phase M2: 4流派並列 (16方位/惑星ライン/引越し/アスペクト) + i アイコン
│   │   ├── map_astro_lines.dart        Phase M2: アスペクト線 Polyline 変換 (FORTUNE 連動 dim)
│   │   ├── map_relocation_popup.dart   Phase M2: 統合タップ popup (線情報+12ハウス情報)
│   │   ├── map_styles.dart             タイル切替（OSM/CyclOSM × Light/Dark）
│   │   ├── map_search.dart             検索候補リスト + SearchFocusPopup (C-2: 保存ボタン削除済)
│   │   ├── map_astro_carto.dart        Phase M3: Astro*Carto*Graphy モード専用UI (Banner/Pills/ZenithPopup)
│   │   ├── map_location_markers.dart   Tier A: 出生地🌟+グロー / VP・Locations slot マーカー / 詳細popup
│   │   └── map_overlays.dart           SideButtons/SearchBar/Badges/VP Pin/RestOverlay 等
│   ├── locations_screen.dart   拠点一覧画面（Map 🗺ボタンから BottomSheet）
│   ├── forecast_screen.dart    1〜5年 Forecast（Map 🔮ボタンから BottomSheet、ヒートマップ+◯◯期+Top5）
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
│   │   ├── horo_planet_table.dart     HoroPlanetTable (ハウス番号列付き)
│   │   ├── horo_relocation_panel.dart リロケーション解説パネル (出生地↔現住所比較)
│   │   ├── horo_relocation_templates.dart (惑星×ハウス) 120 + ASC/MC×星座 24 テンプレート
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
│   ├── fortune_api.dart         Fortune API呼び出し（Gemini占い文 + リロケーション解説）
│   ├── moon_phase.dart          月相計算（Jean Meeusアルゴリズム）
│   ├── constellation_namer.dart 星座名生成・MST構築
│   ├── celestial_events.dart    天体イベント読み込み（API+キャッシュ+静的JSON）
│   ├── celestial_event_meanings.dart  天体イベント占星術的意味辞書（JP/EN）
│   ├── cycle_story_texts.dart   月齢サイクルストーリーテキスト（JP/EN）
│   ├── tarot_data.dart          タロットデータ読み込み
│   ├── title_data.dart          称号システム
│   ├── app_locale.dart          言語切替（端末設定/JP/EN）グローバル Singleton
│   ├── astro_houses.dart        Phase M2: LST/ASC/MC/Placidus を Dart で完結 (Worker同等)
│   ├── astro_lines.dart         Phase M2: 40本アスペクト線計算 (球面三角法 + 近接線検出)
│   └── astro_glossary.dart      Phase M2: 占星術用語辞書 (i アイコン popup 用)
└── widgets/               ← 共通ウィジェット
    ├── solara_nav_bar.dart          ボトムナビゲーション
    ├── glass_panel.dart             フロストガラスパネル
    ├── astro_term_label.dart        Phase M2: 占星術用語の i アイコン + 解説 popup ラベル
    ├── moon_overlay.dart            re-export (下記3ファイル)
    ├── moon_overlay_shared.dart     mysticalMoonBackdrop + MoonScrollingStory (共通)
    ├── new_moon_overlay.dart        新月: ストーリー→テーマ選択→リビール演出+Set Intention
    ├── full_moon_overlay.dart       満月: ストーリー→3段階評価→リビール演出+自動確定
    ├── catasterism_overlay.dart     刻星化: ストーリー→手放せた/途中→発光+余韻+遷移
    ├── catasterism_formation_overlay.dart  刻星化アニメーション（4ステージ）
    ├── celestial_event_bar.dart     天体イベント横スクロールバー
    ├── dominant_fortune_overlay.dart ディスパッチャ: 5カテゴリ演出を enum で切替
    ├── omen_button.dart             Daily Omen Button: 呼吸する金縁＋タイトル/サブ/CTA
    ├── fortune_overlays/            ← 5カテゴリの全画面演出（Omen Button タップで発火）
    │   ├── _common.dart                FortunePainterBuilder 抽象 + easing/stageAlpha 共有
    │   ├── love_painter.dart           恋愛（Solara風）: 薔薇花弁放射 + 中央の金魔法陣 + 金の蔦
    │   ├── money_painter.dart          金運（Solara風）: 錬金術刻印のアンティーク金貨/金箔積み上げ
    │   ├── healing_painter.dart        癒し（Solara風）: 月桂樹/ヒスイの葉が螺旋で舞い上がる
    │   ├── communication_painter.dart  話す（Solara風）: ルーン/惑星記号ペア + 金の衝突魔法陣
    │   └── work_painter.dart           仕事（Solara風）: 金の勲章が歯車背景で漂い、中央収束→閃光→紋章
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

### 方位スコア計算 (map/map_astro.dart `scoreAll`)
- 入力: `ChartResult` (natal/transit/progressed 10天体 + asc/mc/dsc/ic)
- **4種のアスペクトペアから weight で寄与計算**:
  - `tt`（Transit×Transit）×1.0（両側加算）
  - `tn`（Transit×Natal）×0.6 + angle bonus（ASC/DSC=1.5, MC/IC=1.3）
  - `pn`（Progressed×Natal）×0.5 + angle bonus
  - `tp`（Transit×Progressed）×0.4（**両側加算 — 2026-04-21 対称化**）
- **quality → バケット分配** (`_qSplit`):
  - soft → `Soft` 全額 / hard·tense → `Hard` 全額
  - **neutral**（conjunction） → **Soft/Hard 半々**（2026-04-21 変更）
- **16方位への分配** (`_cosFall`):
  - **spread = 22.5°**（2026-04-21 30°→22.5° 変更）
  - 16方位間隔と一致 → Σf ≡ 1.0 の partition of unity が成立
  - Hann窓（コサイン窓）で各天体の黄経を中心にベル型分配
- 出力: `sScores[dir]` / `sComp[dir][bucket]` / カテゴリ別 `fScores[cat][dir]` / ドミナント `sFortune[dir]`
- 運勢方位シートの「合計/トランジット/プログレス」タブは `sComp` の4バケットからのバケット合算フィルタ

### マップタイル切替 (map/map_styles.dart)
- 4プリセット: `osmHotLight` / `osmHotDark` / `cyclosmLight` / `cyclosmDark`
- タイル源: OpenStreetMap Humanitarian (OSM France) + CyclOSM (OSM France)
- Dark版: CSS `filter: invert(1) hue-rotate(180deg)` 相当の2段 ColorFiltered（白背景→黒、赤道路→赤保持）
- 永続化: `shared_preferences` キー `solara_map_style`
- 選択UI: LayerPanel の STYLE セクション
- 商用/アップデート計画: MapTiler独自スタイル（紫夜空テーマ）への移行予定（memory: project_solara_map_styles.md）

### Daily Omen Button + Dominant Fortune Overlay
Map画面を開くと、1日1回「今日のタップボタン」（Daily Omen Button）が浮かぶ。タップすると当日のホロスコープ最高スコアカテゴリの全画面演出（4.0秒）が発動する。

- **表示判定** (`_checkOmenVisibility`):
  1. `_topCategory` が算出済みか（ホロスコープ最高スコア）
  2. SharedPreferences `solara_overlay_shown_dominant_fortune_YYYY-MM-DD` が未セットか（リセット時刻考慮）
  - 両方満たせば `OmenButton` を画面下に表示
- **ボタン** (`widgets/omen_button.dart`): 深紫藍パネル＋金縁＋呼吸グロー（2.8秒cycle）
- **ランダム文言** (`utils/omen_phrases.dart`): 10個の `(title, sub, cta)` からランダム1つ選出。`pickRandomOmenPhrase()`
- **発火** (`_onOmenTap`): `DominantFortuneOverlay` を Stack 末尾に挿入＋`markOverlayShown`
- **enum** `DominantFortuneKind`: love / money / healing / communication / work
- **Painter アーキテクチャ**: `FortunePainterBuilder` 抽象（`_common.dart`）を各カテゴリが継承。Builderは粒子データを initState で1回生成してキャッシュ、毎フレーム `buildPainter(t)` で CustomPainter を返す
- **Solara世界観に統一**（全5カテゴリ刷新済み、2026-04-21〜22）:
  - **love**: 薔薇花弁放射＋中央の金の魔法陣＋金の蔦7本＋ワイン/ローズゴールド
  - **money**: 錬金術シンボル刻印コイン＋羊皮紙セピア背景＋アンティーク金
  - **healing**: 月桂樹/オリーブの葉が螺旋上昇＋月光銀霧＋象牙/ヒスイ/深緑
  - **communication**: ルーン＋惑星記号のペアが自由軌道で漂い、触れ合って金の六芒星魔法陣が灯る
  - **work**: 背景に真鍮歯車3個＋金の勲章medallion20個が中央収束→白閃光→波紋リング3本→金八芒星紋章
- 共通: VS-15＋serif で占星術/惑星記号の絵文字フォント置換を抑止
- パフォーマンス: `MaskFilter.blur` 不使用（放射グラデで代替）、BlendMode.plus で加算発光
- **1日の区切り時刻** (`SolaraStorage.loadDailyResetHour` / `_logicalTodayKey`): Sanctuary 画面で 0-23時を設定可能。リセット時刻未満なら前日扱いの日付キーで判定
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

### リロケーション (Phase M0, 2026-04-25)
**古典的リロケーションチャート**: natal惑星位置は固定したまま、ハウスだけ現住所(`homeLat/Lng`)で再計算する。
- **Worker側** (`worker/src/astro.js` `computeChart`): `relocateLat`/`relocateLng` パラメータ追加。指定時は ASC/MC/houses だけ relocate座標で計算、natal惑星位置は出生地ベース不変。
- **Dart側** (`lib/screens/map/map_astro.dart` `fetchChart`): `relocateLat`/`relocateLng` 引数追加、`0/0` は未指定扱い。
- **デフォルト挙動**: home登録ありなら **現住所ハウスを運用チャート**として使う（古典派の標準）。Map / Locations は内部 relocate 反映のみ（UIトグル無し）。
- **Horoscope画面のトグル** (本質/現実):
  - 1重円NATAL / 2重円N+T / 2重円N+P: 表示・尊重
  - 星読みモード: 非表示・現実固定
- **リロケーション解説パネル** (`horo_relocation_panel.dart`):
  - 1重円+home有効時のみ表示。Bottom Sheet 「拠点」タブ。
  - 静的テンプレート (`horo_relocation_templates.dart`): 惑星×ハウス 120個 + ASC/MC×星座 24個。Phase B で Gemini 動的生成へ移行予定。
  - ASC・MC・10惑星すべて表示（変化なしも dim styling で含める）。
  - 出生地/現住所の意味を **2行並列で比較表示**。
- **並列fetch**: 1重円+home時のみ natal/relocate 2チャートを並列取得（パネル比較用）。他モードは単一fetch。

### アストロカートグラフィ (Phase M2, 2026-04-27)
**真のアストロカートグラフィ**を Dart 側で完結。地図タップで <50ms 即応。

**核心: Dart 完結ハウス計算** (`lib/utils/astro_houses.dart`):
- Worker `calcHousesPlacidus` / `calcAscendant` / `calcMC` を Dart 移植 (210 行)
- **LST 復元戦略**: `chart.mc` から `RA(MC)=LST_baseline` を逆算し、UTC再構築/DST補正を完全回避
  - `LST_tap = LST_baseline + (tapLng - baselineLng)` の単純加算で任意座標の LST を取得
- 検証: Worker `/astro/chart` の relocate 結果と全6ペアで最大誤差 0.0122° (`worker/verify_phase_m2.py`)

**40本アスペクト線** (`lib/utils/astro_lines.dart`):
- 各惑星 (10) × 4アングル (ASC/MC/DSC/IC) = 40本のラインを地球曲面上に計算 (球面三角法)
- MC line: `lng = α - GMST*15` 縦直線。IC line: 経度180°シフト。
- ASC line: `cos(H) = -tan(δ)·tan(φ)` を緯度ごとに解いて経度導出。DSC: 西半球版。
- 画面pixel距離による近接線検出 (`findNearbyLinesScreen`、閾値 20px、Tier A #3)
  - flutter_map `camera.latLngToScreenOffset` を projector に渡し点-線分(Euclidean)距離で計測
  - 子午線跨ぎ対策: 隣接2点が画面幅(4096px)以上離れた線分は skip
  - 通常Map / Astro\*Carto\*Graphy モード共通で全ズームに一貫した感覚
- 検証: Worker と全80ケースで最大誤差 0.01° (`worker/verify_astro_lines.py`)
- ヒットテスト検証: 11/11 pass (`worker/verify_astro_line_hittest.py`)

**LayerPanel 4流派並列** (`lib/screens/map/map_layer_panel.dart`):
- ASTRO セクション: 16方位 / 惑星ライン / 引越し / アスペクト線
- 各トグルに用語解説 i アイコン (グラスモーフィズム popup, `astro_glossary` 連携)
- `planetLines` メタトグルで CHART (natal/progressed/transit) サブメニュー表示制御

**統合タップ popup** (`lib/screens/map/map_relocation_popup.dart`):
- aspect ON & 線が近い → 線セクション表示 (惑星グリフ + アングル + 距離)
- relocate ON → ASC/MC + 12ハウス再配置 + 比較ベース (home優先・出生地fallback)
- 両方ON & 線あり → 統合表示

**戦略観点**: 英語版 (海外展開) で本機能がメインフィーチャー予定。日本市場では β機能扱い (デフォルトOFF, 論点8)。Phase M3 で L10N + 動的解釈テキスト + パワースポット (線交差点) 検出を追加予定。

### 登録地マーカー (Tier A 補助、2026-04-28)
**全モード共通の登録地ピン** (`lib/screens/map/map_location_markers.dart`):
- 出生地 🌟 (BirthMarker、20px円 + 多層グロー + 2.4秒呼吸パルス) — 「個性の源」を視覚的に強調
- VPSlot (VIEWPOINT・Locations、25px円 + 各 slot.icon 絵文字) — `FittedBox` で円内自動拡大
- レイヤー優先順位 (上→下): 出生地 → VP slots (上位先) → Locations slots (下位最後)
  - flutter_map MarkerLayer は list 順描画 (先頭=下) のため、build側で逆順積み
- 全マーカーに tap → 名前+座標 popup (`LocationMarkerPopup`)
- マーカー自身のサイズは `Center` でラップして flutter_map Marker の tight constraints を解放
- syncHome で home が両 SlotManager 先頭に同期 (重複表示は許容、オーナー判断)

**検索保存フロー統一 (C-2 案、2026-04-28)**:
- 検索 popup から「📌 拠点として登録」ボタン削除 → 「✈ ここへ移動」のみ残す
- 保存は VP/Loc パネル「この地点を保存」「この地点を登録」に集約
- 検索中 (`_searchFocus != null`) はパネルに渡す `center` を検索地に切替
  - `center: _searchFocus != null ? LatLng(_searchFocus.lat, _searchFocus.lng) : _center`
  - VP Pin 自体は `_center` (不動)、保存対象だけ検索地優先
- 副次効果: パネルの座標表示・現在地ハイライトも検索地基準に変わる

**Nominatim 逆引き優先順位修正 (2026-04-28)**:
- `SlotManager.saveCurrentLocation` の名称取得を `city > town > village > suburb > neighbourhood` に変更
- 旧: `suburb` 最優先で OSM の道路ループ等局所タグを拾い "Loop" 等を返していた
- 新: 都市名最優先で「ニューヨーク」「東京」等の認識可能な名称に

---

## 既知の課題

### ⚠️ Riverpod が未使用
pubspec.yaml に宣言されているが、コード内で一切使われていない。
- **選択肢A**: Riverpod を導入して状態管理を統一する（大規模リファクタ）
- **選択肢B**: Riverpod を pubspec から削除する（現状のsetState維持）
- **推奨**: リリース前はB（現状維持）。リリース後に画面間連携が複雑化したらA

### ⚠️ 画面ファイルが大きい（2026-04-22 時点）
全画面が分割済み。`tools/verify_code.py` で定期チェック。現状:

| ファイル | 行数 | 状態 |
|---------|-----:|------|
| lib/widgets/fortune_overlays/work_painter.dart | 758 | WARN |
| lib/widgets/fortune_overlays/money_painter.dart | 696 | WARN |
| lib/widgets/fortune_overlays/communication_painter.dart | 642 | WARN |
| lib/widgets/fortune_overlays/love_painter.dart | 581 | WARN |
| lib/widgets/fortune_overlays/healing_painter.dart | 498 | OK |
| lib/widgets/omen_button.dart | 115 | OK |
| lib/utils/omen_phrases.dart | 73 | OK |
| lib/screens/map_screen.dart | 803 | WARN (Phase 1 で 1123→803 へ削減、これ以上の分割はUI凝集度低下のため停止) |
| lib/screens/forecast_screen.dart | 720 | WARN (1画面内の機能密度が高いため許容) |
| lib/screens/locations_screen.dart | 290 | OK |
| lib/screens/map/map_overlays.dart | 349 | OK (Phase 1 で新設、SideButtons/SearchBar/Badges/VP Pin 等を集約) |
| lib/screens/map/map_search.dart | 360 | OK (Phase 1 で新設、検索候補リスト + SearchFocusPopup) |
| lib/utils/forecast_cache.dart | 280 | OK (Phase 1 で新設、キャッシュ+◯◯期検出) |
| apps/solara/worker/src/astro.js | 870 | WARN (天体計算+Forecast、分割は必要性低) |
| lib/screens/sanctuary_screen.dart | 837 | WARN |
| lib/screens/sanctuary/sanctuary_reset_hour_picker.dart | 118 | OK |
| lib/screens/galaxy_screen.dart | 840 | WARN |
| lib/screens/horoscope/horo_chart_painter.dart | 703 | WARN |
| lib/utils/constellation_namer.dart | 627 | WARN |
| lib/widgets/new_moon_overlay.dart | 603 | WARN |
| lib/widgets/catasterism_formation_overlay.dart | 586 | WARN |
| lib/screens/sanctuary/sanctuary_profile_editor.dart | 573 | WARN |
| lib/widgets/full_moon_overlay.dart | 511 | WARN |

500行未満に収めるのを目標に、機能追加時に分割する。fortune_overlays は 1painter = 1 file に揃える設計のため、各 painter が data classes + 描画ロジックを内包して 500〜800行になるのは意図的。

**直近の分割成果 (2026-04-22):**

**Phase 1 最終（Map Feature 2〜5 + Forecast + 5年対応）:**
- map_screen.dart: **1123 → 803 行（320 行削減、28%）**
- `map/map_overlays.dart` 新規: `MapSideButtons` / `SearchBarOverlay` / `SelectedDateBadge` / `StatusBadge` / `SeedBadge` / `VpPinVisual` / `buildVpPinMarker()` / `FortunePullTab` / `RestOverlay` / `PreseedHint` / `showSolaraDatePicker()` を集約
- `map/map_search.dart` 拡張: `SearchHit` / `searchPlaces()` / `SearchResultList` / `SearchFocusPopup`（選択後の詳細カード・_activeSrc連動）
- `forecast_screen.dart` 新規: ヒートマップ3モード(相対/絶対/カテゴリ) + 色方向トグル(🟢↑高/🔴↑高) + 1〜5年範囲 + ◯◯期検出 + Top5総合/5カテゴリ
- `locations_screen.dart` 新規: 拠点一覧（スコア棒 + カテゴリ色 + 距離表示）
- `utils/forecast_cache.dart` 新規: ForecastDay/ForecastCache/ForecastRepo + `detectLifePeriods()`
- Worker `astro.js`: `computeForecast()` + `scoreOneDate()` 追加（Flutter と完全同ロジック）
- Worker `index.js`: per-endpoint Rate Limit (forecast=6/min) + KV 月次クォータ(60req/month)

**Phase 1 中盤:**
- `_OmenButton` (map_screen内 private class ~115行) → `widgets/omen_button.dart` に分離、public 化
- `_DailyResetHourPicker` (sanctuary_screen内 private class ~110行) → `sanctuary/sanctuary_reset_hour_picker.dart` に分離、public 化
- `utils/omen_phrases.dart` 新規（10フレーズ＋ランダム選出）

**分割成果 (2026-04-21):**
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
| `/tiles/jawg/<style>/<z>/<x>/<y>.png?lang=xx` | GET | Jawg Maps タイルプロキシ（トークン秘匿・多言語ラベル）| `map_styles.dart`, `map_hybrid_provider.dart` |

**Secrets (Cloudflare暗号化ストア):**
- `GEMINI_API_KEY` — Fortune LLM 生成用 (wrangler secret put で設定済み)
- `JAWG_TOKEN` — Jawg Maps タイルアクセス用 (2026-04-22 追加)

**Worker URL 単一情報源ルール（2026-04-23 確立）:**
アプリ内で Worker を参照する全ての Dart ファイルは、
`lib/utils/solara_api.dart` の `solaraWorkerBase` 定数を import して参照すること。
ハードコード禁止（過去バグ: `solodev-lab.workers.dev` という存在しないサブドメインが
複数ファイルに散在してサイレント失敗していた）。

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
python tools/verify_code.py           # 総合チェック（既存）
python tools/check_file_split.py      # ファイル分割の健全性（300行 WARN / 500行 CRIT）
python tools/check_unused.py          # map/ 配下の未使用シンボル検出
```

### verify_code.py (総合)
1. ファイル行数（500行超で WARN、900行超で CRIT）
2. 未使用 import（ヒューリスティック、false-positive あり）
3. print/debugPrint 残り
4. TODO/FIXME/XXX
5. 未使用 private シンボル

### check_file_split.py (責務分離)
- lib/ 全体の各ファイル行数・クラス数・import数を一覧表示
- 300行超で WARN、500行超で CRIT を出してファイル分割判断に使う
- 末尾に `map/` 配下のみのサマリーを出す

### check_unused.py (未使用シンボル)
- map/ 配下の public 関数・クラス・定数を lib/ 全体で grep
- 定義ファイル以外で参照ゼロの場合「未使用候補」として報告
- 動的解決（Map lookup等）は誤検知することに注意

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
