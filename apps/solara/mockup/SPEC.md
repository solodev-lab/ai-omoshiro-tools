# Solara V7 統合モックアップ — 確定仕様書

## 概要
Solara Astrocartography + V7 Cosmic Spiral を統合した5画面モックアップ。
モックアップ段階（HTML + JS）。本番は Flutter CustomPaint + AnimationController に移行予定。

---

## 画面構成（5タブ）

| タブ | ファイル | 概要 |
|------|----------|------|
| Map | `index.html` | Astrocartography地図（Leaflet）+ 方位セクター + 惑星ライン |
| Horo | `horoscope.html` | ホロスコープチャート（SVG）+ Fortune Reading 5カード |
| Tarot | `tarot.html` | ムード入力 → カード引き → 鑑定文表示 → 地図連携 |
| Galaxy | `galaxy.html` | Cycle（3Dスパイラル）+ Star Atlas（星座アーカイブ） |
| Sanctuary | `sanctuary.html` | プロフィール編集 + Astrology設定 + Cosmic Pro |

---

## 共通基盤 (`shared/`)

### styles.css
- CSS Custom Properties: `--bg-deep`, `--gold`, `--cyan`, `--text-primary` 等
- `.glass` — blur(16px) + 半透明ボーダー
- `.bottom-nav` + `.nav-item` — 5タブ均等配置
- `.overlay-screen` — 全画面モーダル基盤
- `.gold-btn`, `.ghost-btn`, `.glass-input`, `.section-label`
- `.pro-banner`, `.stella-orb`
- アニメーション: `fadeIn`, `orbPulse`, `twinkle`

### nav.js
- `renderNav(activeTab)` — 5タブ動的レンダリング
- タブ定義: Map/Horo/Tarot/Galaxy/Sanctuary
- `location.href` でページ遷移

### vibe.js
- `calcVibeScore({tarot, mood, transit, progressed})` — 重み: T×0.4 + M×0.1 + Tr×0.3 + P×0.2
- `vibeToColor(vibe, alpha)` — -1→+1 を deep-blue→cyan→gold グラデーション
- `saveVibe(score)` / `loadVibe()` — localStorage（当日のみ有効）
- `saveMood(val)` / `loadMood()` — ムード値永続化

### stella.js
- `generateStellaMessage(vibeScore, lang)` — vibe_scoreに応じたトーン
  - 高(>0.3): 励まし系
  - 中(-0.3〜0.3): 平穏系
  - 低(<-0.3): 内省系
- 日英対応（`'en'` / `'jp'`）
- 日付シードで日替わり一貫性
- `renderStellaMessage(targetId, vibeScore, lang)` — DOM直接レンダリング

### events.js
- **New Moon オーバーレイ**: 3フィールド（Create/Release/Become）、localStorage保存
- **Full Moon オーバーレイ**: intention表示 → Disintegrateパーティクル燃焼エフェクト
- `showNewMoonOverlay()` / `closeNewMoonOverlay()` / `sealIntentions()`
- `showFullMoonOverlay()` / `closeFullMoonOverlay()` / `startDisintegrateEffect()`
- **Moonフェーズ自動検出**: Metonic cycle近似（synodic month = 29.53059日）
- `checkMoonEvents()` — New/Full Moon当日に自動発火（1日1回、localStorage制御）
- `getMoonPhaseInfo()` — フェーズ名・絵文字・ラベル取得
- HTML動的注入（どのページでも呼び出し可能）

---

## 各画面詳細仕様

### 1. Map (`index.html`)

#### 既存機能（V7統合前から）
- Leaflet地図（CartoDB dark tiles）
- 16方位セクター（大圏描画、turf.js）
- Triple chart（Natal/Transit/Progressed）天文計算（astronomy-engine）
- アスペクト検出 → 方位スコア（cosine falloff spread）
- **アングルアスペクト方位ブースト**: ASC/MC/DSC/ICとアスペクトを形成するトランジット・プログレス天体のスコアにウェイトボーナスを付与。チャートの要（アングル）に関わる天体ほど、その方位のエネルギーが強く反映される
- 運勢カテゴリ（癒し/金運/恋愛/仕事/コミュニケーション）
- Fortune Sheet（16方位ランキング）
- レイヤーパネル（チャート/惑星グループ/運勢フィルタ）
- **ビューポイント**（`solara_vp_slots`）: 方位の原点として使う場所。タップ→rebuild()で扇・惑星ライン再計算
- **登録地**（`solara_locations`）: Horo画面のトランジット/プログレス計算用。タップ→地図パンのみ
- VPパネル2タブ切替: `📍 VIEWPOINT` / `🌐 LOCATIONS`
- 自宅はプロフィール（Sanctuary）から両方に自動同期（slot[0]、isHome=true、削除不可）
- タロットブリッジ（Tarot→Map連携）
- パーティクルエフェクト（メテオ/衝撃波/収束）

