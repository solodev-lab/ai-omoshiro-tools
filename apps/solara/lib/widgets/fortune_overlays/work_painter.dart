import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '_common.dart';

/// 仕事（Solara風）: 金の勲章 medallion が次々と画面に現れ、軽やかに回転し漂う。
/// 背景では真鍮の歯車が静かに噛み合って回る。演出終盤、medallion達は中央へ
/// 集まり、中央から左右へ光線が水平に伸びて達成の印を結ぶ。
class WorkPainterBuilder extends FortunePainterBuilder {
  final _rng = math.Random();
  late final List<_Medallion> _medallions;
  late final List<_Gear> _gears;
  late final List<_GoldDust> _dust;
  late final List<_Sparkle> _sparkles;

  static const _medalCount = 20;
  static const _gearCount = 3;
  static const _dustCount = 110;
  static const _sparkleCount = 28;

  WorkPainterBuilder() {
    _medallions = _buildMedallions();
    _gears = _buildGears();
    _dust = _buildDust();
    _sparkles = _buildSparkles();
  }

  @override
  CustomPainter buildPainter(double t) => _WorkPainter(
    t: t, medallions: _medallions, gears: _gears, dust: _dust, sparkles: _sparkles,
  );

  List<_Medallion> _buildMedallions() {
    // 黒・深青・ガンメタル基調、金と銀の彫刻。暖色（ワイン/ローズ）廃止。
    const palettes = <_MedalPalette>[
      // Onyx gold（黒金）
      _MedalPalette(
        plate: Color(0xFF0A0812), plateHl: Color(0xFF1C1830),
        edge: Color(0xFFD8A848), edgeHl: Color(0xFFF0E0A0),
        emblem: Color(0xFFE8C878), deepShadow: Color(0xFF000000),
      ),
      // Midnight gold（深青金）
      _MedalPalette(
        plate: Color(0xFF060E22), plateHl: Color(0xFF14284C),
        edge: Color(0xFFC89830), edgeHl: Color(0xFFE8CC60),
        emblem: Color(0xFFDEB858), deepShadow: Color(0xFF000000),
      ),
      // Gunmetal silver（ガンメタル銀）
      _MedalPalette(
        plate: Color(0xFF0E1016), plateHl: Color(0xFF242834),
        edge: Color(0xFFB0B8C4), edgeHl: Color(0xFFE0E4EC),
        emblem: Color(0xFFC8CFD8), deepShadow: Color(0xFF020204),
      ),
      // Obsidian gold（黒曜石＋金）
      _MedalPalette(
        plate: Color(0xFF07060C), plateHl: Color(0xFF1A1628),
        edge: Color(0xFFBE9040), edgeHl: Color(0xFFE2B868),
        emblem: Color(0xFFD0A558), deepShadow: Color(0xFF000000),
      ),
      // Deep plum gold（深紫金）
      _MedalPalette(
        plate: Color(0xFF10081C), plateHl: Color(0xFF2A1448),
        edge: Color(0xFFC0A250), edgeHl: Color(0xFFE8C878),
        emblem: Color(0xFFE0BE68), deepShadow: Color(0xFF020006),
      ),
    ];
    const emblems = [
      '☉\uFE0E', '☽\uFE0E', '✶\uFE0E', '✦\uFE0E', '❋\uFE0E',
      '☥\uFE0E', '⚭\uFE0E', '⚜\uFE0E',
      'V', 'X', 'M', 'I',
    ];

    final list = <_Medallion>[];
    for (var i = 0; i < _medalCount; i++) {
      // 最終的に中央に集まるので、初期位置は中央付近を避けて画面全体に散らす
      final ang = _rng.nextDouble() * math.pi * 2;
      final rad = 0.18 + _rng.nextDouble() * 0.30;
      list.add(_Medallion(
        xRatio: (0.50 + math.cos(ang) * rad).clamp(0.10, 0.90),
        yRatio: (0.50 + math.sin(ang) * rad * 0.85).clamp(0.10, 0.90),
        size: 38.0 + math.pow(_rng.nextDouble(), 1.6).toDouble() * 56.0,
        palette: palettes[_rng.nextInt(palettes.length)],
        emblem: emblems[_rng.nextInt(emblems.length)],
        rotation: (_rng.nextDouble() - 0.5) * 0.35,
        spinSpeed: (_rng.nextDouble() - 0.5) * 0.40,
        driftAmp: 0.005 + _rng.nextDouble() * 0.010,
        driftSpeed: 0.8 + _rng.nextDouble() * 0.9,
        driftPhase: _rng.nextDouble() * math.pi * 2,
        driftAngle: _rng.nextDouble() * math.pi * 2,
        delay: _rng.nextDouble() * 0.45,
      ));
    }
    return list;
  }

