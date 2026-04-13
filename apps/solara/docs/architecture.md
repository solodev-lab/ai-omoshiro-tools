# Solara アーキテクチャ

> アプリ全体の構造と設計方針。
> 新しい画面や機能を追加する時はこのファイルを確認する。

---

## 全体構成

```
lib/ (合計 約12,400行 / 48ファイル)
├── main.dart              ← アプリ起点。IndexedStackで5画面を管理
├── models/                ← データクラス
│   ├── daily_reading.dart    (37行)   デイリーリーディング
│   ├── galaxy_cycle.dart     (119行)  銀河サイクル・星座ドット
│   ├── lunar_intention.dart  (102行)  月の意図・中間チェック・結晶化
│   └── tarot_card.dart       (61行)   タロットカード
├── screens/               ← 各画面
│   ├── map_screen.dart       (568行)  世界地図・運勢方位（メイン）
│   ├── map/                  ← Map サブウィジェット
│   │   ├── map_vp_panel.dart    (435行)  VP Panel
│   │   ├── map_astro.dart       (321行)  天体計算
│   │   ├── map_fortune_sheet.dart (308行) 運勢シート
│   │   ├── map_planet_lines.dart (191行) 天体ライン描画
│   │   ├── map_sectors.dart     (151行)  セクター描画
│   │   ├── map_layer_panel.dart (117行)  レイヤーパネル
│   │   ├── map_constants.dart   (101行)  定数
│   │   ├── map_widgets.dart     (87行)   共通ウィジェット
│   │   └── map_stella.dart      (57行)   Stella
│   ├── horoscope_screen.dart (604行)  ホロスコープチャート（メイン）
│   ├── horoscope/            ← Horoscope サブウィジェット
│   │   ├── horo_bottom_panels.dart (719行) BS各タブ + パターン検出 + 60日予測
│   │   ├── horo_chart_painter.dart (368行) チャートホイール描画（2重円対応）
│   │   ├── horo_fortune_cards.dart (341行) 星読みView + FORTUNE_MOCK
│   │   └── horo_constants.dart     (93行)  共通定数（アスペクト名JP・パターンORB）
│   ├── observe_screen.dart   (332行)  タロット占い（メイン）
│   ├── observe/              ← Observe サブウィジェット
│   │   ├── observe_history.dart      (253行) 履歴パネル・履歴カード・SyncInput
│   │   ├── observe_card_widgets.dart  (175行) 3Dカード・裏面・表面（画像フル表示）
│   │   └── observe_constants.dart     (59行)  テンプレート・惑星情報・元素マップ
│   ├── galaxy_screen.dart    (620行)  銀河・星座（メイン・サンプルデータ含む）
│   ├── galaxy/               ← Galaxy サブウィジェット
│   │   ├── galaxy_constellation_builder.dart (132行) 星座生成ロジック
│   │   ├── galaxy_star_atlas.dart            (126行) Star Atlasタブ・カード
│   │   └── galaxy_replay_overlay.dart        (121行) リプレイオーバーレイ
│   ├── sanctuary_screen.dart (810行)  プロフィール・設定（メイン）
│   └── sanctuary/            ← Sanctuary サブウィジェット
│       ├── sanctuary_profile_editor.dart  (479行) 出生情報エディタ
│       ├── sanctuary_title_diagnosis.dart (364行) 称号診断ページ
│       ├── sanctuary_orb_overlay.dart     (245行) Orbオーバーレイ
│       └── sanctuary_home_editor.dart     (209行) 自宅エディタ
├── theme/                 ← 色・フォント定義
│   ├── solara_colors.dart    (90行)   全色定数
│   └── solara_theme.dart     (63行)   ThemeData
├── utils/                 ← 計算・データ・永続化
│   ├── solara_storage.dart   (217行)  SharedPreferencesラッパー
│   ├── moon_phase.dart       (327行)  月相計算（Jean Meeusアルゴリズム）
│   ├── constellation_namer.dart (483行) 星座名生成・MST構築
│   ├── celestial_events.dart (121行)  天体イベント読み込み
│   ├── tarot_data.dart       (52行)   タロットデータ読み込み
│   └── title_data.dart       (173行)  称号システム
└── widgets/               ← 共通ウィジェット
    ├── solara_nav_bar.dart   (130行)  ボトムナビゲーション
    ├── glass_panel.dart      (38行)   フロストガラスパネル
    ├── moon_overlay.dart     (660行)  新月・満月・結晶化オーバーレイ
    ├── nav_icons.dart        (218行)  ナビアイコン（CustomPainter x5）
    ├── constellation_painter.dart (198行) 星座描画
    ├── cycle_spiral_painter.dart  (311行) サイクルスパイラル描画
    └── spiral_painter.dart        (91行)  スパイラル描画
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
| http | map_screen / sanctuary_screen | Nominatim地名検索 |
| flutter_riverpod | **未使用** | pubspecに宣言のみ |
| riverpod_annotation | **未使用** | pubspecに宣言のみ |

---

## 独自ロジック（コアアルゴリズム）

### 月相計算 (moon_phase.dart)
- Jean Meeus "Astronomical Algorithms" Chapter 49 準拠
- 精度: ±2-3分
- 機能: 新月/満月の日時算出、月齢計算、サイクルID生成

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

### ⚠️ 画面ファイルが大きい
全5画面が分割済み: Map（568+9）、Horoscope（604+4）、Observe（332+3）、Galaxy（620+3）、Sanctuary（810+4）。
全画面のメインファイルが850行以下。Horoscopeは2重円・パターン検出・60日予測を追加し604行。

### ⚠️ CF Worker 未接続
Worker側（占い文生成のGemini API）は存在するが、Flutterから呼んでいない。
- Horoscope の星読みがサーバー連携していない
- **TODO**: 星読みタブで CF Worker の Fortune API を呼ぶ実装

### ⚠️ GlobalKey による画面間通信
HoroscopeScreenState が public で、GlobalKey 経由で外部からメソッドを呼んでいる。
- Riverpod 導入時にこのパターンを解消する
- 現状は動いているのでリリース前は触らない

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
