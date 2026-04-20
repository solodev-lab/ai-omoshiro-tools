import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '_common.dart';

/// 話す: 画面を横切る光のストリーム + 下から浮上する音符 + 光の粒。
/// 中心バーストなし。水平方向の流れで「対話」を表現。
class CommunicationPainterBuilder extends FortunePainterBuilder {
  final _rng = math.Random();
  late final List<_Stream> _streams;
  late final List<_Note> _notes;
  late final List<_LightMote> _motes;
  late final List<_Sparkle> _sparkles;

  static const _streamCount = 8;
  static const _noteCount = 28;
  static const _moteCount = 90;
  static const _sparkleCount = 22;

  CommunicationPainterBuilder() {
    _streams = _buildStreams();
    _notes = _buildNotes();
    _motes = _buildMotes();
    _sparkles = _buildSparkles();
  }

  @override
  CustomPainter buildPainter(double t) => _CommunicationPainter(
    t: t, streams: _streams, notes: _notes, motes: _motes, sparkles: _sparkles,
  );

  List<_Stream> _buildStreams() {
    final list = <_Stream>[];
    for (var i = 0; i < _streamCount; i++) {
      final leftToRight = _rng.nextBool();
      list.add(_Stream(
        leftToRight: leftToRight,
        yRatio: 0.1 + _rng.nextDouble() * 0.80,
        thickness: 1.5 + _rng.nextDouble() * 3.5,
        curvature: (_rng.nextDouble() - 0.5) * 0.18,
        hue: _rng.nextDouble(),
        delay: 0.05 + _rng.nextDouble() * 0.5,
        lifeSpan: 0.45 + _rng.nextDouble() * 0.25,
      ));
    }
    return list;
  }

  List<_Note> _buildNotes() {
    const symbols = ['♪', '♫', '♩', '♬', '♪'];
    final list = <_Note>[];
    for (var i = 0; i < _noteCount; i++) {
      list.add(_Note(
        symbol: symbols[_rng.nextInt(symbols.length)],
        spawnX: _rng.nextDouble(),
        size: 28.0 + math.pow(_rng.nextDouble(), 1.7).toDouble() * 52.0,
        riseSpeed: 0.75 + _rng.nextDouble() * 0.50,
        swayAmp: 0.015 + _rng.nextDouble() * 0.04,
        swaySpeed: 1.5 + _rng.nextDouble() * 2.0,
        swayPhase: _rng.nextDouble() * math.pi * 2,
        rotation: (_rng.nextDouble() - 0.5) * 0.4,
        rotSpeed: (_rng.nextDouble() - 0.5) * 0.6,
        hue: _rng.nextDouble(),
        delay: _rng.nextDouble() * 0.55,
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
        size: 1.8 + _rng.nextDouble() * 4.0,
        drift: 0.10 + _rng.nextDouble() * 0.20,
        driftAngle: _rng.nextDouble() * math.pi * 2,
        twinklePhase: _rng.nextDouble() * math.pi * 2,
        twinkleSpeed: 2.5 + _rng.nextDouble() * 2.5,
        hue: _rng.nextDouble(),
        delay: _rng.nextDouble() * 0.5,
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
        size: 8 + _rng.nextDouble() * 22,
        twinklePhase: _rng.nextDouble() * math.pi * 2,
        twinkleSpeed: 2.5 + _rng.nextDouble() * 2.5,
        hue: _rng.nextDouble(),
        delay: _rng.nextDouble() * 0.45,
      ));
    }
    return list;
  }
}

class _Stream {
  final bool leftToRight;
  final double yRatio, thickness, curvature, hue, delay, lifeSpan;
  _Stream({
    required this.leftToRight, required this.yRatio, required this.thickness,
    required this.curvature, required this.hue,
    required this.delay, required this.lifeSpan,
  });
}

