import 'package:flutter/material.dart';

import '../../theme/solara_colors.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/dominant_fortune_overlay.dart' show DominantFortuneKind;

/// 下部チップバー (NavBar 直上、4 個: Daily / Fortune / Locations / Forecast)。
///
/// 利用頻度トップ 3 (Daily Transit / 運勢方位 / LOCATIONS) を主役チップに昇格、
/// 表示・占星 (低頻度) は左サイド ☰ 表示メニューに移動。
/// 未閲覧時のグロー演出は Daily チップ自身に halo として焼き込む。
class MapMenuChips extends StatelessWidget {
  /// Daily Transit チップ: 未閲覧 (リセット時刻後初回) で halo 発光
  final bool dailyTransitUnseen;
  final bool dailyTransitDisabled; // プロフィール未設定時 true
  final DominantFortuneKind? topCategory;
  final VoidCallback onDailyTransitTap;
  final VoidCallback onFortuneTap;
  final VoidCallback onLocationsTap;
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
    // 等間隔のための padding 設計:
    //   外側 horizontal = 4, 各チップ horizontal = 4 で
    //   edge gap = 4 + 4 = 8、chip 間 gap = 4 + 4 = 8 と一致。
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xCC0A0A19), Color(0xE60A0A19)],
        ),
        border: Border(top: BorderSide(color: Color(0x33C9A84C))),
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
            _StaticChip(iconAsset: 'fortune', label: 'Fortune', onTap: onFortuneTap),
            _StaticChip(iconAsset: 'location', label: 'Locations', onTap: onLocationsTap),
            _StaticChip(iconAsset: 'forecast', label: 'Forecast', onTap: onForecastTap),
          ],
        ),
      ),
    );
  }
}

// ── 共通寸法・スタイル定数 ─────────────────────────────────────────
//
// Daily / Static の両 chip で完全に同じ Container 寸法を使うことで、
// IntrinsicHeight 不要 + 構造的な OVERFLOW を防ぐ。
// height 60 → child available = 60 − padding 6 − border 2 = 52
// vs Column intrinsic (textScale 1.5): Image 32 + spacing 1 + Text 16.2 = 49.2
// → 余裕 2.8px、textScale 1.0〜1.5 全領域で OVERFLOW なし。
const double _kChipHeight = 60;
const double _kIconSize = 32;
const Color _kDefaultBorderColor = Color(0x33C9A84C);
const Color _kDefaultLabelColor = Color(0xFFC9A84C);
const LinearGradient _kDefaultGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0x22C9A84C), Color(0x0AC9A84C)],
);

/// 全チップ共通の Container 外形 (高さ・border・gradient)。
///
/// Daily 側で unseen 時のみ borderColor / gradient を明るい金に差し替え。
class _ChipBody extends StatelessWidget {
  final Color borderColor;
  final Gradient gradient;
  final Widget child;

  const _ChipBody({
    this.borderColor = _kDefaultBorderColor,
    this.gradient = _kDefaultGradient,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kChipHeight,
      padding: const EdgeInsets.symmetric(vertical: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
        gradient: gradient,
      ),
      child: child,
    );
  }
}

/// 全チップ共通の中身 (アイコン + ラベル縦並び)。
class _ChipColumn extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color labelColor;

  const _ChipColumn({
    required this.icon,
    required this.label,
    this.labelColor = _kDefaultLabelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(height: 1),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 9,
            color: labelColor,
            letterSpacing: 0.3,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Daily 以外の通常チップ (Fortune / Locations / Forecast)。
class _StaticChip extends StatelessWidget {
  /// assets/menu_icons/{iconAsset}.webp として読み込む。
  final String iconAsset;
  final String label;
  final VoidCallback onTap;
  const _StaticChip({required this.iconAsset, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: _ChipBody(
            child: _ChipColumn(
              icon: Image.asset(
                'assets/menu_icons/$iconAsset.webp',
                width: _kIconSize,
                height: _kIconSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
              label: label,
            ),
          ),
        ),
      ),
    );
  }
}

/// Daily Transit 専用チップ。
///
/// アイコン分岐:
///  - disabled (プロフィール未設定): 🌱 emoji
///  - unseen (未開封): unsealed.webp (9芒星アンティーク章) + halo 発光
///  - seen (開封済): topCategory に応じた CategoryIcon
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

  Widget _buildIcon() {
    if (disabled) {
      return const Text('🌱', style: TextStyle(fontSize: _kIconSize));
    }
    if (unseen) {
      return Image.asset(
        'assets/menu_icons/unsealed.webp',
        width: _kIconSize,
        height: _kIconSize,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      );
    }
    return CategoryIcon(
      kind: topCategory?.toCategoryIcon() ?? CategoryIconKind.all,
      size: _kIconSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showHalo = unseen && !disabled;

    Widget content = _ChipColumn(
      icon: _buildIcon(),
      label: 'Daily',
      labelColor: unseen ? const Color(0xFFFFE99A) : _kDefaultLabelColor,
    );

    // halo が必要なときだけ Stack で wrap (通常時は素の Column のみ)。
    // halo は Container の外周まで拡張 (-12) し、Container.clipBehavior は
    // default none なので Stack の clipBehavior: Clip.none で外周描画継続。
    if (showHalo) {
      content = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Positioned(
            left: -12,
            right: -12,
            top: -12,
            bottom: -12,
            child: IgnorePointer(child: _ChipHalo()),
          ),
          content,
        ],
      );
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: disabled ? null : onTap,
          child: _ChipBody(
            borderColor: unseen ? const Color(0xFFFFE99A) : _kDefaultBorderColor,
            gradient: unseen
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x66F9D976), Color(0x22F9D976)],
                  )
                : _kDefaultGradient,
            child: content,
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
