# Flutter Widget Cost Audit Report

- Target: `apps/solara/lib`
- Files scanned: **120**
- 🔴 Critical: **7**
- 🟡 Warning:  **23**
- ⚪ Info:     **15**

リスク基準: HTML→Flutter 移植で出やすい高コスト widget のうち、常時表示領域 / アニメ blur / per-tile/item 適用を **致命**、popup などで使われているものを **警告** とする。

_詳細: `~/.claude/projects/E--AppCreate/memory/feedback_html_costly_widgets.md`_

## 🔴 Critical (7)

### `apps/solara/lib/screens/map/map_location_markers.dart`  _[unknown]_

- **L71** `blurRadius dynamic` — blurRadius = `14 * intensity` (動的)。Flutter は blurRadius を変動させると 毎フレーム blur 再計算で Surface buffer 大量生成。alpha だけ変動させて blur/spread は固定値にすべき。 (このファイルに `..repeat(` あり 行 [41])

  ```dart
       70:                       .withAlpha((180 * intensity).round()),
  >>   71:                   blurRadius: 14 * intensity,
       72:                   spreadRadius: 1.8 * intensity,
  ```

- **L72** `spreadRadius dynamic` — spreadRadius = `1.8 * intensity` (動的)。Flutter は blurRadius を変動させると 毎フレーム blur 再計算で Surface buffer 大量生成。alpha だけ変動させて blur/spread は固定値にすべき。 (このファイルに `..repeat(` あり 行 [41])

  ```dart
       71:                   blurRadius: 14 * intensity,
  >>   72:                   spreadRadius: 1.8 * intensity,
       73:                 ),
  ```

### `apps/solara/lib/screens/map/map_styles.dart`  _[unknown]_

- **L116** `ColorFiltered` — 各タイル/アイテム毎に offscreen layer を作り Surface buffer 倍増の可能性 (per-tile / per-item で繰り返し適用される文脈)

  ```dart
      115:     tileBuilder: cfg.dark
  >>  116:         ? (context, tileWidget, tile) => ColorFiltered(
      117:               // 外側：色相180°回転（invert後の色を元に戻す）
  ```

- **L119** `ColorFiltered` — 各タイル/アイテム毎に offscreen layer を作り Surface buffer 倍増の可能性 (per-tile / per-item で繰り返し適用される文脈)

  ```dart
      118:               colorFilter: const ColorFilter.matrix(_hueRotate180Matrix),
  >>  119:               child: ColorFiltered(
      120:                 // 内側：色反転（白↔黒）
  ```

### `apps/solara/lib/widgets/daily_transit_badge.dart`  _[unknown]_

- **L151** `blurRadius dynamic` — blurRadius = `14 + 8 * glowOpacity` (動的)。Flutter は blurRadius を変動させると 毎フレーム blur 再計算で Surface buffer 大量生成。alpha だけ変動させて blur/spread は固定値にすべき。 (このファイルに `..repeat(` あり 行 [53])

  ```dart
      150:                   color: glowColor.withValues(alpha: glowOpacity),
  >>  151:                   blurRadius: 14 + 8 * glowOpacity,
      152:                   spreadRadius: 2 * glowOpacity,
  ```

- **L152** `spreadRadius dynamic` — spreadRadius = `2 * glowOpacity` (動的)。Flutter は blurRadius を変動させると 毎フレーム blur 再計算で Surface buffer 大量生成。alpha だけ変動させて blur/spread は固定値にすべき。 (このファイルに `..repeat(` あり 行 [53])

  ```dart
      151:                   blurRadius: 14 + 8 * glowOpacity,
  >>  152:                   spreadRadius: 2 * glowOpacity,
      153:                 ),
  ```

### `apps/solara/lib/widgets/solara_nav_bar.dart`  _[always-visible]_

- **L64** `BackdropFilter` — 毎フレーム背景を別 Surface buffer に描画し blur する。 常時表示で使うと致命、popup でも開いている間は重い。

  ```dart
       63:     return ClipRect(
  >>   64:       child: BackdropFilter(
       65:         filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14), // blur(28px) → sigma ≈ 14
  ```


## 🟡 Warning (23)

### `apps/solara/lib/screens/horoscope/horo_chart_painter.dart`  _[unknown]_

- **L163** `blurRadius dynamic` — blurRadius = `4 * scale` (動的)。Flutter は blurRadius を変動させると 毎フレーム blur 再計算で Surface buffer 大量生成。alpha だけ変動させて blur/spread は固定値にすべき。

  ```dart
      162:               shadows: [
  >>  163:                 Shadow(color: const Color(0xFFC9A84C).withAlpha(100), blurRadius: 4 * scale),
      164:               ],
  ```

