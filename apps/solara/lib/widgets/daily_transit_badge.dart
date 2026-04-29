// ============================================================
// DailyTransitBadge — Map 画面右上の日次トリガー
//
// F1-c (2026-04-29 オーナー設計):
//   - リセット時刻後の初回表示は「光る」演出（unseen=true）
//   - タップ → アニメ → F1-c 全面UI
//   - 閲覧済み（unseen=false）: トップカテゴリのアイコンを静的表示
//   - プロフィール未設定（disabled=true）: 控えめ🌱（操作無効）
//
// アイコンは Phase E8.1 で CategoryIcon (CustomPainter) に置換済み。
// ============================================================
import 'package:flutter/material.dart';

import '../theme/solara_colors.dart';
import 'category_icon.dart';
import 'dominant_fortune_overlay.dart' show DominantFortuneKind;

class DailyTransitBadge extends StatefulWidget {
  /// true = リセット時刻後初回（光る）。false = 閲覧済み（静的）。
  final bool unseen;

  /// 閲覧済み時に表示するアイコンのカテゴリ。null時はデフォルト🌱。
  final DominantFortuneKind? topCategory;

  /// プロフィール未設定時 true。グレーアウト＆クリック無効。
  final bool disabled;

  /// タップハンドラ。disabled=true なら呼ばれない。
  final VoidCallback onTap;

  const DailyTransitBadge({
    super.key,
    required this.unseen,
    required this.topCategory,
    required this.disabled,
    required this.onTap,
  });

  @override
  State<DailyTransitBadge> createState() => _DailyTransitBadgeState();
}

class _DailyTransitBadgeState extends State<DailyTransitBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.disabled ? null : widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final pulse = widget.unseen ? _ctrl.value : 0.0;
          return _buildBadge(pulse);
        },
      ),
    );
  }

  Widget _buildBadge(double pulse) {
    if (widget.disabled) {
      // プロフィール無時: 操作無効＋控えめな🌱
      return _container(
        size: 36,
        fillColor: const Color(0x14C9A84C),
        borderColor: const Color(0x44C9A84C),
        glow: false,
        child: const Center(
          child: Text('🌱', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    final iconKind = widget.topCategory?.toCategoryIcon() ?? CategoryIconKind.all;
    final pulseColor = SolaraColors.solaraGoldLight;
    final iconColor = widget.unseen
        ? Color.lerp(
            SolaraColors.solaraGold,
            SolaraColors.solaraGoldLight,
            pulse,
          )!
        : SolaraColors.solaraGoldLight;

    return _container(
      size: 40,
      fillColor: widget.unseen
          ? Color.lerp(
              const Color(0x33C9A84C),
              const Color(0x66F9D976),
              pulse,
            )!
          : const Color(0x26C9A84C),
      borderColor: widget.unseen
          ? Color.lerp(
              const Color(0x88C9A84C),
              const Color(0xFFF9D976),
              pulse,
            )!
          : const Color(0x77C9A84C),
      glow: widget.unseen,
      glowOpacity: 0.35 + 0.45 * pulse,
      glowColor: pulseColor,
      child: Center(
        child: CategoryIcon(
          kind: iconKind,
          size: 22,
          color: iconColor,
          strokeWidth: 1.5,
        ),
      ),
    );
  }

  Widget _container({
    required double size,
    required Color fillColor,
    required Color borderColor,
    required bool glow,
    double glowOpacity = 0,
    Color? glowColor,
    required Widget child,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fillColor,
        border: Border.all(color: borderColor, width: 1.4),
        boxShadow: glow && glowColor != null
            ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: glowOpacity),
                  blurRadius: 14 + 8 * glowOpacity,
                  spreadRadius: 2 * glowOpacity,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

}
