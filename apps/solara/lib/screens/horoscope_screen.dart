import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/solara_storage.dart';

import 'horoscope/horo_constants.dart';
import 'horoscope/horo_chart_painter.dart';
import 'horoscope/horo_fortune_cards.dart';
import 'horoscope/horo_bottom_panels.dart';

class HoroscopeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToSanctuary;
  const HoroscopeScreen({super.key, this.onNavigateToSanctuary});
  @override
  State<HoroscopeScreen> createState() => HoroscopeScreenState();
}

class HoroscopeScreenState extends State<HoroscopeScreen> {
  SolaraProfile? _profile;
  bool _loading = true;
  bool _birthTimeUnknown = false;

  // HTML: chartMode 'single' | 'nt' | 'np' | 'astrology'
  String _chartMode = 'single';

  // HTML: bottom sheet 3-state: mini(52px) / half(~280px) / full(~500px)
  int _bsState = 1; // 0=mini, 1=half, 2=full

  // Bottom sheet — HTML: bs-tab: ⚙ 誕生 / ☾ 経過(hidden unless nt/np) / ☉ 天体 / ⚙ 絞込 / △ 相
  String _bsTab = 'birth';


  // Planet data (mock until CF Worker deployed)
  Map<String, double> _natalPlanets = {};
  Map<String, double> _secondaryPlanets = {}; // transit or progressed
  double _asc = 0, _mc = 0;
  List<Map<String, dynamic>> _aspects = [];

  // Aspect filters — HTML: activeFilters
  final Map<String, bool> _qualityFilters = {'soft': true, 'hard': true, 'neutral': true};
  final Map<String, bool> _pgroupFilters = {'personal': true, 'social': true, 'generational': true};
  String? _fortuneFilter;
  final Set<String> _hiddenAspects = {};
  // Pattern visibility toggle (grandtrine / tsquare / yod)
  final Map<String, bool> _patternVisible = {'grandtrine': true, 'tsquare': true, 'yod': true};

  @override
  void initState() { super.initState(); loadProfile(); }

  @override
  @override
  void dispose() { super.dispose(); }

  Future<void> loadProfile() async {
    final p = await SolaraStorage.loadProfile();
    if (p != null && p.isComplete) {
      _birthTimeUnknown = p.birthTimeUnknown;
      _generateMockChart(p);
    }
    setState(() { _profile = p; _loading = false; });
  }

  void _generateMockChart(SolaraProfile p) {
    final parts = p.birthDate.split('-').map(int.parse).toList();
    final seed = parts[0] * 365 + parts[1] * 30 + parts[2];
    final rng = Random(seed);
    const keys = ['sun','moon','mercury','venus','mars','jupiter','saturn','uranus','neptune','pluto'];
    for (final k in keys) { _natalPlanets[k] = rng.nextDouble() * 360; }
    final month = parts[1], day = parts[2];
    _natalPlanets['sun'] = _approxSunLon(month, day);
    _asc = rng.nextDouble() * 360;
    _mc = (_asc + 90 + rng.nextDouble() * 30 - 15) % 360;

    _generateTransitPlanets();
    _recalcAspects();
  }

  /// HTML: transit = current sky positions (mock: seed from today's date)
  void _generateTransitPlanets() {
    final now = DateTime.now();
    final seed = now.year * 365 + now.month * 30 + now.day;
    final rng = Random(seed + 9999);
    const keys = ['sun','moon','mercury','venus','mars','jupiter','saturn','uranus','neptune','pluto'];
    _secondaryPlanets = {};
    for (final k in keys) { _secondaryPlanets[k] = rng.nextDouble() * 360; }
    _secondaryPlanets['sun'] = _approxSunLon(now.month, now.day);
  }

  /// HTML: progressed = 1 day = 1 year method (mock)
  void _generateProgressedPlanets() {
    if (_profile == null) return;
    final parts = _profile!.birthDate.split('-').map(int.parse).toList();
    final birthDate = DateTime(parts[0], parts[1], parts[2]);
    final now = DateTime.now();
    final yearsLived = now.difference(birthDate).inDays / 365.25;
    final progDate = birthDate.add(Duration(days: yearsLived.round()));
    final seed = progDate.year * 365 + progDate.month * 30 + progDate.day;
    final rng = Random(seed + 7777);
    const keys = ['sun','moon','mercury','venus','mars','jupiter','saturn','uranus','neptune','pluto'];
    _secondaryPlanets = {};
    for (final k in keys) { _secondaryPlanets[k] = rng.nextDouble() * 360; }
    _secondaryPlanets['sun'] = _approxSunLon(progDate.month, progDate.day);
  }

