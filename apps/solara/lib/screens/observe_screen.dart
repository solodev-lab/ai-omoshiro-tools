import 'dart:math';
import 'package:flutter/material.dart';
import '../models/daily_reading.dart';
import '../models/tarot_card.dart';
import '../utils/moon_phase.dart';
import '../utils/solara_storage.dart';
import '../utils/tarot_data.dart';

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
      Tween(begin: 0.5, end: 0.8).animate(CurvedAnimation(
    parent: _pulseCtrl,
    curve: Curves.easeInOut,
  ));
  late final Animation<double> _pulseScale =
      Tween(begin: 1.0, end: 1.05).animate(CurvedAnimation(
    parent: _pulseCtrl,
    curve: Curves.easeInOut,
  ));

  // HTML: 3D card flip — rotateY(180deg) with 0.8s cubic-bezier(0.4,0,0.2,1)
  late final AnimationController _flipCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final Animation<double> _flipAnimation = Tween(begin: 0.0, end: 1.0)
      .animate(CurvedAnimation(
    parent: _flipCtrl,
    curve: const Cubic(0.4, 0, 0.2, 1),
  ));

  // Reading typewriter
  String _readingText = '';
  String _adviceText = '';
  String _stellaText = '';
  int _typedChars = 0;
  bool _typingDone = false;

  // History
  List<DailyReading> _history = [];
  String? _expandedHistory; // date string of expanded card

  // HTML exact: TAROT_READINGS templates
  static const _readings = <String, List<String>>{
    'fire': [
      '炎のエネルギーが今日のあなたを包んでいます。{card}が示すのは、内なる情熱を解放する時が来たということ。行動力と創造性が高まるこの瞬間、新しいプロジェクトや挑戦を始めるには最高のタイミングです。ただし、感情が高ぶりやすい時期でもあるので、衝動的な判断は一呼吸おいてから。あなたの{keyword}は、周囲にも良い影響を与えるでしょう。',
      '{card}の炎があなたの道を照らしています。今日は自信を持って前に進む日。リーダーシップを発揮することで、停滞していた物事が動き始めます。特に午後は創造的なエネルギーが最高潮に達するので、大切な決断や表現活動に適しています。{keyword}の力が、あなたを正しい方向に導いてくれるでしょう。',
    ],
    'water': [
      '深い水のエネルギーが今日のあなたを静かに支えています。{card}は感受性と直感が冴える暗示。普段は気づかない微細なサインに注目してみてください。夢や直感がメッセージを運んでくることがあります。感情の波を否定せず、そのまま受け入れることで、内面の知恵にアクセスできるでしょう。{keyword}が今日のテーマです。',
      '{card}が水面に映し出す真実は、あなたの内側にあります。今日は内省と癒しの日。自分自身に優しくすること、水辺に出かけることが心のバランスを整えます。直感が導く先に重要な気づきがあるかもしれません。{keyword}を胸に、静かに一日を過ごしてみましょう。',
    ],
    'air': [
      '風のエレメントがあなたの知性を刺激しています。{card}は情報収集と知的な交流に適した日を示しています。言葉の力が増幅されるので、重要な会話や文章作成に良いタイミング。新しいアイデアが突然閃くかもしれません。{keyword}の風に乗って、思考を自由に羽ばたかせましょう。',
      '{card}が運ぶ軽やかな風は、あなたのコミュニケーション力を高めます。今日は学びと対話の日。好奇心のままに新しい知識を吸収し、周囲と積極的に意見を交わしましょう。{keyword}がキーワード。多角的な視点が最善の答えに導いてくれるでしょう。',
    ],
    'earth': [
      '大地のエネルギーがあなたに安定と実りをもたらします。{card}は堅実な一歩を踏み出す時を告げています。今日は地に足をつけた行動が吉。財務管理、健康への配慮、長期計画の見直しに適しています。{keyword}の力で、着実に土台を固めていきましょう。焦る必要はありません。',
      '{card}が示す大地の恵みは、忍耐と誠実さの上に実ります。今日は現実的な視点で物事を見つめ直す日。無駄を省き、本当に大切なものに集中しましょう。身体を動かすことで、新たなエネルギーが湧いてきます。{keyword}を意識して、一歩一歩確実に前進を。',
    ],
  };

  // HTML exact: TAROT_ADVICES
  static const _advices = [
    '🧭 {dir}の方角にエネルギーが集中。可能なら足を運んでみて。',
    '🌟 今日のラッキーアクション: {keyword}を意識した行動が幸運を呼びます。',
    '✦ {dir}方位が吉。この方角でのインスピレーションを大切に。',
  ];

  // HTML exact: PLANET_SYMBOLS
  static const _planetInfo = <String, List<String>>{
    // key: [symbol, nameJP, color hex]
    'sun':     ['☉', '太陽',   'FFD700'],
    'moon':    ['☽', '月',     'C0C0C0'],
    'mercury': ['☿', '水星',   '87CEEB'],
    'venus':   ['♀', '金星',   'FF69B4'],
    'mars':    ['♂', '火星',   'FF4500'],
    'jupiter': ['♃', '木星',   'FFA500'],
    'saturn':  ['♄', '土星',   '808080'],
    'uranus':  ['♅', '天王星', '00CED1'],
    'neptune': ['♆', '海王星', '4169E1'],
    'pluto':   ['♇', '冥王星', '8B0000'],
  };

  // HTML exact: ELEMENT_* maps
  static const _elementColors = <String, int>{
    'fire': 0xFFFF6B35,
    'water': 0xFF4169E1,
    'air': 0xFF87CEEB,
    'earth': 0xFF2E8B57,
  };
  static const _elementNames = <String, String>{
    'fire': '火', 'water': '水', 'air': '風', 'earth': '地',
  };
  static const _elementEmojis = <String, String>{
    'fire': '🔥', 'water': '🌊', 'air': '💨', 'earth': '🌿',
  };

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
    final pInfo = _planetInfo[card.planet];
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
        _stellaText = today.stellaMsg.isNotEmpty
            ? today.stellaMsg
            : _generateStellaMsg(card);
      });
      // Show card front immediately (no animation)
      _flipCtrl.value = 1.0;
      _generateReading(card);
    }
  }

  Future<void> _loadHistory() async {
    final readings = await SolaraStorage.loadCurrentReadings();
    if (mounted) setState(() => _history = readings);
  }

  Future<void> _drawCard() async {
    if (_alreadyDrawnToday) return; // HTML: if (isDrawn) return

    final rng = Random();
    final card = TarotData.allCards[rng.nextInt(78)];
    final stellaMsg = _generateStellaMsg(card);

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
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

    // HTML: 3D flip animation
    _flipCtrl.forward();

    // Show Stella + reading after flip (HTML: setTimeout 900ms)
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _generateReading(card);
    });

    _loadHistory();
  }

  void _generateReading(TarotCard card) {
    final rng = Random(card.id * 31 + DateTime.now().day);
    final templates = _readings[card.element] ?? _readings['fire']!;
    final template = templates[rng.nextInt(templates.length)];

    _readingText = template
        .replaceAll('{card}', card.nameJP)
        .replaceAll('{keyword}', card.keyword);

    final adviceTemplate = _advices[rng.nextInt(_advices.length)];
    const dirs = ['北', '北東', '東', '南東', '南', '南西', '西', '北西'];
    final dir = dirs[rng.nextInt(dirs.length)];
    _adviceText = adviceTemplate
        .replaceAll('{keyword}', card.keyword)
        .replaceAll('{dir}', dir);

    _typedChars = 0;
    _typingDone = false;
    _startTypewriter();
  }

  void _startTypewriter() {
    Future.delayed(const Duration(milliseconds: 25), () {
      // HTML: 25ms interval
      if (!mounted) return;
      if (_typedChars < _readingText.length) {
        setState(() => _typedChars++);
        _startTypewriter();
      } else {
        // HTML: setTimeout(function() { advice.textContent = adviceText; }, 300)
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => _typingDone = true);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // HTML: .phone-frame.cosmic-bg — radial-gradient(ellipse at 50% 0%, #0f2850 0%, #080C14 55%)
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
          // HTML: inner-tab-nav (40px height)
          _buildInnerTabs(),
          // Content area
          Expanded(
            child:
                _innerTab == 0 ? _buildDrawPanel() : _buildHistoryPanel(),
          ),
        ]),
      ),
    );
  }

  // ========================================
  // Inner Tabs: 🃏 TAROT DRAW / 📜 HISTORY
  // HTML: .inner-tab-nav { height:40px; bg:rgba(15,15,30,0.9); border-bottom:1px rgba(201,168,76,0.12) }
  // ========================================

  Widget _buildInnerTabs() {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xE60F0F1E), // rgba(15,15,30,0.9)
        border: Border(
            bottom:
                BorderSide(color: Color(0x1FC9A84C))), // rgba(201,168,76,0.12)
      ),
      child: Row(children: [
        _innerTabBtn(0, '🃏 TAROT DRAW'),
        _innerTabBtn(1, '📜 HISTORY'),
      ]),
    );
  }

  Widget _innerTabBtn(int idx, String label) {
    final active = _innerTab == idx;
    return Expanded(
        child: GestureDetector(
      onTap: () => setState(() => _innerTab = idx),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: active
              ? const Border(
                  bottom: BorderSide(color: Color(0xFFC9A84C), width: 2))
              : null,
        ),
        // HTML: font-size 12px, font-weight 500, letter-spacing 1px
        child: Text(label,
            style: TextStyle(
              color: active
                  ? const Color(0xFFC9A84C)
                  : const Color(0xFF555555),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            )),
      ),
    ));
  }

  // ========================================
  // Draw Panel
  // HTML: .draw-panel { flex-col, center, padding:20px 20px 30px, max-width:500 }
  // ========================================

  Widget _buildDrawPanel() {
    return SingleChildScrollView(
      // HTML: .draw-panel { padding:20px 20px 30px }
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(children: [
        // HTML: .card-scene { width:200; height:320; perspective:800px }
        GestureDetector(
          onTap: _drawCard,
          child: SizedBox(
            width: 200,
            height: 320,
            child: _build3DCard(),
          ),
        ),

        const SizedBox(height: 8),

        // HTML: .tap-hint "👆 タップしてカードを引く" (font-size:11px, color:#555)
        if (!_alreadyDrawnToday)
          const Text('👆 タップしてカードを引く',
              style: TextStyle(fontSize: 11, color: Color(0xFF555555))),

        // HTML: .drawn-msg "✓ 本日のカードは引き済み" (font-size:13px, color:#666, letter-spacing:0.5px)
        if (_alreadyDrawnToday)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('✓ 本日のカードは引き済み',
                style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                    letterSpacing: 0.5),
                textAlign: TextAlign.center),
          ),

        const SizedBox(height: 12),

        // HTML: .stella-msg (shown after card flip, opacity 0→1)
        if (_cardFlipped && _drawnCard != null) _buildStellaMsg(),

        const SizedBox(height: 16),

        // HTML: .tarot-reading-panel
        if (_readingText.isNotEmpty) _buildReadingPanel(),
      ]),
    );
  }

  // ========================================
  // 3D Card — perspective flip
  // HTML: perspective:800px, rotateY(180deg), transition 0.8s cubic-bezier(0.4,0,0.2,1)
  // ========================================

  Widget _build3DCard() {
    final angle = _flipAnimation.value * pi; // 0 → π (180deg)
    final showFront = angle > pi / 2;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.00125) // perspective ~800px (1/800)
        ..rotateY(angle),
      child: showFront && _drawnCard != null
          ? Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(pi), // counter-rotate so text isn't mirrored
              child: _buildCardFront(_drawnCard!),
            )
          : _buildCardBack(),
    );
  }

  // ========================================
  // Card Back
  // HTML: gradient(135deg,#1a1a3e,#0d0d2b), border:2px solid #C9A84C, border-radius:14px
  //   pattern: 160x260, border:1px rgba(201,168,76,0.3), radius:8px
  //   symbol: "✨" 48px, animation:cardPulse 3s (opacity 0.5↔0.8, scale 1↔1.05)
  //   corners: inset:8px, border:1px rgba(201,168,76,0.15), radius:4px
  //   stars: ✦ ×4 at corners, 10px, #C9A84C, opacity:0.3
  // ========================================

  Widget _buildCardBack() {
    return Container(
      key: const ValueKey('back'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A3E), Color(0xFF0D0D2B)],
        ),
        border: Border.all(color: const Color(0xFFC9A84C), width: 2),
      ),
      child: Center(
          child: Container(
        width: 160,
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x4DC9A84C)), // rgba(201,168,76,0.3)
          gradient: const RadialGradient(
            colors: [Color(0x146B5CE7), Colors.transparent], // rgba(107,92,231,0.08)
            radius: 0.7,
          ),
        ),
        child: Stack(children: [
          // HTML: card-back-symbol ✨ with cardPulse animation
          Center(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, child) => Opacity(
                opacity: _pulseOpacity.value,
                child: Transform.scale(
                  scale: _pulseScale.value,
                  child:
                      const Text('✨', style: TextStyle(fontSize: 48)),
                ),
              ),
            ),
          ),
          // HTML: card-back-corners { inset:8px, border:1px rgba(201,168,76,0.15), radius:4px }
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: const Color(0x26C9A84C)), // rgba(201,168,76,0.15)
              ),
            ),
          ),
          // HTML: card-back-star ✦ ×4 at corners (font-size:10px, color:#C9A84C, opacity:0.3)
          const Positioned(
              top: 4,
              left: 4,
              child: Text('✦',
                  style: TextStyle(
                      fontSize: 10, color: Color(0x4DC9A84C)))),
          const Positioned(
              top: 4,
              right: 4,
              child: Text('✦',
                  style: TextStyle(
                      fontSize: 10, color: Color(0x4DC9A84C)))),
          const Positioned(
              bottom: 4,
              left: 4,
              child: Text('✦',
                  style: TextStyle(
                      fontSize: 10, color: Color(0x4DC9A84C)))),
          const Positioned(
              bottom: 4,
              right: 4,
              child: Text('✦',
                  style: TextStyle(
                      fontSize: 10, color: Color(0x4DC9A84C)))),
        ]),
      )),
    );
  }

  // ========================================
  // Card Front
  // HTML: gradient(180deg,#1a1a3e,#0d0d2b), border:2px solid [element色], radius:14px, padding:16px
  // ========================================

  Widget _buildCardFront(TarotCard card) {
    // HTML: card-front border color = element color (fire=#FF6B35 etc)
    final borderColor =
        Color(_elementColors[card.element] ?? 0xFFC9A84C);
    final pInfo = _planetInfo[card.planet];
    final planetColor =
        pInfo != null ? Color(int.parse('FF${pInfo[2]}', radix: 16)) : const Color(0xFFC9A84C);
    // HTML: suit label — isMajor ? "MAJOR" : suit.toUpperCase()
    final suitLabel = card.isMajor
        ? 'MAJOR'
        : (card.suit?.toUpperCase() ?? '');

    return Container(
      key: ValueKey('front-${card.id}'),
      padding: const EdgeInsets.all(16), // HTML: padding 16px
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A3E), Color(0xFF0D0D2B)],
        ),
        border: Border.all(color: borderColor, width: 2), // HTML: element色で動的変更
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        // HTML: card-element-badge — "🔥 火 · MAJOR" (font-size:11px, color:#aaa, letter-spacing:1.5)
        Text(
          '${_elementEmojis[card.element] ?? ''} ${_elementNames[card.element] ?? ''} · $suitLabel',
          style: const TextStyle(
              fontSize: 11, color: Color(0xFFAAAAAA), letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        // カード画像を表示
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(card.imagePath, height: 120, fit: BoxFit.contain),
        ),
        const SizedBox(height: 8),
        // HTML: card-name-en (14px, #C9A84C, letter-spacing:2, weight:600)
        Text(card.displayName,
            style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFC9A84C),
                letterSpacing: 2,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        // HTML: card-name-jp (18px, #E8E0D0, weight:300)
        Text(card.nameJP,
            style: const TextStyle(
                fontSize: 18,
                color: Color(0xFFE8E0D0),
                fontWeight: FontWeight.w300)),
        const SizedBox(height: 8),
        // HTML: card-keyword (13px, #999, italic)
        Text(card.keyword,
            style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF999999),
                fontStyle: FontStyle.italic)),
        const SizedBox(height: 12),
        // HTML: card-planet-line — "<colored symbol> nameJP Line" (11px, #888)
        if (pInfo != null)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(pInfo[0],
                style: TextStyle(fontSize: 11, color: planetColor)),
            const SizedBox(width: 4),
            Text('${pInfo[1]} Line',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF888888))),
          ]),
      ]),
    );
  }

  // ========================================
  // Stella Message
  // HTML: .stella-msg { bg:rgba(15,15,30,0.5); border:1px rgba(201,168,76,0.1); radius:14px; padding:16px; opacity:0→1 }
  //   .stella-label { 10px, #C9A84C, letter-spacing:1px } — "✨ Stella"
  //   .stella-text  { 13px, #ccc, line-height:1.6 } — generateStellaMsg() output
  // ========================================

  Widget _buildStellaMsg() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0x800F0F1E), // rgba(15,15,30,0.5)
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0x1AC9A84C)), // rgba(201,168,76,0.1)
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // HTML: .stella-label
        const Text('✨ Stella',
            style: TextStyle(
                fontSize: 10,
                color: Color(0xFFC9A84C),
                letterSpacing: 1)),
        const SizedBox(height: 6),
        // HTML: .stella-text — uses generateStellaMsg with 4 templates
        Text(_stellaText,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFFCCCCCC), height: 1.6)),
      ]),
    );
  }

  // ========================================
  // Reading Panel
  // HTML: .tarot-reading-panel { bg:rgba(15,15,30,0.6); border:1px rgba(201,168,76,0.2); radius:16px; padding:18px 16px }
  // ========================================

  Widget _buildReadingPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18), // HTML: 18px 16px
      decoration: BoxDecoration(
        color: const Color(0x990F0F1E), // rgba(15,15,30,0.6)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0x33C9A84C)), // rgba(201,168,76,0.2)
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // HTML: .reading-header { flex, gap:10px }
        Row(children: [
          // HTML: .reading-icon { 36x36 circle, bg:rgba(201,168,76,0.12), border:1px rgba(201,168,76,0.25), "🔮" 18px }
          Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x1FC9A84C),
                border: Border.all(color: const Color(0x40C9A84C)),
              ),
              child: const Center(
                  child: Text('🔮', style: TextStyle(fontSize: 18)))),
          const SizedBox(width: 10),
          // HTML: .reading-title { 13px, 700, #C9A84C, letter-spacing:1.5px }
          const Text('✦ TAROT READING',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC9A84C),
                  letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 14),
        // HTML: .reading-body { 13px, line-height:1.85, rgba(232,224,208,0.85) } — typewriter
        Text(_readingText.substring(0, _typedChars),
            style: const TextStyle(
                fontSize: 13, height: 1.85, color: Color(0xD9E8E0D0))),
        // HTML: .reading-typing::after { content:'▋', blink animation }
        if (!_typingDone)
          const Text('▋',
              style: TextStyle(fontSize: 13, color: Color(0xFFC9A84C))),
        if (_typingDone && _adviceText.isNotEmpty) ...[
          const SizedBox(height: 14),
          // HTML: .reading-advice { padding:12px 14px; radius:12px; bg:rgba(201,168,76,0.06); border:1px rgba(201,168,76,0.15); 12px; line-height:1.7; #C9A84C }
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0x0FC9A84C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x26C9A84C)),
            ),
            child: Text(_adviceText,
                style: const TextStyle(
                    fontSize: 12,
                    height: 1.7,
                    color: Color(0xFFC9A84C))),
          ),
        ],
      ]),
    );
  }

  // ========================================
  // History Panel
  // HTML: .history-panel { padding:16px 16px 30px }
  // ========================================

  Widget _buildHistoryPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      child: Column(children: [
        // HTML: .history-header { flex, space-between, mb:14px }
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // HTML: .history-title { 12px, #666, letter-spacing:1.5px }
            const Text('NATAL TAROT HISTORY',
                style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                    letterSpacing: 1.5)),
            // HTML: .history-clear { 10px, #444 } → onclick: confirm('履歴をすべて削除しますか？')
            GestureDetector(
              onTap: _confirmClearHistory,
              child: const Text('CLEAR',
                  style:
                      TextStyle(fontSize: 10, color: Color(0xFF444444))),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // 履歴上限の注意書き
        const Text('※ 履歴は50件までです。古い履歴から自動的に削除されます。',
            style: TextStyle(fontSize: 9, color: Color(0xFF444444))),
        const SizedBox(height: 10),

        if (_history.isEmpty)
          // HTML: .history-empty { text-align:center; padding:60px 20px; color:#444; font-size:13px; line-height:1.8 }
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60, horizontal: 20),
            child: Text(
                'まだ履歴がありません\n\nTAROT DRAW タブでカードを引くと\nここに記録されます',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFF444444), fontSize: 13, height: 1.8)),
          )
        else
          Expanded(
              child: ListView.builder(
            itemCount: _history.length,
            itemBuilder: (ctx, i) {
              // HTML: newest first (hist is stored chronologically, reverse display)
              final r = _history[_history.length - 1 - i];
              return _buildHistoryCard(r);
            },
          )),
      ]),
    );
  }

  // HTML: confirm('履歴をすべて削除しますか？')
  Future<void> _confirmClearHistory() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F1E),
        title: const Text('確認',
            style: TextStyle(color: Color(0xFFE8E0D0), fontSize: 16)),
        content: const Text('履歴をすべて削除しますか？',
            style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('キャンセル',
                  style: TextStyle(color: Color(0xFF888888)))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('削除',
                  style: TextStyle(color: Color(0xFFC9A84C)))),
        ],
      ),
    );
    if (ok == true) {
      await SolaraStorage.clearReadings();
      _loadHistory();
    }
  }

  // ========================================
  // History Card
  // HTML: .history-card { radius:14px; mb:12px; border-left:3px solid [element色]; bg:rgba(15,15,30,0.5) }
  //   data-element colors: fire=#FF6B35, water=#4169E1, air=#87CEEB, earth=#2E8B57
  // ========================================

  Widget _buildHistoryCard(DailyReading r) {
    final card = TarotData.getCard(r.cardId);
    final elementColor =
        Color(_elementColors[card.element] ?? 0xFFC9A84C);
    final expanded = _expandedHistory == r.date;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0x800F0F1E), // rgba(15,15,30,0.5)
        border: Border(left: BorderSide(color: elementColor, width: 3)),
      ),
      child: Column(children: [
        // HTML: .history-card-main { flex, gap:12px, padding:14px 12px, cursor:pointer }
        GestureDetector(
          onTap: () =>
              setState(() => _expandedHistory = expanded ? null : r.date),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(children: [
              // HTML: .history-card-emoji { font-size:28px; width:40px }
              SizedBox(
                  width: 40,
                  child: Text(card.emoji,
                      style: const TextStyle(fontSize: 28),
                      textAlign: TextAlign.center)),
              const SizedBox(width: 12),
              // HTML: .history-card-info
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // HTML: .history-card-name { 14px, #E8E0D0, weight:500 }
                    Text(card.nameJP,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFE8E0D0),
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    // HTML: .history-card-keyword { 11px, #999, italic }
                    Text(card.keyword,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF999999),
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: 4),
                    // HTML: .history-card-meta { 10px, #555, flex, gap:8px }
                    //   span: "[elementEmoji] [elementName]" (element色)
                    //   span: location
                    //   span: date
                    Wrap(spacing: 8, children: [
                      Text(
                        '${_elementEmojis[card.element] ?? ''} ${_elementNames[card.element] ?? ''}',
                        style: TextStyle(
                            fontSize: 10, color: elementColor),
                      ),
                      Text('🏠 自宅',
                          style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF555555))),
                      Text(r.date,
                          style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF555555))),
                    ]),
                  ])),
              // HTML: .history-card-chevron { #555, 14px, rotate(180deg) on expanded }
              Text(expanded ? '▲' : '▼',
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF555555))),
            ]),
          ),
        ),

        // HTML: .history-card-detail (expandable, max-height:0→400px, padding:0→14px, bg:rgba(10,10,20,0.4))
        if (expanded) _buildHistoryDetail(card, r),
      ]),
    );
  }

  // ========================================
  // History Detail
  // HTML: .history-card-detail { padding:14px; bg:rgba(10,10,20,0.4) }
  //   .detail-boost-row { flex, gap:10px, mb:12px }
  //     .detail-boost-text { 11px, #999 } — "planetJP(planetSymbol)"
  //   .sync-section { border-top:1px rgba(255,255,255,0.04), padding-top:10px }
  //     .sync-label { 10px, #666, letter-spacing:1px } — "🔗 SYNCHRONICITY"
  //     textarea.sync-input { padding:8px 10px, bg:rgba(15,15,30,0.6), border:1px rgba(201,168,76,0.12), radius:8px, 12px, #E8E0D0, min-height:50px }
  //     .sync-saved { 9px, #C9A84C }
  // ========================================

  Widget _buildHistoryDetail(TarotCard card, DailyReading r) {
    final pInfo = _planetInfo[card.planet];
    final planetDisplay = pInfo != null ? '${pInfo[1]}(${pInfo[0]})' : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Color(0x660A0A14), // rgba(10,10,20,0.4)
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // HTML: .detail-boost-row — "planetJP(planetSymbol)"
        if (planetDisplay.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(planetDisplay,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF999999))),
          ),

        // HTML: .sync-section { border-top:1px rgba(255,255,255,0.04); padding-top:10px }
        Container(
          padding: const EdgeInsets.only(top: 10),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0x0AFFFFFF))),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // HTML: .sync-label { 10px, #666, letter-spacing:1px } — "🔗 SYNCHRONICITY"
            const Row(children: [
              Text('🔗',
                  style:
                      TextStyle(fontSize: 10, color: Color(0xFF666666))),
              SizedBox(width: 4),
              Text('SYNCHRONICITY',
                  style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF666666),
                      letterSpacing: 1)),
            ]),
            const SizedBox(height: 6),
            // HTML: textarea.sync-input — editable, with save
            _SyncInput(
              initialText: r.synchronicity,
              onChanged: (text) {
                r.synchronicity = text;
                SolaraStorage.updateSynchronicity(r.date, text);
              },
            ),
          ]),
        ),
      ]),
    );
  }
}

