# Solara Action画面モックアップ 引き継ぎドキュメント

## 現在のファイル構成

```
apps/solara/mockup/
  index.html          - メインモックアップ（約2000行、単一HTMLファイル）
  effect_impact.mp4   - AI生成（Kling）着弾エフェクト動画
  effect_test.html    - エフェクトテスト用（参考のみ）
```

## 現在のindex.htmlの実装状態

### 動作する機能
- タロットカード裏面表示 → TAP TO REVEAL → 3Dフリップ
- カード縮小 → メテオトレイル降下 → 中心着弾
- AI生成エフェクト動画（mix-blend-mode: screen で加算合成）
- 収束パーティクル（金系4色、全画面→中心、60個）
- Leaflet地図（CartoDB Dark Matter暗色タイル）
- 大圏線ベース扇セクター（turf.js、半径20000km）
  - blessed（金グロウ）/ shadow（紫）/ mid（青灰）の3種
  - マルチカラーグロウ（金→白→シアン）+ スパークル（CSSアニメーション）
  - 扇輪郭（弧+直線）にデュアルグロウ
- 惑星ライン3本（☽♆♇）大圏線で地球規模描画
- 惑星マーカー（金丸+黒シンボル）画面端に追従（map moveイベント）
- コンパスローズ（N/S/E/W/NE/NW/SE/SW + ダッシュ線）Leafletレイヤー
- 地図検索（Nominatim API → セクター判定 → ステラコメント）
- 地図ラップ（1周スクロール対応、ポリゴン±360°複製）
- ステラメッセージ（ガラスモーフィズムカード）
- 下部ナビバー（ACTION/RHYTHM/INTENTIONS/PROFILE）
- REPLAYボタン（演出リプレイ）

### 技術スタック
- Leaflet 1.9.4（CDN）
- turf.js 7（CDN）
- 純粋HTML/CSS/JS（フレームワークなし）
- CartoDB Dark Matter タイル（無料）
- Nominatim API（無料、地図検索）

### カラーパレット
```
背景:       #0A0A14（深い宇宙黒）
金（メイン）: #C9A84C
金（明るい）: #F5D76E
紫:         #6B5CE7
シアン:     #00D4FF
吉方位:     金→白→シアンのマルチカラーグラデーション
凶方位:     #2D1B4E（暗い紫）
中間:       #3A4A6B（青灰）
テキスト:   #E8E0D0（暖かいオフホワイト）
```

### 現在のテストデータ
- 中心位置: 名古屋市東区（35.1815, 136.9066）
- テスト用セクター8方位: N=blessed, NE=blessed, E=mid, SE=shadow, S=mid, SW=shadow, W=blessed, NW=mid
- テスト用惑星: ☽=月(30°), ♆=海王星(160°), ♇=冥王星(245°)
- テスト用タロット: カップの3「再会の喜び」

---

## 次のセッションでやるべきこと

### タスク1: 3重円の全惑星を地図上にプロット

**方式B（確定済み）**: ホロスコープの各惑星位置を、実際の地図上の方角にマッピングする。

#### データ構造
```javascript
const tripleChart = {
  natal: {      // 内円（出生図）- 固定値
    sun:     { symbol: '☉', angle: 150, color: '#FFD700' },
    moon:    { symbol: '☽', angle: 30,  color: '#C0C0C0' },
    mercury: { symbol: '☿', angle: 165, color: '#87CEEB' },
    venus:   { symbol: '♀', angle: 120, color: '#FF69B4' },
    mars:    { symbol: '♂', angle: 210, color: '#FF4500' },
    jupiter: { symbol: '♃', angle: 45,  color: '#FFA500' },
    saturn:  { symbol: '♄', angle: 280, color: '#808080' },
    uranus:  { symbol: '♅', angle: 310, color: '#00CED1' },
    neptune: { symbol: '♆', angle: 160, color: '#4169E1' },
    pluto:   { symbol: '♇', angle: 245, color: '#8B0000' }
  },
  progress: {   // 中円（進行図）- ゆっくり変化
    // 同じ構造、角度が少しずつ異なる
  },
  transit: {    // 外円（経過図）- 日々変化
    // 同じ構造、その日の実際の天体位置
  }
};
```

#### 表示方法
- 各惑星を**大圏線**として地図上に描画（現在の☽♆♇と同じ方式）
- 3層を色で区別:
  - ネイタル（内円）: 白系の実線
  - プログレス（中円）: 金系の破線
  - トランジット（外円）: シアン系のドット線
- 惑星マーカーは画面端に追従（現在の方式を拡張）
- マーカーのデザイン: 円内にシンボル、層ごとに枠色を変える

#### アライメント検出
- 3層の惑星が同一方角（±5°以内）に重なった場合 = アライメント
- 例: ネイタル金星(120°) + トランジット木星(118°) → アライメント発火
- セクターのSeed Boost的な演出を追加