- **L193** `MaskFilter.blur` — sigma = `5 * scale` (動的の可能性、毎 paint で再計算)

  ```dart
      192:           ..strokeWidth = 4 * scale
  >>  193:           ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * scale));
      194:         // Sharp line
  ```

- **L207** `blurRadius dynamic` — blurRadius = `8 * scale` (動的)。Flutter は blurRadius を変動させると 毎フレーム blur 再計算で Surface buffer 大量生成。alpha だけ変動させて blur/spread は固定値にすべき。

  ```dart
      206:             shadows: [
  >>  207:               Shadow(color: color.withAlpha(160), blurRadius: 8 * scale),
      208:               Shadow(color: color.withAlpha(90), blurRadius: 14 * scale),
  ```

- **L208** `blurRadius dynamic` — blurRadius = `14 * scale` (動的)。Flutter は blurRadius を変動させると 毎フレーム blur 再計算で Surface buffer 大量生成。alpha だけ変動させて blur/spread は固定値にすべき。

  ```dart
      207:               Shadow(color: color.withAlpha(160), blurRadius: 8 * scale),
  >>  208:               Shadow(color: color.withAlpha(90), blurRadius: 14 * scale),
      209:             ],
  ```

- **L342** `MaskFilter.blur` — sigma = `6 * scale` (動的の可能性、毎 paint で再計算)

  ```dart
      341:         ..color = const Color(0xFFF6BD60).withAlpha(haloAlpha)
  >>  342:         ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * scale));
      343: 
  ```

- **L402** `MaskFilter.blur` — sigma = `6 * scale` (動的の可能性、毎 paint で再計算)

  ```dart
      401:           ..color = secondaryBright.withAlpha(sHaloAlpha)
  >>  402:           ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * scale));
      403: 
  ```

- **L458** `MaskFilter.blur` — sigma = `4 * scale` (動的の可能性、毎 paint で再計算)

  ```dart
      457:           ..strokeWidth = 4 * scale
  >>  458:           ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * scale));
      459:         // Sharp stroke
  ```

- **L473** `blurRadius dynamic` — blurRadius = `6 * scale` (動的)。Flutter は blurRadius を変動させると 毎フレーム blur 再計算で Surface buffer 大量生成。alpha だけ変動させて blur/spread は固定値にすべき。

  ```dart
      472:             shadows: [
  >>  473:               Shadow(color: color.withAlpha(140), blurRadius: 6 * scale),
      474:             ],
  ```

- **L498** `MaskFilter.blur` — sigma = `(4 + 3 * breath` (動的の可能性、毎 paint で再計算)

  ```dart
      497:       ..strokeWidth = (3 + 2 * breath) * scale
  >>  498:       ..maskFilter = MaskFilter.blur(BlurStyle.normal, (4 + 3 * breath) * scale));
      499:     // Inner steady glow (always visible)
  ```

- **L504** `MaskFilter.blur` — sigma = `3 * scale` (動的の可能性、毎 paint で再計算)

  ```dart
      503:       ..strokeWidth = 2 * scale
  >>  504:       ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * scale));
      505:     // Double gold bezel
  ```

### `apps/solara/lib/screens/horoscope/horo_chart_view.dart`  _[unknown]_

- **L25** `ColorFiltered` — 各タイル/アイテム毎に offscreen layer を作り Surface buffer 倍増の可能性

  ```dart
       24:         width: imgSize, height: imgSize,
  >>   25:         child: IgnorePointer(child: ColorFiltered(
       26:           colorFilter: const ColorFilter.matrix(<double>[
  ```

- **L134** `ColorFiltered` — 各タイル/アイテム毎に offscreen layer を作り Surface buffer 倍増の可能性

  ```dart
      133:                     height: chartSize * (_birthTimeUnknown ? 0.14 : 0.09),
  >>  134:                     child: ColorFiltered(
      135:                       colorFilter: const ColorFilter.matrix(<double>[
  ```

### `apps/solara/lib/screens/horoscope/horo_ornament_painter.dart`  _[unknown]_

- **L65** `MaskFilter.blur` — sigma = `8 * scale` (動的の可能性、毎 paint で再計算)

  ```dart
       64:       ..strokeWidth = 6 * scale
  >>   65:       ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * scale));
       66: 
  ```

### `apps/solara/lib/screens/horoscope/horo_panel_shared.dart`  _[unknown]_

