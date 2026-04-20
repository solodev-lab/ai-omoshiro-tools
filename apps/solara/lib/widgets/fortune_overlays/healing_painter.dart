import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '_common.dart';

/// 癒し: 上から花びらが舞い降り、空気中に淡い光が漂う穏やかな演出。
/// 中心バーストなし。画面上部〜全体に向けた静かな降り注ぎ。
class HealingPainterBuilder extends FortunePainterBuilder {
  final _rng = math.Random();
  late final List<_Petal> _petals;
  late final List<_LightMote> _motes;
  late final List<_Sparkle> _sparkles;

  static const _petalCount = 70;
  static const _moteCount = 110;
  static const _sparkleCount = 25;

  HealingPainterBuilder() {
    _petals = _buildPetals();
    _motes = _buildMotes();
    _sparkles = _buildSparkles();
  }

  @override
  CustomPainter buildPainter(double t) => _HealingPainter(
    t: t, petals: _petals, motes: _motes, sparkles: _sparkles,
  );

  List<_Petal> _buildPetals() {
    const palettes = <_PetalPalette>[
      // Pale mint
      _PetalPalette(
        highlight: Color(0xFFF8FFFC), main: Color(0xFFC4EFE0),
        shadow: Color(0xFF4A8578), rim: Color(0xFFE0FFF4), vein: Color(0xFF7AB5A3),
      ),
      // Soft teal
      _PetalPalette(
        highlight: Color(0xFFEFFFFC), main: Color(0xFFA8E0D4),
        shadow: Color(0xFF2F6A5E), rim: Color(0xFFD0F5EB), vein: Color(0xFF60A092),
      ),
      // Cream white
      _PetalPalette(
        highlight: Color(0xFFFFFFFF), main: Color(0xFFF0FAF6),
        shadow: Color(0xFF6A8A82), rim: Color(0xFFF8FFFC), vein: Color(0xFFA0BBB0),
      ),
      // Pale aqua
      _PetalPalette(
        highlight: Color(0xFFF5FFFF), main: Color(0xFFB0E8E0),
        shadow: Color(0xFF3A7070), rim: Color(0xFFD5F2EE), vein: Color(0xFF6FA5A0),
      ),
      // Sage green
      _PetalPalette(
        highlight: Color(0xFFF5FFEF), main: Color(0xFFC8E5B8),
        shadow: Color(0xFF4A7538), rim: Color(0xFFE0F2D2), vein: Color(0xFF88B070),
      ),
    ];

    final list = <_Petal>[];
    for (var i = 0; i < _petalCount; i++) {
      list.add(_Petal(
        spawnX: _rng.nextDouble(),
        startYOffset: -0.02 - _rng.nextDouble() * 0.25, // 上部から順に降りる
        fallSpeed: 0.6 + _rng.nextDouble() * 0.6,
        size: 14.0 + math.pow(_rng.nextDouble(), 1.8).toDouble() * 38.0,
        aspect: 0.32 + _rng.nextDouble() * 0.22,
        palette: palettes[_rng.nextInt(palettes.length)],
        swayAmp: 0.025 + _rng.nextDouble() * 0.05,
        swaySpeed: 1.2 + _rng.nextDouble() * 1.8,
        swayPhase: _rng.nextDouble() * math.pi * 2,
        rotation: _rng.nextDouble() * math.pi * 2,
        rotSpeed: (_rng.nextDouble() - 0.5) * 1.6,
        tiltSpeed: 1.5 + _rng.nextDouble() * 2.0, // Y軸回転（3D揺らぎ）
        tiltPhase: _rng.nextDouble() * math.pi * 2,
        delay: _rng.nextDouble() * 0.5,
      ));
    }
    return list;
  }

  List<_LightMote> _buildMotes() {
    final list = <_LightMote>[];
    for (var i = 0; i < _moteCount; i++) {
      list.add(_LightMote(
        xRatio: _rng.nextDouble(),
        yRatio: _rng.nextDouble(),
        size: 1.6 + _rng.nextDouble() * 3.8,
        drift: 0.08 + _rng.nextDouble() * 0.15,
        driftAngle: _rng.nextDouble() * math.pi * 2 * 0.3 + math.pi / 2, // ゆるやかに下
        twinklePhase: _rng.nextDouble() * math.pi * 2,
        twinkleSpeed: 2.0 + _rng.nextDouble() * 2.5,
        hue: _rng.nextDouble(),
        delay: _rng.nextDouble() * 0.55,
      ));
    }
    return list;
  }

