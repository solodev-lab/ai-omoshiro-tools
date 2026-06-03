import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'horoscope/horo_antique_icons.dart';
import '../models/daily_reading.dart';
import '../models/galaxy_cycle.dart';
import '../models/lunar_intention.dart';

import '../utils/celestial_events.dart';
import '../utils/constellation_namer.dart';
import '../utils/moon_event_status.dart';
import '../utils/moon_phase.dart';
import '../utils/solara_storage.dart';
import '../utils/tarot_data.dart';
import '../widgets/catasterism_formation_overlay.dart';
import '../widgets/celestial_event_bar.dart';
import '../widgets/cycle_spiral_painter.dart';
import '../widgets/info_popup.dart';
import '../widgets/moon_overlay.dart';
import '../widgets/tap_to_unfocus.dart';

import 'galaxy/constellation_share_card_page.dart';
import 'galaxy/galaxy_constellation_builder.dart';
import 'galaxy/galaxy_stella_messages.dart';
import 'galaxy/galaxy_cycle_actions_sheet.dart';
import 'galaxy/galaxy_sample_data.dart';
import 'galaxy/galaxy_star_atlas.dart';
import 'galaxy/galaxy_replay_overlay.dart';

class GalaxyScreen extends StatefulWidget {
  /// Galaxy 内に表示中の overlay (replay / formation / moon) の有無が
  /// 変化するたびに呼ばれる。
  ///
  /// 🔴 用途 (2026-05-19、PopScope 二重防御の親側ガード):
  /// Flutter の PopScope は階層を持たず、ルート (main.dart) と Galaxy 内
  /// PopScope の onPopInvokedWithResult が **同時に** 呼ばれる。
  /// そのため main.dart 側で「Galaxy が overlay を持っているか」を知り、
  /// 持っている時は `_onTabTap(0)` (= Map タブへ戻す) を抑止する必要がある。
  /// 本コールバックでその情報を親 (SolaraHome) に押し上げる。
  final ValueChanged<bool>? onOverlayChanged;

  const GalaxyScreen({super.key, this.onOverlayChanged});

  @override
  State<GalaxyScreen> createState() => GalaxyScreenState();
}

