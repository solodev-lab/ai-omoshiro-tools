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

  /// オーバーレイ最上段に表示する「一言」(Light面: t144.light、例「省察に長けた」)
  /// 空文字なら非表示。クラス名と縦書きで「省察に長けた / 騎士」と読める順序。
  final String titleLightJP;

  /// 同上 (Shadow面: t144.shadow、例「謎キャラぶって脳内ダメ出し中な」)
  final String titleShadowJP;

  const ClassCard({
    super.key,
    required this.classData,
    this.width = 280,
    this.mode = ClassCardMode.light,
    this.onTap,
    this.isEnglish = false,
    this.showGlow = true,
    this.titleLightJP = '',
    this.titleShadowJP = '',
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

          // ── Shadow 時の薄暗化レイヤー (Light との切替が分かるように) ──
          if (mode == ClassCardMode.shadow)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.28),
                  ),
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

    // 一言 (Light/Shadow 切替)
    final titleOneLine = isLight ? titleLightJP : titleShadowJP;
    final hasTitle = titleOneLine.isNotEmpty;

    // ── 固定高さで Light/Shadow のクラス名位置を一致させる ──
    // オーバーレイはカード下部 1/3 強に収め、絵が見える領域を最大化
    final isSmall = width < 200;
    // 280px の場合: 280 * 0.7 = 196px, カード全体 420 の 47% を占有
    // (長い一言/クラステキスト時のオーバーフロー余裕を確保)
    final overlayHeight = width * (hasTitle ? 0.70 : 0.56);
    final fsTitleOne = isSmall ? 12.0 : 15.0;
    final fsClassJP = isSmall ? 16.0 : 21.0;
    final fsClassEN = isSmall ? 9.0 : 10.0;
    final fsText = isSmall ? 10.0 : 12.0;

    return Container(
      height: overlayHeight,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
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
      // Align で下寄せ。Column は内容高さに収縮 (mainAxisSize.min) するため
      // 長い一言+クラステキストの組合せでも overflow しない。
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // 一言 (任意)「省察に長けた」「謎キャラぶって脳内ダメ出し中な」
          if (hasTitle) ...[
            Text(
              titleOneLine,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accentColor,
                fontSize: fsTitleOne,
                fontWeight: FontWeight.w600,
                height: 1.3,
                letterSpacing: 0.3,
                shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
          ],
          // クラス名 JP (大) — 一言の次の行に来て「省察に長けた / 騎士」と読める
          // 固定高 overlay 内なので maxLines:1+ellipsis で 1.5x の折返しによる縦溢れを防ぐ。
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 6),
            // Light/Shadow クラステキスト — 折返し可で全文表示
            Text(
              text,
              style: TextStyle(
                color: accentColor.withValues(alpha: 0.88),
                fontSize: fsText,
                fontStyle: isLight ? FontStyle.normal : FontStyle.italic,
                height: 1.4,
                letterSpacing: 0,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          ],
        ),
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