### タスク2: レイヤーON/OFFコントロールパネル

```
┌─ レイヤー ──────────┐
│ ☑ 扇セクター        │
│ ☑ 惑星ライン        │
│ ☐ ネイタル（内円）   │
│ ☐ プログレス（中円） │
│ ☐ トランジット（外円）│
│ ☑ コンパス          │
└────────────────────┘
```

- 画面右上にトグルアイコン → タップでパネル展開
- Leafletの`L.control.layers`は使わず、カスタムUIで作る（デザイン統一のため）
- 各レイヤーはLeafletのLayerGroupにまとめておき、addTo/removeFromで切替

### タスク3: ステラ統合メッセージ生成

入力3要素:
- A. 今日のSeed Card（カード名、元素、対応惑星群）
- B. Seed Boostで最も強化された方位セクター
- C. ユーザーの称号（132種）とトーン

テンプレート:
```
[称号に合わせた呼びかけ]、
[カードの核心メッセージ 1文]。
[方位への具体的アクション提案 1文]。
```

### タスク4: Stellar Sync（3重共鳴）特別演出

条件: ネイタル+プログレス+トランジットの惑星が同一セクターに重なる（稀、月1-2回）
演出:
1. 画面フラッシュ（0.1秒）
2. 3重同心円波紋（Canvas）
3. 光の柱（パーティクルストリーム）
4. Haptic振動 + ステラ特別メッセージ

---

### タスク5: 78枚全カードの惑星マッピング表を作成

**コンセプト名: Seed Alignment（シード・アライメント）**

タロットを引くことで地図が「目覚める」。カードが引かれるまでAction画面のレイヤー2はグレーアウト（未活性）状態。引いた瞬間に色が灯り、カードが地図に刺さる。

#### 連携方式（確定: 案1+案4ハイブリッド）

1. **案1**: 朝タロットを引く → カードの元素/惑星対応でレイヤー2の方位重みを再計算
2. **案4**: 地図にカードのエネルギーが着弾する演出
3. ステラが方位+カードを統合したメッセージを生成

#### レイヤー2 再計算ロジック（Seed Boost）

```
■ タロット引く前のレイヤー2（通常計算）:
  各方位セクター = トランジット惑星の方位角 × 惑星固有の強度係数

■ タロット引いた後のレイヤー2（Seed Boost適用）:
  各方位セクター = (トランジット計算値) × (1 + SeedBoost率)

  SeedBoost率 = カード対応惑星がそのセクターにあれば加算

  例: 「カップの3」を引いた場合
    → 水元素 → 月・海王星・冥王星ラインに+15%
    → 数字3（芽吹き）→ そのまま+15%
    → 北東に月ラインがある場合: 北東セクターが 0.65 → 0.75 に上昇
    → 色が中間から吉に変化する可能性
```

**重要な設計判断**: Seed Boostはセクターの色を変えうるが、凶を吉にひっくり返すほどではない。あくまで「押し上げ」であり、元のトランジット計算が主。占星術の整合性を保つ。

#### 大アルカナ: 各カードに固有の惑星/星座対応（Golden Dawn体系準拠）

以下の表を78枚分完成させる作業が必要。

```javascript
// 大アルカナ（22枚）: 各カードに1つの天体/星座が対応
const majorArcana = {
  0:  { name: '愚者',   planet: 'uranus',  boost: 0.05, boostType: 'all' },      // 全方位+5%
  1:  { name: '魔術師', planet: 'mercury', boost: 0.30, boostType: 'single' },   // 水星ライン+30%
  2:  { name: '女教皇', planet: 'moon',    boost: 0.30, boostType: 'single' },
  3:  { name: '女帝',   planet: 'venus',   boost: 0.30, boostType: 'single' },
  4:  { name: '皇帝',   planet: 'mars',    boost: 0.30, boostType: 'single' },   // 牡羊座→火星
  5:  { name: '法王',   planet: 'venus',   boost: 0.30, boostType: 'single' },   // 牡牛座→金星
  6:  { name: '恋人',   planet: 'mercury', boost: 0.30, boostType: 'single' },   // 双子座→水星
  7:  { name: '戦車',   planet: 'moon',    boost: 0.30, boostType: 'single' },   // 蟹座→月
  8:  { name: '力',     planet: 'sun',     boost: 0.30, boostType: 'single' },   // 獅子座→太陽
  9:  { name: '隠者',   planet: 'mercury', boost: 0.30, boostType: 'single' },   // 乙女座→水星
  10: { name: '運命の輪', planet: 'jupiter', boost: 0.30, boostType: 'single' },
  11: { name: '正義',   planet: 'venus',   boost: 0.30, boostType: 'single' },   // 天秤座→金星
  12: { name: '吊るされた男', planet: 'neptune', boost: 0.30, boostType: 'single' },
  13: { name: '死神',   planet: 'pluto',   boost: 0.30, boostType: 'single' },   // 蠍座→冥王星
  14: { name: '節制',   planet: 'jupiter', boost: 0.30, boostType: 'single' },   // 射手座→木星
  15: { name: '悪魔',   planet: 'saturn',  boost: 0.30, boostType: 'single' },   // 山羊座→土星
  16: { name: '塔',     planet: 'mars',    boost: 0.30, boostType: 'single' },
  17: { name: '星',     planet: 'uranus',  boost: 0.30, boostType: 'single' },   // 水瓶座→天王星
  18: { name: '月',     planet: 'neptune', boost: 0.30, boostType: 'single' },   // 魚座→海王星
  19: { name: '太陽',   planet: 'sun',     boost: 0.30, boostType: 'single' },
  20: { name: '審判',   planet: 'pluto',   boost: 0.30, boostType: 'single' },
  21: { name: '世界',   planet: 'saturn',  boost: 0.25, boostType: 'all' },      // 全方位+25%（完成）
};
```

