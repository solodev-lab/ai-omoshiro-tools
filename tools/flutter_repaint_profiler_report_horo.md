# Flutter Repaint Profile Report

- Profile duration: **30 秒**
- Total trace events: **32,680**
  - Begin (B): 14,811
  - Complete (X): 0
  - Instant (i): 0
- Frame events (Frame / Animator::BeginFrame 等): **104**
- Frame interval (median): **16.7 ms** (≈ 60.0 fps)

## 🚨 Idle Repaint 判定

Profile 中の 1/3 (Phase 1 = 最初の 10 秒) はアイドル指示を出しているので、ここで Frame が大量に走っているなら **動かないはずの widget が動いている** 証拠。

- Phase 1 (idle) 中の Frame 数: **35**
  - 🟢 軽微な再描画 (許容範囲)

## Event Category Top

| Category | Count |
|---|---:|
| `Dart` | 11,714 |
| `Embedder` | 2,894 |
| `API` | 170 |
| `GC` | 33 |

## Event Name Top 30

| Event | Category | Count |
|---|---|---:|
| `RasterCacheFlow::Layer` | `Embedder` | 2,346 |
| `RenderConstrainedBox` | `Dart` | 1,903 |
| `RenderPadding` | `Dart` | 1,053 |
| `_ColorFilterRenderObject` | `Dart` | 782 |
| `RenderImage` | `Dart` | 782 |
| `RenderDecoratedBox` | `Dart` | 782 |
| `RenderPointerListener` | `Dart` | 748 |
| `RenderParagraph` | `Dart` | 748 |
| `RenderSemanticsGestureHandler` | `Dart` | 646 |
| `RenderPositionedBox` | `Dart` | 544 |
| `RenderSemanticsAnnotations` | `Dart` | 441 |
| `RenderFlex` | `Dart` | 408 |
| `RenderTransform` | `Dart` | 306 |
| `RenderStack` | `Dart` | 305 |
| `RenderCustomPaint` | `Dart` | 272 |
| `RenderConstrainedOverflowBox` | `Dart` | 204 |
| `_RenderVisibility` | `Dart` | 203 |
| `RenderExcludeSemantics` | `Dart` | 136 |
| `RenderIgnorePointer` | `Dart` | 135 |
| `_RenderLayoutBuilder` | `Dart` | 134 |
| `RenderClipRect` | `Dart` | 102 |
| `RenderFittedBox` | `Dart` | 102 |
| `RenderRepaintBoundary` | `Dart` | 101 |
| `Dart_InvokeClosure` | `API` | 70 |
| `_RenderScrollSemantics` | `Dart` | 68 |
| `RenderIndexedStack` | `Dart` | 67 |
| `Dart_NewInteger` | `API` | 66 |
| `AsyncWaitForVsync` | `Embedder` | 36 |
| `PlatformVsync` | `Embedder` | 35 |
| `VsyncFireCallback` | `Embedder` | 35 |

## PAINT 関連 event 頻度

| Event | Count |
|---|---:|
| `RenderCustomPaint` | 272 |
| `RenderRepaintBoundary` | 101 |
| `LayerTree::Paint` | 34 |
| `PAINT (root)` | 34 |
| `PAINT` | 34 |

## BUILD 関連 event 頻度

| Event | Count |
|---|---:|
| `_RenderLayoutBuilder` | 134 |
| `BUILD` | 33 |
| `AnimatedBuilder` | 33 |

## 解釈ガイド

- **Phase 1 (idle) で Frame が高頻度** → 常時 repaint widget あり → AnimationController.repeat() 等を疑う
- **PAINT 系が突出** → 描画自体が重い (ColorFilter / BoxShadow.blurRadius 動的等)
- **BUILD 系が突出** → setState 多発 / InheritedWidget の必要以上の伝播
- **Widget Build が一部 widget に集中** → その widget の `key` 設定 / `RepaintBoundary` 検討