#### V7統合で追加
- **vibe_scoreセクターブースト**: `rebuild()` 時に `loadVibe()` の値 ×2 を全方位スコアに上乗せ
- **Stellaメッセージ vibe連携**: タロット未引き時は `generateStellaMessage()` で日本語メッセージ表示
- **Moon自動検出**: `checkMoonEvents()` でNew/Full Moon当日にオーバーレイ自動発火
- **共通JS読み込み**: nav.js, vibe.js, stella.js, events.js

### 2. Horo (`horoscope.html`)

#### 既存機能
- SVGホロスコープチャート（600×600）、標準配置（ASC=左、MC=上、反時計回り）
- 1重/2重（N+T, N+P）モード切替
- **プロフィール連携**: `solara_profile`から出生データ自動読み込み。未設定時は案内バナー表示
- **場所選択**: 出生地・トランジット場所に登録地（`solara_locations`）から選択可能。トランジットデフォルト=自宅
- **Placidusハウスシステム**（デフォルト）/ Whole Sign切替可（Sanctuary設定）
  - 高緯度(|lat|>66°)はEqual Houseに自動フォールバック
  - localStorage `solara_house_system` で永続化
- **4アングル（ASC/DSC/IC/MC）**
  - 十字軸ライン: zodiacOuterまで延伸、薄い金色(opacity 0.25, 1px)
  - 4ラベル: zodiacInner内側に表示
  - House System名: SVG左下に表示
- **アングルアスペクト**: ASC/DSC/IC/MCと天体10個のアスペクトを検出・チャート上に描画。アングルとのアスペクトは占星術において非常に重要な意味を持ち、その人の基本的な性質や人生のテーマに深く関わる
- 天体位置テーブル（ASC/MC/DSC/IC 4行追加）
- アスペクトフィルター（性質/運勢/惑星グループ）
- **オーブ設定**: localStorage `solara_orb_settings` / `solara_pattern_orb_settings` から読み込み（Sanctuary設定で変更可）
- **アスペクト種別**: メジャー5種 + マイナー3種（セミセクスタイル30°、セミスクエア45°、クインカンクス150°）
- パターン検出（Grand Trine/T-Square/Yod）— パターン専用オーブ設定あり
- **出生時刻不明時**: ハウス線・ASC/MC/DSC/IC軸・ラベル・ハウス番号を非表示。アングルアスペクトも非表示。惑星同士のアスペクトは表示
- 60日先予測スキャン
- モバイルボトムシート（ドラッグ4段階: mini 52px / small 25% / half 45% / full 85%、bottom: 70px でナビバー上に配置）

#### V7統合で追加
- **Fortune Reading カードUI（5カテゴリ）**
  - 全体運 / 恋愛運 / 金運 / 仕事運 / 対話運
  - 各カード: スコア表示、鑑定文（200〜400字）、方位アドバイス
  - スワイプ切替（touch + mouse drag）
  - ドットナビ + ←→ ボタン
  - デスクトップ右パネル + モバイルBS「✦ 運勢」タブ
- **日キャッシュ**: `solara_fortune_cache` — 同日はlocalStorage利用
- **5タブナビ統合**

#### Fortune Reading データ構造（モック）
```javascript
FORTUNE_CATEGORIES = [
  { id:'overall', icon:'✦', label:'全体運', color:'#F6BD60' },
  { id:'love',    icon:'💕', label:'恋愛運', color:'#FF6B9D' },
  { id:'money',   icon:'💰', label:'金運',   color:'#FFD370' },
  { id:'career',  icon:'💼', label:'仕事運', color:'#FF8C42' },
  { id:'communication', icon:'💬', label:'対話運', color:'#6BB5FF' },
];
// 本番: Claude API (Sonnet) でトランジット×ネイタルアスペクトから動的生成
// ⚠️ 重要仕様: 鑑定文には必ず実際のアスペクト情報（惑星名・角度・性質）を含めること
//   例: 「太陽と木星がトライン（120°）を形成し…」
//   → astronomy-engine で検出したアスペクトリストをプロンプトに渡してSonnetに生成させる
//   モックのテキストはアスペクト名をハードコードしているため、チャートと一致しない場合がある（モック許容）
```

