# Solara Action画面 モックアップ仕様書

> このドキュメントは `index.html` を1から作り直すための仕様書。
> 現行コードにはデッドコード・冗長処理があるため、クリーンに再構築する。

## 1. 全体構成

### フレーム
- スマホモックアップ（375×812px、角丸40px、ダーク背景）
- ステータスバー「SOLARA」（上部50px）
- 下部ナビゲーション（80px）: Action / Rhythm / Intentions / Profile
- REPLAYボタン（左上）

### 地図
- **Leaflet.js** (v1.9.4) + **turf.js** (v7)
- タイル: CartoDB Dark Matter (`dark_all` + `dark_only_labels` overlay)
- 初期位置: 名古屋市東区役所 [35.1815, 136.9262]
- **初期ズーム: 16**（maxZoom 18 - 2）
- minZoom: 2, maxZoom: 18
- worldCopyJump: false
- maxBounds: 緯度[-85, 85], 経度は中心±252
- ズームコントロール・アトリビューション非表示

### Canvas レイヤー（地図上にオーバーレイ）
- `mapCanvas`: 薄い暗いグラデーションオーバーレイのみ（最小限）
- `particleCanvas`: パーティクル・メテオ・スパークル描画用
- `shockwaveCanvas`: 未使用（削除検討）

## 2. 地図上の静的要素（Leaflet レイヤー）

