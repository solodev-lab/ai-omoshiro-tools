import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../utils/solara_storage.dart';
import 'map/map_constants.dart';
import 'map/map_sectors.dart';
import 'map/map_fortune_sheet.dart';
import 'map/map_stella.dart';
import 'map/map_vp_panel.dart';
import 'map/map_layer_panel.dart';
import 'map/map_widgets.dart';
import 'map/map_astro.dart';
import 'map/map_planet_lines.dart';

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
  String _vpTab = 'vp';
  String _preseedState = 'hidden';
  bool _stellaMinimized = false;
  bool _restOverlayVisible = false;
  final String _restOverlayText = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // Layer visibility
  final Map<String, bool> _layers = {
    'sectors': true, 'compass': true, 'transit': true,
    'natal': false, 'progressed': false,
  };

  // Fortune category / source
  String _activeCategory = 'all';
  String _activeSrc = 'combined';

  // Planet group visibility
  final Map<String, bool> _planetGroups = {
    'personal': true, 'social': false, 'generational': false,
  };

  // Sector scores
  final Map<String, double> _sectorScores = {};
  final Map<String, Map<String, double>> _sectorComps = {};

  ChartResult? _chartResult;
  List<PlanetLineData> _planetLines = [];
  SolaraProfile? _profile;

  // Search result
  String? _searchResultName;
  LatLng? _searchResultPos;

  @override
  void initState() {
    super.initState();
    _loadProfileAndChart();
    // モックスコアをフォールバックとして初期化
    _sectorScores.addAll(generateMockScores(_sectorComps));
  }

  Future<void> _loadProfileAndChart() async {
    final p = await SolaraStorage.loadProfile();
    if (p == null || !p.isComplete) return;
    _profile = p;
    setState(() => _center = LatLng(p.birthLat, p.birthLng));

    // CF Worker API で天体データを取得 → scoreAll で16方位スコア計算
    final chart = await fetchChart(
      birthDate: p.birthDate,
      birthTime: p.birthTime,
      birthLat: p.birthLat,
      birthLng: p.birthLng,
      birthTz: p.birthTz,
      birthTzName: p.birthTzName,
    );
    if (chart != null) {
      _chartResult = chart;
      final result = scoreAll(chart);
      final lines = buildPlanetLineData(center: _center, chart: chart);
      setState(() {
        _sectorScores
          ..clear()
          ..addAll(result.sScores);
        _sectorComps
          ..clear()
          ..addAll(result.sComp);
        _planetLines = lines;
      });
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
          _mapCtrl.move(LatLng(lat, lng), 15);
          setState(() {
            _searchOpen = false;
            _searchResultName = data[0]['display_name'] as String?;
            _searchResultPos = LatLng(lat, lng);
          });
        }
      }
    } catch (_) {}
  }

  Color get _sectorColor => categoryColors[_activeCategory] ?? const Color(0xFFC9A84C);

  /// HTML: rebuild(nc, fly) — center変更 + flyTo + セクター再計算 + 天体ライン再構築
  void _rebuild(LatLng newCenter) {
    _mapCtrl.move(newCenter, _mapCtrl.camera.zoom.clamp(12, 18).toDouble());
    setState(() {
      _center = newCenter;
      // 天体ラインは中心点から描画するので再構築
      if (_chartResult != null) {
        _planetLines = buildPlanetLineData(center: newCenter, chart: _chartResult!);
      }
    });
  }

  /// HTML: vpGeo() — GPS現在地に移動（geolocatorパッケージ未導入のため仮実装）
  void _geolocate() {
    // TODO: geolocator パッケージ追加後に実装
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GPS機能は今後実装予定です'), duration: Duration(seconds: 2)),
    );
  }

  // ══════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // ── Map ──
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: _center, initialZoom: 14,
            minZoom: 2, maxZoom: 18,
            backgroundColor: const Color(0xFF080C14),
            // HTML: long-press 600ms → rebuild(nc, fly:true)
            onLongPress: (tapPos, latlng) => _rebuild(latlng),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              maxZoom: 19,
              tileBuilder: (context, tileWidget, tile) => ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
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
            PolygonLayer(polygons: buildSectors(
              center: _center,
              sectorScores: _sectorScores,
              sectorColor: _sectorColor,
              visible: _layers['sectors']!,
            )),
            PolylineLayer(polylines: buildCompass(center: _center, visible: _layers['compass']!)),
            // HTML: addPlanetLines() — natal/progressed/transit 天体ライン
            if (_planetLines.isNotEmpty) PolylineLayer(polylines: buildPlanetPolylines(
              lines: _planetLines, layers: _layers,
              planetGroupVis: _planetGroups, activeCategory: _activeCategory,
            )),
            if (_planetLines.isNotEmpty) MarkerLayer(markers: buildPlanetSymbols(
              lines: _planetLines, layers: _layers,
              planetGroupVis: _planetGroups, activeCategory: _activeCategory,
            )),
            MarkerLayer(markers: buildDirLabels(center: _center)),
            // HTML: searchMarker — circleMarker(radius:8, color:#fff, fillColor:GOLD, fillOpacity:.9, weight:2)
            if (_searchResultPos != null) CircleLayer(circles: [
              CircleMarker(
                point: _searchResultPos!,
                radius: 8,
                color: const Color(0xE6C9A84C), // GOLD fillOpacity:.9
                borderColor: const Color(0xFFFFFFFF), // color:#fff
                borderStrokeWidth: 2,
              ),
            ]),
            // VP Pin — HTML: draggable gold circle, dragend → rebuild
            MarkerLayer(markers: [
              Marker(point: _center, width: 20, height: 20, child: GestureDetector(
                onPanUpdate: (d) {
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
                onPanEnd: (_) {
                  // HTML: vpPin.on('dragend') → rebuild — スコアはAPIベースなので再計算不要、UI更新のみ
                  setState(() {});
                },
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(-0.2, -0.3),
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

        // ── FF Label ──
        Positioned(
          top: topPad + 2, left: 16,
          child: FortuneFilterLabel(
            sectorScores: _sectorScores,
            activeSrc: _activeSrc,
            activeCategory: _activeCategory,
          ),
        ),

        // ── Buttons (search, layer, vp) ──
        if (!_searchOpen) Positioned(
          top: topPad + 76, left: 16,
          child: MapBtn(
            child: const Icon(Icons.search, size: 18, color: Color(0x99C9A84C)),
            onTap: () => setState(() => _searchOpen = true),
          ),
        ),
        Positioned(
          top: topPad + 124, left: 16,
          child: MapBtn(
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
          top: topPad + 172, left: 16,
          child: MapBtn(
            active: _vpPanelOpen,
            onTap: () => setState(() => _vpPanelOpen = !_vpPanelOpen),
            child: const Text('📍', style: TextStyle(fontSize: 16)),
          ),
        ),

        // ── Search Bar ──
        if (_searchOpen) Positioned(
          top: topPad + 76, left: 16, right: 16,
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
                decoration: const InputDecoration(
                  hintText: '🔍 場所を検索...',
                  hintStyle: TextStyle(color: Color(0xFF555555)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

        // ── Stella ──
        Positioned(
          bottom: 90, left: 20, right: 20,
          child: GestureDetector(
            onTap: () => setState(() => _stellaMinimized = !_stellaMinimized),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _stellaMinimized
                ? const StellaMinimized()
                : const Stella(),
            ),
          ),
        ),

        // ── Seed Badge ──
        if (_preseedState == 'hidden') Positioned(
          top: topPad + 6, right: 20,
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

        // ── 外側タップでパネルを閉じる（HTML: pointerdown outside → close）──
        if (_layerPanelOpen || _vpPanelOpen) Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => setState(() { _layerPanelOpen = false; _vpPanelOpen = false; }),
            child: const SizedBox.expand(),
          ),
        ),

        // ── Layer Panel ──
        if (_layerPanelOpen) Positioned(
          top: topPad + 76, left: 60,
          child: LayerPanel(
            layers: _layers,
            planetGroups: _planetGroups,
            activeCategory: _activeCategory,
            onLayerToggle: (k) => setState(() => _layers[k] = !(_layers[k] ?? false)),
            onPlanetGroupToggle: (k) => setState(() => _planetGroups[k] = !(_planetGroups[k] ?? false)),
            onCategoryChanged: (k) => setState(() => _activeCategory = k),
          ),
        ),

        // ── VP Panel ──
        if (_vpPanelOpen) Positioned(
          top: topPad + 172, left: 60,
          child: VPPanel(
            activeTab: _vpTab,
            onTabChanged: (t) => setState(() => _vpTab = t),
            center: _center,
            profile: _profile,
            onSlotSelected: (slot) {
              // HTML: onSelect → rebuild + close panel
              _rebuild(LatLng(slot.lat, slot.lng));
              setState(() => _vpPanelOpen = false);
            },
            onGeolocate: _geolocate,
          ),
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
          child: FortuneSheet(
            activeSrc: _activeSrc,
            activeCategory: _activeCategory,
            sectorComps: _sectorComps,
            onSrcChanged: (s) => setState(() => _activeSrc = s),
            onCatChanged: (c) => setState(() => _activeCategory = c),
            onClose: () => setState(() => _fortuneSheetOpen = false),
          ),
        ),

        // ── Gray veil (pre-seed state) ──
        if (_preseedState != 'hidden') Positioned.fill(
          child: GestureDetector(
            onTap: () {
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

        // ── Preseed ──
        if (_preseedState == 'center') const Center(child: Preseed()),
        if (_preseedState == 'bottom') Positioned(
          bottom: 12, left: 0, right: 0,
          child: AnimatedOpacity(
            opacity: 0.7,
            duration: const Duration(milliseconds: 600),
            child: const Column(mainAxisSize: MainAxisSize.min, children: [
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

        // ── Rest Overlay ──
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
  // Search Result Popup
  // ══════════════════════════════════════════════
  Widget _buildSearchResult() {
    final name = _searchResultName ?? '';
    final parts = name.split(',');
    final short = parts.length > 2 ? '${parts[0]}, ${parts[1]}' : name;
    // Find score for this location (placeholder)
    final sorted = _sectorScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final bestDir = sorted.isNotEmpty ? sorted.first.key : 'N';
    final bestScore = sorted.isNotEmpty ? sorted.first.value : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xF20F0F1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const Text('📍', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(child: Text(short,
            style: const TextStyle(fontSize: 13, color: Color(0xFFE8E0D0), fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
          GestureDetector(
            onTap: () => setState(() { _searchResultName = null; _searchResultPos = null; }),
            child: const Text('✕', style: TextStyle(color: Color(0xFF555555), fontSize: 14)),
          ),
        ]),
        const SizedBox(height: 8),
        // SR Tabs
        DefaultTabController(
          length: 3,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const TabBar(
              isScrollable: true,
              labelColor: Color(0xFFF6BD60),
              unselectedLabelColor: Color(0xFF666666),
              indicatorColor: Color(0xFFF6BD60),
              labelStyle: TextStyle(fontSize: 11),
              tabs: [
                Tab(text: '✦ 総合'),
                Tab(text: '🌿 癒し'),
                Tab(text: '💰 金運'),
              ],
            ),
            SizedBox(
              height: 80,
              child: TabBarView(children: [
                _srContent('この地点は${dir16JP[bestDir]}方面。\n運勢スコア: ${bestScore.toStringAsFixed(2)}'),
                _srContent('癒しのエネルギーが流れている場所です。'),
                _srContent('金運に関連するエネルギーが感じられます。'),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _srContent(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(text,
        style: const TextStyle(fontSize: 12, color: Color(0xFFCCCCCC), height: 1.6)),
    );
  }
}
