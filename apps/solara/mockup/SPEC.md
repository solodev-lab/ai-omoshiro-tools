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
- セクター色: カテゴリ連動（総合=金#C9A84C、癒し=#64C8B4、金運=#F5D76E、恋愛=#FF88B4、仕事=#6BB5FF、話す=#B088FF）
- Fortune Sheet（16方位ランキング）
- レイヤーパネル・VPパネル: 左側縦並び40px丸ボタン（検索→☰→📍）、右端フリー
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

#### Fortune Reading データ構造
```javascript
FORTUNE_CATEGORIES = [
  { id:'overall', icon:'✦', label:'全体運', color:'#F6BD60' },
  { id:'love',    icon:'💕', label:'恋愛運', color:'#FF6B9D' },
  { id:'money',   icon:'💰', label:'金運',   color:'#FFD370' },
  { id:'career',  icon:'💼', label:'仕事運', color:'#FF8C42' },
  { id:'communication', icon:'💬', label:'対話運', color:'#6BB5FF' },
];
// ✅ Gemini 2.5 Flash API で動的生成（実装済み）
// - astronomy-engine で検出した lastAspectsFound をテキスト化してプロンプトに渡す
// - 鑑定文には実際のアスペクト情報（惑星名・角度・性質）が含まれる
// - 全体運: 450字、個別運: 250字
// - フォールバック: APIエラー時は FORTUNE_MOCK テンプレートを表示
// - 日キャッシュ: solara_fortune_cache（同日はlocalStorageから返却）
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
  - ✅ Gemini 2.5 Flash API でカード固有の鑑定文を動的生成（実装済み）
  - 450字程度、カード象徴・エレメント・支配惑星を織り込み
  - フォールバック: APIエラー時はエレメント別テンプレート表示
  - 日キャッシュ: `tarot_ai_reading_{cardId}_{date}`（キャッシュ時は即表示、初回のみタイプライター演出）
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

##### Beat 3: 刻星化 — 新月前日の振り返り演出
- **トリガー**: 次の新月の前日（cycleEnd - 1日）にインテンション設定済みかつ未刻星の場合
- **表示内容**:
  - 選んだインテンション + 満月時の中間評価バッジを表示
  - **天体イベント連動の温かいメッセージ**（月別100字、12ヶ月分定義済み）
  - 「この周期の軌跡が星座になります」
  - 「✦ 星座を刻星化する」ゴールドボタン（選択肢なし、振り返りのみ）
- **ボタン押下時の動作**:
  - 即座にStar Atlasにサイクルデータを保存（アニメーション前に永続化）
  - 星座形成アニメーション（8秒4ステージ: CONVERGENCE→IGNITION→LINKING→COMPLETE）
  - 「View in Star Atlas ✦」→ Star Atlasタブに自動遷移
- **Not nowは廃止**: 刻星化画面が出たら「✦ 星座を刻星化する」を押すのみ
- **未刻星の救済**: 新月が来た時に前周期の未刻星インテンションを検出→刻星化オーバーレイを優先表示（アプリ閉じて見逃した場合の救済）

##### 天体イベントデータ（2026年）
- `assets/celestial_events_2026.json` に12ヶ月分を静的定義
- 各月: 新月日/サイン、満月日/名前、天体イベントリスト、3テーマ（EN/JP）
- 主要イベント: 水星逆行×3、金星逆行、土星逆行、冥王星逆行、日食×2、月食×2、
  海王星牡羊座入り、土星牡羊座入り、天王星双子座入り、木星獅子座入り

---

#### Star Atlas タブ
- **星座カードグリッド**: 2カラム、ミニキャンバス描画
- **リプレイオーバーレイ**: 300×300 キャンバス、刻星化アニメーション再生
- **星座イラスト背景**: 名詞に対応するイラスト（白線画WebP）を15-20%不透明度でオーバーレイ

#### 星座形成ロジック（v2: 3Dアナモルフィック方式）

**旧方式（廃止）**: 全ドットをスパイラル上に配置 → Catmull-Romで全接続 → 斜め線にしかならない

**新方式: 3D逆投影 + アンカー/フィールドスター分離**

1. **3D逆投影（日々のプロット）**:
   - 最終的な2D星座形状を先に決定（アンカー配置 → nearest-neighbor巡回）
   - 各ドットにランダムなz座標（奥行き）を付与 → 3D空間に配置
   - 3層構造: Layer 0（奥 z=-0.6〜-0.2）/ Layer 1（中 z=-0.2〜0.2）/ Layer 2（手前 z=0.2〜0.6）
   - カードIDベースでlayer振り分け（決定論的）
   - 日々の表示はカメラ角度θ=55°（斜め） → ドットがバラバラに見える

2. **刻星化アニメーション（周期完了時）**:
   - カメラ角度θを 55° → 0°（正面）へ3秒でイージング
   - z成分が消失 → ドットが2D星座位置に収束（「星が揃う」瞬間）
   - 投影計算: `screenX = x * cos(θ) + z * sin(θ)`, `screenY = y`
   - 線が引かれる（1.5秒） → アンカー間を直線接続
   - 星座イラストがフェードイン（2秒） → 名詞に対応する白線画が背景に出現
   - 星座名 + レアリティがスタンプ表示（0.8秒）

3. **アンカー/フィールドスター分離**:
   - **アンカー（Major Arcana 6-9枚）**: 星座の骨格を形成、直線で接続
   - **フィールドスター（Minor Arcana）**: 背景の散在星として小さく表示（接続しない）
   - Major Arcanaが5枚未満の場合、Minor Arcanaから昇格
   - **nearest-neighbor巡回**: アンカーを最近傍順に接続 → 線の交差を防止
   - **直線接続**（Catmull-Romスプライン廃止） → 実際の星座図のようなクリーンな形

4. **ドット配置（Golden Angle方式）**:
   - `angle = cardId × 137.508° + baseRotation`（黄金角で全方向に均等分散）
   - `distance = f(dayIndex, cardId)`（日数 + カード番号で距離決定）
   - Major Arcanaは外側寄り（目立つ位置）
   - 結果: 毎回ユニークかつ美しい形状を自動生成

#### 星座イラスト背景
- **方式**: 名詞ごとに1枚の白線画イラスト（黒背景WebP, 512×512）
- **合成**: screenブレンドで黒が透過 → 白線画だけが星座の背景に浮かぶ
- **不透明度**: 15-20%（うっすら表示、星座の補助的役割）
- **色相シフト**: 形容詞に応じて色味を変更（Golden→暖色、Silver→寒色、Crimson→赤系 等）
- **格納**: `share-assets/constellation-art/{noun}.webp`
- **生成**: Gemini直接（gemini-3.1-flash-image-preview）、コスト$0

#### Star Atlas 名前生成
- **seedCard**: 周期内で最頻出の大アルカナ（fallback: 最頻出スートのエース）
- **テンプレート**: `The [形容詞] [名詞]`（EN）/ `[形容詞][名詞]`（JP）
- **語彙（v2）**: 形容詞20語（10色×2段階） × 名詞61語（50通常+11レア） = 1,220通り（月1で約100年分）
  - 形容詞: 10色系統×2段階（例: Golden/Sacred = 金系の明/暗）
  - 名詞: 11カテゴリ（天体/神話/動物/武器/王権/自然/建造物/象徴/楽器/身体/幾何）
  - 名詞ティア: Common(27) / Uncommon(15) / Rare(8) / Legendary(11=各カテゴリ1レア)
  - 詳細リスト: `constellation_nouns.md` 参照
- **重複なし保証**: ユーザーの既出星座名を保存、新規生成時に除外
- **ハッシュ**: `seedCardId + ISO日付` → 決定的生成（既出除外後）

#### レアリティシステム（数学的）
- 星座名の出現確率をハッシュ分布から算出（サーバー不要）
- **ランク**:
  - ★★★★★ Mythic    — 出現率 1%以下
  - ★★★★  Legendary — 出現率 1-2%
  - ★★★   Rare      — 出現率 2-4%
  - ★★    Uncommon  — 出現率 4-7%
  - ★     Common    — 出現率 7%以上
- **表示場所**: Star Atlasカード、刻星化演出、シェアカード
- **将来計画**: Cloudflare Worker経由でリアルユーザー集計に移行
  - `POST /api/constellation-stats` で刻星化時に報告
  - `GET /api/constellation-stats/{name}` で実測出現率を取得
  - リアル集計と数学的レアリティを併記

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
    lunar_intention.dart    — インテンション + 中間 + 刻星化
  utils/
    moon_phase.dart         — 月齢計算（Metonic cycle）
    constellation_namer.dart — 星座命名（ハッシュベース）
    tarot_data.dart         — JSONアセットローダー
    solara_storage.dart     — SharedPreferences wrapper
    celestial_events.dart   — 天体イベントローダー
  widgets/
    cycle_spiral_painter.dart     — 3Dスパイラル描画
    constellation_painter.dart    — 星座描画（フル + ミニ）
    moon_overlay.dart             — 新月/満月/刻星化オーバーレイ
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

#### 称号システム（Title System）

##### 概要
ホロスコープ（先天的本質）× タロット選択（今の感性）の二層構造で、ユーザー固有の称号を生成する。

```
称号 = [太陽星座の外面] + [接続詞] + [月星座の内面] + [クラス名]

