import 'package:flutter/material.dart';

import '../../theme/solara_colors.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/dominant_fortune_overlay.dart' show DominantFortuneKind;

/// 下部チップバー (NavBar 直上、4 個)。
///
/// 2026-05-09 第二弾再設計:
///   旧 4 チップ (⚙️/✨/📍/📈) → 新 4 チップ (Daily Transit / 運勢方位 / LOCATIONS / 予報)
///   利用頻度トップ 3 (Daily Transit / 運勢方位 / LOCATIONS) を主役チップに昇格。
///   表示・占星 (低頻度) は左サイド ☰ 表示メニューに移動。
///   右上 DailyTransitBadge は廃止し、未閲覧時のグロー演出はこのチップで実施。
class MapMenuChips extends StatelessWidget {
  /// Daily Transit チップ: 未閲覧 (リセット時刻後初回) で halo 発光
  final bool dailyTransitUnseen;
  final bool dailyTransitDisabled; // プロフィール未設定時 true
  final DominantFortuneKind? topCategory;
  final VoidCallback onDailyTransitTap;

  /// 運勢方位 (FortuneSheet 起動)
  final VoidCallback onFortuneTap;

  /// LOCATIONS (LocationsScreen 起動)
  final VoidCallback onLocationsTap;

  /// 予報 (ForecastScreen 起動)
  final VoidCallback onForecastTap;

  const MapMenuChips({
    super.key,
    required this.dailyTransitUnseen,
    required this.dailyTransitDisabled,
    required this.topCategory,
    required this.onDailyTransitTap,
    required this.onFortuneTap,
    required this.onLocationsTap,
    required this.onForecastTap,
  });

  @override
  Widget build(BuildContext context) {
    // 等間隔のための padding 設計 (2026-05-09):
    //   外側 horizontal = 4, 各チップ horizontal = 4 で
    //   edge gap = 4 + 4 = 8、chip 間 gap = 4 + 4 = 8 と一致させる。
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xCC0A0A19),
            Color(0xE60A0A19),
          ],
        ),
        border: Border(
          top: BorderSide(color: Color(0x33C9A84C)),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            _DailyTransitChip(
              unseen: dailyTransitUnseen,
              disabled: dailyTransitDisabled,
              topCategory: topCategory,
              onTap: onDailyTransitTap,
            ),
            _StaticChip(
              icon: '🧭',
              label: '運勢方位',
              onTap: onFortuneTap,
            ),
            _StaticChip(
              icon: '📍',
              label: 'LOCATIONS',
              onTap: onLocationsTap,
            ),
            _StaticChip(
              icon: '📈',
              label: '予報',
              onTap: onForecastTap,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 通常チップ (Daily Transit 以外) ────────────────────────────────
class _StaticChip extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  const _StaticChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x33C9A84C)),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x22C9A84C),
                  Color(0x0AC9A84C),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFC9A84C),
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Daily Transit 専用チップ (unseen halo + topCategory アイコン) ──
//
// 旧 DailyTransitBadge (右上、円形 40px) からの移植版。形状を chip 矩形に合わせ、
// halo は背景に焼き込む RadialGradient で saveLayer ゼロ・idle frame 誘発ゼロ。
class _DailyTransitChip extends StatelessWidget {
  final bool unseen;
  final bool disabled;
  final DominantFortuneKind? topCategory;
  final VoidCallback onTap;
  const _DailyTransitChip({
    required this.unseen,
    required this.disabled,
    required this.topCategory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showHalo = unseen && !disabled;
    final iconKind = topCategory?.toCategoryIcon() ?? CategoryIconKind.all;

    // unseen = 最大輝度固定 (border + fill とも明るい金)、
    // 閲覧済み = 通常チップと同等の控えめ色。
    final fillGradient = unseen
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x66F9D976), Color(0x22F9D976)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x22C9A84C), Color(0x0AC9A84C)],
          );
    final borderColor = unseen
        ? const Color(0xFFFFE99A)
        : const Color(0x33C9A84C);
    final iconColor = unseen
        ? SolaraColors.solaraGoldLight
        : const Color(0xFFC9A84C);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: disabled ? null : onTap,
          child: Stack(
            clipBehavior: Clip.none,
            // StackFit.expand は使わない。親 Positioned(bottom:0) は高さが
            // unbounded なので expand させると h=Infinity 強制で assert 失敗
            // (RenderBox 'BoxConstraints forces an infinite height') する。
            // 代わりに Container 自身に width: double.infinity を与えて、
            // 高さは child intrinsic 任せにする (Static チップと同じ挙動)。
            children: [
              // 未閲覧時の halo (chip 矩形の外側に拡張、IgnorePointer)
              if (showHalo)
                const Positioned(
                  left: -8,
                  right: -8,
                  top: -8,
                  bottom: -8,
                  child: IgnorePointer(child: _ChipHalo()),
                ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: unseen ? 1.4 : 1),
                  gradient: fillGradient,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (disabled)
                      const Text('🌱', style: TextStyle(fontSize: 18))
                    else
                      CategoryIcon(
                        kind: iconKind,
                        size: 18,
                        color: iconColor,
                        strokeWidth: 1.5,
                      ),
                    const SizedBox(height: 2),
                    Text(
                      'Daily',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: unseen
                            ? const Color(0xFFFFE99A)
                            : const Color(0xFFC9A84C),
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// チップの周囲に静的に描画する halo。RadialGradient で焼き込み (saveLayer 不要)。
class _ChipHalo extends StatelessWidget {
  const _ChipHalo();

  @override
  Widget build(BuildContext context) {
    const glow = SolaraColors.solaraGoldLight;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: RadialGradient(
          radius: 0.7,
          colors: [
            glow.withValues(alpha: 0.45),
            glow.withValues(alpha: 0.18),
            glow.withValues(alpha: 0.0),
          ],
          stops: const [0.30, 0.60, 1.00],
        ),
      ),
    );
  }
}
