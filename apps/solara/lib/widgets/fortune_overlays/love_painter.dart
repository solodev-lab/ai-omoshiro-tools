import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '_common.dart';

/// 恋愛（Solara風）: 中心に金の魔法陣が開き、そこから薔薇の花弁が放射状に舞い散る。
/// 金の蔦が四方へ伸び、深紫藍の夜気にローズゴールドの光が漂う。
class LovePainterBuilder extends FortunePainterBuilder {
  final _rng = math.Random();
  late final List<_RosePetal> _petals;
  late final List<_Sparkle> _sparkles;
  late final List<_Ray> _rays;
  late final List<_Vine> _vines;

  static const _petalCount = 85;
  static const _sparkleCount = 40;
  static const _rayCount = 8;
  static const _vineCount = 7;

  LovePainterBuilder() {
    _petals = _buildPetals();
    _sparkles = _buildSparkles();
    _rays = _buildRays();
    _vines = _buildVines();
  }

  @override
  CustomPainter buildPainter(double t) => _LovePainter(
    t: t, petals: _petals, sparkles: _sparkles, rays: _rays, vines: _vines,
  );

  List<_RosePetal> _buildPetals() {
    const palettes = <_PetalPalette>[
      // Burgundy（深紅ベルベット）
      _PetalPalette(
        highlight: Color(0xFFE8A6B0), main: Color(0xFF8C1F38),
        shadow: Color(0xFF2A0510), rim: Color(0xFFBC4A68), vein: Color(0xFF4A0A1A),
      ),
      // Wine（ワインレッド）
      _PetalPalette(
        highlight: Color(0xFFE6B0BB), main: Color(0xFFA32C47),
        shadow: Color(0xFF380614), rim: Color(0xFFD06E84), vein: Color(0xFF58101E),
      ),
      // Rose（くすんだローズ）
      _PetalPalette(
        highlight: Color(0xFFFAD5DE), main: Color(0xFFCE6B86),
        shadow: Color(0xFF4E1A2A), rim: Color(0xFFE8A8B8), vein: Color(0xFF782A40),
      ),
      // Rose Gold
      _PetalPalette(
        highlight: Color(0xFFFFE4D6), main: Color(0xFFE0A68E),
        shadow: Color(0xFF5A2E20), rim: Color(0xFFF0C8B4), vein: Color(0xFF8A4C36),
      ),
      // Deep purple velvet
      _PetalPalette(
        highlight: Color(0xFFD8BED8), main: Color(0xFF5A2C64),
        shadow: Color(0xFF18051E), rim: Color(0xFF8A5C92), vein: Color(0xFF2A1030),
      ),
      // Antique gold (少数派)
      _PetalPalette(
        highlight: Color(0xFFFFF0C0), main: Color(0xFFC89A3A),
        shadow: Color(0xFF3E2E0A), rim: Color(0xFFE8C67A), vein: Color(0xFF6E5218),
      ),
    ];
    const weights = <double>[0.24, 0.22, 0.18, 0.14, 0.14, 0.08];
    final list = <_RosePetal>[];
    for (var i = 0; i < _petalCount; i++) {
      final roll = _rng.nextDouble();
      var acc = 0.0;
      var palette = palettes.first;
      for (var k = 0; k < palettes.length; k++) {
        acc += weights[k];
        if (roll <= acc) { palette = palettes[k]; break; }
      }
      final angle = (i / _petalCount) * math.pi * 2 + _rng.nextDouble() * 0.35;
      list.add(_RosePetal(
        angle: angle,
        speed: 0.55 + _rng.nextDouble() * 0.85,
        size: 18.0 + math.pow(_rng.nextDouble(), 2.0).toDouble() * 88.0,
        aspect: 0.48 + _rng.nextDouble() * 0.18,
        palette: palette,
        rotation: (_rng.nextDouble() - 0.5) * 0.6,
        spin: (_rng.nextDouble() - 0.5) * 0.9,
        tiltSpeed: 1.4 + _rng.nextDouble() * 1.8,
        tiltPhase: _rng.nextDouble() * math.pi * 2,
        delay: _rng.nextDouble() * 0.30,
        wobble: _rng.nextDouble() * math.pi * 2,
        depth: _rng.nextDouble(),
      ));
    }
    return list;
  }

