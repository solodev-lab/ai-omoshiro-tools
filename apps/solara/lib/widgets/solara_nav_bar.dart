import 'dart:ui';
import 'package:flutter/material.dart';
import 'nav_icons.dart';

/// Custom bottom navigation bar matching HTML shared/styles.css exactly.
///
/// HTML spec:
/// - height: 80px (--nav-height)
/// - background: linear-gradient(180deg, rgba(6,10,18,0.80), rgba(4,6,14,0.95))
/// - backdrop-filter: blur(28px)
/// - border-top: 1px solid rgba(249,217,118,0.06)
/// - box-shadow: 0 -4px 30px rgba(0,0,0,0.4), inset 0 1px 0 rgba(255,255,255,0.04)
/// - padding: 10px 4px 0
///
/// Nav item:
/// - icon: 24x24, inactive rgba(255,255,255,0.35), active #F9D976 with glow
/// - label: 9px, uppercase, letter-spacing 0.5px
/// - active glow dot: 4x4px #F9D976 with box-shadow
class SolaraNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const SolaraNavBar({super.key, required this.currentIndex, required this.onTap});

  static const _gold = Color(0xFFF9D976);
  static const _inactiveColor = Color(0x59FFFFFF); // rgba(255,255,255,0.35)

  static const _labels = ['Map', 'Horo', 'Tarot', 'Galaxy', 'Sanctuary'];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14), // blur(28px) → sigma ≈ 14
        child: Container(
          height: 80, // --nav-height
          padding: const EdgeInsets.only(top: 10, left: 4, right: 4),
          decoration: BoxDecoration(
            // linear-gradient(180deg, rgba(6,10,18,0.80), rgba(4,6,14,0.95))
            gradient: const LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xCC060A12), Color(0xF204060E)],
            ),
            // border-top: 1px solid rgba(249,217,118,0.06)
            border: const Border(top: BorderSide(color: Color(0x0FF9D976), width: 1)),
            // box-shadow: 0 -4px 30px rgba(0,0,0,0.4)
            boxShadow: const [
              BoxShadow(color: Color(0x66000000), blurRadius: 30, offset: Offset(0, -4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(5, (i) => _buildItem(i)),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int index) {
    final active = index == currentIndex;
    final color = active ? _gold : _inactiveColor;
    final iconWidget = _iconForIndex(index, color);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            // Icon with glow for active
            if (active)
              Container(
                decoration: BoxDecoration(
                  // filter: drop-shadow(0 0 8px gold) drop-shadow(0 0 16px rgba(249,217,118,0.3))
                  boxShadow: [
                    BoxShadow(color: _gold.withAlpha(180), blurRadius: 8),
                    BoxShadow(color: _gold.withAlpha(77), blurRadius: 16),
                  ],
                ),
                child: iconWidget,
              )
            else
              iconWidget,
            const SizedBox(height: 4),
            // Label: 9px, uppercase, letter-spacing 0.5
            Text(
              _labels[index],
              style: TextStyle(
                fontSize: 9, color: color, letterSpacing: 0.5,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            // Active glow dot
            if (active)
              Container(
                width: 4, height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _gold,
                  boxShadow: [
                    BoxShadow(color: _gold.withAlpha(128), blurRadius: 8, spreadRadius: 2),
                    BoxShadow(color: _gold.withAlpha(38), blurRadius: 20, spreadRadius: 4),
                  ],
                ),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _iconForIndex(int index, Color color) {
    switch (index) {
      case 0: return SolaraNavIcons.map(size: 24, color: color);
      case 1: return SolaraNavIcons.horo(size: 24, color: color);
      case 2: return SolaraNavIcons.tarot(size: 24, color: color);
      case 3: return SolaraNavIcons.galaxy(size: 24, color: color);
      case 4: return SolaraNavIcons.sanctuary(size: 24, color: color);
      default: return const SizedBox();
    }
  }
}
