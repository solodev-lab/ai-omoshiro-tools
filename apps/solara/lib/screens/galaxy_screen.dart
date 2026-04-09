import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/daily_reading.dart';
import '../models/galaxy_cycle.dart';
import '../models/lunar_intention.dart';

import '../utils/constellation_namer.dart';
import '../utils/moon_phase.dart';
import '../utils/solara_storage.dart';
import '../utils/tarot_data.dart';
import '../widgets/constellation_painter.dart';
import '../widgets/cycle_spiral_painter.dart';

import '../widgets/moon_overlay.dart';

class GalaxyScreen extends StatefulWidget {
  const GalaxyScreen({super.key});

  @override
  State<GalaxyScreen> createState() => _GalaxyScreenState();
}

class _GalaxyScreenState extends State<GalaxyScreen>
    with TickerProviderStateMixin {
  // Tab
  int _activeTab = 0; // 0=Cycle, 1=Star Atlas

  // Cycle data
  List<DailyReading?> _cycleDays = [];
  int _currentDayIndex = 0;
  int _totalDays = 30;
  DateTime _cycleStart = DateTime.now();

  // Star Atlas
  List<GalaxyCycle> _completedCycles = [];

  // 3D rotation state
  double _rotX = -0.32;
  double _rotY = 0.4;
  final double _zoom = 1.0;
  double _velX = 0;
  double _velY = 0;
  bool _dragging = false;
  Offset _lastDrag = Offset.zero;

  // Breathing animation
  late AnimationController _breathController;

  // Auto-rotate animation
  late AnimationController _autoRotateController;

  // Dot popup
  int _popupDayIndex = -1;
  Offset _popupPosition = Offset.zero;
  Timer? _popupTimer;

  // Constellation replay
  GalaxyCycle? _replayCycle;
  AnimationController? _replayController;

  // Spiral painter key for hit-testing
  CycleSpiralPainter? _lastPainter;

  // Moon overlay state
  String? _activeOverlay; // 'new_moon', 'full_moon', 'crystallization', null
  LunarIntention? _currentIntention;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 100),
    )..repeat();

    _autoRotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 100),
    )..repeat();
    _autoRotateController.addListener(_onAutoRotate);

    _loadData();
  }

  @override
  void dispose() {
    _breathController.dispose();
    _autoRotateController.removeListener(_onAutoRotate);
    _autoRotateController.dispose();
    _popupTimer?.cancel();
    _replayController?.dispose();
    super.dispose();
  }

  void _onAutoRotate() {
    if (!_dragging && mounted) {
      setState(() {
        _rotY += 0.0025;
        _velX *= 0.90;
        _velY *= 0.90;
        _rotX += _velX;
        _rotY += _velY;
      });
    }
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final (cycleStart, cycleEnd) = MoonPhase.getCurrentCycleBounds(now);
    final totalDays = cycleEnd.difference(cycleStart).inDays;
    final currentDay = MoonPhase.getCurrentDayIndex(now);

    // Load all readings
    final allReadings = await SolaraStorage.loadCurrentReadings();
    final completedCycles = await SolaraStorage.loadCompletedCycles();

    // Separate past-cycle readings
    final pastReadings = <DailyReading>[];
    final currentReadings = <DailyReading>[];
    for (final r in allReadings) {
      final rDate = DateTime.parse(r.date);
      if (rDate.isBefore(cycleStart)) {
        pastReadings.add(r);
      } else {
        currentReadings.add(r);
      }
    }

    // If there are past-cycle readings, form a constellation
    if (pastReadings.isNotEmpty) {
      final newCycle = _formConstellation(pastReadings, cycleStart);
      if (newCycle != null) {
        await SolaraStorage.saveCompletedCycle(newCycle);
        completedCycles.add(newCycle);
      }
      // Save only current readings
      await SolaraStorage.saveCurrentReadings(currentReadings);
    }

    // Map readings to day slots
    final days = List<DailyReading?>.filled(totalDays, null);
    for (final r in currentReadings) {
      final rDate = DateTime.parse(r.date);
      final dayIdx = rDate.difference(cycleStart).inDays;
      if (dayIdx >= 0 && dayIdx < totalDays) {
        days[dayIdx] = r;
      }
    }

    // Load intention for current cycle
    final cycleId =
        '${cycleStart.year}-${cycleStart.month.toString().padLeft(2, '0')}';
    final intention = await SolaraStorage.loadIntention(cycleId);

    if (mounted) {
      setState(() {
        _cycleStart = cycleStart;
        _totalDays = totalDays;
        _currentDayIndex = currentDay;
        _cycleDays = days;
        _completedCycles = completedCycles;
        _currentIntention = intention;
      });
    }

    // Check if we should show a moon overlay
    await _checkMoonOverlay(now, cycleStart, cycleEnd, intention, cycleId);
  }

  Future<void> _checkMoonOverlay(
    DateTime now,
    DateTime cycleStart,
    DateTime cycleEnd,
    LunarIntention? intention,
    String cycleId,
  ) async {
    // Day before next new moon = crystallization
    final dayBeforeNewMoon = cycleEnd.subtract(const Duration(days: 1));
    final today = DateTime(now.year, now.month, now.day);
    final crystDay = DateTime(dayBeforeNewMoon.year, dayBeforeNewMoon.month,
        dayBeforeNewMoon.day);

    if (MoonPhase.isNewMoon(now)) {
      // New moon — show intention picker if not already set & not shown today
      if (intention == null &&
          !await SolaraStorage.wasOverlayShownToday('new_moon')) {
        if (mounted) setState(() => _activeOverlay = 'new_moon');
      }
    } else if (MoonPhase.isFullMoon(now)) {
      // Full moon — show midpoint check if intention exists & no midpoint yet
      if (intention != null &&
          intention.midpoint == null &&
          !await SolaraStorage.wasOverlayShownToday('full_moon')) {
        if (mounted) setState(() => _activeOverlay = 'full_moon');
      }
    } else if (today == crystDay || today.isAfter(crystDay)) {
      // Crystallization — show if intention exists & no crystallization yet
      if (intention != null &&
          intention.crystallization == null &&
          !await SolaraStorage.wasOverlayShownToday('crystallization')) {
        if (mounted) setState(() => _activeOverlay = 'crystallization');
      }
    }
  }

  GalaxyCycle? _formConstellation(
      List<DailyReading> readings, DateTime currentCycleStart) {
    if (readings.isEmpty) return null;

    // Find the cycle these readings belong to
    final firstDate = DateTime.parse(readings.first.date);
    final (prevStart, prevEnd) = MoonPhase.getCurrentCycleBounds(firstDate);

    // Determine seed card (most frequent major arcana)
    final majorCounts = <int, int>{};
    final suitCounts = <String, int>{};
    for (final r in readings) {
      if (r.isMajor) {
        majorCounts[r.cardId] = (majorCounts[r.cardId] ?? 0) + 1;
      } else {
        final card = TarotData.getCard(r.cardId);
        if (card.suit != null) {
          suitCounts[card.suit!] = (suitCounts[card.suit!] ?? 0) + 1;
        }
      }
    }

    int seedCardId;
    if (majorCounts.isNotEmpty) {
      seedCardId = majorCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    } else if (suitCounts.isNotEmpty) {
      final topSuit = suitCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
      final suitOffset = {'wands': 0, 'cups': 14, 'swords': 28, 'pentacles': 42};
      seedCardId = 22 + (suitOffset[topSuit] ?? 0);
    } else {
      seedCardId = 0;
    }

    // Generate name (v2: 1,220 combos with dedup)
    // TODO: Load usedNames from storage for deduplication
    final nameResult = ConstellationNamer.generate(
      seedCardId: seedCardId,
      date: prevStart,
    );
    final rarity = ConstellationNamer.calculateRarity(
      nameResult.adjIdx,
      nameResult.nounIdx,
    );

    // HTML exact: Place dots — Majors on NOUN_TEMPLATE positions, Minors via Golden Angle
    const goldenAngle = 137.508 * pi / 180;
    final dots = <ConstellationDot>[];
    final rng = Random(seedCardId + prevStart.millisecondsSinceEpoch);

    // Separate major/minor readings
    final majorReadings = <DailyReading>[];
    final minorReadings = <DailyReading>[];
    for (final r in readings) {
      if (r.isMajor) majorReadings.add(r);
      else minorReadings.add(r);
    }

    // Place Majors on template positions (HTML: getTemplatePositions)
    final templatePos = ConstellationNamer.getTemplatePositions(
      nameResult.nounIdx, majorReadings.length, seedCardId * 100 + prevStart.day,
    );
    for (int i = 0; i < majorReadings.length; i++) {
      final r = majorReadings[i];
      final rDate = DateTime.parse(r.date);
      final dayIdx = rDate.difference(prevStart).inDays;
      final nx = templatePos[i][0];
      final ny = templatePos[i][1];
      final zLayer = (r.cardId % 3) - 1;
      final zJitter = (rng.nextDouble() - 0.5) * 0.4;
      dots.add(ConstellationDot(
        x: nx.clamp(0.08, 0.92),
        y: ny.clamp(0.08, 0.92),
        z: (zLayer + zJitter).clamp(-1.0, 1.0),
        dayIndex: dayIdx,
        cardId: r.cardId,
        isMajor: true,
      ));
    }

    // Place Minors via Golden Angle (HTML: placeCycleDots minors section)
    for (int i = 0; i < minorReadings.length; i++) {
      final r = minorReadings[i];
      final rDate = DateTime.parse(r.date);
      final dayIdx = rDate.difference(prevStart).inDays;
      final angle = r.cardId * goldenAngle;
      final radius = 0.15 + (i / max(1, minorReadings.length)) * 0.28;
      final x = 0.5 + radius * cos(angle);
      final y = 0.5 + radius * sin(angle);
      final zLayer = (r.cardId % 3) - 1;
      final zJitter = (rng.nextDouble() - 0.5) * 0.4;
      dots.add(ConstellationDot(
        x: x.clamp(0.08, 0.92),
        y: y.clamp(0.08, 0.92),
        z: (zLayer + zJitter).clamp(-1.0, 1.0),
        dayIndex: dayIdx,
        cardId: r.cardId,
        isMajor: false,
      ));
    }

    dots.sort((a, b) => a.dayIndex.compareTo(b.dayIndex));

    return GalaxyCycle(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cycleStart: prevStart,
      cycleEnd: prevEnd,
      readings: readings,
      seedCardId: seedCardId,
      nameEN: nameResult.en,
      nameJP: nameResult.jp,
      dots: dots,
      rarity: rarity.stars,
      rarityLabel: rarity.label,
      adjIdx: nameResult.adjIdx,
      nounIdx: nameResult.nounIdx,
    );
  }

  @override
  Widget build(BuildContext context) {
    // HTML: background: radial-gradient(ellipse at center, #0a1220 0%, #020408 100%)
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center, radius: 1.2,
          colors: [Color(0xFF0A1220), Color(0xFF020408)],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // HTML: no "GALAXY" header — tabs are at top directly
                // HTML: .inner-tabs { padding:0 20px; margin-bottom:8px; }
                _buildTabBar(),
                const SizedBox(height: 8),
                Expanded(
                  child: _activeTab == 0 ? _buildCycleTab() : _buildStarAtlasTab(),
                ),
              ],
            ),
            if (_popupDayIndex >= 0) _buildDotPopup(),
            if (_replayCycle != null) _buildReplayOverlay(),
            if (_activeOverlay != null) _buildMoonOverlay(),
          ],
        ),
      ),
    );
  }

  // HTML: .inner-tabs { display:flex; gap:0; padding:0 20px; }
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Expanded(child: _buildTab(0, '🌀 Cycle')),
        Expanded(child: _buildTab(1, '✦ Star Atlas')),
      ]),
    );
  }

  // HTML: .inner-tab-btn { flex:1; padding:10px 0; font-size:12px; font-weight:700;
  //   letter-spacing:1px; text-transform:uppercase; color:rgba(255,255,255,0.35);
  //   border-bottom:2px solid transparent; }
  // .inner-tab-btn.active { color:#F9D976; border-bottom-color:#F9D976; }
  Widget _buildTab(int index, String label) {
    final isActive = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(
            color: isActive ? const Color(0xFFF9D976) : Colors.transparent, width: 2)),
        ),
        child: Center(child: Text(label, style: TextStyle(
          color: isActive ? const Color(0xFFF9D976) : const Color(0x59FFFFFF), // rgba(255,255,255,0.35)
          fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1,
        ))),
      ),
    );
  }

  // ====================== CYCLE TAB ======================

  Widget _buildCycleTab() {
    return Stack(
      children: [
        // Spiral
        GestureDetector(
          onPanStart: _onDragStart,
          onPanUpdate: _onDragUpdate,
          onPanEnd: _onDragEnd,
          onTapUp: _onTapUp,
          child: AnimatedBuilder(
            animation: _breathController,
            builder: (context, _) {
              final painter = CycleSpiralPainter(
                days: _cycleDays,
                currentDayIndex: _currentDayIndex,
                totalDays: _totalDays,
                rotX: _rotX,
                rotY: _rotY,
                zoom: _zoom,
                breathPhase: _breathController.value * 100,
                cycleStart: _cycleStart,
              );
              _lastPainter = painter;
              return CustomPaint(
                painter: painter,
                size: Size.infinite,
              );
            },
          ),
        ),
        // Day badge
        Positioned(
          top: 8,
          right: 16,
          child: _buildDayBadge(),
        ),
        // Moon phase info
        Positioned(
          top: 8,
          left: 16,
          child: _buildMoonBadge(),
        ),
        // Stella message
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: _buildStellaMessage(),
        ),
      ],
    );
  }

  // HTML: .day-badge { position:absolute; top:8px; right:20px;
  //   background:rgba(249,217,118,0.12); border:1px solid rgba(249,217,118,0.28);
  //   border-radius:22px; padding:8px 14px; display:flex; flex-direction:column; align-items:center; }
  Widget _buildDayBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x1FF9D976), // rgba(249,217,118,0.12)
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x47F9D976)), // rgba(249,217,118,0.28)
      ),
      child: Column(children: [
        // HTML: .day-num { font-size:22px; font-weight:700; color:#F9D976; line-height:1; }
        Text('${_currentDayIndex + 1}', style: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFFF9D976), height: 1)),
        // HTML: .day-lbl { font-size:9px; color:rgba(249,217,118,0.65); letter-spacing:1.2px; }
        Text('of $_totalDays', style: const TextStyle(
          fontSize: 9, color: Color(0xA6F9D976), letterSpacing: 1.2)),
      ]),
    );
  }

  // HTML: .moon-badge { position:absolute; top:8px; left:20px;
  //   background:rgba(192,200,224,0.10); border:1px solid rgba(192,200,224,0.22);
  //   border-radius:22px; padding:8px 14px; display:flex; flex-direction:column; align-items:center; }
  Widget _buildMoonBadge() {
    final info = MoonPhase.getPhaseInfo(DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x1AC0C8E0), // rgba(192,200,224,0.10)
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x38C0C8E0)), // rgba(192,200,224,0.22)
      ),
      child: Column(children: [
        // HTML: .moon-emoji { font-size:20px; line-height:1; }
        Text(info.emoji, style: const TextStyle(fontSize: 20, height: 1)),
        const SizedBox(height: 2),
        // HTML: .moon-lbl { font-size:9px; color:rgba(192,200,224,0.65); letter-spacing:1px; }
        Text(info.label, style: const TextStyle(
          fontSize: 9, color: Color(0xA6C0C8E0), letterSpacing: 1)),
      ]),
    );
  }

  // HTML: .stella-msg { margin:0 16px 6px; padding:12px 16px 14px; border-radius:20px; }
  // .bubble-by { font-size:10px; font-weight:700; color:#F9D976; letter-spacing:1.8px; }
  // .bubble-msg { font-size:13px; font-weight:300; color:#EAEAEA; line-height:1.6; }
  Widget _buildStellaMessage() {
    final readingCount = _cycleDays.where((d) => d != null).length;
    String msg;
    if (readingCount == 0) {
      msg = 'Draw a card on the Observe tab to begin your cosmic spiral...';
    } else if (readingCount < 7) {
      msg = 'Your spiral awakens. $readingCount star${readingCount > 1 ? 's' : ''} now glow in this cycle.';
    } else if (readingCount < 20) {
      msg = 'The constellation takes shape. Keep drawing to reveal its true form.';
    } else {
      msg = 'A luminous cycle. Soon these stars will become a constellation.';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF), // glass
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('✦ Stella', style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFF9D976),
          letterSpacing: 1.8)),
        const SizedBox(height: 7),
        Text('"$msg"', style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w300, color: Color(0xFFEAEAEA), height: 1.6)),
      ]),
    );
  }

  // --- 3D interaction ---

  void _onDragStart(DragStartDetails d) {
    _dragging = true;
    _lastDrag = d.localPosition;
    _velX = 0;
    _velY = 0;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (!_dragging) return;
    final dx = d.localPosition.dx - _lastDrag.dx;
    final dy = d.localPosition.dy - _lastDrag.dy;
    setState(() {
      _velX = dy * 0.006;
      _velY = dx * 0.006;
      _rotX += _velX;
      _rotY += _velY;
    });
    _lastDrag = d.localPosition;
  }

  void _onDragEnd(DragEndDetails d) {
    _dragging = false;
  }

  void _onTapUp(TapUpDetails details) {
    if (_lastPainter == null) return;
    final dayIndex = _lastPainter!.hitTestDot(details.localPosition);
    if (dayIndex >= 0 && dayIndex < _cycleDays.length && _cycleDays[dayIndex] != null) {
      _showDotPopup(dayIndex, details.localPosition);
    } else {
      _hideDotPopup();
    }
  }

  void _showDotPopup(int dayIndex, Offset position) {
    _popupTimer?.cancel();
    setState(() {
      _popupDayIndex = dayIndex;
      _popupPosition = position;
    });
    _popupTimer = Timer(const Duration(milliseconds: 3500), _hideDotPopup);
  }

  void _hideDotPopup() {
    if (mounted) {
      setState(() => _popupDayIndex = -1);
    }
  }

  // HTML: .dot-popup { background:rgba(8,12,20,0.95); backdrop-filter:blur(20px);
  //   border:1px solid rgba(255,255,255,0.15); border-radius:18px; padding:14px 16px; width:200px; }
  Widget _buildDotPopup() {
    if (_popupDayIndex < 0 || _popupDayIndex >= _cycleDays.length) {
      return const SizedBox.shrink();
    }
    final reading = _cycleDays[_popupDayIndex];
    if (reading == null) return const SizedBox.shrink();

    final card = TarotData.getCard(reading.cardId);
    final planetNamesJP = const {'sun':'太陽','moon':'月','mercury':'水星','venus':'金星','mars':'火星',
      'jupiter':'木星','saturn':'土星','uranus':'天王星','neptune':'海王星','pluto':'冥王星'};

    return Positioned(
      left: (_popupPosition.dx - 100).clamp(8, MediaQuery.of(context).size.width - 208),
      top: (_popupPosition.dy - 120).clamp(8, MediaQuery.of(context).size.height - 160),
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xF2080C14), // rgba(8,12,20,0.95)
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x26FFFFFF)), // rgba(255,255,255,0.15)
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          // HTML: .popup-day { font-size:10px; font-weight:700; color:#F9D976; letter-spacing:1.5px; }
          Text('DAY ${_popupDayIndex + 1}', style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFF9D976), letterSpacing: 1.5)),
          const SizedBox(height: 8),
          // HTML: .popup-card { display:flex; align-items:center; gap:8px; }
          Row(children: [
            // HTML: .popup-card-emoji { font-size:22px; }
            Text(card.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            // HTML: .popup-card-name { font-size:12px; font-weight:700; color:#EAEAEA; }
            Expanded(child: Text(card.nameEN, style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFEAEAEA)))),
          ]),
          const SizedBox(height: 8),
          // HTML: .popup-planet { font-size:11px; color:rgba(172,172,172,0.8); }
          if (card.planet != null)
            Text('Planet: ${planetNamesJP[card.planet] ?? card.planet}', style: const TextStyle(
              fontSize: 11, color: Color(0xCCACACAC))),
          const SizedBox(height: 4),
          // HTML: .popup-keyword { font-size:11px; font-weight:300; color:rgba(249,217,118,0.7); }
          Text('Keyword: ${card.keyword}', style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w300, color: Color(0xB3F9D976))),
        ]),
      ),
    );
  }

  // ====================== STAR ATLAS TAB ======================

  // HTML: .atlas-content { flex:1; overflow-y:auto; padding:0 16px 100px; display:flex; flex-direction:column; gap:20px; }
  Widget _buildStarAtlasTab() {
    if (_completedCycles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('✦', style: TextStyle(fontSize: 48, color: const Color(0xFFF9D976).withAlpha(77))),
            const SizedBox(height: 16),
            const Text('Star Atlas', style: TextStyle(
              color: Color(0xFFEAEAEA), fontSize: 20, fontWeight: FontWeight.w300)),
            const SizedBox(height: 8),
            const Text('Complete a lunar cycle to form\nyour first constellation.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFACACAC), fontSize: 13, height: 1.5)),
          ]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(children: [
        // HTML: .screen-h1 "Star Atlas" + .screen-h2 "Your completed cosmic cycles"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('Star Atlas', style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w300, color: Color(0xFFEAEAEA))),
            SizedBox(height: 4),
            Text('Your completed cosmic cycles', style: TextStyle(
              fontSize: 13, color: Color(0xFFACACAC))),
          ]),
        ),
        const SizedBox(height: 12),
        // HTML: .constellation-grid { display:grid; grid-template-columns:repeat(auto-fill, minmax(160px, 1fr)); gap:12px; }
        Expanded(child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200, crossAxisSpacing: 12, mainAxisSpacing: 12,
            childAspectRatio: 0.75, // HTML: aspect-ratio:0.75
          ),
          itemCount: _completedCycles.length,
          itemBuilder: (context, index) {
            final cycle = _completedCycles[_completedCycles.length - 1 - index];
            return _buildConstellationCard(cycle);
          },
        )),
      ]),
    );
  }

  // HTML: .const-card { border-radius:20px; padding:14px; aspect-ratio:0.75; }
  // HTML: background:linear-gradient(135deg, adjColor@0.12, adjColor@0.03); border:1px adjColor@0.25
  Widget _buildConstellationCard(GalaxyCycle cycle) {
    final adjColor = ConstellationNamer.adjColor(cycle.adjIdx);
    final anchorCount = cycle.dots.where((d) => d.isMajor).length;
    // HTML: rarity stars display
    final starColor = cycle.rarity >= 4 ? const Color(0xFFF9D976)
        : cycle.rarity >= 3 ? const Color(0xFFB080FF) : const Color(0xFF888888);
    final starsText = '${'★' * cycle.rarity}${'☆' * (5 - cycle.rarity)}';

    return GestureDetector(
      onTap: () => _openReplay(cycle),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          // HTML: background:linear-gradient(135deg, adjColor@0.12, adjColor@0.03)
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [adjColor.withAlpha((0.12 * 255).round()), adjColor.withAlpha((0.03 * 255).round())],
          ),
          borderRadius: BorderRadius.circular(20),
          // HTML: border:1px solid adjColor@0.25
          border: Border.all(color: adjColor.withAlpha((0.25 * 255).round())),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // HTML: .const-mini { flex:1; center; canvas 80x80 }
          Expanded(child: Center(child: CustomPaint(
            painter: MiniConstellationPainter(cycle: cycle),
            size: const Size(80, 80),
          ))),
          const SizedBox(height: 8),
          // HTML: shape type + ★★★☆☆ rarity stars (flex, space-between)
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            // HTML: .const-date (shape type)
            Text(cycle.dateRangeLabel, style: const TextStyle(
              fontSize: 10, color: Color(0xFFACACAC))),
            Text(starsText, style: TextStyle(fontSize: 10, color: starColor, letterSpacing: 2)),
          ]),
          const SizedBox(height: 2),
          // HTML: .const-seed — nameEN
          Text(cycle.nameEN, style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFEAEAEA)),
            overflow: TextOverflow.ellipsis),
          // HTML: nameJP
          if (cycle.nameJP.isNotEmpty)
            Text(cycle.nameJP, style: const TextStyle(
              fontSize: 11, color: Color(0xFFACACAC)),
              overflow: TextOverflow.ellipsis),
          // HTML: meta — "N stars · M anchors · rarityLabel"
          const SizedBox(height: 2),
          Text('${cycle.dots.length} stars · $anchorCount anchors · ${cycle.rarityLabel}',
            style: const TextStyle(fontSize: 10, color: Color(0x99ACACAC))),
        ]),
      ),
    );
  }

  // ====================== REPLAY OVERLAY ======================
  // Crystallization camera animation: 55° → 0° over total 6.5s
  // Phase 1: Camera 55°→0° (0-3s)
  // Phase 2: Line connections (3-4.5s)
  // Phase 3: Name + rarity fade-in (4.5-6.5s)
  static const double _cameraAngle55 = 55 * pi / 180; // ~0.96 rad

  void _openReplay(GalaxyCycle cycle) {
    _replayController?.dispose();
    _replayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6500),
    );
    setState(() => _replayCycle = cycle);
    _replayController!.forward();
  }

  void _closeReplay() {
    _replayController?.dispose();
    _replayController = null;
    setState(() => _replayCycle = null);
  }

  // HTML: #replayModal { background:rgba(2,4,10,0.96); backdrop-filter:blur(12px); }
  // .replay-inner { width:340px; display:flex; flex-direction:column; align-items:center; gap:20px; }
  Widget _buildReplayOverlay() {
    final cycle = _replayCycle!;
    return GestureDetector(
      onTap: _closeReplay,
      child: Container(
        color: const Color(0xF5020408), // rgba(2,4,10,0.96)
        child: Center(
          child: AnimatedBuilder(
            animation: _replayController!,
            builder: (context, _) {
              final t = _replayController!.value;
              final cameraT = (t / 0.46).clamp(0.0, 1.0);
              final easedCamera = Curves.easeInOutCubic.transform(cameraT);
              final cameraAngle = _cameraAngle55 * (1.0 - easedCamera);
              final lineT = ((t - 0.46) / 0.23).clamp(0.0, 1.0);
              final fadeT = ((t - 0.69) / 0.31).clamp(0.0, 1.0);
              final painterProgress = cameraT * 0.4 + lineT * 0.6;

              return SizedBox(
                width: 340,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // HTML: .replay-title — nameEN + nameJP
                  Opacity(opacity: fadeT, child: Column(children: [
                    Text(cycle.nameEN, style: const TextStyle(
                      color: Color(0xFFEAEAEA), fontSize: 20, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text(cycle.nameJP, style: const TextStyle(
                      color: Color(0xFFF9D976), fontSize: 14, fontWeight: FontWeight.w300),
                      textAlign: TextAlign.center),
                  ])),
                  const SizedBox(height: 20),
                  // HTML: #replayCanvas { border-radius:20px; border:1px solid rgba(255,255,255,0.1); background:rgba(6,10,18,0.8); }
                  Container(
                    width: 300, height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xCC060A12), // rgba(6,10,18,0.8)
                      border: Border.all(color: const Color(0x1AFFFFFF)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CustomPaint(
                        painter: ConstellationPainter(
                          cycle: cycle, progress: painterProgress, cameraAngle: cameraAngle),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // HTML: .replay-sub — stars/anchors/shape + rarity
                  Opacity(opacity: fadeT, child: Column(children: [
                    Text('${cycle.dots.length} stars · ${cycle.dots.where((d) => d.isMajor).length} anchors',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFACACAC)),
                      textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    // HTML: ★★★☆☆ + rarityLabel
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('${'★' * cycle.rarity}${'☆' * (5 - cycle.rarity)}',
                        style: TextStyle(fontSize: 12, letterSpacing: 2,
                          color: cycle.rarity >= 4 ? const Color(0xFFF9D976)
                              : cycle.rarity >= 3 ? const Color(0xFFB080FF) : const Color(0xFF888888))),
                      const SizedBox(width: 6),
                      Text(cycle.rarityLabel, style: const TextStyle(
                        fontSize: 11, color: Color(0xFFACACAC))),
                    ]),
                    const SizedBox(height: 4),
                    Text(cycle.dateRangeLabel, style: const TextStyle(
                      fontSize: 12, color: Color(0xFFACACAC))),
                  ])),
                  const SizedBox(height: 24),
                  // HTML: .replay-close { background:none; border:1px solid rgba(255,255,255,0.2);
                  //   border-radius:12px; padding:10px 28px; font-size:13px; color:#ACACAC; }
                  GestureDetector(
                    onTap: _closeReplay,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x33FFFFFF)),
                      ),
                      child: const Text('← Back to Star Atlas', style: TextStyle(
                        fontSize: 13, color: Color(0xFFACACAC))),
                    ),
                  ),
                ]),
              );
            },
          ),
        ),
      ),
    );
  }

  // ====================== MOON OVERLAYS ======================

  Widget _buildMoonOverlay() {
    final cycleId =
        '${_cycleStart.year}-${_cycleStart.month.toString().padLeft(2, '0')}';
    final month = DateTime.now().month;

    switch (_activeOverlay) {
      case 'new_moon':
        return Positioned.fill(
          child: NewMoonOverlay(
            month: month,
            cycleId: cycleId,
            onDismiss: () => setState(() => _activeOverlay = null),
            onIntentionSet: () {
              setState(() => _activeOverlay = null);
              _loadData(); // reload to pick up the new intention
            },
          ),
        );
      case 'full_moon':
        if (_currentIntention != null) {
          return Positioned.fill(
            child: FullMoonOverlay(
              intention: _currentIntention!,
              month: month,
              onDismiss: () => setState(() => _activeOverlay = null),
            ),
          );
        }
        return const SizedBox.shrink();
      case 'crystallization':
        if (_currentIntention != null) {
          return Positioned.fill(
            child: CrystallizationOverlay(
              intention: _currentIntention!,
              onDismiss: () => setState(() => _activeOverlay = null),
            ),
          );
        }
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }
}
