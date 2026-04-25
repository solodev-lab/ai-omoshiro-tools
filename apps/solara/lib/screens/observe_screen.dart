import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/daily_reading.dart';
import '../models/tarot_card.dart';
import '../utils/fortune_api.dart';
import '../utils/moon_phase.dart';
import '../utils/solara_storage.dart';
import '../utils/tarot_data.dart';

import 'observe/observe_constants.dart';
import 'observe/observe_card_widgets.dart';
import 'observe/observe_history.dart';
import 'observe/tarot_altar_scene.dart';

/// Tarot Draw screen — matches tarot.html exactly.
/// Layout: Inner tabs (TAROT DRAW / HISTORY) → Card scene → Tap hint → Reading panel
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
  bool _drawnReversed = false; // 正逆位置（true=逆位置）
  bool _alreadyDrawnToday = false;
  bool _readingLoading = false; // /tarot 呼び出し中
  bool _readingFromApi = false; // true=Gemini生成 / false=静的fallback

  // ローディング演出: 4つのメッセージを4秒ごとに切り替え
  static const _loadingMessages = [
    '星々があなたへの言葉を紡いでいます',
    '天体の囁きに耳を澄ませています',
    'カードの神秘を解き明かしています',
    '今日のあなたの意味を結晶化しています',
  ];
  int _loadingMsgIdx = 0;
  Timer? _loadingMsgTimer;

  void _startLoadingMessageRotation() {
    _loadingMsgIdx = 0;
    _loadingMsgTimer?.cancel();
    _loadingMsgTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_readingLoading) {
        timer.cancel();
        return;
      }
      setState(() => _loadingMsgIdx = (_loadingMsgIdx + 1) % _loadingMessages.length);
    });
  }

  void _stopLoadingMessageRotation() {
    _loadingMsgTimer?.cancel();
    _loadingMsgTimer = null;
  }

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
    _loadingMsgTimer?.cancel();
    _pulseCtrl.dispose();
    _flipCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkTodayReading() async {
    final today = await SolaraStorage.getTodayReading();
    if (today != null && mounted) {
      final card = TarotData.getCard(today.cardId);
      setState(() {
        _drawnCard = card;
        _drawnReversed = today.reversed;
        _cardFlipped = true;
        _alreadyDrawnToday = true;
        _readingFromApi = today.reading.isNotEmpty;
      });
      _flipCtrl.value = 1.0;
      if (today.reading.isNotEmpty) {
        // キャッシュ済み: API再呼び出しせず保存テキストをタイプライター再生
        _readingText = today.reading;
        _typedChars = 0;
        _typingDone = false;
        _startTypewriter();
      } else {
        // 旧データ（reading 無し）: 静的フォールバックで補う
        _generateReadingStatic(card, today.reversed);
      }
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
    final reversed = rng.nextBool(); // 50%確率で逆位置

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final moonPhase = MoonPhase.getPhaseDay(now);

    setState(() {
      _drawnCard = card;
      _drawnReversed = reversed;
      _cardFlipped = true;
      _alreadyDrawnToday = true;
      _readingLoading = true;
    });
    _startLoadingMessageRotation();

    _flipCtrl.forward();

    // 一時保存（後で API 応答で更新）
    final reading = DailyReading(
      date: dateStr,
      cardId: card.id,
      isMajor: card.isMajor,
      moonPhase: moonPhase,
      reversed: reversed,
    );
    await SolaraStorage.addReading(reading);
    _loadHistory();

    // カードフリップ完了後に /tarot 呼び出し
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final profile = await SolaraStorage.loadProfile();
    final tarotResult = await fetchTarotReading(
      cardId: card.id,
      reversed: reversed,
      nameJP: card.nameJP,
      nameEN: card.nameEN,
      keyword: card.keyword,
      element: card.element,
      planet: card.planet,
      moonPhase: moonPhase,
      userName: profile?.name,
    );

    if (!mounted) return;

    _stopLoadingMessageRotation();
    if (tarotResult != null && tarotResult.reading.isNotEmpty) {
      // API成功: Gemini生成テキストを表示・保存
      setState(() {
        _readingText = tarotResult.reading;
        _readingLoading = false;
        _readingFromApi = true;
        _typedChars = 0;
        _typingDone = false;
      });
      // ストレージ更新
      reading.reading = _readingText;
      await SolaraStorage.updateReading(reading);
      _startTypewriter();
    } else {
      // API失敗: 静的テンプレートで fallback
      setState(() {
        _readingLoading = false;
        _readingFromApi = false;
      });
      _generateReadingStatic(card, reversed);
    }
  }

  // テスト用: 今日の引きを削除して再抽選可能な状態に戻す
  // 🔴 本番リリース時にこのメソッドと呼び出しボタンを削除すること
  Future<void> _resetTodayReading() async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await SolaraStorage.removeReadingByDate(dateStr);

    if (!mounted) return;
    _stopLoadingMessageRotation();
    setState(() {
      _drawnCard = null;
      _drawnReversed = false;
      _cardFlipped = false;
      _alreadyDrawnToday = false;
      _readingText = '';
      _typedChars = 0;
      _typingDone = false;
      _readingLoading = false;
      _readingFromApi = false;
    });
    _flipCtrl.value = 0.0;
    _loadHistory();
  }

  // 静的フォールバック: API失敗時のみ使用
  void _generateReadingStatic(TarotCard card, bool reversed) {
    final rng = Random(card.id * 31 + DateTime.now().day + (reversed ? 7 : 0));
    final templates = tarotReadings[card.element] ?? tarotReadings['fire']!;
    final template = templates[rng.nextInt(templates.length)];

    final body = template
        .replaceAll('{card}', card.nameJP)
        .replaceAll('{keyword}', card.keyword);
    _readingText = reversed
        ? '【逆位置】$body しかし今は流れに逆らわず、内側に意識を向けることが先決です。'
        : body;

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
    return TarotAltarScene(
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
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, _) {
              final t = _pulseCtrl.value * 2 * pi;
              final dy = sin(t) * 4.0;
              return Transform.translate(
                offset: Offset(0, dy),
                child: Container(
                  width: 200,
                  height: 320,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 30,
                        spreadRadius: 4,
                        offset: Offset(0, 16 - dy * 0.6),
                      ),
                    ],
                  ),
                  child: Observe3DCard(
                    flipAnimation: _flipAnimation,
                    pulseOpacity: _pulseOpacity,
                    pulseScale: _pulseScale,
                    pulseCtrl: _pulseCtrl,
                    drawnCard: _drawnCard,
                    reversed: _drawnReversed,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Card info below card (moved from inside card front)
        if (_cardFlipped && _drawnCard != null)
          ObserveCardInfo(card: _drawnCard!, reversed: _drawnReversed),
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
        // 🔴 本番リリース時に削除: テスト用「今日の引きをリセット」ボタン
        if (_alreadyDrawnToday)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: GestureDetector(
              onTap: _resetTodayReading,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0x55FF6B6B)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('🔄 [DEV] 今日の引きをリセット',
                    style: TextStyle(fontSize: 10, color: Color(0xFFFF8888), letterSpacing: 0.8)),
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (_readingLoading) _buildLoadingIndicator(),
        if (_readingText.isNotEmpty) _buildReadingPanel(),
      ]),
    );
  }

  // ========================================
  // Reading Panel
  // ========================================

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        final t = _pulseCtrl.value; // 0..1 (3秒周期)
        final phase = t * 2 * pi;

        // 星3つを順次点灯（進行感）
        final activeDot = (t * 3).floor() % 3;
        // メッセージ全体に呼吸 opacity (0.55..1.0)
        final breathOpacity = 0.775 + 0.225 * sin(phase);
        // 末尾の点を 1〜3 個で循環
        final dotCount = 1 + (t * 4).floor() % 3;
        final tail = '・' * dotCount;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const RadialGradient(
              colors: [Color(0x33C9A84C), Color(0x110F0F1E), Color(0x000F0F1E)],
              stops: [0.0, 0.6, 1.0],
              radius: 0.9,
            ),
            border: Border.all(color: const Color(0x33C9A84C)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (int i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '✦',
                    style: TextStyle(
                      fontSize: i == activeDot ? 18 : 13,
                      color: Color.fromRGBO(
                        201, 168, 76,
                        i == activeDot ? 1.0 : 0.28,
                      ),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 14),
            Opacity(
              opacity: breathOpacity.clamp(0.5, 1.0),
              child: Text(
                _loadingMessages[_loadingMsgIdx],
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFFE8E0D0),
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.2,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tail,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFFC9A84C),
                letterSpacing: 6,
                height: 1.0,
              ),
            ),
          ]),
        );
      },
    );
  }

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
        if (_typingDone && !_readingFromApi) ...[
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: const [
            Text('⚠ オフラインモード（簡易表示）',
                style: TextStyle(fontSize: 9, color: Color(0xFF666666), letterSpacing: 0.8)),
          ]),
        ],
      ]),
    );
  }
}
