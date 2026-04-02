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
| Sanctuary | `sanctuary.html` | プロフィール + Silent Hours + Cosmic Pro（UI表示のみ） |

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
- 運勢カテゴリ（癒し/金運/恋愛/仕事/コミュニケーション）
- Fortune Sheet（16方位ランキング）
- レイヤーパネル（チャート/惑星グループ/運勢フィルタ）
- ビューポイント保存（4スロット、絵文字ピッカー、ジオコーディング）
- タロットブリッジ（Tarot→Map連携）
- パーティクルエフェクト（メテオ/衝撃波/収束）

#### V7統合で追加
- **vibe_scoreセクターブースト**: `rebuild()` 時に `loadVibe()` の値 ×2 を全方位スコアに上乗せ
- **Stellaメッセージ vibe連携**: タロット未引き時は `generateStellaMessage()` で日本語メッセージ表示
- **Moon自動検出**: `checkMoonEvents()` でNew/Full Moon当日にオーバーレイ自動発火
- **共通JS読み込み**: nav.js, vibe.js, stella.js, events.js

### 2. Horo (`horoscope.html`)

#### 既存機能
- SVGホロスコープチャート（600×600）
- 1重/2重（N+T, N+P）モード切替
- 天体位置テーブル
- アスペクトフィルター（性質/運勢/惑星グループ）
- パターン検出（Grand Trine/T-Square/Yod）
- 60日先予測スキャン
- モバイルボトムシート（ドラッグ対応）

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

### 4. Galaxy (`galaxy.html`)

#### 内部タブ
| タブ | 機能 |
|------|------|
| 🌀 Cycle | 28日3Dスパイラル（現在のサイクル） |
| ✦ Star Atlas | 完了サイクル星座アーカイブ |

#### Cycle タブ
- **3Dスパイラル**: θ = (d/28)×4.2π, r = b×θ, b = min(W,H)×0.057
- **呼吸アニメ**: 個別sin()位相（2〜4秒周期）、opacity 0.7→1.0
- **vibeToColor**: ドット色が vibe_score で変化（deep-blue→cyan→gold）
- **is_aligned → 星光芒**: 4方向ライン + 回転シマー
- **ドットタップ → ポップアップ**: カード名/vibe値/quote（3.5秒自動消去）
- **3Dインタラクション**: ドラッグ/イナーシャ/ホイールズーム/ピンチズーム
- **Day Badge**: 「12 of 28」
- **Stella メッセージ**: vibe_scoreベースで動的生成

#### Star Atlas タブ
- **星座カードグリッド**: 2カラム、ミニキャンバス（Catmull-Rom スプライン描画）
- **リプレイモーダル**: 300×300 キャンバス、2.8秒アニメーション再生
- **Cosmic Pro バナー**: $7.99/月 UI

#### 星座形成アニメーション（8秒・4ステージ）
1. **Convergence** (0〜2s): ドットが中心に収束
2. **Ignition** (2〜4s): Day1→28が順次フラッシュ、ターゲット位置へ移動
3. **Linking** (4〜6.5s): Catmull-Romスプラインが描画
4. **Naming** (6.5〜8s): シンボル名・クォートがフェードイン

#### Star Atlas 名前生成（モック）
- テンプレート: `[形容詞] + [名詞]`（英語）/ `[形容詞]の + [名詞]`（日本語）
- seedCard + 日付をシードにした決定的生成
- 本番: Claude API (Sonnet) で動的生成

#### デモボタン
| ボタン | 機能 |
|--------|------|
| 🌑 New Moon | New Moonオーバーレイ（intention入力） |
| 🌕 Full Moon | Full Moonオーバーレイ（Disintegrate） |
| ✨ Complete | 星座形成アニメーション → Star Atlas保存 |

#### localStorage連携
- `solara_daily_vibes` — 日次vibeスコア蓄積（最大28件）→ スパイラルに反映
- `solara_galaxy_cycles` — 完了サイクル保存・読み込み
- 星座形成完了 → 新サイクル自動保存 → グリッド再描画

### 5. Sanctuary (`sanctuary.html`)

#### 表示内容
- **プロフィール**: 名前（Hayashi Koji）、Free Tier
- **Stellar Profile**: 生年月日/出生地/出生時刻
- **Sanctuary Sleep**: Silent Hoursトグル + Sleep Window
- **Cosmic Pro**: サブスクカード（$7.99/月、$59.99/年）— UI表示のみ
- **App設定**: Language / Notifications / Rate / Terms

---

## データフロー

### localStorage キー一覧
| キー | 用途 | 管理画面 |
|------|------|----------|
| `solara_vibe_today` | 当日vibe_score | Tarot→Map/Galaxy |
| `solara_mood` | ムード値 | Tarot |
| `solara_tarot_bridge` | タロット→地図ブリッジ | Tarot→Map |
| `solara_natal_history` | タロット履歴（50件） | Tarot |
| `solara_vp_slots` | ビューポイント4スロット | Map |
| `solara_vp_last` | 最後の地図中心座標 | Map |
| `solara_fortune_cache` | 占い結果日キャッシュ | Horo |
| `solara_intentions` | New Moon intentions | events.js |
| `solara_moon_event_shown` | Moon発火済みフラグ | events.js |
| `solara_daily_vibes` | 日次vibeデータ（28件） | Galaxy |
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