  /// Recalculate aspects based on current chart mode
  void _recalcAspects() {
    _aspects = [];
    const keys = ['sun','moon','mercury','venus','mars','jupiter','saturn','uranus','neptune','pluto'];

    if (_chartMode == 'single') {
      // N-N aspects
      for (int i = 0; i < keys.length; i++) {
        for (int j = i + 1; j < keys.length; j++) {
          _addAspect(keys[i], keys[j], _natalPlanets[keys[i]]!, _natalPlanets[keys[j]]!);
        }
      }
    } else {
      // N-T or N-P: natal vs secondary
      final sec = _secondaryPlanets;
      for (int i = 0; i < keys.length; i++) {
        for (int j = 0; j < keys.length; j++) {
          _addAspect(keys[i], keys[j], _natalPlanets[keys[i]]!, sec[keys[j]] ?? 0,
            label: _chartMode == 'nt' ? 'N-T' : 'N-P');
        }
      }
    }

    // Angle aspects (skip if birthTimeUnknown)
    if (!_birthTimeUnknown) {
      final dsc = (_asc + 180) % 360;
      final ic = (_mc + 180) % 360;
      final anglePoints = [('asc', _asc), ('mc', _mc), ('dsc', dsc), ('ic', ic)];
      for (final (angleKey, angleLon) in anglePoints) {
        for (final planetKey in keys) {
          _addAspect(angleKey, planetKey, angleLon, _natalPlanets[planetKey]!, isAngle: true);
        }
      }
    }
  }

  void _addAspect(String p1, String p2, double lon1, double lon2, {String label = 'N-N', bool isAngle = false}) {
    final diff = _angDist(lon1, lon2);
    for (final asp in aspectTypes) {
      final aspAngle = asp['angle'] as double;
      final aspOrb = asp['orb'] as double;
      if ((diff - aspAngle).abs() <= aspOrb) {
        _aspects.add({
          'p1': p1, 'p2': p2, 'type': asp['key'], 'diff': diff,
          'quality': asp['quality'], 'color': asp['color'] as Color,
          'lon1': lon1, 'lon2': lon2,
          'aspectAngle': aspAngle, 'orb': aspOrb,
          'label': label, 'isAngle': isAngle,
        });
      }
    }
  }

  double _approxSunLon(int m, int d) {
    final dayOfYear = DateTime(2000, m, d).difference(DateTime(2000, 3, 21)).inDays;
    return (dayOfYear * 360.0 / 365.25) % 360;
  }

  double _angDist(double a, double b) {
    final d = (a - b).abs() % 360;
    return d > 180 ? 360 - d : d;
  }

  /// フィルター判定（trueならアクティブ、falseなら暗く表示）
  bool _aspectPassesFilter(Map<String, dynamic> a) {
    final q = a['quality'] as String;
    if (!(_qualityFilters[q] ?? true)) return false;
    final g1 = planetGroups[a['p1']] ?? 'personal';
    final g2 = planetGroups[a['p2']] ?? 'personal';
    if (g1 == 'angle' || g2 == 'angle') {
      final other = g1 == 'angle' ? g2 : g1;
      if (other != 'angle' && !(_pgroupFilters[other] ?? true)) return false;
    } else if (!(_pgroupFilters[g1] ?? true) && !(_pgroupFilters[g2] ?? true)) {
      return false;
    }
    if (_fortuneFilter != null) {
      final fp = fortunePlanets[_fortuneFilter] ?? [];
      if (!fp.contains(a['p1']) && !fp.contains(a['p2'])) return false;
    }
    return true;
  }

  /// 全アスペクトにdimmedフラグを付けて返す（リスト表示用）
  List<Map<String, dynamic>> _allAspectsWithDimmed() {
    return _aspects.map((a) {
      final key = '${a['type']}_${a['p1']}_${a['p2']}';
      final hidden = _hiddenAspects.contains(key);
      final filtered = !_aspectPassesFilter(a);
      return {...a, 'dimmed': hidden || filtered};
    }).toList();
  }

  /// チャート描画用（dimmedは暗く描画）
  List<Map<String, dynamic>> _chartAspects() => _allAspectsWithDimmed();