class GalaxyScreenState extends State<GalaxyScreen>
    with TickerProviderStateMixin {
  /// `_hasActiveOverlay` の直近の通知値。build のたびにチェックし、
  /// 変化していれば onOverlayChanged を呼ぶ。
  bool? _lastReportedOverlay;
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

  // ── Motion state (Horoscope Phase 3c 路線 + Galaxy 専用 ease-out 減速) ──
  // 60fps `.repeat()` AnimationController で raster を回し続けるのを止め、
  // 単一 Timer.periodic 30fps で breath / autoRotate を駆動する。
  // ライフサイクル: 覚醒(tap/drag) → 30s フルスピード → 10s ease-out 減速 → 完全停止 (raster 0%)。
  // 完全停止中は _breathPhaseSec を据え置く (= sin 位置固定) → painter は同じ値を返す
  // → freeze/wake で alpha 切れ目ゼロ。"frozenAtMax で peakOp 上書き" は撤去 (ジャンプ要因)。
  double _breathPhaseSec = 0.0;        // breath 累積秒 (sin 引数として painter に渡す)
  Timer? _motionTimer;                  // 単一 30fps tick (breath + autoRotate 兼用)
  DateTime? _motionStartedAt;           // 覚醒時刻 (経過からフェーズ判定)
  static const Duration _motionTick = Duration(milliseconds: 33); // 30fps
  static const double _motionFps = 30.0;
  static const double _motionActiveSec = 30.0;   // フルスピード期間
  static const double _motionDecelSec = 10.0;    // ease-out 減速期間 (1→0)
  static const double _autoRotStep30fps = 0.005; // 60fps の 0.0025/frame と等価な 30fps step
  static const double _velDecay30fps = 0.81;     // pow(0.90, 60/30) ≈ 0.81 (60fps の 0.90 等価)

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
  // 画面復元 (Android プロセス死対策): true なら形成演出を最終フレーム
  // (共有ボタンあり完了画面) から表示する。通常起動・通常再生では false。
  bool _formationSkipToEnd = false;

  // HTML: ART_IMAGES — pre-loaded constellation art images
  final Map<int, ui.Image> _artImages = {};

  // Random seed for background stars & nebula positions (changes each open)
  int _bgSeed = DateTime.now().microsecondsSinceEpoch;

  /// タブ切替でGalaxyに入ってきた時に、背景 (ネビュラ位置・色・星の位置)
  /// を再生成 + motion 再起動 (40s 寿命タイマー fresh start) するための公開メソッド。
  /// main.dart から呼ばれる。
  void regenerateBackground() {
    setState(() {
      _bgSeed = DateTime.now().microsecondsSinceEpoch;
      _initNebulaPositions();
    });
    // タブ入室の見せ場 = motion fresh start (40s フル動作 → 減速 → 停止 のサイクル)
    _wakeMotion();
  }

  /// main.dart から Galaxy タブ離脱時に呼ばれる。Timer 即停止 = raster 0% 化。
  /// (TickerMode は AnimationController のみカバー、Timer.periodic は対象外なので明示停止)
  void pauseMotion() {
    _motionTimer?.cancel();
    _motionTimer = null;
  }

  /// タブ入室 / アプリ復帰時に、月イベント (新月・満月・刻星化) の発火判定だけを
  /// 軽量に再評価する。main.dart の _onTabTap (Galaxy 入室) と
  /// didChangeAppLifecycleState (resumed) から呼ばれる。
  ///
  /// 背景: _checkMoonOverlay は initState→_loadData でしか走らないため、warm resume
  /// (プロセス生存のままバックグラウンド復帰) や、別タブから満月当日に Galaxy へ入った
  /// 場合に overlay が出ない穴があった。
  ///
  /// _loadData 全体 (readings 読込・formConstellation・sample 注入・art ロード) は重く
  /// 副作用もあるので呼ばない。overlay 判定に必要な日付と intention だけ読み直す。
  /// 既に overlay / replay 表示中なら何もしない (進行中の演出を壊さない)。
  Future<void> recheckMoonEvents() async {
    if (!mounted || _activeOverlay != null || _replayCycle != null) return;
    final now = DateTime.now();
    final (cycleStart, cycleEnd) = MoonPhase.getCurrentCycleBounds(now);
    final csLocal = cycleStart.toLocal();
    final cycleId =
        '${csLocal.year}-${csLocal.month.toString().padLeft(2, '0')}';
    final intention = await SolaraStorage.loadIntention(cycleId);
    if (!mounted || _activeOverlay != null || _replayCycle != null) return;
    setState(() {
      _cycleStart = cycleStart;
      _totalDays = cycleEnd.difference(cycleStart).inDays;
      _currentIntention = intention;
    });
    await _checkMoonOverlay(now);
  }

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
    // motion 起動は `regenerateBackground()` (= main.dart _onTabTap が Galaxy タブ
    // 入室時に呼ぶ) に委譲。IndexedStack で initState は app 起動時に走るため、
    // ここで wake すると裏タブで Timer が走り CPU 浪費する。
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
    _motionTimer?.cancel();
    _popupTimer?.cancel();
    _replayController?.dispose();
    super.dispose();
  }

  /// motion 覚醒: 30s フルスピード → 10s ease-out 減速 → 完全停止 (raster 0%)。
  /// tap/drag のたびに呼ばれ、寿命カウンタをリセットする。
  void _wakeMotion() {
    _motionStartedAt = DateTime.now();
    _motionTimer?.cancel();
    _motionTimer = Timer.periodic(_motionTick, _onMotionTick);
  }

  /// 30fps tick — breath 位相 + autoRotate + 慣性減衰を一括更新。
  /// 経過 t に応じて速度倍率を ease-out cubic で 1→0 に落とし、40s で完全停止。
  void _onMotionTick(Timer t) {
    if (!mounted) {
      t.cancel();
      return;
    }
    final elapsed = DateTime.now().difference(_motionStartedAt!).inMilliseconds / 1000.0;

    // 完全停止フェーズ: timer 解除のみ。`_breathPhaseSec` は据え置きで sin 位置を固定
    // → painter は freeze 中 / wake 直後で同じ alpha を返す = 切れ目ゼロ。
    if (elapsed >= _motionActiveSec + _motionDecelSec) {
      t.cancel();
      _motionTimer = null;
      setState(() {
        _velX = 0;
        _velY = 0;
      });
      return;
    }

    // 速度倍率: 0..30s = 1.0、30..40s = ease-out cubic で 1→0
    final double speedMul;
    if (elapsed < _motionActiveSec) {
      speedMul = 1.0;
    } else {
      final tt = (elapsed - _motionActiveSec) / _motionDecelSec; // 0..1
      speedMul = 1.0 - tt * tt * tt;                              // ease-out cubic
    }

    setState(() {
      // breath: 実時間秒で進める (painter 内 sin 用、停止時は frozen 側で 1.0 固定)
      _breathPhaseSec += (1.0 / _motionFps) * speedMul;
      // autoRotate: drag 中は触らない (ユーザー操作優先)
      if (!_dragging) {
        _rotY += _autoRotStep30fps * speedMul;
      }
      // 慣性減衰: drag 後の余韻 (60fps→30fps 等価係数)
      _velX *= _velDecay30fps;
      _velY *= _velDecay30fps;
      _rotX += _velX;
      _rotY += _velY;
    });
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

    // cycleStart は JST 当日 0:00 を UTC instant にしたもの。
    // .year/.month を直接読むと UTC 視点になり月またぎでズレるため、必ず .toLocal() 経由。
    final csLocal = cycleStart.toLocal();
    final cycleId = '${csLocal.year}-${csLocal.month.toString().padLeft(2, '0')}';
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

    await _checkMoonOverlay(now);

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

  /// 月イベント (新月/満月/刻星化) の発火を判定し、該当すれば overlay を出す。
  ///
  /// 2026-06-01: 発火条件を [MoonEventStatus.pendingToday] に一本化 (NavBar バッジ /
  /// Map 案内バナーと共有して乖離を防ぐ)。判定ロジック本体はそちらを参照。
  /// 端末日付 (0 時切替) 基準で、Sanctuary のクレジットリセット時刻には左右されない。
  Future<void> _checkMoonOverlay(DateTime now) async {
    final kind = await MoonEventStatus.pendingToday(now);
    if (!mounted || kind == null) return;
    setState(() {
      _activeOverlay = switch (kind) {
        MoonEventKind.newMoon => 'new_moon',
        MoonEventKind.fullMoon => 'full_moon',
        MoonEventKind.catasterism => 'catasterism',
      };
    });
  }

  /// 画面内で active な overlay (replay / formation / moon)。
  /// Android の back キー処理 (PopScope) で「閉じるべき overlay があるか」を判定する。
  bool get _hasActiveOverlay =>
      _replayCycle != null ||
      _activeOverlay == 'formation' ||
      _activeOverlay == 'catasterism' ||
      _activeOverlay == 'new_moon' ||
      _activeOverlay == 'full_moon';

  /// PopScope の onPopInvokedWithResult から呼ばれる。active な overlay を
  /// 1 段ずつ閉じる (最後に閉じきると main.dart の PopScope に処理が落ちる)。
  void _dismissTopOverlay() {
    if (_replayCycle != null) {
      _closeReplay();
      return;
    }
    if (_activeOverlay != null) {
      setState(() {
        _activeOverlay = null;
        _formationCycle = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔴 overlay 状態を親 (SolaraHome) に伝える (2026-05-19)。
    // Flutter PopScope は階層を持たないため、本画面の PopScope と main.dart の
    // PopScope の onPopInvokedWithResult が同時に呼ばれてしまう。親側で
    // 「Galaxy が overlay 中なら _onTabTap(0) を抑止」するために値を押し上げる。
    final hasOverlay = _hasActiveOverlay;
    if (_lastReportedOverlay != hasOverlay) {
      _lastReportedOverlay = hasOverlay;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onOverlayChanged?.call(hasOverlay);
      });
    }
    return PopScope(
      // overlay がある間は back を Galaxy 内で消化する。
      // overlay が無い時は main.dart の PopScope (Map タブへ戻る) に委ねる。
      canPop: !_hasActiveOverlay,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _dismissTopOverlay();
      },
      child: TapToUnfocus(
        child: Container(
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
                // DEBUG: Cycle完了フローの各タイミングを手動トリガー
                // (release 時のみ非表示、profile build では表示してテスト可能)
                if (!kReleaseMode) _buildDebugTriggerRow(),
                if (!kReleaseMode) const SizedBox(height: 4),
                // HTML: .tab-panel.active { flex:1; display:flex; flex-direction:column; }
                Expanded(
                  child: _activeTab == 0
                      ? _buildCycleTab()
                      : GalaxyStarAtlasTab(
                          completedCycles: _completedCycles,
                          artImages: _artImages,
                          onOpenReplay: _openReplay,
                          onLongPressCard: _openCycleActions,
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
                    child: _buildStellaMessage(context),
                  ),
              ],
            ),
            if (_popupDayIndex >= 0) _buildDotPopup(),
            // 🔴 内側 PopScope で二重防御 (formation と同じ理由、2026-05-19)
            if (_replayCycle != null)
              PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) {
                  if (didPop) return;
                  _closeReplay();
                },
                child: GalaxyReplayOverlay(
                  cycle: _replayCycle!,
                  controller: _replayController!,
                  artImage: _artImages[_replayCycle!.nounIdx],
                  onClose: _closeReplay,
                  // 通常再生からの共有 = 背景なしカード (bgImage 渡さない)。
                  onShare: () => _openConstellationShare(_replayCycle!),
                ),
              ),
            if (_activeOverlay != null) _buildMoonOverlay(),
          ],
        ),
      ),
      ),
      ),
    );
  }

  // HTML: .inner-tabs
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Expanded(child: _buildTab(0, AntiqueIcon.cycle, 'Cycle')),
        Expanded(child: _buildTab(1, AntiqueIcon.pattern, 'Star Atlas')),
      ]),
    );
  }

  Widget _buildTab(int index, AntiqueIcon icon, String label) {
    final isActive = _activeTab == index;
    final color = isActive ? const Color(0xFFF9D976) : const Color(0x80FFFFFF);
    return GestureDetector(
      onTap: () {
        setState(() => _activeTab = index);
        // Cycle (= 0) 入室時のみ motion 起動。Star Atlas (= 1) では Cycle 描画自体
        // 走らないので Timer も停止する (= raster 0%)。
        if (index == 0) {
          _wakeMotion();
        } else {
          pauseMotion();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(
            color: isActive ? const Color(0xFFF9D976) : Colors.transparent, width: 2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AntiqueGlyph(icon: icon, size: 16, color: color, glow: isActive),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cinzel(
                  color: color, fontSize: 13, letterSpacing: 1.8,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
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
          // `.repeat()` AnimationController + AnimatedBuilder を撤去し、
          // _onMotionTick() の setState 駆動に統一 (raster lifecycle 制御のため)。
          child: Builder(builder: (context) {
            final painter = CycleSpiralPainter(
              days: _cycleDays,
              currentDayIndex: _currentDayIndex,
              totalDays: _totalDays,
              rotX: _rotX, rotY: _rotY, zoom: _zoom,
              breathPhase: _breathPhaseSec,
              cycleStart: _cycleStart,
              bgSeed: _bgSeed,
            );
            _lastPainter = painter;
            return CustomPaint(painter: painter, size: Size.infinite);
          }),
        ),
        Positioned(top: 8, right: 20, child: _buildDayBadge()),
        Positioned(top: 8, left: 20, child: _buildMoonBadge()),
        // Stella は親Columnの末尾で共有表示 (HTML準拠)
      ],
    );
  }

  Widget _buildDayBadge() {
    // 2026-06-03: タップで「月のイベント」案内 popup を開けるようにした
    // (新月/満月/刻星化 の説明 + 通知の勧め)。右下に ⓘ ヒントを添える。
    return GestureDetector(
      onTap: () => _showMoonEventsGuide(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x1FF9D976),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x47F9D976)),
        ),
        child: Column(children: [
          // サイクル日数表記を月齢 (0-indexed) に揃える。
          // _currentDayIndex は MoonPhase.getCurrentDayIndex で
          // 「JST 新月発生日 0:00 → JST 当日 0:00 の経過日数」を返すので、
          // 検索サイト等で見る月齢と同じ数字になる。
          // (旧: +1 した 1-indexed 表記。新月日が「Day 1」になり、
          //  検索サイト等の月齢と 1 ズレてユーザーが混乱していた。)
          Text('$_currentDayIndex', style: GoogleFonts.cinzel(
            fontSize: 22, fontWeight: FontWeight.w700,
            color: const Color(0xFFF9D976), height: 1)),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text('of $_totalDays', style: GoogleFonts.cinzel(
              fontSize: 13, color: const Color(0xA6F9D976), letterSpacing: 1.5)),
            const SizedBox(width: 3),
            const Icon(Icons.info_outline,
                size: 11, color: Color(0xA6F9D976)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildMoonBadge() {
    final info = MoonPhase.getPhaseInfo(DateTime.now());
    // 2026-05-08: 月齢バッジをタップ可能化。
    // 月齢の説明 → Galaxy 画面全体 (CYCLE / Star Atlas) の使い方を
    // 1 つの popup で順に説明する (ユーザー要望: 機能をパッと見て理解)。
    return GestureDetector(
      onTap: () => _showGalaxyUsageGuide(context, info),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x1AC0C8E0),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x38C0C8E0)),
        ),
        child: Column(children: [
          Text(info.emoji, style: const TextStyle(fontSize: 20, height: 1)),
          const SizedBox(height: 2),
          Text(info.label, style: GoogleFonts.cinzel(
            fontSize: 13, color: const Color(0xA6C0C8E0), letterSpacing: 1.2)),
        ]),
      ),
    );
  }

  Widget _buildStellaMessage(BuildContext context) {
    final isJP = Localizations.localeOf(context).languageCode == 'ja';
    final now = DateTime.now();

    // 月相連動メッセージ (当日 / 3 日以内) を最優先で表示。
    // 該当しない場合は、月齢に沿った癒しメッセージ (日替わり) にフォールバック。
    final msg = _stellaMoonPhaseMsg(now, isJP: isJP) ??
        moonHealingMessage(now, isJP: isJP);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Stella label — 小文字混じり「Stella」で表示するため Cormorant Garamond Bold。
        // (Cinzel は大文字専用書体で "STELLA" になってしまうため変更。2026-05-31)
        Row(children: [
          const AntiqueGlyph(icon: AntiqueIcon.pattern, size: 13,
            color: Color(0xFFF9D976), glow: false),
          const SizedBox(width: 5),
          Text('Stella', style: GoogleFonts.cormorantGaramond(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: const Color(0xFFF9D976), letterSpacing: 1.0)),
        ]),
        const SizedBox(height: 8),
        // Message body — Cormorant italic (letter-like), w500で読みやすく
        // 1.5x でメッセージが伸びても、上の Cycle 螺旋キャンバス (Expanded) を縦圧迫しないよう
        // 高さ上限 + 内部スクロール (枠は固定・本文だけスクロール)。描画側は一切変更しない。
        ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.18),
          child: SingleChildScrollView(
            child: Text(msg, style: GoogleFonts.cormorantGaramond(
              fontSize: 14, fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: const Color(0xFFEAEAEA), height: 1.6)),
          ),
        ),
      ]),
    );
  }

  /// 新月・満月の発生時刻 (端末ローカル時刻) を Stella メッセージに告知する。
  /// 当日 (isFullMoon / isNewMoon) または 3 日以内 (72h) の場合のみ
  /// メッセージを返す。それ以外は null (= 既存メッセージへフォールバック)。
  String? _stellaMoonPhaseMsg(DateTime now, {required bool isJP}) {
    String fmtTime(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    String fmtDate(DateTime d) =>
        '${d.month}/${d.day.toString().padLeft(2, '0')}';

    // 1. 今日が満月の日
    if (MoonPhase.isFullMoon(now)) {
      final fm = MoonPhase.findFullMoonInCycle(now).toLocal();
      return isJP
          ? '今日 ${fmtTime(fm)} が満月のピーク。'
          : 'Today ${fmtTime(fm)} is the full moon.';
    }
    // 2. 今日が新月の日
    if (MoonPhase.isNewMoon(now)) {
      final nm = MoonPhase.findPreviousNewMoon(now).toLocal();
      return isJP
          ? '今日 ${fmtTime(nm)} が新月のピーク。'
          : 'Today ${fmtTime(nm)} is the new moon.';
    }
    // 3. 次の新月まで 3 日以内
    final nextNew = MoonPhase.findNextNewMoon(now).toLocal();
    final hoursToNew = nextNew.difference(now).inHours;
    if (hoursToNew > 0 && hoursToNew < 72) {
      final dt = '${fmtDate(nextNew)} ${fmtTime(nextNew)}';
      return isJP
          ? '次の新月まであと $hoursToNew 時間 — $dt。'
          : 'New moon in $hoursToNew hour${hoursToNew > 1 ? 's' : ''} — $dt.';
    }
    // 4. 次の満月まで 3 日以内
    final fullMoon = MoonPhase.findFullMoonInCycle(now).toLocal();
    final hoursToFull = fullMoon.difference(now).inHours;
    if (hoursToFull > 0 && hoursToFull < 72) {
      final dt = '${fmtDate(fullMoon)} ${fmtTime(fullMoon)}';
      return isJP
          ? '次の満月まであと $hoursToFull 時間 — $dt。'
          : 'Full moon in $hoursToFull hour${hoursToFull > 1 ? 's' : ''} — $dt.';
    }
    return null;
  }

  // --- 3D interaction ---

  void _onDragStart(DragStartDetails d) {
    _dragging = true;
    _lastDrag = d.localPosition;
    _velX = 0; _velY = 0;
    _wakeMotion();    // ユーザー操作 = 寿命タイマー reset & motion 再開
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

  void _onDragEnd(DragEndDetails d) {
    _dragging = false;
    _wakeMotion();    // drag 終了直後の慣性余韻を tick で見せるため再起動
  }

  void _onTapUp(TapUpDetails details) {
    _wakeMotion();    // tap も「触った」と見なし motion 再覚醒
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
            fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFF9D976), letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Row(children: [
            Flexible(
              child: Text(card.emoji,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(card.nameEN,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFEAEAEA)))),
          ]),
          const SizedBox(height: 8),
          if (card.planet != null)
            Text('Planet: ${planetNamesJP[card.planet] ?? card.planet}', style: const TextStyle(
              fontSize: 13, color: Color(0xCCACACAC))),
          const SizedBox(height: 4),
          Text('Keyword: ${card.keyword}', style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w300, color: Color(0xB3F9D976))),
          const SizedBox(height: 6),
          const Text('"Your momentum is cosmic."', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w300, color: Color(0xB3ACACAC), fontStyle: FontStyle.italic)),
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

  /// 星座カード共有画面を開く (Free 機能、柱 3)。
  /// 刻星化 formation overlay 完了時の「共有」ボタンと、
  /// 将来 Star Atlas カード ⋯ メニューからも呼べる導線。
  /// [bgImage] あり = 形成演出からの共有 (神殿背景つき)、
  /// null = 通常再生からの共有 (背景なし)。
  void _openConstellationShare(GalaxyCycle cycle, {ui.Image? bgImage}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConstellationShareCardPage(
          cycle: cycle,
          artImage: _artImages[cycle.nounIdx],
          bgImage: bgImage,
        ),
      ),
    );
  }

  // ====================== C5: Cycle Actions (long-press) ======================

  /// Star Atlas カード長押しで開く Pro メニュー (通常再生 / 形成演出 / エクスポート)。
  /// `pro_candidates.md` §7.3 「形成演出の再生 + エクスポート」(C5) の入口。
  void _openCycleActions(GalaxyCycle cycle) {
    showGalaxyCycleActionsSheet(
      context: context,
      cycle: cycle,
      onReplay: () => _openReplay(cycle),
      onPlayFormation: (c) {
        _loadArtImage(c.nounIdx);
        setState(() {
          _activeOverlay = 'formation';
          _formationCycle = c;
          _formationSkipToEnd = false; // 通常再生は最初から
        });
      },
      intentionLoader: SolaraStorage.loadIntention,
    );
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
      cycleId: '${_cycleStart.toLocal().year}-${_cycleStart.toLocal().month.toString().padLeft(2, '0')}',
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
      cycleId: '${_cycleStart.toLocal().year}-${_cycleStart.toLocal().month.toString().padLeft(2, '0')}',
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

    for (final day in selectedDays) {
      final cardId = rng.nextInt(78); // 0-77 自然分布
      final isMajor = cardId < 22;
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
    // 旧: ここで「刻星化: Nサイクル前, ...」の SnackBar を 3 秒表示していたが、
    //    刻星化アニメーションを邪魔する案内だったため撤去 (デバッグログとしては
    //    主要パラメータが majorCount/minorCount に変数として残るので必要なら
    //    print/debugPrint で復活可能)。
  }

  // ====================== MOON OVERLAYS ======================

  Widget _buildMoonOverlay() {
    final csLocal = _cycleStart.toLocal();
    final cycleId = '${csLocal.year}-${csLocal.month.toString().padLeft(2, '0')}';
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
          // 🔴 内側 PopScope で二重防御 (2026-05-19):
          // Galaxy 画面の root PopScope だけでは「完了演出表示中に back →
          // Map タブへ飛ぶ」事象が再発する報告あり (オーナー、2 回目)。
          // Positioned.fill 直下に PopScope を入れ、formation overlay が
          // 出ている間の back キーは必ずここで消化して overlay を閉じる。
          // canPop=false なので親 (main.dart) の PopScope へは伝播しない。
          return Positioned.fill(
            child: PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) return;
                _dismissTopOverlay();
              },
              child: CatasterismFormationOverlay(
                cycle: _formationCycle!,
                artImage: _artImages[_formationCycle!.nounIdx],
                onComplete: _onFormationComplete,
                onShare: (bgImage) =>
                    _openConstellationShare(_formationCycle!, bgImage: bgImage),
                startFinished: _formationSkipToEnd,
              ),
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
      _formationSkipToEnd = false;
      _activeTab = 1; // Star Atlasタブへ
    });
  }

  // ── 画面復元 (Android プロセス死対策) ──────────────────────────
  // SolaraHome が paused 時に captureRestore() で「Star atlas 共有画面 (通常再生終了 /
  // 形成演出終了)」の状態を吸い上げ、コールド起動時に restoreGalaxyState() で
  // 最終フレーム (共有ボタンあり) を直接再表示する。

  /// 共有ボタンが出ている終了画面が開いていれば {overlay, cycle} を返す。それ以外は null。
  Map<String, dynamic>? captureRestore() {
    if (_replayCycle != null) {
      return {'overlay': 'replay', 'cycle': _replayCycle!.toJson()};
    }
    if (_activeOverlay == 'formation' && _formationCycle != null) {
      return {'overlay': 'formation', 'cycle': _formationCycle!.toJson()};
    }
    return null;
  }

  /// captureRestore のスナップショットから終了画面を再現する (コールド起動時)。
  void restoreGalaxyState(Map<String, dynamic> data) {
    if (!mounted) return;
    final raw = data['cycle'];
    if (raw is! Map) return;
    final GalaxyCycle cycle;
    try {
      cycle = GalaxyCycle.fromJson(Map<String, dynamic>.from(raw));
    } catch (_) {
      return;
    }
    final overlay = data['overlay'] as String?;
    if (overlay == 'replay') {
      // 通常再生の最終フレーム (共有ボタンあり) へジャンプ。
      _loadArtImage(cycle.nounIdx);
      _replayController?.dispose();
      _replayController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 6500),
      );
      setState(() => _replayCycle = cycle);
      _replayController!.value = 1.0;
    } else if (overlay == 'formation') {
      // 形成演出の最終フレーム (共有ボタンあり) へジャンプ (startFinished 経由)。
      _loadArtImage(cycle.nounIdx);
      setState(() {
        _activeOverlay = 'formation';
        _formationCycle = cycle;
        _formationSkipToEnd = true;
      });
    }
  }
}