### 3. Tarot (`tarot.html`)

#### 既存機能
- 場所選択（自宅/GPS/指定場所）
- 3Dカードフリップアニメーション
- 78枚全カード対応（Major 22 + Minor 56）
- ブースト方位計算（惑星角度ベース）
- コンパスミニ + 方位ラベル
- 履歴管理（50件、展開/折り畳み、同期メモ）
- タロットブリッジ → Map連携

#### V7統合で追加
- **ムードスライダー**
  - -1.0（🌑 Deep stillness）〜 +1.0（☀️ Full radiance）
  - リアルタイム数値表示 + 状態テキスト
  - localStorage保存（`solara_mood`）
- **タロット鑑定文パネル**
  - カード引き後にタイプライター演出で表示
  - エレメント別テンプレート（火/水/風/地）
  - カード名・キーワード動的挿入
  - 方位アドバイス付き
- **vibe_score計算・保存**: `applyToMap()` 時に `calcVibeScore()` → `saveVibe()`

### 4. Galaxy (`galaxy_screen.dart`) — Flutter実装済み

#### 設計思想
「受動的に溜まるタロット履歴の可視化」。ユーザーがObserve画面でカードを引くだけで、GALAXYスパイラルに自動プロットされる。能動的なタスク管理は排除し、占い体験の副産物としてデータが蓄積される。

#### 内部タブ
| タブ | 機能 |
|------|------|
| 🌀 Cycle | 実月齢ベース3Dスパイラル（朔望月~29.5日） |
| ✦ Star Atlas | 完了周期の星座アーカイブ |

#### Cycle タブ — 3Dスパイラル
- **月齢ベース周期**: 固定28日ではなく実際の朔望月（29.53059日）。新月〜次の新月で1周期
- **月齢計算**: Metonic cycle近似（基準: 2000/1/6 18:14 UTC）
- **3Dスパイラル**: θ = (d/total)×4.2π, r = b×θ, b = min(W,H)×0.057
- **3D回転**: X/Y軸回転、自動回転（0.0025rad/frame）、ドラッグ操作、慣性（0.90減衰）
- **投影**: FOV=360×zoom, perspective projection: s = fov/(fov+z+260)
- **呼吸アニメ**: `0.7 + 0.3 × sin(time/period + phase)`, 個別位相（2〜4秒周期）

#### ドット描画ルール

| 条件 | 半径 | 色 | グロー |
|------|------|-----|--------|
| 大アルカナ | 8px | 惑星色（10色） | blur 12px, alpha 0.35 |
| 小アルカナ | 4px | エレメント色（4色） | blur 6px, alpha 0.25 |
| 未プレイ日 | 2px | #555555 | なし |

#### 惑星色マッピング（大アルカナ）
| 惑星 | 色 | 対応カード |
|------|-----|-----------|
| 太陽 Sun | `#FFD700` | 力(8), 太陽(19) |
| 月 Moon | `#C0C8E0` | 女教皇(2), 戦車(7) |
| 水星 Mercury | `#7BE0AD` | 魔術師(1), 隠者(9), 恋人(6) |
| 金星 Venus | `#FF8FA0` | 女帝(3), 法王(5), 正義(11) |
| 火星 Mars | `#FF4444` | 皇帝(4), 塔(16) |
| 木星 Jupiter | `#6B5BFF` | 運命の輪(10), 節制(14) |
| 土星 Saturn | `#8B7355` | 悪魔(15), 世界(21) |
| 天王星 Uranus | `#00D4FF` | 愚者(0), 星(17) |
| 海王星 Neptune | `#9B6BFF` | 吊るされた男(12), 月(18) |
| 冥王星 Pluto | `#2A0030` | 死神(13), 審判(20) |

#### エレメント色マッピング（小アルカナ）
| スート | 色 |
|--------|-----|
| ワンド（火） | `#FF6B35` |
| カップ（水） | `#4DA8DA` |
| ソード（風） | `#B8C4D0` |
| ペンタクル（地） | `#C4A265` |

