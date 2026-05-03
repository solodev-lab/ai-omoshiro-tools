# Solara アーキテクチャ

> アプリ全体の構造と設計方針。
> 新しい画面や機能を追加する時はこのファイルを確認する。
> 2026-04-29 更新: F1-c (Daily Transit) + Phase E1-E8 (Soft/Hard 設計思想) 反映。
> 2026-04-30 更新: Tier S #2 ライン narrative + Daily Transit フィルタ/VP切替 + 検索 Google Places + tile fd 対策。
> 2026-05-03 更新: Phase 1 saveLayer leak 撤去 (Critical 30→5、CPU 半減、Jank 5x 改善)、Impeller off で fd leak 解消。
> 2026-05-04 更新: 5/1 メモ機能修正 9 + UX 修正 5 + 3-1 ミニマップ + Daily Transit i ボタンカテゴリ別 (詳細は末尾)。

---

## 設計思想（最優先）

> 詳細: `memory/project_solara_design_philosophy.md`

- **ソフト/ハードは独立した別エネルギー**（1軸の両端ではない）
- **占い的吉凶判定をしない**（「ラッキー/アンラッキー」は出さない）
- **両面思想**（陰陽・Jungian）
- **実装禁止**: `total = soft + hard` 合算 / `softRatio` / 赤=悪 緑=良 色分け
- **実装すべき**: `DirectionEnergy { soft, hard }` 独立2軸 / 銀月色（ソフト）+ 金陽色（ハード）

---

## 全体構成