  List<_Sparkle> _buildSparkles() {
    final list = <_Sparkle>[];
    for (var i = 0; i < _sparkleCount; i++) {
      list.add(_Sparkle(
        angle: _rng.nextDouble() * math.pi * 2,
        distance: 0.1 + _rng.nextDouble() * 0.6,
        size: 8 + _rng.nextDouble() * 22,
        twinklePhase: _rng.nextDouble() * math.pi * 2,
        twinkleSpeed: 2.5 + _rng.nextDouble() * 2.5,
        drift: 0.3 + _rng.nextDouble() * 0.4,
        hue: _rng.nextDouble(),
        delay: _rng.nextDouble() * 0.3,
      ));
    }
    return list;
  }

  List<_Ray> _buildRays() {
    final list = <_Ray>[];
    for (var i = 0; i < _rayCount; i++) {
      list.add(_Ray(
        baseAngle: (i / _rayCount) * math.pi * 2 + _rng.nextDouble() * 0.2,
        width: 0.04 + _rng.nextDouble() * 0.07,
        intensity: 0.30 + _rng.nextDouble() * 0.35,
      ));
    }
    return list;
  }

  List<_Vine> _buildVines() {
    final list = <_Vine>[];
    for (var i = 0; i < _vineCount; i++) {
      list.add(_Vine(
        baseAngle: (i / _vineCount) * math.pi * 2 + _rng.nextDouble() * 0.25,
        curlSign: _rng.nextBool() ? 1 : -1,
        curlAmount: 0.5 + _rng.nextDouble() * 0.6,
        reach: 0.40 + _rng.nextDouble() * 0.22,
        delay: 0.08 + _rng.nextDouble() * 0.20,
        growDuration: 0.55 + _rng.nextDouble() * 0.15,
        thickness: 1.4 + _rng.nextDouble() * 1.2,
      ));
    }
    return list;
  }
}

class _PetalPalette {
  final Color highlight, main, shadow, rim, vein;
  const _PetalPalette({
    required this.highlight, required this.main, required this.shadow,
    required this.rim, required this.vein,
  });
}

class _RosePetal {
  final double angle, speed, size, aspect;
  final _PetalPalette palette;
  final double rotation, spin, tiltSpeed, tiltPhase;
  final double delay, wobble, depth;
  _RosePetal({
    required this.angle, required this.speed, required this.size, required this.aspect,
    required this.palette,
    required this.rotation, required this.spin,
    required this.tiltSpeed, required this.tiltPhase,
    required this.delay, required this.wobble, required this.depth,
  });
}

class _Sparkle {
  final double angle, distance, size, twinklePhase, twinkleSpeed, drift, hue, delay;
  _Sparkle({
    required this.angle, required this.distance, required this.size,
    required this.twinklePhase, required this.twinkleSpeed, required this.drift,
    required this.hue, required this.delay,
  });
}

class _Ray {
  final double baseAngle, width, intensity;
  _Ray({required this.baseAngle, required this.width, required this.intensity});
}

class _Vine {
  final double baseAngle;
  final int curlSign;
  final double curlAmount, reach, delay, growDuration, thickness;
  _Vine({
    required this.baseAngle, required this.curlSign, required this.curlAmount,
    required this.reach, required this.delay, required this.growDuration,
    required this.thickness,
  });
}

class _LovePainter extends CustomPainter {
  final double t;
  final List<_RosePetal> petals;
  final List<_Sparkle> sparkles;
  final List<_Ray> rays;
  final List<_Vine> vines;
  _LovePainter({
    required this.t, required this.petals, required this.sparkles,
    required this.rays, required this.vines,
  });

  static const _nightViolet = Color(0xFF2A1440);
  static const _wine = Color(0xFF5C1030);
  static const _roseGold = Color(0xFFE0A080);
  static const _antiqueGold = Color(0xFFD8B05A);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final diag = math.sqrt(size.width * size.width + size.height * size.height);

    // 背景: 深紫藍→ワイン→ローズゴールドの神秘グラデ
    final bgAlpha = stageAlpha(t, fadeIn: 0.12, hold: 0.55, fadeOut: 0.33);
    if (bgAlpha > 0) {
      canvas.drawRect(Offset.zero & size, Paint()
        ..shader = ui.Gradient.radial(center, diag * 0.60, [
          _roseGold.withValues(alpha: 0.38 * bgAlpha),
          _wine.withValues(alpha: 0.35 * bgAlpha),
          _nightViolet.withValues(alpha: 0.30 * bgAlpha),
          const Color(0x00000000),
        ], [0.0, 0.40, 0.78, 1.0]));
    }

    _drawGodRays(canvas, center, diag);

    // 中心の魔法陣（六芒星＋二重円）
    _drawSigil(canvas, center, diag);

