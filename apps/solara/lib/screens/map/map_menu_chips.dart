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
        // IntrinsicHeight + stretch で全チップに有限 tight vertical 制約を渡す。
        // これがないと Daily 側の Stack (全 Positioned.fill 構成) が
        // h=Infinity で assert 失敗する (constraints.biggest が無限になる)。
        // 副作用として Static / Daily の高さも自動で揃う (max intrinsic に統一)。
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DailyTransitChip(
                unseen: dailyTransitUnseen,
                disabled: dailyTransitDisabled,
                topCategory: topCategory,
                onTap: onDailyTransitTap,
              ),
              _StaticChip(
                iconAsset: 'fortune',
                label: 'Fortune',
                onTap: onFortuneTap,
              ),
              _StaticChip(
                iconAsset: 'location',
                label: 'Locations',
                onTap: onLocationsTap,
              ),
              _StaticChip(
                iconAsset: 'forecast',
                label: 'Forecast',
                onTap: onForecastTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 通常チップ (Daily Transit 以外) ────────────────────────────────
// 2026-05-10: emoji (🧭/📍/📈) → アンティーク神秘 WebP に置換
//             (assets/menu_icons/{iconAsset}.webp)。Daily チップと
//             同じ画材で統一感を出す。
class _StaticChip extends StatelessWidget {
  /// assets/menu_icons/{iconAsset}.webp として読み込む。
  /// 例: 'fortune' / 'location' / 'forecast'
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
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(vertical: 3),
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
            // 寸法 (2026-05-10 第六弾 = 最終):
            //   height: 54 で explicit 固定 → Daily/Static 両方完全に 54 で揃う。
            //   child available = 54 − padding 6 − border 2 = 46 vs Column 43.8
            //   → 2.2px 余裕で subpixel OVERFLOW を完全回避。
            //   構成: Image 32 + spacing 1 + Text fontSize 9 (~10.8) = 43.8
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/menu_icons/$iconAsset.webp',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFFC9A84C),
                    letterSpacing: 0.3,
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

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: disabled ? null : onTap,
          // 構造 (2026-05-10 第六弾 = 最終):
          //   Container { decoration, padding, child: Stack {
          //     Positioned (halo, padding+border 含む -12 拡張),  // 背面
          //     Column (non-positioned),  // メインコンテンツ
          //   }}
          //
          // 第四/五弾 (Container を Stack の non-positioned 子に) では Stack
          // の幅が Container intrinsic 幅 (32px) で shrink → Daily チップだけ
          // 横幅が小さくなる副作用が出た。
          //
          // 最終構造: Static chip と外形を完全一致させ (Expanded > Padding >
          // GestureDetector > Container)、Container 内側で Stack を使い
          // halo + Column を配置。Container は parent (Expanded) の幅を
          // 採用 → 4 chips が均等幅。Container の clipBehavior は default
          // none なので halo (Positioned で -12 外側拡張) も問題なく外周描画。
          child: Container(
            height: 54,
            // border width も Static と一致 (1)。unseen 時の存在感は halo +
            // border color (明金) + gradient brightness で表現済。
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1),
              gradient: fillGradient,
            ),
            // 寸法 (Static chip と完全一致):
            //   height: 54 で explicit 固定。child available = 54 − padding 6 − border 2 = 46
            //   vs Column 43.8 → 2.2px 余裕で subpixel OVERFLOW 完全回避。
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // halo は Container の外側まで拡張 (padding 3 + border 1 + 追加 8 = -12)
                if (showHalo)
                  const Positioned(
                    left: -12,
                    right: -12,
                    top: -12,
                    bottom: -12,
                    child: IgnorePointer(child: _ChipHalo()),
                  ),
                // メインコンテンツ (non-positioned で Stack のサイズ基準)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 表示分岐 (2026-05-10):
                    //  - disabled (プロフィール未設定): 🌱 emoji (32pt 表示)
                    //  - unseen (未開封): unsealed.webp (9芒星アンティーク章)
                    //    → 答えがまだ見えていないことを象徴。halo は背面で発光
                    //  - seen (開封済): topCategory に応じた CategoryIcon
                    //    → 今日の追い風カテゴリを示す
                    if (disabled)
                      const Text('🌱', style: TextStyle(fontSize: 32))
                    else if (unseen)
                      Image.asset(
                        'assets/menu_icons/unsealed.webp',
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      )
                    else
                      CategoryIcon(kind: iconKind, size: 32),
                    const SizedBox(height: 1),
                    Text(
                      'Daily',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: unseen
                            ? const Color(0xFFFFE99A)
                            : const Color(0xFFC9A84C),
                        letterSpacing: 0.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
