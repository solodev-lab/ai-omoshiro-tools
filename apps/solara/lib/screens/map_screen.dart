import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/solara_storage.dart';
import '../utils/omen_phrases.dart';
import '../widgets/dominant_fortune_overlay.dart';
import '../widgets/omen_button.dart';
import 'map/map_constants.dart';
import 'map/map_styles.dart';
import 'map/map_sectors.dart';
import 'map/map_fortune_sheet.dart';
import 'map/map_stella.dart';
import 'map/map_vp_panel.dart';
import 'map/map_layer_panel.dart';
import 'map/map_widgets.dart';
import 'map/map_astro.dart';
import 'map/map_planet_lines.dart';
import 'map/map_search.dart';
import 'forecast_screen.dart';
import 'locations_screen.dart';

/// 開発用フラグ: true なら日付チェックをバイパスして毎回オーバーレイを表示する。
/// 本番では false。
const bool _debugAlwaysShowOverlay = false;

/// 開発用: true ならタップ毎に _debugCycleOrder の順番で演出を切り替える。
/// 本番では false、実際のトップカテゴリで表示。
const bool _debugCycleOverlayKinds = false;

/// デバッグ循環順: 5種を通しで確認できるようにする
const _debugCycleOrder = <DominantFortuneKind>[
  DominantFortuneKind.love,
  DominantFortuneKind.money,
  DominantFortuneKind.healing,
  DominantFortuneKind.communication,
  DominantFortuneKind.work,
];

/// 実装済みのカテゴリ（5種全て）
const _implementedOverlayKinds = <DominantFortuneKind>{
  DominantFortuneKind.love,
  DominantFortuneKind.money,
  DominantFortuneKind.healing,
  DominantFortuneKind.communication,
  DominantFortuneKind.work,
};