    // 金の蔦（中心から四方へ螺旋）
    for (final v in vines) { _drawVine(canvas, v, center, diag); }

    // 薔薇の花弁（奥→手前）
    final sorted = List<_RosePetal>.from(petals)..sort((a, b) => b.depth.compareTo(a.depth));
    for (final p in sorted) { _drawRosePetal(canvas, p, center, diag); }

    // スパークル
    for (final s in sparkles) { _drawSparkle(canvas, s, center, diag); }
  }

  void _drawGodRays(Canvas canvas, Offset center, double diag) {
    final alpha = stageAlpha(t, fadeIn: 0.10, hold: 0.42, fadeOut: 0.48);
    if (alpha <= 0) return;
    final rotation = t * 0.28;
    final length = diag * 0.62;
    for (final ray in rays) {
      final angle = ray.baseAngle + rotation;
      final w = ray.width;
      final p2 = center + Offset(math.cos(angle - w) * length, math.sin(angle - w) * length);
      final p3 = center + Offset(math.cos(angle + w) * length, math.sin(angle + w) * length);
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();
      canvas.drawPath(path, Paint()
        ..shader = ui.Gradient.radial(center, length, [
          _roseGold.withValues(alpha: ray.intensity * alpha * 0.55),
          _wine.withValues(alpha: ray.intensity * alpha * 0.25),
          const Color(0x00000000),
        ], [0.0, 0.5, 1.0])
        ..blendMode = BlendMode.plus);
    }
  }

  void _drawSigil(Canvas canvas, Offset center, double diag) {
    // 0.0〜0.35で急速に開く、その後ゆっくり回転しながら余韻
    final openT = (t / 0.30).clamp(0.0, 1.0);
    final ease = 1 - math.pow(1 - openT, 3).toDouble();
    final alpha = stageAlpha(t, fadeIn: 0.06, hold: 0.50, fadeOut: 0.44);
    if (alpha <= 0) return;

    final r = diag * 0.075 * (0.18 + ease * 1.6);
    final rot = t * 0.35;

    // 外側グロー
    canvas.drawCircle(center, r * 1.6, Paint()
      ..shader = ui.Gradient.radial(center, r * 1.6, [
        _antiqueGold.withValues(alpha: 0.55 * alpha),
        _roseGold.withValues(alpha: 0.22 * alpha),
        const Color(0x00000000),
      ], [0.0, 0.5, 1.0])
      ..blendMode = BlendMode.plus);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rot);

    final gold = _antiqueGold.withValues(alpha: 0.75 * alpha);
    final goldBright = _antiqueGold.withValues(alpha: 0.95 * alpha);
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, r * 0.035)
      ..color = gold
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round;

    // 二重円
    canvas.drawCircle(Offset.zero, r, strokePaint);
    canvas.drawCircle(Offset.zero, r * 0.82, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, r * 0.020)
      ..color = gold
      ..blendMode = BlendMode.plus);

    // 六芒星（2つの三角形）
    final starR = r * 0.78;
    for (var i = 0; i < 2; i++) {
      final base = i * math.pi / 3;
      final path = Path();
      for (var k = 0; k < 3; k++) {
        final a = base + k * (math.pi * 2 / 3) - math.pi / 2;
        final px = math.cos(a) * starR;
        final py = math.sin(a) * starR;
        if (k == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      path.close();
      canvas.drawPath(path, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, r * 0.028)
        ..color = goldBright
        ..blendMode = BlendMode.plus
        ..strokeJoin = StrokeJoin.round);
    }

    // 中心の小さな円
    canvas.drawCircle(Offset.zero, r * 0.12, Paint()
      ..color = _antiqueGold.withValues(alpha: alpha)
      ..blendMode = BlendMode.plus);

    // 外周のミニ目盛り（12分割 = 星座）
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final p1 = Offset(math.cos(a) * r, math.sin(a) * r);
      final p2 = Offset(math.cos(a) * r * 1.10, math.sin(a) * r * 1.10);
      canvas.drawLine(p1, p2, Paint()
        ..strokeWidth = math.max(0.8, r * 0.020)
        ..color = gold
        ..blendMode = BlendMode.plus
        ..strokeCap = StrokeCap.round);
    }

    canvas.restore();
  }

  void _drawVine(Canvas canvas, _Vine v, Offset center, double diag) {
    final localT = t - v.delay;
    if (localT <= 0) return;
    final growT = (localT / v.growDuration).clamp(0.0, 1.0);
    final alpha = stageAlpha(t, fadeIn: 0.12, hold: 0.58, fadeOut: 0.30);
    if (alpha <= 0) return;

    // 蔦の形状: 中心から外へ螺旋を描く曲線
    final totalLen = diag * v.reach;
    final grown = totalLen * easeOutCubic(growT);

    // サンプリング点数
    const samples = 24;
    final path = Path();
    for (var i = 0; i <= samples; i++) {
      final frac = i / samples;
      final dist = grown * frac;
      // 螺旋: 角度 = baseAngle + curl * (dist / totalLen)
      final spiral = v.baseAngle + v.curlSign * v.curlAmount * (dist / totalLen * math.pi * 0.8);
      final px = center.dx + math.cos(spiral) * dist;
      final py = center.dy + math.sin(spiral) * dist;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }

    // 外グロー
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = v.thickness * 3.5
      ..color = _antiqueGold.withValues(alpha: 0.28 * alpha)
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round);
    // 中間層
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = v.thickness * 1.5
      ..color = _antiqueGold.withValues(alpha: 0.70 * alpha)
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round);
    // 白コア
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = v.thickness * 0.55
      ..color = Color.fromRGBO(255, 240, 210, 0.85 * alpha)
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round);

    // 先端のつぼみ（小さな金の玉）
    if (growT > 0.1) {
      final tipDist = grown;
      final tipSpiral = v.baseAngle + v.curlSign * v.curlAmount * (math.pi * 0.8);
      final tip = Offset(
        center.dx + math.cos(tipSpiral) * tipDist,
        center.dy + math.sin(tipSpiral) * tipDist,
      );
      canvas.drawCircle(tip, v.thickness * 3.5, Paint()
        ..shader = ui.Gradient.radial(tip, v.thickness * 3.5, [
          _antiqueGold.withValues(alpha: 0.85 * alpha),
          _wine.withValues(alpha: 0.35 * alpha),
          const Color(0x00000000),
        ], [0.0, 0.5, 1.0])
        ..blendMode = BlendMode.plus);
      canvas.drawCircle(tip, v.thickness * 1.2, Paint()
        ..color = Color.fromRGBO(255, 240, 210, alpha)
        ..blendMode = BlendMode.plus);
    }
  }

  void _drawRosePetal(Canvas canvas, _RosePetal p, Offset center, double diag) {
    final lt = ((t - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
    if (lt <= 0) return;
    final depthFactor = 1.0 - p.depth * 0.25;
    final radial = easeOutCubic(lt) * diag * 0.58 * p.speed * depthFactor;
    final wobbleY = math.sin(p.wobble + lt * math.pi * 1.6) * p.size * 0.12 * lt;
    final pos = center + Offset(
      math.cos(p.angle) * radial,
      math.sin(p.angle) * radial - lt * diag * 0.03 + wobbleY,
    );
    final alpha = stageAlpha(lt, fadeIn: 0.20, hold: 0.52, fadeOut: 0.28);
    if (alpha <= 0) return;

    final scale = easeOutBack((lt / 0.30).clamp(0.0, 1.0)) * (0.88 + lt * 0.24);
    final rot = p.rotation + p.spin * lt;

    // 3D風の傾き（ベルベット質感）
    final tiltCos = math.cos(p.tiltPhase + lt * p.tiltSpeed * math.pi * 2);
    final faceVis = tiltCos.abs().clamp(0.28, 1.0);
    final isBack = tiltCos < 0;

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rot);
    canvas.scale(scale);

    final s = p.size;
    final w = s * p.aspect;
    final pal = p.palette;

    // 後光（ベルベット淡発光）
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 2.4, height: s * 1.5),
      Paint()
        ..shader = ui.Gradient.radial(Offset.zero, s * 0.8, [
          pal.main.withValues(alpha: 0.40 * alpha),
          pal.main.withValues(alpha: 0.14 * alpha),
          const Color(0x00000000),
        ], [0.0, 0.55, 1.0])
        ..blendMode = BlendMode.plus,
    );

    canvas.save();
    canvas.scale(faceVis, 1.0);

    final path = _buildPetalPath(s, w);

    // 本体（ベルベット風の上→下グラデ）
    canvas.drawPath(path, Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, -s * 0.4), Offset(0, s * 0.4),
        isBack
            ? [
                pal.shadow.withValues(alpha: 0.92 * alpha),
                pal.main.withValues(alpha: 0.72 * alpha),
                pal.shadow.withValues(alpha: 0.82 * alpha),
              ]
            : [
                pal.highlight.withValues(alpha: alpha),
                pal.main.withValues(alpha: alpha),
                pal.shadow.withValues(alpha: 0.90 * alpha),
              ],
        const [0.0, 0.5, 1.0],
      ));

    // 中心の脈（金線）
    if (!isBack && faceVis > 0.45) {
      canvas.drawLine(
        Offset(0, -s * 0.42),
        Offset(0, s * 0.42),
        Paint()
          ..color = pal.vein.withValues(alpha: 0.55 * alpha)
          ..strokeWidth = math.max(0.6, s * 0.012),
      );
      // ほのかな金の線
      canvas.drawLine(
        Offset(0, -s * 0.42),
        Offset(0, s * 0.42),
        Paint()
          ..color = _antiqueGold.withValues(alpha: 0.30 * alpha)
          ..strokeWidth = math.max(0.4, s * 0.006)
          ..blendMode = BlendMode.plus,
      );
    }

    // リムライト
    if (!isBack) {
      canvas.drawPath(path, Paint()
        ..shader = ui.Gradient.radial(
          Offset(-w * 0.2, -s * 0.12), s * 0.55,
          [
            pal.rim.withValues(alpha: 0.55 * alpha),
            const Color(0x00000000),
          ],
          [0.0, 1.0],
        )
        ..blendMode = BlendMode.plus);
    }

    // 縁取り（やや暗め）
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, s * 0.010)
      ..color = (isBack ? pal.shadow : pal.rim).withValues(alpha: 0.55 * alpha));

    canvas.restore();
    canvas.restore();
  }

  Path _buildPetalPath(double length, double width) {
    // 薔薇の花弁: 上がやや尖り、下が広い涙型
    final path = Path();
    final l = length * 0.5;
    final w = width * 0.5;
    path.moveTo(0, -l);
    path.cubicTo(w * 1.4, -l * 0.45, w * 1.15, l * 0.50, w * 0.30, l);
    path.cubicTo(0, l * 0.85, 0, l * 0.85, -w * 0.30, l);
    path.cubicTo(-w * 1.15, l * 0.50, -w * 1.4, -l * 0.45, 0, -l);
    path.close();
    return path;
  }

  void _drawSparkle(Canvas canvas, _Sparkle sp, Offset center, double diag) {
    final lt = ((t - sp.delay) / (1.0 - sp.delay)).clamp(0.0, 1.0);
    if (lt <= 0) return;
    final fadeEnv = stageAlpha(lt, fadeIn: 0.18, hold: 0.55, fadeOut: 0.27);
    if (fadeEnv <= 0) return;
    final dist = diag * sp.distance + diag * 0.15 * lt * sp.drift;
    final pos = center + Offset(math.cos(sp.angle) * dist, math.sin(sp.angle) * dist);
    final tw = (math.sin(sp.twinklePhase + lt * sp.twinkleSpeed * math.pi * 2) + 1) / 2;
    final alpha = fadeEnv * (0.35 + tw * 0.65);
    // 金・象牙・ローズゴールドの配色
    final color = Color.lerp(
      const Color(0xFFFFF0CE),
      sp.hue < 0.5 ? _antiqueGold : _roseGold,
      sp.hue < 0.5 ? sp.hue * 2 : (sp.hue - 0.5) * 2,
    )!;
    final size = sp.size * (0.7 + tw * 0.6);

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.drawCircle(Offset.zero, size * 0.7, Paint()
      ..shader = ui.Gradient.radial(Offset.zero, size * 0.7, [
        color.withValues(alpha: 0.60 * alpha),
        color.withValues(alpha: 0.20 * alpha),
        const Color(0x00000000),
      ], [0.0, 0.5, 1.0])
      ..blendMode = BlendMode.plus);
    final starPaint = Paint()..color = color.withValues(alpha: alpha)..blendMode = BlendMode.plus;
    canvas.drawPath(Path()
      ..moveTo(0, -size * 0.5)
      ..quadraticBezierTo(size * 0.04, 0, 0, size * 0.5)
      ..quadraticBezierTo(-size * 0.04, 0, 0, -size * 0.5)
      ..close(), starPaint);
    canvas.drawPath(Path()
      ..moveTo(-size * 0.5, 0)
      ..quadraticBezierTo(0, size * 0.04, size * 0.5, 0)
      ..quadraticBezierTo(0, -size * 0.04, -size * 0.5, 0)
      ..close(), starPaint);
    canvas.drawCircle(Offset.zero, size * 0.07, Paint()..color = Color.fromRGBO(255, 255, 255, alpha));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LovePainter old) => old.t != t;
}
