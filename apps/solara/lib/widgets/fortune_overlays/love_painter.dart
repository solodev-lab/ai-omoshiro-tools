import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '_common.dart';

/// 恋愛: ピンク/赤/金のハートが中心から放射状に広がる。
class LovePainterBuilder extends FortunePainterBuilder {
  final _rng = math.Random();
  late final List<_HeartParticle> _hearts;
  late final List<_Sparkle> _sparkles;
  late final List<_Ray> _rays;

  static const _heartCount = 85;
  static const _sparkleCount = 40;
  static const _rayCount = 8;

  LovePainterBuilder() {
    _hearts = _buildHearts();
    _sparkles = _buildSparkles();
    _rays = _buildRays();
  }

  @override
  CustomPainter buildPainter(double t) => _LovePainter(
    t: t, hearts: _hearts, sparkles: _sparkles, rays: _rays,
  );

  List<_HeartParticle> _buildHearts() {
    const palettes = <_HeartPalette>[
      // Rose pink
      _HeartPalette(highlight: Color(0xFFFFF1F7), main: Color(0xFFFF7FB3), shadow: Color(0xFF8E1A46), rim: Color(0xFFFFD9E8)),
      _HeartPalette(highlight: Color(0xFFFFE5EE), main: Color(0xFFFF9EC5), shadow: Color(0xFF7A1E40), rim: Color(0xFFFFC9DE)),
      _HeartPalette(highlight: Color(0xFFFFF6FA), main: Color(0xFFFFB8D4), shadow: Color(0xFF9B3768), rim: Color(0xFFFFE3EE)),
      // Ruby red
      _HeartPalette(highlight: Color(0xFFFFDCE2), main: Color(0xFFFF3E6C), shadow: Color(0xFF5E0C24), rim: Color(0xFFFF9CB4)),
      _HeartPalette(highlight: Color(0xFFFFCAD3), main: Color(0xFFE63462), shadow: Color(0xFF4A0C1E), rim: Color(0xFFFF8AA6)),
      // Champagne gold
      _HeartPalette(highlight: Color(0xFFFFF8DC), main: Color(0xFFFFD76E), shadow: Color(0xFF8B6914), rim: Color(0xFFFFE8A6)),
      _HeartPalette(highlight: Color(0xFFFFF4C6), main: Color(0xFFFFCB4D), shadow: Color(0xFF7A5A0A), rim: Color(0xFFFFDE87)),
    ];
    const weights = <double>[0.22, 0.20, 0.18, 0.14, 0.11, 0.08, 0.07];
    final hearts = <_HeartParticle>[];
    for (var i = 0; i < _heartCount; i++) {
      final roll = _rng.nextDouble();
      var acc = 0.0;
      var palette = palettes.first;
      for (var k = 0; k < palettes.length; k++) {
        acc += weights[k];
        if (roll <= acc) { palette = palettes[k]; break; }
      }
      final angle = (i / _heartCount) * math.pi * 2 + _rng.nextDouble() * 0.35;
      final speed = 0.55 + _rng.nextDouble() * 0.85;
      final size = 20.0 + math.pow(_rng.nextDouble(), 2.2).toDouble() * 130.0;
      hearts.add(_HeartParticle(
        angle: angle, speed: speed, size: size, palette: palette,
        rotation: (_rng.nextDouble() - 0.5) * 0.5,
        spin: (_rng.nextDouble() - 0.5) * 0.7,
        delay: _rng.nextDouble() * 0.28,
        wobble: _rng.nextDouble() * math.pi * 2,
        depth: _rng.nextDouble(),
      ));
    }
    return hearts;
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
        drift: _rng.nextDouble() * 0.4 + 0.3,
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
        width: 0.05 + _rng.nextDouble() * 0.08,
        intensity: 0.35 + _rng.nextDouble() * 0.4,
      ));
    }
    return list;
  }
}