### 2.1 中心マーカー（ユーザー位置）
- `L.circleMarker` 半径4, 白色 (#E8E0D0), fillOpacity 0.8

### 2.2 8方位線（大圏線 / geodesic）
- `turf.destination` で 0〜20,000km を 1,000km刻み（21ポイント）
- 8方向: 0°, 45°, 90°, 135°, 180°, 225°, 270°, 315°
- スタイル: `color: '#C9A84C', weight: 1, opacity: 0.35, dashArray: '4 8'`
- 経度は `normalizeLng()` で正規化

### 2.3 方角ラベル（固定位置、静的マーカー）
- **3箇所**: 2km, 150km, 1000km
- 8方向: N, NE, E, SE, S, SW, W, NW
- 位置計算: `turf.destination` で geodesic
- 基本方位(N/E/S/W): `opacity: 0.5, fontSize: 11px`
- 斜め方位(NE/SE/SW/NW): `opacity: 0.3, fontSize: 9px`
- `L.divIcon`, `interactive: false`

### 2.4 normalizeLng() ヘルパー
```javascript
function normalizeLng(ptLng, refLng) {
  let diff = ptLng - refLng;
  while (diff > 180) diff -= 360;
  while (diff < -180) diff += 360;
  return refLng + diff;
}
```

## 3. Seed カード → 地図活性化フロー

### 3.1 初期状態 (idle)
- グレーベール表示（半透明オーバーレイ）
- 「🌱 Seedカードで起こして？」プロンプト表示
- 「🌱 DRAW SEED CARD」CTAボタン

### 3.2 カードドロー
- タップで全画面カードオーバーレイ表示
- タップでカード反転（CUP III / 再会の喜び / 🌊）
- 縮小アニメーション → メテオ発射

### 3.3 メテオ → インパクト
- 上部から中心に向かってメテオ落下（加速）
- t=0.6 でエフェクト動画再生開始（`effect_impact.mp4`, mix-blend-mode: screen, 3x速度）
- t=1.0 でインパクト:
  - 画面フラッシュ
  - インパクトリング
  - 収束パーティクル（60個、全方向から中心へ）
  - バイブレーション

### 3.4 インパクト後の活性化
- **グレーベール解除**
- **検索バー表示**
- **レイヤーインジケーター表示**
- **Stellaメッセージ表示**（1.2秒後）
- **Seedバッジ表示**（0.8秒後）
- **Geoセクター作成** (`createGeoSectors`)
- **惑星ライン追加** (`addBoostedPlanetLines`)
- **キラキラアニメーション** 10秒間（`sectorAnimating = true` → 10秒後 false）

## 4. Leaflet Geoセクター（活性化後に表示）

### 4.1 セクター定義
- 真東 (85°〜95°): blessed（金色）
- 真西 (265°〜275°): blessed（金色）
- ※狭い帯で表現

### 4.2 描画方法
- 左辺: `turf.destination` で start bearing 方向に 0〜20,000km（30分割）
- 外弧: `geodesicArc()` で start→end bearing（50ステップ）
- 右辺: 同様に end bearing 方向（逆順）
- `L.polygon` でフェードイン（cascade delay）

### 4.3 スタイル
| type | color | fillOpacity | opacity | weight |
|------|-------|-------------|---------|--------|
| blessed | #C9A84C | 0.12 | 0.5 | 2 |
| shadow | #6B5CE7 | 0.10 | 0.25 | 1 |
| mid | #3A4A6B | 0.06 | 0.2 | 1 |

### 4.4 ワールドラップ
- ±360°経度シフトしたコピーも追加

## 5. 惑星ライン（活性化後に表示）

### 5.1 定義
| 惑星 | 角度 | opacity | シンボル |
|------|------|---------|----------|
| 月 | 35° | 0.7 | ☽ |
| 海王星 | 260° | 0.5 | ♆ |
| 冥王星 | 150° | 0.4 | ♇ |

### 5.2 描画
- `turf.destination` で 0〜20,000km（20分割 = 21ポイント）
- `L.polyline` color: '#C9A84C', weight: 2, dashArray: '4 6'

### 5.3 惑星シンボルマーカー（ビューポート端追従）
- 金色円形バッジ（28×28px）にシンボル表示
- **Liang-Barsky セグメント交差検出**でビューポート端に配置
- ライン全21ポイントの各セグメントをチェック
- ビューポート内にセグメントが交差 → 出口点にマーカー配置
- ライン全体がビューポート外 → マーカー非表示
- イベント: `move moveend zoomend`

### 5.4 Liang-Barsky アルゴリズム概要
```
各セグメント(lastPx → px)について:
- ビューポート矩形(margin=30px)との交差判定
- t0, t1 を計算し、t1 の点が「出口点」
- 最後に見つかった出口点を採用
```

### 5.5 Seedマーカー（活性化後）
- `L.circleMarker` 半径6, gold
- 🌊 絵文字ラベル

## 6. Canvas アニメーション

### 6.1 アニメーションループ（省電力設計）
```javascript
let animLoopRunning = false;

function startAnimLoop() {
  if (animLoopRunning) return;
  animLoopRunning = true;
  animate();
}

function animate() {
  // ... 描画処理 ...

  const hasWork = sectorAnimating || impactRings.length > 0 || meteor || particles.length > 0;
  if (hasWork) {
    setTimeout(animate, 16); // ~60fps
  } else {
    animLoopRunning = false; // CPU 0% when idle
  }
}
```
- **何もアニメーションしていない時はループ停止（電池消費ゼロ）**
- `startAnimLoop()` は各アニメーション開始時に呼ぶ

### 6.2 Geoスパークル（Canvas, 活性化後10秒間）
- 真東(85°-95°)・真西(265°-275°)セクターに5個ずつ
- 色: warm white / gold / teal / cyan / light gold
- ズームレベルに応じた半径自動調整
- 中心グロウパルス
- `turf.destination` で地理座標 → `latLngToContainerPoint` でスクリーン座標

### 6.3 パーティクルシステム
- `Particle` クラス: x, y, vx, vy, color, size, life, decay
- インパクトパーティクル: 爆発的拡散
- 収束パーティクル: 画面端から中心へ集まる（`converge` フラグ）
- グロー + シャドウブラー効果

### 6.4 メテオ
- 左上から中心へ落下（ease-in 加速）
- ヘッドグロー（放射グラデーション）+ 白色コア

### 6.5 インパクトリング
- 中心から広がるリング（alpha フェードアウト）

## 7. 検索機能（活性化後に利用可能）

- Nominatim (OSM) ジオコーディング
- 検索結果の位置に `flyTo` + マーカー配置
- `turf.bearing` + `turf.distance` でセクター判定
- 吉方位(blessed) / 要注意方位(shadow) / 中間方位(mid) のメッセージ表示

### セクター判定定義（検索用）
| 方角 | 角度範囲 | タイプ |
|------|----------|--------|
| N | 337.5-22.5 | mid |
| NE | 22.5-67.5 | blessed |
| E | 67.5-112.5 | shadow |
| SE | 112.5-157.5 | shadow |
| S | 157.5-202.5 | mid |
| SW | 202.5-247.5 | mid |
| W | 247.5-292.5 | blessed |
| NW | 292.5-337.5 | mid |

## 8. エフェクト動画
- `effect_impact.mp4`
- `mix-blend-mode: screen` で加算合成
- 3倍速再生
- CSS: `effectColorShift` キーフレームで色変化

## 9. UI要素

### Stellaメッセージ
- ボトムシートスタイル（glass morphism）
- 「✨ Stella」ラベル + テーマメッセージ

### Seedバッジ
- 右上の丸バッジ（🌊）
- scale(0) → scale(1) アニメーション

### レイヤーインジケーター
- 3つのドット（L1紫、L2金、Seed黄金）

## 10. 削除すべきデッドコード（現行版）
- `compassRadiusKm` 変数
- `geoPoint()` 関数
- `makeGeoCircle()` 関数
- `drawBlob()` 関数
- `drawPlanetLine()` 関数（Canvas版）
- `drawActiveSectors()` 関数（Canvas版セクター描画）
- `drawSector()` 関数（drawActiveSectorsの依存）
- `trailParticles` 配列
- `spawnTrailParticle()` 関数
- turf.js の2重読み込み（1つ削除）
- D3関連の空コメント
- `shockwaveCanvas`（未使用）

## 11. 外部依存
- Leaflet 1.9.4 (CSS + JS)
- turf.js v7 (**1回だけ読み込む**)
- CartoDB Dark Matter タイル
- CartoDB Dark Only Labels タイル
- `effect_impact.mp4`（ローカルファイル）

## 12. パフォーマンス設計方針
- アニメーション無い時 → ループ停止 → CPU/電池ゼロ
- 静的Leafletレイヤー（polyline, marker）は電池消費なし
- 惑星マーカー追従は `move/moveend/zoomend` イベントのみ
- 大圏線ポイントは最小限（方位線21pt、惑星線21pt）
- `setTimeout(animate, 16)` で requestAnimationFrame 相当（タブ非表示時は停止）
