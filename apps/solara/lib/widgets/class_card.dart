import 'package:flutter/material.dart';
import '../utils/title_data.dart';

/// Solara クラスカード表示ウィジェット
///
/// アール・ヌーヴォー画風で生成された 25 クラスのカード画像を表示する。
/// アセットパス規約: `assets/class-cards/<axis>_<court>_<nameen>.webp`
///
/// 用途:
/// 1. 診断儀式の reveal 画面（中央に大きく表示）
/// 2. シェアカード（招待状/紹介カード）
/// 3. 図鑑/コレクション画面（将来）
class ClassCard extends StatelessWidget {
  /// クラスデータ（title_data.dart の TitleClass）
  final TitleClass classData;

  /// カード横幅。高さは 2:3 比率で自動計算。
  final double width;

  /// 下部オーバーレイ表示モード。
  /// - [ClassCardMode.none]   : 画像のみ
  /// - [ClassCardMode.light]  : クラス名 + Light テキスト
  /// - [ClassCardMode.shadow] : クラス名 + Shadow テキスト
  final ClassCardMode mode;

  /// タップ時のコールバック（任意）
  final VoidCallback? onTap;

  /// EN 言語表示モード（false = JP、true = EN）
  final bool isEnglish;

  /// 軸別グローを表示するか
  final bool showGlow;

  const ClassCard({
    super.key,
    required this.classData,
    this.width = 280,
    this.mode = ClassCardMode.light,
    this.onTap,
    this.isEnglish = false,
    this.showGlow = true,
  });

  // ── 軸別カラー ──
  // 画像の枠と合わせ、ウィジェット側のグローもこの色を使用
  static const Map<String, Color> _axisColors = {
    'power': Color(0xFFC02942), // crimson
    'mind': Color(0xFF4A5BA8), // sapphire
    'spirit': Color(0xFF8E5BD0), // violet
    'shadow': Color(0xFF5E3D7A), // amethyst (dark purple)
    'heart': Color(0xFFE8A0B5), // rose-pink
  };

  Color get _axisColor => _axisColors[classData.axis] ?? const Color(0xFFF9D976);

  String get _assetPath {
    return 'assets/class-cards/'
        '${classData.axis}_${classData.court}_${classData.nameEN.toLowerCase()}.webp';
  }

  @override
  Widget build(BuildContext context) {
    final height = width * 1.5; // 2:3 縦長

    Widget card = SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // ── カード画像 ──
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                _assetPath,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => _buildPlaceholder(),
              ),
            ),
          ),

          // ── オーバーレイ ──
          if (mode != ClassCardMode.none)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildOverlay(),
            ),
        ],
      ),
    );

    // 軸色グロー
    if (showGlow) {
      card = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _axisColor.withValues(alpha: 0.35),
              blurRadius: 32,
              spreadRadius: 1,
            ),
            const BoxShadow(
              color: Color(0x66000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: card,
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }

  Widget _buildOverlay() {
    final isLight = mode == ClassCardMode.light;
    final classNameJP = classData.nameJP;
    final classNameEN = classData.nameEN;

    // Light/Shadow テキスト (JP/EN 切替)
    final text = isLight
        ? (isEnglish ? classData.lightEN : classData.lightJP)
        : (isEnglish ? classData.shadowEN : classData.shadowJP);

    final accentColor = isLight ? const Color(0xFFF9D976) : const Color(0xFFEAEAEA);

    // ── 固定高さで Light/Shadow のクラス名位置を一致させる ──
    // テキスト 3行ぶんを確保 (短い Light でも長い Shadow でも同じレイアウト)
    final isSmall = width < 200;
    final overlayHeight = width * 0.62; // 280→174, 260→161, 200→124
    final fsClassJP = isSmall ? 16.0 : 22.0;
    final fsClassEN = isSmall ? 9.0 : 11.0;
    final fsText = isSmall ? 11.0 : 14.0;

    return Container(
      height: overlayHeight,
      padding: const EdgeInsets.fromLTRB(16, 36, 16, 14),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.7),
            Colors.black.withValues(alpha: 0.92),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // クラス名 JP (大)
          Text(
            isEnglish ? classNameEN : classNameJP,
            style: TextStyle(
              color: accentColor,
              fontSize: fsClassJP,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 6),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          // クラス名 EN (小)
          Text(
            isEnglish ? '— ${classData.axis.toUpperCase()} ${classData.court.toUpperCase()} —' : classNameEN,
            style: TextStyle(
              color: accentColor.withValues(alpha: 0.6),
              fontSize: fsClassEN,
              letterSpacing: 3,
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 10),
            // Light/Shadow テキスト (固定領域で揃える)
            Expanded(
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    color: accentColor.withValues(alpha: 0.92),
                    fontSize: fsText,
                    fontStyle: isLight ? FontStyle.normal : FontStyle.italic,
                    height: 1.5,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// アセット欠落時のプレースホルダ
  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF0A0A14),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 48, color: _axisColor.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              classData.nameJP,
              style: TextStyle(
                color: _axisColor.withValues(alpha: 0.8),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              classData.nameEN,
              style: const TextStyle(
                color: Color(0xFFACACAC),
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ClassCard のオーバーレイ表示モード
enum ClassCardMode {
  /// オーバーレイ無し（画像のみ）
  none,

  /// クラス名 + Light テキスト
  light,

  /// クラス名 + Shadow テキスト
  shadow,
}
