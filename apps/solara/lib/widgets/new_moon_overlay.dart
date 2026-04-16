import 'package:flutter/material.dart';
import '../models/lunar_intention.dart';
import '../theme/solara_colors.dart';
import '../utils/celestial_events.dart';
import '../utils/cycle_story_texts.dart';
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
  int _notTodayCount = 0;
  bool _showStory = true; // true=ストーリー画面, false=テーマ選択画面
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  List<CelestialEvent>? _cycleEvents;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadCycleEvents();
    _loadNotTodayCount();
  }

  Future<void> _loadNotTodayCount() async {
    final count = await SolaraStorage.getNotTodayCount(widget.cycleId);
    if (mounted) setState(() => _notTodayCount = count);
  }

  Future<void> _loadCycleEvents() async {
    final now = DateTime.now();
    final events = await CelestialEvents.fetchCycleEvents(now.year, widget.month);
    if (mounted) setState(() => _cycleEvents = events);
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
    final paragraphs = CycleStoryTexts.getNewMoon(locale);

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
                      const Text('\u{1F311}', style: TextStyle(fontSize: 48)),
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
    final monthData = CelestialEvents.getMonth(widget.month);
    final themes = CelestialEvents.getThemes(widget.month);
    final sign = monthData?.newMoonSign ?? '';
    final signJP = monthData?.newMoonSignJP ?? '';
    // API取得前は静的JSONのイベント、取得後はサイクル内イベントを表示
    final events = _cycleEvents ?? monthData?.events ?? [];

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
                // Celestial events summary (サイクル内イベント)
                if (events.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: GlassPanel(
                      padding: const EdgeInsets.all(12),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        children: events.map((e) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              e.localDescJP,
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
                // 3 choices + 「特別決めない」
                ...List.generate(themes.en.length + 1, (i) {
                  final isSkipChoice = i == themes.en.length;
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
                              isSkipChoice ? '特別決めない' : themes.jp[i],
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
                              isSkipChoice ? 'No particular theme' : themes.en[i],
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
                // Not today (累計3回で「特別決めない」として保存)
                TextButton(
                  onPressed: () async {
                    await SolaraStorage.incrementNotTodayCount(widget.cycleId);
                    if (_notTodayCount + 1 >= 3) {
                      _selectedIndex = themes.en.length; // skip choice
                      await _setIntention();
                    } else {
                      await SolaraStorage.markOverlayShown('new_moon');
                      widget.onDismiss();
                    }
                  },
                  child: Text(
                    _notTodayCount >= 2 ? 'Not today（もう一度押すと「特別決めない」で開始）' : 'Not today',
                    style: const TextStyle(
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
    final isSkip = _selectedIndex == themes.en.length;
    final intention = LunarIntention(
      cycleId: widget.cycleId,
      chosenText: isSkip ? 'No particular theme' : themes.en[_selectedIndex],
      chosenTextJP: isSkip ? '特別決めない' : themes.jp[_selectedIndex],
      chosenAt: DateTime.now(),
      newMoonSign: monthData?.newMoonSign ?? '',
    );
    await SolaraStorage.saveIntention(intention);
    await SolaraStorage.markOverlayShown('new_moon');
    widget.onIntentionSet();
  }
}

