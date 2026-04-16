import 'package:flutter/material.dart';
import '../models/lunar_intention.dart';
import '../theme/solara_colors.dart';
import '../utils/cycle_story_texts.dart';
import '../utils/solara_storage.dart';
import 'glass_panel.dart';

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
    with SingleTickerProviderStateMixin {
  bool _showStory = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showStory) return _buildStoryPage(context);
    return _buildChoicePage(context);
  }

  Widget _buildStoryPage(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final chosenText = locale.startsWith('ja')
        ? widget.intention.chosenTextJP
        : widget.intention.chosenText;
    final paragraphs = CycleStoryTexts.getCatasterism(
        locale, widget.totalDays, chosenText);

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        color: const Color(0xF0040810),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 20),
                  child: Column(
                    children: [
                      const Text('\u{1F48E}', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 24),
                      ...paragraphs.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          p,
                          style: const TextStyle(
                            color: Color(0xFFEAEAEA),
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            height: 1.8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                child: GestureDetector(
                  onTap: () => setState(() => _showStory = false),
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [
                          SolaraColors.solaraGold,
                          SolaraColors.solaraGoldLight,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          color: SolaraColors.celestialBlueDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoicePage(BuildContext context) {
    final midRating = widget.intention.midpoint?.rating;
    String midLabel = '';
    if (midRating != null) {
      const labels = ['', '\u{1F30A} \u307e\u3060\u53d6\u308a\u7d44\u3093\u3067\u3044\u305f', '\u{2728} \u9032\u5c55\u3042\u308a', '\u{1F31F} \u8efd\u304f\u306a\u3063\u3066\u304d\u305f'];
      midLabel = labels[midRating];
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        color: const Color(0xF0040810),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('\u{1F48E}', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text(
                  'Catasterism',
                  style: TextStyle(
                    color: SolaraColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                  ),
                ),
                const Text(
                  '\u523b\u661f\u5316', // 刻星化
                  style: TextStyle(
                    color: SolaraColors.solaraGold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'This cycle, you chose to release:',
                  style: TextStyle(
                    color: SolaraColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                GlassPanel(
                  padding: const EdgeInsets.all(16),
                  borderRadius: BorderRadius.circular(14),
                  child: Column(
                    children: [
                      Text(
                        widget.intention.chosenTextJP,
                        style: const TextStyle(
                          color: SolaraColors.solaraGold,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.intention.chosenText,
                        style: const TextStyle(
                          color: SolaraColors.textSecondary,
                          fontSize: 12,
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
                const SizedBox(height: 28),
                const Text(
                  'Did you release it?',
                  style: TextStyle(
                    color: SolaraColors.textPrimary,
                    fontSize: 16,
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
                const SizedBox(height: 20),
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
                      fontSize: 13,
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

  Widget _buildChoice({
    required String emoji,
    required String label,
    required String sublabel,
    required bool released,
  }) {
    return GestureDetector(
      onTap: () => _submit(released),
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: SolaraColors.glassFill,
          border: Border.all(color: SolaraColors.glassBorder),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    color: SolaraColors.textPrimary, fontSize: 14)),
            Text(sublabel,
                style: const TextStyle(
                    color: SolaraColors.textSecondary, fontSize: 11)),
          ],
        ),
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