```
lib/ (約 80 .dart ファイル)
├── main.dart              ← アプリ起点。IndexedStackで5画面を管理
├── models/                ← データクラス
│   ├── daily_reading.dart    デイリーリーディング
│   ├── galaxy_cycle.dart     銀河サイクル・星座ドット
│   ├── lunar_intention.dart  月の意図・中間チェック・刻星化
│   └── tarot_card.dart       タロットカード
├── screens/               ← 各画面
│   ├── map_screen.dart       世界地図・運勢方位（メイン、約 1480 行）
│   │                           Phase M2: アスペクト線(40本) + 引越しレイヤー
│   │                           F1-c (2026-04-29): DailyTransitBadge + フルUI 統合
│   ├── solara_philosophy_screen.dart  Phase E5 (2026-04-29): 設計思想ガイド画面
│   ├── map/                  ← Map サブウィジェット
│   │   ├── map_vp_panel.dart, map_astro.dart, map_fortune_sheet.dart
│   │   ├── map_planet_lines.dart, map_sectors.dart, map_stella.dart
│   │   ├── map_constants.dart, map_widgets.dart
│   │   ├── map_layer_panel.dart        Phase M2: 4流派並列 + 設計思想ガイド導線
│   │   ├── map_astro_lines.dart        Phase M2: アスペクト線 Polyline 変換 (FORTUNE 連動 dim)
│   │   ├── map_relocation_popup.dart   Phase M2: 統合タップ popup (線情報+12ハウス情報)
│   │   ├── map_styles.dart             タイル切替（OSM/CyclOSM × Light/Dark）
│   │   ├── map_search.dart             検索候補リスト + SearchFocusPopup
│   │   ├── map_astro_carto.dart        Phase M3: Astro*Carto*Graphy モード専用UI
│   │   ├── map_location_markers.dart   Tier A: 出生地+グロー / VP/Locations マーカー
│   │   ├── map_time_slider.dart        Tier A #5 (CCG): ±365日 + 時刻スライダー
│   │   ├── map_direction_popup.dart    E4 (2026-04-29): セクタータップ詳細 popup
│   │   │                                  (2エネルギー独立バー + アスペクト attribution)
│   │   ├── map_aspect_chip.dart        F1-c (2026-04-29): MapAspectChip
│   │   │                                  Daily Transit V2 のアスペクトチップ
│   │   │                                  タップで Horo 相タブ同等の詳細を表示
│   │   ├── map_daily_transit_screen.dart  F1-c (2026-04-29): Daily Transit フルUI
│   │   │                                  ヘッダ(カテゴリ + VP切替) + 本日/明日タブ
│   │   │                                  + アングル/カテゴリフィルタ + タイムライン
│   │   │                                  2026-04-30: VIEWPOINT切替 + フィルタ + i Dialog
│   │   ├── daily_transit_data.dart      2026-04-30 分割: AngleFilter + tips/baseText/appendix
│   │   │                                  10惑星 × 4アングル = 40パターン基本意味
│   │   │                                  5カテゴリ × 2相 = 10パターン行動指針
│   │   ├── map_line_narrative_sheet.dart  Tier S #2 (2026-04-30): A*C*G ライン詳細シート
│   │   │                                  静的辞書 → 「詳しく読む」→ Soft/Hard別表示
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
│   ├── solara_storage.dart      SharedPreferencesラッパー (orb設定読込ヘルパー追加)
│   ├── solara_api.dart          CF Worker API呼び出し（TZ取得）
│   ├── fortune_api.dart         Fortune API呼び出し（Gemini占い文 + リロケーション解説）
│   ├── daily_transits_api.dart  F1-b (2026-04-29): /astro/daily-transits 呼び出し
│   │                              TransitEvent / TransitAspect / DailyTransitsResult
│   ├── direction_energy.dart    E1/E3 (2026-04-29): Soft/Hard 独立2エネルギー
│   │                              DirectionEnergy + AspectContribution + 集約ヘルパー
│   ├── solara_manifesto.dart    E0 (2026-04-29): 設計思想マニフェスト（JP/EN）
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
│   ├── astro_glossary.dart      Phase M2: 占星術用語辞書 (i アイコン popup 用)
│   │                              E6 (2026-04-29): 文言全面書き直し + 'two_energies' /
│   │                              'soft_aspect' / 'hard_aspect' / 'transit_angles' /
│   │                              'top_category_logic' エントリ追加
│   │                              2026-04-30: 'category_tips_intent' 追加 +
│   │                              Dialog スクロール対応 (overflow防止)
│   ├── line_narrative_api.dart  Tier S #2 (2026-04-30): /astro/line-narrative
│   │                              呼出 + LRU キャッシュ (max 100, lat/lng 0.1° 丸め)
│   └── tile_http_client.dart    2026-04-30: タイル取得用 共有 HttpClient
│                                  fd 枯渇対策 (maxConnectionsPerHost=6, idleTimeout=15s)
└── widgets/               ← 共通ウィジェット
    ├── solara_nav_bar.dart          ボトムナビゲーション
    ├── glass_panel.dart             フロストガラスパネル
    ├── astro_term_label.dart        Phase M2: 用語ラベル + i アイコン (16px / タップ領域32px)
    ├── daily_transit_badge.dart     F1-c (2026-04-29): Map右上の日次トリガー
    │                                  リセット時刻後初回=光る、閲覧済み=カテゴリアイコン
    ├── category_icon.dart           E8.1 (2026-04-29): 6カテゴリベクターアイコン
    │                                  Style D = 惑星シンボル + 装飾線 (CustomPainter)
    │                                  all/love/money/work/healing/communication
    ├── moon_overlay.dart            re-export (下記3ファイル)
    ├── moon_overlay_shared.dart     mysticalMoonBackdrop + MoonScrollingStory (共通)
    ├── new_moon_overlay.dart        新月: ストーリー→テーマ選択→リビール演出+Set Intention
    ├── full_moon_overlay.dart       満月: ストーリー→3段階評価→リビール演出+自動確定
    ├── catasterism_overlay.dart     刻星化: ストーリー→手放せた/途中→発光+余韻+遷移
    ├── catasterism_formation_overlay.dart  刻星化アニメーション（4ステージ）
    ├── celestial_event_bar.dart     天体イベント横スクロールバー
    ├── dominant_fortune_overlay.dart ディスパッチャ: 5カテゴリ演出を enum で切替
    ├── fortune_overlays/            ← 5カテゴリの全画面演出（DailyTransitBadge タップで発火）
    │   ├── _common.dart                FortunePainterBuilder 抽象 + easing/stageAlpha 共有
    │   ├── love_painter.dart           恋愛（Solara風）: 薔薇花弁放射 + 中央の金魔法陣 + 金の蔦
    │   ├── money_painter.dart          豊かさ（Solara風）: 錬金術刻印のアンティーク金貨/金箔積み上げ
    │   ├── healing_painter.dart        癒し（Solara風）: 月桂樹/ヒスイの葉が螺旋で舞い上がる
    │   ├── communication_painter.dart  話す（Solara風）: ルーン/惑星記号ペア + 金の衝突魔法陣
    │   └── work_painter.dart           仕事（Solara風）: 金の勲章が歯車背景で漂い、中央収束→閃光→紋章
    ├── nav_icons.dart               ナビアイコン（CustomPainter x5）
    ├── constellation_painter.dart   星座描画（screen合成）
    ├── cycle_spiral_painter.dart    サイクルスパイラル描画
    └── spiral_painter.dart          スパイラル描画
```