/// 月齢ごとの詩的な解説 (popup の冒頭で表示)。
/// labelJP (新月 / 三日月 / 上弦の月 / 十三夜月 / 満月 / 十八夜月 /
///        下弦の月 / 二十六夜月) で分岐。
String _moonPhaseDescription(String labelJP) {
  switch (labelJP) {
    case '新月':
      return '始まりの時。\n'
          '空が最も暗く、星々が最もよく見える夜。\n'
          '新しい意図を立て、種を蒔く時間帯です。';
    case '三日月':
      return '芽吹きの時。\n'
          '細い光が西の空に現れます。\n'
          '新月で蒔いた意図に向けて、少しずつ動き出す時間帯。';
    case '上弦の月':
      return '行動の時。\n'
          '半月が天頂に達し、決断と行動が求められます。\n'
          '芽生えた意図を形にしていく転換点。';
    case '十三夜月':
      return '高まりの時。\n'
          '月が満ちていく勢いがピークに近づきます。\n'
          '準備が整い、表現が膨らむ時間帯。';
    case '満月':
      return '達成・解放の時。\n'
          '月が最も明るく輝く夜。\n'
          '気づきと完了がやってきます。\n'
          '手にしたものを見つめ直し、感謝する時間帯。';
    case '十八夜月':
      return '共有の時。\n'
          '月が欠け始めます。\n'
          '満月で得た学びを他者と分かち合う時間帯。';
    case '下弦の月':
      return '手放しの時。\n'
          '半月が逆向きに浮かびます。\n'
          '不要なものを整理し、ゆるめる時間帯。';
    case '二十六夜月':
      return '休息の時。\n'
          '空に薄い月が残ります。\n'
          '次のサイクルへ向けて静かに整える時間帯。';
    default:
      return '月のサイクルが流れています。';
  }
}

