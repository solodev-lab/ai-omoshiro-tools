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

class _ObserveScreenState extends State<ObserveScreen> {
  int _innerTab = 0; // 0=draw, 1=history
  bool _cardFlipped = false;
  TarotCard? _drawnCard;
  bool _alreadyDrawnToday = false;

  // Reading typewriter
  String _readingText = '';
  String _adviceText = '';
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

  static const _planetNamesJP = <String, String>{
    'sun':'太陽','moon':'月','mercury':'水星','venus':'金星','mars':'火星',
    'jupiter':'木星','saturn':'土星','uranus':'天王星','neptune':'海王星','pluto':'冥王星',
  };

  @override
  void initState() {
    super.initState();
    _checkTodayReading();
    _loadHistory();
  }

  Future<void> _checkTodayReading() async {
    final today = await SolaraStorage.getTodayReading();
    if (today != null && mounted) {
      final card = TarotData.getCard(today.cardId);
      setState(() {
        _drawnCard = card;
        _cardFlipped = true;
        _alreadyDrawnToday = true;
      });
      _generateReading(card);
    }
  }

  Future<void> _loadHistory() async {
    final readings = await SolaraStorage.loadCurrentReadings();
    setState(() => _history = readings);
  }

  Future<void> _drawCard() async {
    if (_alreadyDrawnToday) return; // HTML: if (isDrawn) return

    final rng = Random();
    final card = TarotData.allCards[rng.nextInt(78)];

    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final reading = DailyReading(
      date: dateStr, cardId: card.id, isMajor: card.isMajor,
      moonPhase: MoonPhase.getPhaseDay(now),
    );
    await SolaraStorage.addReading(reading);

    setState(() {
      _drawnCard = card;
      _cardFlipped = true;
      _alreadyDrawnToday = true;
    });
    _generateReading(card);
    _loadHistory();
  }

  void _generateReading(TarotCard card) {
    final rng = Random(card.id * 31 + DateTime.now().day);
    final templates = _readings[card.element] ?? _readings['fire']!;
    final template = templates[rng.nextInt(templates.length)];
    final planetJP = _planetNamesJP[card.planet] ?? '星';

    _readingText = template
        .replaceAll('{card}', card.nameJP)
        .replaceAll('{keyword}', card.keyword)
        .replaceAll('{planetJP}', planetJP);

    final adviceTemplate = _advices[rng.nextInt(_advices.length)];
    const dirs = ['北','北東','東','南東','南','南西','西','北西'];
    final dir = dirs[rng.nextInt(dirs.length)];
    _adviceText = adviceTemplate.replaceAll('{keyword}', card.keyword).replaceAll('{dir}', dir);

    _typedChars = 0;
    _typingDone = false;
    _startTypewriter();
  }

