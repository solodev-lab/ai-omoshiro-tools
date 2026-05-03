import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/lunar_intention.dart';
import '../theme/solara_colors.dart';
import '../utils/cycle_story_texts.dart';
import '../utils/solara_storage.dart';
import 'glass_panel.dart';
import 'moon_overlay_shared.dart';

// ============================================================
//  Catasterism Overlay (刻星化) — day before new moon self-assessment
//  Catasterism: Greek myth — the placing of mortals among the stars as constellations.
// ============================================================

class CatasterismOverlay extends StatefulWidget {
  final LunarIntention intention;
  final int totalDays;
  final VoidCallback onDismiss;
  final void Function(bool released)? onResult;

  const CatasterismOverlay({
    super.key,
    required this.intention,
    required this.totalDays,
    required this.onDismiss,
    this.onResult,
  });

  @override
  State<CatasterismOverlay> createState() => _CatasterismOverlayState();
}

class _CatasterismOverlayState extends State<CatasterismOverlay>
    with TickerProviderStateMixin {
  bool _showStory = true;
  late AnimationController _fadeController;
  /// 物語→選択画面のクロスフェード用 (0=物語のみ / 0.5=切替点 / 1=選択画面のみ)
  late AnimationController _pageCtl;
  /// 選択タップ後、全体をフェードアウトしてアニメーション画面へ移る
  late AnimationController _exitCtl;
  /// タップ時のグロウパルス (forward=発光, reverse=元に戻る)
  late AnimationController _glowCtl;
  late Animation<double> _fadeAnim;
  /// タップ済みの選択 (null=未選択 / true=手放せた / false=まだ途中)
  bool? _selectedReleased;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    // ページクロスフェード (物語フェードアウト→選択画面フェードイン)
    _pageCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addListener(() {
      if (_pageCtl.value >= 0.5 && _showStory && mounted) {
        setState(() => _showStory = false);
      }
    });
    // 選択後のフェードアウト (0→1 でコンテンツ全体が消える)
    _exitCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    // タップ時のグロウパルス (0→1→0)。値は _buildChoice の装飾に直接反映。
    _glowCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  /// 物語→選択画面のフェード遷移を開始。多重呼び出しは無視。
  void _transitionToChoice() {
    if (_pageCtl.isAnimating || _pageCtl.value > 0) return;
    _pageCtl.forward();
  }

  /// 選択タップ → 発光パルス(forward→reverse)で元に戻す → 余韻 →
  /// 全体をフェードアウト → アニメーションへ
  Future<void> _onReleasedTap(bool released) async {
    if (_selectedReleased != null) return;
    setState(() => _selectedReleased = released);
    // 発光: 600ms で光り、100ms ピークホールド、600ms で元に戻す (計1300ms)
    await _glowCtl.forward();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    await _glowCtl.reverse();
    if (!mounted) return;
    // 発光後、残り余韻 — タップから合計 2200ms 経過するまで待つ
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    // 800ms でフェードアウト
    await _exitCtl.forward();
    if (!mounted) return;
    _submit(released);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageCtl.dispose();
    _exitCtl.dispose();
    _glowCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // オーバーレイ全体を初期フェードインで包む (背景含む)
    return FadeTransition(
      opacity: _fadeAnim,
      child: mysticalMoonBackdrop(
        assetPath: 'assets/catasterism_bg_void2.webp',
        child: AnimatedBuilder(
          animation: _pageCtl,
          builder: (context, _) {
            final t = _pageCtl.value;
            final opacity = _showStory
                ? (1 - t * 2).clamp(0.0, 1.0)
                : ((t - 0.5) * 2).clamp(0.0, 1.0);
            return Opacity(
              opacity: opacity,
              child: _showStory
                  ? _buildStoryContent(context)
                  : _buildChoiceContent(context),
            );
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // Story content — 自動スクロール + ユーザー操作可能
  // ══════════════════════════════════════════════════
  Widget _buildStoryContent(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final chosenText = locale.startsWith('ja')
        ? widget.intention.chosenTextJP
        : widget.intention.chosenText;
    final paragraphs = CycleStoryTexts.getCatasterism(
        locale, widget.totalDays, chosenText);

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: MoonScrollingStory(
              fadeAnim: _fadeAnim,
              label: 'CATASTERISM',
              paragraphs: paragraphs,
              onReachedEnd: _transitionToChoice,
            ),
          ),
          // Continue button (fixed at bottom)
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: GestureDetector(
                onTap: _transitionToChoice,
                child: Container(
                  width: 240,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [
                        SolaraColors.solaraGold,
                        SolaraColors.solaraGoldLight,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Continue',
                      style: GoogleFonts.cinzel(
                        color: SolaraColors.celestialBlueDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // Choice content — 過ぎたサイクルの自己評価 (Yes / Not yet)
  // タップ後は選択側のみ輝かせ、全体をフェードアウト → アニメーションへ
  // ══════════════════════════════════════════════════
  Widget _buildChoiceContent(BuildContext context) {
    final midRating = widget.intention.midpoint?.rating;
    String midLabel = '';
    if (midRating != null) {
      const labels = ['', '\u{1F30A} \u307e\u3060\u53d6\u308a\u7d44\u3093\u3067\u3044\u305f', '\u{2728} \u9032\u5c55\u3042\u308a', '\u{1F31F} \u8efd\u304f\u306a\u3063\u3066\u304d\u305f'];
      midLabel = labels[midRating];
    }

    return AnimatedBuilder(
      animation: _exitCtl,
      builder: (context, _) {
        final exitOpacity = (1 - _exitCtl.value).clamp(0.0, 1.0);
        return Opacity(
          opacity: exitOpacity,
          child: SafeArea(
            // 小画面 (Pixel 8 縦持ち / SO-41B / A101FC など) で
            // 「Did you release it?」セクションが overflow するため
            // SingleChildScrollView でラップ。Column の中央寄せは使わず、
            // 上下に Spacer 風の SizedBox で位置調整する。
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Catasterism',
                    style: GoogleFonts.cinzel(
                      color: SolaraColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '\u523b\u661f\u5316', // 刻星化
                    style: TextStyle(
                      color: SolaraColors.solaraGold,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'This cycle, you chose to release:',
                    style: GoogleFonts.cinzel(
                      color: SolaraColors.textSecondary,
                      fontSize: 14, letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GlassPanel(
                    padding: const EdgeInsets.all(18),
                    borderRadius: BorderRadius.circular(14),
                    child: Column(
                      children: [
                        Text(
                          widget.intention.chosenTextJP,
                          style: const TextStyle(
                            color: SolaraColors.solaraGold,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.intention.chosenText,
                          style: const TextStyle(
                            color: SolaraColors.textSecondary,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (midLabel.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'At full moon: $midLabel',
                            style: const TextStyle(
                              color: SolaraColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // ScrollView 化で「中央より下」概念が消えたため、
                  // 単なる視覚的セパレータとして 60 に縮小 (旧 150)。
                  const SizedBox(height: 60),
                  Text(
                    'Did you release it?',
                    style: GoogleFonts.cinzel(
                      color: SolaraColors.textPrimary,
                      fontSize: 18, letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '\u624b\u653e\u305b\u307e\u3057\u305f\u304b\uff1f',
                    style: TextStyle(
                      color: SolaraColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Yes / Not yet
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildChoice(
                        emoji: '\u{2728}',
                        label: '\u624b\u653e\u305b\u305f',
                        sublabel: 'Released',
                        released: true,
                      ),
                      const SizedBox(width: 16),
                      _buildChoice(
                        emoji: '\u{1F331}',
                        label: '\u307e\u3060\u9014\u4e2d',
                        sublabel: 'Still growing',
                        released: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      await SolaraStorage.markOverlayShown('catasterism');
                      widget.onDismiss();
                    },
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: SolaraColors.textSecondary,
                        fontSize: 14,
                        letterSpacing: 1.2,
                        decoration: TextDecoration.underline,
                        decorationColor: SolaraColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChoice({
    required String emoji,
    required String label,
    required String sublabel,
    required bool released,
  }) {
    final isSelected = _selectedReleased == released;
    return GestureDetector(
      onTap: () => _onReleasedTap(released),
      child: AnimatedBuilder(
        animation: _glowCtl,
        builder: (context, _) {
          // glow: 選択側のみパルス値 (0→1→0)、他は常に 0
          final glow = isSelected ? _glowCtl.value : 0.0;
          // 枠は isSelected が true の間ずっと金色で残す (パルス後の余韻)
          final borderColor = isSelected
              ? SolaraColors.solaraGold.withValues(alpha: 0.85)
              : SolaraColors.glassBorder;
          final borderWidth = isSelected ? 1.5 : 1.0;
          return Container(
            width: 130,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Color.lerp(
                SolaraColors.glassFill,
                SolaraColors.solaraGold.withValues(alpha: 0.16),
                glow,
              ),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: glow > 0.01
                  ? [
                      BoxShadow(
                        color: SolaraColors.solaraGold.withValues(alpha: 0.55 * glow),
                        blurRadius: 28 * glow,
                        spreadRadius: 2 * glow,
                      ),
                      BoxShadow(
                        color: SolaraColors.solaraGoldLight.withValues(alpha: 0.35 * glow),
                        blurRadius: 48 * glow,
                        spreadRadius: 6 * glow,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Color.lerp(
                      SolaraColors.textPrimary,
                      SolaraColors.solaraGold,
                      glow,
                    ),
                    fontSize: 14,
                    fontWeight: glow > 0.5 ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                Text(
                  sublabel,
                  style: const TextStyle(
                    color: SolaraColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit(bool released) async {
    final updated = widget.intention.copyWith(
      catasterism:
          CatasterismResult(assessedAt: DateTime.now(), released: released),
    );
    await SolaraStorage.saveIntention(updated);
    await SolaraStorage.markOverlayShown('catasterism');
    // onResult があればそちらを呼ぶ (formation animation遷移用)。なければ単純dismiss。
    if (widget.onResult != null) {
      widget.onResult!(released);
    } else {
      widget.onDismiss();
    }
  }
}

