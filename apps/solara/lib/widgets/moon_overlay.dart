import 'package:flutter/material.dart';
import '../models/lunar_intention.dart';
import '../theme/solara_colors.dart';
import '../utils/celestial_events.dart';
import '../utils/solara_storage.dart';
import 'glass_panel.dart';

// ============================================================
//  New Moon Overlay — choose what to release this cycle
// ============================================================

class NewMoonOverlay extends StatefulWidget {
  final int month;
  final String cycleId;
  final VoidCallback onDismiss;
  final VoidCallback onIntentionSet;

  const NewMoonOverlay({
    super.key,
    required this.month,
    required this.cycleId,
    required this.onDismiss,
    required this.onIntentionSet,
  });

  @override
  State<NewMoonOverlay> createState() => _NewMoonOverlayState();
}

class _NewMoonOverlayState extends State<NewMoonOverlay>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = -1;
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
    final monthData = CelestialEvents.getMonth(widget.month);
    final themes = CelestialEvents.getThemes(widget.month);
    final sign = monthData?.newMoonSign ?? '';
    final signJP = monthData?.newMoonSignJP ?? '';

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
                // Moon emoji
                const Text('\u{1F311}', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'New Moon in $sign',
                  style: const TextStyle(
                    color: SolaraColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$signJP\u306e\u65b0\u6708',
                  style: const TextStyle(
                    color: SolaraColors.solaraGold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                // Celestial events summary
                if (monthData != null && monthData.events.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: GlassPanel(
                      padding: const EdgeInsets.all(12),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        children: monthData.events.map((e) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              e.descJP,
                              style: const TextStyle(
                                color: SolaraColors.textSecondary,
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'What will you release\nthis cycle?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SolaraColors.textPrimary,
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 20),
                // 3 choices
                ...List.generate(themes.en.length, (i) {
                  final isSelected = _selectedIndex == i;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              themes.jp[i],
                              style: TextStyle(
                                color: isSelected
                                    ? SolaraColors.solaraGold
                                    : SolaraColors.textPrimary,
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              themes.en[i],
                              style: TextStyle(
                                color: SolaraColors.textSecondary
                                    .withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                // Set intention button
                if (_selectedIndex >= 0)
                  GestureDetector(
                    onTap: _setIntention,
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
                          'Set Intention',
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
                const SizedBox(height: 12),
                // Not today
                TextButton(
                  onPressed: () async {
                    await SolaraStorage.markOverlayShown('new_moon');
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

  Future<void> _setIntention() async {
    final themes = CelestialEvents.getThemes(widget.month);
    final monthData = CelestialEvents.getMonth(widget.month);
    final intention = LunarIntention(
      cycleId: widget.cycleId,
      chosenText: themes.en[_selectedIndex],
      chosenTextJP: themes.jp[_selectedIndex],
      chosenAt: DateTime.now(),
      newMoonSign: monthData?.newMoonSign ?? '',
    );
    await SolaraStorage.saveIntention(intention);
    await SolaraStorage.markOverlayShown('new_moon');
    widget.onIntentionSet();
  }
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
    with SingleTickerProviderStateMixin {
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

// ============================================================
//  Crystallization Overlay — day before new moon self-assessment
// ============================================================

class CrystallizationOverlay extends StatefulWidget {
  final LunarIntention intention;
  final VoidCallback onDismiss;

  const CrystallizationOverlay({
    super.key,
    required this.intention,
    required this.onDismiss,
  });

  @override
  State<CrystallizationOverlay> createState() => _CrystallizationOverlayState();
}

class _CrystallizationOverlayState extends State<CrystallizationOverlay>
    with SingleTickerProviderStateMixin {
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
                  'Crystallization',
                  style: TextStyle(
                    color: SolaraColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                  ),
                ),
                const Text(
                  '\u7d50\u6676\u5316',
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
                    await SolaraStorage.markOverlayShown('crystallization');
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
      crystallization:
          CrystallizationResult(assessedAt: DateTime.now(), released: released),
    );
    await SolaraStorage.saveIntention(updated);
    await SolaraStorage.markOverlayShown('crystallization');
    widget.onDismiss();
  }
}