class _Note {
  final String symbol;
  final double spawnX, size, riseSpeed, swayAmp, swaySpeed, swayPhase;
  final double rotation, rotSpeed, hue, delay;
  _Note({
    required this.symbol, required this.spawnX, required this.size,
    required this.riseSpeed, required this.swayAmp, required this.swaySpeed, required this.swayPhase,
    required this.rotation, required this.rotSpeed, required this.hue, required this.delay,
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
  final double xRatio, yRatio, size, twinklePhase, twinkleSpeed, hue, delay;
  _Sparkle({
    required this.xRatio, required this.yRatio, required this.size,
    required this.twinklePhase, required this.twinkleSpeed, required this.hue, required this.delay,
  });
}

class _CommunicationPainter extends CustomPainter {
  final double t;
  final List<_Stream> streams;
  final List<_Note> notes;
  final List<_LightMote> motes;
  final List<_Sparkle> sparkles;
  _CommunicationPainter({required this.t, required this.streams, required this.notes, required this.motes, required this.sparkles});

  static const _lavender = Color(0xFFB088FF);
  static const _blue = Color(0xFF8AB5FF);
  static const _violet = Color(0xFFD8BFFF);
  static const _cyan = Color(0xFFA8DFFF);

  Color _hueColor(double h) {
    if (h < 0.33) {
      return Color.lerp(_lavender, _blue, h * 3)!;
    } else if (h < 0.66) {
      return Color.lerp(_blue, _cyan, (h - 0.33) * 3)!;
    }
    return Color.lerp(_cyan, _violet, (h - 0.66) * 3)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 背景: 紫〜青のベール（画面全体に薄く）
    final bgAlpha = stageAlpha(t, fadeIn: 0.12, hold: 0.58, fadeOut: 0.30);
    if (bgAlpha > 0) {
      canvas.drawRect(Offset.zero & size, Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, 0), Offset(size.width, size.height),
          [
            Color.fromRGBO(180, 150, 255, 0.32 * bgAlpha),
            Color.fromRGBO(130, 170, 240, 0.22 * bgAlpha),
            Color.fromRGBO(30, 15, 50, 0.15 * bgAlpha),
            const Color(0x00000000),
          ],
          [0.0, 0.35, 0.75, 1.0],
        ));
    }

    // 背景の光の粒
    for (final m in motes) { _drawMote(canvas, m, size); }

    // 光のストリーム（水平の光の帯）
    for (final s in streams) { _drawStream(canvas, s, size); }

    // 音符（下から上へ）
    for (final n in notes) { _drawNote(canvas, n, size); }

    // スパークル
    for (final sp in sparkles) { _drawSparkle(canvas, sp, size); }
  }