### 2026-04-29 セッションでの削除ファイル
- `lib/widgets/omen_button.dart`     — DailyTransitBadge に置換
- `lib/utils/omen_phrases.dart`      — 固定文言「今日の惑星からのエネルギーを確認する」に置換
- (Preseed / PreseedHint / SeedBadge クラスも内部で削除)

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

### CCG (Cyclo*Carto*Graphy) — Tier A #5 (2026-04-28)
**動的フレーム4種を独立トグル可能に拡張** (`lib/utils/astro_lines.dart` + 関連)。

**フレーム定義** (`AstroFrame` enum):
- **Natal**:      出生時固定 (一生不変、本質の地図) — 既存 buildAstroLines
- **Transit**:    今この瞬間の天体位置 (毎日動く、CCG の核) — `chart.transit` を Worker 取得
- **Progressed**: 2次進行 (1日=1年、人生の長期テーマ) — `chart.progressed` を Worker 取得
- **Solar Arc**:  全惑星に同 arc (= prog.sun − natal.sun) 加算した古典予測法 — クライアント側で導出

**汎用ビルダ** (`buildAstroLinesAt`):
- `(planets, gmstHours, frame)` を受けて40本生成。natal/transit/progressed/solarArc 共通路。
- GMST 取得経路は2系統:
  - natal: `_gmstHoursFromBaseline(chart.mc, baselineLng)` (既存・出生時GMST逆算)
  - dynamic: `gmstHoursFromUtc(viewDate.toUtc())` (USNO線形公式、Worker `Astronomy.SiderealTime` と <0.6秒誤差)
- 動的3フレームは同一 `viewGmst` (= タイムスライダー位置) で投影 → 「今(or指定時刻)の天体を世界に映す」標準解釈

**Solar Arc 算術** (`solarArcPlanets`):
- arc = (prog.sun − natal.sun) mod 360
- 全惑星に同 arc 加算 → solarArc[planet] = (natal[planet] + arc) mod 360
- 検証: solarArc.sun ≡ progressed.sun (定義より)

