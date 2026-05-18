# Flutter Repaint Profile Report

- Profile duration: **30 秒**
- Total trace events: **32,665**
  - Begin (B): 15,907
  - Complete (X): 0
  - Instant (i): 157
- Frame events (Frame / Animator::BeginFrame 等): **81**
- Frame interval (median): **16.7 ms** (≈ 59.9 fps)

## 🚨 Idle Repaint 判定

Profile 中の 1/3 (Phase 1 = 最初の 10 秒) はアイドル指示を出しているので、ここで Frame が大量に走っているなら **動かないはずの widget が動いている** 証拠。

- Phase 1 (idle) 中の Frame 数: **27**
  - ✅ ほぼ静止 (理想的)

## Event Category Top

| Category | Count |
|---|---:|
| `Dart` | 14,964 |
| `Embedder` | 760 |
| `API` | 313 |
| `GC` | 27 |

## Event Name Top 30

| Event | Category | Count |
|---|---|---:|
| `RenderConstrainedBox` | `Dart` | 2,030 |
| `Positioned` | `Dart` | 982 |
| `RenderPadding` | `Dart` | 808 |
| `Container` | `Dart` | 717 |
| `RenderDecoratedBox` | `Dart` | 702 |
| `RenderParagraph` | `Dart` | 572 |
| `Image` | `Dart` | 555 |
| `RenderPositionedBox` | `Dart` | 546 |
| `AnimatedBuilder` | `Dart` | 525 |
| `RenderSemanticsGestureHandler` | `Dart` | 520 |
| `RenderPointerListener` | `Dart` | 520 |
| `IgnorePointer` | `Dart` | 507 |
| `Text` | `Dart` | 405 |
| `RenderFlex` | `Dart` | 365 |
| `RenderSemanticsAnnotations` | `Dart` | 364 |
| `ColorFiltered` | `Dart` | 351 |
| `Transform` | `Dart` | 340 |
| `Stack` | `Dart` | 290 |
| `SizedBox` | `Dart` | 265 |
| `RenderIgnorePointer` | `Dart` | 261 |
| `RenderStack` | `Dart` | 236 |
| `RenderExcludeSemantics` | `Dart` | 234 |
| `Row` | `Dart` | 189 |
| `GestureDetector` | `Dart` | 162 |
| `CustomPaint` | `Dart` | 162 |
| `_RenderVisibility` | `Dart` | 158 |
| `RenderTransform` | `Dart` | 157 |
| `raster cache hit` | `Embedder` | 157 |
| `RasterCacheFlow::DisplayList` | `Embedder` | 156 |
| `RenderCustomPaint` | `Dart` | 156 |

## PAINT 関連 event 頻度

| Event | Count |
|---|---:|
| `CustomPaint` | 162 |
| `RenderCustomPaint` | 156 |
| `LayerTree::Paint` | 26 |
| `PAINT (root)` | 26 |
| `PAINT` | 26 |
| `RenderRepaintBoundary` | 26 |

## BUILD 関連 event 頻度

| Event | Count |
|---|---:|
| `AnimatedBuilder` | 525 |
| `_RenderLayoutBuilder` | 132 |
| `BUILD` | 80 |

## 解釈ガイド

- **Phase 1 (idle) で Frame が高頻度** → 常時 repaint widget あり → AnimationController.repeat() 等を疑う
- **PAINT 系が突出** → 描画自体が重い (ColorFilter / BoxShadow.blurRadius 動的等)
- **BUILD 系が突出** → setState 多発 / InheritedWidget の必要以上の伝播
- **Widget Build が一部 widget に集中** → その widget の `key` 設定 / `RepaintBoundary` 検討

