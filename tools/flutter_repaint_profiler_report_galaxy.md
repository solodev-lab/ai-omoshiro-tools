# Flutter Repaint Profile Report

- Profile duration: **30 秒**
- Total trace events: **32,669**
  - Begin (B): 15,867
  - Complete (X): 0
  - Instant (i): 0
- Frame events (Frame / Animator::BeginFrame 等): **138**
- Frame interval (median): **16.7 ms** (≈ 59.9 fps)

## 🚨 Idle Repaint 判定

Profile 中の 1/3 (Phase 1 = 最初の 10 秒) はアイドル指示を出しているので、ここで Frame が大量に走っているなら **動かないはずの widget が動いている** 証拠。

- Phase 1 (idle) 中の Frame 数: **46**
  - 🟢 軽微な再描画 (許容範囲)

## Event Category Top

| Category | Count |
|---|---:|
| `Dart` | 14,791 |
| `Embedder` | 735 |
| `API` | 283 |
| `GC` | 58 |

## Event Name Top 30

| Event | Category | Count |
|---|---|---:|
| `RenderConstrainedBox` | `Dart` | 1,932 |
| `Text` | `Dart` | 1,467 |
| `Container` | `Dart` | 872 |
| `RenderPadding` | `Dart` | 690 |
| `RenderDecoratedBox` | `Dart` | 598 |
| `GestureDetector` | `Dart` | 550 |
| `RenderFlex` | `Dart` | 506 |
| `RenderPointerListener` | `Dart` | 506 |
| `Expanded` | `Dart` | 506 |
| `SizedBox` | `Dart` | 505 |
| `CustomPaint` | `Dart` | 505 |
| `Column` | `Dart` | 504 |
| `RenderSemanticsGestureHandler` | `Dart` | 460 |
| `Center` | `Dart` | 413 |
| `ClipRRect` | `Dart` | 413 |
| `Builder` | `Dart` | 413 |
| `RenderCustomPaint` | `Dart` | 368 |
| `RenderParagraph` | `Dart` | 368 |
| `_ConstellationCard` | `Dart` | 368 |
| `RenderLimitedBox` | `Dart` | 230 |
| `RenderStack` | `Dart` | 184 |
| `Row` | `Dart` | 183 |
| `Dart_InvokeClosure` | `API` | 144 |
| `RenderIgnorePointer` | `Dart` | 138 |
| `RenderIndexedStack` | `Dart` | 92 |
| `RenderSemanticsAnnotations` | `Dart` | 92 |
| `_RenderLayoutBuilder` | `Dart` | 92 |
| `RenderTransform` | `Dart` | 92 |
| `Dart_NewInteger` | `API` | 92 |
| `Stack` | `Dart` | 92 |

## PAINT 関連 event 頻度

| Event | Count |
|---|---:|
| `CustomPaint` | 505 |
| `RenderCustomPaint` | 368 |
| `PAINT (root)` | 46 |
| `PAINT` | 46 |
| `RenderRepaintBoundary` | 46 |
| `LayerTree::Paint` | 46 |

## BUILD 関連 event 頻度

| Event | Count |
|---|---:|
| `Builder` | 413 |
| `_RenderLayoutBuilder` | 92 |
| `BUILD` | 46 |
| `AnimatedBuilder` | 45 |

## 解釈ガイド

- **Phase 1 (idle) で Frame が高頻度** → 常時 repaint widget あり → AnimationController.repeat() 等を疑う
- **PAINT 系が突出** → 描画自体が重い (ColorFilter / BoxShadow.blurRadius 動的等)
- **BUILD 系が突出** → setState 多発 / InheritedWidget の必要以上の伝播
- **Widget Build が一部 widget に集中** → その widget の `key` 設定 / `RepaintBoundary` 検討

