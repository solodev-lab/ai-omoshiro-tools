# Flutter Repaint Profile Report

- Profile duration: **30 秒**
- Total trace events: **32,680**
  - Begin (B): 15,951
  - Complete (X): 0
  - Instant (i): 0
- Frame events (Frame / Animator::BeginFrame 等): **124**
- Frame interval (median): **16.7 ms** (≈ 59.8 fps)

## 🚨 Idle Repaint 判定

Profile 中の 1/3 (Phase 1 = 最初の 10 秒) はアイドル指示を出しているので、ここで Frame が大量に走っているなら **動かないはずの widget が動いている** 証拠。

- Phase 1 (idle) 中の Frame 数: **41**
  - 🟢 軽微な再描画 (許容範囲)

## Event Category Top

| Category | Count |
|---|---:|
| `Dart` | 14,707 |
| `Embedder` | 762 |
| `API` | 440 |
| `GC` | 42 |

## Event Name Top 30

| Event | Category | Count |
|---|---|---:|
| `RenderConstrainedBox` | `Dart` | 2,301 |
| `RenderPadding` | `Dart` | 1,125 |
| `RenderDecoratedBox` | `Dart` | 876 |
| `RenderParagraph` | `Dart` | 789 |
| `RenderTransform` | `Dart` | 748 |
| `Positioned` | `Dart` | 657 |
| `AnimatedBuilder` | `Dart` | 587 |
| `RenderFlex` | `Dart` | 586 |
| `RenderIgnorePointer` | `Dart` | 583 |
| `RenderPointerListener` | `Dart` | 462 |
| `Container` | `Dart` | 456 |
| `Transform` | `Dart` | 451 |
| `RenderSemanticsGestureHandler` | `Dart` | 420 |
| `RenderStack` | `Dart` | 418 |
| `RenderSemanticsAnnotations` | `Dart` | 378 |
| `RenderImage` | `Dart` | 293 |
| `Image` | `Dart` | 277 |
| `_RenderVisibility` | `Dart` | 247 |
| `Stack` | `Dart` | 247 |
| `IgnorePointer` | `Dart` | 246 |
| `Text` | `Dart` | 214 |
| `RenderCustomPaint` | `Dart` | 210 |
| `SizedBox` | `Dart` | 205 |
| `Dart_NewInteger` | `API` | 195 |
| `_RenderLayoutBuilder` | `Dart` | 166 |
| `RenderLimitedBox` | `Dart` | 125 |
| `Padding` | `Dart` | 124 |
| `Dart_InvokeClosure` | `API` | 117 |
| `RenderPositionedBox` | `Dart` | 84 |
| `RenderIndexedStack` | `Dart` | 83 |

## PAINT 関連 event 頻度

| Event | Count |
|---|---:|
| `RenderCustomPaint` | 210 |
| `RenderRepaintBoundary` | 42 |
| `PAINT (root)` | 41 |
| `PAINT` | 41 |
| `LayerTree::Paint` | 40 |

## BUILD 関連 event 頻度

| Event | Count |
|---|---:|
| `AnimatedBuilder` | 587 |
| `_RenderLayoutBuilder` | 166 |
| `BUILD` | 42 |
| `LayoutBuilder` | 1 |

## 解釈ガイド

- **Phase 1 (idle) で Frame が高頻度** → 常時 repaint widget あり → AnimationController.repeat() 等を疑う
- **PAINT 系が突出** → 描画自体が重い (ColorFilter / BoxShadow.blurRadius 動的等)
- **BUILD 系が突出** → setState 多発 / InheritedWidget の必要以上の伝播
- **Widget Build が一部 widget に集中** → その widget の `key` 設定 / `RepaintBoundary` 検討

