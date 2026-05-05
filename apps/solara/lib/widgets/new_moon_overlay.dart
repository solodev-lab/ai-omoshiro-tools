import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/lunar_intention.dart';
import '../theme/solara_colors.dart';
import '../utils/celestial_events.dart';
import '../utils/cycle_story_texts.dart';
import '../utils/solara_storage.dart';
import 'glass_panel.dart';
import 'moon_overlay_shared.dart';

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
  /// 物語→選択画面のクロスフェード用 (0=物語のみ / 0.5=切替点 / 1=選択画面のみ)
  late AnimationController _pageCtl;
  late Animation<double> _fadeAnim;
  List<CelestialEvent>? _cycleEvents;

  // ── 選択後のリビール演出 ─────────────────────────────
  /// タイトル＋選択肢を中央に寄せるスライド (0→1、同時にゴール)
  late AnimationController _revealCtl;
  /// 詩的メッセージのフェードイン
  late AnimationController _messageCtl;
  /// 惑星イベント一覧のフェードイン
  late AnimationController _eventsCtl;
  /// 最下部の確定ボタン (Set Intention) のフェードイン
  late AnimationController _actionCtl;
  // 位置計測用
  final GlobalKey _titleKey = GlobalKey();
  final List<GlobalKey> _choiceKeys = List.generate(4, (_) => GlobalKey());
  double? _titleStartY;
  double? _titleHeight;
  double? _choiceStartY;
  double? _choiceHeight;

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
      // 中点で物語→選択画面に切替
      if (_pageCtl.value >= 0.5 && _showStory && mounted) {
        setState(() => _showStory = false);
      }
    });
    // 選択後リビール用コントローラ
    _revealCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _messageCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _eventsCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _actionCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadCycleEvents();
    _loadNotTodayCount();
  }

  /// 物語→選択画面のフェード遷移を開始。多重呼び出しは無視。
  void _transitionToChoice() {
    if (_pageCtl.isAnimating || _pageCtl.value > 0) return;
    _pageCtl.forward();
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
    _pageCtl.dispose();
    _revealCtl.dispose();
    _messageCtl.dispose();
    _eventsCtl.dispose();
    _actionCtl.dispose();
    super.dispose();
  }

  /// 選択タップ → GlobalKey で現在位置を測定 → リビール演出を順次再生
  void _onChoiceTap(int i) {
    if (_selectedIndex >= 0) return; // 既に選択済み
    final g = measureMoonOverlayTapGeometry(_titleKey, _choiceKeys[i]);
    if (g == null) return;
    setState(() {
      _selectedIndex = i;
      _titleStartY = g.titleY;
      _titleHeight = g.titleH;
      _choiceStartY = g.itemY;
      _choiceHeight = g.itemH;
    });
    _runRevealSequence();
  }

  Future<void> _runRevealSequence() async {
    await _revealCtl.forward();
    if (!mounted) return;
    await _messageCtl.forward();
    if (!mounted) return;
    await _eventsCtl.forward();
    if (!mounted) return;
    // 最後に確定ボタンをフェードイン。ユーザーのタップで _setIntention を実行。
    await _actionCtl.forward();
  }

  @override
  Widget build(BuildContext context) {
    // 共通ページ構造は moon_overlay_shared.dart の moonOverlayPageStructure を共用。
    return moonOverlayPageStructure(
      fadeAnim: _fadeAnim,
      pageAnim: _pageCtl,
      assetPath: 'assets/horo-bg/new_moon_bg.webp',
      showStory: _showStory,
      showReveal: _selectedIndex >= 0,
      storyBuilder: _buildStoryContent,
      selectionBuilder: _buildChoiceList,
      revealBuilder: _buildRevealLayout,
    );
  }

  // ══════════════════════════════════════════════════
  // Story content (backdrop は外側で付与済みなのでここでは付けない)
  // ══════════════════════════════════════════════════
  Widget _buildStoryContent(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final paragraphs = CycleStoryTexts.getNewMoon(locale);

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: MoonScrollingStory(
              fadeAnim: _fadeAnim,
              label: 'NEW MOON',
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
  // 選択肢リスト (初期画面)
  // ══════════════════════════════════════════════════
  Widget _buildChoiceList(BuildContext context) {
    final monthData = CelestialEvents.getMonth(widget.month);
    final themes = CelestialEvents.getThemes(widget.month);
    final sign = monthData?.newMoonSign ?? '';
    final signJP = monthData?.newMoonSignJP ?? '';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 14),
            _titleBlock(keyRef: _titleKey, sign: sign, signJP: signJP),
            // 月背景にかぶらないよう、削除した惑星イベントブロック分の縦スペースを確保
            const SizedBox(height: 110),
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
              return Padding(
                key: _choiceKeys[i],
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: GestureDetector(
                  onTap: () => _onChoiceTap(i),
                  child: _choiceCardWidget(
                    isSelected: false,
                    isSkipChoice: isSkipChoice,
                    titleJP: isSkipChoice ? '特別決めない' : themes.jp[i],
                    titleEN: isSkipChoice ? 'No particular theme' : themes.en[i],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            // Not today (リンク風表示 + 累計3回で「特別決めない」として保存)
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Not today',
                    style: TextStyle(
                      color: SolaraColors.textSecondary,
                      fontSize: 14,
                      letterSpacing: 1.2,
                      decoration: TextDecoration.underline,
                      decorationColor: SolaraColors.textSecondary,
                    ),
                  ),
                  if (_notTodayCount >= 2) ...[
                    const SizedBox(height: 3),
                    Text(
                      'もう一度押すと「特別決めない」で開始',
                      style: TextStyle(
                        color: SolaraColors.textSecondary.withValues(alpha: 0.72),
                        fontSize: 11,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // 選択後のリビール画面
  // タイトルと選択肢を中央に寄せ、メッセージ→惑星イベントを順次表示
  // ══════════════════════════════════════════════════
  Widget _buildRevealLayout(BuildContext context) {
    final monthData = CelestialEvents.getMonth(widget.month);
    final themes = CelestialEvents.getThemes(widget.month);
    final sign = monthData?.newMoonSign ?? '';
    final signJP = monthData?.newMoonSignJP ?? '';
    final isSkip = _selectedIndex == themes.en.length;
    final events = _cycleEvents ?? monthData?.events ?? [];
    final size = MediaQuery.of(context).size;

    // ゴール位置 — 選択肢を画面中央付近に据え、タイトルはその上 (満月と同じロジック)
    final titleHeight = _titleHeight ?? 60;
    final choiceHeight = _choiceHeight ?? 60;
    final choiceTargetY = size.height * 0.42;
    final titleTargetY = choiceTargetY - titleHeight - 28;

    return AnimatedBuilder(
      animation: _revealCtl,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_revealCtl.value);
        final titleY = lerpDouble(_titleStartY!, titleTargetY, t)!;
        final choiceY = lerpDouble(_choiceStartY!, choiceTargetY, t)!;
        return Stack(
          fit: StackFit.expand,
          children: [
            // タイトル (New Moon in ARIES)
            Positioned(
              left: 0,
              right: 0,
              top: titleY,
              child: Center(
                child: _titleBlock(sign: sign, signJP: signJP),
              ),
            ),
            // 選択された選択肢
            Positioned(
              left: 28,
              right: 28,
              top: choiceY,
              child: _choiceCardWidget(
                isSelected: true,
                isSkipChoice: isSkip,
                titleJP: isSkip ? '特別決めない' : themes.jp[_selectedIndex],
                titleEN: isSkip ? 'No particular theme' : themes.en[_selectedIndex],
              ),
            ),
            // 選択肢の下: 詩的メッセージ → 惑星イベント → SET INTENTION ボタン
            // 全体スクロール可。ボタンは天体イベントの下、最下部にスクロールして到達。
            Positioned(
              left: 28,
              right: 28,
              top: choiceY + choiceHeight + 26,
              bottom: 0,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _messageCtl,
                      child: _revealMessage(context),
                    ),
                    const SizedBox(height: 22),
                    FadeTransition(
                      opacity: _eventsCtl,
                      child: _revealEvents(events),
                    ),
                    const SizedBox(height: 36),
                    FadeTransition(
                      opacity: _actionCtl,
                      child: Center(
                        child: GestureDetector(
                          onTap: _setIntention,
                          behavior: HitTestBehavior.opaque,
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ══════════════════════════════════════════════════
  // 共通 widget builder
  // ══════════════════════════════════════════════════

  /// タイトルブロック (英語大見出し + 日本語サブ)
  Widget _titleBlock({
    Key? keyRef,
    required String sign,
    required String signJP,
  }) {
    return Container(
      key: keyRef,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            '$signJPの新月',
            style: const TextStyle(
              color: SolaraColors.solaraGold,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// 選択肢カード (選択前/後で見た目同じ、isSelected で枠色が変わる)
  /// 外枠は moon_overlay_shared.dart の moonOverlaySelectableCard を共用。
  Widget _choiceCardWidget({
    required bool isSelected,
    required bool isSkipChoice,
    required String titleJP,
    required String titleEN,
  }) {
    return moonOverlaySelectableCard(
      isSelected: isSelected,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleJP,
            style: TextStyle(
              color: isSelected
                  ? SolaraColors.solaraGold
                  : SolaraColors.textPrimary,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            titleEN,
            style: TextStyle(
              color: SolaraColors.textSecondary.withValues(alpha: 0.8),
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 詩的メッセージ (選択後フェードイン) — 共通実装は moon_overlay_shared.dart
  Widget _revealMessage(BuildContext context) => revealPoeticMessage(
        context,
        ja: 'あなたの選んだ道は、すべて正しい。\n星々はあなたを照らし、導いている。',
        en: 'Every path you choose is right.\nThe stars light your way.',
      );

  /// 惑星イベント一覧 (選択後フェードイン)
  Widget _revealEvents(List<CelestialEvent> events) {
    if (events.isEmpty) return const SizedBox.shrink();
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