// ========================================
// Synchronicity Input (separate StatefulWidget for TextField state)
// HTML: textarea.sync-input { padding:8px 10px; bg:rgba(15,15,30,0.6);
//   border:1px rgba(201,168,76,0.12); radius:8px; 12px; #E8E0D0; min-height:50px }
//   placeholder:"偶然の一致や気づきをメモ..."
//   .sync-saved { 9px, #C9A84C, opacity:0→1 }
// ========================================

class _SyncInput extends StatefulWidget {
  final String initialText;
  final ValueChanged<String> onChanged;

  const _SyncInput({required this.initialText, required this.onChanged});

  @override
  State<_SyncInput> createState() => _SyncInputState();
}

class _SyncInputState extends State<_SyncInput> {
  late final TextEditingController _ctrl;
  bool _showSaved = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    widget.onChanged(text);
    setState(() => _showSaved = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showSaved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      // HTML: textarea.sync-input
      TextField(
        controller: _ctrl,
        onChanged: _onChanged,
        maxLines: null,
        minLines: 2,
        style: const TextStyle(fontSize: 12, color: Color(0xFFE8E0D0)),
        decoration: InputDecoration(
          hintText: '偶然の一致や気づきをメモ...',
          hintStyle: const TextStyle(color: Color(0xFF444444)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          filled: true,
          fillColor: const Color(0x990F0F1E), // rgba(15,15,30,0.6)
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0x1FC9A84C)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0x1FC9A84C)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: Color(0x4DC9A84C)), // rgba(201,168,76,0.3) on focus
          ),
        ),
      ),
      // HTML: .sync-saved { 9px, #C9A84C, opacity:0→1 } — "saved"
      AnimatedOpacity(
        opacity: _showSaved ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('saved',
              style: TextStyle(fontSize: 9, color: Color(0xFFC9A84C))),
        ),
      ),
    ]);
  }
}