#### 月齢特別演出
| 月齢 | 演出 |
|------|------|
| 満月（phase 14-15） | サイズ1.5倍 + 白金リング(`#FFF0C0`) + 放射グロー(blur 18px) |
| 新月（phase 0-1） | サイズ0.75倍 + 深紫コア(`#2A0030`) |
| ランダム（5%確率） | 白金リング（満月より控えめ: alpha 0.3, glow 10px）— readingがある日のみ |

#### ドットタップ → ポップアップ
- ヒットテスト: 28px閾値で最近傍ドット検出
- 表示: Day番号、月齢emoji、カード名(emoji+EN)、惑星/スート、キーワード
- 3.5秒自動消去

#### Day Badge / Moon Badge
- 右上: 「Day X of Y」（周期進捗）
- 左上: 月齢emoji + フェーズ名（例: 🌔 Waxing Gibbous）

#### Stella メッセージ
- reading数に応じた動的メッセージ（0件/1-6件/7-19件/20+件）

---

#### 月のインテンション機能（3ビート構造）

天体イベント連動の自己内省リチュアル。**完全任意**（スキップしてもスパイラルに影響なし）。

##### Beat 1: 新月 — 手放す選択
- **トリガー**: 新月当日（phase 0-1）にGalaxy画面表示時に自動発火。1日1回のみ
- **表示内容**:
  - 新月のサイン（例: "New Moon in Scorpio / 蠍座の新月"）
  - その月の天体イベント一覧（逆行・食・イングレス等）
  - **3つの選択肢**: 月のサインと天体イベントに基づく「手放すべきこと」（日英表示）
- **選択肢データソース**: `celestial_events_2026.json`（静的テンプレート）
  - 将来: Claude API (Haiku) で動的生成（月1回/ユーザー、~$0.001/回）
- **保存**: `LunarIntention` モデルとして SharedPreferences に保存

##### Beat 2: 満月 — 中間チェック
- **トリガー**: 満月当日（phase 14-15）にインテンションが設定済みかつ未チェックの場合
- **表示内容**:
  - 満月名（例: "Pink Moon / 桃色の月"）
  - 新月で選んだインテンションを再表示
  - 3段階の自己評価: 🌊まだ途中 / ✨進展あり / 🌟軽くなった

##### Beat 3: 結晶化 — 新月前日の振り返り演出
- **トリガー**: 次の新月の前日（cycleEnd - 1日）にインテンション設定済みかつ未結晶の場合
- **表示内容**:
  - 選んだインテンション + 満月時の中間評価バッジを表示
  - **天体イベント連動の温かいメッセージ**（月別100字、12ヶ月分定義済み）
  - 「この周期の軌跡が星座になります」
  - 「✦ 星座を結晶化する」ゴールドボタン（選択肢なし、振り返りのみ）
- **ボタン押下時の動作**:
  - 即座にStar Atlasにサイクルデータを保存（アニメーション前に永続化）
  - 星座形成アニメーション（8秒4ステージ: CONVERGENCE→IGNITION→LINKING→COMPLETE）
  - 「View in Star Atlas ✦」→ Star Atlasタブに自動遷移
- **Not nowは廃止**: 結晶化画面が出たら「✦ 星座を結晶化する」を押すのみ
- **未結晶の救済**: 新月が来た時に前周期の未結晶インテンションを検出→結晶化オーバーレイを優先表示（アプリ閉じて見逃した場合の救済）

##### 天体イベントデータ（2026年）
- `assets/celestial_events_2026.json` に12ヶ月分を静的定義
- 各月: 新月日/サイン、満月日/名前、天体イベントリスト、3テーマ（EN/JP）
- 主要イベント: 水星逆行×3、金星逆行、土星逆行、冥王星逆行、日食×2、月食×2、
  海王星牡羊座入り、土星牡羊座入り、天王星双子座入り、木星獅子座入り

---

#### Star Atlas タブ
- **星座カードグリッド**: 2カラム、ミニキャンバス（Catmull-Rom スプライン描画）
- **リプレイオーバーレイ**: 300×300 キャンバス、2.8秒アニメーション再生
- **星座形成ロジック**:
  - 全プレイ日（大アルカナ＋小アルカナ）のドットを時系列で接続
  - 大アルカナ = 主要ノード（大きく描画）、小アルカナ = 中継点（小さく描画）
  - 未プレイ日はスキップ → 星座の「切れ目」に（毎日引くほど密な星座、サボるほど疎な星座）
  - Catmull-Rom スプラインで滑らかな曲線

