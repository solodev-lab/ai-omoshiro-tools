import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/lunar_intention.dart';
import '../theme/solara_colors.dart';
import '../utils/celestial_events.dart';
import '../utils/cycle_story_texts.dart';
import '../utils/solara_storage.dart';
import 'glass_panel.dart';

Widget _mysticalMoonBackdrop({
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
    const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0x66000000), Color(0xCC000000), Color(0xF0000000)],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
    ),
    child,
  ]);
}

// ============================================================
//  Full Moon Overlay — midpoint check-in
// ============================================================

class FullMoonOverlay extends StatefulWidget {
  final LunarIntention intention;
  final int month;
  final VoidCallback onDismiss;

  const FullMoonOverlay({
    super.key,
    required this.intention,
    required this.month,
    required this.onDismiss,
  });

  @override
  State<FullMoonOverlay> createState() => _FullMoonOverlayState();
}

class _FullMoonOverlayState extends State<FullMoonOverlay>
    with TickerProviderStateMixin {
  bool _showStory = true;
  late AnimationController _fadeController;
  late AnimationController _scrollController;
  late Animation<double> _fadeAnim;
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _scrollController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..forward();
    // スクロール完了後、2秒待って次ページ (評価画面) へ自動切替
    _scrollController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _showStory && mounted) {
        _autoAdvanceTimer = Timer(const Duration(seconds: 2), () {
          if (mounted && _showStory) setState(() => _showStory = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  static const _ratingLabels = [
    ('\u{1F30A}', 'Still working on it', '\u307e\u3060\u53d6\u308a\u7d44\u3093\u3067\u3044\u308b'),
    ('\u{2728}', 'Making progress', '\u9032\u5c55\u3042\u308a'),
    ('\u{1F31F}', 'Feeling lighter', '\u8efd\u304f\u306a\u3063\u3066\u304d\u305f'),
  ];

  @override
  Widget build(BuildContext context) {
    if (_showStory) return _buildStoryPage(context);
    return _buildRatingPage(context);
  }

  Widget _buildStoryPage(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final chosenText = locale.startsWith('ja')
        ? widget.intention.chosenTextJP
        : widget.intention.chosenText;
    final paragraphs = CycleStoryTexts.getFullMoon(locale, chosenText);

    return _mysticalMoonBackdrop(
      assetPath: 'assets/horo-bg/full_moon_bg.webp',
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _FullMoonScrollingStory(
                fadeAnim: _fadeAnim,
                scrollAnim: _scrollController,
                paragraphs: paragraphs,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: GestureDetector(
                  onTap: () => setState(() => _showStory = false),
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
      ),
    );
  }

  Widget _buildRatingPage(BuildContext context) {
    final monthData = CelestialEvents.getMonth(widget.month);
    final moonName = monthData?.fullMoonName ?? 'Full Moon';
    final moonNameJP = monthData?.fullMoonNameJP ?? '\u6e80\u6708';

    return FadeTransition(
      opacity: _fadeAnim,
      child: _mysticalMoonBackdrop(
        assetPath: 'assets/horo-bg/full_moon_bg.webp',
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 14),
                Text(
                  moonName,
                  style: GoogleFonts.cinzel(
                    color: SolaraColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.5,
                  ),
                ),
                Text(
                  moonNameJP,
                  style: const TextStyle(
                    color: SolaraColors.solaraGold,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'You set out to release:',
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
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'How does it feel now?',
                  style: GoogleFonts.cinzel(
                    color: SolaraColors.textPrimary,
                    fontSize: 18, letterSpacing: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                // 3 rating options
                ...List.generate(3, (i) {
                  final (emoji, labelEN, labelJP) = _ratingLabels[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: GestureDetector(
                      onTap: () => _submitRating(i + 1),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: SolaraColors.glassFill,
                          border: Border.all(color: SolaraColors.glassBorder),
                        ),
                        child: Row(
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 26)),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(labelJP,
                                    style: const TextStyle(
                                        color: SolaraColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text(labelEN,
                                    style: const TextStyle(
                                        color: SolaraColors.textSecondary,
                                        fontSize: 12,
                                        letterSpacing: 0.5)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    await SolaraStorage.markOverlayShown('full_moon');
                    widget.onDismiss();
                  },
                  child: const Text(
                    'Not today',
                    style: TextStyle(
                      color: SolaraColors.textSecondary,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitRating(int rating) async {
    final updated = widget.intention.copyWith(
      midpoint: MidpointCheck(checkedAt: DateTime.now(), rating: rating),
    );
    await SolaraStorage.saveIntention(updated);
    await SolaraStorage.markOverlayShown('full_moon');
    widget.onDismiss();
  }
}

class _FullMoonScrollingStory extends StatelessWidget {
  final Animation<double> fadeAnim;
  final Animation<double> scrollAnim;
  final List<String> paragraphs;
  const _FullMoonScrollingStory({
    required this.fadeAnim,
    required this.scrollAnim,
    required this.paragraphs,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, cons) {
      final h = cons.maxHeight;
      final startY = h * 0.5;
      final endY = -h * 1.2;

      return ClipRect(
        child: ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
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
            opacity: fadeAnim,
            child: AnimatedBuilder(
              animation: scrollAnim,
              child: RepaintBoundary(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: 0,
                  maxHeight: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('FULL MOON', style: GoogleFonts.cinzel(
                          color: const Color(0xFFF9D976),
                          fontSize: 14, letterSpacing: 4,
                          fontWeight: FontWeight.w600)),
                        const SizedBox(height: 32),
                        ...paragraphs.map((p) => Padding(
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
              builder: (_, child) {
                final t = scrollAnim.value;
                final y = startY + (endY - startY) * t;
                return Transform.translate(
                  offset: Offset(0, y),
                  child: child,
                );
              },
            ),
          ),
        ),
      );
    });
  }
}

