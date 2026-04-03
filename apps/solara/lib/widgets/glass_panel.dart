import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/solara_colors.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double blurRadius;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const GlassPanel({
    super.key,
    required this.child,
    this.blurRadius = 16.0,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
        child: Container(
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: SolaraColors.glassFill,
            borderRadius: radius,
            border: Border.all(color: SolaraColors.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}
