import 'package:flutter/material.dart';
import 'fortune_overlays/_common.dart';
import 'fortune_overlays/communication_painter.dart';
import 'fortune_overlays/healing_painter.dart';
import 'fortune_overlays/love_painter.dart';
import 'fortune_overlays/money_painter.dart';
import 'fortune_overlays/work_painter.dart';

/// 今日の最高スコアカテゴリに応じた全画面演出。
/// 1日の最初のタップで約2秒間表示する。
enum DominantFortuneKind { healing, money, love, work, communication }

DominantFortuneKind? kindFromKey(String key) {
  switch (key) {
    case 'healing':       return DominantFortuneKind.healing;
    case 'money':         return DominantFortuneKind.money;
    case 'love':          return DominantFortuneKind.love;
    case 'work':          return DominantFortuneKind.work;
    case 'communication': return DominantFortuneKind.communication;
  }
  return null;
}

class DominantFortuneOverlay extends StatefulWidget {
  final DominantFortuneKind kind;
  final VoidCallback onComplete;

  const DominantFortuneOverlay({
    super.key,
    required this.kind,
    required this.onComplete,
  });

  @override
  State<DominantFortuneOverlay> createState() => _DominantFortuneOverlayState();
}

class _DominantFortuneOverlayState extends State<DominantFortuneOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final FortunePainterBuilder _builder;

  static const _duration = Duration(milliseconds: 2400);

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onComplete();
      });
    _builder = _createBuilder(widget.kind);
    _ctl.forward();
  }

  FortunePainterBuilder _createBuilder(DominantFortuneKind kind) {
    switch (kind) {
      case DominantFortuneKind.love:          return LovePainterBuilder();
      case DominantFortuneKind.money:         return MoneyPainterBuilder();
      case DominantFortuneKind.healing:       return HealingPainterBuilder();
      case DominantFortuneKind.communication: return CommunicationPainterBuilder();
      case DominantFortuneKind.work:          return WorkPainterBuilder();
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: AnimatedBuilder(
        animation: _ctl,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _builder.buildPainter(_ctl.value),
        ),
      ),
    );
  }
}
