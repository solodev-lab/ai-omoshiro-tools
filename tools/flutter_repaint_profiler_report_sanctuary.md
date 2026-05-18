# Flutter Repaint Profile Report

- Profile duration: **30 秒**
- Total trace events: **32,589**
  - Begin (B): 15,152
  - Complete (X): 0
  - Instant (i): 29
- Frame events (Frame / Animator::BeginFrame 等): **148**
- Frame interval (median): **16.7 ms** (≈ 59.8 fps)

## 🚨 Idle Repaint 判定

Profile 中の 1/3 (Phase 1 = 最初の 10 秒) はアイドル指示を出しているので、ここで Frame が大量に走っているなら **動かないはずの widget が動いている** 証拠。

- Phase 1 (idle) 中の Frame 数: **49**
  - 🟢 軽微な再描画 (許容範囲)

## Event Category Top

| Category | Count |
|---|---:|
| `Dart` | 10,580 |
| `Embedder` | 2,584 |
| `API` | 1,952 |
| `GC` | 65 |

## Event Name Top 30

| Event | Category | Count |
|---|---|---:|
| `RenderSemanticsAnnotations` | `Dart` | 977 |
| `RasterCacheFlow::Layer` | `Embedder` | 961 |
| `RenderPadding` | `Dart` | 845 |
| `_ColorFilterRenderObject` | `Dart` | 672 |
| `RenderImage` | `Dart` | 672 |
| `Dart_InvokeClosure` | `API` | 642 |
| `RenderConstrainedBox` | `Dart` | 599 |
| `RenderParagraph` | `Dart` | 500 |
| `Dart_NewInteger` | `API` | 480 |
| `RenderPointerListener` | `Dart` | 400 |
| `RenderPositionedBox` | `Dart` | 400 |
| `RenderFlex` | `Dart` | 398 |
| `DartIsolate::HandleMessage` | `Embedder` | 397 |
| `Dart_HandleMessage` | `API` | 397 |
| `AnimatedBuilder` | `Dart` | 282 |
| `Positioned` | `Dart` | 277 |
| `RawImage` | `Dart` | 267 |
| `Tile` | `Dart` | 251 |
| `RenderStack` | `Dart` | 249 |
| `ColorFiltered` | `Dart` | 249 |
| `Dart_SendPortGetId` | `API` | 216 |
| `_RenderInkFeatures` | `Dart` | 200 |
| `RenderMouseRegion` | `Dart` | 200 |
| `RenderSemanticsGestureHandler` | `Dart` | 150 |
| `RenderTransform` | `Dart` | 150 |
| `RenderExcludeSemantics` | `Dart` | 150 |
| `RenderCustomPaint` | `Dart` | 150 |
| `RenderDecoratedBox` | `Dart` | 150 |
| `RenderRepaintBoundary` | `Dart` | 148 |
| `Dart_IntegerFitsIntoInt64` | `API` | 136 |

## PAINT 関連 event 頻度

| Event | Count |
|---|---:|
| `RenderCustomPaint` | 150 |
| `RenderRepaintBoundary` | 148 |
| `LayerTree::Paint` | 49 |
| `PAINT (root)` | 49 |
| `PAINT` | 49 |

## BUILD 関連 event 頻度

| Event | Count |
|---|---:|
| `AnimatedBuilder` | 282 |
| `_RenderLayoutBuilder` | 98 |
| `BUILD` | 49 |

## 解釈ガイド

- **Phase 1 (idle) で Frame が高頻度** → 常時 repaint widget あり → AnimationController.repeat() 等を疑う
- **PAINT 系が突出** → 描画自体が重い (ColorFilter / BoxShadow.blurRadius 動的等)
- **BUILD 系が突出** → setState 多発 / InheritedWidget の必要以上の伝播
- **Widget Build が一部 widget に集中** → その widget の `key` 設定 / `RepaintBoundary` 検討

