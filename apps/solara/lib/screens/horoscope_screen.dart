import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/solara_storage.dart';

class HoroscopeScreen extends StatefulWidget {
  const HoroscopeScreen({super.key});
  @override
  State<HoroscopeScreen> createState() => HoroscopeScreenState();
}

class HoroscopeScreenState extends State<HoroscopeScreen> {
  SolaraProfile? _profile;
  bool _loading = true;
  bool _birthTimeUnknown = false;

  // HTML: chartMode 'single' | 'nt' | 'np' | 'astrology'
  String _chartMode = 'single';

  // Bottom sheet — HTML: bs-tab: ⚙ 誕生 / ☾ 経過(hidden unless nt/np) / ☉ 天体 / ⚙ 絞込 / △ 相
  String _bsTab = 'birth';

  // Fortune
  int _fortuneIdx = 0;
  final PageController _fortunePageCtrl = PageController();

  // Planet data (mock until CF Worker deployed)
  Map<String, double> _natalPlanets = {};
  double _asc = 0, _mc = 0;
  List<Map<String, dynamic>> _aspects = [];

  // Aspect filters — HTML: activeFilters
  final Map<String, bool> _qualityFilters = {'soft': true, 'hard': true, 'neutral': true};
  // HTML: activeFilters.pgroup {personal:true, social:true, generational:true}
  final Map<String, bool> _pgroupFilters = {'personal': true, 'social': true, 'generational': true};
  String? _fortuneFilter; // HTML: activeFilters.fortune — null = no fortune filter
  // HTML: hiddenAspects (L1194) — individual aspect visibility toggle
  final Set<String> _hiddenAspects = {};

  // HTML: IDX_PLANET_GROUPS (L1132-1136)
  static const _planetGroups = {
    'sun': 'personal', 'moon': 'personal', 'mercury': 'personal', 'venus': 'personal', 'mars': 'personal',
    'jupiter': 'social', 'saturn': 'social',
    'uranus': 'generational', 'neptune': 'generational', 'pluto': 'generational',
  };
  // HTML: IDX_FORTUNE_PLANETS (L1139-1145)
  static const _fortunePlanets = {
    'healing': ['moon', 'neptune', 'jupiter'],
    'money': ['venus', 'jupiter', 'saturn'],
    'love': ['venus', 'mars', 'moon'],
    'career': ['saturn', 'mars', 'sun'],
    'communication': ['mercury', 'moon', 'jupiter'],
  };

  @override
  void initState() { super.initState(); loadProfile(); }

  @override
  void dispose() { _fortunePageCtrl.dispose(); super.dispose(); }

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

