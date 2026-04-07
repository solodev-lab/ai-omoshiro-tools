import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../utils/solara_storage.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapCtrl = MapController();
  LatLng _center = const LatLng(35.4233, 136.7607);

  // UI state
  bool _searchOpen = false;
  bool _layerPanelOpen = false;
  bool _fortuneSheetOpen = false;
  bool _vpPanelOpen = false;
  String _vpTab = 'vp'; // 'vp' or 'loc'
  bool _seeded = false; // seed card drawn today
  final TextEditingController _searchCtrl = TextEditingController();

  // Layer visibility
  // HTML: data-layer="sectors","compass","natal","progressed","transit"
  final Map<String, bool> _layers = {
    'sectors': true, 'compass': true, 'transit': true,
    'natal': false, 'progressed': false,
  };

  // Fortune category
  // HTML: fp-item data-fortune="all","healing","money","love","work","communication"
  String _activeCategory = 'all';
  String _activeSrc = 'combined'; // HTML: fs-tab data-s="combined","transit","progressed"

  // HTML: fp-item --pc colors: all=#E8E0D0, healing=#64C8B4, money=#F5D76E, love=#FF88B4, work=#6BB5FF, communication=#B088FF
  static const _categoryColors = <String, Color>{
    'all': Color(0xFFE8E0D0), 'healing': Color(0xFF64C8B4), 'money': Color(0xFFF5D76E),
    'love': Color(0xFFFF88B4), 'work': Color(0xFF6BB5FF), 'communication': Color(0xFFB088FF),
  };

  // Planet group visibility
  final Map<String, bool> _planetGroups = {
    'personal': true, 'social': false, 'generational': false,
  };

  static const _dir16 = ['N','NNE','NE','ENE','E','ESE','SE','SSE',
                          'S','SSW','SW','WSW','W','WNW','NW','NNW'];
  static const _dir16JP = <String,String>{'N':'北','NNE':'北北東','NE':'北東','ENE':'東北東',
    'E':'東','ESE':'東南東','SE':'南東','SSE':'南南東','S':'南','SSW':'南南西',
    'SW':'南西','WSW':'西南西','W':'西','WNW':'西北西','NW':'北西','NNW':'北北西'};

  final Map<String, double> _sectorScores = {};

  // Search result
  String? _searchResultName;


  @override
  void initState() {
    super.initState();
    _loadProfile();
    _generateMockScores();
  }

  void _generateMockScores() {
    final rng = Random(DateTime.now().day);
    for (final d in _dir16) {
      _sectorScores[d] = rng.nextDouble() * 6;
    }
  }

  Future<void> _loadProfile() async {
    final p = await SolaraStorage.loadProfile();
    if (p != null && p.isComplete) {
      setState(() => _center = LatLng(p.birthLat, p.birthLng));
    }
  }

  Future<void> _doSearch(String query) async {
    if (query.length < 2) return;
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1');
      final resp = await http.get(uri, headers: {'User-Agent': 'SolaraApp/1.0', 'Accept-Language': 'ja,en'});
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List;
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lng = double.parse(data[0]['lon']);
          _mapCtrl.move(LatLng(lat, lng), 10);
          setState(() {
            _searchOpen = false;
            _searchResultName = data[0]['display_name'] as String?;
          });
        }
      }
    } catch (_) {}
  }

  // Rank: top 1 = strong, top 2 = weak, rest = null (matches HTML computeRanks)
  String? _sectorRank(String dir) {
    final sorted = _sectorScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final idx = sorted.indexWhere((e) => e.key == dir);
    if (idx == 0) return 'strong';
    if (idx == 1) return 'weak';
    return null;
  }

  // pct() from HTML: 0-5 → 0-83.3%, 5-10 → 83.3-100%
  double _pct(double v) {
    if (v <= 5) return (v / 5) * (100 * 5 / 6);
    return (5 / 6) * 100 + (1 / 6) * 100 * ((v - 5) / 5).clamp(0, 1);
  }

  // ══════════════════════════════════════════════
  // Sector polygons
  // ══════════════════════════════════════════════
  List<Polygon> _buildSectors() {
    if (!_layers['sectors']!) return [];
    final polygons = <Polygon>[];
    const d = Distance();

    for (int i = 0; i < 16; i++) {
      final dir = _dir16[i];
      final rank = _sectorRank(dir);
      if (rank == null) continue;

      final bearing = i * 22.5;
      const halfWidth = 11.25;
      const maxDist = 20000000.0;
      const radialSteps = 25;
      const arcSteps = 20;
      final points = <LatLng>[];

      points.add(_center);
      final leftBearing = bearing - halfWidth;
      for (int s = 1; s <= radialSteps; s++) {
        final dist = maxDist * s / radialSteps;
        points.add(d.offset(_center, dist, leftBearing));
      }
      for (int s = 1; s <= arcSteps; s++) {
        final a = leftBearing + (halfWidth * 2) * s / arcSteps;
        points.add(d.offset(_center, maxDist, a));
      }
      final rightBearing = bearing + halfWidth;
      for (int s = radialSteps - 1; s >= 1; s--) {
        final dist = maxDist * s / radialSteps;
        points.add(d.offset(_center, dist, rightBearing));
      }

      // HTML: strong fillOpacity=0.40 opacity=0.85 weight=3
      //       weak   fillOpacity=0.20 opacity=0.50 weight=2
      final isStrong = rank == 'strong';
      final sectorColor = _categoryColors[_activeCategory] ?? const Color(0xFFC9A84C);
      polygons.add(Polygon(
        points: points,
        color: sectorColor.withAlpha(isStrong ? 102 : 51),
        borderColor: sectorColor.withAlpha(isStrong ? 217 : 128),
        borderStrokeWidth: isStrong ? 3.0 : 2.0,
      ));
    }
    return polygons;
  }

  // ══════════════════════════════════════════════
  // Compass lines
  // ══════════════════════════════════════════════
  List<Polyline> _buildCompass() {
    if (!_layers['compass']!) return [];
    final lines = <Polyline>[];
    const d = Distance();
    for (int i = 0; i < 16; i++) {
      final bearing = i * 22.5;
      final pts = <LatLng>[];
      for (double km = 0; km <= 20000000; km += 500000) {
        pts.add(d.offset(_center, km, bearing));
      }
      lines.add(Polyline(
        points: pts,
        color: const Color(0x59C9A84C), // rgba(201,168,76,0.35)
        strokeWidth: 1,
      ));
    }
    return lines;
  }

  // ══════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Leaflet Map ──
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: _center, initialZoom: 14,
            minZoom: 2, maxZoom: 18,
            backgroundColor: const Color(0xFF080C14),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}.png',
              maxZoom: 18,
            ),
            PolygonLayer(polygons: _buildSectors()),
            PolylineLayer(polylines: _buildCompass()),
            // HTML: vpPin — center marker
            MarkerLayer(markers: [
              Marker(point: _center, width: 20, height: 20, child: Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // HTML: radial-gradient(circle at 40% 35%, #FFE8A0, #C9A84C)
                  gradient: const RadialGradient(
                    center: Alignment(-0.2, -0.3),
                    colors: [Color(0xFFFFE8A0), Color(0xFFC9A84C)],
                  ),
                  // HTML: border: 2px solid #E8E0D0
                  border: Border.all(color: const Color(0xFFE8E0D0), width: 2),
                  // HTML: box-shadow: 0 0 12px rgba(201,168,76,.6), 0 2px 6px rgba(0,0,0,.4)
                  boxShadow: const [
                    BoxShadow(color: Color(0x99C9A84C), blurRadius: 12),
                    BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
              )),
            ]),
          ],
        ),

        // ── Search Trigger Button ──
        // HTML: .search-trigger { top:82px; left:16px; width:40px; height:40px; border-radius:50%;
        //   background:rgba(10,10,25,.8); border:1px solid rgba(255,255,255,.12); }
        if (!_searchOpen) Positioned(
          top: MediaQuery.of(context).padding.top + 32, left: 16,
          child: _MapBtn(
            child: const Icon(Icons.search, size: 18, color: Color(0x99C9A84C)),
            onTap: () => setState(() => _searchOpen = true),
          ),
        ),

        // ── Search Bar (open state) ──
        // HTML: .search-bar { top:82px; left:16px; right:16px; }
        if (_searchOpen) Positioned(
          top: MediaQuery.of(context).padding.top + 32, left: 16, right: 16,
          child: Container(
            decoration: BoxDecoration(
              // HTML: background:rgba(15,15,30,.9); backdrop-filter:blur(15px);
              color: const Color(0xE60F0F1E),
              borderRadius: BorderRadius.circular(10),
              // HTML: border:1px solid rgba(255,255,255,.15);
              border: Border.all(color: const Color(0x26FFFFFF)),
            ),
            child: Row(children: [
              Expanded(child: TextField(
                controller: _searchCtrl, autofocus: true,
                // HTML: color:#E8E0D0; font-size:13px;
                style: const TextStyle(color: Color(0xFFE8E0D0), fontSize: 13),
                decoration: InputDecoration(
                  // HTML: placeholder "🔍 場所を検索..."
                  hintText: '🔍 場所を検索...',
                  hintStyle: const TextStyle(color: Color(0xFF555555)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onSubmitted: _doSearch,
              )),
              // Close / search button
              GestureDetector(
                onTap: () => setState(() => _searchOpen = false),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('✕', style: TextStyle(color: Color(0xFF555555), fontSize: 16)),
                ),
              ),
            ]),
          ),
        ),

        // ── Layer Button ──
        // HTML: .layer-btn { top:130px; left:16px; width:40px; height:40px; }
        Positioned(
          top: MediaQuery.of(context).padding.top + 80, left: 16,
          child: _MapBtn(
            active: _layerPanelOpen,
            onTap: () => setState(() => _layerPanelOpen = !_layerPanelOpen),
            // HTML: 3 bars with different colors
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 18, height: 2, decoration: BoxDecoration(color: const Color(0xFFE8E0D0), borderRadius: BorderRadius.circular(1))),
              const SizedBox(height: 3),
              Container(width: 18, height: 2, decoration: BoxDecoration(color: const Color(0xFFC9A84C), borderRadius: BorderRadius.circular(1))),
              const SizedBox(height: 3),
              Container(width: 18, height: 2, decoration: BoxDecoration(color: const Color(0xFF00D4FF), borderRadius: BorderRadius.circular(1))),
            ]),
          ),
        ),

        // ── Layer Panel ──
        // HTML: .layer-panel { top:175px; left:60px; width:100px; border-radius:14px; padding:14px; }
        if (_layerPanelOpen) Positioned(
          top: MediaQuery.of(context).padding.top + 128, left: 60,
          child: _buildLayerPanel(),
        ),

        // ── Fortune Filter Label ──
        // HTML: .ff-label { top:52px; left:16px; }
        Positioned(
          top: MediaQuery.of(context).padding.top + 2, left: 16,
          child: _buildFortuneFilterLabel(),
        ),

        // ── Fortune Pull Tab ──
        // HTML: .fs-pull { bottom:80px; left:50%; transform:translateX(-50%); }
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () => setState(() => _fortuneSheetOpen = !_fortuneSheetOpen),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 2),
                decoration: BoxDecoration(
                  // HTML: background:rgba(10,10,25,.8); border:1px solid rgba(201,168,76,.2);
                  color: const Color(0xCC0A0A19),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border.all(color: const Color(0x33C9A84C)),
                ),
                // HTML: font-size:10px; color:#888; letter-spacing:.5px;
                child: Text(
                  _fortuneSheetOpen ? '▼ 運勢方位' : '▲ 運勢方位',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF888888), letterSpacing: 0.5),
                ),
              ),
            ),
          ),
        ),

        // ── Fortune Sheet ──
        if (_fortuneSheetOpen) Positioned(
          bottom: 0, left: 0, right: 0,
          child: _buildFortuneSheet(),
        ),

        // ── Viewpoint Button ──
        // HTML: .vp-btn { top:178px; left:16px; width:40px; height:40px; "📍" }
        Positioned(
          top: MediaQuery.of(context).padding.top + 128, left: 16,
          child: _MapBtn(
            active: _vpPanelOpen,
            onTap: () => setState(() => _vpPanelOpen = !_vpPanelOpen),
            child: const Text('📍', style: TextStyle(fontSize: 16)),
          ),
        ),

        // ── Viewpoint Panel ──
        // HTML: .vp-panel { top:222px; left:60px; width:180px; }
        if (_vpPanelOpen) Positioned(
          top: MediaQuery.of(context).padding.top + 172, left: 60,
          child: _buildVPPanel(),
        ),

        // ── Seed Badge ──
        // HTML: .seed-badge { top:56px; right:20px; width:36px; height:36px; }
        if (_seeded) Positioned(
          top: MediaQuery.of(context).padding.top + 6, right: 20,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x26C9A84C), // rgba(201,168,76,.15)
              border: Border.all(color: const Color(0x66C9A84C)), // rgba(201,168,76,.4)
            ),
            child: const Center(child: Text('🌱', style: TextStyle(fontSize: 16))),
          ),
        ),

        // ── Stella ──
        // HTML: .stella { bottom:90px; left:20px; right:20px; }
        Positioned(
          bottom: _fortuneSheetOpen ? 320 : 30, left: 20, right: 20,
          child: _buildStella(),
        ),

        // ── Preseed (shown when no scores yet) ──
        // HTML: .preseed { top:50%; left:50%; transform:translate(-50%,-50%); z-index:30; }
        if (_sectorScores.values.every((v) => v < 0.01))
          const Center(child: _Preseed()),

        // ── Search Result Popup ──
        // HTML: .sr-popup { bottom:160px; left:16px; right:16px; }
        if (_searchResultName != null) Positioned(
          bottom: 160, left: 16, right: 16,
          child: _buildSearchResult(),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════
  // Fortune Filter Label
  // HTML: .ff-label { position:absolute; top:52px; left:16px; z-index:105;
  //   display:inline-flex; align-items:center; gap:6px;
  //   font-size:10px; color:#C9A84C; background:rgba(10,10,20,.7);
  //   padding:3px 10px; border-radius:10px; border:1px solid rgba(201,168,76,.3);
  //   letter-spacing:.5px; pointer-events:none; }
  // ══════════════════════════════════════════════
  Widget _buildFortuneFilterLabel() {
    final sorted = _sectorScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.isEmpty) return const SizedBox();

    final srcLabels = {'combined':'合計','transit':'トランジット','progressed':'プログレス'};
    final catLabels = {'all':'総合','healing':'癒し','money':'金運','love':'恋愛','work':'仕事','communication':'話す'};

    // HTML: top 2 directions
    final top2 = sorted.where((e) => e.value > 0.01).take(2).toList();
    final maxScore = top2.isNotEmpty ? top2.first.value : 1.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xB30A0A14), // rgba(10,10,20,.7)
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x4DC9A84C)), // rgba(201,168,76,.3)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HTML: .ff-tag { white-space:nowrap; flex-shrink:0; }
          Text(
            '${srcLabels[_activeSrc] ?? '合計'} / ${catLabels[_activeCategory] ?? '総合'}',
            style: const TextStyle(fontSize: 10, color: Color(0xFFC9A84C), letterSpacing: 0.5),
          ),
          if (top2.isNotEmpty) ...[
            const SizedBox(width: 6),
            // HTML: .ff-bars { flex:1; display:flex; flex-direction:column; gap:2px; }
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: top2.map((e) {
                final pct = (e.value / maxScore).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  // HTML: .ff-row { display:flex; align-items:center; gap:4px; font-size:9px; color:#E8E0D0; }
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    // HTML: .ff-dir { width:32px; text-align:right; color:#888; }
                    SizedBox(width: 32, child: Text(
                      _dir16JP[e.key] ?? e.key,
                      style: const TextStyle(fontSize: 9, color: Color(0xFF888888)),
                      textAlign: TextAlign.right,
                    )),
                    const SizedBox(width: 4),
                    // HTML: .ff-bw { width:120px; height:5px; background:rgba(255,255,255,0.06); border-radius:3px; }
                    SizedBox(
                      width: 120, height: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0x0FFFFFFF), // rgba(255,255,255,0.06)
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: pct,
                          // HTML: .ff-b { height:100%; border-radius:3px; background:#C9A84C; }
                          child: Container(
                            decoration: BoxDecoration(
                              color: _categoryColors[_activeCategory] ?? const Color(0xFFC9A84C),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // HTML: .ff-sc { width:28px; text-align:right; font-family:monospace; font-size:8px; color:#F6BD60; }
                    SizedBox(width: 28, child: Text(
                      e.value.toStringAsFixed(2),
                      style: const TextStyle(fontSize: 8, fontFamily: 'monospace', color: Color(0xFFF6BD60)),
                      textAlign: TextAlign.right,
                    )),
                  ]),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // Layer Panel
  // HTML: .layer-panel { width:100px; background:rgba(12,12,26,.92); border:1px solid rgba(201,168,76,.2);
  //   border-radius:14px; padding:14px; }
  // ══════════════════════════════════════════════
  // HTML: .layer-panel { width:100px; }
  Widget _buildLayerPanel() {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xEB0C0C1A), // rgba(12,12,26,.92)
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33C9A84C)), // rgba(201,168,76,.2)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('LAYERS', style: TextStyle(fontSize: 9, color: Color(0xFF666666), letterSpacing: 1.5)),
          const SizedBox(height: 10),

          // MAP section
          _lpSection('MAP', [
            _lpToggle('sectors', '方位EN', const Color(0xFFC9A84C)),
            _lpToggle('compass', 'コンパス', const Color(0xFFE8E0D0)),
          ]),

          // CHART section
          _lpSection('CHART', [
            _lpToggle('natal', 'Natal', const Color(0xFFE8E0D0)),
            _lpToggle('progressed', 'Progressed', const Color(0xFFC9A84C)),
            _lpToggle('transit', 'Transit', const Color(0xFF00D4FF)),
          ]),

          // HTML: PLANET GROUP section (line 312-316)
          _lpSection('PLANET GROUP', [
            _lpGroupToggle('personal', '個人天体', const Color(0xFFFFD370)),
            _lpGroupToggle('social', '社会天体', const Color(0xFF6BB5FF)),
            _lpGroupToggle('generational', '世代天体', const Color(0xFFB088FF)),
          ]),

          // FORTUNE section
          _lpSection('FORTUNE', [
            ..._categoryColors.entries.map((e) {
              final labels = {'all':'総合','healing':'癒し','money':'金運','love':'恋愛','work':'仕事','communication':'話す'};
              final active = _activeCategory == e.key;
              return GestureDetector(
                onTap: () => setState(() => _activeCategory = e.key),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: active ? e.value : const Color(0x1FFFFFFF)),
                    color: active ? e.value.withAlpha(26) : Colors.transparent,
                  ),
                  child: Text(labels[e.key] ?? e.key,
                    style: TextStyle(fontSize: 10, color: active ? e.value : const Color(0xFF555555), letterSpacing: 0.3)),
                ),
              );
            }),
          ]),
        ],
      ),
    );
  }

  Widget _lpGroupToggle(String key, String label, Color color) {
    final on = _planetGroups[key] ?? false;
    return GestureDetector(
      onTap: () => setState(() => _planetGroups[key] = !on),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Container(
            width: 14, height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: on ? color : const Color(0x33FFFFFF), width: 1.5),
              color: on ? color.withAlpha(26) : Colors.transparent,
            ),
            child: on ? Center(child: Text('✓', style: TextStyle(fontSize: 9, color: color))) : null,
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 11, color: on ? const Color(0xFFBBBBBB) : const Color(0xFF666666))),
        ]),
      ),
    );
  }

  // HTML: .lp-sec { margin-bottom:10px; padding-bottom:8px; border-bottom:1px solid rgba(255,255,255,.06); }
  Widget _lpSection(String label, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0FFFFFFF))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HTML: .lp-label { font-size:8px; color:#555; letter-spacing:1px; margin-bottom:6px; }
          Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF555555), letterSpacing: 1)),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  // HTML: .lt { display:flex; align-items:center; gap:8px; padding:5px 0; }
  // .lt-check { width:14px; height:14px; border-radius:3px; }
  // .lt.on .lt-check { border-color:var(--tc); color:var(--tc); background:rgba(201,168,76,.1); }
  // .lt-text { font-size:11px; color:#666; } .lt.on .lt-text { color:#bbb; }
  Widget _lpToggle(String key, String label, Color color) {
    final on = _layers[key] ?? false;
    return GestureDetector(
      onTap: () => setState(() => _layers[key] = !on),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Container(
            width: 14, height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: on ? color : const Color(0x33FFFFFF), width: 1.5),
              color: on ? color.withAlpha(26) : Colors.transparent,
            ),
            child: on ? Center(child: Text('✓', style: TextStyle(fontSize: 9, color: color))) : null,
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 11, color: on ? const Color(0xFFBBBBBB) : const Color(0xFF666666))),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // Fortune Sheet
  // HTML: .fs { bottom:80px; background:rgba(10,10,25,.95); border-top:1px solid rgba(201,168,76,.25);
  //   border-radius:16px 16px 0 0; }
  // ══════════════════════════════════════════════
  Widget _buildFortuneSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF20A0A19), // rgba(10,10,25,.95)
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: Color(0x40C9A84C))), // rgba(201,168,76,.25)
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HTML: .fs-handle { width:36px; height:4px; background:rgba(255,255,255,.25); border-radius:2px; margin:10px auto 6px; }
          GestureDetector(
            onTap: () => setState(() => _fortuneSheetOpen = false),
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              decoration: BoxDecoration(
                color: const Color(0x40FFFFFF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // HTML: .fs-tabs .fs-src — Source tabs (合計/トランジット/プログレス)
          _buildSrcTabs(),

          // HTML: .fs-legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _LegendDot(color: Color(0xFFC9A84C), label: 'T柔'),
                SizedBox(width: 10),
                _LegendDot(color: Color(0xFF6B5CE7), label: 'T剛'),
                SizedBox(width: 10),
                _LegendDot(color: Color(0xFF4CB8B0), label: 'P柔'),
                SizedBox(width: 10),
                _LegendDot(color: Color(0xFFE74C6B), label: 'P剛'),
              ],
            ),
          ),

          // HTML: .fs-tabs .fs-cat — Category tabs (総合/癒し/金運/恋愛/仕事/話す)
          _buildCatTabs(),

          // HTML: .fs-body { height:185px; overflow-y:auto; padding:10px 14px 14px; }
          SizedBox(
            height: 185,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              children: _buildFortuneRows(),
            ),
          ),
        ],
      ),
    );
  }

  // HTML: .fs-tabs { display:flex; gap:0; padding:0 8px; border-bottom:1px solid rgba(255,255,255,.06); }
  // .fs-tab { padding:8px 12px; font-size:11px; color:#666; border-bottom:2px solid transparent; }
  // .fs-tab.active { color:#C9A84C; border-bottom-color:#C9A84C; }
  Widget _buildSrcTabs() {
    const srcs = [('combined', '合計'), ('transit', 'トランジット'), ('progressed', 'プログレス')];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0FFFFFFF))),
      ),
      child: Row(
        children: srcs.map((s) {
          final active = _activeSrc == s.$1;
          return GestureDetector(
            onTap: () => setState(() => _activeSrc = s.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(
                  color: active ? const Color(0xFFC9A84C) : Colors.transparent, width: 2)),
              ),
              child: Text(s.$2, style: TextStyle(fontSize: 11,
                color: active ? const Color(0xFFC9A84C) : const Color(0xFF666666))),
            ),
          );
        }).toList(),
      ),
    );
  }

  // HTML: .fs-cat .fs-tab { font-size:10px; padding:6px 10px; }
  Widget _buildCatTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categoryColors.entries.map((e) {
          final labels = {'all':'総合','healing':'癒し','money':'金運','love':'恋愛','work':'仕事','communication':'話す'};
          final active = _activeCategory == e.key;
          return GestureDetector(
            onTap: () => setState(() => _activeCategory = e.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(
                  color: active ? const Color(0xFFC9A84C) : Colors.transparent, width: 2)),
              ),
              child: Text(labels[e.key] ?? e.key, style: TextStyle(fontSize: 10,
                color: active ? const Color(0xFFC9A84C) : const Color(0xFF666666))),
            ),
          );
        }).toList(),
      ),
    );
  }

  // HTML: .fs-row { display:flex; align-items:center; padding:7px 4px; border-bottom:1px solid rgba(255,255,255,.04); }
  // .fs-dir { width:36px; font-size:12px; font-weight:600; color:#B49774; }
  // .fs-bar-wrap { flex:1; height:14px; background:rgba(255,255,255,.04); border-radius:7px; margin:0 10px; }
  // .fs-score { width:48px; text-align:right; font-size:11px; font-family:monospace; color:#F6BD60; }
  List<Widget> _buildFortuneRows() {
    final sorted = _sectorScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.where((e) => e.value > 0.01).map((e) {
      final pct = (_pct(e.value) / 100).clamp(0.0, 1.0);
      final catColor = _categoryColors[_activeCategory] ?? const Color(0xFFC9A84C);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x0AFFFFFF))),
        ),
        child: Row(children: [
          // HTML: .fs-dir
          SizedBox(width: 36, child: Text(_dir16JP[e.key] ?? e.key,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFB49774)))),
          // HTML: .fs-bar-wrap > .fs-stack > .fs-seg
          Expanded(
            child: Container(
              height: 14, margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0x0AFFFFFF), // rgba(255,255,255,.04)
                borderRadius: BorderRadius.circular(7),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(
                    color: catColor,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ),
          ),
          // HTML: .fs-score
          SizedBox(width: 48, child: Text(e.value.toStringAsFixed(1),
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFFF6BD60)),
            textAlign: TextAlign.right)),
        ]),
      );
    }).toList();
  }

  // ══════════════════════════════════════════════
  // Stella
  // HTML: .stella { bottom:90px; left:20px; right:20px;
  //   background:rgba(15,15,30,.75); backdrop-filter:blur(20px);
  //   border:1px solid rgba(201,168,76,.2); border-radius:16px; padding:16px 20px; }
  // .stella-name { font-size:10px; letter-spacing:2px; color:#6B5CE7; text-transform:uppercase; }
  // .stella-text { font-size:13px; line-height:1.6; }  .hl { color:#C9A84C; font-weight:600; }
  // ══════════════════════════════════════════════
  Widget _buildStella() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xBF0F0F1E), // rgba(15,15,30,.75)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33C9A84C)), // rgba(201,168,76,.2)
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('✨ Stella', style: TextStyle(
          fontSize: 10, letterSpacing: 2, color: Color(0xFF6B5CE7))),
        const SizedBox(height: 6),
        RichText(text: const TextSpan(
          style: TextStyle(fontSize: 13, color: Color(0xFFEAEAEA), height: 1.6),
          children: [
            TextSpan(text: '『再会の喜び』', style: TextStyle(color: Color(0xFFC9A84C), fontWeight: FontWeight.w600)),
            TextSpan(text: 'が今日の種。北東の風が、懐かしい誰かとの縁を運んでくるよ。'),
          ],
        )),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // Viewpoint Panel
  // HTML: .vp-panel { top:222px; left:60px; width:180px; }
  // .vp-tabs: "📍 VIEWPOINT" / "🌐 LOCATIONS"
  // .vp-action: "📡 現在地に移動" / "💾 この地点を保存"
  // ══════════════════════════════════════════════
  Widget _buildVPPanel() {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xEB0C0C1A), // rgba(12,12,26,.92)
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        // HTML: .vp-tabs
        Container(
          decoration: BoxDecoration(
            color: const Color(0x08FFFFFF),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(children: [
            _vpTabBtn('vp', '📍 VIEWPOINT'),
            _vpTabBtn('loc', '🌐 LOCATIONS'),
          ]),
        ),
        const SizedBox(height: 10),
        // Content based on tab
        if (_vpTab == 'vp') ...[
          // HTML: .vp-action
          _vpAction('📡', '現在地に移動', () {}),
          _vpAction('💾', 'この地点を保存', () {}),
        ] else ...[
          const Text('保存された場所はありません',
            style: TextStyle(fontSize: 10, color: Color(0xFF666666))),
          const SizedBox(height: 8),
          _vpAction('💾', 'この地点を登録', () {}),
        ],
        const SizedBox(height: 8),
        // HTML: .vp-coord
        Center(child: Text(
          '${_center.latitude.toStringAsFixed(4)}, ${_center.longitude.toStringAsFixed(4)}',
          style: const TextStyle(fontSize: 9, color: Color(0x80C9A84C), letterSpacing: 0.3),
        )),
      ]),
    );
  }

  // HTML: .vp-tab { font-size:8px; letter-spacing:1px; }
  // .vp-tab.active { background:rgba(201,168,76,.15); color:#C9A84C; }
  Widget _vpTabBtn(String key, String label) {
    final active = _vpTab == key;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _vpTab = key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: active ? const Color(0x26C9A84C) : Colors.transparent,
        ),
        child: Center(child: Text(label, style: TextStyle(
          fontSize: 8, letterSpacing: 1,
          color: active ? const Color(0xFFC9A84C) : const Color(0xFF666666),
        ))),
      ),
    ));
  }

  // HTML: .vp-action { padding:6px 4px; border-radius:8px; font-size:11px; color:#888; }
  Widget _vpAction(String icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // Search Result Popup
  // HTML: .sr-popup { bottom:160px; left:16px; right:16px;
  //   background:rgba(15,15,30,.85); border:1px solid rgba(255,255,255,.1); border-radius:12px; padding:14px 16px; }
  // Contains: sr-close, sr-name, sr-sector, sr-tabs, sr-advice
  // ══════════════════════════════════════════════
  Widget _buildSearchResult() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xD90F0F1E), // rgba(15,15,30,.85)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        // sr-close + sr-name
        Row(children: [
          Expanded(
            // HTML: .sr-name { font-size:13px; color:#E8E0D0; margin-bottom:6px; }
            child: Text(_searchResultName ?? '',
              style: const TextStyle(fontSize: 13, color: Color(0xFFE8E0D0)),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          // HTML: .sr-close { color:#555; font-size:16px; }
          GestureDetector(
            onTap: () => setState(() => _searchResultName = null),
            child: const Text('✕', style: TextStyle(fontSize: 16, color: Color(0xFF555555))),
          ),
        ]),
        const SizedBox(height: 6),
        // HTML: .sr-sector { font-size:12px; line-height:1.5; }
        const Text('方位情報を読み込み中...', style: TextStyle(fontSize: 12, color: Color(0xFF888888), height: 1.5)),
        // HTML: .sr-tabs { display:flex; border-bottom:1px solid rgba(255,255,255,.08); }
        const SizedBox(height: 10),
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x14FFFFFF))),
          ),
          child: Row(children: [
            _srTab('総合', true),
            _srTab('癒し', false),
            _srTab('金運', false),
          ]),
        ),
        // HTML: .sr-advice { font-size:11px; line-height:1.6; color:rgba(232,224,208,.85); margin-top:8px; }
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('この場所のエネルギー分析はAPI接続後に表示されます。',
            style: TextStyle(fontSize: 11, color: Color(0xD9E8E0D0), height: 1.6)),
        ),
      ]),
    );
  }

  // HTML: .sr-tab { flex:1; padding:6px 0; font-size:10px; color:#666; text-align:center;
  //   border-bottom:2px solid transparent; }
  // .sr-tab.active { color:#C9A84C; border-bottom-color:#C9A84C; }
  Widget _srTab(String label, bool active) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(
          color: active ? const Color(0xFFC9A84C) : Colors.transparent, width: 2)),
      ),
      child: Center(child: Text(label, style: TextStyle(
        fontSize: 10, color: active ? const Color(0xFFC9A84C) : const Color(0xFF666666)))),
    ));
  }
}

