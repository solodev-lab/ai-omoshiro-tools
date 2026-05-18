# Flutter Widget Cost Audit v2 Report

v1 検出 + saveLayer trigger 系拡張 (Opacity / AnimatedOpacity / FadeTransition / ShaderMask / ClipPath / canvas.saveLayer / 動的 ImageFilter.blur)

- Target: `apps/solara/lib`
- Files scanned: **121**
- 🔴 Critical: **22**
- 🟡 Warning:  **48**
- ⚪ Info:     **25**

リスク基準: HTML→Flutter 移植で出やすい高コスト widget のうち、常時表示領域 / アニメ blur / per-tile/item 適用を **致命**、popup などで使われているものを **警告** とする。

_詳細: `~/.claude/projects/E--AppCreate/memory/feedback_html_costly_widgets.md`_

## 🔴 Critical (22)

### `apps/solara/lib/screens/map/map_daily_transit_screen.dart`  _[always-visible]_

- **L194** `FadeTransition` — FadeTransition は Opacity を Animation で動かす。saveLayer 多発。 必要に応じて自前の AnimatedBuilder + Color alpha で代替を検討。

  ```dart
      193:     final hasFailed = _failed[key] ?? false;
  >>  194:     return FadeTransition(
      195:       opacity: _fadeCtrl,
  ```

### `apps/solara/lib/screens/map/map_styles.dart`  _[unknown]_

- **L115** `ColorFiltered` — 各タイル/アイテム毎に offscreen layer を作り Surface buffer 倍増の可能性 (per-tile / per-item で繰り返し適用される文脈)

  ```dart
      114:     tileBuilder: cfg.dark
  >>  115:         ? (context, tileWidget, tile) => ColorFiltered(
      116:               // 1 段に合成済 (saveLayer x2 → x1、ACG 画面点滅対策)
  ```

### `apps/solara/lib/screens/observe/observe_history.dart`  _[unknown]_

- **L268** `AnimatedOpacity` — AnimatedOpacity は内部で Opacity widget を使い、Animation 中は saveLayer trigger。 半透明 Color の AnimatedContainer / AnimatedDefaultTextStyle 等で代替可。

  ```dart
      267:       ),
  >>  268:       AnimatedOpacity(
      269:         opacity: _showSaved ? 1.0 : 0.0,
  ```

### `apps/solara/lib/screens/observe/tarot_altar_scene.dart`  _[unknown]_

- **L381** `Opacity widget` — Opacity(opacity: ?) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。 (このファイルに `..repeat(` あり)

  ```dart
      380:                 // Mid flame layer (orange)
  >>  381:                 Opacity(
      382:                   opacity: o2,
  ```

- **L453** `Opacity widget` — Opacity(opacity: ?) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。 (このファイルに `..repeat(` あり)

  ```dart
      452:           alignment: Alignment.center,
  >>  453:           child: Opacity(
      454:             opacity: opacity.clamp(0.0, 1.0),
  ```

### `apps/solara/lib/screens/sanctuary/sanctuary_title_diagnosis.dart`  _[popup]_

- **L296** `AnimatedOpacity` — AnimatedOpacity は内部で Opacity widget を使い、Animation 中は saveLayer trigger。 半透明 Color の AnimatedContainer / AnimatedDefaultTextStyle 等で代替可。

  ```dart
      295:                     boxShadow: selected ? [const BoxShadow(color: Color(0x66F9D976), blurRadius: 20)] : null),
  >>  296:                   child: AnimatedOpacity(duration: const Duration(milliseconds: 300), opacity: dimmed ? 0.25 : 1.0,
      297:                     // HTML: <img src="card-images/XX.png"> — show card image
  ```

### `apps/solara/lib/screens/sanctuary_screen.dart`  _[always-visible]_

- **L382** `FadeTransition` — FadeTransition は Opacity を Animation で動かす。saveLayer 多発。 必要に応じて自前の AnimatedBuilder + Color alpha で代替を検討。

  ```dart
      381:       transitionBuilder: (child, animation) {
  >>  382:         return FadeTransition(opacity: animation, child: child);
      383:       },
  ```

- **L494** `ShaderMask` — ShaderMask は saveLayer trigger。常時表示なら致命。 gradient 単色塗り or RenderObject 経由の代替を検討。

  ```dart
      493:             // (Flutter doesn't support background-clip text easily, use ShaderMask)
  >>  494:             ShaderMask(
      495:               shaderCallback: (bounds) => const LinearGradient(
  ```