例:
  JP: 「調子に乗って自由に表現しちゃったあとに反省会が欠かせないKnight」
  EN: (JP確定後に作成)
```

##### メイン称号（144通り）— テンプレート合成方式

太陽星座（外面の行動パターン）+ 接続詞 + 月星座（内面の裏の顔）+ クラス名で合成。
12 × 12 = 144通り。カジュアルで共感しやすいトーン（MBTI的ミーム文化に合わせる）。

**テンプレート構造**:
```
[太陽パーツ] + [接続詞] + [月パーツ] + [クラス名]
例: 「調子に乗って自由に表現しちゃったあとに反省会が欠かせないKnight」
```

**接続詞パターン（ランダムまたは太陽×月の組み合わせで選択）**:
- 「〜けど実は〜」
- 「〜のに実は〜」
- 「〜したあとに〜」
- 「〜だし〜」

**太陽星座 → 外面パーツ（行動パターン）**

| 星座 | JP |
|------|-----|
| 牡羊座 | 思い立ったら即行動する猪突猛進型 |
| 牡牛座 | 一度決めたらテコでも動かないマイペース |
| 双子座 | 話題が3秒で変わるおしゃべり好き |
| 蟹座 | 身内には甘いけど外には壁を作りがち |
| 獅子座 | 調子に乗って自由に表現しちゃう |
| 乙女座 | 細かいところが気になって仕方ない完璧主義 |
| 天秤座 | みんなに良い顔しすぎて疲れる八方美人 |
| 蠍座 | 好きなものへの執着がすごい一途タイプ |
| 射手座 | 楽しそうなことに飛びつく自由人 |
| 山羊座 | コツコツ積み上げないと気が済まない努力家 |
| 水瓶座 | 人と同じが嫌で逆張りしがち |
| 魚座 | 妄想が止まらないロマンチスト |

**月星座 → 内面パーツ（裏の顔）**

| 星座 | JP |
|------|-----|
| 牡羊座 | 実はすぐカッとなって後悔する |
| 牡牛座 | 実は変化が怖くてしがみつく |
| 双子座 | 実は考えすぎて頭の中が忙しい |
| 蟹座 | 実はナイーブで反省会が欠かせない |
| 獅子座 | 実は褒められないと不安になる |
| 乙女座 | 実は自分にダメ出しが止まらない |
| 天秤座 | 実は本音を隠すのが上手すぎる |
| 蠍座 | 実は傷つきやすくて根に持つ |
| 射手座 | 実は飽きっぽくて続かない |
| 山羊座 | 実は弱みを見せるのが怖い |
| 水瓶座 | 実は寂しがり屋なのに素直になれない |
| 魚座 | 実は現実逃避が得意すぎる |

**144文の手作り調整**: 太陽×月の全144パターンをテンプレート合成後、手動で文章を自然に整える。
（別セッションで作業予定）

**EN版**: JP確定後にトーンを合わせて作成（カジュアル英語、Z世代向け）

##### サブタイトル（25クラス）— タロット診断から決定

大アルカナ3択×15ラウンド + 人物札4択×4スート = 計19問の診断で決定。
大アルカナとは無関係の独自分類。5軸×5クラス = 25種。

**5軸の定義**

| 軸 | 意味 |
|------|------|
| Power（力） | 突破力・支配・戦闘 |
| Mind（知） | 知識・戦略・分析 |
| Spirit（霊） | 直感・神秘・信仰 |
| Shadow（影） | 自由・欺瞞・変革 |
| Heart（心） | 共感・創造・調和 |

**25クラス配置表**

各軸内の5クラスは、人物札選択の傾向（Page/Knight/Queen/King/混合）で振り分ける。
「混合」= 人物札4問で1つの人物タイプに偏らなかったバランス型。レア枠。

***Power軸（力・突破・支配）***

| 人物傾向 | クラス | Light | Shadow |
|----------|--------|-------|--------|
| Page | Knight | 「守る」と決めたら迷わない | 守りたいものが多すぎて忙しい |
| Knight | Dragoon | とりあえず飛んでから考える | 飛び込みすぎて毎回びっくりされる |
| Queen | Paladin | 困ってる人を見ると体が動く | 正義感が強すぎて頼られがち |
| King | Overlord | 気づいたら全部仕切っている | リーダーになりすぎて休めない |
| 混合 | Spellblade | なんでもそこそこできてしまう | 器用すぎて自分の専門が決められない |

***Mind軸（知・戦略・分析）***

| 人物傾向 | クラス | Light | Shadow |
|----------|--------|-------|--------|
| Page | Sage | 「なぜ？」が止まらない | 知りたいことが多すぎて夜更かしする |
| Knight | Strategist | 三手先まで自然と見えている | 先が見えすぎて一人で心配する |
| Queen | Chancellor | 誰が何を求めているか分かる | 気配り上手すぎて自分を後回しにする |
| King | Judge | おかしいことはおかしいと言える | 筋が通らないと気になって眠れない |
| 混合 | Wizard | 好きなことなら永遠にやれる | 没頭すると時間を忘れてご飯を忘れる |

***Spirit軸（霊・直感・信仰）***

| 人物傾向 | クラス | Light | Shadow |
|----------|--------|-------|--------|
| Page | Cleric | いるだけで周りが安心する | 優しすぎて全員の相談役になる |
| Knight | Astrologer | 見えないつながりを見つけるのが得意 | 星が気になりすぎて空ばかり見ている |
| Queen | Oracle | 言葉にする前に空気で分かる | 感受性が高すぎて映画で毎回泣く |
| King | Fate Weaver | 人の才能を見抜いて背中を押せる | おせっかいが止まらない |
| 混合 | Druid | 自然の中にいると充電できる | 一人の時間が好きすぎて誘いを忘れる |

***Shadow軸（影・自由・変革）***

| 人物傾向 | クラス | Light | Shadow |
|----------|--------|-------|--------|
| Page | Trickster | 退屈な場の空気を一瞬で変える | 面白いことを思いつくと黙っていられない |
| Knight | Liberator | 「おかしい」と思ったら声を上げる | 自由すぎてスケジュールが守れない |
| Queen | Phantom | 気配を消すのが天才的にうまい | 存在感を消すのが上手すぎて探される |
| King | Rogue | 自分のやり方で結果を出す | マイペースすぎて周りがハラハラする |
| 混合 | Alchemist | 関係なさそうなものを組み合わせて化ける | 好奇心が強すぎて余計なものまで作る |

***Heart軸（心・共感・創造）***

| 人物傾向 | クラス | Light | Shadow |
|----------|--------|-------|--------|
| Page | Bard | その場にいる人を全員笑顔にする | 共感力が高すぎてもらい泣きする |
| Knight | Sorcerer | 感情のエネルギーがそのまま力になる | 感情豊かすぎて表情が忙しい |
| Queen | Enchanter | 会った人がなぜか好きになる | 魅力的すぎて誤解される |
| King | Emperor | 人が自然と集まってくる | 理想が高すぎて妥協できない |
| 混合 | Chronomancer | 「あの瞬間」を大事にできる | 思い出を大事にしすぎてアルバムが増え続ける |

**Light/Shadow（英語版）**

| Class | Light (EN) | Shadow (EN) |
|-------|------------|-------------|
| Knight | Never hesitates when someone needs protecting | Too many people to protect, not enough hours |
| Dragoon | Leaps first, thinks later | Keeps surprising everyone by diving in headfirst |
| Paladin | Body moves before brain when someone's in trouble | Too reliable — everyone's go-to hero |
| Overlord | Somehow ends up running everything | Can't stop leading long enough to rest |
| Spellblade | Annoyingly good at everything | Too versatile to pick a specialty |
| Sage | Can't stop asking "but why?" | Too many rabbit holes, not enough sleep |
| Strategist | Sees three moves ahead without trying | Worries alone because they see too far |
| Chancellor | Knows what everyone needs before they ask | So busy reading the room, forgets to read themselves |
| Judge | Calls out what's wrong without flinching | Can't sleep when something doesn't add up |
| Wizard | Could do one thing forever and never get bored | Forgets to eat when hyperfocused |
| Cleric | People feel safe just being near them | Too kind — accidentally becomes everyone's therapist |
| Astrologer | Finds invisible connections everywhere | Stares at the sky so much, forgets the ground |
| Oracle | Reads the room before a word is spoken | So sensitive they cry at every movie |
| Fate Weaver | Spots hidden talent and pushes people forward | Can't stop meddling |
| Druid | Recharges in nature like a solar panel | Loves alone time so much, forgets to reply |
| Trickster | Flips a boring room upside down in seconds | Can't keep a good idea to themselves |
| Liberator | Speaks up the moment something feels off | Too free-spirited to keep a schedule |
| Phantom | Disappears so well it's basically a superpower | So good at vanishing, people file missing reports |
| Rogue | Gets results their own way, every time | So independent it makes everyone nervous |
| Alchemist | Combines random things into something brilliant | Too curious — builds stuff nobody asked for |
| Bard | Makes every person in the room smile | Empathy so strong they ugly-cry for others |
| Sorcerer | Turns raw emotion into pure power | So expressive their face never sits still |
| Enchanter | People just like them and can't explain why | Too charming — constantly misunderstood |
| Emperor | People naturally gravitate and gather around | Standards so high they can't compromise |
| Chronomancer | Treasures moments others let slip by | Hoards memories until the album shelf collapses |

##### 診断フロー

```
[Sanctuary] 「✦ あなたの称号を受け取る」ボタン
  ↓