/// 右上の月齢バッジ (サイクル日数) をタップで開く「月のイベント」案内。
/// 新月 → 満月 → 刻星化 の 3 イベントと、その発生条件・通知の勧めを説明する。
/// 発生条件は MoonEventStatus.pendingToday と整合 (満月/刻星化は新月の意図設定が前提)。
void _showMoonEventsGuide(BuildContext context) {
  showInfoPopup(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('月のイベントについて',
            style: TextStyle(
                color: Color(0xFFC9A84C), fontSize: 14, letterSpacing: 1)),
        SizedBox(height: 10),
        Text(
          'このサイクルでは、月の満ち欠けに合わせて\n'
          '3 つの節目があなたを訪れます。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.7),
        ),
        SizedBox(height: 14),
        Text('🌑 新月イベント',
            style: TextStyle(
                color: Color(0xFFC9A84C),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        SizedBox(height: 4),
        Text(
          '新月の日に「意図（インテンション）」を立てる出発点。\n'
          'このサイクルで大切にしたいことを言葉にします。\n'
          'すべてはここから始まります。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.7),
        ),
        SizedBox(height: 12),
        Text('🌕 満月イベント',
            style: TextStyle(
                color: Color(0xFFC9A84C),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        SizedBox(height: 4),
        Text(
          '満月の日に、立てた意図への中間チェック（振り返り）。\n'
          '※ 新月で意図を立てていないと出てきません。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.7),
        ),
        SizedBox(height: 12),
        Text('✦ 刻星化イベント',
            style: TextStyle(
                color: Color(0xFFC9A84C),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        SizedBox(height: 4),
        Text(
          '次の新月の前日以降に訪れる、サイクルの締めくくり。\n'
          '手放しと、あなただけの星座の形成です。\n'
          '※ こちらも新月で意図を立てているのが前提です。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.7),
        ),
        SizedBox(height: 16),
        Divider(color: Color(0x33C9A84C), height: 1),
        SizedBox(height: 16),
        Text('🔔 通知をオンにするのがおすすめ',
            style: TextStyle(
                color: Color(0xFFF9D976),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        SizedBox(height: 4),
        Text(
          '各イベントは「その日」だけ訪れます。\n'
          'Sanctuary で通知をオンにしておくと、\n'
          '当日の朝にお知らせします。\n\n'
          '満月・刻星化は新月の意図設定が前提なので、\n'
          'まず新月を逃さないことが大切です。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.7),
        ),
      ],
    ),
  );
}

/// Galaxy 画面の総合ガイド popup (月齢バッジをタップで開く)。
/// 月齢の説明 → Galaxy 画面全体 → CYCLE タブ → Star Atlas タブを
/// 1 つの popup で順に表示する。
void _showGalaxyUsageGuide(
    BuildContext context, ({String label, String labelJP, String emoji}) info) {
  showInfoPopup(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 今日の月齢 ──
        Row(
          children: [
            Flexible(
              child: Text(info.emoji,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '今日の月: ${info.labelJP}',
                    style: const TextStyle(
                        color: Color(0xFFC9A84C),
                        fontSize: 14,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    info.label,
                    style: const TextStyle(
                        color: Color(0xA6C0C8E0),
                        fontSize: 11,
                        letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _moonPhaseDescription(info.labelJP),
          style: const TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.7),
        ),
        const SizedBox(height: 16),
        const Divider(color: Color(0x33C9A84C), height: 1),
        const SizedBox(height: 16),
        // ── Galaxy 画面とは ──
        const Text(
          'Galaxy 画面とは',
          style: TextStyle(
              color: Color(0xFFC9A84C), fontSize: 14, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        const Text(
          '月のサイクル (約 29.5 日) に合わせて、\n'
          'あなたの日々のタロットリーディングが\n'
          '「星」として記録されていく画面です。\n\n'
          '1 サイクル = 1 つの constellation (星座) が完成。\n'
          '内面のリズムが、星座という形で残っていきます。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.7),
        ),
        const SizedBox(height: 16),
        // ── CYCLE タブ ──
        const Text(
          '🌌 CYCLE タブ (現在のサイクル)',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 6),
        const Text(
          '今の月サイクルの「現在地」を表示。\n'
          '日々の reading を描いた "dot" が螺旋上に並び、\n'
          '完成に向けて進んでいきます。\n\n'
          '・右上の数字: サイクル何日目か (例: 23 of 30)\n'
          '・左上の月齢バッジ: 今日の月の相 (← 今ココ)\n'
          '・ドラッグで 3D 回転\n'
          '・dot タップで該当日のリーディングを表示\n'
          '・新月・満月の日は特別オーバーレイで\n'
          '　意図を立てる/振り返るアクションを促します',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.7),
        ),
        const SizedBox(height: 14),
        // ── Star Atlas タブ ──
        const Text(
          '🌟 Star Atlas タブ (過去の星座図鑑)',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 6),
        const Text(
          '完成した過去のサイクル (= 星座) のコレクション。\n'
          '1 つ 1 つが、あなた自身の内面が紡いだ星座です。\n\n'
          '・各カードは 1 サイクル分の reading が織りなす星座\n'
          '・カードタップで再アニメ + 詳細表示\n'
          '　(星座名・期間・レア度)\n'
          '・レア度: 5 段階の星評価 (★)\n'
          '　レア度が高いほど「珍しい組み合わせ」が出た証',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.7),
        ),
        const SizedBox(height: 14),
        // ── 月のサイクルの意味 ──
        const Text(
          '月のサイクルの意味',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 6),
        const Text(
          '🌑 新月 → 始まり。種を蒔く時。\n'
          '🌕 満月 → 達成・解放。気づきの時。\n\n'
          '1 サイクルかけて、あなたの内面が 1 つの星座に\n'
          'なっていきます。Tarot タブで日々のカードを\n'
          '引いて、ゆっくり育てていってください。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.7),
        ),
      ],
    ),
  );
}