  /// モードに合致するパターンのみ抽出
  /// single: N-Nのみ, nt: Tを含むもののみ, np: Pを含むもののみ
  Map<String, List<Map<String, dynamic>>> _modeFilteredPatterns() {
    final all = detectPatterns(_natalPlanets, secondary: _secondaryPlanets, chartMode: _chartMode);
    final result = <String, List<Map<String, dynamic>>>{};
    for (final type in ['grandtrine', 'tsquare', 'yod']) {
      result[type] = (all[type] ?? []).where((p) {
        final sources = p['sources'] as List<String>? ?? [];
        if (_chartMode == 'single') return sources.every((s) => s == 'N');
        if (_chartMode == 'nt') return sources.any((s) => s == 'T');
        if (_chartMode == 'np') return sources.any((s) => s == 'P');
        return true;
      }).toList();
    }
    return result;
  }

  /// 指定モードで成立する特殊アスペクトを取得
  Map<String, List<Map<String, dynamic>>> _patternsForMode(String mode) {
    final sec = mode == 'single' ? <String, double>{} : _secondaryPlanets;
    final all = detectPatterns(_natalPlanets, secondary: sec, chartMode: mode);
    final result = <String, List<Map<String, dynamic>>>{};
    for (final type in ['grandtrine', 'tsquare', 'yod']) {
      result[type] = (all[type] ?? []).where((p) {
        final sources = p['sources'] as List<String>? ?? [];
        if (mode == 'single') return sources.every((s) => s == 'N');
        if (mode == 'nt') return sources.any((s) => s == 'T');
        if (mode == 'np') return sources.any((s) => s == 'P');
        return true;
      }).toList();
    }
    return result;
  }

  /// パターン表示フィルタ（ON/OFFトグル反映 + モードフィルタ）
  Map<String, List<Map<String, dynamic>>> _visiblePatterns() {
    final filtered = _modeFilteredPatterns();
    return {
      for (final type in ['grandtrine', 'tsquare', 'yod'])
        type: (_patternVisible[type] ?? true) ? (filtered[type] ?? []) : [],
    };
  }