class _HeartPalette {
  final Color highlight, main, shadow, rim;
  const _HeartPalette({required this.highlight, required this.main, required this.shadow, required this.rim});
}

class _HeartParticle {
  final double angle, speed, size, rotation, spin, delay, wobble, depth;
  final _HeartPalette palette;
  _HeartParticle({
    required this.angle, required this.speed, required this.size, required this.palette,
    required this.rotation, required this.spin, required this.delay, required this.wobble, required this.depth,
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

class _LovePainter extends CustomPainter {
  final double t;
  final List<_HeartParticle> hearts;
  final List<_Sparkle> sparkles;
  final List<_Ray> rays;
  _LovePainter({required this.t, required this.hearts, required this.sparkles, required this.rays});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final diag = math.sqrt(size.width * size.width + size.height * size.height);

    // 背景グロー
    final bgAlpha = stageAlpha(t, fadeIn: 0.12, hold: 0.55, fadeOut: 0.33);
    if (bgAlpha > 0) {
      canvas.drawRect(Offset.zero & size, Paint()
        ..shader = ui.Gradient.radial(center, diag * 0.55, [
          Color.fromRGBO(255, 190, 215, 0.60 * bgAlpha),
          Color.fromRGBO(255, 140, 180, 0.30 * bgAlpha),
          Color.fromRGBO(40, 5, 25, 0.12 * bgAlpha),
          const Color(0x00000000),
        ], [0.0, 0.35, 0.75, 1.0]));
    }

    _drawGodRays(canvas, center, diag);

    // 中心バースト
    final burstT = (t / 0.24).clamp(0.0, 1.0);
    if (burstT < 1.0) {
      final ease = 1 - math.pow(1 - burstT, 3).toDouble();
      final alpha = (1.0 - burstT) * 0.95;
      final radius = diag * 0.10 * (0.15 + ease * 1.8);
      canvas.drawCircle(center, radius, Paint()
        ..shader = ui.Gradient.radial(center, radius, [
          Color.fromRGBO(255, 250, 230, alpha),
          Color.fromRGBO(255, 180, 210, alpha * 0.75),
          Color.fromRGBO(255, 120, 170, alpha * 0.35),
          const Color(0x00000000),
        ], [0.0, 0.35, 0.7, 1.0]));
    }

    // ハート粒子（奥→手前）
    final sorted = List<_HeartParticle>.from(hearts)..sort((a, b) => b.depth.compareTo(a.depth));
    for (final h in sorted) { _drawHeart(canvas, h, center, diag); }

    for (final s in sparkles) { _drawSparkle(canvas, s, center, diag); }
  }

  void _drawGodRays(Canvas canvas, Offset center, double diag) {
    final alpha = stageAlpha(t, fadeIn: 0.10, hold: 0.40, fadeOut: 0.50);
    if (alpha <= 0) return;
    final rotation = t * 0.35;
    final length = diag * 0.62;
    for (final ray in rays) {
      final angle = ray.baseAngle + rotation;
      final w = ray.width;
      final p2 = center + Offset(math.cos(angle - w) * length, math.sin(angle - w) * length);
      final p3 = center + Offset(math.cos(angle + w) * length, math.sin(angle + w) * length);
      final path = Path()..moveTo(center.dx, center.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..close();
      canvas.drawPath(path, Paint()
        ..shader = ui.Gradient.radial(center, length, [
          Color.fromRGBO(255, 230, 240, ray.intensity * alpha * 0.7),
          Color.fromRGBO(255, 180, 210, ray.intensity * alpha * 0.3),
          const Color(0x00000000),
        ], [0.0, 0.5, 1.0])
        ..blendMode = BlendMode.plus);
    }
  }

  void _drawHeart(Canvas canvas, _HeartParticle h, Offset center, double diag) {
    final lt = ((t - h.delay) / (1.0 - h.delay)).clamp(0.0, 1.0);
    if (lt <= 0) return;
    final depthFactor = 1.0 - h.depth * 0.25;
    final radial = easeOutCubic(lt) * diag * 0.58 * h.speed * depthFactor;
    final wobbleY = math.sin(h.wobble + lt * math.pi * 1.6) * h.size * 0.12 * lt;
    final pos = center + Offset(
      math.cos(h.angle) * radial,
      math.sin(h.angle) * radial - lt * diag * 0.03 + wobbleY,
    );
    final alpha = stageAlpha(lt, fadeIn: 0.20, hold: 0.52, fadeOut: 0.28);
    if (alpha <= 0) return;
    final scale = easeOutBack((lt / 0.30).clamp(0.0, 1.0)) * (0.88 + lt * 0.24);
    final rot = h.rotation + h.spin * lt;

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rot);
    canvas.scale(scale);
    final s = h.size;
    final pal = h.palette;

    // 後光
    _drawHeartPath(canvas, Paint()
      ..shader = ui.Gradient.radial(Offset.zero, s * 0.85, [
        pal.main.withValues(alpha: 0.55 * alpha),
        pal.main.withValues(alpha: 0.22 * alpha),
        const Color(0x00000000),
      ], [0.0, 0.55, 1.0])
      ..blendMode = BlendMode.plus, s * 1.35);

    // 本体
    _drawHeartPath(canvas, Paint()
      ..shader = ui.Gradient.radial(Offset(-s * 0.18, -s * 0.06), s * 0.85, [
        pal.highlight.withValues(alpha: alpha),
        pal.main.withValues(alpha: alpha),
        pal.shadow.withValues(alpha: 0.9 * alpha),
      ], [0.0, 0.45, 1.0]), s);

    // リムライト
    canvas.save();
    canvas.translate(s * 0.02, s * 0.07);
    _drawHeartPath(canvas, Paint()
      ..shader = ui.Gradient.radial(Offset(s * 0.18, s * 0.32), s * 0.55, [
        pal.rim.withValues(alpha: 0.60 * alpha),
        pal.rim.withValues(alpha: 0.15 * alpha),
        const Color(0x00000000),
      ], [0.0, 0.5, 1.0])
      ..blendMode = BlendMode.plus, s * 0.95);
    canvas.restore();

    // 大ハイライト
    canvas.save();
    canvas.translate(-s * 0.14, -s * 0.08);
    canvas.rotate(-0.45);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: s * 0.42, height: s * 0.18),
      Paint()..shader = ui.Gradient.radial(Offset.zero, s * 0.21, [
        Color.fromRGBO(255, 255, 255, 0.70 * alpha),
        const Color(0x00FFFFFF),
      ], [0.0, 1.0]),
    );
    canvas.restore();

    // 小スペキュラ
    canvas.drawCircle(
      Offset(-s * 0.22, -s * 0.16), s * 0.055,
      Paint()..color = Color.fromRGBO(255, 255, 255, 0.95 * alpha),
    );

    canvas.restore();
  }

  void _drawHeartPath(Canvas canvas, Paint paint, double s) {
    final path = Path();
    final w = s, h = s;
    path.moveTo(0, h * 0.28);
    path.cubicTo(w * 0.05, h * 0.02, w * 0.50, -h * 0.05, w * 0.50, h * 0.18);
    path.cubicTo(w * 0.50, h * 0.38, w * 0.25, h * 0.48, 0, h * 0.55);
    path.cubicTo(-w * 0.25, h * 0.48, -w * 0.50, h * 0.38, -w * 0.50, h * 0.18);
    path.cubicTo(-w * 0.50, -h * 0.05, -w * 0.05, h * 0.02, 0, h * 0.28);
    path.close();
    canvas.drawPath(path, paint);
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
    final color = Color.lerp(
      const Color(0xFFFFFFFF),
      sp.hue < 0.5 ? const Color(0xFFFFD9E8) : const Color(0xFFFFE8A6),
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