[パート1] 数札4択 × 9ラウンド（R1〜R9）→ ウォームアップ + 5軸スコア蓄積
  ↓
[パート2] 大アルカナ3択 × 15ラウンド（R10〜R24）→ 5軸スコア本判定
  ↓
[パート3] 人物札4択 × 4スート（R25〜R28）→ 軸内クラス振り分け
  ↓
[鍛造演出] → [開封] → [シェア]

合計: 28問
```

**全パート共通: カードは絵のみ表示、説明文なし。質問文を読み、直感でカードを選ぶ。**

**パート1: 数札選択（9ラウンド / R1〜R9）— ウォームアップ + 5軸スコア蓄積**

Ace〜9のテーマに沿った問い → 4スート（Wands/Cups/Swords/Pentacles）の絵を提示 → 1枚選ぶ。
スート → 軸対応: Wands=Power, Cups=Heart, Swords=Mind, Pentacles=Spirit/Shadow（質問で振り分け）

| R | 数 | 質問 (JP) | 質問 (EN) | 表示カード |
|---|---|---|---|---|
| 1 | Ace | 新しい何かが始まるとき、あなたが最初に手に取るのは？ | When something new begins, what do you reach for first? | Ace of W/C/S/P |
| 2 | 2 | 選択する時が来た。なにをおもう？ | The moment of choice has come. What goes through your mind? | 2 of W/C/S/P |
| 3 | 3 | あなたは大きな決断をした。どんな気持ち？ | You've made a big decision. How does it feel? | 3 of W/C/S/P |
| 4 | 4 | 安心を感じるのはどんなとき？ | When do you feel most at ease? | 4 of W/C/S/P |
| 5 | 5 | 困難にぶつかったとき、あなたはどうなっている？ | When you hit a wall, what happens to you? | 5 of W/C/S/P |
| 6 | 6 | あなたが癒されるのは？ | What heals you? | 6 of W/C/S/P |
| 7 | 7 | 眠れない夜、頭をよぎるのは？ | What crosses your mind on sleepless nights? | 7 of W/C/S/P |
| 8 | 8 | 前進する為に、やるべきことは | What must be done to move forward? | 8 of W/C/S/P |
| 9 | 9 | 今の自分の姿にちかいのは？ | Which one looks most like you right now? | 9 of W/C/S/P |

**パート2: 大アルカナ選択（15ラウンド / R10〜R24）— 5軸スコア本判定**

3枚ずつ提示、1枚選ぶを15ラウンド繰り返す。
- 異なる軸から1枚ずつ出す（毎回「どの軸が自分に近いか」を測る）
- 同じカードが複数ラウンドで再登場する（組み合わせは毎回異なる）
- 選んだカードの軸に+1点
- 同点の場合は後半ラウンドの選択を優先

**大アルカナの5軸配置**

| 軸 | カード |
|------|------|
| Power | 皇帝(4), 戦車(7), 力(8), 塔(16) |
| Mind | 魔術師(1), 隠者(9), 正義(11), 審判(20) |
| Spirit | 女教皇(2), 法王(5), 星(17), 月(18) |
| Shadow | 運命の輪(10), 吊るされた男(12), 死神(13), 悪魔(15) |
| Heart | 女帝(3), 恋人(6), 節制(14), 太陽(19) |
| 特別 | 愚者(0), 世界(21) — ワイルドカード（選択時、最も低い軸に+1点） |

**15ラウンド提示テーブル（確定）**

カードが全員「人」のラウンド → 「誰」系の問い。物/情景が混じるラウンド → 「何を」系の問い。

| R | 質問 (JP) | 質問 (EN) | カードA | カードB | カードC |
|---|---|---|---|---|---|
| 10 | 生まれ変わるとしたら、誰になる？ | If reborn, who would you become? | 皇帝(4) P | 魔術師(1) M | 女帝(3) H |
| 11 | 迷ったとき、頼りにしたいのは？ | When lost, what do you trust? | 女教皇(2) Sp | 運命の輪(10) Sh | 戦車(7) P |
| 12 | 旅の仲間にするなら、誰を選ぶ？ | Who would you choose as your travel companion? | 恋人(6) H | 隠者(9) M | 死神(13) Sh |
| 13 | あなたの師匠になるのは？ | Who would be your mentor? | 力(8) P | 法王(5) Sp | 節制(14) H |
| 14 | 深夜、語り明かしたい相手は？ | Who would you talk with until dawn? | 悪魔(15) Sh | 正義(11) M | 星(17) Sp |
| 15 | 壁にぶつかったとき、あなたの心は？ | When you hit a wall, where does your heart go? | 太陽(19) H | 吊るされた男(12) Sh | 塔(16) P |
| 16 | 夜明け前、あなたを導くのは？ | Before dawn, what guides you? | 審判(20) M | 月(18) Sp | 皇帝(4) P |
| 17 | あなたを理解してくれるのは？ | Who truly understands you? | 死神(13) Sh | 女帝(3) H | 女教皇(2) Sp |
| 18 | 世界を変えるなら、何を手に取る？ | To change the world, what would you reach for? | 戦車(7) P | 魔術師(1) M | 運命の輪(10) Sh |
| 19 | 帰る場所で待っていてほしいのは？ | Who do you want waiting when you come home? | 法王(5) Sp | 恋人(6) H | 隠者(9) M |
| 20 | 未知の扉の向こうにあってほしいのは？ | What do you hope lies beyond the unknown door? | 力(8) P | 運命の輪(10) Sh | 愚者(0) ★ |
| 21 | 大切な人に贈りたい力は？ | What power would you gift to someone you love? | 正義(11) M | 節制(14) H | 星(17) Sp |
| 22 | 手放したとき、残るものは？ | When you let go, what remains? | 吊るされた男(12) Sh | 月(18) Sp | 世界(21) ★ |
| 23 | あなたが一番輝ける場所は？ | Where do you shine brightest? | 太陽(19) H | 塔(16) P | 愚者(0) ★ |
| 24 | この旅の終わりに、誰として立っていたい？ | At the end of this journey, who do you want to be? | 審判(20) M | 悪魔(15) Sh | 世界(21) ★ |

軸略記: P=Power, M=Mind, Sp=Spirit, Sh=Shadow, H=Heart, ★=特別（ワイルドカード）
※ 愚者・世界はワイルドカード: 選択時に最も低い軸に+1点（バランスを取る力）
※ 運命の輪のみ3回登場、他は全カード2回登場

**パート3: 人物札選択（4ラウンド / R25〜R28）— 軸内クラス振り分け**

スートごとにPage/Knight/Queen/Kingの絵を4枚提示 → 1枚選ぶ。

| R | スート | 質問 (JP) | 質問 (EN) | 表示カード |
|---|---|---|---|---|
| 25 | Wands/火 | あなたの情熱の形は？ | What shape does your passion take? | Page/Knight/Queen/King of Wands |
| 26 | Cups/水 | 奇跡が目の前に降りた瞬間、あなたは？ | When a miracle descends before you? | Page/Knight/Queen/King of Cups |
| 27 | Swords/風 | 答えが出ないときのあなたはどんな様子？ | When there's no answer, what do you look like? | Page/Knight/Queen/King of Swords |
| 28 | Pentacles/地 | あなたが築きたいものは？ | What do you want to build? | Page/Knight/Queen/King of Pentacles |

**スコアリング**
1. 数札9問（パート1）→ スート選択傾向で5軸スコア蓄積（Wands=Power+1, Cups=Heart+1, Swords=Mind+1, Pentacles=状況によりSpirit/Shadow+1）
2. 大アルカナ15問（パート2）→ 選んだカードの軸に+1点 → 5軸スコア本判定
3. パート1+パート2の合算 → 最高得点の軸が確定（同点は後半ラウンド優先）
4. 人物札4問（パート3）→ Page/Knight/Queen/King の選択傾向 → 軸内クラス確定
   - Page 2回以上 → Page型
   - Knight 2回以上 → Knight型
   - Queen 2回以上 → Queen型
   - King 2回以上 → King型
   - 全部バラバラ → 「混合」枠（レアクラス）

##### 再診断ルール

| 条件 | 回数 |
|------|------|
| 初回 | 2回まで無料。1回目の結果後「これでいく」or「もう一度診断する」を選択。2回目で確定 |
| 以降 | Cosmic Pro限定。月1回、新月サイクルに合わせて再診断解放（Galaxy連動） |

##### 演出

**パート1: 数札選択（9ラウンド）— ウォームアップ**
- 4枚のカードが横並びで浮かび上がる
- 選んだカードが光って中央に寄る
- 軽快なテンポ（数札は直感的に選びやすいので短めの間）

**パート2: 大アルカナ選択（15ラウンド）— メインフェーズ**
- 暗闇から3枚のカードが浮かび上がる
- 選んだカードが光って吸い込まれる
- 背景に選んだ軸の色が少しずつ溜まっていく（Power=赤、Mind=青、Spirit=紫、Shadow=黒、Heart=金）
- 進捗: 星が1つずつ灯る（15個の星座を結んでいくイメージ）

**パート3: 人物札選択（4ラウンド）— 最終フェーズ**
- スートの元素が背景に（Wands=炎、Cups=水流、Swords=風、Pentacles=大地）
- 4人物のシルエットが並ぶ → タップで正体が明かされる
- パート2より「自分と向き合う」静かなトーン

**鍛造演出（5〜8秒）**
- 画面中央に光の炉が出現
- 全パートで集めた軸の色 + 元素が炉に流れ込む
- 炉が輝き、称号の文字が浮かび上がる
- ハプティクス（振動）フィードバック

**開封（段階表示）**
1. メイン称号がゆっくりフェードイン（2秒）
2. 「———」ラインが引かれる（1秒）
3. サブタイトル（クラス名）がスタンプのように押される（1秒）
4. Light文が下から浮かぶ（1.5秒）
5. Shadow文が最後にふわっと現れる（1.5秒）
6. 全体が完成 → シェアボタン出現

##### Stellaメッセージ連携

クラスごとに3フレーズの呼びかけを用意（日替わりまたはランダムで回す）。
Map画面のStella冒頭に表示。

| クラス | フレーズ1 | フレーズ2 | フレーズ3 |
|--------|-----------|-----------|-----------|
| Knight | 勇敢なる騎士よ | 剣を掲げる者よ | 守るべき人を想う君へ |
| Dragoon | 空を翔ける者よ | 恐れ知らずの突撃手よ | 風を切って進む君へ |
| Paladin | 光をまとう聖騎士よ | 慈悲の盾を持つ者よ | 正しさを信じる君へ |
| Overlord | 全てを統べる者よ | 玉座に座る覇者よ | 頂点を見据える君へ |
| Spellblade | 剣と魔を束ねる者よ | 二つの力を持つ者よ | どちらも手放さない君へ |
| Sage | 知を愛する求道者よ | 真理を追う者よ | 問い続ける君へ |
| Strategist | 盤上を見渡す軍師よ | 三手先を読む者よ | 静かに勝利を描く君へ |
| Chancellor | 影の立役者よ | 糸を引く知恵者よ | 誰より全体が見える君へ |
| Judge | 公正なる裁定者よ | 真実を見抜く眼よ | 曇りなき目を持つ君へ |
| Wizard | 探究の魔術師よ | 未知を愛する者よ | 好奇心が止まらない君へ |
| Cleric | 癒しの祈り手よ | 静かな光を灯す者よ | そこにいるだけで安心をくれる君へ |
| Astrologer | 星を読む旅人よ | 天空の地図を持つ者よ | 見えない線を辿る君へ |
| Oracle | 静かなる預言者よ | 言葉になる前を知る者よ | 空気で全てを感じ取る君へ |
| Fate Weaver | 運命を紡ぐ者よ | 糸を手繰る導き手よ | 人の才能を照らす君へ |
| Druid | 森と語る者よ | 境界に立つ調和の番人よ | 静けさの中で充電する君へ |
| Trickster | やあ、いたずら好きの君 | 退屈を壊す天才よ | 黙っていられない君へ |
| Liberator | 鎖を断つ解放者よ | 声を上げる勇者よ | 自由を愛しすぎる君へ |
| Phantom | 影に溶ける者よ | 気配を消す達人よ | 見えないのに確かにいる君へ |
| Rogue | 我が道を行く者よ | ルールの外に立つ者よ | 自分のやり方を貫く君へ |
| Alchemist | 禁断の錬金術師よ | 混ぜるな危険の探求者よ | 何でも試してみたい君へ |
| Bard | 歌と物語の語り手よ | 笑顔を連れてくる者よ | 場の空気を変えられる君へ |
| Sorcerer | 感情が魔力になる者よ | 心の炎を燃やす者よ | 喜怒哀楽が全部パワーの君へ |
| Enchanter | 人を魅了する者よ | 世界を書き換える魔法使いよ | 会うだけで何かが変わる君へ |
| Emperor | 人が集まる王よ | 国を築く者よ | 理想を諦めない君へ |
| Chronomancer | 時を操る者よ | 瞬間を永遠にする者よ | 思い出を宝物にする君へ |

**Stellaフレーズ（英語版）**

| Class | Phrase 1 | Phrase 2 | Phrase 3 |
|-------|----------|----------|----------|
| Knight | Brave knight | You who raise your sword | To you who fight for those you love |
| Dragoon | Sky rider | Fearless charger | To you who cut through the wind |
| Paladin | Holy knight of light | You who bear the shield of mercy | To you who believe in what's right |
| Overlord | Ruler of all | Sovereign on the throne | To you who never look away from the top |
| Spellblade | Bearer of blade and spell | You who wield two powers | To you who refuse to choose just one |
| Sage | Seeker of truth | You who chase wisdom | To you who never stop asking |
| Strategist | Grand tactician | You who read three moves ahead | To you who quietly design victory |
| Chancellor | The one behind the curtain | Master of threads | To you who see the whole picture |
| Judge | Arbiter of truth | Eyes that pierce deception | To you whose gaze never clouds |
| Wizard | Wizard of wonder | You who love the unknown | To you whose curiosity never sleeps |
| Cleric | Gentle healer | You who light a quiet flame | To you whose presence is comfort enough |
| Astrologer | Star traveler | You who hold the celestial map | To you who trace the invisible lines |
| Oracle | Silent prophet | You who know before words are spoken | To you who feel everything in the air |
| Fate Weaver | Weaver of destiny | You who pull the thread of fate | To you who shine a light on hidden talent |
| Druid | Whisperer of the forest | Guardian of the boundary | To you who recharge in stillness |
| Trickster | Hey there, troublemaker | Genius of chaos | To you who can't keep quiet |
| Liberator | Breaker of chains | Voice of the voiceless | To you who love freedom too much |
| Phantom | One who melts into shadow | Master of disappearing | To you who are invisible yet always there |
| Rogue | Lone wolf | You who stand outside the rules | To you who always do it your way |
| Alchemist | Forbidden alchemist | You who mix the unmixable | To you who want to try everything |
| Bard | Teller of tales | You who bring the smiles | To you who change the room just by walking in |
| Sorcerer | You whose emotions are magic | You who burn with inner fire | To you whose every feeling is power |
| Enchanter | The one who enchants | Spellcaster who rewrites the world | To you who change something just by meeting people |
| Emperor | The one people gather around | Builder of kingdoms | To you who never give up on the dream |
| Chronomancer | Master of time | You who make moments eternal | To you who turn memories into treasure |

##### シェア機能

- フォーマット: Instagram Stories向け縦長画像（1080×1920）
- 背景色: クラスの軸で変わる（Power=赤系、Mind=青系、Spirit=紫系、Shadow=黒系、Heart=金系）
- 表示内容: メイン称号（日英）+ クラス名 + **Shadow面のみ**（カジュアルで共感・拡散しやすい）
- 太陽/月星座のシンボル表示（☉ Gemini ☽ Virgo）
- QRコード: 右下にアプリリンク
- 日本語版/英語版を自動生成
- 「Share Your Title」タップ → OS標準の共有シート

##### UI配置

**Sanctuary画面（上から順）**
```
├── COSMIC PROFILE
│   ├── 名前
│   ├── 称号表示（常時表示）
│   │   「風を駆ける灯台 — Trickster」
│   └── 出生データ（日付・時刻・場所）
├── TITLE DIAGNOSIS
│   ├── 未診断 → 「✦ あなたの称号を受け取る」ゴールドボタン
│   └── 診断済み → 称号カード（タップでLight⇔Shadowフリップ切り替え）
│       ├── Light面（デフォルト）: ライト称号+クラス名JP / クラス名EN / Light説明
│       ├── Shadow面: シャドー称号+クラス名JP / クラス名EN / Shadow説明
│       ├── Y軸180°3Dフリップ（0.6秒）、「tap to flip」ヒント表示
│       └── Cosmic Proなら「再診断する」ボタン（月1回）
├── Home Location
├── House System
├── Aspect Orbs
└── Cosmic Pro
```

**他画面での表示**

| 画面 | 表示内容 |
|------|----------|
| Map | Stellaメッセージの冒頭に呼びかけフレーズ |
| Horo | なし（チャート画面はデータに集中） |
| Tarot | なし（カード体験に集中） |
| Galaxy | Star Atlasのサイクルカードにクラスアイコン |
| Sanctuary | 称号カード常時表示 + 診断導線 |

**称号未設定時の誘導**
- プロフィール登録済み & 称号未設定 → Sanctuaryプロフィール下に「✦ あなたの称号を受け取る」ゴールドボタン
- プロフィール未設定 → まずプロフィール登録を促す（既存の導線）

##### データ永続化

| キー | 用途 |
|------|------|
| `solara_title_main` | メイン称号（太陽星座×月星座の結果） |
| `solara_title_class` | サブタイトル（25クラス名） |
| `solara_title_axis` | 5軸スコア（診断結果の内訳） |
| `solara_title_court` | 人物札選択結果（4スート分） |
| `solara_title_diagnosed_at` | 最終診断日時 |
| `solara_title_diagnosis_count` | 無料診断の使用回数（最大2） |
| `solara_title_sun` | 診断時の太陽星座（出生情報変更検知用） |
| `solara_title_moon` | 診断時の月星座（出生情報変更検知用） |

##### 出生情報変更時の称号自動更新
- 出生情報保存時に太陽/月星座を再算出し、`solara_title_sun`/`solara_title_moon`と比較
- 星座が変わった場合: メイン称号テキスト（Light/Shadow）を`TITLE_144`から自動差し替え
- 星座が変わらない場合: 何もしない
- **サブクラス（タロット28問結果）は変更しない** — タロット診断は「今の感性」であり出生情報と無関係

##### 未実装タスク（後続で詰める）
- [x] 15ラウンドの3枚提示組み合わせテーブル — 確定済み（質問文付き）
- [x] 愚者(0)・世界(21)の特別枠 — ワイルドカード方式（最も低い軸に+1）
- [x] 25クラスの英語版Light/Shadow文 — 確定済み
- [x] Stellaフレーズ75個の英語版 — 確定済み
- [ ] 144称号の英訳（Light/Shadow各144個） — 言語設定の英語対応実装時に作成する
- [ ] 言語設定機能の実装（日本語/英語切り替え）
- [ ] シェアカードの具体的ビジュアルデザイン
- [ ] 鍛造演出の詳細アニメーション仕様

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
| `solara_title_main` | メイン称号（太陽星座×月星座の結果） | Sanctuary→全画面 |
| `solara_title_class` | サブタイトル（25クラス名） | Sanctuary→全画面 |
| `solara_title_axis` | 5軸スコア（診断結果の内訳） | Sanctuary |
| `solara_title_court` | 人物札選択結果（4スート分） | Sanctuary |
| `solara_title_diagnosed_at` | 最終診断日時 | Sanctuary |
| `solara_title_diagnosis_count` | 無料診断の使用回数（最大2） | Sanctuary |

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

## シェアアセット (`share-assets/`)

SNSシェア・Instagram Stories・ギャラリー表示用の星座背景画像を格納。ベース12枚以外は全て `gemini-3.1-flash-image-preview` (Nano Banana 2) で生成、9:16縦長 (768×1376 PNG)。

### フォルダ構成

| フォルダ | 内容 | 枚数 |
|---------|------|------|
| `backgrounds_original/` | 元絵（1536×2752 2K、fal.ai Imagen生成・**保護必須・削除禁止**） | 12 |
| `backgrounds/` | 本番配信用 webp（`backgrounds_original` の変換版） | 12 |
| `backgrounds_mystical/` | 星座シンボル無し版（抽象ネビュラのみ、Nano Banana 2再生成） | 12 |
| `backgrounds_aries_variants/` | aries基形状（螺旋）× 他11属性 | 11 |
| `backgrounds_aquarius_variants/` | aquarius基形状（縦カスケード）× 他11属性 | 11 |
| `backgrounds_leo_variants/` | leo基形状（サンバースト）× 他11属性 | 11 |
| `backgrounds_pisces_variants/` | pisces基形状（波）× 他11属性 | 11 |
| `backgrounds_scorpio_variants/` | scorpio基形状（渦）× 他11属性 | 11 |
| `backgrounds_virgo_variants/` | virgo基形状（神聖幾何学）× 他11属性 | 11 |
| `constellation-art/` | 星座名詞の白線画イラスト（512×512 WebP、Galaxy Star Atlas用） | 61 |

累計: 背景画像 90枚 + 星座名詞線画 61枚

### バリエーション生成の設計思想

- **ベース形状を完全固定**、色・属性・雰囲気だけを12星座属性で切り替え
- 同一ユーザーでも「本命星座」×「運勢相手星座」の組み合わせで違う背景を出せる
- 各ベースは視覚的に明確に区別される（螺旋 / カスケード / サンバースト / 波 / 渦 / 神聖幾何学）

### 生成スクリプト

| スクリプト | 用途 |
|-----------|------|
| `generate_backgrounds_mystical.py` | 12星座の新ベース背景（シンボル無し） |
| `generate_aries_variants.py` | aries基形状の11バリエーション |
| `generate_aquarius_variants.py` | aquarius基形状の11バリエーション |
| `generate_base_variants.py` | 汎用バリエーション生成（leo/pisces/scorpio/virgo）、自動503リトライ付き |
| `generate_4bases_overnight.py` | 4ベース × 11属性 = 44枚を一括生成（約1.5〜2時間） |
| `generate_constellation_art.py` | Galaxy Star Atlas用61点線画 |
| `generate_share_assets.py` | 旧 fal.ai 版（**非推奨・新規使用禁止**） |

### モデル・生成ルール（詳細は `CLAUDE.md` 「🔴 画像生成 必須手順」セクション参照）

- モデル: `gemini-3.1-flash-image-preview` (Nano Banana 2, 2026年2月リリース、Google AI Pro範囲内で動作)
- アスペクト比: `types.ImageConfig(aspect_ratio="9:16")` で縦長指定
- API キー: `E:\AppCreate\.env` の `GEMINI_API_KEY`
- 503エラー時は自動リトライ（30s→60s→90s バックオフ、最大3回）
- 具体物単語（moon / lion / crab 等）は避ける → 抽象語（aquatic / solar corona / water swirl）に置換

### 禁止事項

- ❌ `backgrounds_original/` の画像を削除・上書きしてはならない
- ❌ fal.ai / Imagen API / Chrome MCP 手動操作を新規に使わない
- ❌ 旧モデル `gemini-2.5-flash-image` を新規コードで使わない（アスペクト比指定不可）

---

## 本番移行時の変更点

| モックアップ | 本番（Flutter） |
|-------------|----------------|
| HTML + JS | Flutter CustomPaint + AnimationController |
| localStorage | Cloudflare Worker + ローカルDB |
| ~~モック鑑定文~~ Gemini Flash動的生成済み | **✅ 完了**: CF Worker `/fortune` (Gemini 2.5 Flash) |
| モック名前生成 | Claude API (Sonnet) テンプレートルール制約付き |
| events.js DOM注入 | Flutter Widget overlay |
| CSS glass | Flutter BackdropFilter |
| 日英2段表示（例: 星読み/READING） | AppLocalizations による自動多言語切替（Sanctuary言語設定と連動） |
| api_proxy.py ローカル | **✅ 本番稼働**: `https://solara-api.solodev-lab.com` (Cloudflare Worker) |

