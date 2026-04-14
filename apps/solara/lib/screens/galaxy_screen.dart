import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/daily_reading.dart';
import '../models/galaxy_cycle.dart';
import '../models/lunar_intention.dart';

import '../utils/constellation_namer.dart';
import '../utils/moon_phase.dart';
import '../utils/solara_storage.dart';
import '../utils/tarot_data.dart';
import '../widgets/cycle_spiral_painter.dart';
import '../widgets/moon_overlay.dart';

import 'galaxy/galaxy_constellation_builder.dart';
import 'galaxy/galaxy_star_atlas.dart';
import 'galaxy/galaxy_replay_overlay.dart';

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

  // HTML: ART_IMAGES — pre-loaded constellation art images
  final Map<int, ui.Image> _artImages = {};

  // Random seed for background stars & nebula positions (changes each open)
  final int _bgSeed = DateTime.now().microsecondsSinceEpoch;
  List<Alignment> _nebulaPositions = [];
  List<Color> _nebulaColors = [];

  // Nebula color palette (no gold — cool/mysterious tones only)
  static const _nebulaPalette = [
    Color(0x60402060), // purple
    Color(0x50102850), // deep blue
    Color(0x40102850), // dark blue
    Color(0x2680D0F0), // light blue
    Color(0x30304060), // steel blue
    Color(0x35502060), // violet
    Color(0x2860A0B0), // teal
    Color(0x30203050), // navy
  ];

  @override
  void initState() {
    super.initState();
    _initNebulaPositions();
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

  void _initNebulaPositions() {
    final rng = Random(_bgSeed);
    double jitter(double base, double range) => base + (rng.nextDouble() - 0.5) * range;
    _nebulaPositions = [
      Alignment(jitter(-0.8, 0.4), jitter(-0.6, 0.4)),
      Alignment(jitter(0.7, 0.4), jitter(0.8, 0.4)),
      Alignment(jitter(-0.15, 0.3), jitter(0.15, 0.3)),
      Alignment(jitter(-0.7, 0.4), jitter(0.6, 0.4)),
      Alignment(jitter(0.0, 0.15), jitter(0.0, 0.15)),    // center gold (fixed color)
    ];
    // Random colors for first 4 nebulae (center stays gold)
    _nebulaColors = [
      _nebulaPalette[rng.nextInt(_nebulaPalette.length)],
      _nebulaPalette[rng.nextInt(_nebulaPalette.length)],
      _nebulaPalette[rng.nextInt(_nebulaPalette.length)],
      _nebulaPalette[rng.nextInt(_nebulaPalette.length)],
    ];
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

    final allReadings = await SolaraStorage.loadCurrentReadings();
    final completedCycles = await SolaraStorage.loadCompletedCycles();

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

    if (pastReadings.isNotEmpty) {
      final newCycle = formConstellation(pastReadings, cycleStart);
      if (newCycle != null) {
        await SolaraStorage.saveCompletedCycle(newCycle);
        completedCycles.add(newCycle);
      }
      await SolaraStorage.saveCurrentReadings(currentReadings);
    }

    final days = List<DailyReading?>.filled(totalDays, null);
    for (final r in currentReadings) {
      final rDate = DateTime.parse(r.date);
      final dayIdx = rDate.difference(cycleStart).inDays;
      if (dayIdx >= 0 && dayIdx < totalDays) {
        days[dayIdx] = r;
      }
    }

    final cycleId = '${cycleStart.year}-${cycleStart.month.toString().padLeft(2, '0')}';
    final intention = await SolaraStorage.loadIntention(cycleId);

    // ── サンプルデータ注入（デモ用） ──
    _injectSampleData(days, completedCycles, cycleStart, totalDays);

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

    await _checkMoonOverlay(now, cycleStart, cycleEnd, intention, cycleId);

    for (final c in completedCycles) {
      _loadArtImage(c.nounIdx);
    }
  }

  /// デモ用サンプルデータ: Cycleに25個の星 + Star Atlasに61全星座
  void _injectSampleData(List<DailyReading?> days, List<GalaxyCycle> cycles, DateTime cycleStart, int totalDays) {
    final rng = Random(42);

    // ── Cycle: 25個のサンプル星を散りばめる ──
    for (int i = 0; i < 25 && i < totalDays; i++) {
      final dayIdx = (i * totalDays / 25).floor();
      if (dayIdx < days.length && days[dayIdx] == null) {
        final cardId = rng.nextInt(78);
        final isMajor = cardId < 22;
        final date = cycleStart.add(Duration(days: dayIdx));
        days[dayIdx] = DailyReading(
          date: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          cardId: cardId, isMajor: isMajor, moonPhase: (dayIdx / totalDays * 29.53),
        );
      }
    }

    // ── Star Atlas: 61全星座のサンプル（formConstellation経由でテンプレート座標使用） ──
    if (cycles.isEmpty) {
      for (int nounIdx = 0; nounIdx < 61; nounIdx++) {
        final cycle = _buildSampleFromTemplate(nounIdx, cycleStart);
        cycles.add(cycle);
      }
    }
  }

  /// nounIdx指定でテンプレート座標を使った正確なサンプル星座を生成
  GalaxyCycle _buildSampleFromTemplate(int nounIdx, DateTime now) {
    final adjIdx = (nounIdx * 3 + 5) % 20;
    final start = now.subtract(Duration(days: 30 * (61 - nounIdx)));
    final end = start.add(const Duration(days: 29));
    final rng = Random(nounIdx * 1000 + 7);

    // テンプレート座標を取得（Anchor=Major星の位置）
    final template = ConstellationNamer.nounTemplates[nounIdx] ?? [];
    final anchorCount = template.length;
    // レアリティに応じてMinor星を追加（合計8〜25個）
    final rarity = ConstellationNamer.calculateRarity(adjIdx, nounIdx);
    final minorCount = (rarity.stars * 3 + 2).clamp(2, 25 - anchorCount);
    final totalDots = anchorCount + minorCount;
    const goldenAngle = 137.508 * pi / 180;

    final readings = <DailyReading>[];
    final dots = <ConstellationDot>[];

    // Anchor星（Major）: テンプレート座標をそのまま使用
    for (int i = 0; i < anchorCount; i++) {
      final cardId = (nounIdx * 7 + i * 11) % 78;
      final date = start.add(Duration(days: i));
      readings.add(DailyReading(
        date: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        cardId: cardId, isMajor: true, moonPhase: i * 1.0,
      ));
      dots.add(ConstellationDot(
        x: template[i][0],
        y: template[i][1],
        z: (rng.nextDouble() - 0.5) * 1.0,
        dayIndex: i, cardId: cardId, isMajor: true,
      ));
    }

    // Minor星（Field）: Golden Angle配置でAnchor周辺に散りばめる
    for (int i = 0; i < minorCount; i++) {
      final cardId = (nounIdx * 13 + i * 17 + 22) % 78;
      final date = start.add(Duration(days: anchorCount + i));
      readings.add(DailyReading(
        date: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        cardId: cardId, isMajor: false, moonPhase: (anchorCount + i) * 1.0,
      ));
      final angle = cardId * goldenAngle;
      final radius = 0.12 + (i / totalDots) * 0.3;
      final x = (0.5 + radius * cos(angle)).clamp(0.08, 0.92);
      final y = (0.5 + radius * sin(angle)).clamp(0.08, 0.92);
      dots.add(ConstellationDot(
        x: x, y: y,
        z: (rng.nextDouble() - 0.5) * 1.5,
        dayIndex: anchorCount + i, cardId: cardId, isMajor: false,
      ));
    }

    final nameEN = ConstellationNamer.buildName(adjIdx, nounIdx, en: true);
    final nameJP = ConstellationNamer.buildName(adjIdx, nounIdx, en: false);

    return GalaxyCycle(
      id: 'sample_$nounIdx',
      cycleStart: start, cycleEnd: end,
      readings: readings, seedCardId: readings.isNotEmpty ? readings.first.cardId : 0,
      nameEN: nameEN, nameJP: nameJP,
      dots: dots, rarity: rarity.stars, rarityLabel: rarity.label,
      adjIdx: adjIdx, nounIdx: nounIdx,
    );
  }

  Future<void> _loadArtImage(int nounIdx) async {
    if (_artImages.containsKey(nounIdx)) return;
    final path = ConstellationNamer.artAssetPath(nounIdx);
    if (path.isEmpty) return;
    try {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (mounted) {
        _artImages[nounIdx] = frame.image;
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _checkMoonOverlay(
    DateTime now, DateTime cycleStart, DateTime cycleEnd,
    LunarIntention? intention, String cycleId,
  ) async {
    final dayBeforeNewMoon = cycleEnd.subtract(const Duration(days: 1));
    final today = DateTime(now.year, now.month, now.day);
    final crystDay = DateTime(dayBeforeNewMoon.year, dayBeforeNewMoon.month, dayBeforeNewMoon.day);

    if (MoonPhase.isNewMoon(now)) {
      if (intention == null && !await SolaraStorage.wasOverlayShownToday('new_moon')) {
        if (mounted) setState(() => _activeOverlay = 'new_moon');
      }
    } else if (MoonPhase.isFullMoon(now)) {
      if (intention != null && intention.midpoint == null &&
          !await SolaraStorage.wasOverlayShownToday('full_moon')) {
        if (mounted) setState(() => _activeOverlay = 'full_moon');
      }
    } else if (today == crystDay || today.isAfter(crystDay)) {
      if (intention != null && intention.crystallization == null &&
          !await SolaraStorage.wasOverlayShownToday('crystallization')) {
        if (mounted) setState(() => _activeOverlay = 'crystallization');
      }
    }
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
        child: Stack(
          children: [
            // Nebula-like background gradients (positions randomized per session)
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(children: [
                  if (_nebulaColors.length >= 4) ...[
                    Container(decoration: BoxDecoration(gradient: RadialGradient(
                      center: _nebulaPositions[0], radius: 0.8,
                      colors: [_nebulaColors[0], const Color(0x00000000)]))),
                    Container(decoration: BoxDecoration(gradient: RadialGradient(
                      center: _nebulaPositions[1], radius: 0.7,
                      colors: [_nebulaColors[1], const Color(0x00000000)]))),
                    Container(decoration: BoxDecoration(gradient: RadialGradient(
                      center: _nebulaPositions[2], radius: 0.6,
                      colors: [_nebulaColors[2], const Color(0x00000000)]))),
                    Container(decoration: BoxDecoration(gradient: RadialGradient(
                      center: _nebulaPositions[3], radius: 0.65,
                      colors: [_nebulaColors[3], const Color(0x00000000)]))),
                  ],
                  // Center: warm gold glow (fixed)
                  Container(decoration: BoxDecoration(gradient: RadialGradient(
                    center: _nebulaPositions.length > 4 ? _nebulaPositions[4] : Alignment.center,
                    radius: 0.45,
                    colors: const [Color(0x30F9D976), Color(0x00000000)]))),
                ]),
              ),
            ),
            // HTML: .main-area { position:fixed; top:0; left:0; right:0; bottom:80px; }
            //       → bottom:80px は BottomNav 分。Column 全体は SafeArea で確保済みの
            //       画面サイズを使い、下余白はルート側 Scaffold.bottomNavigationBar が担う。
            Column(
              children: [
                // HTML: .inner-tabs (padding:0 20px; margin-bottom:8px)
                _buildTabBar(),
                const SizedBox(height: 8),
                // HTML: .tab-panel.active { flex:1; display:flex; flex-direction:column; }
                Expanded(
                  child: _activeTab == 0
                      ? _buildCycleTab()
                      : GalaxyStarAtlasTab(
                          completedCycles: _completedCycles,
                          artImages: _artImages,
                          onOpenReplay: _openReplay,
                        ),
                ),
                // HTML: .stella-msg.glass — #panel-cycle/#panel-atlas の外、
                //       .main-area の末尾にある。両タブで共有表示される。
                //       margin: 0 16px 6px
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: _buildStellaMessage(),
                ),
              ],
            ),
            if (_popupDayIndex >= 0) _buildDotPopup(),
            if (_replayCycle != null) GalaxyReplayOverlay(
              cycle: _replayCycle!,
              controller: _replayController!,
              artImage: _artImages[_replayCycle!.nounIdx],
              onClose: _closeReplay,
            ),
            if (_activeOverlay != null) _buildMoonOverlay(),
          ],
        ),
      ),
    );
  }

  // HTML: .inner-tabs
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Expanded(child: _buildTab(0, '🌀 Cycle')),
        Expanded(child: _buildTab(1, '✦ Star Atlas')),
      ]),
    );
  }

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
          color: isActive ? const Color(0xFFF9D976) : const Color(0x59FFFFFF),
          fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1,
        ))),
      ),
    );
  }

  // ====================== CYCLE TAB ======================

  Widget _buildCycleTab() {
    return Stack(
      children: [
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
                rotX: _rotX, rotY: _rotY, zoom: _zoom,
                breathPhase: _breathController.value * 100,
                cycleStart: _cycleStart,
                bgSeed: _bgSeed,
              );
              _lastPainter = painter;
              return CustomPaint(painter: painter, size: Size.infinite);
            },
          ),
        ),
        Positioned(top: 8, right: 20, child: _buildDayBadge()),
        Positioned(top: 8, left: 20, child: _buildMoonBadge()),
        // Stella は親Columnの末尾で共有表示 (HTML準拠)
      ],
    );
  }

  Widget _buildDayBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x1FF9D976),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x47F9D976)),
      ),
      child: Column(children: [
        Text('${_currentDayIndex + 1}', style: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFFF9D976), height: 1)),
        Text('of $_totalDays', style: const TextStyle(
          fontSize: 9, color: Color(0xA6F9D976), letterSpacing: 1.2)),
      ]),
    );
  }

  Widget _buildMoonBadge() {
    final info = MoonPhase.getPhaseInfo(DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x1AC0C8E0),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x38C0C8E0)),
      ),
      child: Column(children: [
        Text(info.emoji, style: const TextStyle(fontSize: 20, height: 1)),
        const SizedBox(height: 2),
        Text(info.label, style: const TextStyle(
          fontSize: 9, color: Color(0xA6C0C8E0), letterSpacing: 1)),
      ]),
    );
  }

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
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('✦ Stella', style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFF9D976), letterSpacing: 1.8)),
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
    _velX = 0; _velY = 0;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (!_dragging) return;
    final dx = d.localPosition.dx - _lastDrag.dx;
    final dy = d.localPosition.dy - _lastDrag.dy;
    setState(() {
      _velX = dy * 0.006; _velY = dx * 0.006;
      _rotX += _velX; _rotY += _velY;
    });
    _lastDrag = d.localPosition;
  }

  void _onDragEnd(DragEndDetails d) { _dragging = false; }

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
    setState(() { _popupDayIndex = dayIndex; _popupPosition = position; });
    _popupTimer = Timer(const Duration(milliseconds: 3500), _hideDotPopup);
  }

  void _hideDotPopup() {
    if (mounted) setState(() => _popupDayIndex = -1);
  }

  Widget _buildDotPopup() {
    if (_popupDayIndex < 0 || _popupDayIndex >= _cycleDays.length) return const SizedBox.shrink();
    final reading = _cycleDays[_popupDayIndex];
    if (reading == null) return const SizedBox.shrink();

    final card = TarotData.getCard(reading.cardId);
    const planetNamesJP = {'sun':'太陽','moon':'月','mercury':'水星','venus':'金星','mars':'火星',
      'jupiter':'木星','saturn':'土星','uranus':'天王星','neptune':'海王星','pluto':'冥王星'};

    return Positioned(
      left: (_popupPosition.dx - 100).clamp(8, MediaQuery.of(context).size.width - 208),
      top: (_popupPosition.dy - 120).clamp(8, MediaQuery.of(context).size.height - 160),
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xF2080C14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x26FFFFFF)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('DAY ${_popupDayIndex + 1}', style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFF9D976), letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Row(children: [
            Text(card.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(child: Text(card.nameEN, style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFEAEAEA)))),
          ]),
          const SizedBox(height: 8),
          if (card.planet != null)
            Text('Planet: ${planetNamesJP[card.planet] ?? card.planet}', style: const TextStyle(
              fontSize: 11, color: Color(0xCCACACAC))),
          const SizedBox(height: 4),
          Text('Keyword: ${card.keyword}', style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w300, color: Color(0xB3F9D976))),
          const SizedBox(height: 6),
          const Text('"Your momentum is cosmic."', style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w300, color: Color(0xB3ACACAC), fontStyle: FontStyle.italic)),
        ]),
      ),
    );
  }

  // ====================== REPLAY ======================

  void _openReplay(GalaxyCycle cycle) {
    _replayController?.dispose();
    _replayController = AnimationController(vsync: this, duration: const Duration(milliseconds: 6500));
    setState(() => _replayCycle = cycle);
    _replayController!.forward();
  }

  void _closeReplay() {
    _replayController?.dispose();
    _replayController = null;
    setState(() => _replayCycle = null);
  }

  // ====================== MOON OVERLAYS ======================

  Widget _buildMoonOverlay() {
    final cycleId = '${_cycleStart.year}-${_cycleStart.month.toString().padLeft(2, '0')}';
    final month = DateTime.now().month;

    switch (_activeOverlay) {
      case 'new_moon':
        return Positioned.fill(
          child: NewMoonOverlay(
            month: month, cycleId: cycleId,
            onDismiss: () => setState(() => _activeOverlay = null),
            onIntentionSet: () { setState(() => _activeOverlay = null); _loadData(); },
          ),
        );
      case 'full_moon':
        if (_currentIntention != null) {
          return Positioned.fill(
            child: FullMoonOverlay(
              intention: _currentIntention!, month: month,
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