- **L82** `ColorFiltered` — 各タイル/アイテム毎に offscreen layer を作り Surface buffer 倍増の可能性

  ```dart
       81:       width: size, height: size,
  >>   82:       child: ColorFiltered(
       83:         colorFilter: const ColorFilter.matrix(<double>[
  ```

### `apps/solara/lib/screens/map/map_astro_lines.dart`  _[unknown]_

- **L270** `blurRadius dynamic` — blurRadius = `isNatal ? 14 : 10` (動的)。Flutter は blurRadius を変動させると 毎フレーム blur 再計算で Surface buffer 大量生成。alpha だけ変動させて blur/spread は固定値にすべき。

  ```dart
      269:                 color: planetColor.withAlpha(isNatal ? 160 : 120),
  >>  270:                 blurRadius: isNatal ? 14 : 10,
      271:                 spreadRadius: isNatal ? 1 : 0,
  ```

- **L271** `spreadRadius dynamic` — spreadRadius = `isNatal ? 1 : 0` (動的)。Flutter は blurRadius を変動させると 毎フレーム blur 再計算で Surface buffer 大量生成。alpha だけ変動させて blur/spread は固定値にすべき。

  ```dart
      270:                 blurRadius: isNatal ? 14 : 10,
  >>  271:                 spreadRadius: isNatal ? 1 : 0,
      272:               ),
  ```

### `apps/solara/lib/screens/map/map_location_markers.dart`  _[unknown]_

- **L66** `BoxShadow x3` — BoxShadow が 3 段。各影は別レイヤー化されることがあり、合算コストが大きい。

  ```dart
  >>   66:               boxShadow: [
       67:                 // 外側ソフトグロー (拡散大、暖色)
       68:                 BoxShadow(
       69:                   color: const Color(0xFFFFD370)
       70:                       .withAlpha((180 * intensity).round()),
  ```

### `apps/solara/lib/screens/sanctuary/sanctuary_title_diagnosis.dart`  _[popup]_

- **L324** `blurRadius dynamic` — blurRadius = `40 + (v - 0.9` (動的)。Flutter は blurRadius を変動させると 毎フレーム blur 再計算で Surface buffer 大量生成。alpha だけ変動させて blur/spread は固定値にすべき。

  ```dart
      323:           gradient: const RadialGradient(colors: [Color(0x99F9D976), Color(0x1AF9D976), Colors.transparent], stops: [0, 0.6, 0.8]),
  >>  324:           boxShadow: [BoxShadow(color: const Color(0x4DF9D976), blurRadius: 40 + (v - 0.9) * 160)]),
      325:         transform: Matrix4.identity()..scaleByDouble(v, v, v, 1.0))),
  ```

### `apps/solara/lib/widgets/catasterism_overlay.dart`  _[popup]_

- **L383** `blurRadius dynamic` — blurRadius = `28 * glow` (動的)。Flutter は blurRadius を変動させると 毎フレーム blur 再計算で Surface buffer 大量生成。alpha だけ変動させて blur/spread は固定値にすべき。

  ```dart
      382:                         color: SolaraColors.solaraGold.withValues(alpha: 0.55 * glow),
  >>  383:                         blurRadius: 28 * glow,
      384:                         spreadRadius: 2 * glow,
  ```

- **L384** `spreadRadius dynamic` — spreadRadius = `2 * glow` (動的)。Flutter は blurRadius を変動させると 毎フレーム blur 再計算で Surface buffer 大量生成。alpha だけ変動させて blur/spread は固定値にすべき。

  ```dart
      383:                         blurRadius: 28 * glow,
  >>  384:                         spreadRadius: 2 * glow,
      385:                       ),
  ```

- **L388** `blurRadius dynamic` — blurRadius = `48 * glow` (動的)。Flutter は blurRadius を変動させると 毎フレーム blur 再計算で Surface buffer 大量生成。alpha だけ変動させて blur/spread は固定値にすべき。

  ```dart
      387:                         color: SolaraColors.solaraGoldLight.withValues(alpha: 0.35 * glow),
  >>  388:                         blurRadius: 48 * glow,
      389:                         spreadRadius: 6 * glow,
  ```

- **L389** `spreadRadius dynamic` — spreadRadius = `6 * glow` (動的)。Flutter は blurRadius を変動させると 毎フレーム blur 再計算で Surface buffer 大量生成。alpha だけ変動させて blur/spread は固定値にすべき。

  ```dart
      388:                         blurRadius: 48 * glow,
  >>  389:                         spreadRadius: 6 * glow,
      390:                       ),
  ```