---

## CF Worker API 仕様 (本番稼働 2026-04-15〜)

**Base URL**: `https://solara-api.solodev-lab.com` (fallback: `solara-api.kojifo369.workers.dev`)

### `/fortune` POST — Gemini生成の占い文
- **入力**: `{ category, lang, natal, aspects, patterns, date, userName }`
  - `category`: `'overall'|'love'|'money'|'career'|'communication'`
  - `lang`: `'ja'|'en'`
  - `aspects`: `[{p1,p2,type,quality,diff,aspectAngle,orb}, ...]`
  - `patterns`: `{grandtrine:[], tsquare:[], yod:[]}`
- **出力**: `{ category, score, reading, advice, direction, lang }`
  - `score`: 20-95 (関連惑星のアスペクト強度で算出、確定的)
  - `reading`: 120-200字の鑑定文 (Gemini JSON mode)
  - `advice`: 実践的アドバイス1文
  - `direction`: 吉方位 + 理由
- **モデル**: `gemini-2.5-flash` → 503時は `gemini-2.0-flash` fallback、最大2リトライ
- **Secret**: `GEMINI_API_KEY` (wrangler secret put で Cloudflare暗号化ストア保存)

### `/tz` GET — IANA TZ名 lookup (C案)
- **入力**: `?lat=35.68&lng=139.76`
- **出力**: `{ tz: 'Asia/Tokyo', source: 'box'|'offset'|'utc' }`
- **用途**: Sanctuaryで出生地選択時に自動呼出 → `SolaraProfile.birthTzName` に保存
- **実装**: Bounding-box heuristic (主要国) + Etc/GMT±X fallback