const _overlayStorageKey = 'dominant_fortune';

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
  // _sectorComps: 総合（all）用の per-direction components {tSoft, tHard, pSoft, pHard}
  // _fComps: カテゴリ別の per-direction components  _fComps[cat][dir] = {tSoft,...}
  final Map<String, double> _sectorScores = {};
  final Map<String, Map<String, double>> _sectorComps = {};
  final Map<String, Map<String, Map<String, double>>> _fComps = {};
  ScoreResult? _scoreResult;

  ChartResult? _chartResult;
  List<PlanetLineData> _planetLines = [];
  SolaraProfile? _profile;

  // 日付選択（null = 今日）。UTC 扱い。
  DateTime? _selectedDate;
  bool _loadingChart = false;

  /// 初回ロードで _center を出生地に揃える用のフラグ。
  /// 2回目以降の _loadProfileAndChart 呼び出し（日付変更・Forecastジャンプ等）では
  /// ユーザーが選んだ VP / 手動中心を保持する。
  bool _hasInitialCenter = false;

  // Dominant fortune overlay
  DominantFortuneKind? _topCategory;
  DominantFortuneKind? _activeOverlay;
  int _debugCycleIdx = 0;

  // Daily Omen button
  bool _omenVisible = false;
  OmenPhrase _omenPhrase = pickRandomOmenPhrase();

  // Search results
  List<SearchHit> _searchHits = [];
  SearchHit? _searchFocus; // 選択済み1件（ピン表示用）
  bool _searching = false;

  // Map style (tile source + light/dark filter)
  MapStyle _mapStyle = MapStyle.osmHotLight;

  @override
  void initState() {
    super.initState();
    _loadProfileAndChart();
    _loadMapStyle();
    // モックスコアをフォールバックとして初期化
    _sectorScores.addAll(generateMockScores(_sectorComps));
    _checkOmenVisibility();
  }

  /// 「今日のタップボタン」表示判定。
  /// ホロスコープ最高カテゴリが算出されていて、かつリセット時刻考慮の
  /// 「今日」で未表示なら出す。（デバッグフラグ ON 時は常に表示）
  Future<void> _checkOmenVisibility() async {
    bool visible;
    if (_debugAlwaysShowOverlay) {
      visible = true;
    } else {
      if (_topCategory == null ||
          !_implementedOverlayKinds.contains(_topCategory)) {
        visible = false;
      } else {
        final shown = await SolaraStorage.wasOverlayShownToday(_overlayStorageKey);
        visible = !shown;
      }
    }
    if (!mounted) return;
    setState(() {
      _omenVisible = visible;
      _omenPhrase = pickRandomOmenPhrase();
    });
  }

  Future<void> _loadMapStyle() async {
    final id = await SolaraStorage.loadMapStyleId();
    if (!mounted) return;
    setState(() => _mapStyle = mapStyleFromId(id));
  }

  void _onMapStyleChanged(MapStyle style) {
    setState(() => _mapStyle = style);
    SolaraStorage.saveMapStyleId(mapStyleConfigs[style]!.id);
  }

  Future<void> _loadProfileAndChart({DateTime? targetDate}) async {
    final p = await SolaraStorage.loadProfile();
    if (p == null || !p.isComplete) return;
    _profile = p;
    if (mounted) {
      setState(() {
        // 初回のみ _center を出生地に設定。日付変更等の再計算では
        // ユーザーが選んだ VP / 手動中心を保持する。
        if (!_hasInitialCenter) {
          _center = LatLng(p.birthLat, p.birthLng);
          _hasInitialCenter = true;
          // FlutterMap 初期化後にカメラを出生地へ移動
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              try {
                _mapCtrl.move(_center, _mapCtrl.camera.zoom);
              } catch (_) {
                // MapController が未接続の場合は無視（次回 rebuild で追従）
              }
            }
          });
        }
        _loadingChart = true;
      });
    }

    // CF Worker API で天体データを取得 → scoreAll で16方位スコア計算
    final chart = await fetchChart(
      birthDate: p.birthDate,
      birthTime: p.birthTime,
      birthLat: p.birthLat,
      birthLng: p.birthLng,
      birthTz: p.birthTz,
      birthTzName: p.birthTzName,
      targetDate: targetDate,
    );
    if (chart != null) {
      _chartResult = chart;
      final result = scoreAll(chart);
      final lines = buildPlanetLineData(center: _center, chart: chart);
      // 16方位合計の最高カテゴリを今日のドミナントとする
      String? topKey;
      double topSum = -1;
      for (final entry in result.fScores.entries) {
        final sum = entry.value.values.fold<double>(0, (a, b) => a + b);
        if (sum > topSum) {
          topSum = sum;
          topKey = entry.key;
        }
      }
      setState(() {
        _sectorScores
          ..clear()
          ..addAll(result.sScores);
        _sectorComps
          ..clear()
          ..addAll(result.sComp);
        _fComps
          ..clear()
          ..addAll(result.fComp);
        _scoreResult = result;
        _planetLines = lines;
        _topCategory = topKey != null ? kindFromKey(topKey) : null;
        _loadingChart = false;
      });
      // トップカテゴリが確定したので Omen ボタンの表示判定を再評価
      await _checkOmenVisibility();
      // 検索結果が残っていれば、新しい日付のスコアで再注入
      _reannotateSearchResults();
    } else {
      if (mounted) setState(() => _loadingChart = false);
    }
  }

  /// 既存の検索結果（リスト + フォーカス1件）に、現在の中心・日付・カテゴリ・ソース
  /// で算出したスコアを再注入する。日付ピッカー・VP切替・カテゴリ切替から呼ぶ。
  void _reannotateSearchResults() {
    final hasHits = _searchHits.isNotEmpty;
    final hasFocus = _searchFocus != null;
    if (!hasHits && !hasFocus) return;
    final scores = _displayScores();
    if (hasHits) {
      annotateHitsWithScores(
        hits: _searchHits,
        center: _center,
        sectorScores: scores,
        scoreResult: _scoreResult,
      );
    }
    if (hasFocus) {
      annotateHitsWithScores(
        hits: [_searchFocus!],
        center: _center,
        sectorScores: scores,
        scoreResult: _scoreResult,
      );
    }
    if (mounted) setState(() {});
  }

  /// 日付ピッカー表示。選択されたら該当日の transit/progressed で再計算する。
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _selectedDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: DateTime(now.year + 2, now.month, now.day),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFC9A84C),
            onPrimary: Color(0xFF0F0F1E),
            surface: Color(0xFF0F0F1E),
            onSurface: Color(0xFFE8E0D0),
          ),
          dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF0F0F1E)),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    // 正午固定（house 位置の揺れを抑える意図で日中の代表時刻を選ぶ）
    final noon = DateTime.utc(picked.year, picked.month, picked.day, 3, 0, 0);
    setState(() => _selectedDate = noon);
    await _loadProfileAndChart(targetDate: noon);
  }

  /// 日付リセット（「今日」に戻す）
  Future<void> _resetDateToToday() async {
    setState(() => _selectedDate = null);
    await _loadProfileAndChart();
  }

  Future<void> _openLocations() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xB3000000),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.9,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: LocationsScreen(
            center: _center,
            scoreResult: _scoreResult,
            sectorScores: _displayScores(),
            profile: _profile,
            onSelectSlot: (slot) {
              _rebuild(LatLng(slot.lat, slot.lng));
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openForecast() async {
    // 現在の中心が出生地/ホームと一致するか判定し、ラベルと座標文字列を決定する
    String? baseLabel;
    String? baseDetail;
    final p = _profile;
    if (p != null) {
      // Home と一致する場合は Home 表示、それ以外は "現在地点"
      final isHome = p.homeName.isNotEmpty &&
          (p.homeLat - _center.latitude).abs() < 0.001 &&
          (p.homeLng - _center.longitude).abs() < 0.001;
      final isBirth = p.birthPlace.isNotEmpty &&
          (p.birthLat - _center.latitude).abs() < 0.001 &&
          (p.birthLng - _center.longitude).abs() < 0.001;
      if (isHome) {
        baseLabel = p.homeName;
      } else if (isBirth) {
        baseLabel = p.birthPlace;
      } else {
        baseLabel = '現在のビューポイント';
      }
      baseDetail = '${_center.latitude.toStringAsFixed(4)}, ${_center.longitude.toStringAsFixed(4)}';
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xB3000000),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.92,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: ForecastScreen(
            baseLabel: baseLabel,
            baseDetail: baseDetail,
            onJumpToDate: (date) {
              setState(() => _selectedDate = date);
              _loadProfileAndChart(targetDate: date);
            },
          ),
        ),
      ),
    );
  }

  String _formatSelectedDate() {
    final d = _selectedDate;
    if (d == null) return '今日';
    // UTC → JST 表示（正午固定なので日付だけで十分）
    final jst = d.toLocal();
    return '${jst.year}/${jst.month.toString().padLeft(2, '0')}/${jst.day.toString().padLeft(2, '0')}';
  }

  /// 今日のタップボタン押下時のハンドラ。
  /// ホロスコープから得た最高スコアカテゴリの演出を起動する。
  Future<void> _onOmenTap() async {
    if (_activeOverlay != null) return;

    DominantFortuneKind? kind;
    if (_debugAlwaysShowOverlay && _debugCycleOverlayKinds) {
      kind = _debugCycleOrder[_debugCycleIdx];
      _debugCycleIdx = (_debugCycleIdx + 1) % _debugCycleOrder.length;
    } else {
      kind = _topCategory;
      if (_debugAlwaysShowOverlay && (kind == null || !_implementedOverlayKinds.contains(kind))) {
        kind = DominantFortuneKind.love;
      }
      if (kind == null) return;
      if (!_implementedOverlayKinds.contains(kind)) return;
    }

    if (!mounted) return;
    setState(() {
      _activeOverlay = kind;
      _omenVisible = false;
    });
    if (!_debugAlwaysShowOverlay) {
      await SolaraStorage.markOverlayShown(_overlayStorageKey);
    }
  }

  /// Dominant Fortune Overlay 完了時の処理。
  /// 本番: ボタンは当日再表示しない（リセット時刻で自動的に復活）。
  /// デバッグ: フラグ ON 時のみ再表示＋フレーズ再抽選。
  void _onOverlayComplete() {
    if (!mounted) return;
    setState(() {
      _activeOverlay = null;
      if (_debugAlwaysShowOverlay) {
        _omenVisible = true;
        _omenPhrase = pickRandomOmenPhrase();
      }
    });
  }

  Future<void> _doSearch(String query) async {
    if (query.trim().length < 2) return;
    setState(() => _searching = true);
    final hits = await searchPlaces(query);
    annotateHitsWithScores(
      hits: hits,
      center: _center,
      sectorScores: _displayScores(),
      scoreResult: _scoreResult,
    );
    if (!mounted) return;
    setState(() {
      _searchHits = hits;
      _searching = false;
      _searchOpen = false;
    });
    if (hits.length == 1) {
      _selectSearchHit(hits.first);
    }
  }

  void _selectSearchHit(SearchHit hit) {
    final pos = LatLng(hit.lat, hit.lng);
    _mapCtrl.move(pos, 15);
    setState(() {
      _searchFocus = hit;
      _searchHits = []; // リスト閉じる
    });
  }

  Color get _sectorColor {
    final base = categoryColors[_activeCategory] ?? const Color(0xFFC9A84C);
    final isDark = mapStyleConfigs[_mapStyle]?.dark ?? true;
    if (isDark) return base;
    // 明るい地図（OSM Light/Cycle Light）はパステル色が埋もれるため、
    // 明度を下げ彩度を上げて視認性を確保する。
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness((hsl.lightness * 0.45).clamp(0.0, 0.55))
        .withSaturation((hsl.saturation * 1.2).clamp(0.0, 1.0))
        .toColor();
  }

  /// カテゴリ × ソース（transit/progressed/combined）に応じた
  /// 16方位スコアを算出する。セクター描画・FortuneFilterLabel 共通利用。
  /// _activeCategory == 'all' の場合は総合合算、それ以外はカテゴリ別 _fComps を使用。
  /// _activeSrc で transit/progressed/combined を切替。
  Map<String, double> _displayScores() {
    final comps = _activeCategory == 'all'
        ? _sectorComps
        : (_fComps[_activeCategory] ?? const <String, Map<String, double>>{});
    if (comps.isEmpty) return _sectorScores; // データ未取得時のフォールバック

    final keys = _activeSrc == 'transit'
        ? const ['tSoft', 'tHard']
        : _activeSrc == 'progressed'
            ? const ['pSoft', 'pHard']
            : compKeys;

    final result = <String, double>{};
    for (final d in dir16) {
      final c = comps[d] ?? const <String, double>{};
      double total = 0;
      for (final k in keys) {
        total += c[k] ?? 0;
      }
      result[d] = total;
    }
    return result;
  }

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
    // 中心が変われば検索結果の方位/距離/スコアも変わる
    _reannotateSearchResults();
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
            minZoom: 2, maxZoom: 19,
            backgroundColor: mapStyleConfigs[_mapStyle]!.backgroundColor,
            // HTML: long-press 600ms → rebuild(nc, fly:true)
            onLongPress: (tapPos, latlng) => _rebuild(latlng),
          ),
          children: [
            buildStyledTileLayer(_mapStyle),
            PolygonLayer(polygons: buildSectors(
              center: _center,
              sectorScores: _displayScores(),
              sectorColor: _sectorColor,
              visible: _layers['sectors']!,
              lightMap: !(mapStyleConfigs[_mapStyle]?.dark ?? true),
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
            if (_searchFocus != null) CircleLayer(circles: [
              CircleMarker(
                point: LatLng(_searchFocus!.lat, _searchFocus!.lng),
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
                  // 中心が動いたので検索結果の方位/距離/スコアを再注入
                  _reannotateSearchResults();
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
            sectorScores: _displayScores(),
            activeSrc: _activeSrc,
            activeCategory: _activeCategory,
          ),
        ),

        // ── 選択日バッジ（今日以外を選択中のみ表示） ──
        if (_selectedDate != null) Positioned(
          top: topPad + 44, left: 16,
          child: GestureDetector(
            onTap: _resetDateToToday,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xE60F0F1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x66C9A84C)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('📅', style: TextStyle(fontSize: 11)),
                const SizedBox(width: 6),
                Text(_formatSelectedDate(),
                    style: const TextStyle(fontSize: 11, color: Color(0xFFC9A84C), letterSpacing: 0.5)),
                const SizedBox(width: 6),
                const Text('✕', style: TextStyle(fontSize: 10, color: Color(0xFF888888))),
              ]),
            ),
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
        // Date picker button (📅)
        Positioned(
          top: topPad + 220, left: 16,
          child: MapBtn(
            active: _selectedDate != null,
            onTap: _pickDate,
            child: const Text('📅', style: TextStyle(fontSize: 14)),
          ),
        ),
        // Locations list button (🗺)
        Positioned(
          top: topPad + 268, left: 16,
          child: MapBtn(
            onTap: _openLocations,
            child: const Text('🗺', style: TextStyle(fontSize: 14)),
          ),
        ),
        // Forecast button (🔮)
        Positioned(
          top: topPad + 316, left: 16,
          child: MapBtn(
            onTap: _openForecast,
            child: const Text('🔮', style: TextStyle(fontSize: 14)),
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
            mapStyle: _mapStyle,
            onLayerToggle: (k) => setState(() => _layers[k] = !(_layers[k] ?? false)),
            onPlanetGroupToggle: (k) => setState(() => _planetGroups[k] = !(_planetGroups[k] ?? false)),
            onCategoryChanged: (k) {
              setState(() => _activeCategory = k);
              _reannotateSearchResults();
            },
            onMapStyleChanged: _onMapStyleChanged,
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
            // 'all' 時は総合 sComp、それ以外はカテゴリ別 fComp を渡す
            sectorComps: _activeCategory == 'all'
                ? _sectorComps
                : (_fComps[_activeCategory] ?? _sectorComps),
            onSrcChanged: (s) {
              setState(() => _activeSrc = s);
              _reannotateSearchResults();
            },
            onCatChanged: (c) {
              setState(() => _activeCategory = c);
              _reannotateSearchResults();
            },
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

        // ── Search Result List（複数候補） ──
        if (_searchHits.isNotEmpty) Positioned(
          bottom: 160, left: 16, right: 16,
          child: SearchResultList(
            hits: _searchHits,
            onTap: _selectSearchHit,
            onClose: () => setState(() => _searchHits = []),
          ),
        ),

        // ── Search Focus Popup（単一選択後） ──
        if (_searchFocus != null) Positioned(
          bottom: 160, left: 16, right: 16,
          child: _buildSearchFocusPopup(),
        ),

        // ── Searching spinner ──
        if (_searching) Positioned(
          top: topPad + 128, left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xE60F0F1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x33C9A84C)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: const [
              SizedBox(
                width: 10, height: 10,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFC9A84C)),
              ),
              SizedBox(width: 8),
              Text('検索中…', style: TextStyle(fontSize: 10, color: Color(0xFFC9A84C))),
            ]),
          ),
        ),

        // ── Daily Omen Button（今日のタップボタン）──
        if (_omenVisible && _activeOverlay == null) Positioned(
          left: 24, right: 24, bottom: 170,
          child: OmenButton(phrase: _omenPhrase, onTap: _onOmenTap),
        ),

        // ── Dominant Fortune Overlay ──
        if (_activeOverlay != null) Positioned.fill(
          child: DominantFortuneOverlay(
            key: ValueKey(_activeOverlay),
            kind: _activeOverlay!,
            onComplete: _onOverlayComplete,
          ),
        ),

        // ── Loading Indicator (date change) ──
        if (_loadingChart) Positioned(
          top: topPad + 44, right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xE60F0F1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x33C9A84C)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: const [
              SizedBox(
                width: 10, height: 10,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFC9A84C)),
              ),
              SizedBox(width: 8),
              Text('計算中…', style: TextStyle(fontSize: 10, color: Color(0xFFC9A84C))),
            ]),
          ),
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
  // Search Focus Popup（単一選択後）
  // ══════════════════════════════════════════════
  Widget _buildSearchFocusPopup() {
    final f = _searchFocus!;
    final parts = f.name.split(',');
    final short = parts.length > 2 ? '${parts[0]}, ${parts[1]}' : f.name;
    // 中心が動いたら方位を再計算（bestDir はキャッシュの可能性がある）
    final dir = f.directionFrom(_center);
    final dirJp = dir16JP[dir] ?? dir;
    final km = f.distanceKmFrom(_center);

    // この方位のカテゴリ別スコア — _displayScores と同じ src フィルタを適用して、
    // 日付変更・ソース切替に追随して値が動くようにする。
    final srcKeys = _activeSrc == 'transit'
        ? const ['tSoft', 'tHard']
        : _activeSrc == 'progressed'
            ? const ['pSoft', 'pHard']
            : compKeys;
    final catEntries = <MapEntry<String, double>>[];
    for (final cat in _fComps.keys) {
      final comps = _fComps[cat]?[dir];
      if (comps == null) continue;
      double sum = 0;
      for (final k in srcKeys) {
        sum += comps[k] ?? 0;
      }
      if (sum < 0.05) continue; // 0同然のカテゴリは省く
      catEntries.add(MapEntry(cat, sum));
    }
    catEntries.sort((a, b) => b.value.compareTo(a.value));
    final top3 = catEntries.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(14),
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
            onTap: () => setState(() => _searchFocus = null),
            child: const Text('✕', style: TextStyle(color: Color(0xFF555555), fontSize: 14)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Text('$dirJp方位',
              style: const TextStyle(fontSize: 11, color: Color(0xFFC9A84C), letterSpacing: 1)),
          const SizedBox(width: 10),
          Text('${km.toStringAsFixed(km < 100 ? 1 : 0)} km',
              style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
          const Spacer(),
          Text('総合 ${(f.bestScore).toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 10, color: Color(0xFFE8E0D0))),
        ]),
        const SizedBox(height: 8),
        if (top3.isNotEmpty) Wrap(
          spacing: 8, runSpacing: 4,
          children: [for (final e in top3) _catChip(e.key, e.value)],
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _actionTile('📌 拠点として登録', _saveFocusAsLocation)),
          const SizedBox(width: 6),
          Expanded(child: _actionTile('✈ ここへ移動', () {
            _rebuild(LatLng(f.lat, f.lng));
            setState(() => _searchFocus = null);
          })),
        ]),
      ]),
    );
  }

  Widget _catChip(String cat, double score) {
    final color = categoryColors[cat] ?? const Color(0xFFE8E0D0);
    final label = categoryLabels[cat] ?? cat;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(fontSize: 10, color: color)),
        const SizedBox(width: 4),
        Text(score.toStringAsFixed(1), style: const TextStyle(fontSize: 9, color: Color(0xFF999999))),
      ]),
    );
  }

  Widget _actionTile(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0x1FC9A84C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x66C9A84C)),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(fontSize: 10, color: Color(0xFFC9A84C), letterSpacing: 0.5)),
        ),
      ),
    );
  }

  Future<void> _saveFocusAsLocation() async {
    final f = _searchFocus;
    if (f == null) return;
    final mgr = SlotManager(storageKey: 'solara_locations', defaultNames: ['場所1','場所2','場所3','場所4']);
    final slots = await mgr.load();
    final homeCount = (slots.isNotEmpty && slots[0].isHome) ? 1 : 0;
    if (slots.length >= mgr.maxSlots) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存は${mgr.maxSlots - homeCount}件までです。'), duration: const Duration(seconds: 2)),
      );
      return;
    }
    final parts = f.name.split(',');
    final name = parts.isNotEmpty ? parts.first.substring(0, parts.first.length.clamp(0, 12)) : 'spot';
    slots.add(VPSlot(name: name, lat: f.lat, lng: f.lng, icon: '⭐'));
    await mgr.save(slots);
    if (!mounted) return;
    setState(() => _searchFocus = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$nameを登録しました'), duration: const Duration(seconds: 2)),
    );
  }
}