#### 小アルカナ: 元素→惑星群のグループマッピング（56枚）

```javascript
// スート別の対応惑星群
const suitMapping = {
  wands:      { element: 'fire',  planets: ['sun', 'mars', 'jupiter'] },
  cups:       { element: 'water', planets: ['moon', 'neptune', 'pluto'] },
  swords:     { element: 'air',   planets: ['mercury', 'uranus', 'saturn'] },
  pentacles:  { element: 'earth', planets: ['venus', 'saturn', 'earth'] },
};

// 数字による強度補正
const numberBoost = {
  1:  0.25,  // Ace: 元素の純粋な力（最大ブースト）
  2:  0.15,  // 芽吹き
  3:  0.15,  // 芽吹き
  4:  0.20,  // 成長期
  5:  0.20,  // 成長期
  6:  0.20,  // 成長期
  7:  0.10,  // 試練/成熟（分散型、広い範囲に薄く）
  8:  0.10,  // 試練/成熟
  9:  0.10,  // 試練/成熟
  10: 0.20,  // 完成/転換（次のサイクルへの橋渡し）
};

// コートカード: 追加ブースト対象
const courtBoost = {
  page:   { extraPlanets: ['mercury'],       boost: 0.15 },  // 学び
  knight: { extraPlanets: ['mars'],          boost: 0.20 },  // 行動
  queen:  { extraPlanets: ['moon', 'venus'], boost: 0.15 },  // 受容
  king:   { extraPlanets: ['sun', 'jupiter'], boost: 0.20 }, // 統治
};

// 小アルカナのブースト計算例:
// 「カップの3」→ cups.planets=['moon','neptune','pluto'] × numberBoost[3]=0.15
// 各惑星ラインが存在するセクターに+15%
//
// 「ワンドのナイト」→ wands.planets=['sun','mars','jupiter'] + knight.extraPlanets=['mars']
// → mars が2重でカウント（+20%×2ではなく、+20%+行動ボーナス+5%的な扱い）
```

#### 78枚マッピング表の作成手順

1. 上記のデータ構造をJSONファイルとして `apps/solara/mockup/tarot_planet_map.json` に保存
2. 大アルカナ22枚: Golden Dawn体系に基づき、惑星/星座対応を確定
3. 小アルカナ56枚: スート×(数字14枚)の組み合わせ、上記ロジックで自動計算可能
4. 各カードの日本語名・英語名・キーワード・ステラメッセージテンプレートも併記
5. モックアップ（index.html）に組み込み、カード選択→Seed Boost→セクター再計算のフルフローを実装

#### Seed Boost の UX フロー

```
[タロット未引き時のAction画面]
  レイヤー1（宿命の3帯）: 常時表示
  レイヤー2（日常の5帯）: グレーアウト
  ステラ: 「おはよう。今日の方位はまだ眠ってるよ。Seedカードで起こして？」
  [🌱 Seedを引く] ボタン → Rhythm画面へ

[タロット引いた後のAction画面]
  レイヤー2が色付きに変化（Seed Boost適用済み）
  対応惑星ラインの方位に「Seedマーカー」出現
  ステラ統合メッセージ表示
```

---

## 重要な技術的決定事項（変更不可）

1. **D3.js正距方位図法は不使用** → Leaflet+turf.js大圏線で統一
2. **大圏線がメルカトル上で曲がるのは正しい動作**（NYC→サンディエゴ=真西271°）
3. **エフェクト素材はAI生成（Kling AI）→ MP4 → mix-blend-mode:screen**
4. **本番の検索はGoogle Places API**（モックアップではNominatim）
5. **扇の半径は20000km**（地球規模、ラップ対応）
6. **信号機カラー禁止**（赤/緑不使用、金/紫/青灰のパレット）

## 全体仕様書の参照先

`apps/solara/全体仕様.docx` - Action画面の元の仕様はこのファイルの「Action astrocartography」セクション参照。
