# Flutter Repaint Profile Report

- Profile duration: **30 秒**
- Total trace events: **32,680**
  - Begin (B): 15,729
  - Complete (X): 0
  - Instant (i): 193
- Frame events (Frame / Animator::BeginFrame 等): **132**
- Frame interval (median): **16.7 ms** (≈ 59.8 fps)

## 🚨 Idle Repaint 判定

Profile 中の 1/3 (Phase 1 = 最初の 10 秒) はアイドル指示を出しているので、ここで Frame が大量に走っているなら **動かないはずの widget が動いている** 証拠。

- Phase 1 (idle) 中の Frame 数: **46**
  - 🟢 軽微な再描画 (許容範囲)

## Event Category Top

| Category | Count |
|---|---:|
| `Dart` | 14,619 |
| `Embedder` | 1,053 |
| `API` | 203 |
| `GC` | 47 |

## Event Name Top 30

| Event | Category | Count |
|---|---|---:|
| `RenderConstrainedBox` | `Dart` | 3,119 |
| `RenderPadding` | `Dart` | 1,239 |
| `RenderDecoratedBox` | `Dart` | 1,080 |
| `RenderPointerListener` | `Dart` | 958 |
| `RenderParagraph` | `Dart` | 920 |
| `RenderSemanticsGestureHandler` | `Dart` | 919 |
| `RenderPositionedBox` | `Dart` | 880 |
| `RenderSemanticsAnnotations` | `Dart` | 638 |
| `RenderFlex` | `Dart` | 520 |
| `RenderStack` | `Dart` | 516 |
| `RenderExcludeSemantics` | `Dart` | 360 |
| `RenderCustomPaint` | `Dart` | 357 |
| `RenderTransform` | `Dart` | 356 |
| `RenderConstrainedOverflowBox` | `Dart` | 316 |
| `RenderImage` | `Dart` | 312 |
| `_RenderVisibility` | `Dart` | 235 |
| `_RenderLayoutBuilder` | `Dart` | 197 |
| `raster cache hit` | `Embedder` | 193 |
| `RasterCacheFlow::DisplayList` | `Embedder` | 192 |
| `RenderRepaintBoundary` | `Dart` | 118 |
| `Dart_InvokeClosure` | `API` | 83 |
| `RenderFractionallySizedOverflowBox` | `Dart` | 80 |
| `RenderLimitedBox` | `Dart` | 80 |
| `RenderIndexedStack` | `Dart` | 79 |
| `RenderIgnorePointer` | `Dart` | 79 |
| `Dart_NewInteger` | `API` | 78 |
| `BUILD` | `Dart` | 78 |
| `AnimatedBuilder` | `Dart` | 78 |
| `Container` | `Dart` | 78 |
| `Center` | `Dart` | 78 |

## PAINT 関連 event 頻度

| Event | Count |
|---|---:|
| `RenderCustomPaint` | 357 |
| `RenderRepaintBoundary` | 118 |
| `CustomPaint` | 39 |
| `PAINT (root)` | 39 |
| `PAINT` | 39 |
| `LayerTree::Paint` | 39 |

## BUILD 関連 event 頻度

| Event | Count |
|---|---:|
| `_RenderLayoutBuilder` | 197 |
| `BUILD` | 78 |
| `AnimatedBuilder` | 78 |

## 解釈ガイド

- **Phase 1 (idle) で Frame が高頻度** → 常時 repaint widget あり → AnimationController.repeat() 等を疑う
- **PAINT 系が突出** → 描画自体が重い (ColorFilter / BoxShadow.blurRadius 動的等)
- **BUILD 系が突出** → setState 多発 / InheritedWidget の必要以上の伝播
- **Widget Build が一部 widget に集中** → その widget の `key` 設定 / `RepaintBoundary` 検討