  // ══════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        decoration: _bgDecoration,
        child: const Center(child: CircularProgressIndicator(color: Color(0xFFF6BD60))),
      );
    }
    if (!(_profile?.isComplete ?? false)) return _buildNoProfile();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: _bgDecoration,
        child: SafeArea(
          child: Column(children: [
            // ── Top bar with hamburger ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(children: [
                const Spacer(),
                // HTML: .chart-menu-btn
                PopupMenuButton<String>(
                  onSelected: (mode) {
                    // HTML: setChartMode() — reset filters + generate secondary planets
                    _chartMode = mode;
                    _qualityFilters.updateAll((k, v) => true);
                    _pgroupFilters.updateAll((k, v) => true);
                    _fortuneFilter = null;
                    if (mode == 'nt') { _generateTransitPlanets(); }
                    else if (mode == 'np') { _generateProgressedPlanets(); }
                    _recalcAspects();
                    setState(() {});
                  },
                  offset: const Offset(0, 40),
                  color: const Color(0xF80C0C1A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0x33F6BD60)),
                  ),
                  itemBuilder: (_) => [
                    _menuItem('single', '1重 NATAL'),
                    _menuItem('nt', '2重 N+T'),
                    _menuItem('np', '2重 N+P'),
                    _menuItem('astrology', '✦ 星読み'),
                  ],
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xEB0C0C1A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x4DF6BD60)),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(width: 18, height: 2, decoration: BoxDecoration(color: const Color(0xFFF6BD60), borderRadius: BorderRadius.circular(1))),
                      const SizedBox(height: 4),
                      Container(width: 18, height: 2, decoration: BoxDecoration(color: const Color(0xFFF6BD60), borderRadius: BorderRadius.circular(1))),
                      const SizedBox(height: 4),
                      Container(width: 18, height: 2, decoration: BoxDecoration(color: const Color(0xFFF6BD60), borderRadius: BorderRadius.circular(1))),
                    ]),
                  ),
                ),
              ]),
            ),

            // ── Chart or Astrology View ──
            Expanded(child: _chartMode == 'astrology'
              ? HoroAstrologyView(
                  natalPatterns: _patternsForMode('single'),
                  transitPatterns: _patternsForMode('nt'),
                  progressedPatterns: _patternsForMode('np'),
                )
              : _buildChartScrollView(),
            ),

            // ── Bottom Sheet (HTML: 3-state, hidden when astrology mode) ──
            if (_chartMode != 'astrology') _buildBottomSheet(),
          ]),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // No Profile
  // ══════════════════════════════════════════════
  Widget _buildNoProfile() {
    return Container(
      decoration: _bgDecoration,
      child: SafeArea(child: Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0x14F9D976),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x40F9D976)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('✦', style: TextStyle(fontSize: 28, color: Color(0xFFF6BD60))),
            const SizedBox(height: 8),
            const Text('SANCTUARYでプロフィールを設定すると、\nあなた専用のホロスコープが表示されます',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFFF6BD60))),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => widget.onNavigateToSanctuary?.call(),
              child: const Text('設定する →', style: TextStyle(fontSize: 12, color: Color(0xFFF9D976),
                decoration: TextDecoration.underline)),
            ),
          ]),
        ),
      ))),
    );
  }

  Widget _buildChartScrollView() {
    final screenW = MediaQuery.of(context).size.width;
    final chartSize = (screenW - 16).clamp(200.0, 600.0); // 8px padding each side
    final chartAsp = _chartAspects();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(children: [
        const SizedBox(height: 8),
        Center(child: SizedBox(
          width: chartSize, height: chartSize,
          child: Stack(children: [
            Positioned(
              top: chartSize * 0.42 - 8, left: 0, right: 0,
              child: const Center(child: Text('SOLARA', style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 4,
                color: Color(0x2EF6BD60),
              ))),
            ),
            CustomPaint(
              size: Size(chartSize, chartSize),
              painter: HoroChartWheelPainter(
                planets: _natalPlanets, asc: _asc, mc: _mc,
                aspects: chartAsp,
                signColors: signColors.map((c) => Color(c)).toList(),
                showHouses: !_birthTimeUnknown,
                birthTimeUnknown: _birthTimeUnknown,
                userName: _profile?.name ?? '',
                userDate: _profile?.birthDate ?? '',
                userTime: _profile?.birthTime ?? '',
                secondaryPlanets: (_chartMode == 'nt' || _chartMode == 'np') ? _secondaryPlanets : null,
                secondaryColor: _chartMode == 'np'
                  ? const Color(0xFFB088FF)
                  : const Color(0xFF6BB5FF),
                patterns: _visiblePatterns(),
              ),
            ),
          ]),
        )),
        const SizedBox(height: 12),
        _buildChartLegend(),
        const SizedBox(height: 20),
      ]),
    );
  }

  PopupMenuEntry<String> _menuItem(String value, String label) {
    final active = _chartMode == value;
    return PopupMenuItem<String>(
      value: value,
      child: Text(label, style: TextStyle(
        fontSize: 13,
        color: active ? const Color(0xFFF6BD60) : const Color(0xFFACACAC),
      )),
    );
  }

  // ══════════════════════════════════════════════
  // Chart Legend
  // ══════════════════════════════════════════════
  Widget _buildChartLegend() {
    return const Wrap(
      spacing: 16, runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        HoroLegendItem(color: Color(0xFFC9A84C), label: 'ソフト'),
        HoroLegendItem(color: Color(0xFF6B5CE7), label: 'ハード'),
        HoroLegendItem(color: Color(0xFF26D0CE), label: '中立'),
        HoroLegendItem(color: Color(0xFFFFD370), label: 'ネイタル'),
      ],
    );
  }

  // ══════════════════════════════════════════════
  // Bottom Sheet — HTML: 3-state (mini 52px / half ~280px / full ~500px)
  // AnimatedContainer + ドラッグハンドルタップで切替
  // ══════════════════════════════════════════════
  // HTML: BS_MINI_H=52, BS_HALF_RATIO=0.45, BS_FULL_RATIO=0.85
  double _bsHeight(BuildContext context) {
    switch (_bsState) {
      case 0: return 52;  // mini: ドラッグハンドル + ラベルのみ
      case 2: return MediaQuery.of(context).size.height * 0.65; // full
      default: return 280; // half
    }
  }

  void _cycleBsState() {
    // タップ: mini→half, half→full, full→half（miniには下スワイプでのみ）
    setState(() {
      if (_bsState == 0) { _bsState = 1; }
      else if (_bsState == 1) { _bsState = 2; }
      else { _bsState = 1; }
    });
  }

  Widget _buildBottomSheet() {
    final h = _bsHeight(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: h,
      decoration: const BoxDecoration(
        color: Color(0xF80C0C16),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: Color(0x4DF6BD60))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HTML: .bs-drag-handle — タップで3段階切替
          GestureDetector(
            onTap: _cycleBsState,
            onVerticalDragEnd: (d) {
              // 上スワイプで拡大、下スワイプで縮小
              if (d.primaryVelocity != null) {
                setState(() {
                  if (d.primaryVelocity! < -200 && _bsState < 2) _bsState++;
                  if (d.primaryVelocity! > 200 && _bsState > 0) _bsState--;
                });
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.transparent, // タッチ領域確保
              child: Center(child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x66F6BD60),
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
            ),
          ),
          // mini状態ではラベルだけ表示
          if (_bsState == 0)
            GestureDetector(
              onTap: () => setState(() => _bsState = 1),
              child: const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('▲ ホロスコープ設定',
                  style: TextStyle(fontSize: 11, color: Color(0xFFF6BD60), letterSpacing: 1.5)),
              ),
            ),
          // half/full状態ではタブ + コンテンツ
          if (_bsState > 0) ...[
            _buildBSTabs(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                child: _buildBSContent(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBSTabs() {
    final showTransit = _chartMode == 'nt' || _chartMode == 'np';
    // HTML: bs-tab — 5 tabs (fortune has no tab button in HTML mobile)
    final tabs = <(String, String)>[
      ('birth', '⚙ 誕生'),
      if (showTransit) ('transit', _chartMode == 'np' ? '☆ 進行' : '☾ 経過'),
      ('planets', '☉ 天体'),
      ('filter', '⚙ 絞込'),
      ('aspects', '△ 相'),
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0FFFFFFF))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(children: tabs.map((t) {
        final active = _bsTab == t.$1;
        return Expanded(child: GestureDetector(
          onTap: () => setState(() => _bsTab = t.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(
                color: active ? const Color(0xFFF6BD60) : Colors.transparent, width: 2)),
            ),
            child: Center(child: Text(t.$2, style: TextStyle(
              fontSize: 11, letterSpacing: 0.5,
              color: active ? const Color(0xFFF6BD60) : const Color(0xFF777777),
            ))),
          ),
        ));
      }).toList()),
    );
  }

  Widget _buildBSContent() {
    switch (_bsTab) {
      case 'birth': return HoroBirthPanel(profile: _profile!);
      case 'transit': return HoroTransitPanel(chartMode: _chartMode);
      case 'planets': return HoroPlanetTable(natalPlanets: _natalPlanets, asc: _asc, mc: _mc, birthTimeUnknown: _birthTimeUnknown);
      case 'filter': return HoroFilterPanel(
        qualityFilters: _qualityFilters,
        pgroupFilters: _pgroupFilters,
        fortuneFilter: _fortuneFilter,
        onReset: () => setState(() {
          _qualityFilters.updateAll((k, v) => true);
          _pgroupFilters.updateAll((k, v) => true);
          _fortuneFilter = null;
        }),
        onQualityChanged: (k, v) => setState(() => _qualityFilters[k] = v),
        onPgroupChanged: (k, v) => setState(() => _pgroupFilters[k] = v),
        onFortuneChanged: (v) => setState(() => _fortuneFilter = v),
      );
      case 'aspects': return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        HoroAspectList(
          filteredAspects: _allAspectsWithDimmed(),
          hiddenAspects: _hiddenAspects,
          onToggleAspect: (key) => setState(() {
            if (_hiddenAspects.contains(key)) { _hiddenAspects.remove(key); } else { _hiddenAspects.add(key); }
          }),
        ),
        const SizedBox(height: 12),
        HoroPredictionPanel(
          activePatterns: _modeFilteredPatterns(),
          // 60日予測はnt/npモード（2重円画面）で表示。singleでは不要
          predictions: (_chartMode == 'nt' || _chartMode == 'np')
            ? predictPatternCompletions(_natalPlanets, chartMode: _chartMode) : [],
          patternVisible: _patternVisible,
          onPatternToggle: (type, v) => setState(() => _patternVisible[type] = v),
        ),
      ]);
      default: return const SizedBox();
    }
  }

  // ══════════════════════════════════════════════
  // Background
  // ══════════════════════════════════════════════
  static const _bgDecoration = BoxDecoration(
    gradient: RadialGradient(
      center: Alignment.center, radius: 1.2,
      colors: [Color(0xFF0C1D3A), Color(0xFF080C14)],
    ),
  );
}
