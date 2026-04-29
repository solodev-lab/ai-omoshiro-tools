// ============================================================
// CategoryIcon — Solara カテゴリアイコン (Phase E8.1)
//
// Style D (2026-04-29 オーナー確定):
//   惑星シンボル中心 + カテゴリ別装飾線
//
// 6カテゴリ:
//   - all          : ✦ 4点星（汎用 / トップ未確定時）
//   - love (恋愛)   : ♀ Venus + 抱擁の弧
//   - money (豊かさ): ♃ Jupiter + 拡大の放射線
//   - work (仕事)   : ♄ Saturn + 構造の基線
//   - healing (癒し): ☽ Moon + 月相のトレイル
//   - communication : ☿ Mercury + 翼の弧
//
// ベクター描画（Path）で全サイズ対応。
// 利用箇所: DailyTransitBadge / MapDailyTransitScreen / LayerPanel 等。
// ============================================================
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/solara_colors.dart';
import 'dominant_fortune_overlay.dart' show DominantFortuneKind;

enum CategoryIconKind { all, love, money, work, healing, communication }

extension DominantFortuneKindToCategoryIcon on DominantFortuneKind {
  CategoryIconKind toCategoryIcon() {
    switch (this) {
      case DominantFortuneKind.love:          return CategoryIconKind.love;
      case DominantFortuneKind.money:         return CategoryIconKind.money;
      case DominantFortuneKind.work:          return CategoryIconKind.work;
      case DominantFortuneKind.healing:       return CategoryIconKind.healing;
      case DominantFortuneKind.communication: return CategoryIconKind.communication;
    }
  }
}

/// カテゴリ別ベクターアイコン。
///
/// [size] は描画領域の一辺ピクセル。symbol path は 100×100 仮想座標で
/// 設計してあるため、size 値をそのまま渡せばよい。
/// [color] 省略時は SolaraColors.solaraGoldLight。
class CategoryIcon extends StatelessWidget {
  final CategoryIconKind kind;
  final double size;
  final Color? color;
  final double strokeWidth;

