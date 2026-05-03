import 'package:flutter/material.dart';
import '../theme/solara_colors.dart';

/// 2026-05-03: BackdropFilter 撤去 (Adreno saveLayer leak)。blur なしの半透明
/// 暗色パネルにし、popup 越しに後ろがうっすら見える程度に統一 (スコアバー方式)。
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xE60A0A14),
        borderRadius: radius,
        border: Border.all(color: SolaraColors.glassBorder),
      ),
      child: child,
    );
  }
}