  List<_Gear> _buildGears() {
    final list = <_Gear>[];
    // 画面の四隅寄りに配置、重ならないように
    final configs = <List<double>>[
      // xRatio, yRatio, radius(画面幅比), toothCount, rotSpeed, phase
      [0.18, 0.22, 0.16, 14, 0.35, 0.0],
      [0.82, 0.36, 0.13, 11, -0.45, 0.8],
      [0.26, 0.82, 0.14, 13, -0.32, 1.6],
    ];
    for (var i = 0; i < _gearCount && i < configs.length; i++) {
      final c = configs[i];
      list.add(_Gear(
        xRatio: c[0], yRatio: c[1], radius: c[2],
        toothCount: c[3].toInt(), rotSpeed: c[4], phase: c[5],
      ));
    }
    return list;
  }

  List<_GoldDust> _buildDust() {
    final list = <_GoldDust>[];
    for (var i = 0; i < _dustCount; i++) {
      list.add(_GoldDust(
        xRatio: _rng.nextDouble(),
        yRatio: _rng.nextDouble(),
        size: 1.2 + _rng.nextDouble() * 3.0,
        driftAmp: 0.008 + _rng.nextDouble() * 0.020,
        driftSpeed: 0.8 + _rng.nextDouble() * 1.4,
        driftPhase: _rng.nextDouble() * math.pi * 2,
        driftAngle: _rng.nextDouble() * math.pi * 2,
        twinklePhase: _rng.nextDouble() * math.pi * 2,
        twinkleSpeed: 1.6 + _rng.nextDouble() * 2.2,
        warm: _rng.nextDouble() < 0.70,
        delay: _rng.nextDouble() * 0.35,
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
        size: 9 + _rng.nextDouble() * 20,
        twinklePhase: _rng.nextDouble() * math.pi * 2,
        twinkleSpeed: 2.0 + _rng.nextDouble() * 2.4,
        hue: _rng.nextDouble(),
        delay: _rng.nextDouble() * 0.55,
      ));
    }
    return list;
  }
}

class _MedalPalette {
  final Color plate, plateHl, edge, edgeHl, emblem, deepShadow;
  const _MedalPalette({
    required this.plate, required this.plateHl,
    required this.edge, required this.edgeHl,
    required this.emblem, required this.deepShadow,
  });
}

class _Medallion {
  final double xRatio, yRatio, size;
  final _MedalPalette palette;
  final String emblem;
  final double rotation, spinSpeed;
  final double driftAmp, driftSpeed, driftPhase, driftAngle;
  final double delay;
  _Medallion({
    required this.xRatio, required this.yRatio, required this.size,
    required this.palette, required this.emblem,
    required this.rotation, required this.spinSpeed,
    required this.driftAmp, required this.driftSpeed,
    required this.driftPhase, required this.driftAngle,
    required this.delay,
  });
}

class _Gear {
  final double xRatio, yRatio, radius;
  final int toothCount;
  final double rotSpeed, phase;
  _Gear({
    required this.xRatio, required this.yRatio, required this.radius,
    required this.toothCount, required this.rotSpeed, required this.phase,
  });
}

class _GoldDust {
  final double xRatio, yRatio, size;
  final double driftAmp, driftSpeed, driftPhase, driftAngle;
  final double twinklePhase, twinkleSpeed;
  final bool warm;
  final double delay;
  _GoldDust({
    required this.xRatio, required this.yRatio, required this.size,
    required this.driftAmp, required this.driftSpeed,
    required this.driftPhase, required this.driftAngle,
    required this.twinklePhase, required this.twinkleSpeed,
    required this.warm, required this.delay,
  });
}

class _Sparkle {
  final double xRatio, yRatio, size, twinklePhase, twinkleSpeed, hue, delay;
  _Sparkle({
    required this.xRatio, required this.yRatio, required this.size,
    required this.twinklePhase, required this.twinkleSpeed,
    required this.hue, required this.delay,
  });
}

