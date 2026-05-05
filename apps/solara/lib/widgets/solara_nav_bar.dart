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
///
/// 2026-04-29: Android systemNav (3ボタン △〇□ / ジェスチャーバー) 対応。
/// `MediaQuery.viewPaddingOf(context).bottom` 分だけ高さを動的に拡張し、
/// アイコンは上 80px に固定して背景 gradient のみ systemNav 領域まで延ばす。
/// これによりジェスチャーナビでも 3ボタンナビでも見た目が綺麗に揃う。
class SolaraNavBar extends StatelessWidget {
  /// 視覚上の固定高さ (アイコン行が収まる本来の高さ)。
  /// systemNav 領域はこれに加算される。
  static const double baseHeight = 80;

  final int currentIndex;
  final ValueChanged<int> onTap;

  const SolaraNavBar({super.key, required this.currentIndex, required this.onTap});

  /// systemNav 込みの NavBar 全体の高さ。
  /// Map画面など bottom 配置で「NavBar の上」を計算するときに使う。
  static double totalHeight(BuildContext context) =>
      baseHeight + systemNavInset(context);

  /// 3ボタンナビ (△〇□) 検出用の閾値。
  /// ジェスチャーナビ (Pixel 8 等) は 16〜24px、3ボタンナビは ~48px。
  /// 閾値以下は「ジェスチャーバーが NavBar 下端の空白に収まる」とみなして拡張しない。
  static const double _threeButtonNavThreshold = 30;

  /// 3ボタンナビ時のみ加算する追加高さ。ジェスチャーナビ時は 0。
  /// オーナー指定 (2026-04-29): 3ボタン時も systemNav 高 - 12px で詰める
  /// (NavBar が大き過ぎないよう僅かに短縮)。
  static const double _threeButtonShrink = 12;
  static double systemNavInset(BuildContext context) {
    final v = MediaQuery.viewPaddingOf(context).bottom;
    if (v <= _threeButtonNavThreshold) return 0;
    final adjusted = v - _threeButtonShrink;
    return adjusted < 0 ? 0 : adjusted;
  }

  static const _gold = Color(0xFFF9D976);
  static const _inactiveColor = Color(0x59FFFFFF); // rgba(255,255,255,0.35)

  static const _labels = ['Map', 'Horo', 'Tarot', 'Galaxy', 'Sanctuary'];

  @override
  Widget build(BuildContext context) {
    final inset = systemNavInset(context);
    // 2026-05-03: BackdropFilter 撤去 (Adreno saveLayer leak の Critical)。
    // gradient は alpha 高めに変更し、後ろの地図がうっすら透ける程度を維持。
    return Container(
      height: baseHeight + inset,
      padding: EdgeInsets.only(top: 10, left: 4, right: 4, bottom: inset),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xF2060A12), Color(0xFF04060E)],
        ),
        border: const Border(top: BorderSide(color: Color(0x0FF9D976), width: 1)),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 30, offset: Offset(0, -4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(5, (i) => _buildItem(i)),
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
