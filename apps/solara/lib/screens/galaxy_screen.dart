import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/daily_reading.dart';
import '../models/galaxy_cycle.dart';
import '../models/lunar_intention.dart';

import '../utils/celestial_events.dart';
import '../utils/constellation_namer.dart';
import '../utils/moon_phase.dart';
import '../utils/solara_storage.dart';
import '../utils/tarot_data.dart';
import '../widgets/catasterism_formation_overlay.dart';
import '../widgets/celestial_event_bar.dart';
import '../widgets/cycle_spiral_painter.dart';
import '../widgets/moon_overlay.dart';

import 'galaxy/galaxy_constellation_builder.dart';
import 'galaxy/galaxy_sample_data.dart';
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

  // Celestial events (サイクル内)
  List<CelestialEvent> _cycleEvents = [];

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
  String? _activeOverlay; // 'new_moon', 'full_moon', 'catasterism', 'formation', null
  LunarIntention? _currentIntention;
  // 刻星化完了演出で表示する対象cycle (formation overlay用)
  GalaxyCycle? _formationCycle;

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
      // 既存cycleの名前集合を渡して重複防止(generate()内でattemptシフト)
      final usedNames = completedCycles.map((c) => c.nameEN).toSet();
      final newCycle = formConstellation(
        pastReadings,
        cycleStart,
        usedNames: usedNames,
      );
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
    injectGalaxySampleData(days, completedCycles, cycleStart, totalDays);

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

    // サイクル内天体イベントを取得
    final events = await CelestialEvents.fetchCycleEvents(now.year, now.month);
    if (mounted) setState(() => _cycleEvents = events);
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
      if (intention != null && intention.catasterism == null &&
          !await SolaraStorage.wasOverlayShownToday('catasterism')) {
        if (mounted) setState(() => _activeOverlay = 'catasterism');
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
                const SizedBox(height: 4),
                // DEBUG: Cycle完了フローの各タイミングを手動トリガー (release時は非表示)
                if (kDebugMode) _buildDebugTriggerRow(),
                if (kDebugMode) const SizedBox(height: 4),
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
                // 天体イベントバー（Cycleタブのみ、Stellaの上）
                if (_activeTab == 0 && _cycleEvents.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: CelestialEventBar(events: _cycleEvents),
                  ),
                // HTML: .stella-msg.glass — #panel-cycle/#panel-atlas の外、
                //       .main-area の末尾にある。Cycleタブのみ表示（Atlasでは非表示）。
                //       margin: 0 16px 6px
                if (_activeTab == 0)
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

  // ====================== DEBUG TRIGGERS ======================
  // 4つのタイミングを日付監視をバイパスして直接トリガーする

  Widget _buildDebugTriggerRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildDebugBtn('🌑 新月', _debugTriggerNewMoon)),
          const SizedBox(width: 6),
          Expanded(child: _buildDebugBtn('🌕 満月', _debugTriggerFullMoon)),
          const SizedBox(width: 6),
          Expanded(child: _buildDebugBtn('✦ 刻星化', _debugTriggerCatasterism)),
          const SizedBox(width: 6),
          Expanded(child: _buildDebugBtn('✨ 完了', _debugTriggerCycleCompletion)),
        ],
      ),
    );
  }

  Widget _buildDebugBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x22F9D976),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0x66F9D976), width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFF9D976),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 新月トリガー: `_checkMoonOverlay` 内の `if (isNewMoon)` ブロックの下流を実行
  void _debugTriggerNewMoon() {
    setState(() => _activeOverlay = 'new_moon');
  }

  /// 満月トリガー: 意図が無ければダミーをセット → `if (isFullMoon)` ブロックの下流を実行
  void _debugTriggerFullMoon() {
    _currentIntention ??= LunarIntention(
      cycleId: '${_cycleStart.year}-${_cycleStart.month.toString().padLeft(2, '0')}',
      chosenText: 'Self-doubt',
      chosenTextJP: '自己不信',
      chosenAt: _cycleStart,
      newMoonSign: 'Aries',
    );
    setState(() => _activeOverlay = 'full_moon');
  }

  /// 刻星化トリガー: フル完了フロー模擬
  /// - ダミー過去readings保存 → _loadDataで cycle が formConstellation 経由で形成
  /// - 意図+満月記録ダミー → catasterism overlay 表示
  /// - ユーザーが「手放せた / まだ途中」押下 → _onCatasterismResult → formation animation
  Future<void> _debugTriggerCatasterism() async {
    // 1. cycle を事前に作っておく (完了ボタンと同じロジック)
    await _debugTriggerCycleCompletion();
    // 2. 意図ダミー (満月中間記録あり)
    _currentIntention ??= LunarIntention(
      cycleId: '${_cycleStart.year}-${_cycleStart.month.toString().padLeft(2, '0')}',
      chosenText: 'Self-doubt',
      chosenTextJP: '自己不信',
      chosenAt: _cycleStart,
      newMoonSign: 'Aries',
      midpoint: MidpointCheck(checkedAt: DateTime.now(), rating: 2),
    );
    // 3. catasterism overlay 表示 (押下後 _onCatasterismResult 経由で formation へ)
    if (mounted) setState(() => _activeOverlay = 'catasterism');
  }

  /// サイクル完了トリガー: ダミー過去readingsを保存 → `_loadData` 再実行で
  /// `if (pastReadings.isNotEmpty)` ブロックの下流(formConstellation+保存)が走る
  Future<void> _debugTriggerCycleCompletion() async {
    final now = DateTime.now();
    final (cycleStart, _) = MoonPhase.getCurrentCycleBounds(now);
    final rng = Random(now.microsecondsSinceEpoch);

    // [デバッグ専用] 擬似的に「1〜24サイクル前」の過去に readings を配置する。
    // → formConstellation 内で readings.first.date から prevStart を
    //    MoonPhase.getCurrentCycleBounds で再計算 → ハッシュのdateStrが毎回変わる
    // → 同じ日に何度押しても多様な (adjIdx, nounIdx) が出現する
    // 本番コードは一切変更せず、デバッグ側の入力日付だけを操作。
    final cyclesBack = 1 + rng.nextInt(24); // 1〜24サイクル前
    final prevStart = cycleStart.subtract(Duration(days: 29 * cyclesBack));

    final dummyReadings = <DailyReading>[];
    // 実運用シミュレート: ユーザーが何日タロット引くかランダム (5〜29日)
    // カードは78枚から自然分布 → Major(<22)は約28%
    final readingDays = 5 + rng.nextInt(25); // 5-29枚の範囲
    // 29日サイクル内のユニークな日をランダムに選ぶ
    final daySlots = List<int>.generate(29, (i) => i)..shuffle(rng);
    final selectedDays = daySlots.take(readingDays).toList()..sort();

    int majorCount = 0;
    int minorCount = 0;
    for (final day in selectedDays) {
      final cardId = rng.nextInt(78); // 0-77 自然分布
      final isMajor = cardId < 22;
      if (isMajor) {
        majorCount++;
      } else {
        minorCount++;
      }
      final date = prevStart.add(Duration(days: day));
      dummyReadings.add(DailyReading(
        date: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        cardId: cardId,
        isMajor: isMajor,
        moonPhase: day * 1.0,
      ));
    }

    // saveCurrentReadings に保存 → _loadData 内で cycleStart より前のものが
    // pastReadings として分離され、formConstellation が走る
    await SolaraStorage.saveCurrentReadings(dummyReadings);
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '刻星化: $cyclesBackサイクル前, $readingDays日分 (M:$majorCount / m:$minorCount) → Atlas確認',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
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
      case 'catasterism':
        if (_currentIntention != null) {
          return Positioned.fill(
            child: CatasterismOverlay(
              intention: _currentIntention!,
              totalDays: _totalDays,
              onDismiss: () => setState(() => _activeOverlay = null),
              onResult: _onCatasterismResult,
            ),
          );
        }
        return const SizedBox.shrink();
      case 'formation':
        if (_formationCycle != null) {
          return Positioned.fill(
            child: CatasterismFormationOverlay(
              cycle: _formationCycle!,
              artImage: _artImages[_formationCycle!.nounIdx],
              onComplete: _onFormationComplete,
            ),
          );
        }
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  /// 刻星化判定後 (手放せた / まだ途中) → formation animation 起動
  /// _completedCycles の最新を演出対象にする (なければ何もしない)
  void _onCatasterismResult(bool released) {
    final latest =
        _completedCycles.isNotEmpty ? _completedCycles.last : null;
    if (latest != null) {
      _loadArtImage(latest.nounIdx);
      setState(() {
        _activeOverlay = 'formation';
        _formationCycle = latest;
      });
    } else {
      setState(() => _activeOverlay = null);
    }
  }

  /// formation animation 完了 → オーバーレイ閉じてStar Atlasタブへ自動遷移
  void _onFormationComplete() {
    setState(() {
      _activeOverlay = null;
      _formationCycle = null;
      _activeTab = 1; // Star Atlasタブへ
    });
  }
}