  const CategoryIcon({
    super.key,
    required this.kind,
    this.size = 24,
    this.color,
    this.strokeWidth = 1.6,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CategoryIconPainter(
          kind: kind,
          color: color ?? SolaraColors.solaraGoldLight,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _CategoryIconPainter extends CustomPainter {
  final CategoryIconKind kind;
  final Color color;
  final double strokeWidth;

  _CategoryIconPainter({
    required this.kind,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final scale = s / 100; // 仮想座標 100x100 → 実サイズ
    canvas.save();
    canvas.scale(scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final decorPaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (strokeWidth * 0.7) / scale
      ..strokeCap = StrokeCap.round;

    switch (kind) {
      case CategoryIconKind.all:
        _drawAll(canvas, paint, fillPaint, decorPaint);
        break;
      case CategoryIconKind.love:
        _drawLove(canvas, paint, decorPaint);
        break;
      case CategoryIconKind.money:
        _drawMoney(canvas, paint, decorPaint);
        break;
      case CategoryIconKind.work:
        _drawWork(canvas, paint, decorPaint);
        break;
      case CategoryIconKind.healing:
        _drawHealing(canvas, paint, decorPaint);
        break;
      case CategoryIconKind.communication:
        _drawCommunication(canvas, paint, decorPaint);
        break;
    }

    canvas.restore();
  }

  // ── all: ✦ 4点星 + 周囲の小光点 ──
  void _drawAll(Canvas c, Paint stroke, Paint fill, Paint decor) {
    // 中央: 4点星（縦長の菱形 + 横長の菱形を重ねる）
    final star = Path()
      ..moveTo(50, 18)
      ..quadraticBezierTo(50, 50, 18, 50)
      ..quadraticBezierTo(50, 50, 50, 82)
      ..quadraticBezierTo(50, 50, 82, 50)
      ..quadraticBezierTo(50, 50, 50, 18)
      ..close();
    c.drawPath(star, fill);

    // 装飾: 4方向に小ドット
    for (int i = 0; i < 4; i++) {
      final a = math.pi / 4 + i * math.pi / 2;
      final dx = 50 + 38 * math.cos(a);
      final dy = 50 + 38 * math.sin(a);
      c.drawCircle(Offset(dx, dy), 1.6, fill);
    }
  }

  // ── love: ♀ Venus + 抱擁の弧 ──
  void _drawLove(Canvas c, Paint stroke, Paint decor) {
    // Venus シンボル: 円 + 下の十字
    c.drawCircle(const Offset(50, 38), 14, stroke);
    final line = Path()
      ..moveTo(50, 52)
      ..lineTo(50, 78)
      ..moveTo(40, 68)
      ..lineTo(60, 68);
    c.drawPath(line, stroke);

    // 装飾: 左右の弧（包み込み）
    final leftArc = Path()
      ..addArc(
        const Rect.fromLTWH(15, 25, 30, 30),
        math.pi * 0.3,
        math.pi * 1.0,
      );
    final rightArc = Path()
      ..addArc(
        const Rect.fromLTWH(55, 25, 30, 30),
        math.pi * 1.7,
        math.pi * 1.0,
      );
    c.drawPath(leftArc, decor);
    c.drawPath(rightArc, decor);
  }

  // ── money (豊かさ): ♃ Jupiter + 拡大の放射線 ──
  void _drawMoney(Canvas c, Paint stroke, Paint decor) {
    // Jupiter シンボル: 横線 + 下に伸びる縦線 + 上の曲線
    final sym = Path()
      // 上の曲線（4の左肩部分）
      ..moveTo(36, 42)
      ..quadraticBezierTo(36, 22, 56, 22)
      ..quadraticBezierTo(70, 22, 70, 38)
      // 縦線で下に
      ..moveTo(56, 22)
      ..lineTo(56, 78)
      // 横線（クロスバー）
      ..moveTo(42, 60)
      ..lineTo(78, 60);
    c.drawPath(sym, stroke);

    // 装飾: 4隅から外に向かう短い線（拡大）
    for (int i = 0; i < 4; i++) {
      final a = math.pi / 4 + i * math.pi / 2;
      final x1 = 50 + 40 * math.cos(a);
      final y1 = 50 + 40 * math.sin(a);
      final x2 = 50 + 48 * math.cos(a);
      final y2 = 50 + 48 * math.sin(a);
      c.drawLine(Offset(x1, y1), Offset(x2, y2), decor);
    }
  }

  // ── work: ♄ Saturn + 安定の基線 ──
  void _drawWork(Canvas c, Paint stroke, Paint decor) {
    // Saturn: 縦線 + 右下のカーブ + 上の十字
    final sym = Path()
      // 縦線
      ..moveTo(45, 22)
      ..lineTo(45, 70)
      // 右下のカーブ
      ..quadraticBezierTo(45, 80, 60, 78)
      ..quadraticBezierTo(70, 76, 70, 64)
      // 上の十字（横）
      ..moveTo(33, 32)
      ..lineTo(57, 32);
    c.drawPath(sym, stroke);

    // 装飾: 下部の安定基線（2本）
    c.drawLine(const Offset(20, 88), const Offset(80, 88), decor);
    c.drawLine(const Offset(28, 92), const Offset(72, 92), decor);
  }

  // ── healing: ☽ Moon + 月相のトレイル ──
  void _drawHealing(Canvas c, Paint stroke, Paint decor) {
    // 中央: 三日月
    final moon = Path()
      ..addArc(
        const Rect.fromLTWH(28, 25, 50, 50),
        math.pi * 0.3,
        math.pi * 1.4,
      )
      ..addArc(
        const Rect.fromLTWH(40, 25, 50, 50),
        math.pi * 1.7,
        -math.pi * 1.4,
      );
    c.drawPath(moon, stroke);

    // 装飾: 周囲に3つの小三日月（月相）
    for (int i = 0; i < 3; i++) {
      final a = math.pi * 0.7 + i * math.pi * 0.25;
      final cx = 50 + 36 * math.cos(a);
      final cy = 50 + 36 * math.sin(a);
      c.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: 4),
        math.pi * 0.3,
        math.pi * 1.4,
        false,
        decor,
      );
    }
  }

  // ── communication: ☿ Mercury + 翼の弧 ──
  void _drawCommunication(Canvas c, Paint stroke, Paint decor) {
    // Mercury: 上の半円（角）+ 中央の円 + 下の十字
    final sym = Path()
      // 上の角
      ..addArc(
        const Rect.fromLTWH(38, 12, 24, 16),
        math.pi,
        math.pi,
      );
    c.drawPath(sym, stroke);
    // 中央の円
    c.drawCircle(const Offset(50, 42), 11, stroke);
    // 下の十字
    final cross = Path()
      ..moveTo(50, 53)
      ..lineTo(50, 80)
      ..moveTo(42, 70)
      ..lineTo(58, 70);
    c.drawPath(cross, stroke);

    // 装飾: 左右の翼（外向きの弧）
    final leftWing = Path()
      ..moveTo(20, 38)
      ..quadraticBezierTo(8, 50, 20, 62);
    final rightWing = Path()
      ..moveTo(80, 38)
      ..quadraticBezierTo(92, 50, 80, 62);
    c.drawPath(leftWing, decor);
    c.drawPath(rightWing, decor);
  }

  @override
  bool shouldRepaint(covariant _CategoryIconPainter old) =>
      old.kind != kind || old.color != color || old.strokeWidth != strokeWidth;
}