// ══════════════════════════════════════════════════
// Map circle button
// HTML: .search-trigger, .layer-btn, .vp-btn
// width:40px; height:40px; border-radius:50%;
// background:rgba(10,10,25,.8); border:1px solid rgba(255,255,255,.12);
// ══════════════════════════════════════════════════

class _MapBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool active;
  const _MapBtn({required this.child, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xCC0A0A19), // rgba(10,10,25,.8)
          border: Border.all(
            color: active
                ? const Color(0x80C9A84C) // rgba(201,168,76,.5)
                : const Color(0x1FFFFFFF), // rgba(255,255,255,.12)
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Legend dot
// HTML: .fs-legend { font-size:9px; color:#888; }
// ══════════════════════════════════════════════════

// ══════════════════════════════════════════════════
// Preseed prompt (shown before first seed)
// HTML: .preseed { top:50%; left:50%; z-index:30; text-align:center; }
// .preseed-icon { font-size:32px; opacity:.6; animation:float 3s ease-in-out infinite; }
// .preseed-text { font-size:12px; color:#555; letter-spacing:1px; line-height:1.8; }
// ══════════════════════════════════════════════════

class _Preseed extends StatelessWidget {
  const _Preseed();

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: const [
      Text('🌱', style: TextStyle(fontSize: 32)),
      SizedBox(height: 16),
      Text('今日の方位を探索してみよう\n地図をタップして始めてね',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Color(0xFF555555), letterSpacing: 1, height: 1.8)),
    ]);
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('●', style: TextStyle(fontSize: 9, color: color)),
        const SizedBox(width: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF888888))),
      ],
    );
  }
}
