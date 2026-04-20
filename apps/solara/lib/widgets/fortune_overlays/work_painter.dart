import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '_common.dart';

/// 仕事: 下から立ち上がる光の柱 + 上昇する結晶/幾何形状 + 横切る走査線。
/// 「地から湧き上がるエネルギー」の力強さ。
class WorkPainterBuilder extends FortunePainterBuilder {
  final _rng = math.Random();
  late final List<_Pillar> _pillars;
  late final List<_Shard> _shards;
  late final List<_ScanLine> _scans;
  late final List<_Spark> _sparks;
  late final List<_Sparkle> _sparkles;

  static const _pillarCount = 7;
  static const _shardCount = 32;
  static const _scanCount = 3;
  static const _sparkCount = 90;
  static const _sparkleCount = 22;

  WorkPainterBuilder() {
    _pillars = _buildPillars();
    _shards = _buildShards();
    _scans = _buildScans();
    _sparks = _buildSparks();
    _sparkles = _buildSparkles();
  }

  @override
  CustomPainter buildPainter(double t) => _WorkPainter(
    t: t, pillars: _pillars, shards: _shards, scans: _scans, sparks: _sparks, sparkles: _sparkles,
  );

  List<_Pillar> _buildPillars() {
    final list = <_Pillar>[];
    for (var i = 0; i < _pillarCount; i++) {
      list.add(_Pillar(
        xRatio: (i + 0.5) / _pillarCount + (_rng.nextDouble() - 0.5) * 0.04,
        width: 0.03 + _rng.nextDouble() * 0.06,
        maxHeight: 0.65 + _rng.nextDouble() * 0.30,
        riseSpeed: 0.8 + _rng.nextDouble() * 0.5,
        hue: _rng.nextDouble(),
        delay: 0.02 + _rng.nextDouble() * 0.25,
        shimmerSpeed: 2.0 + _rng.nextDouble() * 3.0,
        shimmerPhase: _rng.nextDouble() * math.pi * 2,
      ));
    }
    return list;
  }

  List<_Shard> _buildShards() {
    const palettes = <_ShardPalette>[
      // Electric blue
      _ShardPalette(
        highlight: Color(0xFFFFFFFF), main: Color(0xFF6BB5FF),
        shadow: Color(0xFF15325A), rim: Color(0xFFAEEAFF), glow: Color(0xFF00D4FF),
      ),
      // Cyan steel
      _ShardPalette(
        highlight: Color(0xFFF0FFFF), main: Color(0xFF8CD6F0),
        shadow: Color(0xFF244E68), rim: Color(0xFFBEEFFC), glow: Color(0xFF7FE8FF),
      ),
      // Ice
      _ShardPalette(
        highlight: Color(0xFFFFFFFF), main: Color(0xFFB0E0F0),
        shadow: Color(0xFF2E5870), rim: Color(0xFFD8F0FA), glow: Color(0xFFB0E0F0),
      ),
      // Deep ocean
      _ShardPalette(
        highlight: Color(0xFFE5F4FF), main: Color(0xFF5095E0),
        shadow: Color(0xFF0F1F4A), rim: Color(0xFF8AB5E8), glow: Color(0xFF4FC5FF),
      ),
    ];
    const shapes = <_ShardShape>[
      _ShardShape.diamond, _ShardShape.triangle, _ShardShape.hexagon, _ShardShape.diamond,
    ];
    final list = <_Shard>[];
    for (var i = 0; i < _shardCount; i++) {
      list.add(_Shard(
        spawnX: _rng.nextDouble(),
        riseSpeed: 0.80 + _rng.nextDouble() * 0.6,
        size: 16.0 + math.pow(_rng.nextDouble(), 1.7).toDouble() * 38.0,
        aspect: 0.5 + _rng.nextDouble() * 0.35,
        palette: palettes[_rng.nextInt(palettes.length)],
        shape: shapes[_rng.nextInt(shapes.length)],
        rotation: _rng.nextDouble() * math.pi * 2,
        rotSpeed: (_rng.nextDouble() - 0.5) * 1.4,
        flipSpeed: 1.5 + _rng.nextDouble() * 2.5,
        flipPhase: _rng.nextDouble() * math.pi * 2,
        swayAmp: 0.015 + _rng.nextDouble() * 0.03,
        swaySpeed: 1.5 + _rng.nextDouble() * 2.0,
        swayPhase: _rng.nextDouble() * math.pi * 2,
        flashPhase: _rng.nextDouble() * math.pi * 2,
        flashSpeed: 3.0 + _rng.nextDouble() * 3.0,
        delay: _rng.nextDouble() * 0.50,
      ));
    }
    return list;
  }