    _aspects = [];
    for (int i = 0; i < keys.length; i++) {
      for (int j = i + 1; j < keys.length; j++) {
        final diff = _angDist(_natalPlanets[keys[i]]!, _natalPlanets[keys[j]]!);
        for (final asp in _aspectTypes) {
          if ((diff - (asp['angle'] as double)).abs() <= (asp['orb'] as double)) {
            _aspects.add({'p1': keys[i], 'p2': keys[j], 'type': asp['key'], 'diff': diff,
              'quality': asp['quality'], 'color': asp['color'] as Color});
          }
        }
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

  // HTML: ORB_SETTINGS = { conjunction:2, opposition:2, trine:2, square:2, sextile:2, quincunx:2, semisextile:1, semisquare:1 }
  // HTML: ASPECT_TYPES (L1162-1171) — 8種
  static final _aspectTypes = [
    {'key':'conjunction','angle':0.0,'orb':2.0,'quality':'neutral','color':const Color(0xFF26D0CE),'minor':false},
    {'key':'opposition','angle':180.0,'orb':2.0,'quality':'hard','color':const Color(0xFF6B5CE7),'minor':false},
    {'key':'trine','angle':120.0,'orb':2.0,'quality':'soft','color':const Color(0xFFC9A84C),'minor':false},
    {'key':'square','angle':90.0,'orb':2.0,'quality':'hard','color':const Color(0xFF6B5CE7),'minor':false},
    {'key':'sextile','angle':60.0,'orb':2.0,'quality':'soft','color':const Color(0xFFC9A84C),'minor':false},
    {'key':'quincunx','angle':150.0,'orb':2.0,'quality':'neutral','color':const Color(0xFF26D0CE),'minor':false},
    {'key':'semisextile','angle':30.0,'orb':1.0,'quality':'soft','color':const Color(0xFF8BC34A),'minor':true},
    {'key':'semisquare','angle':45.0,'orb':1.0,'quality':'hard','color':const Color(0xFFFF7043),'minor':true},
  ];

  static const _signs = ['♈','♉','♊','♋','♌','♍','♎','♏','♐','♑','♒','♓'];
  static const _signNames = ['牡羊','牡牛','双子','蟹','獅子','乙女','天秤','蠍','射手','山羊','水瓶','魚'];
  static const _signColors = [0xFFFF4444,0xFF4CAF50,0xFFFFD700,0xFFC0C0C0,0xFFFF8C00,0xFF8BC34A,
    0xFFE91E63,0xFF9C27B0,0xFF9C27B0,0xFF607D8B,0xFF00BCD4,0xFF3F51B5];
  static const _planetGlyphs = {'sun':'☉','moon':'☽','mercury':'☿','venus':'♀','mars':'♂',
    'jupiter':'♃','saturn':'♄','uranus':'♅','neptune':'♆','pluto':'♇'};
  static const _planetNamesJP = {'sun':'太陽','moon':'月','mercury':'水星','venus':'金星','mars':'火星',
    'jupiter':'木星','saturn':'土星','uranus':'天王星','neptune':'海王星','pluto':'冥王星'};

  // HTML: FORTUNE_CATEGORIES (L2748-2773)
  // + FORTUNE_MOCK scores & directions
  static const _fortuneCategories = [
    {'id':'overall','icon':'✦','nameJP':'全体運','color':0xFFF6BD60,'bg':0x14F6BD60,'border':0x33F6BD60,'score':82,'direction':'東の方角が吉。朝の光を浴びると良い。'},
    {'id':'love','icon':'💕','nameJP':'恋愛運','color':0xFFFF6B9D,'bg':0x14FF6B9D,'border':0x33FF6B9D,'score':75,'direction':'南東の方角にチャンスの兆し。'},
    {'id':'money','icon':'💰','nameJP':'金運','color':0xFFFFD370,'bg':0x14FFD370,'border':0x33FFD370,'score':68,'direction':'西の方角に金運の流れあり。'},
    {'id':'career','icon':'💼','nameJP':'仕事運','color':0xFFFF8C42,'bg':0x14FF8C42,'border':0x33FF8C42,'score':88,'direction':'北の方角で集中力が高まる。'},
    {'id':'communication','icon':'💬','nameJP':'対話運','color':0xFF6BB5FF,'bg':0x146BB5FF,'border':0x336BB5FF,'score':71,'direction':'南の方角で人との出会いが。'},
  ];

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

    return Container(
      decoration: _bgDecoration,
      child: SafeArea(
        top: false,
        child: Column(children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 8),

          // ── Chart Menu Button (モバイル) ──
          // HTML: .chart-menu-btn { top:12px; right:12px; width:40px; height:40px; border-radius:10px; }
          _buildChartMenuRow(),

          // ── Chart or Astrology View ──
          Expanded(child: _chartMode == 'astrology'
            ? _buildAstrologyView()
            : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(builder: (ctx, constraints) {
                final chartSize = (constraints.maxWidth - 32).clamp(200.0, 400.0);
                return Column(children: [
                  const SizedBox(height: 8),
                  // HTML: .chart-container with watermark + SVG
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
                        painter: _ChartWheelPainter(
                          planets: _natalPlanets, asc: _asc, mc: _mc,
                          aspects: _filteredAspects(),
                          signColors: _signColors.map((c) => Color(c)).toList(),
                          showHouses: !_birthTimeUnknown,
                        ),
                      ),
                    ]),
                  )),
                  const SizedBox(height: 12),
                  _buildChartLegend(),
                  const SizedBox(height: 16),
                  _buildFortuneCards(),
                  const SizedBox(height: 100),
                ]);
              }),
            ),
          ),

          // ── Bottom Sheet (HTML: hidden when astrology mode) ──
          if (_chartMode != 'astrology') _buildBottomSheet(),
        ]),
      ),
    );
  }

  // HTML: aspectPassesFilter() (L1491-1503)
  List<Map<String, dynamic>> _filteredAspects() {
    return _aspects.where((a) {
      final q = a['quality'] as String;
      if (!(_qualityFilters[q] ?? true)) return false;
      // pgroup filter
      final g1 = _planetGroups[a['p1']] ?? 'personal';
      final g2 = _planetGroups[a['p2']] ?? 'personal';
      if (!(_pgroupFilters[g1] ?? true) && !(_pgroupFilters[g2] ?? true)) return false;
      // fortune filter
      if (_fortuneFilter != null) {
        final fp = _fortunePlanets[_fortuneFilter] ?? [];
        if (!fp.contains(a['p1']) && !fp.contains(a['p2'])) return false;
      }
      return true;
    }).toList();
  }

  // ══════════════════════════════════════════════
  // No Profile
  // ══════════════════════════════════════════════
  Widget _buildNoProfile() {
    // HTML: #noProfileBanner { background:rgba(249,217,118,0.08); border:1px solid rgba(249,217,118,0.25);
    //   border-radius:12px; padding:14px 18px; }
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
            const Text('設定する →', style: TextStyle(fontSize: 12, color: Color(0xFFF9D976),
              decoration: TextDecoration.underline)),
          ]),
        ),
      ))),
    );
  }

  // ══════════════════════════════════════════════
  // Chart Menu Row (Mode Selection)
  // HTML mobile: .chart-menu-btn + .chart-menu-panel
  // Items: 1重 NATAL, 2重 N+T, 2重 N+P, ✦ 星読み
  // ══════════════════════════════════════════════
  Widget _buildChartMenuRow() {
    // HTML: .chart-menu-item { padding:10px 14px; font-size:13px; }
    // .chart-menu-item.active { color:#F6BD60; background:rgba(246,189,96,0.12); }
    final modes = [
      ('single', '1重 NATAL'),
      ('nt', '2重 N+T'),
      ('np', '2重 N+P'),
      ('astrology', '✦ 星読み'),
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      // HTML: .tab-nav { background:rgba(255,255,255,0.03); border-radius:12px; padding:4px; }
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(children: modes.map((m) {
        final active = _chartMode == m.$1;
        return Expanded(child: GestureDetector(
          onTap: () => setState(() {
            _chartMode = m.$1;
            // HTML: setChartMode() calls resetFilters() on mode change (L1711)
            _qualityFilters.updateAll((k, v) => true);
            _pgroupFilters.updateAll((k, v) => true);
            _fortuneFilter = null;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              // HTML: .tab-btn.active { background:rgba(246,189,96,0.15); color:#F6BD60; }
              color: active ? const Color(0x26F6BD60) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text(m.$2, style: TextStyle(
              fontSize: 11, letterSpacing: 1,
              color: active ? const Color(0xFFF6BD60) : const Color(0xFF888888),
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ))),
          ),
        ));
      }).toList()),
    );
  }

  // ══════════════════════════════════════════════
  // Chart Legend
  // HTML: .chart-legend { display:flex; gap:16px; font-size:11px; color:#888; }
  // .legend-dot { width:8px; height:8px; border-radius:50%; }
  // ══════════════════════════════════════════════
  Widget _buildChartLegend() {
    return Wrap(
      spacing: 16, runSpacing: 4,
      alignment: WrapAlignment.center,
      children: const [
        _LegendItem(color: Color(0xFFC9A84C), label: 'ソフト'),
        _LegendItem(color: Color(0xFF6B5CE7), label: 'ハード'),
        _LegendItem(color: Color(0xFF26D0CE), label: '中立'),
        _LegendItem(color: Color(0xFFFFD370), label: 'ネイタル'),
      ],
    );
  }

  // ══════════════════════════════════════════════
  // Fortune Cards
  // HTML: .fortune-cards-wrap, .fortune-card, .fortune-dots, .fortune-nav-row
  // ══════════════════════════════════════════════
  Widget _buildFortuneCards() {
    return Column(children: [
      // HTML: .fortune-reading h3
      const Text('✦ FORTUNE', style: TextStyle(
        fontSize: 13, color: Color(0xFFF6BD60), letterSpacing: 2)),
      const SizedBox(height: 12),
      // HTML: .fortune-cards-wrap { border-radius:16px; overflow:hidden; }
      // .fortune-card { min-width:100%; padding:20px; border-radius:16px; }
      SizedBox(height: 180, child: PageView.builder(
        controller: _fortunePageCtrl, itemCount: _fortuneCategories.length,
        onPageChanged: (i) => setState(() => _fortuneIdx = i),
        itemBuilder: (ctx, i) {
          final cat = _fortuneCategories[i];
          final color = Color(cat['color'] as int);
          final bgColor = Color(cat['bg'] as int);
          final borderColor = Color(cat['border'] as int);
          final score = cat['score'] as int;
          final direction = cat['direction'] as String;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              // HTML: background:cat.bg; border:1px solid cat.border;
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // HTML: .fortune-card-header — icon + title + score
              Row(children: [
                // HTML: .fortune-card-icon { width:36px; height:36px; border-radius:10px; font-size:18px; }
                Container(width: 36, height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: bgColor,
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(child: Text(cat['icon'] as String, style: const TextStyle(fontSize: 18)))),
                const SizedBox(width: 10),
                // HTML: .fortune-card-title { font-size:15px; font-weight:700; }
                Text(cat['nameJP'] as String, style: TextStyle(
                  color: color, fontSize: 15, fontWeight: FontWeight.w700)),
                const Spacer(),
                // HTML: .fortune-card-score { font-size:20px; font-weight:700; }
                Text('$score', style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: color)),
              ]),
              const SizedBox(height: 14),
              // HTML: .fortune-card-body { font-size:13px; line-height:1.8; color:rgba(232,224,208,0.85); }
              Text('星々の配置があなたの${cat['nameJP']}に影響しています。\n詳細な鑑定はAPI接続後に表示されます。',
                style: const TextStyle(fontSize: 13, color: Color(0xD9E8E0D0), height: 1.8)),
              const SizedBox(height: 12),
              // HTML: .fortune-card-direction { margin-top:12px; padding:10px 14px; border-radius:12px;
              //   background:rgba(249,217,118,0.06); border:1px solid rgba(249,217,118,0.15); font-size:12px; color:#F6BD60; }
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0x0FF9D976),
                  border: Border.all(color: const Color(0x26F9D976)),
                ),
                child: Text('🧭 方位アドバイス: $direction',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFF6BD60))),
              ),
            ]),
          );
        },
      )),
      const SizedBox(height: 12),
      // HTML: .fortune-dots
      Row(mainAxisAlignment: MainAxisAlignment.center, children:
        List.generate(_fortuneCategories.length, (i) => Container(
          // HTML: .fortune-dot { width:8px; height:8px; border-radius:50%; }
          // .fortune-dot.active { width:20px; border-radius:4px; background:#F6BD60; box-shadow:0 0 8px rgba(246,189,96,0.5); }
          width: i == _fortuneIdx ? 20 : 8, height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(i == _fortuneIdx ? 4 : 4),
            color: i == _fortuneIdx ? const Color(0xFFF6BD60) : const Color(0x26FFFFFF),
            boxShadow: i == _fortuneIdx
                ? const [BoxShadow(color: Color(0x80F6BD60), blurRadius: 8)]
                : null,
          ),
        )),
      ),
      const SizedBox(height: 8),
      // HTML: .fortune-nav-row
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _fortuneNavBtn('← 前へ', () {
          if (_fortuneIdx > 0) {
            _fortunePageCtrl.previousPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
          }
        }),
        _fortuneNavBtn('次へ →', () {
          if (_fortuneIdx < _fortuneCategories.length - 1) {
            _fortunePageCtrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
          }
        }),
      ]),
    ]);
  }

  // HTML: .fortune-nav-btn { border:1px solid rgba(255,255,255,0.12); border-radius:8px; padding:6px 14px; font-size:11px; color:#ACACAC; }
  Widget _fortuneNavBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFFACACAC))),
    ),
  );

  // ══════════════════════════════════════════════
  // Bottom Sheet (Mobile)
  // HTML: .mobile-bottom-sheet { bottom:70px; background:rgba(12,12,22,0.97);
  //   border-top:1px solid rgba(246,189,96,0.3); border-radius:16px 16px 0 0; }
  // ══════════════════════════════════════════════
  Widget _buildBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF80C0C16), // rgba(12,12,22,0.97)
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: Color(0x4DF6BD60))), // rgba(246,189,96,0.3)
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HTML: .bs-drag-handle { width:36px; height:4px; background:rgba(246,189,96,0.4); border-radius:2px; }
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            decoration: BoxDecoration(
              color: const Color(0x66F6BD60),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // HTML: .bs-tabs { display:flex; gap:0; padding:0 8px; border-bottom:1px solid rgba(255,255,255,0.06); }
          _buildBSTabs(),
          // HTML: .bs-body { overflow-y:auto; padding:12px 14px 24px; }
          SizedBox(
            height: 220,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              child: _buildBSContent(),
            ),
          ),
        ],
      ),
    );
  }

  // HTML: .bs-tab { flex:1; padding:8px 4px; text-align:center; font-size:11px; color:#777;
  //   border-bottom:2px solid transparent; }
  // .bs-tab.active { color:#F6BD60; border-bottom-color:#F6BD60; }
  Widget _buildBSTabs() {
    // HTML exact: bs-tab: ⚙ 誕生 / ☾ 経過(hidden-tab unless nt/np) / ☉ 天体 / ⚙ 絞込 / △ 相
    final showTransit = _chartMode == 'nt' || _chartMode == 'np';
    // HTML: bs-tab (L1104-1110) — 5 tabs, NO fortune tab in bottom sheet
    final tabs = <(String, String)>[
      ('birth', '⚙ 誕生'),
      if (showTransit) ('transit', _chartMode == 'np' ? '☆ 進行' : '☾ 経過'),
      ('planets', '☉ 天体'),
      ('filter', '⚙ 絞込'),
      ('aspects', '△ 相'),
    ];

    return Container(
      decoration: const BoxDecoration(
        // HTML: .bs-tabs { border-bottom:1px solid rgba(255,255,255,0.06); }
        border: Border(bottom: BorderSide(color: Color(0x0FFFFFFF))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(children: tabs.map((t) {
        final active = _bsTab == t.$1;
        return Expanded(child: GestureDetector(
          onTap: () => setState(() => _bsTab = t.$1),
          child: Container(
            // HTML: .bs-tab { flex:1; padding:8px 4px; text-align:center; font-size:11px; color:#777;
            //   border-bottom:2px solid transparent; letter-spacing:0.5px; }
            // .bs-tab.active { color:#F6BD60; border-bottom-color:#F6BD60; }
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
      case 'birth': return _buildBirthSection();
      case 'transit': return _buildTransitSection();
      case 'planets': return _buildPlanetTable();
      case 'filter': return _buildFilterPanel();
      case 'aspects': return _buildAspectList();
      default: return const SizedBox();
    }
  }

  // ── Birth Section (BS) ──
  // HTML: #bsBirth — profile info display (name, date, time, place) + generate button
  Widget _buildBirthSection() {
    final p = _profile;
    if (p == null) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // HTML: .bs-body h3 { font-size:12px; color:#F6BD60; letter-spacing:1px; }
      const Text('⚙ BIRTH DATA', style: TextStyle(fontSize: 12, color: Color(0xFFF6BD60), letterSpacing: 1)),
      const SizedBox(height: 10),
      // HTML: .form-group label { font-size:11px; color:#888; letter-spacing:1px; }
      _bsInfoRow('氏名 NAME', p.name.isEmpty ? '未設定' : p.name),
      _bsInfoRow('生年月日 DATE', p.birthDate),
      _bsInfoRow('出生時刻 TIME', p.birthTimeUnknown ? '不明' : p.birthTime),
      _bsInfoRow('出生地 BIRTHPLACE', p.birthPlace.isEmpty ? '未設定' : p.birthPlace),
      if (p.birthLat != 0) ...[
        _bsInfoRow('緯度/経度', '${p.birthLat.toStringAsFixed(4)} / ${p.birthLng.toStringAsFixed(4)}'),
      ],
      const SizedBox(height: 8),
      // HTML: .btn-generate { width:100%; padding:10px; background:linear-gradient(135deg,#F6BD60,#E8A840);
      //   border-radius:10px; color:#0A0A14; font-size:13px; font-weight:600; letter-spacing:1px; }
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFF6BD60), Color(0xFFE8A840)],
          ),
        ),
        child: const Center(child: Text('ホロスコープ生成', style: TextStyle(
          color: Color(0xFF0A0A14), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1))),
      ),
    ]);
  }

  Widget _bsInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888888), letterSpacing: 1)),
        const SizedBox(height: 3),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          // HTML: .form-group input { background:rgba(255,255,255,0.05); border:1px solid rgba(255,255,255,0.1); border-radius:8px; }
          decoration: BoxDecoration(
            color: const Color(0x0DFFFFFF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFFE8E0D0))),
        ),
      ]),
    );
  }

  // ── Transit Section (BS) ──
  // HTML: #bsTransit — transit date/time/location
  Widget _buildTransitSection() {
    final label = _chartMode == 'np' ? 'プログレス更新' : 'トランジット更新';
    final btnColor = _chartMode == 'np' ? const Color(0xFFB088FF) : const Color(0xFF6BB5FF);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_chartMode == 'np' ? '☽ PROGRESSED DATA' : '☾ TRANSIT DATA',
        style: const TextStyle(fontSize: 12, color: Color(0xFFF6BD60), letterSpacing: 1)),
      const SizedBox(height: 10),
      _bsInfoRow('日付 DATE', DateTime.now().toString().split(' ')[0]),
      _bsInfoRow('時刻 TIME', '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}'),
      const SizedBox(height: 8),
      // HTML: #transitBtn { background:linear-gradient(135deg,#6BB5FF,#4A90D9) }
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [btnColor, btnColor.withAlpha(200)],
          ),
        ),
        child: Center(child: Text(label, style: const TextStyle(
          color: Color(0xFF0A0A14), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1))),
      ),
    ]);
  }

  // ══════════════════════════════════════════════
  // Planet Table
  // HTML: .planet-row { display:flex; align-items:center; padding:5px 0; border-bottom:1px solid rgba(255,255,255,0.04); }
  // .planet-glyph { width:24px; font-size:16px; text-align:center; }
  // .planet-name { width:60px; color:#aaa; font-size:12px; }
  // .planet-pos { flex:1; color:#E8E0D0; font-family:monospace; font-size:12px; }
  // ══════════════════════════════════════════════
  Widget _buildPlanetTable() {
    return Column(children: [
      // HTML: h3 { font-size:12px; color:#F6BD60; letter-spacing:1px; }
      const Align(
        alignment: Alignment.centerLeft,
        child: Text('☉ PLANET POSITIONS', style: TextStyle(
          fontSize: 12, color: Color(0xFFF6BD60), letterSpacing: 1)),
      ),
      const SizedBox(height: 10),
      if (!_birthTimeUnknown) ...[
        _planetRow('ASC', '↑', _asc),
        _planetRow('MC', '⬆', _mc),
        Container(height: 1, color: const Color(0x0AFFFFFF), margin: const EdgeInsets.symmetric(vertical: 4)),
      ],
      ..._natalPlanets.entries.map((e) => _planetRow(
        _planetNamesJP[e.key] ?? e.key,
        _planetGlyphs[e.key] ?? '?',
        e.value)),
    ]);
  }

  Widget _planetRow(String name, String glyph, double lon) {
    final signIdx = (lon / 30).floor() % 12;
    final deg = lon % 30;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0AFFFFFF))),
      ),
      child: Row(children: [
        // HTML: .planet-glyph { width:24px; font-size:16px; }
        SizedBox(width: 24, child: Text(glyph, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center)),
        // HTML: .planet-name { width:60px; color:#aaa; font-size:12px; }
        SizedBox(width: 60, child: Text(name, style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12))),
        // HTML: .planet-pos { color:#E8E0D0; font-family:monospace; font-size:12px; }
        Text(_signs[signIdx], style: TextStyle(color: Color(_signColors[signIdx]), fontSize: 14)),
        const SizedBox(width: 4),
        Text('${deg.toStringAsFixed(1)}°', style: const TextStyle(
          color: Color(0xFFE8E0D0), fontFamily: 'Courier New', fontSize: 12)),
        const SizedBox(width: 4),
        Text(_signNames[signIdx], style: TextStyle(
          color: Color(_signColors[signIdx]).withAlpha(180), fontSize: 10)),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // Filter Panel
  // HTML: .filter-section, .filter-chips, .filter-chip
  // ══════════════════════════════════════════════
  Widget _buildFilterPanel() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('ASPECT FILTER', style: TextStyle(fontSize: 11, color: Color(0xFF888888), letterSpacing: 1.5)),
        // HTML: .filter-reset-btn
        GestureDetector(
          onTap: () => setState(() {
            _qualityFilters.updateAll((k, v) => true);
            _pgroupFilters.updateAll((k, v) => true);
            _fortuneFilter = null;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: const Text('RESET', style: TextStyle(fontSize: 10, color: Color(0xFF666666))),
          ),
        ),
      ]),
      const SizedBox(height: 10),

      // A: Aspect Quality
      _filterSection('A', 'アスペクト性質', [
        _filterChip('ソフト（調和）', 'soft', const Color(0xFFC9A84C), _qualityFilters['soft']!, (v) => setState(() => _qualityFilters['soft'] = v)),
        _filterChip('ハード（緊張）', 'hard', const Color(0xFF6B5CE7), _qualityFilters['hard']!, (v) => setState(() => _qualityFilters['hard'] = v)),
        _filterChip('中立', 'neutral', const Color(0xFF26D0CE), _qualityFilters['neutral']!, (v) => setState(() => _qualityFilters['neutral'] = v)),
      ]),

      // B: Fortune Category
      _filterSection('B', '運勢カテゴリ', [
        _exclusiveChip('癒し', 'healing', const Color(0xFF26D0CE)),
        _exclusiveChip('金運', 'money', const Color(0xFFFFD370)),
        _exclusiveChip('恋愛運', 'love', const Color(0xFFFF6B9D)),
        _exclusiveChip('仕事運', 'career', const Color(0xFFFF8C42)),
        _exclusiveChip('コミュニケーション', 'communication', const Color(0xFF6BB5FF)),
      ]),

      // C: Planet Group — HTML L1065-1071
      _filterSection('C', '惑星グループ', [
        _filterChip('個人天体', 'personal', const Color(0xFFFFD370), _pgroupFilters['personal']!, (v) => setState(() => _pgroupFilters['personal'] = v)),
        _filterChip('社会天体', 'social', const Color(0xFF6BB5FF), _pgroupFilters['social']!, (v) => setState(() => _pgroupFilters['social'] = v)),
        _filterChip('世代天体', 'generational', const Color(0xFFB088FF), _pgroupFilters['generational']!, (v) => setState(() => _pgroupFilters['generational'] = v)),
      ]),
    ]);
  }

  // HTML: .filter-section { margin-bottom:10px; padding-bottom:8px; border-bottom:1px solid rgba(255,255,255,0.05); }
  Widget _filterSection(String badge, String title, List<Widget> chips) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0DFFFFFF))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // HTML: .filter-section-title { font-size:10px; color:#888; letter-spacing:1.5px; }
        Row(children: [
          // HTML: .filter-label { background:rgba(255,255,255,0.08); padding:1px 6px; border-radius:4px; font-size:9px; }
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(badge, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFFAAAAAA))),
          ),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF888888), letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 6),
        // HTML: .filter-chips { display:flex; flex-wrap:wrap; gap:4px; }
        Wrap(spacing: 4, runSpacing: 4, children: chips),
      ]),
    );
  }

  // HTML: .filter-chip { padding:4px 10px; border:1px solid rgba(255,255,255,0.1); border-radius:6px; font-size:11px; color:#888; }
  // .filter-chip.active { border-color:var(--chip-color); color:var(--chip-color); background:rgba(246,189,96,0.08); }
  Widget _filterChip(String label, String key, Color color, bool active, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!active),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? color : const Color(0x1AFFFFFF)),
          color: active ? color.withAlpha(20) : const Color(0x08FFFFFF),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, color: active ? color : const Color(0xFF888888))),
      ),
    );
  }

  // HTML: .filter-chip.exclusive { border-style:dashed; }
  // .filter-chip.exclusive.active { border-style:solid; }
  Widget _exclusiveChip(String label, String key, Color color) {
    final active = _fortuneFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _fortuneFilter = active ? null : key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? color : const Color(0x1AFFFFFF),
            // Dashed border not easily doable in Flutter, use thinner line for inactive
          ),
          color: active ? color.withAlpha(20) : const Color(0x08FFFFFF),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, color: active ? color : const Color(0xFF888888))),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // Aspect List
  // HTML: aspect-lists-row in analysis-body
  // ══════════════════════════════════════════════
  Widget _buildAspectList() {
    final filtered = _filteredAspects();
    if (filtered.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('アスペクトなし', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('△ ASPECTS (${filtered.length})', style: const TextStyle(
        fontSize: 12, color: Color(0xFFF6BD60), letterSpacing: 1)),
      const SizedBox(height: 8),
      // HTML: toggleAspectVisibility() — tap to show/hide individual aspects
      ...filtered.take(15).map((a) {
        final key = '${a['type']}_${a['p1']}_${a['p2']}';
        final isHidden = _hiddenAspects.contains(key);
        return GestureDetector(
          onTap: () => setState(() {
            if (isHidden) { _hiddenAspects.remove(key); } else { _hiddenAspects.add(key); }
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0x08FFFFFF))),
            ),
            child: Opacity(
              opacity: isHidden ? 0.25 : 1.0,
              child: Row(children: [
                // HTML: .aspect-check { color:green/red; font-size:14px; }
                SizedBox(width: 16, child: Text(isHidden ? '○' : '●',
                  style: TextStyle(fontSize: 14, color: isHidden ? const Color(0xFF555555) : (a['color'] as Color)),
                  textAlign: TextAlign.center)),
                const SizedBox(width: 4),
                Text('${_planetGlyphs[a['p1']]} ${_planetNamesJP[a['p1']]}',
                  style: const TextStyle(color: Color(0xFFE8E0D0), fontSize: 12)),
                Text(' — ', style: TextStyle(color: (a['color'] as Color).withAlpha(180), fontSize: 12)),
                Text('${_planetGlyphs[a['p2']]} ${_planetNamesJP[a['p2']]}',
                  style: const TextStyle(color: Color(0xFFE8E0D0), fontSize: 12)),
                const Spacer(),
                Text('${(a['diff'] as double).toStringAsFixed(1)}°',
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 10)),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: (a['color'] as Color).withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(a['type'] as String, style: TextStyle(
                    color: a['color'] as Color, fontSize: 9)),
                ),
              ]),
            ),
          ),
        );
      }),
      if (filtered.length > 15)
        Padding(padding: const EdgeInsets.only(top: 4),
          child: Text('... 他${filtered.length - 15}件',
            style: const TextStyle(color: Color(0x99888888), fontSize: 10))),
    ]);
  }

  // ══════════════════════════════════════════════
  // Astrology / Today View (full screen fortune cards)
  // HTML: #astrologyView — shown when chartMode === 'astrology'
  // ══════════════════════════════════════════════
  // HTML: renderFortuneCard(cat, text, direction)
  // — icon + title + text body + direction advice
  // — NO score number, NO score bar (score is only in carousel version)
  Widget _buildAstrologyView() {
    final messages = [
      '星の配置が良い流れを作っている。',
      '穏やかなエネルギーが流れている。',
      '意識して行動すると良い結果に。',
      '今日は自分のペースで進もう。',
      '周囲との調和を大切に。',
    ];
    final directions = [
      '🧭 全体的に東の方角が吉。朝の光を浴びると良い。',
      '🧭 南東の方角にチャンスの兆し。',
      '🧭 西の方角に金運の流れあり。',
      '🧭 北の方角で集中力が高まる。',
      '🧭 南の方角で人との出会いが。',
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('✦ TODAY\'S READING', style: TextStyle(
          fontSize: 14, color: Color(0xFFF6BD60), letterSpacing: 2, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          '${DateTime.now().month}/${DateTime.now().day} のホロスコープ運勢',
          style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
        ),
        const SizedBox(height: 16),
        // HTML: .fortune-card { border-radius:16px; padding:20px; margin-bottom:16px; }
        ..._fortuneCategories.map((cat) {
          final color = Color(cat['color'] as int);
          final idx = _fortuneCategories.indexOf(cat);
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withAlpha(12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withAlpha(50)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // HTML: .fortune-card-header — icon + title (NO score)
              Row(children: [
                // HTML: .fortune-card-icon { width:36px; height:36px; border-radius:10px; font-size:18px; }
                Container(width: 36, height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: color.withAlpha(20),
                    border: Border.all(color: color.withAlpha(40)),
                  ),
                  child: Center(child: Text(cat['icon'] as String, style: const TextStyle(fontSize: 18)))),
                const SizedBox(width: 10),
                // HTML: .fortune-card-title { color:cat.color; font-size:15px; font-weight:700; }
                Text(cat['nameJP'] as String, style: TextStyle(
                  fontSize: 15, color: color, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 12),
              // HTML: .fortune-card-body { font-size:13px; line-height:1.8; color:rgba(232,224,208,0.85); }
              Text(messages[idx % messages.length],
                style: const TextStyle(fontSize: 13, color: Color(0xD9E8E0D0), height: 1.8)),
              const SizedBox(height: 12),
              // HTML: .fortune-card-direction { margin-top:12px; padding:10px 14px; border-radius:12px;
              //   background:rgba(249,217,118,0.06); border:1px solid rgba(249,217,118,0.15);
              //   font-size:12px; color:#F6BD60; }
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0x0FF9D976), // rgba(249,217,118,0.06)
                  border: Border.all(color: const Color(0x26F9D976)), // rgba(249,217,118,0.15)
                ),
                child: Text(directions[idx % directions.length],
                  style: const TextStyle(fontSize: 12, color: Color(0xFFF6BD60))),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // Background
  // HTML: body { background: var(--bg-deep); } = #080C14
  // ══════════════════════════════════════════════
  static const _bgDecoration = BoxDecoration(
    gradient: RadialGradient(
      center: Alignment.center, radius: 1.2,
      colors: [Color(0xFF0C1D3A), Color(0xFF080C14)],
    ),
  );
}

// ══════════════════════════════════════════════════
// Legend Item
// HTML: .legend-item { display:flex; align-items:center; gap:6px; }
// .legend-dot { width:8px; height:8px; border-radius:50%; }
// ══════════════════════════════════════════════════

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
    ]);
  }
}

// ══════════════════════════════════════════════════
// Chart Wheel Painter
// HTML: SVG 600x600, outer 270, inner 220, planetR 185, center 50
// ══════════════════════════════════════════════════

class _ChartWheelPainter extends CustomPainter {
  final Map<String, double> planets;
  final double asc, mc;
  final List<Map<String, dynamic>> aspects;
  final List<Color> signColors;
  final bool showHouses;

  _ChartWheelPainter({required this.planets, required this.asc, required this.mc,
    required this.aspects, required this.signColors, this.showHouses = true});

  static const _glyphs = ['♈','♉','♊','♋','♌','♍','♎','♏','♐','♑','♒','♓'];
  static const _pGlyphs = {'sun':'☉','moon':'☽','mercury':'☿','venus':'♀','mars':'♂',
    'jupiter':'♃','saturn':'♄','uranus':'♅','neptune':'♆','pluto':'♇'};

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 600;
    final outerR = 270 * scale;
    final innerR = 220 * scale;
    final planetR = 185 * scale;
    final coreR = 50 * scale;
    final ascRad = -asc * pi / 180 - pi / 2;

    // Circles
    for (final r in [outerR, innerR, coreR]) {
      canvas.drawCircle(center, r, Paint()..color = const Color(0x30FFFFFF)..style = PaintingStyle.stroke..strokeWidth = 1);
    }

    // 12 sign sectors
    for (int i = 0; i < 12; i++) {
      final startAngle = ascRad + i * pi / 6;
      final midAngle = startAngle + pi / 12;

      canvas.drawLine(
        Offset(center.dx + outerR * cos(startAngle), center.dy + outerR * sin(startAngle)),
        Offset(center.dx + innerR * cos(startAngle), center.dy + innerR * sin(startAngle)),
        Paint()..color = const Color(0x20FFFFFF)..strokeWidth = 0.5);

      final glyphR = (outerR + innerR) / 2;
      final tp = TextPainter(text: TextSpan(text: _glyphs[i],
        style: TextStyle(fontSize: 14, color: signColors[i].withAlpha(180))),
        textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(center.dx + glyphR * cos(midAngle) - tp.width / 2,
        center.dy + glyphR * sin(midAngle) - tp.height / 2));
    }

    // ASC/DSC/MC/IC lines
    if (showHouses) {
      final axes = [
        [asc, 'ASC', const Color(0xFFFFD370)],
        [(asc + 180) % 360, 'DSC', const Color(0xFFFFD370)],
        [mc, 'MC', const Color(0xFF6BB5FF)],
        [(mc + 180) % 360, 'IC', const Color(0xFF6BB5FF)],
      ];
      for (final ax in axes) {
        final angle = -(ax[0] as double) * pi / 180 - pi / 2;
        canvas.drawLine(
          Offset(center.dx + coreR * cos(angle), center.dy + coreR * sin(angle)),
          Offset(center.dx + innerR * cos(angle), center.dy + innerR * sin(angle)),
          Paint()..color = (ax[2] as Color).withAlpha(64)..strokeWidth = 1);
      }
    }

    // Aspect lines
    for (final a in aspects) {
      final lon1 = planets[a['p1']] ?? 0;
      final lon2 = planets[a['p2']] ?? 0;
      final ang1 = -(lon1) * pi / 180 - pi / 2 + ascRad + pi / 2;
      final ang2 = -(lon2) * pi / 180 - pi / 2 + ascRad + pi / 2;
      canvas.drawLine(
        Offset(center.dx + coreR * 0.9 * cos(ang1), center.dy + coreR * 0.9 * sin(ang1)),
        Offset(center.dx + coreR * 0.9 * cos(ang2), center.dy + coreR * 0.9 * sin(ang2)),
        Paint()..color = (a['color'] as Color).withAlpha(60)..strokeWidth = 0.8);
    }

    // Planet glyphs
    for (final e in planets.entries) {
      final angle = -(e.value) * pi / 180 - pi / 2 + ascRad + pi / 2;
      final glyph = _pGlyphs[e.key] ?? '?';
      final tp = TextPainter(text: TextSpan(text: glyph,
        style: const TextStyle(fontSize: 13, color: Color(0xFFFFD370))),
        textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(center.dx + planetR * cos(angle) - tp.width / 2,
        center.dy + planetR * sin(angle) - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