#### Star Atlas 名前生成
- **seedCard**: 周期内で最頻出の大アルカナ（fallback: 最頻出スートのエース）
- **テンプレート**: `The [形容詞] [名詞]`（EN）/ `[形容詞][名詞]`（JP）
- **語彙**: 各10語（Golden/Silver/Crimson/Ethereal/Radiant/Silent/Infinite/Luminous/Frozen/Mystic × Crown/Arrow/Veil/Flame/Chalice/Mirror/Gate/Wing/Orbit/Sigil）
- **ハッシュ**: `seedCardId + ISO日付` → 決定的生成
- **将来**: Claude API (Sonnet) で動的生成

#### データ永続化 (SharedPreferences)
| キー | 用途 |
|------|------|
| `solara_current_cycle_readings` | 現在周期のDailyReadingリスト |
| `solara_galaxy_cycles` | 完了GalaxyCycleリスト |
| `solara_lunar_intention_{cycleId}` | 月のインテンション（cycleId = "2026-04"形式） |
| `solara_overlay_shown_{type}_{date}` | オーバーレイ表示済みフラグ（1日1回制御） |

#### Observe画面連携
- Observeでカードを引くと `SolaraStorage.addReading()` で自動保存
- 1日1枚制限（同日は同じカードを表示）
- Galaxy画面表示時に `_loadData()` で読み込み → スパイラルに自動反映

#### ファイル構成（Flutter実装）
```
lib/
  models/
    tarot_card.dart         — 78枚カードモデル
    daily_reading.dart      — 日次占い記録
    galaxy_cycle.dart       — 完了周期 + 星座ドット
    lunar_intention.dart    — インテンション + 中間 + 結晶化
  utils/
    moon_phase.dart         — 月齢計算（Metonic cycle）
    constellation_namer.dart — 星座命名（ハッシュベース）
    tarot_data.dart         — JSONアセットローダー
    solara_storage.dart     — SharedPreferences wrapper
    celestial_events.dart   — 天体イベントローダー
  widgets/
    cycle_spiral_painter.dart     — 3Dスパイラル描画
    constellation_painter.dart    — 星座描画（フル + ミニ）
    moon_overlay.dart             — 新月/満月/結晶化オーバーレイ
  screens/
    galaxy_screen.dart      — GALAXY画面（Cycle + Star Atlas）
    observe_screen.dart     — Observe画面（ランダムカード + 保存）
assets/
  tarot_planet_map.json         — 78枚カードデータ
  celestial_events_2026.json    — 2026年天体イベント + テーマ
```

### 5. Sanctuary (`sanctuary.html`)

#### プロフィール管理（`solara_profile`）
- **出生情報**: 1つのオーバーレイ画面で氏名・生年月日・出生時刻・出生地を一括入力
  - **出生時刻不明**: チェックボックスでON → 出生時刻入力無効化、正午(12:00)で計算。ハウス・ASC・MC鑑定は省略
  - **出生地**: テキスト検索 + Leaflet地図ピッカー（クリックで座標取得、逆ジオコーディングで住所自動入力）
- **自宅（現住所）**: 出生地と同様の地図UIで入力。保存時 `solara_vp_slots`[0] と `solara_locations`[0] に自動同期（isHome=true）
- **プロフィール未設定時**: Horo画面に案内バナー表示

#### Astrology設定
- **House System**: Placidus / Whole Sign 切替（localStorage `solara_house_system`）
  - 出生時刻不明時はグレーアウト（選択不可）
- **Aspect Orbs**: 別画面オーバーレイ、3カテゴリに分類（0.5°〜8°、0.5°刻み）
  - **Major Aspects**: Conjunction(0°/2°), Opposition(180°/2°), Trine(120°/2°), Square(90°/2°), Sextile(60°/2°)
  - **Minor Aspects**: Quincunx(150°/2°), Semi-Sextile(30°/1°), Semi-Square(45°/1°)
  - **Patterns**: Grand Trine(120°/3°), T-Square Opp(180°/3°), T-Square Sq(90°/2.5°), Yod Sextile(60°/2.5°), Yod Quincunx(150°/1.5°)
  - ±ボタン + スライダー + デフォルト位置マーク + リセットボタン
  - localStorage: `solara_orb_settings`（アスペクト）/ `solara_pattern_orb_settings`（パターン）

#### その他設定
- **Cosmic Pro**: サブスクカード（$9.99/月、$49.99/年）— UI表示のみ
- **App設定**: Language / Notifications / Terms