**フレーム別スタイリング** (`map_astro_lines.dart` の `astroFrameStyles`):
| フレーム | accent色 | tint混合 | opacity倍 |
|---------|---------|---------|-----------|
| Natal      | ゴールド (#E9D29A) | 0.0  | 1.00 |
| Transit    | オレンジ (#FF8E5C) | 0.28 | 0.88 |
| Progressed | 緑      (#63D6A0) | 0.30 | 0.72 |
| Solar Arc  | 紫      (#B07CFF) | 0.32 | 0.62 |

惑星色を accent に向けて `_lerpColor` で混色 → 惑星識別を保ちつつ frame を区別。

**LayerPanel 拡張** (`map_layer_panel.dart`):
- 2026-04-29 改修: CCG 4 frame 追加でパネルが画面外に伸びる問題を解決すべく
  `LayerPanelView` enum (`display` / `astro`) で **2ボタン分割**:
  - ☰ DISPLAY 系 (topPad+140): 16方位 / コンパス / MAPSTYLE
  - ✨ ASTRO 系 (topPad+188): 惑星ライン / 引越し / Natal線 / Transit線 / Prog線 / S.Arc線 / aspectAll / CHART / PLANET GROUP / FORTUNE
- 各 ASTRO 線トグルは frame accent カラーで彩色
- aspectAll サブトグルは何れかの aspect ON 時に表示 (4フレーム共通フィルタ)
- 同時には1パネルのみ開く (排他)。サイドボタン位置: 📍/🗺/🔮/🌐 を ✨ 分だけ下へずらした

**Astro\*Carto\*Graphy モード Pills** (`map_astro_carto.dart` の `AstroCartoFramePills`):
- 世界規模ビュー下部に4 frame 切替ピル配置 (Banner と CategoryPills の間 bottom 64)
- D2 仕様: モード入時 Natal=ON、Transit/Progressed/SolarArc は直前選択維持

**タイムスライダー** (`map_time_slider.dart` `MapTimeSlider`、2026-04-29 改修):
- 上部常時表示 (旧 SelectedDateBadge / 日付ピッカーを置換、`top: topPad+44`)
- 上段: ◀ 1日 [日付] 1日 ▶ + ±365日スライダー + LIVE + ⏰ 展開トグル
- 下段 (折りたたみ): ◀ 1時間 [時刻] 1時間 ▶ + 0..23h スライダー (緑系 accent)
- ドラッグ中はラベルのみ更新、指離しで commit (API 節約)
- LIVE ボタン: 「今日」+「現在時刻」に復帰 (= `_selectedDate = null`)
- 日付ラベルは `committedDays==0` のとき自動で「今日」表記に切替
- 上下段で ▶ 位置・スライダー長を完全一致 (label width:90、LIVE+⏰ stack:76)

**chart 日付別キャッシュ** (`_chartCacheByDate`):
- key = "yyyy-MM-dd" UTC日、LRU 50件
- スライダー往復で同じ日に戻った際の Worker API 連続呼出を回避
- 時刻だけ変えた場合は同日キャッシュ HIT → planets 流用 + GMST 再計算で線がヌルヌル動く

**検証** (`worker/verify_ccg_lines.py`):
- USNO線形 GMST vs Worker SiderealTime: 4ケース全 pass、max diff 0.54秒
- Transit MC line geometry: 15/15 pass、max diff 0.0000°
- Solar Arc 算術: solarArc.sun ≡ progressed.sun 完全一致

**戦略観点**: ACG (本質の地図) と CCG (タイミングの地図) を独立軸として並列展開。
英米圏では Solar Fire / TimePassages 系の主機能 → 英語版で必須。

### Map レイアウト構造リファクタ (2026-04-29)
NavBar 被り問題の根本解決として overlay 群を内側 SafeArea で囲み込み:

```
Stack (画面全体)
├── FlutterMap (全画面、NavBar 越しに blur 効果が透ける)
└── Positioned.fill
    └── SafeArea(top: false, left: false, right: false)  // bottom のみ尊重
        └── Stack (overlay 群)
            ├── 全 Positioned widgets (top: は status bar 基準のまま)
            └── bottom: 0 = NavBar 上端 (自動)
```

- Scaffold の `extendBody:true` 環境では body の `MediaQuery.padding.bottom` =
  bottomNavigationBar の実高 を Scaffold が自動設定 → SafeArea がそれを尊重
- 全 overlay widget の `bottom: X` が「NavBar の上 X px」を意味する
- 新規追加時に `+ navInset` 等を意識する必要なし
- 端末・Flutter バージョン・systemNav 設定が変わっても自動追従
- 例外: FlutterMap 内の `PlanetSymbolsLayer` は `MapCamera.size` ベースのため
  `SolaraNavBar.systemNavInset(context)` を独自参照 (1箇所のみ)

**SolaraNavBar 動的拡張** (`widgets/solara_nav_bar.dart`):
- 高さ = `baseHeight (80) + systemNavInset(context)`
- ジェスチャーナビ (Pixel 8 等、viewPadding ≤ 30px): inset = 0、旧来通り
- 3ボタンナビ (△〇□、viewPadding ~48px): inset = viewPadding - 12 (12px 詰める)
- アイコン行は上 80px に固定、追加領域は systemNav の下に伸びる gradient 領域
- 公開 helper: `SolaraNavBar.totalHeight(context)` / `SolaraNavBar.systemNavInset(context)`

### 回転ジェスチャー無効化 (2026-04-29)
`MapOptions.interactionOptions` に `flags: InteractiveFlag.all & ~InteractiveFlag.rotate`
を指定。Solara は北上固定前提 (16方位/コンパス/VP Pin の方位概念) のため
ピンチズーム時の指のひねりで誤回転していた問題を解消。

### 惑星シンボル端部マージン (2026-04-29)
`PlanetSymbolsLayer` のビューポートマージンを4方向に分離:
- 左右: 各 12px (画面端ギリギリ、左右対称)
- 上: 30px (現状維持)
- 下: `80 + SolaraNavBar.systemNavInset(context) + 12` (NavBar 全高 + 視覚マージン)

### Tarot 円卓 bottom-anchored + 上端 fade (2026-04-29)
`tarot_altar_scene.dart`:
- 旧: `Positioned(top: layout.top, height: layout.height)` で top-anchored
  → 画面サイズ変動で top 値が動き視覚的にブレる
- 新: `Positioned(bottom: -h * _altarBottomShift, height: ...)` で bottom-anchored
  → 画面下からの相対位置で固定
- 上端 30% に `ShaderMask + LinearGradient` で fade 適用
  - `colors: [transparent, white]`、`stops: [0.0, 0.30]`、`blendMode: dstIn`
  - 画像の切れ目が背景に溶け込み視覚的に消える

### Galaxy 惑星イベント popup (2026-04-29)
`celestial_event_bar.dart` の `_showMeaning`:
- 旧: 高さ無制限、内容に応じて伸縮
- 新: `SizedBox(height: screenH * 0.5)` で **画面半分固定**
  - 上端は常に画面中央位置 → 一貫した UX
  - `isScrollControlled: true` + `SingleChildScrollView` で長文時は縦スクロール
- ドラッグハンドル (40×4px バー) に `GestureDetector` でタップ閉じ機能
  - タップ領域は Padding(vertical: 12, horizontal: 24) で拡大
  - `Navigator.of(context).pop()` で sheet 閉じる

### Horo 縦短端末対応 (2026-04-29)
縦に短い端末で chart が bottom sheet に被って見えない問題を解決:

**chart 自動縮小** (`horo_chart_view.dart` `_buildChartScrollView`):
- `LayoutBuilder` で利用可能な縦幅 (`constraints.maxHeight`) を取得
- `chartSize = min(screenW - 16, availH - 32).clamp(200, 600)` で動的サイズ決定
- 上下端の余白 32px (上 padding 8 + 凡例等) を引く
- 200px 下限はクランプで担保 (これ以下では読めなくなるため)

**bottom sheet 上限** (`horo_bottom_sheet.dart` `_bsHeight`):
- 上限 = `screenH - 320`、chart に最低 320px を確保
- full 状態 (`screenH * 0.65`) と上限 の `min` を採用
- half 状態 (280) も同上限でクランプ
- 縦に短い端末では sheet が自動で縮み、chart に必要なスペースを譲る

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
| `/astro/forecast` | POST | 1〜5年 Forecast (KV月次クォータ60req/月) | `forecast_screen` |
| `/astro/events` | GET | 月別天体イベント (ingress/retrograde/eclipse) | `celestial_events.dart#fetchMonthEvents` |
| `/astro/daily-transits` | POST | F1 (2026-04-29): 拠点での1日のトランジット通過時刻 + 各時刻 natal アスペクト併記 (V2.2) | `daily_transits_api.dart#fetchDailyTransits` |
| `/astro/line-narrative` | POST | Tier S #2 (2026-04-30): A*C*G ライン (natal/transit) のタップ詳細解説 (Soft/Hard 両面記述) | `line_narrative_api.dart#fetchLineNarrative` |
| `/tz` | GET | 緯度経度→IANA TZ名 (C案, DST対応) | `solara_api.dart#fetchTimezoneName` |
| `/search` | GET | Google Places (New) Text Search 優先 → Nominatim fallback (lat/lng で locationBias.circle 15km, pageSize 20) | `map_search.dart#searchPlaces` |
| `/fortune` | POST | Gemini 2.5 Flash 生成の占い文 (5カテゴリ) | `fortune_api.dart#fetchFortune` |
| `/tarot` | POST | Gemini 生成のタロットリーディング | `observe_screen` |
| `/relocation` | POST | Gemini 生成のリロケーションナラティブ | `horo_relocation_panel.dart` |
| `/tiles/osm/<source>/<z>/<x>/<y>.png` | GET | OSM 系タイルプロキシ (HOT/Standard/CyclOSM) | `map_styles.dart` (sharedTileHttpClient 経由) |

**Secrets (Cloudflare暗号化ストア):**
- `GEMINI_API_KEY` — Fortune LLM 生成用 (wrangler secret put で設定済み)
- `JAWG_TOKEN` — Jawg Maps タイルアクセス用 (2026-04-22 追加)
- `GOOGLE_PLACES_KEY` — Places API (New) Text Search 用 (2026-04-30 追加、月10,000 req 無料枠)

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

---

## 変更履歴

### 2026-05-04 セッション

**5/1 メモ機能修正 9 項目** (commit `c2709cf`):
- クインカンクス用語変更 (違和感→異視点) + summary 文言更新
- セミセクスタイル/セミスクエア度数欠落 fix (`aspectInfo` 未登録 → entry 追加)
- スコアバー (FortuneFilterLabel) 端末幅対応 (左ラベル ConstrainedBox 32% / 方角幅 32→44 / バー幅 LayoutBuilder)
- 扇状 `activeCategory='all'` 限定 TOP2 濃さ +0.10 (rank0 0.85, rank1 0.65, rank>1 0.40)
- DailyTransitBadge 明暗アニメ強化 (alpha 振れ幅 約4倍、周期 2400ms→1800ms)
- 検索結果総合スコア計算注記 + 計算内容ボタン (info_outline + dialog)
- Sanctuary 1日開始時刻 1分単位ピッカー (時/分 ドロップダウン、`solara_daily_reset_minute` storage 追加)
- 新月 reveal 画面 SET INTENTION ボタン位置 (Stack 固定→SingleChildScrollView 化、events の下)
- Catasterism 選択肢画面 overflow 修正 (固定 SizedBox 150 + Stack→ScrollView 化)

**UX 修正 5 項目 + 検索住所** (commit `6c4e795`):
- アスペクト詳細 popup BottomSheet → AlertDialog (`map_aspect_chip.dart`、軽量化)
- Horo 相タブ overflow 修正 (Flexible + ellipsis + badge 文字列短縮)
- 検索詳細 popup に住所行追加 (parts.skip(1) で複数階層住所表示)
- 検索結果スコアラベル「総合」固定 → activeCategory 動的化 (合計/豊かさ/癒し 等)
- 扇状 `activeCategory='all'` 時に方位別 dominant カテゴリ色 (`map_screen._dominantTintByDir()`)
- Map (Light) で DailyTransitBadge 反転コントラスト (内側 暗紺 + 強い金 border)

**3-1 出生地/現住所 ミニマップ + パン式座標調整** (commit `fdc1b99`):
- 新規 widget `lib/widgets/location_picker_minimap.dart`
- flutter_map ベース、初期 zoom 14、中央固定ピン (B 方式 = マップパン)
- onPositionChanged で座標即時更新、didUpdateWidget で外部変化検知 (epsilon でループ防止)
- `sanctuary_profile_editor.dart` 出生地検索後に表示
- `sanctuary_home_editor.dart` 現住所検索後に表示

**緊急 4 件 fix** (commit `c3b2164`):
- 検索 popup 住所表示条件緩和 (parts.length > 2 → > 1)
- 扇状 dominant カテゴリ色の lerp 廃止 (上部スコアバーと同色)
- スコアバーと DailyTransitBadge 重なり修正 (右マージン 64 予約)
- カテゴリスコア閾値 0.05 → 0.001 (低スコアでも chip 表示)

**Daily Transit i ボタン カテゴリ別動的化** (commit `e9d2239`):
- 4-2 デモボタン profile build 表示 (`kDebugMode` → `!kReleaseMode`)
- B5 「お勧め行動の例」i ボタン → カテゴリ別 dialog (`categoryTipsIntent` 5 種、`_showCategoryTipsIntent`)
- B6 惑星×アングル i ボタン → カテゴリ×アングル補足 (`categoryAngleAppendix` 5×4=20 パターン)
- `daily_transit_data.dart` に上記 2 データセット追加 (+142 行)
- `_showPlanetAngleDetail()` ヘルパーに既存 dialog ロジック切出し

**新規ファイル**:
- `lib/widgets/location_picker_minimap.dart` (B 方式座標ピッカー、141 行)

**主要修正ファイル**:
- `lib/screens/map/map_search.dart` — SearchResultList/SearchFocusPopup に activeCategory + 住所
- `lib/screens/map/map_sectors.dart` — sectorTintByDir 引数 + lerp 廃止
- `lib/screens/map_screen.dart` — `_dominantTintByDir()` ヘルパー追加
- `lib/screens/map/map_fortune_sheet.dart` — LayoutBuilder + ConstrainedBox + バー幅可変
- `lib/screens/map/map_aspect_chip.dart` — Dialog 化 (BottomSheet 廃止)
- `lib/screens/map/map_daily_transit_screen.dart` — i ボタン dialog 動的化 (+73 行)
- `lib/screens/map/daily_transit_data.dart` — categoryAngleAppendix + categoryTipsIntent (+142 行)
- `lib/screens/horoscope/horo_aspect_description.dart` — クインカンクス + minor aspect 追加
- `lib/screens/horoscope/horo_aspect_list.dart` — overflow fix
- `lib/screens/sanctuary/sanctuary_profile_editor.dart` — ミニマップ組込
- `lib/screens/sanctuary/sanctuary_home_editor.dart` — ミニマップ組込
- `lib/screens/sanctuary/sanctuary_reset_hour_picker.dart` — 1分単位ピッカー全書換
- `lib/screens/sanctuary_screen.dart` — minute state + storage
- `lib/utils/solara_storage.dart` — `solara_daily_reset_minute` key
- `lib/widgets/daily_transit_badge.dart` — 明暗アニメ強化 + isLightMap 引数
- `lib/widgets/new_moon_overlay.dart` — SET INTENTION ScrollView 化
- `lib/widgets/catasterism_overlay.dart` — overflow fix (ScrollView)
- `lib/screens/galaxy_screen.dart` — デモボタン profile 表示

**残課題 (次セッション)**:
- 4-2 catasterism「ガサガサ」感の真の原因究明 (実機確認 + Phase 2 Perfetto trace 想定)
- map_screen.dart 1752 行 / map_daily_transit_screen.dart 1294 行 の分割 (大規模 refactor)
- audit Critical 22 件のうち実害ある箇所の選定 + 修正 (FadeTransition 等)

### 2026-05-03 セッション

**Phase 1 saveLayer leak 撤去** (Critical 30→5, CPU 227%→113%, Jank 52%→7.32%):
- NavBar/GlassPanel BackdropFilter 撤去、動的 blur 固定化、Opacity → Color alpha
- IndexedStack 裏画面の TickerMode で Animation 完全停止
- Dark タイル ColorFilter 二重→1段合成
- Impeller off (`AndroidManifest EnableImpeller=false`) で A101FC fd leak 完全停止

**perf_audit ツール追加** (commit `2340d4a`):
- `apps/solara/tools/perf_audit/` Android 性能網羅計測 CLI
- 13 collector (CPU/Memory/Frame/Battery/Network/GPS/Sensor/fd/IO 等)
- 3 端末 (a101fc/pixel8/so41b) + 3 profile (quick/standard/full)
- compare.py で 2 レポート side-by-side 比較
- PHASE2_DESIGN.md で Perfetto trace 統合計画