### `apps/solara/lib/widgets/catasterism_formation_overlay.dart`  _[popup]_

- **L114** `FadeTransition` — FadeTransition は Opacity を Animation で動かす。saveLayer 多発。 必要に応じて自前の AnimatedBuilder + Color alpha で代替を検討。

  ```dart
      113:   Widget build(BuildContext context) {
  >>  114:     return FadeTransition(
      115:       opacity: CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
  ```

- **L214** `AnimatedOpacity` — AnimatedOpacity は内部で Opacity widget を使い、Animation 中は saveLayer trigger。 半透明 Color の AnimatedContainer / AnimatedDefaultTextStyle 等で代替可。

  ```dart
      213:                     right: 0,
  >>  214:                     child: AnimatedOpacity(
      215:                       duration: const Duration(milliseconds: 600),
  ```

- **L258** `AnimatedOpacity` — AnimatedOpacity は内部で Opacity widget を使い、Animation 中は saveLayer trigger。 半透明 Color の AnimatedContainer / AnimatedDefaultTextStyle 等で代替可。

  ```dart
      257:                     right: 32,
  >>  258:                     child: AnimatedOpacity(
      259:                       duration: const Duration(milliseconds: 600),
  ```

### `apps/solara/lib/widgets/catasterism_overlay.dart`  _[popup]_

- **L114** `FadeTransition` — FadeTransition は Opacity を Animation で動かす。saveLayer 多発。 必要に応じて自前の AnimatedBuilder + Color alpha で代替を検討。

  ```dart
      113:     // オーバーレイ全体を初期フェードインで包む (背景含む)
  >>  114:     return FadeTransition(
      115:       opacity: _fadeAnim,
  ```

- **L162** `FadeTransition` — FadeTransition は Opacity を Animation で動かす。saveLayer 多発。 必要に応じて自前の AnimatedBuilder + Color alpha で代替を検討。

  ```dart
      161:             padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
  >>  162:             child: FadeTransition(
      163:               opacity: _fadeAnim,
  ```

### `apps/solara/lib/widgets/full_moon_overlay.dart`  _[popup]_

- **L139** `FadeTransition` — FadeTransition は Opacity を Animation で動かす。saveLayer 多発。 必要に応じて自前の AnimatedBuilder + Color alpha で代替を検討。

  ```dart
      138:     // オーバーレイ全体を初期フェードインで包む (月背景含む)
  >>  139:     return FadeTransition(
      140:       opacity: _fadeAnim,
  ```

- **L187** `FadeTransition` — FadeTransition は Opacity を Animation で動かす。saveLayer 多発。 必要に応じて自前の AnimatedBuilder + Color alpha で代替を検討。

  ```dart
      186:             padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
  >>  187:             child: FadeTransition(
      188:               opacity: _fadeAnim,
  ```

- **L377** `FadeTransition` — FadeTransition は Opacity を Animation で動かす。saveLayer 多発。 必要に応じて自前の AnimatedBuilder + Color alpha で代替を検討。

  ```dart
      376:               top: ratingY + ratingHeight + 26,
  >>  377:               child: FadeTransition(
      378:                 opacity: _messageCtl,
  ```

### `apps/solara/lib/widgets/moon_overlay_shared.dart`  _[unknown]_

- **L109** `FadeTransition` — FadeTransition は Opacity を Animation で動かす。saveLayer 多発。 必要に応じて自前の AnimatedBuilder + Color alpha で代替を検討。

  ```dart
      108:           blendMode: BlendMode.dstIn,
  >>  109:           child: FadeTransition(
      110:             opacity: widget.fadeAnim,
  ```

### `apps/solara/lib/widgets/new_moon_overlay.dart`  _[popup]_

- **L162** `FadeTransition` — FadeTransition は Opacity を Animation で動かす。saveLayer 多発。 必要に応じて自前の AnimatedBuilder + Color alpha で代替を検討。

  ```dart
      161:     // Backdrop はこの下で常時表示し、クロスフェード中にCycle画面が透けるのを防ぐ
  >>  162:     return FadeTransition(
      163:       opacity: _fadeAnim,
  ```

