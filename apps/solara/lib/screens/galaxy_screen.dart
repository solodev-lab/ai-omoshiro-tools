import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/daily_reading.dart';
import '../models/galaxy_cycle.dart';
import '../models/lunar_intention.dart';
import '../theme/solara_colors.dart';
import '../utils/constellation_namer.dart';
import '../utils/moon_phase.dart';
import '../utils/solara_storage.dart';
import '../utils/tarot_data.dart';
import '../widgets/constellation_painter.dart';
import '../widgets/cycle_spiral_painter.dart';
import '../widgets/glass_panel.dart';
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

    // Build constellation dots using Golden Angle placement + 3D z-layers
    // Golden Angle: each dot placed at cardId × 137.508° for uniform distribution
    const goldenAngle = 137.508 * pi / 180;
    final dots = <ConstellationDot>[];
    final rng = Random(seedCardId + prevStart.millisecondsSinceEpoch);

    for (int i = 0; i < readings.length; i++) {
      final r = readings[i];
      final rDate = DateTime.parse(r.date);
      final dayIdx = rDate.difference(prevStart).inDays;

      // Golden Angle placement based on cardId
      final angle = r.cardId * goldenAngle;
      final radius = 0.15 + (i / readings.length) * 0.28;
      final x = 0.5 + radius * cos(angle);
      final y = 0.5 + radius * sin(angle);

      // Assign z-layer: 3 layers (back/mid/front)
      // Deterministic based on cardId
      final zLayer = (r.cardId % 3) - 1; // -1, 0, 1
      final zJitter = (rng.nextDouble() - 0.5) * 0.4;
      final z = zLayer + zJitter;

      dots.add(ConstellationDot(
        x: x.clamp(0.08, 0.92),
        y: y.clamp(0.08, 0.92),
        z: z.clamp(-1.0, 1.0),
        dayIndex: dayIdx,
        cardId: r.cardId,
        isMajor: r.isMajor,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [SolaraColors.celestialBlueLight, SolaraColors.celestialBlueDark],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 16),
                // Header
                Text(
                  'GALAXY',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: SolaraColors.solaraGold,
                        letterSpacing: 3.0,
                      ),
                ),
                const SizedBox(height: 12),
                // Tab bar
                _buildTabBar(),
                const SizedBox(height: 8),
                // Content
                Expanded(
                  child: _activeTab == 0 ? _buildCycleTab() : _buildStarAtlasTab(),
                ),
              ],
            ),
            // Dot popup overlay
            if (_popupDayIndex >= 0) _buildDotPopup(),
            // Replay overlay
            if (_replayCycle != null) _buildReplayOverlay(),
            // Moon overlays
            if (_activeOverlay != null) _buildMoonOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        children: [
          Expanded(child: _buildTab(0, '\u{1F300} Cycle')),
          const SizedBox(width: 8),
          Expanded(child: _buildTab(1, '\u{2726} Star Atlas')),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isActive = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive
                  ? SolaraColors.solaraGold
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            // HTML: font-size 12px, font-weight 700, letter-spacing 1px, inactive rgba(255,255,255,0.35)
            style: TextStyle(
              color: isActive
                  ? SolaraColors.solaraGold
                  : Colors.white.withAlpha(89),
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              letterSpacing: 1.0,
            ),
          ),
        ),
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

  Widget _buildDayBadge() {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      borderRadius: BorderRadius.circular(16),
      child: Text(
        'Day ${_currentDayIndex + 1} of $_totalDays',
        style: const TextStyle(
          color: SolaraColors.solaraGold,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildMoonBadge() {
    final info = MoonPhase.getPhaseInfo(DateTime.now());
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      borderRadius: BorderRadius.circular(16),
      child: Text(
        '${info.emoji} ${info.label}',
        style: const TextStyle(
          color: SolaraColors.textSecondary,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildStellaMessage() {
    // Count readings in current cycle
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

    return GlassPanel(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          const Text('\u{2728}', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              // HTML: font-size 13px, font-weight 300, line-height 1.6
              style: const TextStyle(
                color: SolaraColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w300,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildDotPopup() {
    if (_popupDayIndex < 0 || _popupDayIndex >= _cycleDays.length) {
      return const SizedBox.shrink();
    }
    final reading = _cycleDays[_popupDayIndex];
    if (reading == null) return const SizedBox.shrink();

    final card = TarotData.getCard(reading.cardId);
    final dayDate = _cycleStart.add(Duration(days: _popupDayIndex));
    final moonInfo = MoonPhase.getPhaseInfo(dayDate);

    return Positioned(
      left: (_popupPosition.dx - 90).clamp(8, MediaQuery.of(context).size.width - 196),
      top: (_popupPosition.dy - 100).clamp(8, MediaQuery.of(context).size.height - 140),
      child: GlassPanel(
        blurRadius: 20,
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 180,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Day ${_popupDayIndex + 1} ${moonInfo.emoji}',
                style: const TextStyle(
                  color: SolaraColors.solaraGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${card.emoji} ${card.nameEN}',
                style: const TextStyle(
                  color: SolaraColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                card.isMajor
                    ? '${card.planet?.toUpperCase() ?? ''} \u00B7 Major Arcana'
                    : '${card.suit?.toUpperCase() ?? ''} \u00B7 ${card.element}',
                style: const TextStyle(
                  color: SolaraColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                card.keyword,
                style: const TextStyle(
                  color: SolaraColors.textSecondary,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====================== STAR ATLAS TAB ======================

  Widget _buildStarAtlasTab() {
    if (_completedCycles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '\u{2726}',
                style: TextStyle(
                  fontSize: 48,
                  color: SolaraColors.solaraGold.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Star Atlas',
                style: TextStyle(
                  color: SolaraColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Complete a lunar cycle to form\nyour first constellation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SolaraColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: _completedCycles.length,
        itemBuilder: (context, index) {
          final cycle = _completedCycles[_completedCycles.length - 1 - index];
          return _buildConstellationCard(cycle);
        },
      ),
    );
  }

  Widget _buildConstellationCard(GalaxyCycle cycle) {
    final starColor = cycle.rarity >= 4
        ? SolaraColors.solaraGold
        : cycle.rarity >= 3
            ? const Color(0xFFB080FF)
            : SolaraColors.textSecondary;
    return GestureDetector(
      onTap: () => _openReplay(cycle),
      child: GlassPanel(
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: CustomPaint(
                  painter: MiniConstellationPainter(cycle: cycle),
                  size: const Size(80, 80),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  cycle.dateRangeLabel,
                  style: const TextStyle(
                    color: SolaraColors.solaraGold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '\u2605' * cycle.rarity,
                  style: TextStyle(
                    color: starColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              cycle.nameEN,
              style: const TextStyle(
                color: SolaraColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              cycle.nameJP,
              style: const TextStyle(
                color: SolaraColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${cycle.dots.length} stars \u00B7 ${cycle.dots.where((d) => d.isMajor).length} anchors \u00B7 ${cycle.rarityLabel}',
              style: TextStyle(
                color: SolaraColors.textSecondary.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
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

  Widget _buildReplayOverlay() {
    final cycle = _replayCycle!;
    return GestureDetector(
      onTap: _closeReplay,
      child: Container(
        color: const Color(0xF0080C14),
        child: Center(
          child: AnimatedBuilder(
            animation: _replayController!,
            builder: (context, _) {
              final t = _replayController!.value;
              // Phase 1: Camera animation (0 - 0.46 = 3s/6.5s)
              final cameraT = (t / 0.46).clamp(0.0, 1.0);
              final easedCamera = Curves.easeInOutCubic.transform(cameraT);
              final cameraAngle = _cameraAngle55 * (1.0 - easedCamera);

              // Phase 2: Line connections (0.46 - 0.69 = 1.5s/6.5s)
              final lineT = ((t - 0.46) / 0.23).clamp(0.0, 1.0);

              // Phase 3: Name fade-in (0.69 - 1.0 = 2s/6.5s)
              final fadeT = ((t - 0.69) / 0.31).clamp(0.0, 1.0);

              // Combined progress for painter: dots appear with camera, lines after
              final painterProgress = cameraT * 0.4 + lineT * 0.6;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name + rarity (fades in)
                  Opacity(
                    opacity: fadeT,
                    child: Column(
                      children: [
                        Text(
                          cycle.nameEN,
                          style: const TextStyle(
                            color: SolaraColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cycle.nameJP,
                          style: const TextStyle(
                            color: SolaraColors.solaraGold,
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Rarity stars
                        _buildRarityStars(cycle.rarity, cycle.rarityLabel),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Animated constellation with camera
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: CustomPaint(
                      painter: ConstellationPainter(
                        cycle: cycle,
                        progress: painterProgress,
                        cameraAngle: cameraAngle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Opacity(
                    opacity: fadeT,
                    child: Column(
                      children: [
                        Text(
                          cycle.dateRangeLabel,
                          style: const TextStyle(
                            color: SolaraColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${cycle.dots.length} stars \u00B7 ${cycle.dots.where((d) => d.isMajor).length} anchors',
                          style: const TextStyle(
                            color: SolaraColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _closeReplay,
                    child: const Text(
                      '\u{2190} Back to Star Atlas',
                      style: TextStyle(
                        color: SolaraColors.solaraGold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRarityStars(int stars, String label) {
    final starColor = stars >= 4
        ? SolaraColors.solaraGold
        : stars >= 3
            ? const Color(0xFFB080FF)
            : SolaraColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '\u2605' * stars + '\u2606' * (5 - stars),
          style: TextStyle(
            color: starColor,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: starColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
        ),
      ],
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