### `/astro/chart` POST — natal + transit + aspects + patterns
- **入力追加** (C案): `birthTzName` (optional) — IANA TZ名、DST自動考慮
- 未指定時は従来の `birthTz` 整数オフセットにfallback
- **Worker側処理**: `Intl.DateTimeFormat('en-US', {timeZone: tzName})` で正確なUTC変換

### `/astro/events` GET — 月別天体イベント
- **入力**: `?year=2026&month=4`
- **出力**: `{ events: [{type, planet, date (UTC ISO), descTemplate, descTemplateJP, ...}] }`
- Flutter側でlocal時刻変換して表示 (`CelestialEvent.localDescJP`)

---

## ファイル構成（確定）
```
apps/solara/mockup/
  index.html          ← Map画面（1270行）
  horoscope.html      ← Horo画面（1730行）
  tarot.html          ← Tarot画面（1330行）
  galaxy.html         ← Galaxy画面（810行）
  sanctuary.html      ← Sanctuary画面（190行）
  api_proxy.py        ← Gemini API プロキシサーバー（ポート3915）
  shared/
    styles.css        ← 共通CSS（155行）
    nav.js            ← 5タブナビ（25行）
    vibe.js           ← vibe_score計算（55行）
    stella.js         ← Stellaメッセージ（95行）
    events.js         ← Moonイベント（220行）
```