### `apps/solara/lib/widgets/glass_panel.dart`  _[unknown]_

- **L24** `BackdropFilter` — 毎フレーム背景を別 Surface buffer に描画し blur する。 常時表示で使うと致命、popup でも開いている間は重い。

  ```dart
       23:       borderRadius: radius,
  >>   24:       child: BackdropFilter(
       25:         filter: ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
  ```


## ⚪ Info (15)

### `apps/solara/lib/screens/horoscope/horo_antique_icons.dart`  _[unknown]_

- **L74** `MaskFilter.blur` — sigma = `2.2` (静的、許容)

  ```dart
       73:       ..strokeJoin = StrokeJoin.round
  >>   74:       ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);
       75: 
  ```

### `apps/solara/lib/screens/horoscope/horo_chart_painter.dart`  _[unknown]_

- **L577** `MaskFilter.blur` — sigma = `3` (静的、許容)

  ```dart
      576:         ..strokeJoin = StrokeJoin.round
  >>  577:         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      578:     }
  ```

### `apps/solara/lib/screens/horoscope/horo_ornament_painter.dart`  _[unknown]_

- **L109** `MaskFilter.blur` — sigma = `3` (静的、許容)

  ```dart
      108:       ..strokeWidth = 2.2
  >>  109:       ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      110:     // Stroke
  ```

### `apps/solara/lib/screens/horoscope/horo_panel_shared.dart`  _[unknown]_

- **L170** `MaskFilter.blur` — sigma = `2.5` (静的、許容)

  ```dart
      169:         ..strokeWidth = 2.5
  >>  170:         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5));
      171:     }
  ```

- **L194** `MaskFilter.blur` — sigma = `2.0` (静的、許容)

  ```dart
      193:         ..strokeJoin = StrokeJoin.round
  >>  194:         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0));
      195:       // main stroke
  ```

- **L230** `MaskFilter.blur` — sigma = `2.0` (静的、許容)

  ```dart
      229:       ..strokeCap = StrokeCap.round
  >>  230:       ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      231:     final stroke = Paint()
  ```

### `apps/solara/lib/widgets/catasterism_formation_overlay.dart`  _[popup]_

- **L449** `MaskFilter.blur` — sigma = `6` (静的、許容)

  ```dart
      448:             ..strokeWidth = 1.2
  >>  449:             ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      450:         );
  ```

- **L503** `MaskFilter.blur` — sigma = `10` (静的、許容)

  ```dart
      502:           ..style = PaintingStyle.stroke
  >>  503:           ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      504:         // Main line
  ```

- **L557** `MaskFilter.blur` — sigma = `12` (静的、許容)

  ```dart
      556:             ..color = const Color(0xFFF9D976).withAlpha((zodiacAlpha * 0.18 * 255).round())
  >>  557:             ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      558:         );
  ```

### `apps/solara/lib/widgets/constellation_painter.dart`  _[unknown]_

- **L113** `MaskFilter.blur` — sigma = `8` (静的、許容)

  ```dart
      112:         ..style = PaintingStyle.stroke
  >>  113:         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      114:       // Main line
  ```

- **L225** `MaskFilter.blur` — sigma = `9` (静的、許容)

  ```dart
      224:         ..style = PaintingStyle.stroke
  >>  225:         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
      226:       // Line (核: 属性色、太く)
  ```

### `apps/solara/lib/widgets/cycle_spiral_painter.dart`  _[unknown]_

- **L147** `MaskFilter.blur` — sigma = `1.5` (静的、許容)

  ```dart
      146:         ..color = starColor.withValues(alpha: alpha * 0.25)
  >>  147:         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
      148: 
  ```

### `apps/solara/lib/widgets/spiral_painter.dart`  _[unknown]_

- **L59** `MaskFilter.blur` — sigma = `8.0` (静的、許容)

  ```dart
       58:           ..color = SolaraColors.spiralDotActive.withValues(alpha: 0.3)
  >>   59:           ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
       60:         canvas.drawCircle(Offset(x, y), 12.0, glowPaint);
  ```

- **L78** `MaskFilter.blur` — sigma = `24` (静的、許容)

  ```dart
       77:       ..color = SolaraColors.solaraGold.withValues(alpha: 0.15)
  >>   78:       ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
       79:     canvas.drawCircle(center, 20, stellaGlow);
  ```

- **L83** `MaskFilter.blur` — sigma = `8` (静的、許容)

  ```dart
       82:       ..color = SolaraColors.solaraGold.withValues(alpha: 0.6)
  >>   83:       ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
       84:     canvas.drawCircle(center, 6, stellaCore);
  ```


