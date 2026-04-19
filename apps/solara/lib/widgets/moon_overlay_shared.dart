import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ══════════════════════════════════════════════════════════════
// 月 / 刻星化オーバーレイ共通ビルディングブロック
// - mysticalMoonBackdrop: 暗い宇宙背景 + 画像
// - MoonScrollingStory: 下1/4から始まる自動スクロール物語テキスト
// ══════════════════════════════════════════════════════════════

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
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