---

## データフロー

### localStorage キー一覧
| キー | 用途 | 管理画面 |
|------|------|----------|
| `solara_vibe_today` | 当日vibe_score | Tarot→Map/Galaxy |
| `solara_mood` | ムード値 | Tarot |
| `solara_tarot_bridge` | タロット→地図ブリッジ | Tarot→Map |
| `solara_natal_history` | タロット履歴（50件） | Tarot |
| `solara_profile` | ユーザープロフィール（氏名/出生データ/自宅） | Sanctuary→全画面 |
| `solara_vp_slots` | ビューポイント（方位原点）5スロット | Map |
| `solara_locations` | 登録地（HORO用）5スロット | Map→Horo |
| `solara_vp_last` | 最後の地図中心座標 | Map |
| `solara_fortune_cache` | 占い結果日キャッシュ | Horo |
| `solara_intentions` | New Moon intentions | events.js |
| `solara_moon_event_shown` | Moon発火済みフラグ | events.js |
| `solara_daily_vibes` | 日次vibeデータ（28件） | Galaxy |
| `solara_house_system` | ハウスシステム（placidus/whole_sign） | Sanctuary→Horo |
| `solara_orb_settings` | アスペクトオーブ値JSON | Sanctuary→Horo |
| `solara_pattern_orb_settings` | パターン検出オーブ値JSON | Sanctuary→Horo |
| `solara_galaxy_cycles` | 完了サイクル一覧 | Galaxy |

### vibe_score計算式
```
S = Tarot × 0.4 + Mood × 0.1 + Transit × 0.3 + Progressed × 0.2
```
- 範囲: -1.0 〜 +1.0
- 影響: Galaxy（スパイラルドット色）、Map（セクター強度上乗せ）、Stella（メッセージトーン）

### タロット → Map 連携フロー
1. Tarotでカード引き → 鑑定文表示
2. 「地図に反映する」→ bridge保存 + vibe_score保存
3. Map画面: bridge検出 → seedBoost適用 → メテオ演出 → セクター更新

---

## デザイントークン

| トークン | 値 | 用途 |
|----------|-----|------|
| Background Deep | `#080C14` | 主背景 |
| Background Mid | `#0C1D3A` | ネビュラ中心 |
| Gold | `#F9D976` → `#F6BD60` | アクセント、CTA |
| Cyan | `#26D0CE` | Transit、Water系 |
| Cyan Deep | `#1A2980` | 深い水系 |
| Text Primary | `#EAEAEA` | 本文 |
| Text Secondary | `#ACACAC` | サブテキスト |
| Glass BG | `rgba(255,255,255,0.05)` | グラスモーフィズム |
| Glass Border | `rgba(255,255,255,0.1)` | グラスボーダー |
| Phone Frame | `390×844px` | モバイルモックアップ |

---

## 外部依存

| ライブラリ | バージョン | 使用画面 |
|-----------|-----------|----------|
| Leaflet | 1.9.4 | Map |
| Turf.js | 7.x | Map |
| Astronomy Engine | 2.1.19 | Map, Horo |
| Lato (Google Fonts) | — | Galaxy, Sanctuary |

---

## 本番移行時の変更点

| モックアップ | 本番（Flutter） |
|-------------|----------------|
| HTML + JS | Flutter CustomPaint + AnimationController |
| localStorage | Cloudflare Worker + ローカルDB |
| モック鑑定文 | Claude API (Sonnet) 動的生成 |
| モック名前生成 | Claude API (Sonnet) テンプレートルール制約付き |
| events.js DOM注入 | Flutter Widget overlay |
| CSS glass | Flutter BackdropFilter |
| 日英2段表示（例: 星読み/READING） | AppLocalizations による自動多言語切替（Sanctuary言語設定と連動） |

---

## ファイル構成（確定）
```
apps/solara/mockup/
  index.html          ← Map画面（1270行）
  horoscope.html      ← Horo画面（1730行）
  tarot.html          ← Tarot画面（1330行）
  galaxy.html         ← Galaxy画面（810行）
  sanctuary.html      ← Sanctuary画面（190行）
  shared/
    styles.css        ← 共通CSS（155行）
    nav.js            ← 5タブナビ（25行）
    vibe.js           ← vibe_score計算（55行）
    stella.js         ← Stellaメッセージ（95行）
    events.js         ← Moonイベント（220行）
```