class _WorkPainter extends CustomPainter {
  final double t;
  final List<_Medallion> medallions;
  final List<_Gear> gears;
  final List<_GoldDust> dust;
  final List<_Sparkle> sparkles;
  _WorkPainter({
    required this.t, required this.medallions, required this.gears,
    required this.dust, required this.sparkles,
  });

  static const _deepBlack = Color(0xFF05060E);
  static const _navy = Color(0xFF0A1230);
  static const _violet = Color(0xFF14103A);
  static const _antiqueGold = Color(0xFFD8A848);
  static const _paleGold = Color(0xFFF0D890);
  static const _ivory = Color(0xFFF8E8C0);
  static const _brassDim = Color(0xFF886028);

  // 中央収束の開始タイミング / 左右光線の開始
  static const _convergeStart = 0.55;
  static const _lateralStart = 0.78;

  @override
  void paint(Canvas canvas, Size size) {
    final bgAlpha = stageAlpha(t, fadeIn: 0.10, hold: 0.60, fadeOut: 0.30);

    // 背景: 深黒 → 深青 → 深紫の縦グラデ（クール基調、他カテゴリと同程度に薄く）
    if (bgAlpha > 0) {
      canvas.drawRect(Offset.zero & size, Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width / 2, 0),
          Offset(size.width / 2, size.height),
          [
            _deepBlack.withValues(alpha: 0.30 * bgAlpha),
            _navy.withValues(alpha: 0.26 * bgAlpha),
            _violet.withValues(alpha: 0.20 * bgAlpha),
            const Color(0x00000000),
          ],
          [0.0, 0.40, 0.80, 1.0],
        ));
    }

    // 歯車（奥、静かに回転する背景装飾）
    for (final g in gears) { _drawGear(canvas, g, size, bgAlpha); }

    // 金粉（奥、常時漂う）
    for (final d in dust) { _drawDust(canvas, d, size); }

    // 勲章（メイン、登場→漂う→終盤に中央収束）
    for (final m in medallions) { _drawMedallion(canvas, m, size); }

    // 最終モーメント: 閃光→波紋リング→中央紋章
    _drawFinalMoment(canvas, size);

    // スパークル（前面、常時輝き）
    for (final s in sparkles) { _drawSparkle(canvas, s, size); }
  }

  // ─── 歯車（背景） ─────────────────────────
  void _drawGear(Canvas canvas, _Gear g, Size size, double bgAlpha) {
    if (bgAlpha <= 0) return;
    // 演出終盤にかけて歯車自体も少しフェードアウト（medallionが主役化）
    final fadeOut = t > 0.75 ? (1.0 - (t - 0.75) / 0.25).clamp(0.0, 1.0) : 1.0;
    final alpha = bgAlpha * fadeOut;
    if (alpha <= 0) return;

    final r = g.radius * size.width;
    final cx = size.width * g.xRatio;
    final cy = size.height * g.yRatio;
    final rot = g.phase + t * g.rotSpeed * math.pi * 2;
    final toothDepth = r * 0.18;
    final innerR = r * 0.55;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rot);

    // 歯車外形
    final path = Path();
    final n = g.toothCount;
    for (var i = 0; i < n * 2; i++) {
      final a = (i / (n * 2)) * math.pi * 2;
      final rr = i.isEven ? r : r - toothDepth;
      final px = math.cos(a) * rr;
      final py = math.sin(a) * rr;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();

    canvas.drawPath(path, Paint()
      ..color = _brassDim.withValues(alpha: 0.14 * alpha)
      ..blendMode = BlendMode.plus);
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, r * 0.020)
      ..color = _antiqueGold.withValues(alpha: 0.45 * alpha)
      ..blendMode = BlendMode.plus);

    // 中心穴
    canvas.drawCircle(Offset.zero, innerR * 0.35, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, r * 0.018)
      ..color = _antiqueGold.withValues(alpha: 0.52 * alpha)
      ..blendMode = BlendMode.plus);
    canvas.drawCircle(Offset.zero, innerR * 0.35, Paint()
      ..color = _paleGold.withValues(alpha: 0.10 * alpha));

    // スポーク4本
    final spokePaint = Paint()
      ..strokeWidth = math.max(0.8, r * 0.020)
      ..color = _antiqueGold.withValues(alpha: 0.38 * alpha)
      ..strokeCap = StrokeCap.butt
      ..blendMode = BlendMode.plus;
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final p0 = Offset(math.cos(a) * innerR * 0.38, math.sin(a) * innerR * 0.38);
      final p1 = Offset(math.cos(a) * innerR * 0.92, math.sin(a) * innerR * 0.92);
      canvas.drawLine(p0, p1, spokePaint);
    }

    canvas.restore();
  }

  // ─── 最終モーメント: 閃光→波紋リング→中央紋章 ────
  void _drawFinalMoment(Canvas canvas, Size size) {
    if (t < _lateralStart) return;
    final localT = (t - _lateralStart) / (1.0 - _lateralStart);
    final lt = localT.clamp(0.0, 1.0);

    final c = Offset(size.width * 0.5, size.height * 0.5);
    final diag = math.sqrt(size.width * size.width + size.height * size.height);

    // ── Phase 1: 閃光（lt 0〜0.20 でピーク→急減衰）
    double flashAlpha = 0;
    if (lt < 0.08) {
      flashAlpha = lt / 0.08;
    } else if (lt < 0.22) {
      flashAlpha = 1.0 - (lt - 0.08) / 0.14;
    }
    flashAlpha = flashAlpha.clamp(0.0, 1.0);
    if (flashAlpha > 0) {
      // 中央から広がる強い白光（画面全体に到達）
      canvas.drawRect(Offset.zero & size, Paint()
        ..shader = ui.Gradient.radial(c, diag * 0.65, [
          Colors.white.withValues(alpha: 0.95 * flashAlpha),
          _ivory.withValues(alpha: 0.60 * flashAlpha),
          _paleGold.withValues(alpha: 0.22 * flashAlpha),
          const Color(0x00000000),
        ], [0.0, 0.30, 0.65, 1.0])
        ..blendMode = BlendMode.plus);
    }

    // ── Phase 2: 波紋リング 3本（時差で外へ広がる）
    final maxR = diag * 0.58;
    for (var i = 0; i < 3; i++) {
      final ringStart = 0.12 + i * 0.14;
      const ringDuration = 0.46;
      if (lt < ringStart || lt >= ringStart + ringDuration) continue;
      final ringT = ((lt - ringStart) / ringDuration).clamp(0.0, 1.0);
      final ringR = maxR * easeOutCubic(ringT);
      final ringAlpha = (1.0 - ringT);

      // 外側の金の輪（太め）
      canvas.drawCircle(c, ringR, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.8, size.width * 0.008)
        ..color = _paleGold.withValues(alpha: 0.55 * ringAlpha)
        ..blendMode = BlendMode.plus);
      // 内側の白芯（薄い、若干内側）
      canvas.drawCircle(c, ringR - math.max(1.0, size.width * 0.003), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, size.width * 0.003)
        ..color = Colors.white.withValues(alpha: 0.70 * ringAlpha)
        ..blendMode = BlendMode.plus);
    }

    // ── Phase 3: 中央紋章（lt >= 0.18からフェードイン、回転）
    if (lt >= 0.15) {
      final sigilT = ((lt - 0.15) / 0.85).clamp(0.0, 1.0);
      final sigilAlpha = stageAlpha(sigilT, fadeIn: 0.20, hold: 0.55, fadeOut: 0.25);
      if (sigilAlpha > 0) {
        final rBase = math.min(size.width, size.height) * 0.115;
        final scale = easeOutBack((sigilT / 0.32).clamp(0.0, 1.0));
        final r = rBase * scale;
        final rot = sigilT * math.pi * 0.18;

        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(rot);

        // 後光（柔らかい広い光）
        canvas.drawCircle(Offset.zero, r * 2.2, Paint()
          ..shader = ui.Gradient.radial(Offset.zero, r * 2.2, [
            _ivory.withValues(alpha: 0.55 * sigilAlpha),
            _paleGold.withValues(alpha: 0.24 * sigilAlpha),
            const Color(0x00000000),
          ], [0.0, 0.5, 1.0])
          ..blendMode = BlendMode.plus);

        // 二重円
        canvas.drawCircle(Offset.zero, r, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, r * 0.055)
          ..color = _antiqueGold.withValues(alpha: 0.95 * sigilAlpha)
          ..blendMode = BlendMode.plus);
        canvas.drawCircle(Offset.zero, r * 0.80, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.6, r * 0.022)
          ..color = _paleGold.withValues(alpha: 0.90 * sigilAlpha)
          ..blendMode = BlendMode.plus);

        // 16点の八芒星（金塗り＋縁取り）
        final starPath = Path();
        for (var i = 0; i < 16; i++) {
          final a = (i / 16) * math.pi * 2 - math.pi / 2;
          final rr = i.isEven ? r * 0.86 : r * 0.42;
          final px = math.cos(a) * rr;
          final py = math.sin(a) * rr;
          if (i == 0) {
            starPath.moveTo(px, py);
          } else {
            starPath.lineTo(px, py);
          }
        }
        starPath.close();
        canvas.drawPath(starPath, Paint()
          ..shader = ui.Gradient.radial(Offset.zero, r, [
            _ivory.withValues(alpha: 0.98 * sigilAlpha),
            _paleGold.withValues(alpha: 0.85 * sigilAlpha),
          ], [0.0, 1.0]));
        canvas.drawPath(starPath, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.8, r * 0.028)
          ..color = _antiqueGold.withValues(alpha: 0.95 * sigilAlpha)
          ..strokeJoin = StrokeJoin.miter
          ..blendMode = BlendMode.plus);

        // 中心の小さな白コア
        canvas.drawCircle(Offset.zero, r * 0.14, Paint()
          ..color = _ivory.withValues(alpha: sigilAlpha));
        canvas.drawCircle(Offset.zero, r * 0.07, Paint()
          ..color = Colors.white.withValues(alpha: sigilAlpha));

        canvas.restore();
      }
    }
  }

  // ─── 勲章 medallion ───────────────────────
  // 登場フェード → 漂う → 中央収束 → 光線フェーズで小さく溶ける
  void _drawMedallion(Canvas canvas, _Medallion m, Size size) {
    final localT = t - m.delay;
    if (localT <= 0) return;

    // 登場フェード（0〜0.18秒）
    double appearAlpha = (localT / 0.18).clamp(0.0, 1.0);
    // 光線が広がり始めたら medallion はスッと溶ける
    double finalAlpha = 1.0;
    if (t > _lateralStart) {
      finalAlpha = (1.0 - (t - _lateralStart) / 0.18).clamp(0.0, 1.0);
    }
    final alpha = appearAlpha * finalAlpha;
    if (alpha <= 0) return;

    // 登場ポップスケール
    final popScale = easeOutBack((localT / 0.22).clamp(0.0, 1.0));

    // 小振幅の漂い
    final dr = math.sin(m.driftPhase + localT * m.driftSpeed * math.pi * 2) * m.driftAmp;
    final dxDrift = math.cos(m.driftAngle) * dr * size.width;
    final dyDrift = math.sin(m.driftAngle) * dr * size.width * 0.6;

    // 基本位置
    final baseX = size.width * m.xRatio + dxDrift;
    final baseY = size.height * m.yRatio + dyDrift;

    // 中央収束: t >= _convergeStart から中央へ引き寄せ
    double convergeT = 0;
    if (t > _convergeStart) {
      convergeT = easeInOutQuad(
        ((t - _convergeStart) / (_lateralStart - _convergeStart)).clamp(0.0, 1.0),
      );
    }
    final cx = size.width * 0.5;
    final cy = size.height * 0.5;
    final px = baseX + (cx - baseX) * convergeT;
    final py = baseY + (cy - baseY) * convergeT;

    // 収束中はスケールを少し縮小（密集感）
    final convergeScale = 1.0 - convergeT * 0.25;
    final s = m.size * popScale * convergeScale;

    final rot = m.rotation + m.spinSpeed * localT;
    final pal = m.palette;

    canvas.save();
    canvas.translate(px, py);
    canvas.rotate(rot);

    _paintMedalBody(canvas, s, pal, m.emblem, alpha);

    canvas.restore();
  }

  // 精密な八角形盤面（機械式メカニカル、黒金）
  void _paintMedalBody(
    Canvas canvas, double s, _MedalPalette pal, String emblem, double alpha,
  ) {
    final r = s * 0.5;

    // 後光（控えめ、冷たい光）
    canvas.drawCircle(Offset.zero, r * 1.6, Paint()
      ..shader = ui.Gradient.radial(Offset.zero, r * 1.6, [
        pal.edge.withValues(alpha: 0.28 * alpha),
        pal.edge.withValues(alpha: 0.08 * alpha),
        const Color(0x00000000),
      ], [0.0, 0.55, 1.0])
      ..blendMode = BlendMode.plus);

    // 八角形外枠パス
    final outerPath = _octagonPath(r);

    // 外枠 — 暗黒プレート（金属の深み）
    canvas.drawPath(outerPath, Paint()
      ..shader = ui.Gradient.linear(
        Offset(-r * 0.5, -r * 0.7), Offset(r * 0.5, r * 0.7),
        [
          pal.plateHl.withValues(alpha: alpha),
          pal.plate.withValues(alpha: alpha),
          pal.deepShadow.withValues(alpha: 0.95 * alpha),
        ],
        [0.0, 0.45, 1.0],
      ));

    // 外枠エッジ（金の刻印）
    canvas.drawPath(outerPath, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, r * 0.050)
      ..color = pal.edge.withValues(alpha: 0.95 * alpha)
      ..strokeJoin = StrokeJoin.miter);

    // 内側の八角形（ひとまわり小さく、金の内枠）
    final inner1Path = _octagonPath(r * 0.82);
    canvas.drawPath(inner1Path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, r * 0.022)
      ..color = pal.edgeHl.withValues(alpha: 0.90 * alpha)
      ..strokeJoin = StrokeJoin.miter);

    // 内側の円（機械盤面）
    canvas.drawCircle(Offset.zero, r * 0.70, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.5, r * 0.016)
      ..color = pal.edge.withValues(alpha: 0.75 * alpha));
    canvas.drawCircle(Offset.zero, r * 0.60, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.4, r * 0.012)
      ..color = pal.edge.withValues(alpha: 0.55 * alpha));

    // 12分目盛（長い/短いを交互に、時計風）
    for (var i = 0; i < 24; i++) {
      final a = i * math.pi / 12 - math.pi / 2;
      final isMajor = i % 2 == 0;
      final rOut = r * 0.70;
      final rIn = isMajor ? r * 0.60 : r * 0.65;
      final p1 = Offset(math.cos(a) * rIn, math.sin(a) * rIn);
      final p2 = Offset(math.cos(a) * rOut, math.sin(a) * rOut);
      canvas.drawLine(p1, p2, Paint()
        ..strokeWidth = math.max(0.5, r * (isMajor ? 0.018 : 0.010))
        ..color = pal.edge.withValues(alpha: (isMajor ? 0.90 : 0.55) * alpha)
        ..strokeCap = StrokeCap.butt);
    }

    // 八角形の各頂点にリベット（金のドット）
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 - math.pi / 2 + math.pi / 8;
      final px = math.cos(a) * r * 0.92;
      final py = math.sin(a) * r * 0.92;
      canvas.drawCircle(Offset(px, py), r * 0.028, Paint()
        ..color = pal.edgeHl.withValues(alpha: 0.95 * alpha));
    }

    // 背景の八芒星（薄く、金で）
    final starPath = Path();
    for (var i = 0; i < 16; i++) {
      final a = (i / 16) * math.pi * 2 - math.pi / 2;
      final rr = i.isEven ? r * 0.52 : r * 0.22;
      final px = math.cos(a) * rr;
      final py = math.sin(a) * rr;
      if (i == 0) {
        starPath.moveTo(px, py);
      } else {
        starPath.lineTo(px, py);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.5, r * 0.014)
      ..color = pal.edge.withValues(alpha: 0.50 * alpha)
      ..strokeJoin = StrokeJoin.miter);

    // 中央の記号（serif）— 金で強く、黒い影で彫り
    final emblemSize = r * 0.70;
    // 影（少し下にずらして彫刻の深さ）
    final darkPaint = Paint()
      ..color = pal.deepShadow.withValues(alpha: 0.85 * alpha);
    final tpDark = TextPainter(
      text: TextSpan(
        text: emblem,
        style: TextStyle(
          fontSize: emblemSize,
          foreground: darkPaint,
          height: 1.0,
          fontFamily: 'serif',
          fontFamilyFallback: const ['Noto Serif', 'Times New Roman', 'DejaVu Serif'],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tpDark.layout();
    tpDark.paint(canvas, Offset(-tpDark.width / 2 + r * 0.018, -tpDark.height / 2 + r * 0.028));

    // 本体（金）
    final emblemPaint = Paint()
      ..color = pal.emblem.withValues(alpha: 0.98 * alpha);
    final tp = TextPainter(
      text: TextSpan(
        text: emblem,
        style: TextStyle(
          fontSize: emblemSize,
          foreground: emblemPaint,
          height: 1.0,
          fontFamily: 'serif',
          fontFamilyFallback: const ['Noto Serif', 'Times New Roman', 'DejaVu Serif'],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2 + r * 0.01));

    // 上端の鋭いエッジハイライト（斜め白光）
    canvas.drawLine(
      Offset(-r * 0.45, -r * 0.82),
      Offset(r * 0.20, -r * 0.55),
      Paint()
        ..strokeWidth = math.max(0.5, r * 0.020)
        ..color = Colors.white.withValues(alpha: 0.32 * alpha)
        ..strokeCap = StrokeCap.butt
        ..blendMode = BlendMode.plus,
    );
  }

  // 八角形パス（頂点を上下左右と対角）
  Path _octagonPath(double r) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      // -π/2 から π/4 ずつ8頂点。頂点が上下左右＋対角に並ぶ配置
      final a = -math.pi / 2 + i * math.pi / 4 + math.pi / 8;
      final px = math.cos(a) * r;
      final py = math.sin(a) * r;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    return path;
  }

  // ─── 金粉（奥、常時漂う輝き）──────────────
  void _drawDust(Canvas canvas, _GoldDust d, Size size) {
    final localT = t - d.delay;
    if (localT <= 0) return;
    final lt = (localT / (1.0 - d.delay)).clamp(0.0, 1.0);
    final fadeEnv = stageAlpha(lt, fadeIn: 0.18, hold: 0.60, fadeOut: 0.22);
    if (fadeEnv <= 0) return;

    final dr = math.sin(d.driftPhase + lt * d.driftSpeed * math.pi * 2) * d.driftAmp;
    final dx = math.cos(d.driftAngle) * dr * size.width;
    final dy = math.sin(d.driftAngle) * dr * size.height;
    final pos = Offset(size.width * d.xRatio + dx, size.height * d.yRatio + dy);

    final tw = (math.sin(d.twinklePhase + lt * d.twinkleSpeed * math.pi * 2) + 1) / 2;
    final alpha = fadeEnv * (0.30 + tw * 0.55);
    final color = d.warm ? _antiqueGold : _paleGold;
    final sz = d.size * (0.8 + tw * 0.45);

    canvas.drawCircle(pos, sz * 1.6, Paint()
      ..shader = ui.Gradient.radial(pos, sz * 1.6, [
        color.withValues(alpha: 0.55 * alpha),
        color.withValues(alpha: 0.18 * alpha),
        const Color(0x00000000),
      ], [0.0, 0.5, 1.0])
      ..blendMode = BlendMode.plus);
    canvas.drawCircle(pos, sz * 0.55, Paint()
      ..color = _ivory.withValues(alpha: alpha));
  }

  // ─── スパークル（前面、常時輝き）──────────
  void _drawSparkle(Canvas canvas, _Sparkle sp, Size size) {
    final lt = ((t - sp.delay) / (1.0 - sp.delay)).clamp(0.0, 1.0);
    if (lt <= 0) return;
    final fadeEnv = stageAlpha(lt, fadeIn: 0.18, hold: 0.55, fadeOut: 0.27);
    if (fadeEnv <= 0) return;

    final pos = Offset(size.width * sp.xRatio, size.height * sp.yRatio);
    final tw = (math.sin(sp.twinklePhase + lt * sp.twinkleSpeed * math.pi * 2) + 1) / 2;
    final alpha = fadeEnv * (0.35 + tw * 0.65);
    final color = sp.hue < 0.5 ? _ivory : _paleGold;
    final size2 = sp.size * (0.7 + tw * 0.6);

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.drawCircle(Offset.zero, size2 * 0.7, Paint()
      ..shader = ui.Gradient.radial(Offset.zero, size2 * 0.7, [
        color.withValues(alpha: 0.60 * alpha),
        color.withValues(alpha: 0.20 * alpha),
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
    canvas.drawCircle(Offset.zero, size2 * 0.07, Paint()
      ..color = Colors.white.withValues(alpha: alpha));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WorkPainter old) => old.t != t;
}
