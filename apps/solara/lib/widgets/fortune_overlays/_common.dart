import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 各演出の共通ビルダー。1度生成した粒子を使い回す。
abstract class FortunePainterBuilder {
  CustomPainter buildPainter(double t);
}

/// イージング: 減速
double easeOutCubic(double x) {
  final v = 1 - x;
  return 1 - v * v * v;
}

/// イージング: バウンドつき出現
double easeOutBack(double x) {
  const c1 = 1.70158;
  const c3 = c1 + 1;
  final v = x - 1;
  return 1 + c3 * v * v * v + c1 * v * v;
}

/// イージング: 急加速
double easeInCubic(double x) => x * x * x;

/// イージング: 二次イーズインアウト
double easeInOutQuad(double x) {
  if (x < 0.5) return 2 * x * x;
  return 1 - math.pow(-2 * x + 2, 2).toDouble() / 2;
}

/// 3段階αカーブ: fadeIn / hold / fadeOut
double stageAlpha(double x, {
  required double fadeIn,
  required double hold,
  required double fadeOut,
}) {
  if (x <= 0 || x >= 1) return 0;
  if (x < fadeIn) return x / fadeIn;
  if (x < fadeIn + hold) return 1.0;
  final f = (x - fadeIn - hold) / fadeOut;
  return (1.0 - f).clamp(0.0, 1.0);
}
