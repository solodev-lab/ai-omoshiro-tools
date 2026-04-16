import 'package:flutter/material.dart';
import '../models/lunar_intention.dart';
import '../theme/solara_colors.dart';
import '../utils/celestial_events.dart';
import '../utils/cycle_story_texts.dart';
import '../utils/solara_storage.dart';
import 'glass_panel.dart';

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
                      const Text('\u{1F315}', style: TextStyle(fontSize: 48)),
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

  Widget _buildRatingPage(BuildContext context) {
    final monthData = CelestialEvents.getMonth(widget.month);
    final moonName = monthData?.fullMoonName ?? 'Full Moon';
    final moonNameJP = monthData?.fullMoonNameJP ?? '\u6e80\u6708';

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
                const Text('\u{1F315}', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  moonName,
                  style: const TextStyle(
                    color: SolaraColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  moonNameJP,
                  style: const TextStyle(
                    color: SolaraColors.solaraGold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'You set out to release:',
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
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'How does it feel now?',
                  style: TextStyle(
                    color: SolaraColors.textPrimary,
                    fontSize: 16,
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
                            Text(emoji, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(labelJP,
                                    style: const TextStyle(
                                        color: SolaraColors.textPrimary,
                                        fontSize: 14)),
                                Text(labelEN,
                                    style: const TextStyle(
                                        color: SolaraColors.textSecondary,
                                        fontSize: 11)),
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

  Future<void> _submitRating(int rating) async {
    final updated = widget.intention.copyWith(
      midpoint: MidpointCheck(checkedAt: DateTime.now(), rating: rating),
    );
    await SolaraStorage.saveIntention(updated);
    await SolaraStorage.markOverlayShown('full_moon');
    widget.onDismiss();
  }
}