  List<_Sparkle> _buildSparkles() {
    final list = <_Sparkle>[];
    for (var i = 0; i < _sparkleCount; i++) {
      list.add(_Sparkle(
        xRatio: _rng.nextDouble(),
        yRatio: _rng.nextDouble(),
        size: 8 + _rng.nextDouble() * 18,
        twinklePhase: _rng.nextDouble() * math.pi * 2,
        twinkleSpeed: 1.8 + _rng.nextDouble() * 2.2,
        delay: _rng.nextDouble() * 0.45,
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

class _Petal {
  final double spawnX, startYOffset, fallSpeed, size, aspect;
  final _PetalPalette palette;
  final double swayAmp, swaySpeed, swayPhase;
  final double rotation, rotSpeed, tiltSpeed, tiltPhase;
  final double delay;
  _Petal({
    required this.spawnX, required this.startYOffset, required this.fallSpeed,
    required this.size, required this.aspect, required this.palette,
    required this.swayAmp, required this.swaySpeed, required this.swayPhase,
    required this.rotation, required this.rotSpeed,
    required this.tiltSpeed, required this.tiltPhase,
    required this.delay,
  });
}

class _LightMote {
  final double xRatio, yRatio, size, drift, driftAngle;
  final double twinklePhase, twinkleSpeed, hue, delay;
  _LightMote({
    required this.xRatio, required this.yRatio, required this.size,
    required this.drift, required this.driftAngle,
    required this.twinklePhase, required this.twinkleSpeed,
    required this.hue, required this.delay,
  });
}

class _Sparkle {
  final double xRatio, yRatio, size, twinklePhase, twinkleSpeed, delay;
  _Sparkle({
    required this.xRatio, required this.yRatio, required this.size,
    required this.twinklePhase, required this.twinkleSpeed, required this.delay,
  });
}

class _HealingPainter extends CustomPainter {
  final double t;
  final List<_Petal> petals;
  final List<_LightMote> motes;
  final List<_Sparkle> sparkles;
  _HealingPainter({required this.t, required this.petals, required this.motes, required this.sparkles});

  @override
  void paint(Canvas canvas, Size size) {
    // 背景: 上部から淡い翡翠色のベール（空気感）
    final bgAlpha = stageAlpha(t, fadeIn: 0.12, hold: 0.60, fadeOut: 0.28);
    if (bgAlpha > 0) {
      canvas.drawRect(Offset.zero & size, Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width / 2, 0),
          Offset(size.width / 2, size.height),
          [
            Color.fromRGBO(200, 240, 230, 0.40 * bgAlpha),
            Color.fromRGBO(140, 210, 200, 0.22 * bgAlpha),
            Color.fromRGBO(50, 90, 85, 0.15 * bgAlpha),
            const Color(0x00000000),
          ],
          [0.0, 0.35, 0.75, 1.0],
        ));
    }

    // 上部のオーロラ状の光の帯（薄く横切る）
    _drawAuroraBand(canvas, size, bgAlpha);

    // 光の粒（奥）
    for (final m in motes) { _drawMote(canvas, m, size); }

    // 花びら
    for (final p in petals) { _drawPetal(canvas, p, size); }

    // スパークル（前面）
    for (final s in sparkles) { _drawSparkle(canvas, s, size); }
  }

  void _drawAuroraBand(Canvas canvas, Size size, double bgAlpha) {
    // 上部15%〜30%に柔らかいオーロラ色の帯
    if (bgAlpha <= 0) return;
    final bandTop = size.height * 0.05;
    final bandBottom = size.height * 0.35;
    final rect = Rect.fromLTRB(0, bandTop, size.width, bandBottom);

    // 時間で色相が微妙にシフト
    final phase = t * math.pi * 0.8;
    final hue1 = Color.lerp(
      const Color(0xFFB0F0E0), const Color(0xFFA8E8F0), (math.sin(phase) + 1) / 2,
    )!;
    final hue2 = Color.lerp(
      const Color(0xFFE0F5DD), const Color(0xFFD0E8F5), (math.cos(phase * 0.7) + 1) / 2,
    )!;

    canvas.drawRect(rect, Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, bandTop), Offset(0, bandBottom),
        [
          hue1.withValues(alpha: 0.28 * bgAlpha),
          hue2.withValues(alpha: 0.18 * bgAlpha),
          const Color(0x00000000),
        ],
        [0.0, 0.5, 1.0],
      )
      ..blendMode = BlendMode.plus);

    // 2本目のうっすら光の帯（ずらして）
    final bandTop2 = size.height * 0.15;
    final bandBottom2 = size.height * 0.45;
    canvas.drawRect(
      Rect.fromLTRB(0, bandTop2, size.width, bandBottom2),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width * 0.3, bandTop2),
          Offset(size.width * 0.7, bandBottom2),
          [
            const Color(0x00FFFFFF),
            Color.fromRGBO(220, 248, 240, 0.15 * bgAlpha),
            const Color(0x00FFFFFF),
          ],
          [0.0, 0.5, 1.0],
        )
        ..blendMode = BlendMode.plus,
    );
  }

  void _drawPetal(Canvas canvas, _Petal p, Size size) {
    final lt = ((t - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
    if (lt <= 0) return;
    final alpha = stageAlpha(lt, fadeIn: 0.12, hold: 0.68, fadeOut: 0.20);
    if (alpha <= 0) return;

    // 落下位置（重力はかけず一定速度、スウェイを加える）
    final startY = size.height * p.startYOffset;
    final endY = size.height * 1.12;
    final fallProgress = lt; // 一定速度で降る
    final baseY = startY + (endY - startY) * fallProgress * p.fallSpeed;
    if (baseY > size.height + 50) return;

    final swayX = math.sin(p.swayPhase + lt * p.swaySpeed * math.pi * 2) * p.swayAmp * size.width;
    final x = size.width * p.spawnX + swayX;

    // 3D風の傾き: Y軸回転で奥行き（スケールX圧縮）
    final tiltCos = math.cos(p.tiltPhase + lt * p.tiltSpeed * math.pi * 2);
    final faceVis = tiltCos.abs().clamp(0.25, 1.0);
    final isBackside = tiltCos < 0;

    final rot = p.rotation + p.rotSpeed * lt * math.pi;

    canvas.save();
    canvas.translate(x, baseY);
    canvas.rotate(rot);

    final s = p.size;
    final w = s * p.aspect;
    final pal = p.palette;

    // 後光（放射グラデ、ブラー不使用）
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 2.2, height: s * 1.4),
      Paint()
        ..shader = ui.Gradient.radial(Offset.zero, s * 0.7, [
          pal.main.withValues(alpha: 0.30 * alpha),
          pal.main.withValues(alpha: 0.10 * alpha),
          const Color(0x00000000),
        ], [0.0, 0.55, 1.0])
        ..blendMode = BlendMode.plus,
    );

    // 3D傾き: 水平方向スケール
    canvas.save();
    canvas.scale(faceVis, 1.0);

    // 花びら形状（上下に尖ったアーモンド）
    final path = _buildPetalPath(s, w);

    // 本体グラデ（表/裏で色味変更）
    canvas.drawPath(path, Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, -s * 0.4), Offset(0, s * 0.4),
        isBackside
            ? [
                pal.shadow.withValues(alpha: 0.8 * alpha),
                pal.main.withValues(alpha: 0.6 * alpha),
                pal.shadow.withValues(alpha: 0.7 * alpha),
              ]
            : [
                pal.highlight.withValues(alpha: alpha),
                pal.main.withValues(alpha: alpha),
                pal.shadow.withValues(alpha: 0.85 * alpha),
              ],
        const [0.0, 0.5, 1.0],
      ));

    // 光沢ハイライト（片側）
    if (!isBackside) {
      canvas.drawPath(path, Paint()
        ..shader = ui.Gradient.radial(
          Offset(-w * 0.2, -s * 0.12), s * 0.55,
          [
            Color.fromRGBO(255, 255, 255, 0.55 * alpha),
            const Color(0x00FFFFFF),
          ],
          [0.0, 1.0],
        )
        ..blendMode = BlendMode.plus);
    }

    // 中央脈（vein） — 控えめな線
    if (!isBackside && faceVis > 0.5) {
      canvas.drawLine(
        Offset(0, -s * 0.42),
        Offset(0, s * 0.42),
        Paint()
          ..color = pal.vein.withValues(alpha: 0.35 * alpha)
          ..strokeWidth = math.max(0.6, s * 0.01),
      );
    }

    // 縁取り
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, s * 0.012)
      ..color = (isBackside ? pal.shadow : pal.rim).withValues(alpha: 0.65 * alpha));

    canvas.restore(); // end scale
    canvas.restore(); // end translate/rotate
  }

  Path _buildPetalPath(double length, double width) {
    // 花びら: 上下に尖ったアーモンド/リーフ型
    final path = Path();
    final l = length * 0.5;
    final w = width * 0.5;
    path.moveTo(0, -l);
    path.cubicTo(w * 1.3, -l * 0.5, w * 1.05, l * 0.55, 0, l);
    path.cubicTo(-w * 1.05, l * 0.55, -w * 1.3, -l * 0.5, 0, -l);
    path.close();
    return path;
  }

  void _drawMote(Canvas canvas, _LightMote m, Size size) {
    final lt = ((t - m.delay) / (1.0 - m.delay)).clamp(0.0, 1.0);
    if (lt <= 0) return;
    final fadeEnv = stageAlpha(lt, fadeIn: 0.18, hold: 0.60, fadeOut: 0.22);
    if (fadeEnv <= 0) return;

    final driftDist = m.drift * size.height * lt;
    final x = size.width * m.xRatio + math.cos(m.driftAngle) * driftDist * 0.3;
    final y = size.height * m.yRatio + math.sin(m.driftAngle) * driftDist;
    final pos = Offset(x, y);

    final tw = (math.sin(m.twinklePhase + lt * m.twinkleSpeed * math.pi * 2) + 1) / 2;
    final alpha = fadeEnv * (0.3 + tw * 0.7);
    final color = Color.lerp(
      const Color(0xFFFFFFFF), const Color(0xFFB0E8DC), m.hue,
    )!;
    final size2 = m.size * (0.7 + tw * 0.5);

    canvas.drawCircle(pos, size2 * 1.6, Paint()
      ..shader = ui.Gradient.radial(pos, size2 * 1.6, [
        color.withValues(alpha: 0.55 * alpha),
        color.withValues(alpha: 0.18 * alpha),
        const Color(0x00000000),
      ], [0.0, 0.5, 1.0])
      ..blendMode = BlendMode.plus);
    canvas.drawCircle(pos, size2, Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: alpha));
  }

  void _drawSparkle(Canvas canvas, _Sparkle sp, Size size) {
    final lt = ((t - sp.delay) / (1.0 - sp.delay)).clamp(0.0, 1.0);
    if (lt <= 0) return;
    final fadeEnv = stageAlpha(lt, fadeIn: 0.18, hold: 0.55, fadeOut: 0.27);
    if (fadeEnv <= 0) return;

    final pos = Offset(size.width * sp.xRatio, size.height * sp.yRatio);
    final tw = (math.sin(sp.twinklePhase + lt * sp.twinkleSpeed * math.pi * 2) + 1) / 2;
    final alpha = fadeEnv * (0.35 + tw * 0.65);
    const color = Color(0xFFE0FFFC);
    final size2 = sp.size * (0.7 + tw * 0.6);

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.drawCircle(Offset.zero, size2 * 0.7, Paint()
      ..shader = ui.Gradient.radial(Offset.zero, size2 * 0.7, [
        color.withValues(alpha: 0.55 * alpha),
        color.withValues(alpha: 0.18 * alpha),
        const Color(0x00000000),
      ], [0.0, 0.5, 1.0])
      ..blendMode = BlendMode.plus);
    final starPaint = Paint()..color = color.withValues(alpha: alpha)..blendMode = BlendMode.plus;
    canvas.drawPath(Path()
      ..moveTo(0, -size2 * 0.5)
      ..quadraticBezierTo(size2 * 0.04, 0, 0, size2 * 0.5)
      ..quadraticBezierTo(-size2 * 0.04, 0, 0, -size2 * 0.5)
      ..close(), starPaint);
    canvas.drawPath(Path()
      ..moveTo(-size2 * 0.5, 0)
      ..quadraticBezierTo(0, size2 * 0.04, size2 * 0.5, 0)
      ..quadraticBezierTo(0, -size2 * 0.04, -size2 * 0.5, 0)
      ..close(), starPaint);
    canvas.drawCircle(Offset.zero, size2 * 0.06, Paint()..color = Color.fromRGBO(255, 255, 255, alpha));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HealingPainter old) => old.t != t;
}