  List<_ScanLine> _buildScans() {
    final list = <_ScanLine>[];
    for (var i = 0; i < _scanCount; i++) {
      final downward = _rng.nextBool();
      list.add(_ScanLine(
        startYRatio: downward ? -0.1 : 1.1,
        endYRatio: downward ? 1.1 : -0.1,
        delay: 0.1 + i * 0.35 + _rng.nextDouble() * 0.1,
        duration: 0.35 + _rng.nextDouble() * 0.15,
        thickness: 2.0 + _rng.nextDouble() * 2.5,
        hue: _rng.nextDouble(),
      ));
    }
    return list;
  }

  List<_Spark> _buildSparks() {
    final list = <_Spark>[];
    for (var i = 0; i < _sparkCount; i++) {
      list.add(_Spark(
        spawnX: _rng.nextDouble(),
        riseSpeed: 0.8 + _rng.nextDouble() * 0.8,
        size: 1.8 + _rng.nextDouble() * 4.5,
        trailLength: 0.04 + _rng.nextDouble() * 0.10,
        wobbleAmp: 0.005 + _rng.nextDouble() * 0.02,
        wobbleSpeed: 2.0 + _rng.nextDouble() * 3.0,
        wobblePhase: _rng.nextDouble() * math.pi * 2,
        hue: _rng.nextDouble(),
        delay: _rng.nextDouble() * 0.6,
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
        size: 8 + _rng.nextDouble() * 20,
        twinklePhase: _rng.nextDouble() * math.pi * 2,
        twinkleSpeed: 3.0 + _rng.nextDouble() * 3.0,
        delay: _rng.nextDouble() * 0.5,
      ));
    }
    return list;
  }
}

enum _ShardShape { diamond, triangle, hexagon }

class _ShardPalette {
  final Color highlight, main, shadow, rim, glow;
  const _ShardPalette({
    required this.highlight, required this.main, required this.shadow,
    required this.rim, required this.glow,
  });
}

class _Pillar {
  final double xRatio, width, maxHeight, riseSpeed, hue, delay, shimmerSpeed, shimmerPhase;
  _Pillar({
    required this.xRatio, required this.width, required this.maxHeight,
    required this.riseSpeed, required this.hue, required this.delay,
    required this.shimmerSpeed, required this.shimmerPhase,
  });
}

class _Shard {
  final double spawnX, riseSpeed, size, aspect;
  final _ShardPalette palette;
  final _ShardShape shape;
  final double rotation, rotSpeed, flipSpeed, flipPhase;
  final double swayAmp, swaySpeed, swayPhase;
  final double flashPhase, flashSpeed, delay;
  _Shard({
    required this.spawnX, required this.riseSpeed, required this.size, required this.aspect,
    required this.palette, required this.shape,
    required this.rotation, required this.rotSpeed, required this.flipSpeed, required this.flipPhase,
    required this.swayAmp, required this.swaySpeed, required this.swayPhase,
    required this.flashPhase, required this.flashSpeed, required this.delay,
  });
}

class _ScanLine {
  final double startYRatio, endYRatio, delay, duration, thickness, hue;
  _ScanLine({
    required this.startYRatio, required this.endYRatio,
    required this.delay, required this.duration, required this.thickness, required this.hue,
  });
}

