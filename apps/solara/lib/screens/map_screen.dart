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

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapCtrl = MapController();
  LatLng _center = const LatLng(35.4233, 136.7607);

  // UI state
  bool _searchOpen = false;
  bool _layerPanelOpen = false;
  bool _fortuneSheetOpen = false;
  bool _vpPanelOpen = false;
  String _vpTab = 'vp'; // 'vp' or 'loc'
  // HTML preseed states: 'center' → 'bottom' → 'hidden'
  String _preseedState = 'center'; // 'center', 'bottom', 'hidden'
  bool _stellaMinimized = false;
  bool _restOverlayVisible = false;
  String _restOverlayText = '';
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
  // HTML: each direction has 4 component scores: tSoft, tHard, pSoft, pHard
  final Map<String, Map<String, double>> _sectorComps = {};

  // Search result
  String? _searchResultName;

  // HTML: COMP_COLORS
  static const _compColors = <String, Color>{
    'tSoft': Color(0xFFC9A84C), 'tHard': Color(0xFF6B5CE7),
    'pSoft': Color(0xFF4CB8B0), 'pHard': Color(0xFFE74C6B),
  };
  static const _compKeys = ['tSoft', 'tHard', 'pSoft', 'pHard'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _generateMockScores();
  }

  void _generateMockScores() {
    final rng = Random(DateTime.now().day);
    for (final d in _dir16) {
      final ts = rng.nextDouble() * 2.5;
      final th = rng.nextDouble() * 1.5;
      final ps = rng.nextDouble() * 1.2;
      final ph = rng.nextDouble() * 0.8;
      _sectorComps[d] = {'tSoft': ts, 'tHard': th, 'pSoft': ps, 'pHard': ph};
      _sectorScores[d] = ts + th + ps + ph;
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

  // pct() from HTML: 0-5 → 0-83.3%, 5-10 → 83.3-100%
  double _pct(double v) {
    if (v <= 5) return (v / 5) * (100 * 5 / 6);
    return (5 / 6) * 100 + (1 / 6) * 100 * ((v - 5) / 5).clamp(0, 1);
  }

  // ══════════════════════════════════════════════
  // Sector polygons — HTML: 8 directions, blessed/mid/shadow
  // blessed: fillOpacity=0.12, opacity=0.5, weight=2, color=#C9A84C
  // shadow:  fillOpacity=0.10, opacity=0.25, weight=1, color=#6B5CE7, fill=#2D1B4E
  // mid:     fillOpacity=0.06, opacity=0.2,  weight=1, color=#3A4A6B
  // ══════════════════════════════════════════════
  static const _dir8 = ['N','NE','E','SE','S','SW','W','NW'];
  static const _dir8Angles = <String, List<double>>{
    'N':  [337.5, 22.5],  'NE': [22.5, 67.5],
    'E':  [67.5, 112.5],  'SE': [112.5, 157.5],
    'S':  [157.5, 202.5], 'SW': [202.5, 247.5],
    'W':  [247.5, 292.5], 'NW': [292.5, 337.5],
  };

  // Default sector types (matches HTML fallback when no seedBoostData)
  String _sectorType(String dir) {
    // Compute from _sectorScores: top 2 = blessed, next 3 = mid, rest = shadow
    // Map 16-dir scores to 8-dir by picking best sub-sector
    final score8 = <String, double>{};
    for (final d8 in _dir8) {
      double best = 0;
      for (final e in _sectorScores.entries) {
        // Check if this 16-dir falls within this 8-dir
        final idx16 = _dir16.indexOf(e.key);
        final bearing16 = idx16 * 22.5;
        final angles = _dir8Angles[d8]!;
        bool inSector;
        if (angles[0] > angles[1]) {
          inSector = bearing16 >= angles[0] || bearing16 < angles[1];
        } else {
          inSector = bearing16 >= angles[0] && bearing16 < angles[1];
        }
        if (inSector && e.value > best) best = e.value;
      }
      score8[d8] = best;
    }
    final sorted = score8.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final idx = sorted.indexWhere((e) => e.key == dir);
    if (idx < 2) return 'blessed';
    if (idx < 5) return 'mid';
    return 'shadow';
  }

  List<Polygon> _buildSectors() {
    if (!_layers['sectors']!) return [];
    final polygons = <Polygon>[];
    const d = Distance();
    const maxDist = 20000000.0; // 20000km in meters
    const radialSteps = 30;
    const arcSteps = 50;

    for (final dir in _dir8) {
      final angles = _dir8Angles[dir]!;
      double startDeg = angles[0];
      double endDeg = angles[1];
      if (startDeg > endDeg) endDeg += 360;

      final type = _sectorType(dir);
      final points = <LatLng>[];

      // Left edge (great circle from center outward)
      for (int s = 0; s <= radialSteps; s++) {
        final dist = maxDist * s / radialSteps;
        points.add(d.offset(_center, dist, startDeg % 360));
      }
      // Outer arc
      for (int s = 1; s <= arcSteps; s++) {
        final a = startDeg + (endDeg - startDeg) * s / arcSteps;
        points.add(d.offset(_center, maxDist, a % 360));
      }
      // Right edge (reversed, from outer to center)
      for (int s = radialSteps; s >= 0; s--) {
        final dist = maxDist * s / radialSteps;
        points.add(d.offset(_center, dist, endDeg % 360));
      }

      // HTML styles
      Color fillColor;
      Color borderColor;
      double borderWidth;
      switch (type) {
        case 'blessed':
          fillColor = const Color(0x1FC9A84C); // fillOpacity 0.12
          borderColor = const Color(0x80C9A84C); // opacity 0.5
          borderWidth = 2;
          break;
        case 'shadow':
          fillColor = const Color(0x1A2D1B4E); // fillOpacity 0.10
          borderColor = const Color(0x406B5CE7); // opacity 0.25
          borderWidth = 1;
          break;
        default: // mid
          fillColor = const Color(0x0F3A4A6B); // fillOpacity 0.06
          borderColor = const Color(0x333A4A6B); // opacity 0.2
          borderWidth = 1;
      }

      polygons.add(Polygon(
        points: points,
        color: fillColor,
        borderColor: borderColor,
        borderStrokeWidth: borderWidth,
      ));
    }
    return polygons;
  }

  // ══════════════════════════════════════════════
  // Compass lines
  // ══════════════════════════════════════════════
  // HTML: 8 direction lines (0,45,90,135,180,225,270,315)
  // color:'#C9A84C', weight:1, opacity:0.35, dashArray:'4 8'
  List<Polyline> _buildCompass() {
    if (!_layers['compass']!) return [];
    final lines = <Polyline>[];
    const d = Distance();
    for (int i = 0; i < 8; i++) {
      final bearing = i * 45.0;
      final pts = <LatLng>[];
      for (double km = 0; km <= 20000000; km += 1000000) {
        pts.add(d.offset(_center, km, bearing));
      }
      lines.add(Polyline(
        points: pts,
        color: const Color(0x59C9A84C), // rgba(201,168,76,0.35)
        strokeWidth: 1,
        pattern: StrokePattern.dashed(segments: const [4.0, 8.0]),
      ));
    }
    return lines;
  }

  // ══════════════════════════════════════════════
  // Direction labels at 3 distances
  // HTML: labelDistances=[2,150,1000]km
  // Cardinal(N,E,S,W): opacity 0.5, fontSize 11, bold
  // Intercardinal(NE,SE,SW,NW): opacity 0.3, fontSize 9, bold
  // ══════════════════════════════════════════════
  List<Marker> _buildDirLabels() {
    if (!_layers['compass']!) return [];
    final markers = <Marker>[];
    const d = Distance();
    const dirDefs = [
      ('N', 0.0), ('NE', 45.0), ('E', 90.0), ('SE', 135.0),
      ('S', 180.0), ('SW', 225.0), ('W', 270.0), ('NW', 315.0),
    ];
    const labelDistances = [2000.0, 150000.0, 1000000.0]; // meters

    for (final dist in labelDistances) {
      for (final dir in dirDefs) {
        final isCardinal = dir.$1.length == 1;
        final pt = d.offset(_center, dist, dir.$2);
        markers.add(Marker(
          point: pt,
          width: 24, height: 16,
          child: Center(
            child: Text(
              dir.$1,
              style: TextStyle(
                fontSize: isCardinal ? 11.0 : 9.0,
                fontWeight: FontWeight.bold,
                color: Color(isCardinal ? 0x80FFFFFF : 0x4DFFFFFF),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ));
      }
    }
    return markers;
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
            // HTML: dark_nolabels base + dark_only_labels overlay
            // .leaflet-tile-pane { filter: brightness(1.5) contrast(1.05) saturate(0.9) }
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              maxZoom: 19,
              tileBuilder: (context, tileWidget, tile) => ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  // brightness(1.5) * contrast(1.05) * saturate(0.9) approximation
                  1.42, 0.08, 0.05, 0, 0.0,
                  0.08, 1.35, 0.05, 0, 0.0,
                  0.08, 0.08, 1.32, 0, 0.0,
                  0,    0,    0,    1, 0,
                ]),
                child: tileWidget,
              ),
            ),
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_only_labels/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              maxZoom: 19,
            ),
            PolygonLayer(polygons: _buildSectors()),
            PolylineLayer(polylines: _buildCompass()),
            // HTML: direction labels (N,NE,E etc at 3 distances)
            MarkerLayer(markers: _buildDirLabels()),
            // HTML: VP Pin — draggable gold circle
            // radial-gradient(circle at 40% 35%, #FFE8A0, #C9A84C)
            // border:2px solid #E8E0D0
            // box-shadow: 0 0 12px rgba(201,168,76,.6), 0 2px 6px rgba(0,0,0,.4)
            MarkerLayer(markers: [
              Marker(point: _center, width: 20, height: 20, child: GestureDetector(
                onPanUpdate: (d) {
                  // Drag to move center (approximate)
                  final bounds = _mapCtrl.camera.visibleBounds;
                  final latRange = bounds.north - bounds.south;
                  final lngRange = bounds.east - bounds.west;
                  final size = MediaQuery.of(context).size;
                  setState(() {
                    _center = LatLng(
                      _center.latitude - d.delta.dy * latRange / size.height,
                      _center.longitude + d.delta.dx * lngRange / size.width,
                    );
                  });
                },
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(-0.2, -0.3), // circle at 40% 35%
                      colors: [Color(0xFFFFE8A0), Color(0xFFC9A84C)],
                    ),
                    border: Border.all(color: const Color(0xFFE8E0D0), width: 2),
                    boxShadow: const [
                      BoxShadow(color: Color(0x99C9A84C), blurRadius: 12),
                      BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                ),
              )),
            ]),
          ],
        ),

        // ── Fortune Filter Label (top bar) ──
        // HTML: .ff-label { top:52px; left:16px; }
        Positioned(
          top: MediaQuery.of(context).padding.top + 2, left: 16,
          child: _buildFortuneFilterLabel(),
        ),

        // ── 3 Buttons (below ff-label, left column) ──
        // ff-label height ~62px, starts at top+2 → bottom at ~top+64
        // Buttons: search(top+76), layer(top+124), vp(top+172)
        if (!_searchOpen) Positioned(
          top: MediaQuery.of(context).padding.top + 76, left: 16,
          child: _MapBtn(
            child: const Icon(Icons.search, size: 18, color: Color(0x99C9A84C)),
            onTap: () => setState(() => _searchOpen = true),
          ),
        ),

        Positioned(
          top: MediaQuery.of(context).padding.top + 124, left: 16,
          child: _MapBtn(
            active: _layerPanelOpen,
            onTap: () => setState(() => _layerPanelOpen = !_layerPanelOpen),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 18, height: 2, decoration: BoxDecoration(color: const Color(0xFFE8E0D0), borderRadius: BorderRadius.circular(1))),
              const SizedBox(height: 3),
              Container(width: 18, height: 2, decoration: BoxDecoration(color: const Color(0xFFC9A84C), borderRadius: BorderRadius.circular(1))),
              const SizedBox(height: 3),
              Container(width: 18, height: 2, decoration: BoxDecoration(color: const Color(0xFF00D4FF), borderRadius: BorderRadius.circular(1))),
            ]),
          ),
        ),

        Positioned(
          top: MediaQuery.of(context).padding.top + 172, left: 16,
          child: _MapBtn(
            active: _vpPanelOpen,
            onTap: () => setState(() => _vpPanelOpen = !_vpPanelOpen),
            child: const Text('📍', style: TextStyle(fontSize: 16)),
          ),
        ),

        // ── Search Bar (open state) ──
        if (_searchOpen) Positioned(
          top: MediaQuery.of(context).padding.top + 76, left: 16, right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xE60F0F1E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x26FFFFFF)),
            ),
            child: Row(children: [
              Expanded(child: TextField(
                controller: _searchCtrl, autofocus: true,
                style: const TextStyle(color: Color(0xFFE8E0D0), fontSize: 13),
                decoration: InputDecoration(
                  hintText: '🔍 場所を検索...',
                  hintStyle: const TextStyle(color: Color(0xFF555555)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onSubmitted: _doSearch,
              )),
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

        // ── Zoom Buttons (right side) ──
        Positioned(
          top: MediaQuery.of(context).padding.top + 76, right: 16,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _MapBtn(
              onTap: () => _mapCtrl.move(_mapCtrl.camera.center, _mapCtrl.camera.zoom + 1),
              child: const Text('+', style: TextStyle(fontSize: 18, color: Color(0x99C9A84C))),
            ),
            const SizedBox(height: 8),
            _MapBtn(
              onTap: () => _mapCtrl.move(_mapCtrl.camera.center, _mapCtrl.camera.zoom - 1),
              child: const Text('−', style: TextStyle(fontSize: 18, color: Color(0x99C9A84C))),
            ),
          ]),
        ),

        // ── Stella (right of buttons, minimizable) ──
        // HTML: .stella { opacity:0; transform:translateY(10px); transition:opacity .8s, transform .8s; }
        // .stella.vis { opacity:1; transform:translateY(0); }
        Positioned(
          top: MediaQuery.of(context).padding.top + 76, left: 64, right: 16,
          child: GestureDetector(
            onTap: () => setState(() => _stellaMinimized = !_stellaMinimized),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _stellaMinimized
                ? _buildStellaMinimized()
                : _buildStella(),
            ),
          ),
        ),

        // ── Seed Badge ──
        if (_preseedState == 'hidden') Positioned(
          top: MediaQuery.of(context).padding.top + 6, right: 20,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x26C9A84C),
              border: Border.all(color: const Color(0x66C9A84C)),
            ),
            child: const Center(child: Text('🌱', style: TextStyle(fontSize: 16))),
          ),
        ),

        // ── Layer Panel (above Stella in z-order) ──
        if (_layerPanelOpen) Positioned(
          top: MediaQuery.of(context).padding.top + 76, left: 60,
          child: _buildLayerPanel(),
        ),

        // ── Viewpoint Panel (above Stella in z-order) ──
        if (_vpPanelOpen) Positioned(
          top: MediaQuery.of(context).padding.top + 172, left: 60,
          child: _buildVPPanel(),
        ),

        // ── Fortune Pull Tab ──
        if (!_fortuneSheetOpen) Positioned(
          bottom: 80, left: 0, right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () => setState(() => _fortuneSheetOpen = true),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 2),
                decoration: const BoxDecoration(
                  color: Color(0xCC0A0A19),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(
                    top: BorderSide(color: Color(0x33C9A84C)),
                    left: BorderSide(color: Color(0x33C9A84C)),
                    right: BorderSide(color: Color(0x33C9A84C)),
                  ),
                ),
                child: const Text('▲ 運勢方位',
                  style: TextStyle(fontSize: 10, color: Color(0xFF888888), letterSpacing: 0.5)),
              ),
            ),
          ),
        ),

        // ── Fortune Sheet ──
        if (_fortuneSheetOpen) Positioned(
          bottom: 80, left: 0, right: 0,
          child: _buildFortuneSheet(),
        ),

        // ── Gray veil (pre-seed state) ──
        // HTML: .gray-veil { background:rgba(10,10,20,.25); transition:opacity .8s; }
        // .gray-veil.lifted { opacity:0; }
        if (_preseedState != 'hidden') Positioned.fill(
          child: GestureDetector(
            onTap: () {
              // HTML: dismissVeil() → preseed center→bottom, then hidden
              if (_preseedState == 'center') {
                setState(() => _preseedState = 'bottom');
              } else if (_preseedState == 'bottom') {
                setState(() => _preseedState = 'hidden');
              }
            },
            child: AnimatedOpacity(
              opacity: _preseedState == 'center' ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 800),
              child: Container(color: const Color(0x400A0A14)),
            ),
          ),
        ),

        // ── Preseed prompt (3 states: center → bottom → hidden) ──
        if (_preseedState == 'center') const Center(child: _Preseed()),
        if (_preseedState == 'bottom') Positioned(
          bottom: 12, left: 0, right: 0,
          child: AnimatedOpacity(
            opacity: 0.7,
            duration: const Duration(milliseconds: 600),
            child: Column(mainAxisSize: MainAxisSize.min, children: const [
              Text('🌱', style: TextStyle(fontSize: 20)),
              SizedBox(height: 6),
              Text('今日の方位を探索してみよう\n地図をタップして始めてね',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Color(0xFF555555), letterSpacing: 1, height: 1.5)),
            ]),
          ),
        ),

        // ── Search Result Popup ──
        if (_searchResultName != null) Positioned(
          bottom: 160, left: 16, right: 16,
          child: _buildSearchResult(),
        ),

        // ── Rest Overlay — "Stars are quiet" modal ──
        // HTML: .rest-overlay { z-index:800; display:flex; justify-content:center; align-items:center; }
        // .rest-inner { background:rgba(15,15,30,.85); border:1px solid rgba(201,168,76,.3);
        //   border-radius:16px; padding:20px 28px; animation:restIn .4s ease-out; }
        if (_restOverlayVisible) Positioned.fill(
          child: GestureDetector(
            onTap: () => setState(() => _restOverlayVisible = false),
            child: Container(
              color: Colors.transparent,
              child: Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                constraints: const BoxConstraints(maxWidth: 260),
                decoration: BoxDecoration(
                  color: const Color(0xD90F0F1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x4DC9A84C)),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🌙', style: TextStyle(fontSize: 28)),
                  const SizedBox(height: 8),
                  Text(_restOverlayText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xFFC9A84C), height: 1.7)),
                ]),
              )),
            ),
          ),
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
  // HTML: .ff-label { position:absolute; top:52px; left:16px; z-index:105;
  //   display:inline-flex; align-items:center; gap:6px;
  //   font-size:10px; color:#C9A84C; background:rgba(10,10,20,.7);
  //   padding:3px 10px; border-radius:10px; border:1px solid rgba(201,168,76,.3); }
  // Screenshot: label left + 2 rows of direction bars right
  Widget _buildFortuneFilterLabel() {
    final sorted = _sectorScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.isEmpty) return const SizedBox();

    final srcLabels = {'combined':'合計','transit':'トランジット','progressed':'プログレス'};
    final catLabels = {'all':'総合','healing':'癒し','money':'金運','love':'恋愛','work':'仕事','communication':'話す'};
    final top2 = sorted.where((e) => e.value > 0.01).take(2).toList();
    final maxScore = top2.isNotEmpty ? top2.first.value : 1.0;
    final catColor = _categoryColors[_activeCategory] ?? const Color(0xFFC9A84C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xB30A0A14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x4DC9A84C)),
      ),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: label
            Text(
              '${srcLabels[_activeSrc] ?? '合計'} / ${catLabels[_activeCategory] ?? '総合'}',
              style: const TextStyle(fontSize: 10, color: Color(0xFFC9A84C), letterSpacing: 0.5, fontWeight: FontWeight.w600),
            ),
            if (top2.isNotEmpty) ...[
              const SizedBox(height: 4),
              // Rows: direction bars
              ...top2.map((e) {
                final pct = (e.value / maxScore).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    // dir name
                    SizedBox(width: 36, child: Text(
                      _dir16JP[e.key] ?? e.key,
                      style: const TextStyle(fontSize: 10, color: Color(0xFFE8E0D0), fontWeight: FontWeight.w500),
                      textAlign: TextAlign.right,
                    )),
                    const SizedBox(width: 6),
                    // bar
                    SizedBox(
                      width: 120, height: 6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0x15FFFFFF),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: pct,
                          child: Container(
                            decoration: BoxDecoration(
                              color: catColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // score
                    SizedBox(width: 36, child: Text(
                      e.value.toStringAsFixed(2),
                      style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFFF6BD60), fontWeight: FontWeight.w600),
                      textAlign: TextAlign.right,
                    )),
                  ]),
                );
              }),
            ],
          ],
        ),
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
      width: 110,
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
          Flexible(child: Text(label, style: TextStyle(fontSize: 11, color: on ? const Color(0xFFBBBBBB) : const Color(0xFF666666)), overflow: TextOverflow.ellipsis)),
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
          Flexible(child: Text(label, style: TextStyle(fontSize: 11, color: on ? const Color(0xFFBBBBBB) : const Color(0xFF666666)), overflow: TextOverflow.ellipsis)),
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
          // HTML: .fs-handle { width:36px; height:4px; background:rgba(255,255,255,.25);
          //   border-radius:2px; margin:10px auto 6px; cursor:grab; }
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

          // HTML: .fs-tabs.fs-src { padding:0 8px; border-bottom:1px solid rgba(255,255,255,.08); }
          _buildSrcTabs(),

          // HTML: .fs-legend { display:flex; gap:10px; padding:4px 12px; font-size:9px; color:#888; }
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

          // HTML: .fs-tabs.fs-cat { padding:0 8px; border-bottom:1px solid rgba(255,255,255,.06); }
          // .fs-cat .fs-tab { font-size:10px; padding:6px 10px; }
          _buildCatTabs(),

          // HTML: .fs-body { height:185px; min-height:185px; max-height:185px;
          //   overflow-y:auto; padding:10px 14px 14px; scrollbar-width:thin; }
          SizedBox(
            height: 185,
            child: RawScrollbar(
              thumbColor: const Color(0x40C9A84C), // visible gold scrollbar
              radius: const Radius.circular(2),
              thickness: 3,
              thumbVisibility: true,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                children: _buildFortuneRows(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // HTML: .fs-tabs { display:flex; gap:0; padding:0 8px; border-bottom:1px solid rgba(255,255,255,.06); }
  // .fs-tab { padding:8px 12px; font-size:11px; color:#666; border-bottom:2px solid transparent; }
  // .fs-tab.active { color:#C9A84C; border-bottom-color:#C9A84C; }
  // HTML: .fs-tabs { display:flex; gap:0; padding:0 8px; border-bottom:1px solid rgba(255,255,255,.06); }
  // .fs-src { border-bottom:1px solid rgba(255,255,255,.08); }
  // .fs-tab { flex:0 0 auto; padding:8px 12px; font-size:11px; color:#666;
  //   border-bottom:2px solid transparent; white-space:nowrap; }
  // .fs-tab.active { color:#C9A84C; border-bottom-color:#C9A84C; }
  Widget _buildSrcTabs() {
    const srcs = [('combined', '合計'), ('transit', 'トランジット'), ('progressed', 'プログレス')];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8), // HTML: padding:0 8px
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x14FFFFFF))), // rgba(255,255,255,.08)
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

  // HTML: .fs-tabs { padding:0 8px; border-bottom:1px solid rgba(255,255,255,.06); }
  // .fs-cat .fs-tab { font-size:10px; padding:6px 10px; }
  Widget _buildCatTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8), // HTML: padding:0 8px
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0FFFFFFF))), // rgba(255,255,255,.06)
      ),
      child: SingleChildScrollView(
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
      ),
    );
  }

  // HTML: .fs-row { display:flex; align-items:center; padding:7px 4px; border-bottom:1px solid rgba(255,255,255,.04); }
  // .fs-dir { width:36px; font-size:12px; font-weight:600; color:#B49774; }
  // .fs-bar-wrap { flex:1; height:14px; background:rgba(255,255,255,.04); border-radius:7px; margin:0 10px; position:relative; }
  // .fs-tick { position:absolute; width:1px; background:rgba(255,255,255,.13); }
  // .fs-stack { height:100%; display:flex; border-radius:7px; }
  // .fs-seg { height:100%; } — colors: tSoft=#C9A84C, tHard=#6B5CE7, pSoft=#4CB8B0, pHard=#E74C6B
  // .fs-score { width:48px; font-size:11px; font-family:monospace; color:#F6BD60; }
  // .fs-badge { font-size:10px; margin-left:4px; width:20px; }
  List<Widget> _buildFortuneRows() {
    // Determine which comp keys to use based on source tab
    final ck = _activeSrc == 'transit' ? ['tSoft', 'tHard']
             : _activeSrc == 'progressed' ? ['pSoft', 'pHard']
             : _compKeys;

    // Compute totals per direction
    final dt = <String, double>{};
    for (final d in _dir16) {
      final c = _sectorComps[d] ?? {};
      double t = 0;
      for (final k in ck) { t += (c[k] ?? 0); }
      dt[d] = t;
    }

    final sorted = _dir16.toList()..sort((a, b) => (dt[b] ?? 0).compareTo(dt[a] ?? 0));

    final visible = sorted.where((d) => (dt[d] ?? 0) > 0.01).toList();
    return List.generate(visible.length, (i) {
      final dir = visible[i];
      final total = dt[dir]!;
      final pct = (_pct(total) / 100).clamp(0.0, 1.0);
      final comp = _sectorComps[dir] ?? {};
      final isLast = i == visible.length - 1;

      // Build segments
      final segs = <Widget>[];
      for (final k in ck) {
        final v = comp[k] ?? 0;
        if (v < 0.001) continue;
        segs.add(Expanded(
          flex: (v * 1000).round(),
          child: Container(color: _compColors[k]),
        ));
      }

      return Container(
        // HTML: .fs-row { padding:7px 4px; border-bottom:1px solid rgba(255,255,255,.04); }
        // .fs-row:last-child { border-bottom:none; }
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: Color(0x0AFFFFFF))),
        ),
        child: Row(children: [
          // HTML: .fs-dir { width:36px; font-size:12px; font-weight:600; color:#B49774; }
          SizedBox(width: 36, child: Text(_dir16JP[dir] ?? dir,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFB49774)))),
          // HTML: .fs-bar-wrap { flex:1; height:14px; background:rgba(255,255,255,.04);
          //   border-radius:7px; overflow:hidden; margin:0 10px; position:relative; }
          Expanded(
            child: Container(
              height: 14, margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0x0AFFFFFF),
                borderRadius: BorderRadius.circular(7),
              ),
              child: LayoutBuilder(builder: (ctx, constraints) {
                final barW = constraints.maxWidth;
                return Stack(children: [
                  // HTML: .fs-tick { position:absolute; width:1px; background:rgba(255,255,255,.13); }
                  // 5 ticks at 1/6, 2/6, 3/6, 4/6, 5/6
                  for (int t = 1; t <= 5; t++)
                    Positioned(
                      left: barW * t / 6, top: 0, bottom: 0,
                      child: Container(width: 1, color: const Color(0x21FFFFFF)),
                    ),
                  // HTML: .fs-stack { height:100%; display:flex; border-radius:7px; min-width:2px; }
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: pct,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Row(children: segs.isNotEmpty ? segs : [Expanded(child: Container())]),
                    ),
                  ),
                ]);
              }),
            ),
          ),
          // HTML: .fs-score { width:48px; text-align:right; font-size:11px; font-family:monospace; color:#F6BD60; }
          SizedBox(width: 48, child: Text(total.toStringAsFixed(2),
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFFF6BD60)),
            textAlign: TextAlign.right)),
        ]),
      );
    });
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xBF0F0F1E), // rgba(15,15,30,.75)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const Text('✨ Stella', style: TextStyle(
            fontSize: 9, letterSpacing: 2, color: Color(0xFF6B5CE7))),
          const Spacer(),
          // Minimize button
          Text('▼', style: TextStyle(fontSize: 8, color: const Color(0xFF555555))),
        ]),
        const SizedBox(height: 4),
        RichText(text: const TextSpan(
          style: TextStyle(fontSize: 11, color: Color(0xFFEAEAEA), height: 1.5),
          children: [
            TextSpan(text: '『再会の喜び』', style: TextStyle(color: Color(0xFFC9A84C), fontWeight: FontWeight.w600)),
            TextSpan(text: 'が今日の種。北東の風が、懐かしい誰かとの縁を運んでくるよ。'),
          ],
        )),
      ]),
    );
  }

  Widget _buildStellaMinimized() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xBF0F0F1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Text('✨ Stella', style: TextStyle(fontSize: 9, letterSpacing: 1, color: Color(0xFF6B5CE7))),
        SizedBox(width: 6),
        Text('▲', style: TextStyle(fontSize: 8, color: Color(0xFF555555))),
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

class _Preseed extends StatefulWidget {
  const _Preseed();
  @override
  State<_Preseed> createState() => _PreseedState();
}

class _PreseedState extends State<_Preseed> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();
    // HTML: animation: float 3s ease-in-out infinite
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _float = Tween<double>(begin: 0, end: -8).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (_, child) => Transform.translate(offset: Offset(0, _float.value), child: child),
      child: Column(mainAxisSize: MainAxisSize.min, children: const [
        Opacity(opacity: 0.6, child: Text('🌱', style: TextStyle(fontSize: 32))),
        SizedBox(height: 16),
        Text('今日の方位を探索してみよう\n地図をタップして始めてね',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFF555555), letterSpacing: 1, height: 1.8)),
      ]),
    );
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
