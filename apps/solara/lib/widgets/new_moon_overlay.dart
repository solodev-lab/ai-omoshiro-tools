import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/lunar_intention.dart';
import '../theme/solara_colors.dart';
import '../utils/celestial_events.dart';
import '../utils/cycle_story_texts.dart';
import '../utils/solara_storage.dart';
import 'glass_panel.dart';

/// 神秘的な月オーバーレイ背景 — 画像 + 薄めのオーバーレイ
/// 新月は画像自体が暗いので、オーバーレイは軽めにして画像を見せる
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
    // 軽めのグラデーション (新月の暗さを潰さない)
    const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0x22000000), Color(0x55000000), Color(0x88000000)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
    ),
    child,
  ]);
}

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
    with TickerProviderStateMixin {
  int _selectedIndex = -1;
  int _notTodayCount = 0;
  bool _showStory = true;
  late AnimationController _fadeController;
  late AnimationController _scrollController;
  late Animation<double> _fadeAnim;
  Timer? _autoAdvanceTimer;
  List<CelestialEvent>? _cycleEvents;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    // ゆっくり上昇する縦スクロール (40秒で1往復)
    _scrollController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..forward();
    // スクロール完了後、2秒待って次ページ (選択画面) へ自動切替
    _scrollController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _showStory && mounted) {
        _autoAdvanceTimer = Timer(const Duration(seconds: 2), () {
          if (mounted && _showStory) setState(() => _showStory = false);
        });
      }
    });
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
    _autoAdvanceTimer?.cancel();
    _fadeController.dispose();
    _scrollController.dispose();
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

    return _mysticalMoonBackdrop(
      assetPath: 'assets/horo-bg/new_moon_bg.webp',
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _ScrollingStoryText(
                fadeAnim: _fadeAnim,
                scrollAnim: _scrollController,
                label: 'NEW MOON',
                paragraphs: paragraphs,
              ),
            ),
            // Continue button (fixed at bottom)
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

  Widget _buildChoicePage(BuildContext context) {
    final monthData = CelestialEvents.getMonth(widget.month);
    final themes = CelestialEvents.getThemes(widget.month);
    final sign = monthData?.newMoonSign ?? '';
    final signJP = monthData?.newMoonSignJP ?? '';
    // API取得前は静的JSONのイベント、取得後はサイクル内イベントを表示
    final events = _cycleEvents ?? monthData?.events ?? [];

    return FadeTransition(
      opacity: _fadeAnim,
      child: _mysticalMoonBackdrop(
        assetPath: 'assets/horo-bg/new_moon_bg.webp',
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 14),
                Text(
                  'New Moon in $sign',
                  style: GoogleFonts.cinzel(
                    color: SolaraColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$signJP\u306e\u65b0\u6708',
                  style: const TextStyle(
                    color: SolaraColors.solaraGold,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                // Celestial events summary (サイクル内イベント)
                if (events.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: GlassPanel(
                      padding: const EdgeInsets.all(14),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        children: events.map((e) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text(
                              e.localDescJP,
                              style: const TextStyle(
                                color: Color(0xFFCCCCCC),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  'What will you release\nthis cycle?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    color: SolaraColors.textPrimary,
                    fontSize: 18,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
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
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isSkipChoice ? 'No particular theme' : themes.en[i],
                              style: TextStyle(
                                color: SolaraColors.textSecondary
                                    .withValues(alpha: 0.8),
                                fontSize: 12,
                                letterSpacing: 0.5,
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
                      child: Center(
                        child: Text(
                          'Set Intention',
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

/// 縦スクロールするストーリーテキスト
/// - 中央からフェードイン
/// - ゆっくり上方向に流れる
/// - 上部 25% はマスクで不可視・グラデーションでフェードアウト
class _ScrollingStoryText extends StatelessWidget {
  final Animation<double> fadeAnim;
  final Animation<double> scrollAnim;
  final String label;
  final List<String> paragraphs;
  const _ScrollingStoryText({
    required this.fadeAnim,
    required this.scrollAnim,
    required this.label,
    required this.paragraphs,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, cons) {
      final h = cons.maxHeight;
      // 初期位置: コンテンツの先頭を 画面縦中央 (50%) に配置
      // 終位置: コンテンツ全体が上に流れ切る位置 (-120% ~ 完全に画面外へ)
      final startY = h * 0.5;
      final endY = -h * 1.2;

      return ClipRect(
        child: ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            // 上部 0~25% は透明、25%〜35% でぼかしながらフェード、以降不透明
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
              // 子ツリーは1回だけビルドして使い回す (再レイアウト防止)
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
                        Text(label, style: GoogleFonts.cinzel(
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

