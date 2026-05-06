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
//
// ── 発光手法の変遷 ──
// 旧: BoxShadow(blurRadius: 18) + AnimationController.repeat() で breathing。
//     → Skia OpenGL backend で saveLayer + Gaussian blur が idle 中も毎 frame
//       走り、Map idle 中の raster thread を 100% 占有 (実機 SO-41B / Pixel8)。
//     → Impeller 有効化でも本質改善せず (97% / fps 52→10)。A101FC fd leak 互換性
//       のため Impeller は永久 off に決定。
//
// 現: RadialGradient で halo を「焼き込み」、saveLayer ゼロ・idle frame 誘発ゼロ。
//   - 内側 40px = solid fill + 鋭利 border + icon (従来通り)
//   - 外側 (Stack overlay, clipBehavior: Clip.none で layout 外へ展開) に
//     76px の DecoratedBox + RadialGradient で diffuse な金 halo を静的描画
//   - Stack の親 Positioned (right:20, top:topPad+6) は据え置き
//
// 根拠: Flutter docs の perf guide が saveLayer を最も高コストな操作と明記。
//       gradient fill は単一 paint pass で saveLayer 不要。
//       (refs: docs.flutter.dev/perf/ui-performance, Issue #131206 / #184390)
// ============================================================
import 'package:flutter/material.dart';

import '../theme/solara_colors.dart';
import 'category_icon.dart';
import 'dominant_fortune_overlay.dart' show DominantFortuneKind;

class DailyTransitBadge extends StatelessWidget {
  /// true = リセット時刻後初回（最大輝度固定）。false = 閲覧済み（控えめ）。
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

  // ── 発光 (halo) パラメータ ──
  // 内側 badge: 40px、外側 halo: 76px (旧 BoxShadow blurRadius=18 と同じ広がり)。
  static const double _innerSize = 40;
  static const double _haloSize = 76;
  static const double _haloOffset = (_haloSize - _innerSize) / 2; // = 18

  @override
  Widget build(BuildContext context) {
    final showHalo = unseen && !disabled;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        // 親 Positioned に対しては従来通り 40x40 を主張する。
        // halo は Stack(clipBehavior: Clip.none) で layout の外側に描画される。
        width: _innerSize,
        height: _innerSize,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (showHalo)
              Positioned(
                left: -_haloOffset,
                right: -_haloOffset,
                top: -_haloOffset,
                bottom: -_haloOffset,
                child: const IgnorePointer(child: _BadgeHalo()),
              ),
            _buildBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge() {
    if (disabled) {
      // プロフィール無時: 操作無効＋控えめな🌱
      return _container(
        size: 36,
        fillColor: const Color(0x14C9A84C),
        borderColor: const Color(0x44C9A84C),
        child: const Center(
          child: Text('🌱', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    final iconKind = topCategory?.toCategoryIcon() ?? CategoryIconKind.all;
    const iconColor = SolaraColors.solaraGoldLight;

    // Light map 上では金色が薄れて視認性低下。
    // 内側を暗紺で塗り、border と icon は金で強調 (反転コントラスト)。
    // unseen=true は最大輝度固定。
    final fillColor = unseen
        ? (isLightMap
            ? const Color(0xFF1A1A38)   // 暗紺 (light map)
            : const Color(0x88F9D976))  // gold 半透明 (dark map)
        : (isLightMap
            ? const Color(0xCC0A0A1E)
            : const Color(0x26C9A84C));
    final borderColor = unseen
        ? const Color(0xFFFFE99A)       // 明るい金
        : (isLightMap
            ? const Color(0xFFC9A84C)
            : const Color(0x77C9A84C));

    return _container(
      size: _innerSize,
      fillColor: fillColor,
      borderColor: borderColor,
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
    required Widget child,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fillColor,
        border: Border.all(color: borderColor, width: 1.4),
      ),
      child: child,
    );
  }
}

/// unseen=true の時に badge の周囲に描画される金色 halo。
///
/// `BoxShadow + blurRadius` は Skia で saveLayer + Gaussian blur を idle 中も
/// 毎 frame 走らせ、raster thread を 100% 占有する。
/// 代わりに `RadialGradient` を fill に焼き込むことで saveLayer ゼロ、
/// 静止 frame で raster コストもゼロにする (= Phase 3c 方針との完全整合)。
///
/// gradient stops の意図:
///   - 0.50 (= inner badge edge 20px / halo radius 38px ≒ 0.526) で alpha 0
///     → badge 輪郭に被らないよう halo の内側は完全透明
///   - 0.58 で peak (alpha 0.55) → badge 縁の直外で最も明るく光る
///   - 0.78 で alpha 0.18 → 中間の柔らかい減衰
///   - 1.00 で alpha 0 → 外周は背景に溶け込む
class _BadgeHalo extends StatelessWidget {
  const _BadgeHalo();

  @override
  Widget build(BuildContext context) {
    const glow = SolaraColors.solaraGoldLight;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          radius: 0.5,
          colors: [
            glow.withValues(alpha: 0.0),
            glow.withValues(alpha: 0.55),
            glow.withValues(alpha: 0.18),
            glow.withValues(alpha: 0.0),
          ],
          stops: const [0.50, 0.58, 0.78, 1.00],
        ),
      ),
    );
  }
}
