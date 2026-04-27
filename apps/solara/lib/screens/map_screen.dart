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
import 'map/map_relocation_popup.dart';
import 'map/map_search.dart';
import 'map/map_overlays.dart';
import 'forecast_screen.dart';
import 'horoscope/horo_antique_icons.dart';
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
  /// プロフィール未設定時の案内から Sanctuary タブへ遷移させるコールバック。
  /// 実体は main.dart の `_onTabTap(4)`。
  final VoidCallback? onNavigateToSanctuary;
  const MapScreen({super.key, this.onNavigateToSanctuary});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
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

  // Phase M2 ASTRO レイヤー: 引越し / アスペクト線
  // 設計: project_solara_astrocartography_m2.md 論点8 (両方OFFスタート)
  final Map<String, bool> _astroLayers = {
    'relocate': false, 'aspect': false,
  };

  // 引越しレイヤー ON時のタップ詳細ポップアップ用
  LatLng? _relocateTapPoint;

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

  /// プロフィール未設定状態。true の間は占い系オーバーレイ（セクター・
  /// FortuneSheet・Omen 等）を非表示にし、中央に案内カードを出す。
  /// 乱数のモックスコアを見せて誤解を招くのを防ぐ目的。
  bool _noProfile = false;

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
  // OSM HOT は現地言語ラベルのまま（多言語化はユーザー数増えてから再検討）。
  MapStyle _mapStyle = MapStyle.osmHotLight;

  @override
  void initState() {
    super.initState();
    _loadProfileAndChart();
    _loadMapStyle();
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

  /// 外部（main.dart のタブ切替）から呼ばれる公開リロード。
  /// Sanctuary でプロフィール登録/編集後に Map に戻ったとき、
  /// `_noProfile` フラグを更新して占い系オーバーレイを再表示するために使う。
  Future<void> reloadProfile() => _loadProfileAndChart();

  Future<void> _loadProfileAndChart({DateTime? targetDate}) async {
    final p = await SolaraStorage.loadProfile();
    if (p == null || !p.isComplete) {
      if (mounted) setState(() => _noProfile = true);
      return;
    }
    _profile = p;
    if (mounted) setState(() => _noProfile = false);
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
    // 現住所が登録されていればハウス計算は現住所ベース(リロケーション)。
    // 注意: scoreAll() は houses 配列を直接使わない(aspects/角度距離のみ)ため、
    // 現状 16方位スコアには影響なし。将来 M1(ハウス重み付け)で意味を持つ。
    final useRelocate = !(p.homeLat == 0 && p.homeLng == 0);
    final chart = await fetchChart(
      birthDate: p.birthDate,
      birthTime: p.birthTime,
      birthLat: p.birthLat,
      birthLng: p.birthLng,
      birthTz: p.birthTz,
      birthTzName: p.birthTzName,
      targetDate: targetDate,
      relocateLat: useRelocate ? p.homeLat : null,
      relocateLng: useRelocate ? p.homeLng : null,
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
    final picked = await showSolaraDatePicker(context, initial: _selectedDate);
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

  /// 共通: 角丸付き全画面BottomSheet
  Future<void> _showSheet(Widget child, {double heightFrac = 0.9}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xB3000000),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * heightFrac,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: child,
        ),
      ),
    );
  }

  Future<void> _openLocations() => _showSheet(LocationsScreen(
    center: _center,
    scoreResult: _scoreResult,
    sectorScores: _displayScores(),
    profile: _profile,
    onSelectSlot: (slot) => _rebuild(LatLng(slot.lat, slot.lng)),
    onNavigateToSanctuary: widget.onNavigateToSanctuary,
  ));

  Future<void> _openForecast() {
    return _showSheet(
      ForecastScreen(
        onJumpToDate: (date) {
          setState(() => _selectedDate = date);
          _loadProfileAndChart(targetDate: date);
        },
        onNavigateToSanctuary: widget.onNavigateToSanctuary,
      ),
      heightFrac: 0.92,
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
    Color color = base;
    if (!isDark) {
      // 明るい地図（OSM Light/Cycle Light）はパステル色が埋もれるため、
      // 明度を下げ彩度を上げて視認性を確保する。
      final hsl = HSLColor.fromColor(base);
      // all/money は強めのコントラスト、healing/love はさらに薄めに、他は中間。
      final isStrong = _activeCategory == 'all' || _activeCategory == 'money';
      final isLight = _activeCategory == 'healing' || _activeCategory == 'love';
      final double lightMul = isStrong ? 0.65 : (isLight ? 0.95 : 0.85);
      final double lightMax = isStrong ? 0.72 : (isLight ? 0.90 : 0.85);
      final double satMul = isStrong ? 1.2 : (isLight ? 0.80 : 0.95);
      color = hsl
          .withLightness((hsl.lightness * lightMul).clamp(0.0, lightMax))
          .withSaturation((hsl.saturation * satMul).clamp(0.0, 1.0))
          .toColor();
    }
    // Phase M2 論点9 (7-E2): 引越しレイヤーON時は16方位カラーをdim
    if (_astroLayers['relocate'] == true) {
      color = color.withAlpha((color.a * 255 * 0.4).round());
    }
    return color;
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
            // Phase M2: 引越しレイヤーON時のみ、タップで引越しチャート再計算
            onTap: (tapPos, latlng) {
              if (_astroLayers['relocate'] == true && _chartResult != null) {
                setState(() => _relocateTapPoint = latlng);
              }
            },
          ),
          children: [
            buildStyledTileLayer(_mapStyle),
            // 出生情報が無い間はセクターを描画しない（スコアが乱数になるため）
            if (!_noProfile) PolygonLayer(polygons: buildSectors(
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
            if (_planetLines.isNotEmpty) PlanetSymbolsLayer(
              lines: _planetLines, layers: _layers,
              planetGroupVis: _planetGroups, activeCategory: _activeCategory,
            ),
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
              buildVpPinMarker(
                mapCtrl: _mapCtrl,
                center: _center,
                screenSize: MediaQuery.of(context).size,
                onCenterChange: (c) => setState(() => _center = c),
                onDragEnd: () {
                  setState(() {});
                  _reannotateSearchResults();
                },
              ),
            ]),
          ],
        ),

        // ── FF Label ──
        if (!_noProfile) Positioned(
          top: topPad + 2, left: 16,
          child: FortuneFilterLabel(
            sectorScores: _displayScores(),
            activeSrc: _activeSrc,
            activeCategory: _activeCategory,
          ),
        ),

        // ── 日付バッジ（常時表示。今日なら「今日」、ラベルタップでピッカー）──
        Positioned(
          top: topPad + 44, left: 16,
          child: SelectedDateBadge(
            label: _formatSelectedDate(),
            onTap: _pickDate,
            onReset: _selectedDate != null ? _resetDateToToday : null,
          ),
        ),

        // ── サイドボタン群（🔍 ≡ 📍 🗺 🔮） ──
        // 📅 日付ボタンは削除済み（左上の SelectedDateBadge から起動）
        MapSideButtons(
          topPad: topPad,
          searchOpen: _searchOpen,
          layerPanelOpen: _layerPanelOpen,
          vpPanelOpen: _vpPanelOpen,
          onSearchTap: () => setState(() => _searchOpen = true),
          onLayerTap: () => setState(() => _layerPanelOpen = !_layerPanelOpen),
          onVpTap: () => setState(() => _vpPanelOpen = !_vpPanelOpen),
          onLocationsTap: _openLocations,
          onForecastTap: _openForecast,
        ),

        // ── Search Bar ──
        if (_searchOpen) Positioned(
          top: topPad + 92, left: 16, right: 16,
          child: SearchBarOverlay(
            controller: _searchCtrl,
            onSubmitted: _doSearch,
            onClose: () => setState(() => _searchOpen = false),
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
          child: const SeedBadge(),
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
          top: topPad + 92, left: 60,
          child: LayerPanel(
            layers: _layers,
            planetGroups: _planetGroups,
            astroLayers: _astroLayers,
            activeCategory: _activeCategory,
            mapStyle: _mapStyle,
            onLayerToggle: (k) => setState(() => _layers[k] = !(_layers[k] ?? false)),
            onPlanetGroupToggle: (k) => setState(() => _planetGroups[k] = !(_planetGroups[k] ?? false)),
            onAstroToggle: (k) => setState(() {
              _astroLayers[k] = !(_astroLayers[k] ?? false);
              // 引越しレイヤーOFF時はタップ詳細も閉じる
              if (k == 'relocate' && !(_astroLayers[k] ?? false)) {
                _relocateTapPoint = null;
              }
            }),
            onCategoryChanged: (k) {
              setState(() => _activeCategory = k);
              _reannotateSearchResults();
            },
            onMapStyleChanged: _onMapStyleChanged,
          ),
        ),

        // ── VP Panel ──
        if (_vpPanelOpen) Positioned(
          top: topPad + 188, left: 60,
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

        // ── Fortune Pull Tab ──（プロフィール未設定時は非表示）
        if (!_noProfile && !_fortuneSheetOpen) Positioned(
          bottom: 80, left: 0, right: 0,
          child: Center(
            child: FortunePullTab(onTap: () => setState(() => _fortuneSheetOpen = true)),
          ),
        ),

        // ── Fortune Sheet ──
        if (!_noProfile && _fortuneSheetOpen) Positioned(
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
        if (_preseedState == 'bottom') const Positioned(
          bottom: 12, left: 0, right: 0,
          child: PreseedHint(),
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
          child: SearchFocusPopup(
            focus: _searchFocus!,
            center: _center,
            fComps: _fComps,
            activeSrc: _activeSrc,
            onClose: () => setState(() => _searchFocus = null),
            onMoveToHit: () {
              final f = _searchFocus!;
              _rebuild(LatLng(f.lat, f.lng));
              setState(() => _searchFocus = null);
            },
            onSaveAsLocation: _saveFocusAsLocation,
          ),
        ),

        // ── Searching spinner ──
        if (_searching) Positioned(
          top: topPad + 144, left: 16,
          child: const StatusBadge(label: '検索中…'),
        ),

        // ── Daily Omen Button（今日のタップボタン）──
        if (!_noProfile && _omenVisible && _activeOverlay == null) Positioned(
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
          child: const StatusBadge(label: '計算中…'),
        ),

        // ── Rest Overlay ──
        if (_restOverlayVisible) Positioned.fill(
          child: RestOverlay(
            text: _restOverlayText,
            onDismiss: () => setState(() => _restOverlayVisible = false),
          ),
        ),

        // ── プロフィール未設定時の案内カード（Horo/Locations/Forecast と同文面・同スタイル）──
        if (_noProfile) Positioned.fill(
          child: IgnorePointer(
            ignoring: false,
            child: Center(child: _buildNoProfileGuide()),
          ),
        ),

        // ── Phase M2: 引越しレイヤー タップ詳細ポップアップ ──
        if (_relocateTapPoint != null && _chartResult != null && _profile != null)
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: SafeArea(
              top: false,
              child: _buildRelocationPopup(_relocateTapPoint!),
            ),
          ),
      ],
    );
  }

  /// Phase M2 引越しレイヤー: タップ地点の引越しチャートを表示。
  /// 比較ベースは home (現住所) 優先、未設定時は出生地。
  Widget _buildRelocationPopup(LatLng tap) {
    final p = _profile!;
    final chart = _chartResult!;
    final hasHome = !(p.homeLat == 0 && p.homeLng == 0);
    final baselineLng = hasHome ? p.homeLng : p.birthLng;
    final baselineLabel = hasHome ? '現住所' : '出生地';
    return MapRelocationPopup(
      tapLat: tap.latitude,
      tapLng: tap.longitude,
      natalPlanets: chart.natal,
      baselineMc: chart.mc,
      baselineLng: baselineLng,
      baselineHouses: chart.houses,
      baselineLabel: baselineLabel,
      onClose: () => setState(() => _relocateTapPoint = null),
    );
  }

  /// プロフィール未設定時の案内カード（他画面と完全同一）。
  /// 「設定する」タップで Sanctuary タブへ遷移。
  Widget _buildNoProfileGuide() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xE60C0C1A), // 地図上に出すので不透明度高めの背景
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x40F9D976)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const AntiqueGlyph(icon: AntiqueIcon.reading, size: 32,
            color: Color(0xFFF6BD60)),
          const SizedBox(height: 8),
          const Text('SANCTUARYでプロフィールを設定すると、\n各地点の方位スコアが表示されます',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFFF6BD60))),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => widget.onNavigateToSanctuary?.call(),
            child: const Text('設定する →',
              style: TextStyle(fontSize: 12, color: Color(0xFFF9D976),
                decoration: TextDecoration.underline)),
          ),
        ]),
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