- **L209** `FadeTransition` — FadeTransition は Opacity を Animation で動かす。saveLayer 多発。 必要に応じて自前の AnimatedBuilder + Color alpha で代替を検討。

  ```dart
      208:             padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
  >>  209:             child: FadeTransition(
      210:               opacity: _fadeAnim,
  ```

- **L400** `FadeTransition` — FadeTransition は Opacity を Animation で動かす。saveLayer 多発。 必要に応じて自前の AnimatedBuilder + Color alpha で代替を検討。

  ```dart
      399:                   children: [
  >>  400:                     FadeTransition(
      401:                       opacity: _messageCtl,
  ```

- **L405** `FadeTransition` — FadeTransition は Opacity を Animation で動かす。saveLayer 多発。 必要に応じて自前の AnimatedBuilder + Color alpha で代替を検討。

  ```dart
      404:                     const SizedBox(height: 22),
  >>  405:                     FadeTransition(
      406:                       opacity: _eventsCtl,
  ```

- **L410** `FadeTransition` — FadeTransition は Opacity を Animation で動かす。saveLayer 多発。 必要に応じて自前の AnimatedBuilder + Color alpha で代替を検討。

  ```dart
      409:                     const SizedBox(height: 36),
  >>  410:                     FadeTransition(
      411:                       opacity: _actionCtl,
  ```


## 🟡 Warning (48)

### `apps/solara/lib/screens/forecast_screen.dart`  _[always-visible]_