  void _drawStream(Canvas canvas, _Stream s, Size size) {
    final localT = t - s.delay;
    if (localT <= 0 || localT >= s.lifeSpan) return;

    final lt = (localT / s.lifeSpan).clamp(0.0, 1.0);
    final alpha = stageAlpha(lt, fadeIn: 0.20, hold: 0.40, fadeOut: 0.40);
    if (alpha <= 0) return;

    // ストリームの進行: progress に応じて長い弧の一部を描画
    final progress = easeInOutQuad(lt);
    final totalLength = size.width * 1.3;
    final tipX = s.leftToRight
        ? -totalLength * 0.3 + progress * totalLength
        : size.width + totalLength * 0.3 - progress * totalLength;
    final tailX = s.leftToRight
        ? tipX - totalLength * 0.45
        : tipX + totalLength * 0.45;

    final yBase = size.height * s.yRatio;
    final yTip = yBase + (s.leftToRight ? -1 : 1) * s.curvature * size.height * 0.5;

    final path = Path()
      ..moveTo(tailX, yBase)
      ..quadraticBezierTo(
        (tailX + tipX) / 2, (yBase + yTip) / 2 + s.curvature * size.height * 0.3,
        tipX, yTip,
      );

    final color = _hueColor(s.hue);

    // 外側グロー
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.thickness * 4.5
      ..shader = ui.Gradient.linear(
        Offset(tailX, yBase), Offset(tipX, yTip),
        [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.35 * alpha),
          color.withValues(alpha: 0.60 * alpha),
        ],
        [0.0, 0.5, 1.0],
      )
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round);

    // 中間層
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.thickness * 1.8
      ..shader = ui.Gradient.linear(
        Offset(tailX, yBase), Offset(tipX, yTip),
        [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.6 * alpha),
          color.withValues(alpha: 0.9 * alpha),
        ],
        [0.0, 0.5, 1.0],
      )
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round);

    // 白いコア
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.thickness * 0.7
      ..shader = ui.Gradient.linear(
        Offset(tailX, yBase), Offset(tipX, yTip),
        [
          const Color(0x00FFFFFF),
          Color.fromRGBO(255, 255, 255, 0.6 * alpha),
          Color.fromRGBO(255, 255, 255, 0.95 * alpha),
        ],
        [0.0, 0.6, 1.0],
      )
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round);

    // 先端の明るいポイント
    canvas.drawCircle(Offset(tipX, yTip), s.thickness * 3.2, Paint()
      ..shader = ui.Gradient.radial(
        Offset(tipX, yTip), s.thickness * 3.2,
        [
          Color.fromRGBO(255, 255, 255, 0.95 * alpha),
          color.withValues(alpha: 0.45 * alpha),
          const Color(0x00000000),
        ],
        [0.0, 0.4, 1.0],
      )
      ..blendMode = BlendMode.plus);
  }

  void _drawNote(Canvas canvas, _Note n, Size size) {
    final lt = ((t - n.delay) / (1.0 - n.delay)).clamp(0.0, 1.0);
    if (lt <= 0) return;
    final alpha = stageAlpha(lt, fadeIn: 0.15, hold: 0.55, fadeOut: 0.30);
    if (alpha <= 0) return;

    // 位置: 下から上へ
    final startY = size.height * 1.1;
    final endY = -size.height * 0.15;
    final y = startY + (endY - startY) * n.riseSpeed * easeOutCubic(lt);

    final swayX = math.sin(n.swayPhase + lt * n.swaySpeed * math.pi * 2) * n.swayAmp * size.width;
    final x = size.width * n.spawnX + swayX;

    final scale = easeOutBack((lt / 0.25).clamp(0.0, 1.0)) * (0.9 + lt * 0.15);
    final rot = n.rotation + n.rotSpeed * lt;

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rot);
    canvas.scale(scale);

    final s = n.size;
    final color = _hueColor(n.hue);

    // グロー（後光）
    canvas.drawCircle(Offset.zero, s * 0.8, Paint()
      ..shader = ui.Gradient.radial(Offset.zero, s * 0.8, [
        color.withValues(alpha: 0.5 * alpha),
        color.withValues(alpha: 0.18 * alpha),
        const Color(0x00000000),
      ], [0.0, 0.55, 1.0])
      ..blendMode = BlendMode.plus);

    // 音符本体（グラデーションシェーダで塗る）
    final notePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, -s * 0.5), Offset(0, s * 0.5),
        [
          const Color(0xFFFFFFFF).withValues(alpha: alpha),
          color.withValues(alpha: alpha),
          Color.lerp(color, Colors.black, 0.4)!.withValues(alpha: 0.85 * alpha),
        ],
        [0.0, 0.5, 1.0],
      );

    final textStyle = TextStyle(
      fontSize: s,
      foreground: notePaint,
      height: 1.0,
      shadows: [
        Shadow(color: Colors.white.withValues(alpha: 0.35 * alpha), blurRadius: 0, offset: const Offset(0, 0)),
      ],
    );

    final tp = TextPainter(
      text: TextSpan(text: n.symbol, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tp.layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

    // 縁取り（明るい白）
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, s * 0.04)
      ..color = Color.fromRGBO(255, 255, 255, 0.55 * alpha);
    final tpOutline = TextPainter(
      text: TextSpan(text: n.symbol, style: TextStyle(
        fontSize: s, height: 1.0, foreground: outlinePaint,
      )),
      textDirection: TextDirection.ltr,
    );
    tpOutline.layout();
    tpOutline.paint(canvas, Offset(-tpOutline.width / 2, -tpOutline.height / 2));

    canvas.restore();
  }

  void _drawMote(Canvas canvas, _LightMote m, Size size) {
    final lt = ((t - m.delay) / (1.0 - m.delay)).clamp(0.0, 1.0);
    if (lt <= 0) return;
    final fadeEnv = stageAlpha(lt, fadeIn: 0.20, hold: 0.55, fadeOut: 0.25);
    if (fadeEnv <= 0) return;

    final driftDist = m.drift * size.height * lt;
    final x = size.width * m.xRatio + math.cos(m.driftAngle) * driftDist;
    final y = size.height * m.yRatio + math.sin(m.driftAngle) * driftDist;
    final pos = Offset(x, y);

    final tw = (math.sin(m.twinklePhase + lt * m.twinkleSpeed * math.pi * 2) + 1) / 2;
    final alpha = fadeEnv * (0.3 + tw * 0.7);
    final color = _hueColor(m.hue);
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
    final color = _hueColor(sp.hue);
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
  bool shouldRepaint(covariant _CommunicationPainter old) => old.t != t;
}