class _Spark {
  final double spawnX, riseSpeed, size, trailLength;
  final double wobbleAmp, wobbleSpeed, wobblePhase, hue, delay;
  _Spark({
    required this.spawnX, required this.riseSpeed, required this.size, required this.trailLength,
    required this.wobbleAmp, required this.wobbleSpeed, required this.wobblePhase,
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

class _WorkPainter extends CustomPainter {
  final double t;
  final List<_Pillar> pillars;
  final List<_Shard> shards;
  final List<_ScanLine> scans;
  final List<_Spark> sparks;
  final List<_Sparkle> sparkles;
  _WorkPainter({
    required this.t, required this.pillars, required this.shards,
    required this.scans, required this.sparks, required this.sparkles,
  });

  static const _electricBlue = Color(0xFF6BB5FF);
  static const _cyan = Color(0xFF00D4FF);
  static const _ice = Color(0xFFB0E0F0);
  static const _deepBlue = Color(0xFF4070D8);

  Color _hueColor(double h) {
    if (h < 0.33) {
      return Color.lerp(_electricBlue, _cyan, h * 3)!;
    } else if (h < 0.66) {
      return Color.lerp(_cyan, _ice, (h - 0.33) * 3)!;
    }
    return Color.lerp(_ice, _deepBlue, (h - 0.66) * 3)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 背景: 下から青のエネルギー
    final bgAlpha = stageAlpha(t, fadeIn: 0.10, hold: 0.60, fadeOut: 0.30);
    if (bgAlpha > 0) {
      canvas.drawRect(Offset.zero & size, Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width / 2, size.height),
          Offset(size.width / 2, 0),
          [
            Color.fromRGBO(130, 185, 255, 0.40 * bgAlpha),
            Color.fromRGBO(70, 120, 220, 0.25 * bgAlpha),
            Color.fromRGBO(10, 20, 50, 0.14 * bgAlpha),
            const Color(0x00000000),
          ],
          [0.0, 0.35, 0.75, 1.0],
        ));
    }

    // 光の柱（背景）
    for (final p in pillars) { _drawPillar(canvas, p, size); }

    // 火花（奥）
    for (final sp in sparks) { _drawSpark(canvas, sp, size); }

    // 結晶（前景）
    for (final sh in shards) { _drawShard(canvas, sh, size); }

    // スキャンライン（手前）
    for (final sc in scans) { _drawScanLine(canvas, sc, size); }

    // スパークル
    for (final sp in sparkles) { _drawSparkle(canvas, sp, size); }
  }

  void _drawPillar(Canvas canvas, _Pillar p, Size size) {
    final lt = ((t - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
    if (lt <= 0) return;
    final alpha = stageAlpha(lt, fadeIn: 0.15, hold: 0.55, fadeOut: 0.30);
    if (alpha <= 0) return;

    // 柱の高さ: 下から上へ伸びる
    final currentHeight = p.maxHeight * size.height * easeOutCubic(lt * p.riseSpeed).clamp(0.0, 1.0);
    final baseY = size.height;
    final topY = baseY - currentHeight;

    final centerX = size.width * p.xRatio;
    final w = size.width * p.width;

    // シマー（時間で強弱）
    final shimmer = (math.sin(p.shimmerPhase + t * p.shimmerSpeed * math.pi * 2) + 1) / 2;

    final color = _hueColor(p.hue);

    // 外側グロー（幅広、柔らかい）
    final rect = Rect.fromLTWH(centerX - w * 1.5, topY - 30, w * 3, currentHeight + 30);
    canvas.drawRect(rect, Paint()
      ..shader = ui.Gradient.linear(
        Offset(rect.left, 0), Offset(rect.right, 0),
        [
          const Color(0x00000000),
          color.withValues(alpha: (0.30 + shimmer * 0.15) * alpha),
          const Color(0x00000000),
        ],
        [0.0, 0.5, 1.0],
      )
      ..blendMode = BlendMode.plus);

    // 中間層
    final rect2 = Rect.fromLTWH(centerX - w * 0.6, topY - 15, w * 1.2, currentHeight + 15);
    canvas.drawRect(rect2, Paint()
      ..shader = ui.Gradient.linear(
        Offset(rect2.left, 0), Offset(rect2.right, 0),
        [
          const Color(0x00000000),
          color.withValues(alpha: 0.55 * alpha),
          const Color(0x00000000),
        ],
        [0.0, 0.5, 1.0],
      )
      ..blendMode = BlendMode.plus);

    // 明るいコア
    final rect3 = Rect.fromLTWH(centerX - w * 0.15, topY, w * 0.3, currentHeight);
    canvas.drawRect(rect3, Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, topY), Offset(0, baseY),
        [
          Color.fromRGBO(255, 255, 255, (0.5 + shimmer * 0.3) * alpha),
          Color.fromRGBO(255, 255, 255, 0.85 * alpha),
          Color.fromRGBO(255, 255, 255, 0.3 * alpha),
        ],
        [0.0, 0.2, 1.0],
      )
      ..blendMode = BlendMode.plus);

    // 先端の輝き
    canvas.drawCircle(Offset(centerX, topY), w * 2.0, Paint()
      ..shader = ui.Gradient.radial(
        Offset(centerX, topY), w * 2.0,
        [
          Color.fromRGBO(255, 255, 255, 0.85 * alpha),
          color.withValues(alpha: 0.35 * alpha),
          const Color(0x00000000),
        ],
        [0.0, 0.4, 1.0],
      )
      ..blendMode = BlendMode.plus);
  }

  void _drawShard(Canvas canvas, _Shard s, Size size) {
    final lt = ((t - s.delay) / (1.0 - s.delay)).clamp(0.0, 1.0);
    if (lt <= 0) return;
    final alpha = stageAlpha(lt, fadeIn: 0.18, hold: 0.55, fadeOut: 0.27);
    if (alpha <= 0) return;

    // 下から上へ移動
    final startY = size.height * 1.05;
    final endY = -size.height * 0.15;
    final y = startY + (endY - startY) * s.riseSpeed * easeOutCubic(lt);
    final swayX = math.sin(s.swayPhase + lt * s.swaySpeed * math.pi * 2) * s.swayAmp * size.width;
    final x = size.width * s.spawnX + swayX;

    final scale = easeOutBack((lt / 0.28).clamp(0.0, 1.0)) * 0.95;
    final rot = s.rotation + s.rotSpeed * lt;
    // フラッシュ
    final flashI = math.max(0, math.sin(s.flashPhase + lt * s.flashSpeed * math.pi * 2));
    // 3Dフリップ
    final flipCos = math.cos(s.flipPhase + lt * s.flipSpeed * math.pi * 2);
    final faceVis = flipCos.abs().clamp(0.25, 1.0);

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rot);
    canvas.scale(scale);

    final sz = s.size;
    final w = sz * s.aspect;
    final pal = s.palette;

    // 後光
    canvas.drawCircle(Offset.zero, sz * 0.8, Paint()
      ..shader = ui.Gradient.radial(Offset.zero, sz * 0.8, [
        pal.glow.withValues(alpha: (0.40 + flashI * 0.3) * alpha),
        pal.glow.withValues(alpha: 0.12 * alpha),
        const Color(0x00000000),
      ], [0.0, 0.55, 1.0])
      ..blendMode = BlendMode.plus);

    canvas.save();
    canvas.scale(faceVis, 1.0);

    final path = _buildShardPath(s.shape, sz, w);

    // 本体グラデ
    canvas.drawPath(path, Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, -sz), Offset(0, sz),
        [
          pal.highlight.withValues(alpha: 0.92 * alpha),
          pal.main.withValues(alpha: alpha),
          pal.shadow.withValues(alpha: 0.85 * alpha),
        ],
        [0.0, 0.5, 1.0],
      ));

    // 片面のファセット陰影
    if (s.shape == _ShardShape.diamond || s.shape == _ShardShape.hexagon) {
      final leftFacet = Path()
        ..moveTo(0, -sz)
        ..lineTo(-w, 0)
        ..lineTo(0, sz)
        ..close();
      canvas.drawPath(leftFacet, Paint()
        ..color = Color.fromRGBO(0, 0, 0, 0.22 * alpha)
        ..blendMode = BlendMode.multiply);
    }

    // 中心の縦ハイライト
    final hlPath = Path()
      ..moveTo(0, -sz * 0.9)
      ..lineTo(w * 0.12, 0)
      ..lineTo(0, sz * 0.9)
      ..lineTo(-w * 0.12, 0)
      ..close();
    canvas.drawPath(hlPath, Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, -sz * 0.9), Offset(0, sz * 0.9),
        [
          const Color(0x00FFFFFF),
          Color.fromRGBO(255, 255, 255, (0.55 + flashI * 0.35) * alpha),
          const Color(0x00FFFFFF),
        ],
        [0.0, 0.5, 1.0],
      )
      ..blendMode = BlendMode.plus);

    // 縁取り
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, sz * 0.02)
      ..color = pal.rim.withValues(alpha: (0.65 + flashI * 0.35) * alpha)
      ..blendMode = BlendMode.plus);

    canvas.restore();

    // エッジオン時のスリット
    if (faceVis < 0.30) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: math.max(1.4, sz * 0.06), height: sz),
        Paint()
          ..color = pal.rim.withValues(alpha: alpha)
          ..blendMode = BlendMode.plus,
      );
    }

    canvas.restore();
  }

  Path _buildShardPath(_ShardShape shape, double sz, double w) {
    final path = Path();
    switch (shape) {
      case _ShardShape.diamond:
        path
          ..moveTo(0, -sz)
          ..lineTo(w, 0)
          ..lineTo(0, sz)
          ..lineTo(-w, 0)
          ..close();
        break;
      case _ShardShape.triangle:
        path
          ..moveTo(0, -sz)
          ..lineTo(w * 1.15, sz * 0.85)
          ..lineTo(-w * 1.15, sz * 0.85)
          ..close();
        break;
      case _ShardShape.hexagon:
        for (var i = 0; i < 6; i++) {
          final a = math.pi / 2 + i * math.pi / 3;
          final px = math.cos(a) * w * 1.05;
          final py = -math.sin(a) * sz;
          if (i == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        path.close();
        break;
    }
    return path;
  }

  void _drawScanLine(Canvas canvas, _ScanLine sc, Size size) {
    final localT = t - sc.delay;
    if (localT <= 0 || localT >= sc.duration) return;
    final lt = (localT / sc.duration).clamp(0.0, 1.0);
    final alpha = stageAlpha(lt, fadeIn: 0.15, hold: 0.30, fadeOut: 0.55);
    if (alpha <= 0) return;

    final startY = size.height * sc.startYRatio;
    final endY = size.height * sc.endYRatio;
    final y = startY + (endY - startY) * easeOutCubic(lt);

    final color = _hueColor(sc.hue);

    // 外側グロー（厚い）
    canvas.drawRect(
      Rect.fromLTWH(0, y - sc.thickness * 8, size.width, sc.thickness * 16),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, y - sc.thickness * 8), Offset(0, y + sc.thickness * 8),
          [
            const Color(0x00000000),
            color.withValues(alpha: 0.35 * alpha),
            const Color(0x00000000),
          ],
          [0.0, 0.5, 1.0],
        )
        ..blendMode = BlendMode.plus,
    );

    // 中間
    canvas.drawRect(
      Rect.fromLTWH(0, y - sc.thickness * 2, size.width, sc.thickness * 4),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, y - sc.thickness * 2), Offset(0, y + sc.thickness * 2),
          [
            const Color(0x00000000),
            color.withValues(alpha: 0.75 * alpha),
            const Color(0x00000000),
          ],
          [0.0, 0.5, 1.0],
        )
        ..blendMode = BlendMode.plus,
    );

    // 白いコアライン
    canvas.drawLine(
      Offset(0, y), Offset(size.width, y),
      Paint()
        ..strokeWidth = sc.thickness * 0.7
        ..color = Color.fromRGBO(255, 255, 255, 0.9 * alpha)
        ..blendMode = BlendMode.plus,
    );
  }

  void _drawSpark(Canvas canvas, _Spark sp, Size size) {
    final lt = ((t - sp.delay) / (1.0 - sp.delay)).clamp(0.0, 1.0);
    if (lt <= 0) return;
    final alpha = stageAlpha(lt, fadeIn: 0.15, hold: 0.55, fadeOut: 0.30);
    if (alpha <= 0) return;

    final travel = size.height * 1.15 * sp.riseSpeed * easeOutCubic(lt);
    final wobble = math.sin(sp.wobblePhase + lt * sp.wobbleSpeed * math.pi * 2) * sp.wobbleAmp * size.width;
    final x = sp.spawnX * size.width + wobble;
    final y = size.height * 1.05 - travel;

    final color = Color.lerp(_electricBlue, const Color(0xFFE0FAFF), sp.hue)!;
    final tail = sp.trailLength * size.height;
    final tailStart = Offset(x - wobble * 0.3, y + tail);
    final head = Offset(x, y);

    canvas.drawLine(tailStart, head, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sp.size * 0.6
      ..shader = ui.Gradient.linear(tailStart, head, [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.8 * alpha),
      ], [0.0, 1.0])
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round);

    canvas.drawCircle(head, sp.size * 2.2, Paint()
      ..shader = ui.Gradient.radial(head, sp.size * 2.2, [
        color.withValues(alpha: 0.85 * alpha),
        color.withValues(alpha: 0.22 * alpha),
        const Color(0x00000000),
      ], [0.0, 0.5, 1.0])
      ..blendMode = BlendMode.plus);

    canvas.drawCircle(head, sp.size * 0.7, Paint()
      ..color = Color.fromRGBO(255, 255, 255, alpha));
  }

  void _drawSparkle(Canvas canvas, _Sparkle sp, Size size) {
    final lt = ((t - sp.delay) / (1.0 - sp.delay)).clamp(0.0, 1.0);
    if (lt <= 0) return;
    final fadeEnv = stageAlpha(lt, fadeIn: 0.18, hold: 0.55, fadeOut: 0.27);
    if (fadeEnv <= 0) return;

    final pos = Offset(size.width * sp.xRatio, size.height * sp.yRatio);
    final tw = (math.sin(sp.twinklePhase + lt * sp.twinkleSpeed * math.pi * 2) + 1) / 2;
    final alpha = fadeEnv * (0.35 + tw * 0.65);
    const color = Color(0xFFE0F5FF);
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
  bool shouldRepaint(covariant _WorkPainter old) => old.t != t;
}