- **L421** `Opacity widget` — Opacity(opacity: ?) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
      420:               : () => _setHighColor(_highColor == 'green' ? 'red' : 'green'),
  >>  421:           child: Opacity(
      422:             opacity: highToggleDisabled ? 0.35 : 1.0,
  ```

- **L451** `Opacity widget` — Opacity(opacity: ?) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
      450:     final active = !disabled && _categoryRank == rank;
  >>  451:     return Opacity(
      452:       opacity: disabled ? 0.35 : 1.0,
  ```

### `apps/solara/lib/screens/galaxy/galaxy_replay_overlay.dart`  _[popup]_

- **L55** `Opacity widget` — Opacity(opacity: fadeT) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
       54:                   // replay title — 端末言語でEN or JP を1つだけ表示
  >>   55:                   Opacity(opacity: fadeT, child: Builder(builder: (ctx) {
       56:                     final isJP = Localizations.localeOf(ctx).languageCode == 'ja';
  ```

- **L94** `Opacity widget` — Opacity(opacity: fadeT) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
       93:                   // サブ情報 — Cinzelで統一 (大きめサイズ)
  >>   94:                   Opacity(opacity: fadeT, child: Column(children: [
       95:                     Text('${cycle.dots.length} stars · ${cycle.dots.where((d) => d.isMajor).length} anchors',
  ```

### `apps/solara/lib/screens/horoscope/horo_aspect_list.dart`  _[unknown]_

- **L162** `Opacity widget` — Opacity(opacity: ?) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
      161:             //   - Aspect badge から日本語名削除 (symbol + 度数のみ) → 詳細はタップで dialog
  >>  162:             Expanded(child: Opacity(
      163:               opacity: isOff ? 0.25 : 1.0,
  ```

### `apps/solara/lib/screens/horoscope/horo_backdrop.dart`  _[unknown]_

- **L31** `Opacity widget` — Opacity(opacity: ?) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
       30:               valueListenable: _readingParallax,
  >>   31:               builder: (_, dy, _) => Opacity(
       32:                 opacity: 0.35,
  ```

- **L49** `Opacity widget` — Opacity(opacity: ?) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
       48:               animation: _rotCtl,
  >>   49:               builder: (_, _) => Opacity(
       50:                 opacity: 0.35,
  ```

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

- **L70** `Opacity widget` — Opacity(opacity: ?) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
       69:                 Positioned.fill(child: ClipOval(
  >>   70:                   child: Opacity(
       71:                     opacity: 0.75,
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

### `apps/solara/lib/screens/horoscope/horo_prediction_panel.dart`  _[unknown]_

- **L163** `Opacity widget` — Opacity(opacity: ?) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
      162:         // Body (dimmed when off)
  >>  163:         Expanded(child: Opacity(
      164:           opacity: visible ? 1.0 : 0.25,
  ```

- **L227** `Opacity widget` — Opacity(opacity: ?) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
      226:         const SizedBox(width: 4),
  >>  227:         Expanded(child: Opacity(
      228:           opacity: visible ? 1.0 : 0.25,
  ```

### `apps/solara/lib/screens/horoscope/horo_relocation_panel.dart`  _[unknown]_

- **L267** `Opacity widget` — Opacity(opacity: ?) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
      266:         : '変化なし';
  >>  267:     return Opacity(
      268:       opacity: changed ? 1.0 : 0.55,
  ```

- **L331** `Opacity widget` — Opacity(opacity: ?) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
      330: 
  >>  331:     return Opacity(
      332:       opacity: changed ? 1.0 : 0.5,
  ```

### `apps/solara/lib/screens/map/map_location_markers.dart`  _[unknown]_

- **L66** `BoxShadow x3` — BoxShadow が 3 段。各影は別レイヤー化されることがあり、合算コストが大きい。

  ```dart
  >>   66:               boxShadow: [
       67:                 // 外側ソフトグロー (拡散大、暖色)
       68:                 // 2026-05-03: blur/spread を固定化 (Critical fix)。
       69:                 // breathing は alpha のみで表現 = saveLayer 回避。
       70:                 BoxShadow(
  ```

### `apps/solara/lib/screens/map/map_vp_panel.dart`  _[unknown]_

- **L352** `Opacity widget` — Opacity(opacity: ?) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
      351:       onTap: disabled ? null : onTap,
  >>  352:       child: Opacity(
      353:         opacity: disabled ? 0.25 : 1,
  ```

### `apps/solara/lib/screens/observe/observe_card_widgets.dart`  _[unknown]_

- **L82** `Opacity widget` — Opacity(opacity: ?) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
       81:             animation: pulseCtrl,
  >>   82:             builder: (_, child) => Opacity(
       83:               opacity: pulseOpacity.value,
  ```

### `apps/solara/lib/screens/observe/tarot_altar_scene.dart`  _[unknown]_

- **L128** `ShaderMask` — ShaderMask は saveLayer trigger。常時表示なら致命。 gradient 単色塗り or RenderObject 経由の代替を検討。

  ```dart
      127:               height: _altarLayout(w, h).height,
  >>  128:               child: ShaderMask(
      129:                 blendMode: BlendMode.dstIn,
  ```

### `apps/solara/lib/screens/sanctuary/sanctuary_title_diagnosis.dart`  _[popup]_

- **L316** `Opacity widget` — Opacity(opacity: v) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
      315:     tween: Tween(begin: 0.0, end: 1.0), duration: const Duration(seconds: 1),
  >>  316:     builder: (_, v, child) => Opacity(opacity: v, child: Text(_partNames[_lastPart] ?? '',
      317:       style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFFF9D976), letterSpacing: 3)))));
  ```

- **L324** `blurRadius dynamic` — blurRadius = `40 + (v - 0.9` (動的)。Flutter は blurRadius を変動させると 毎フレーム blur 再計算で Surface buffer 大量生成。alpha だけ変動させて blur/spread は固定値にすべき。

  ```dart
      323:           gradient: const RadialGradient(colors: [Color(0x99F9D976), Color(0x1AF9D976), Colors.transparent], stops: [0, 0.6, 0.8]),
  >>  324:           boxShadow: [BoxShadow(color: const Color(0x4DF9D976), blurRadius: 40 + (v - 0.9) * 160)]),
      325:         transform: Matrix4.identity()..scaleByDouble(v, v, v, 1.0))),
  ```

- **L334** `Opacity widget` — Opacity(opacity: (t / 1.5) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
      333:       child: Column(mainAxisSize: MainAxisSize.min, children: [
  >>  334:         Opacity(opacity: (t / 1.5).clamp(0.0, 1.0),
      335:           child: Transform.translate(offset: Offset(0, 20 * (1 - (t / 1.5).clamp(0.0, 1.0))),
  ```

- **L338** `Opacity widget` — Opacity(opacity: ((t - 0.3) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
      337:         const SizedBox(height: 4),
  >>  338:         Opacity(opacity: ((t - 0.3) / 1.2).clamp(0.0, 1.0),
      339:           child: Text(_revealTitleEN, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0x80F9D976)))),
  ```

- **L342** `Opacity widget` — Opacity(opacity: ((t - 2.8) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
      341:           decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Color(0xFFF9D976), Colors.transparent]))),
  >>  342:         Opacity(opacity: ((t - 2.8) / 0.8).clamp(0.0, 1.0),
      343:           child: Transform.scale(scale: 1.0 + 0.5 * (1 - ((t - 2.8) / 0.8).clamp(0.0, 1.0)),
  ```

- **L347** `Opacity widget` — Opacity(opacity: ((t - 3.8) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
      346:         const SizedBox(height: 20),
  >>  347:         Opacity(opacity: ((t - 3.8) / 1.2).clamp(0.0, 1.0),
      348:           child: Text('\u2726 $_revealLightJP', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFFACACAC), height: 1.6))),
  ```

- **L350** `Opacity widget` — Opacity(opacity: ((t - 5.0) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
      349:         const SizedBox(height: 6),
  >>  350:         Opacity(opacity: ((t - 5.0) / 1.2).clamp(0.0, 1.0),
      351:           child: Text('\u2726 $_revealShadowJP', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFFACACAC), height: 1.6, fontStyle: FontStyle.italic))),
  ```

- **L353** `Opacity widget` — Opacity(opacity: ((t - 6.2) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
      352:         const SizedBox(height: 28),
  >>  353:         Opacity(opacity: ((t - 6.2) / 0.8).clamp(0.0, 1.0),
      354:           child: Column(children: [
  ```

### `apps/solara/lib/screens/sanctuary_screen.dart`  _[always-visible]_

- **L696** `Opacity widget` — Opacity(opacity: opacity) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
      695: extension _WidgetOpacity on Widget {
  >>  696:   Widget withOpacity(double opacity) => Opacity(opacity: opacity, child: this);
      697: }
  ```

### `apps/solara/lib/widgets/catasterism_overlay.dart`  _[popup]_

- **L125** `Opacity widget` — Opacity(opacity: ?) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
      124:                 : ((t - 0.5) * 2).clamp(0.0, 1.0);
  >>  125:             return Opacity(
      126:               opacity: opacity,
  ```

- **L214** `Opacity widget` — Opacity(opacity: ?) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
      213:         final exitOpacity = (1 - _exitCtl.value).clamp(0.0, 1.0);
  >>  214:         return Opacity(
      215:           opacity: exitOpacity,
  ```

- **L388** `blurRadius dynamic` — blurRadius = `28 * glow` (動的)。Flutter は blurRadius を変動させると 毎フレーム blur 再計算で Surface buffer 大量生成。alpha だけ変動させて blur/spread は固定値にすべき。

  ```dart
      387:                         color: SolaraColors.solaraGold.withValues(alpha: 0.55 * glow),
  >>  388:                         blurRadius: 28 * glow,
      389:                         spreadRadius: 2 * glow,
  ```

- **L389** `spreadRadius dynamic` — spreadRadius = `2 * glow` (動的)。Flutter は blurRadius を変動させると 毎フレーム blur 再計算で Surface buffer 大量生成。alpha だけ変動させて blur/spread は固定値にすべき。

  ```dart
      388:                         blurRadius: 28 * glow,
  >>  389:                         spreadRadius: 2 * glow,
      390:                       ),
  ```

- **L393** `blurRadius dynamic` — blurRadius = `48 * glow` (動的)。Flutter は blurRadius を変動させると 毎フレーム blur 再計算で Surface buffer 大量生成。alpha だけ変動させて blur/spread は固定値にすべき。

  ```dart
      392:                         color: SolaraColors.solaraGoldLight.withValues(alpha: 0.35 * glow),
  >>  393:                         blurRadius: 48 * glow,
      394:                         spreadRadius: 6 * glow,
  ```

- **L394** `spreadRadius dynamic` — spreadRadius = `6 * glow` (動的)。Flutter は blurRadius を変動させると 毎フレーム blur 再計算で Surface buffer 大量生成。alpha だけ変動させて blur/spread は固定値にすべき。

  ```dart
      393:                         blurRadius: 48 * glow,
  >>  394:                         spreadRadius: 6 * glow,
      395:                       ),
  ```

### `apps/solara/lib/widgets/full_moon_overlay.dart`  _[popup]_

- **L150** `Opacity widget` — Opacity(opacity: ?) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
      149:                 : ((t - 0.5) * 2).clamp(0.0, 1.0);
  >>  150:             return Opacity(
      151:               opacity: opacity,
  ```

### `apps/solara/lib/widgets/moon_overlay_shared.dart`  _[unknown]_

- **L96** `ShaderMask` — ShaderMask は saveLayer trigger。常時表示なら致命。 gradient 単色塗り or RenderObject 経由の代替を検討。

  ```dart
       95:       return ClipRect(
  >>   96:         child: ShaderMask(
       97:           shaderCallback: (rect) => const LinearGradient(
  ```

### `apps/solara/lib/widgets/new_moon_overlay.dart`  _[popup]_

- **L174** `Opacity widget` — Opacity(opacity: ?) — alpha < 1.0 で saveLayer trigger。 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。

  ```dart
      173:                 : ((t - 0.5) * 2).clamp(0.0, 1.0);
  >>  174:             return Opacity(
      175:               opacity: opacity,
  ```


## ⚪ Info (25)

### `apps/solara/lib/screens/galaxy/galaxy_replay_overlay.dart`  _[popup]_

- **L82** `ClipRRect` — ClipRRect default は最適化されるが、巨大領域で常時使うと描画コスト発生。

  ```dart
       81:                     ),
  >>   82:                     child: ClipRRect(
       83:                       borderRadius: BorderRadius.circular(20),
  ```

### `apps/solara/lib/screens/galaxy/galaxy_star_atlas.dart`  _[unknown]_

- **L196** `ClipRRect` — ClipRRect default は最適化されるが、巨大領域で常時使うと描画コスト発生。

  ```dart
      195:               child: Center(
  >>  196:                 child: ClipRRect(
      197:                   borderRadius: BorderRadius.circular(10),
  ```

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

### `apps/solara/lib/screens/horoscope/horo_chart_view.dart`  _[unknown]_

- **L69** `ClipOval` — ClipOval default は最適化されるが、巨大領域で常時使うと描画コスト発生。

  ```dart
       68:                 // ── Parchment base disc (plain, no astrological diagrams) ──
  >>   69:                 Positioned.fill(child: ClipOval(
       70:                   child: Opacity(
  ```

- **L80** `ClipOval` — ClipOval default は最適化されるが、巨大領域で常時使うと描画コスト発生。

  ```dart
       79:                 // Slight golden bloom overlay
  >>   80:                 Positioned.fill(child: ClipOval(child: DecoratedBox(
       81:                   decoration: BoxDecoration(
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

### `apps/solara/lib/screens/map/map_fortune_sheet.dart`  _[popup]_

- **L63** `ClipRRect` — ClipRRect default は最適化されるが、巨大領域で常時使うと描画コスト発生。

  ```dart
       62:       behavior: HitTestBehavior.opaque,
  >>   63:       child: ClipRRect(
       64:       borderRadius: BorderRadius.circular(10),
  ```

- **L352** `ClipRRect` — ClipRRect default は最適化されるが、巨大領域で常時使うと描画コスト発生。

  ```dart
      351:                     widthFactor: pct,
  >>  352:                     child: ClipRRect(
      353:                       borderRadius: BorderRadius.circular(7),
  ```

### `apps/solara/lib/screens/map_screen.dart`  _[always-visible]_

- **L485** `ClipRRect` — ClipRRect default は最適化されるが、巨大領域で常時使うと描画コスト発生。

  ```dart
      484:         height: MediaQuery.of(ctx).size.height * heightFrac,
  >>  485:         child: ClipRRect(
      486:           borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
  ```

### `apps/solara/lib/screens/observe/observe_card_widgets.dart`  _[unknown]_

- **L120** `ClipRRect` — ClipRRect default は最適化されるが、巨大領域で常時使うと描画コスト発生。

  ```dart
      119: 
  >>  120:     final cardImage = ClipRRect(
      121:       borderRadius: BorderRadius.circular(12),
  ```

### `apps/solara/lib/screens/sanctuary/sanctuary_title_diagnosis.dart`  _[popup]_

- **L299** `ClipRRect` — ClipRRect default は最適化されるが、巨大領域で常時使うと描画コスト発生。

  ```dart
      298:                     child: c['img'] != null
  >>  299:                       ? ClipRRect(
      300:                           borderRadius: BorderRadius.circular(8),
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

### `apps/solara/lib/widgets/location_picker_minimap.dart`  _[unknown]_

- **L69** `ClipRRect` — ClipRRect default は最適化されるが、巨大領域で常時使うと描画コスト発生。

  ```dart
       68:       height: widget.height,
  >>   69:       child: ClipRRect(
       70:         borderRadius: BorderRadius.circular(10),
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


