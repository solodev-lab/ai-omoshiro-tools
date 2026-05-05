import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/solara_colors.dart';

// ══════════════════════════════════════════════════════════════
// 月 / 刻星化オーバーレイ共通ビルディングブロック
// - mysticalMoonBackdrop: 暗い宇宙背景 + 画像
// - MoonScrollingStory: 下1/4から始まる自動スクロール物語テキスト
// - revealPoeticMessage: 選択後フェードインの詩的メッセージ (full/new moon 共有)
// ══════════════════════════════════════════════════════════════

/// 選択後フェードインで表示する詩的メッセージ。
/// full_moon_overlay の `_revealMessage` と new_moon_overlay の `_revealMessage` が
/// テキスト 2 行のみ違い完全同形だったため共有化 (audit T2, 2026-05-06)。
/// ロケール ja で [ja]、それ以外は [en] を使う。
Widget revealPoeticMessage(BuildContext context, {required String ja, required String en}) {
  final locale = Localizations.localeOf(context).toString();
  final isJA = locale.startsWith('ja');
  return Text(
    isJA ? ja : en,
    textAlign: TextAlign.center,
    style: TextStyle(
      color: SolaraColors.textPrimary.withValues(alpha: 0.92),
      fontSize: 14,
      height: 1.8,
      letterSpacing: 1.2,
      fontStyle: FontStyle.italic,
    ),
  );
}

/// 月オーバーレイの選択可能カードの共通枠 (full_moon の評価カード /
/// new_moon の選択肢カード)。
///
/// AnimatedContainer + 角丸 + isSelected による枠色/背景色の切替までを共通化。
/// 内部 child は呼び側で構築 (Row/Column どちらでも可)。
/// audit T7, 2026-05-06。
Widget moonOverlaySelectableCard({required bool isSelected, required Widget child}) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: isSelected
          ? SolaraColors.solaraGold.withValues(alpha: 0.12)
          : SolaraColors.glassFill,
      border: Border.all(
        color: isSelected
            ? SolaraColors.solaraGold.withValues(alpha: 0.5)
            : SolaraColors.glassBorder,
      ),
    ),
    child: child,
  );
}

/// 月オーバーレイのタップ時の幾何測定 — title と選択 item の Y 座標 + 高さ。
///
/// full_moon の _onRatingTap / new_moon の _onChoiceTap が GlobalKey から
/// RenderBox を取って localToGlobal + size.height を返す処理を完全に同じ形で
/// 持っていたため共有化 (audit T7, 2026-05-06)。
///
/// 戻り値が null の場合は RenderBox がまだ未確定 (build 前) のため呼び側は早期 return。
({double titleY, double titleH, double itemY, double itemH})?
    measureMoonOverlayTapGeometry(GlobalKey titleKey, GlobalKey itemKey) {
  final titleBox = titleKey.currentContext?.findRenderObject() as RenderBox?;
  final itemBox = itemKey.currentContext?.findRenderObject() as RenderBox?;
  if (titleBox == null || itemBox == null) return null;
  return (
    titleY: titleBox.localToGlobal(Offset.zero).dy,
    titleH: titleBox.size.height,
    itemY: itemBox.localToGlobal(Offset.zero).dy,
    itemH: itemBox.size.height,
  );
}

/// 神秘的な月/刻星化背景 — 黒ベース + 画像レイヤー + 子widget
Widget mysticalMoonBackdrop({
  required String assetPath,
  required Widget child,
}) {
  return Stack(fit: StackFit.expand, children: [
    const ColoredBox(color: Color(0xFF040810)),
    Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    ),
    child,
  ]);
}

/// 縦スクロールするストーリーテキスト (新月/満月/刻星化 共通)
/// - 下1/4位置からコンテンツ開始
/// - 30 px/s の自動スクロール + ユーザードラッグで中断可能
/// - 最後まで到達 (自動 or 手動) で onReachedEnd を発火
/// - 上部 22~38% はシェーダーマスクでフェードアウト
class MoonScrollingStory extends StatefulWidget {
  /// 物語テキスト全体のフェードイン
  final Animation<double> fadeAnim;
  /// 先頭の大見出しラベル (例: 'NEW MOON', 'FULL MOON', 'CATASTERISM')
  final String label;
  /// 本文段落
  final List<String> paragraphs;
  /// 自動/手動いずれかで最後まで到達した時のコールバック
  final VoidCallback onReachedEnd;
  const MoonScrollingStory({
    super.key,
    required this.fadeAnim,
    required this.label,
    required this.paragraphs,
    required this.onReachedEnd,
  });

  @override
  State<MoonScrollingStory> createState() => _MoonScrollingStoryState();
}

class _MoonScrollingStoryState extends State<MoonScrollingStory> {
  final ScrollController _scrollCtl = ScrollController();
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _scrollCtl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  void _startAutoScroll() {
    if (!mounted || !_scrollCtl.hasClients) return;
    final max = _scrollCtl.position.maxScrollExtent;
    if (max <= 0) return;
    // 30 px/s 一定速度
    final ms = (max / 30.0 * 1000).round();
    _scrollCtl.animateTo(
      max,
      duration: Duration(milliseconds: ms),
      curve: Curves.linear,
    );
  }

  void _onScroll() {
    if (_triggered || !_scrollCtl.hasClients) return;
    final pos = _scrollCtl.position;
    if (pos.pixels >= pos.maxScrollExtent - 2) {
      _triggered = true;
      widget.onReachedEnd();
    }
  }

  @override
  void dispose() {
    _scrollCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, cons) {
      final h = cons.maxHeight;
      return ClipRect(
        child: ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            // 上部 0~22% 透明、22%→38% でフェード、以降不透明
            colors: [
              Color(0x00FFFFFF),
              Color(0x00FFFFFF),
              Color(0xFFFFFFFF),
              Color(0xFFFFFFFF),
            ],
            stops: [0.0, 0.22, 0.38, 1.0],
          ).createShader(rect),
          blendMode: BlendMode.dstIn,
          child: FadeTransition(
            opacity: widget.fadeAnim,
            child: SingleChildScrollView(
              controller: _scrollCtl,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                top: h * 0.75,
                bottom: h, // 本文が viewport 上端まで完全に流れ切る余白
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(widget.label, style: GoogleFonts.cinzel(
                      color: const Color(0xFFF9D976),
                      fontSize: 14, letterSpacing: 4,
                      fontWeight: FontWeight.w600)),
                    const SizedBox(height: 32),
                    ...widget.paragraphs.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: Text(
                        p,
                        style: const TextStyle(
                          color: Color(0xFFF5EFDA),
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          height: 1.9,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
