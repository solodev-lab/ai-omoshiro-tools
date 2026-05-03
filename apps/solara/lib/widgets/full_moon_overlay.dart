import 'dart:async';
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
  /// 物語→評価画面のクロスフェード用 (0=物語のみ / 0.5=切替点 / 1=評価画面のみ)
  late AnimationController _pageCtl;
  late Animation<double> _fadeAnim;
  // ── 評価選択後のリビール演出 ─────────────────────────────
  /// 選択済みの評価 (1-3)、未選択時は -1
  int _selectedRating = -1;
  /// タイトル＋選択肢を中央に寄せるスライド (0→1、同時にゴール)
  late AnimationController _revealCtl;
  /// 詩的メッセージのフェードイン
  late AnimationController _messageCtl;
  /// 自動クローズタイマー
  Timer? _dismissTimer;
  // 位置計測用
  final GlobalKey _titleKey = GlobalKey();
  final List<GlobalKey> _ratingKeys = List.generate(3, (_) => GlobalKey());
  double? _titleStartY;
  double? _titleHeight;
  double? _ratingStartY;
  double? _ratingHeight;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    // ページクロスフェード (物語フェードアウト→評価画面フェードイン)
    _pageCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addListener(() {
      if (_pageCtl.value >= 0.5 && _showStory && mounted) {
        setState(() => _showStory = false);
      }
    });
    // 選択後リビール用
    _revealCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _messageCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  /// 物語→評価画面のフェード遷移を開始。多重呼び出しは無視。
  void _transitionToRating() {
    if (_pageCtl.isAnimating || _pageCtl.value > 0) return;
    _pageCtl.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageCtl.dispose();
    _revealCtl.dispose();
    _messageCtl.dispose();
    _dismissTimer?.cancel();
    super.dispose();
  }

  static const _ratingLabels = [
    ('\u{1F30A}', 'Still working on it', '\u307e\u3060\u53d6\u308a\u7d44\u3093\u3067\u3044\u308b'),
    ('\u{2728}', 'Making progress', '\u9032\u5c55\u3042\u308a'),
    ('\u{1F31F}', 'Feeling lighter', '\u8efd\u304f\u306a\u3063\u3066\u304d\u305f'),
  ];

  /// 評価タップ → GlobalKey で現在位置を測定 → リビール演出を順次再生
  void _onRatingTap(int i) {
    if (_selectedRating >= 0) return; // 既に選択済み
    final titleBox = _titleKey.currentContext?.findRenderObject() as RenderBox?;
    final ratingBox = _ratingKeys[i].currentContext?.findRenderObject() as RenderBox?;
    if (titleBox == null || ratingBox == null) return;
    final titlePos = titleBox.localToGlobal(Offset.zero);
    final ratingPos = ratingBox.localToGlobal(Offset.zero);
    setState(() {
      _selectedRating = i + 1; // rating値は1-3
      _titleStartY = titlePos.dy;
      _titleHeight = titleBox.size.height;
      _ratingStartY = ratingPos.dy;
      _ratingHeight = ratingBox.size.height;
    });
    _runRevealSequence();
  }

  Future<void> _runRevealSequence() async {
    await _revealCtl.forward();
    if (!mounted) return;
    await _messageCtl.forward();
    if (!mounted) return;
    // 余韻を残して自動確定 (合計3秒)
    _dismissTimer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted) _submitRating(_selectedRating);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 2026-05-03: FadeTransition 撤廃 (Phase 2 saveLayer leak 対策)。
    return mysticalMoonBackdrop(
      assetPath: 'assets/horo-bg/full_moon_bg.webp',
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
                : (_selectedRating >= 0
                    ? _buildRevealLayout(context)
                    : _buildRatingList(context)),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // Story content (backdrop は外側で付与済み)
  // ══════════════════════════════════════════════════
  Widget _buildStoryContent(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final chosenText = locale.startsWith('ja')
        ? widget.intention.chosenTextJP
        : widget.intention.chosenText;
    final paragraphs = CycleStoryTexts.getFullMoon(locale, chosenText);

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: MoonScrollingStory(
              fadeAnim: _fadeAnim,
              label: 'FULL MOON',
              paragraphs: paragraphs,
              onReachedEnd: _transitionToRating,
            ),
          ),
          // 2026-05-03: FadeTransition 撤廃。
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
            child: GestureDetector(
              onTap: _transitionToRating,
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
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // 評価リスト (初期画面)
  // ══════════════════════════════════════════════════
  Widget _buildRatingList(BuildContext context) {
    final monthData = CelestialEvents.getMonth(widget.month);
    final moonName = monthData?.fullMoonName ?? 'Full Moon';
    final moonNameJP = monthData?.fullMoonNameJP ?? '\u6e80\u6708';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 14),
            _titleBlock(keyRef: _titleKey, moonName: moonName, moonNameJP: moonNameJP),
            // 月背景にかぶらないよう縦スペースを広げる (全体を下に)
            const SizedBox(height: 170),
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
                key: _ratingKeys[i],
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: GestureDetector(
                  onTap: () => _onRatingTap(i),
                  child: _ratingCardWidget(
                    isSelected: false,
                    emoji: emoji,
                    labelJP: labelJP,
                    labelEN: labelEN,
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
                  decoration: TextDecoration.underline,
                  decorationColor: SolaraColors.textSecondary,
                ),
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
    final moonName = monthData?.fullMoonName ?? 'Full Moon';
    final moonNameJP = monthData?.fullMoonNameJP ?? '\u6e80\u6708';
    final idx = _selectedRating - 1;
    final (emoji, labelEN, labelJP) = _ratingLabels[idx];
    final size = MediaQuery.of(context).size;

    // ゴール位置 — 評価カードを画面中央付近に据え、タイトルはその上
    final titleHeight = _titleHeight ?? 60;
    final ratingHeight = _ratingHeight ?? 60;
    final ratingTargetY = size.height * 0.42;
    final titleTargetY = ratingTargetY - titleHeight - 28;

    return AnimatedBuilder(
      animation: _revealCtl,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_revealCtl.value);
        final titleY = lerpDouble(_titleStartY!, titleTargetY, t)!;
        final ratingY = lerpDouble(_ratingStartY!, ratingTargetY, t)!;
        return Stack(
          fit: StackFit.expand,
          children: [
            // タイトル (Pink Moon / 満月)
            Positioned(
              left: 0,
              right: 0,
              top: titleY,
              child: Center(
                child: _titleBlock(moonName: moonName, moonNameJP: moonNameJP),
              ),
            ),
            // 選択された評価カード
            Positioned(
              left: 28,
              right: 28,
              top: ratingY,
              child: _ratingCardWidget(
                isSelected: true,
                emoji: emoji,
                labelJP: labelJP,
                labelEN: labelEN,
              ),
            ),
            // 選択肢の下: 詩的メッセージ (満月は惑星イベント非表示)
            // 2026-05-03: FadeTransition 撤廃。
            Positioned(
              left: 28,
              right: 28,
              top: ratingY + ratingHeight + 26,
              child: _revealMessage(context),
            ),
          ],
        );
      },
    );
  }

  // ══════════════════════════════════════════════════
  // 共通 widget builder
  // ══════════════════════════════════════════════════

  /// タイトルブロック (moonName + moonNameJP)
  Widget _titleBlock({
    Key? keyRef,
    required String moonName,
    required String moonNameJP,
  }) {
    return Container(
      key: keyRef,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
        ],
      ),
    );
  }

  /// 評価カード (選択前/後で見た目同じ、isSelected で枠色が変わる)
  Widget _ratingCardWidget({
    required bool isSelected,
    required String emoji,
    required String labelJP,
    required String labelEN,
  }) {
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
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                labelJP,
                style: TextStyle(
                  color: isSelected
                      ? SolaraColors.solaraGold
                      : SolaraColors.textPrimary,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                labelEN,
                style: const TextStyle(
                  color: SolaraColors.textSecondary,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 詩的メッセージ (選択後フェードイン)
  Widget _revealMessage(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final isJA = locale.startsWith('ja');
    final text = isJA
        ? '今のあなたの感覚は、すべて受けとめられている。\n月はあなたの歩みを祝福している。'
        : 'Whatever you feel now is received.\nThe moon honors your journey.';
    return Text(
      text,
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

  Future<void> _submitRating(int rating) async {
    final updated = widget.intention.copyWith(
      midpoint: MidpointCheck(checkedAt: DateTime.now(), rating: rating),
    );
    await SolaraStorage.saveIntention(updated);
    await SolaraStorage.markOverlayShown('full_moon');
    widget.onDismiss();
  }
}

