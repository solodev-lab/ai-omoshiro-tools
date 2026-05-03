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

  /// Map style が Light のとき true。
  /// Light モードの白背景上で目立たせるためコントラストを強める。
  final bool isLightMap;

  const DailyTransitBadge({
    super.key,
    required this.unseen,
    required this.topCategory,
    required this.disabled,
    required this.onTap,
    this.isLightMap = false,
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
    // 周期を短めにして明暗の動きを強調 (旧 2400ms → 1800ms)。
    // ユーザー指摘「ずっと暗いと暗いイメージ」対策で目立たせる。
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
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

    // Light map 上では金色が薄れて視認性低下。
    // 内側を暗紺で塗り、border と icon は金で強調 (反転コントラスト)。
    final lightFillBase = widget.isLightMap
        ? const Color(0xCC0A0A1E)   // ほぼ不透明な深紺
        : const Color(0x11C9A84C);  // 半透明 gold (旧)
    final lightFillBright = widget.isLightMap
        ? const Color(0xFF1A1A38)   // 暗紺 + わずかに明るく
        : const Color(0x88F9D976);
    final lightBorderBase = widget.isLightMap
        ? const Color(0xCCC9A84C)
        : const Color(0x44C9A84C);
    final lightBorderBright = widget.isLightMap
        ? const Color(0xFFFFE99A)
        : const Color(0xFFFFE99A);

    return _container(
      size: 40,
      // ユーザー指摘「暗いから明るいに変わる、明暗はっきり」対応:
      // 旧: alpha 振れ幅 約2倍 (51→102, 136→255, 0.35→0.80) — 控えめ
      // 新: alpha 振れ幅 約4倍 (17→136, 68→255, 0.10→0.95) — はっきり明暗
      fillColor: widget.unseen
          ? Color.lerp(lightFillBase, lightFillBright, pulse)!
          : (widget.isLightMap
              ? const Color(0xCC0A0A1E)
              : const Color(0x26C9A84C)),
      borderColor: widget.unseen
          ? Color.lerp(lightBorderBase, lightBorderBright, pulse)!
          : (widget.isLightMap
              ? const Color(0xFFC9A84C)
              : const Color(0x77C9A84C)),
      glow: widget.unseen,
      // Light map では glow も濃いめ (alpha 0.30→1.00)。
      glowOpacity: widget.isLightMap
          ? 0.30 + 0.70 * pulse
          : 0.10 + 0.85 * pulse,
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
                // 2026-05-03: blurRadius/spreadRadius を固定化 (Critical fix)。
                // glow の breathing は color alpha のみで表現 = saveLayer 回避。
                BoxShadow(
                  color: glowColor.withValues(alpha: glowOpacity),
                  blurRadius: 18,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

}
