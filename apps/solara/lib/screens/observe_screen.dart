import 'dart:math';
import 'package:flutter/material.dart';
import '../models/daily_reading.dart';
import '../models/tarot_card.dart';
import '../utils/moon_phase.dart';
import '../utils/solara_storage.dart';
import '../utils/tarot_data.dart';

import 'observe/observe_constants.dart';
import 'observe/observe_card_widgets.dart';
import 'observe/observe_history.dart';

/// Tarot Draw screen — matches tarot.html exactly.
/// Layout: Inner tabs (TAROT DRAW / HISTORY) → Card scene → Tap hint → Stella → Reading panel
class ObserveScreen extends StatefulWidget {
  const ObserveScreen({super.key});
  @override
  State<ObserveScreen> createState() => _ObserveScreenState();
}

class _ObserveScreenState extends State<ObserveScreen>
    with TickerProviderStateMixin {
  int _innerTab = 0; // 0=draw, 1=history
  bool _cardFlipped = false;
  TarotCard? _drawnCard;
  bool _alreadyDrawnToday = false;

  // HTML: cardPulse animation 3s infinite
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);
  late final Animation<double> _pulseOpacity =
      Tween(begin: 0.5, end: 0.8).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  late final Animation<double> _pulseScale =
      Tween(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

  // HTML: 3D card flip — rotateY(180deg) with 0.8s cubic-bezier(0.4,0,0.2,1)
  late final AnimationController _flipCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final Animation<double> _flipAnimation = Tween(begin: 0.0, end: 1.0)
      .animate(CurvedAnimation(parent: _flipCtrl, curve: const Cubic(0.4, 0, 0.2, 1)));

  // Reading typewriter
  String _readingText = '';
  String _stellaText = '';
  int _typedChars = 0;
  bool _typingDone = false;

  // History
  List<DailyReading> _history = [];

  @override
  void initState() {
    super.initState();
    _flipAnimation.addListener(() => setState(() {}));
    _checkTodayReading();
    _loadHistory();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _flipCtrl.dispose();
    super.dispose();
  }

  // ── HTML exact: generateStellaMsg(card, planetJP) ──
  String _generateStellaMsg(TarotCard card) {
    final pInfo = planetInfo[card.planet];
    final planetJP = pInfo?[1] ?? '星';
    final templates = [
      '『${card.nameJP}』が今日の種。${card.keyword}のエネルギーが$planetJPを通じてあなたに届いているよ。',
      '今日のSeedは『${card.nameJP}』。$planetJPが${card.keyword}の光を運んでいる。心を開いてみて。',
      '『${card.nameJP}』が目覚めた。$planetJPの力が${card.keyword}を引き出している。',
      '今日は$planetJPが活性化。『${card.nameJP}』の${card.keyword}を味方につけて。',
    ];
    final d = DateTime.now();
    final seed = d.year * 10000 + d.month * 100 + d.day;
    return templates[seed % templates.length];
  }

  Future<void> _checkTodayReading() async {
    final today = await SolaraStorage.getTodayReading();
    if (today != null && mounted) {
      final card = TarotData.getCard(today.cardId);
      setState(() {
        _drawnCard = card;
        _cardFlipped = true;
        _alreadyDrawnToday = true;
        _stellaText = today.stellaMsg.isNotEmpty ? today.stellaMsg : _generateStellaMsg(card);
      });
      _flipCtrl.value = 1.0;
      _generateReading(card);
    }
  }

  Future<void> _loadHistory() async {
    final readings = await SolaraStorage.loadCurrentReadings();
    if (mounted) setState(() => _history = readings);
  }

  Future<void> _drawCard() async {
    if (_alreadyDrawnToday) return;

    final rng = Random();
    final card = TarotData.allCards[rng.nextInt(78)];
    final stellaMsg = _generateStellaMsg(card);

    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final reading = DailyReading(
      date: dateStr,
      cardId: card.id,
      isMajor: card.isMajor,
      moonPhase: MoonPhase.getPhaseDay(now),
      stellaMsg: stellaMsg,
    );
    await SolaraStorage.addReading(reading);

    setState(() {
      _drawnCard = card;
      _cardFlipped = true;
      _alreadyDrawnToday = true;
      _stellaText = stellaMsg;
    });

    _flipCtrl.forward();

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _generateReading(card);
    });

    _loadHistory();
  }

  void _generateReading(TarotCard card) {
    final rng = Random(card.id * 31 + DateTime.now().day);
    final templates = tarotReadings[card.element] ?? tarotReadings['fire']!;
    final template = templates[rng.nextInt(templates.length)];

    _readingText = template.replaceAll('{card}', card.nameJP).replaceAll('{keyword}', card.keyword);

    _typedChars = 0;
    _typingDone = false;
    _startTypewriter();
  }

  void _startTypewriter() {
    Future.delayed(const Duration(milliseconds: 25), () {
      if (!mounted) return;
      if (_typedChars < _readingText.length) {
        setState(() => _typedChars++);
        _startTypewriter();
      } else {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => _typingDone = true);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -1), radius: 1.1,
          colors: [Color(0xFF0F2850), Color(0xFF080C14)],
          stops: [0.0, 0.55],
        ),
      ),
      child: SafeArea(
        child: Column(children: [
          _buildInnerTabs(),
          Expanded(
            child: _innerTab == 0 ? _buildDrawPanel() : ObserveHistoryPanel(
              history: _history,
              onCleared: _loadHistory,
            ),
          ),
        ]),
      ),
    );
  }

  // ========================================
  // Inner Tabs: 🃏 TAROT DRAW / 📜 HISTORY
  // ========================================

  Widget _buildInnerTabs() {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xE60F0F1E),
        border: Border(bottom: BorderSide(color: Color(0x1FC9A84C))),
      ),
      child: Row(children: [
        _innerTabBtn(0, '🃏 TAROT DRAW'),
        _innerTabBtn(1, '📜 HISTORY'),
      ]),
    );
  }

  Widget _innerTabBtn(int idx, String label) {
    final active = _innerTab == idx;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _innerTab = idx),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: active ? const Border(bottom: BorderSide(color: Color(0xFFC9A84C), width: 2)) : null,
        ),
        child: Text(label, style: TextStyle(
          color: active ? const Color(0xFFC9A84C) : const Color(0xFF555555),
          fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1,
        )),
      ),
    ));
  }

  // ========================================
  // Draw Panel
  // ========================================

  Widget _buildDrawPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(children: [
        GestureDetector(
          onTap: _drawCard,
          child: SizedBox(
            width: 200, height: 320,
            child: Observe3DCard(
              flipAnimation: _flipAnimation,
              pulseOpacity: _pulseOpacity,
              pulseScale: _pulseScale,
              pulseCtrl: _pulseCtrl,
              drawnCard: _drawnCard,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Card info below card (moved from inside card front)
        if (_cardFlipped && _drawnCard != null)
          ObserveCardInfo(card: _drawnCard!),
        if (!_alreadyDrawnToday)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('👆 タップしてカードを引く', style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
          ),
        if (_alreadyDrawnToday && !_cardFlipped)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('✓ 本日のカードは引き済み',
                style: TextStyle(fontSize: 13, color: Color(0xFF666666), letterSpacing: 0.5),
                textAlign: TextAlign.center),
          ),
        const SizedBox(height: 12),
        if (_cardFlipped && _drawnCard != null) _buildStellaMsg(),
        const SizedBox(height: 16),
        if (_readingText.isNotEmpty) _buildReadingPanel(),
      ]),
    );
  }

  // ========================================
  // Stella Message
  // ========================================

  Widget _buildStellaMsg() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0x800F0F1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1AC9A84C)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('✨ Stella', style: TextStyle(fontSize: 10, color: Color(0xFFC9A84C), letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(_stellaText, style: const TextStyle(fontSize: 13, color: Color(0xFFCCCCCC), height: 1.6)),
      ]),
    );
  }

  // ========================================
  // Reading Panel
  // ========================================

  Widget _buildReadingPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0x990F0F1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x1FC9A84C),
                border: Border.all(color: const Color(0x40C9A84C)),
              ),
              child: const Center(child: Text('🔮', style: TextStyle(fontSize: 18)))),
          const SizedBox(width: 10),
          const Text('✦ TAROT READING',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFC9A84C), letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 14),
        Text(_readingText.substring(0, _typedChars),
            style: const TextStyle(fontSize: 13, height: 1.85, color: Color(0xD9E8E0D0))),
        if (!_typingDone)
          const Text('▋', style: TextStyle(fontSize: 13, color: Color(0xFFC9A84C))),
      ]),
    );
  }
}