  void _startTypewriter() {
    Future.delayed(const Duration(milliseconds: 25), () { // HTML: 25ms
      if (!mounted) return;
      if (_typedChars < _readingText.length) {
        setState(() => _typedChars++);
        _startTypewriter();
      } else {
        setState(() => _typingDone = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF080C14), // --bg-deep
      child: SafeArea(
        child: Column(children: [
          // HTML: inner-tab-nav (40px height)
          _buildInnerTabs(),
          // Content area
          Expanded(
            child: _innerTab == 0 ? _buildDrawPanel() : _buildHistoryPanel(),
          ),
        ]),
      ),
    );
  }

  // ── Inner Tabs: 🃏 TAROT DRAW / 📜 HISTORY ──
  Widget _buildInnerTabs() {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xE60F0F1E), // rgba(15,15,30,0.9)
        border: Border(bottom: BorderSide(color: Color(0x1FC9A84C))), // rgba(201,168,76,0.12)
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
        // HTML: font-size 12px, font-weight 500, letter-spacing 1px
        child: Text(label, style: TextStyle(
          color: active ? const Color(0xFFC9A84C) : const Color(0xFF555555),
          fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1,
        )),
      ),
    ));
  }

  // ── Draw Panel ──
  Widget _buildDrawPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(children: [
        // 3D Card (200x320)
        GestureDetector(
          onTap: _drawCard,
          child: SizedBox(
            width: 200, height: 320, // HTML: card-scene 200x320
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 800), // HTML: 0.8s
              child: _cardFlipped && _drawnCard != null
                  ? _buildCardFront(_drawnCard!)
                  : _buildCardBack(),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // HTML: tap-hint "👆 タップしてカードを引く"
        if (!_alreadyDrawnToday)
          const Text('👆 タップしてカードを引く', style: TextStyle(
            fontSize: 11, color: Color(0xFF555555))),

        // HTML: drawn-msg (after draw)
        if (_alreadyDrawnToday && _drawnCard != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('今日のカード: ${_drawnCard!.nameJP}', style: const TextStyle(
              fontSize: 13, color: Color(0xFF666666), letterSpacing: 0.5),
              textAlign: TextAlign.center),
          ),

        const SizedBox(height: 12),

        // HTML: .stella-msg (shown after card flip)
        if (_cardFlipped && _drawnCard != null) _buildStellaMsg(),

        const SizedBox(height: 16),

        // Reading panel (HTML: tarot-reading-panel)
        if (_readingText.isNotEmpty) _buildReadingPanel(),
      ]),
    );
  }

  // ── Stella Message ── HTML: .stella-msg
  // background:rgba(15,15,30,0.5); border:1px solid rgba(201,168,76,0.1); border-radius:14px; padding:16px;
  Widget _buildStellaMsg() {
    final card = _drawnCard!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0x800F0F1E), // rgba(15,15,30,0.5)
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1AC9A84C)), // rgba(201,168,76,0.1)
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // HTML: .stella-label { font-size:10px; color:#C9A84C; letter-spacing:1px; }
        const Text('✨ Stella', style: TextStyle(fontSize: 10, color: Color(0xFFC9A84C), letterSpacing: 1)),
        const SizedBox(height: 6),
        // HTML: .stella-text { font-size:13px; color:#ccc; line-height:1.6; }
        Text('今日の${card.nameJP}は、${card.keyword}のエネルギーを運んでいます。',
          style: const TextStyle(fontSize: 13, color: Color(0xFFCCCCCC), height: 1.6)),
      ]),
    );
  }

  // ── Card Back ── HTML: card-back
  Widget _buildCardBack() {
    return Container(
      key: const ValueKey('back'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14), // HTML: 14px
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A3E), Color(0xFF0D0D2B)], // HTML exact
        ),
        border: Border.all(color: const Color(0xFFC9A84C), width: 2), // HTML: 2px solid #C9A84C
      ),
      child: Center(child: Container(
        width: 160, height: 260, // HTML: card-back-pattern
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x4DC9A84C)), // rgba(201,168,76,0.3)
        ),
        child: const Center(child: Text('✨', style: TextStyle(fontSize: 48))), // HTML: card-back-symbol
      )),
    );
  }

  // ── Card Front ── HTML: card-front
  Widget _buildCardFront(TarotCard card) {
    return Container(
      key: ValueKey('front-${card.id}'),
      padding: const EdgeInsets.all(16), // HTML: padding 16px
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A3E), Color(0xFF0D0D2B)], // HTML exact
        ),
        border: Border.all(color: const Color(0xFFC9A84C), width: 2),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        // HTML: card-element-badge (11px, #aaa, letter-spacing 1.5)
        Text(
          '${_elementEmoji(card.element)} ${_elementName(card.element)}',
          style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA), letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        // HTML: card-emoji (56px with drop-shadow)
        Text(card.emoji, style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        // HTML: card-name-en (14px, #C9A84C, letter-spacing 2, weight 600)
        Text(card.nameEN.toUpperCase(), style: const TextStyle(
          fontSize: 14, color: Color(0xFFC9A84C), letterSpacing: 2, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center),
        const SizedBox(height: 4),
        // HTML: card-name-jp (18px, #E8E0D0, weight 300)
        Text(card.nameJP, style: const TextStyle(
          fontSize: 18, color: Color(0xFFE8E0D0), fontWeight: FontWeight.w300)),
        const SizedBox(height: 8),
        // HTML: card-keyword (13px, #999, italic)
        Text(card.keyword, style: const TextStyle(
          fontSize: 13, color: Color(0xFF999999), fontStyle: FontStyle.italic)),
        const SizedBox(height: 12),
        // HTML: card-planet-line (11px, #888)
        if (card.planet != null)
          Text('${_planetNamesJP[card.planet] ?? ''} ${_planetSymbol(card.planet!)}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
      ]),
    );
  }

  String _elementEmoji(String e) => const {'fire':'🔥','water':'🌊','air':'💨','earth':'🌿'}[e] ?? '';
  String _elementName(String e) => const {'fire':'Fire','water':'Water','air':'Air','earth':'Earth'}[e] ?? '';
  String _planetSymbol(String p) => const {'sun':'☉','moon':'☽','mercury':'☿','venus':'♀','mars':'♂',
    'jupiter':'♃','saturn':'♄','uranus':'♅','neptune':'♆','pluto':'♇'}[p] ?? '';

  // ── Reading Panel ── HTML: tarot-reading-panel
  Widget _buildReadingPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x990F0F1E), // rgba(15,15,30,0.6)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33C9A84C)), // rgba(201,168,76,0.2)
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // HTML: reading-header
        Row(children: [
          // reading-icon (36px circle)
          Container(width: 36, height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: const Color(0x1FC9A84C), // rgba(201,168,76,0.12)
              border: Border.all(color: const Color(0x40C9A84C))),
            child: const Center(child: Text('🔮', style: TextStyle(fontSize: 18)))),
          const SizedBox(width: 10),
          // reading-title (13px, 700, #C9A84C, letter-spacing 1.5)
          const Text('✦ TAROT READING', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFC9A84C), letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 14),
        // reading-body (13px, line-height 1.85, rgba(232,224,208,0.85))
        Text(_readingText.substring(0, _typedChars), style: const TextStyle(
          fontSize: 13, height: 1.85, color: Color(0xD9E8E0D0))),
        if (!_typingDone)
          const Text('▋', style: TextStyle(fontSize: 13, color: Color(0xFFC9A84C))),
        if (_typingDone && _adviceText.isNotEmpty) ...[
          const SizedBox(height: 14),
          // reading-advice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0x0FC9A84C), // rgba(201,168,76,0.06)
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x26C9A84C)), // rgba(201,168,76,0.15)
            ),
            child: Text(_adviceText, style: const TextStyle(
              fontSize: 12, height: 1.7, color: Color(0xFFC9A84C))),
          ),
        ],
      ]),
    );
  }

  // ── History Panel ── HTML: .history-panel { padding:16px 16px 30px; }
  Widget _buildHistoryPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      child: Column(children: [
        // HTML: .history-header { display:flex; align-items:center; justify-content:space-between; margin-bottom:14px; }
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // HTML: .history-title { font-size:12px; color:#666; letter-spacing:1.5px; }
            const Text('NATAL TAROT HISTORY', style: TextStyle(
              fontSize: 12, color: Color(0xFF666666), letterSpacing: 1.5)),
            // HTML: .history-clear { font-size:10px; color:#444; }
            GestureDetector(
              onTap: () async {
                await SolaraStorage.clearReadings();
                _loadHistory();
              },
              child: const Text('CLEAR', style: TextStyle(fontSize: 10, color: Color(0xFF444444))),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_history.isEmpty)
          // HTML: .history-empty { text-align:center; padding:60px 20px; color:#444; font-size:13px; line-height:1.8; }
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60, horizontal: 20),
            child: Text('まだカードを引いていません\n毎日1枚のカードがあなたを導きます',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF444444), fontSize: 13, height: 1.8)),
          )
        else
          Expanded(child: ListView.builder(
            itemCount: _history.length,
            itemBuilder: (ctx, i) {
              final r = _history[_history.length - 1 - i]; // newest first
              return _buildHistoryCard(r);
            },
          )),
      ]),
    );
  }

  // ── History Card ──
  // HTML: .history-card { border-radius:14px; margin-bottom:12px; border-left:3px solid #C9A84C;
  //   background:rgba(15,15,30,0.5); }
  // data-element colors: fire=#FF6B35, water=#4169E1, air=#87CEEB, earth=#2E8B57
  Widget _buildHistoryCard(DailyReading r) {
    final card = TarotData.getCard(r.cardId);
    final elementColor = _elementBorderColor(card.element);
    final expanded = _expandedHistory == r.date;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0x800F0F1E), // rgba(15,15,30,0.5)
        border: Border(left: BorderSide(color: elementColor, width: 3)),
      ),
      child: Column(children: [
        // HTML: .history-card-main { display:flex; align-items:center; gap:12px; padding:14px 12px; }
        GestureDetector(
          onTap: () => setState(() => _expandedHistory = expanded ? null : r.date),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(children: [
              // HTML: .history-card-emoji { font-size:28px; width:40px; }
              SizedBox(width: 40, child: Text(card.emoji,
                style: const TextStyle(fontSize: 28), textAlign: TextAlign.center)),
              const SizedBox(width: 12),
              // HTML: .history-card-info
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // HTML: .history-card-name { font-size:14px; color:#E8E0D0; font-weight:500; }
                Text(card.nameJP, style: const TextStyle(
                  fontSize: 14, color: Color(0xFFE8E0D0), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                // HTML: .history-card-keyword { font-size:11px; color:#999; font-style:italic; }
                Text(card.keyword, style: const TextStyle(
                  fontSize: 11, color: Color(0xFF999999), fontStyle: FontStyle.italic)),
                const SizedBox(height: 4),
                // HTML: .history-card-meta { font-size:10px; color:#555; display:flex; gap:8px; }
                Row(children: [
                  Text(r.date, style: const TextStyle(fontSize: 10, color: Color(0xFF555555))),
                  const SizedBox(width: 8),
                  Text(card.isMajor ? '大アルカナ' : '小アルカナ',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF555555))),
                  if (r.moonPhase > 0) ...[
                    const SizedBox(width: 8),
                    Text('🌙 ${r.moonPhase}日目',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF555555))),
                  ],
                ]),
              ])),
              // HTML: .history-card-chevron { color:#555; font-size:14px; }
              Text(expanded ? '▲' : '▼',
                style: const TextStyle(fontSize: 14, color: Color(0xFF555555))),
            ]),
          ),
        ),

        // HTML: .history-card-detail (expandable)
        if (expanded) _buildHistoryDetail(card),
      ]),
    );
  }

  // HTML: .history-card-detail { padding:14px; background:rgba(10,10,20,0.4); }
  Widget _buildHistoryDetail(TarotCard card) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Color(0x660A0A14), // rgba(10,10,20,0.4)
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // HTML: .detail-boost-row { display:flex; align-items:center; gap:10px; margin-bottom:12px; }
        Row(children: [
          // HTML: .detail-boost-dir { font-size:18px; font-weight:600; color:#C9A84C; }
          const Text('✦', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFC9A84C))),
          const SizedBox(width: 10),
          // HTML: .detail-boost-text { font-size:11px; color:#999; }
          Expanded(child: Text('${card.keyword}のエネルギーが活性化',
            style: const TextStyle(fontSize: 11, color: Color(0xFF999999)))),
        ]),
        const SizedBox(height: 12),

        // HTML: .detail-planets { display:flex; flex-wrap:wrap; gap:6px; }
        if (card.planet != null)
          Wrap(spacing: 6, runSpacing: 6, children: [
            // HTML: .detail-planet-tag { padding:3px 8px; border-radius:12px;
            //   background:rgba(201,168,76,0.06); border:1px solid rgba(201,168,76,0.15); font-size:10px; color:#C9A84C; }
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0x0FC9A84C),
                border: Border.all(color: const Color(0x26C9A84C)),
              ),
              child: Text('${_planetNamesJP[card.planet] ?? ''} ${_planetSymbol(card.planet!)}',
                style: const TextStyle(fontSize: 10, color: Color(0xFFC9A84C))),
            ),
          ]),
        const SizedBox(height: 12),

        // HTML: .sync-section { border-top:1px solid rgba(255,255,255,0.04); padding-top:10px; }
        Container(
          padding: const EdgeInsets.only(top: 10),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0x0AFFFFFF))),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // HTML: .sync-label { font-size:10px; color:#666; letter-spacing:1px; }
            const Row(children: [
              Text('✦', style: TextStyle(fontSize: 10, color: Color(0xFF666666))),
              SizedBox(width: 4),
              Text('SYNCHRONICITY', style: TextStyle(
                fontSize: 10, color: Color(0xFF666666), letterSpacing: 1)),
            ]),
            const SizedBox(height: 6),
            // HTML: .sync-input { padding:8px 10px; background:rgba(15,15,30,0.6);
            //   border:1px solid rgba(201,168,76,0.12); border-radius:8px; font-size:12px; color:#E8E0D0; }
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x990F0F1E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x1FC9A84C)),
              ),
              child: const Text('気づいたことを記録...', style: TextStyle(
                fontSize: 12, color: Color(0xFF444444))),
            ),
          ]),
        ),
      ]),
    );
  }

  Color _elementBorderColor(String e) => const {
    'fire': Color(0xFFFF6B35),
    'water': Color(0xFF4169E1),
    'air': Color(0xFF87CEEB),
    'earth': Color(0xFF2E8B57),
  }[e] ?? const Color(0xFFC9A84C);
}
