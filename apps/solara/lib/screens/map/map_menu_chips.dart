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
            // 寸法 (2026-05-10 第三弾):
            //   padding 3 + Image 32 + spacing 1 + Text fontSize 9 (~10.8) + padding 3 = 49.8
            //   旧 53 just-fit 構成で Daily 側 Stack 構造の subpixel 由来 OVERFLOW
            //   が再発したため、余裕を ~3px 確保。アイコンも 28→32 へ拡大、
            //   ラベルは 10→9 に縮小 (オーナー要望「もっと大きく / もっと小さく」)。
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
          // 構造 (2026-05-10 第四弾):
          //   Stack { clipBehavior: Clip.none, children: [
          //     Positioned (halo, -8 拡張),  // 描画順 = 背面
          //     Container (non-positioned),  // ← Stack のサイズ基準
          //   ]}
          //
          // 旧 (Positioned.fill Container) では Stack が parent tight 制約
          // (Row crossAxisAlignment.stretch 由来) を受け、Positioned.fill
          // Container がその tight 高を埋めて just-fit となり、Column の
          // intrinsic + padding の subpixel 計算で Daily 側だけ常時
          // OVERFLOW していた。
          //
          // 新構造: Container を non-positioned に置くと Stack のサイズは
          // Container の intrinsic で決まる (Static chip と同じ) ため、
          // child Column が padding 内に正しく収まる。halo は Positioned
          // で外側 (−8) に拡張、clipBehavior: Clip.none で外周描画継続。
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. halo を背面に (Positioned)
              if (showHalo)
                const Positioned(
                  left: -8,
                  right: -8,
                  top: -8,
                  bottom: -8,
                  child: IgnorePointer(child: _ChipHalo()),
                ),
              // 2. Container を non-positioned で配置 (Static chip と同じ)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: unseen ? 1.4 : 1),
                  gradient: fillGradient,
                ),
                // Static chip と完全一致する寸法:
                //   padding 3 + Image 32 + spacing 1 + Text fontSize 9 (~10.8) + padding 3 = 49.8
                child: Column(
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
