import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/solara_storage.dart';
import '../widgets/dominant_fortune_overlay.dart';
import '../widgets/daily_transit_badge.dart';
import 'map/map_daily_transit_screen.dart';
import 'map/map_constants.dart';
import 'map/map_styles.dart';
import 'map/map_sectors.dart';
import 'map/map_fortune_sheet.dart';
import 'map/map_stella.dart';
import 'map/map_vp_panel.dart';
import 'map/map_layer_panel.dart';
import 'map/map_astro.dart';
import 'map/map_astro_carto.dart';
import 'map/map_astro_lines.dart';
import 'map/map_location_markers.dart';
import 'map/map_planet_lines.dart';
import 'map/map_relocation_popup.dart';
import 'map/map_search.dart';
import 'map/map_overlays.dart';
import 'map/map_time_slider.dart';
import '../utils/astro_lines.dart' as astro_lines;
import '../utils/direction_energy.dart';
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
  // 2026-04-29: CCG 4 frame 追加でパネル長過ぎる問題を解決すべく
  // ☰DISPLAY (16方位/MAPSTYLE/コンパス) と ✨ASTRO (惑星ライン/CCG/CHART/PLANET GROUP/FORTUNE) に分割。
  bool _astroPanelOpen = false;
  bool _fortuneSheetOpen = false;
  bool _vpPanelOpen = false;
  String _vpTab = 'vp';
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

  // Phase M2 ASTRO レイヤー: 16方位/惑星ライン/引越し/アスペクト線 (論点5 4流派並列)
  // 設計: project_solara_astrocartography_m2.md 論点8 (引越し/アスペクトはOFFスタート)
  // planetLines は既存挙動の維持で true デフォルト (新機能のM2のみOFFスタート)
  //
  // Tier A #5 (CCG): aspectTransit / aspectProgressed / aspectSolarArc 追加。
  // 'aspect' は natal フレームを意味する (後方互換のため既存キー名を維持)。
  // 動的フレーム (T/P/SA) は viewDate から GMST を再計算する設計。
  final Map<String, bool> _astroLayers = {
    'planetLines': true,
    'relocate': false,
    'aspect': false,         // natal フレーム
    'aspectTransit': false,  // CCG transit
    'aspectProgressed': false, // CCG progressed
    'aspectSolarArc': false, // CCG solar arc
    'aspectAll': false,      // 全惑星モード (FORTUNE フィルタ無視)
  };

  // 引越しレイヤー ON時のタップ詳細ポップアップ用
  LatLng? _relocateTapPoint;

  // Astro*Carto*Graphy モード: 天頂点マーカータップ詳細用
  // 値が入っていれば下部 popup を表示する。
  // CCG: frame と point を保持し、natal以外の天頂タップにも対応。
  ({String planet, astro_lines.AstroFrame frame, LatLng point})? _zenithTapInfo;

  // Phase M2 論点3: アスペクト線 40本キャッシュ (chart 取得時に build)
  // CCG (Tier A #5): 4フレーム合算 (natal+transit+progressed+solarArc) を保持
  List<astro_lines.AstroLine> _astroLinesCache = const [];

  // CCG: 日付別 ChartResult キャッシュ (タイムスライダーの往復で再fetch回避)。
  // key = "yyyy-MM-dd" (UTC日)、null は relocate設定変化等で無効化。
  // LRU 風: 50件超えたら古いものから削除 (≒ ±25日往復で十分)。
  final Map<String, ChartResult> _chartCacheByDate = {};
  static const int _chartCacheMax = 50;

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

  // F1-c: Daily Transit Badge — 右上の日次トリガー。
  // _dailyBadgeUnseen=true 時は光る（リセット時刻後の初回表示）。
  // タップで _onDailyBadgeTap() → アニメ → F1-c フルUI へ。
  bool _dailyBadgeUnseen = false;
  bool _dailyTransitOpen = false;

  // Search results
  List<SearchHit> _searchHits = [];
  SearchHit? _searchFocus; // 選択済み1件（ピン表示用）
  bool _searching = false;
  // 検索一覧を表示し始めた時のマップ状態 (center/zoom)。
  // hit を選んでズームイン後、戻るボタンで一覧画面に戻る際に復元する。
  LatLng? _searchListCenter;
  double? _searchListZoom;
  // 検索結果リスト dropdown で選択中の VIEWPOINT index
  // -1 = 地図中心、0+ = _vpSlotsCache の index
  int _searchVpIndex = -1;

  // Map style (tile source + light/dark filter)
  // OSM HOT は現地言語ラベルのまま（多言語化はユーザー数増えてから再検討）。
  MapStyle _mapStyle = MapStyle.osmHotLight;

  // Astro*Carto*Graphy モード
  // ON時: 世界地図ズームアウト + relocate/aspect/aspectAll 強制ON +
  //       16方位/コンパス/惑星ライン/各種オーバーレイ非表示 +
  //       天頂点マーカー表示。情報密度を抑え世界規模ビューに集中させる。
  // 退避先: モード解除時に元の状態を完全復元する。
  bool _astroCartoMode = false;
  LatLng? _savedCenter;
  double? _savedZoom;
  Map<String, bool>? _savedLayers;
  Map<String, bool>? _savedAstroLayers;
  MapStyle? _savedMapStyle;

  // 登録地マーカー (出生地 + VP slots + Locations slots、両モード共通表示)
  // VP/Locations 編集後は _reloadLocationSlots() で再読込。
  final SlotManager _vpSlotMgr =
      SlotManager(storageKey: 'solara_vp_slots', defaultNames: ['職場','お気に入り','スポット','場所']);
  final SlotManager _locSlotMgr =
      SlotManager(storageKey: 'solara_locations', defaultNames: ['場所1','場所2','場所3','場所4']);
  List<VPSlot> _vpSlotsCache = const [];
  List<VPSlot> _locSlotsCache = const [];
  // タップされたマーカー情報 (popup 表示用)。null = popup 非表示。
  ({String name, LatLng point, bool isBirth})? _locationTapInfo;

  @override
  void initState() {
    super.initState();
    _loadProfileAndChart();
    _loadMapStyle();
    _checkDailyBadgeState();
  }

  /// 右上 DailyTransitBadge の「未閲覧（光る）」状態判定。
  /// _topCategory が算出されていて、かつリセット時刻考慮の
  /// 「今日」で未表示なら出す。（デバッグフラグ ON 時は常に表示）
  Future<void> _checkDailyBadgeState() async {
    bool unseen;
    if (_debugAlwaysShowOverlay) {
      unseen = true;
    } else {
      if (_topCategory == null ||
          !_implementedOverlayKinds.contains(_topCategory)) {
        // トップカテゴリ未算出 or アニメ未実装カテゴリ: 光らない（プロフィール無等）
        unseen = false;
      } else {
        final shown = await SolaraStorage.wasOverlayShownToday(_overlayStorageKey);
        unseen = !shown;
      }
    }
    if (!mounted) return;
    setState(() => _dailyBadgeUnseen = unseen);
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
    // 登録地スロット (home含む) を読込してマーカー描画に使う
    await _reloadLocationSlots();
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

    // CCG (Tier A #5): 日時別 chart キャッシュ参照。
    // タイムスライダーで往復した際の API 連続呼出を回避する。
    //
    // 2026-04-29 修正: キーに時(hour)を含める。
    // 旧実装は YYYY-MM-DD だけだったため、時刻スライダーを動かしても
    // 同日キャッシュがヒットして月などの惑星黄経が更新されない問題があった。
    // 月は約0.5°/h 動くので、1h 刻みで chart を再取得する妥当性が高い。
    String cacheKey;
    if (targetDate == null) {
      cacheKey = 'today';
    } else {
      final t = targetDate.toUtc();
      cacheKey =
          '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}T${t.hour.toString().padLeft(2, '0')}';
    }
    ChartResult? chart = _chartCacheByDate[cacheKey];
    if (chart == null) {
      chart = await fetchChart(
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
        // LRU 風: 既存キーは末尾移動、超過時に先頭削除
        _chartCacheByDate.remove(cacheKey);
        _chartCacheByDate[cacheKey] = chart;
        if (_chartCacheByDate.length > _chartCacheMax) {
          _chartCacheByDate.remove(_chartCacheByDate.keys.first);
        }
      }
    }
    if (chart != null) {
      _chartResult = chart;
      final result = scoreAll(chart);
      final lines = buildPlanetLineData(center: _center, chart: chart);
      // Phase M2 論点3: アスペクト線 40本を build (Worker呼出ゼロ)
      // 比較ベースは relocate=home優先・未設定なら出生地 (chart fetch と同じ)
      final baselineLng = useRelocate ? p.homeLng : p.birthLng;
      // Tier A #5 (CCG): 4フレーム同時計算
      // - natal:   baseline 由来 GMST (chart fetch時の MC + lng から逆算)
      // - dynamic: viewDate (= targetDate ?? now) UTC から計算した GMST
      //            transit/progressed planets は Worker 計算済み
      //            solarArc planets は natal+progressed から arc=Δsun を全惑星に加算
      final viewUtc = (targetDate ?? DateTime.now()).toUtc();
      final viewGmst = astro_lines.gmstHoursFromUtc(viewUtc);
      final natalLines = astro_lines.buildAstroLines(
        natal: chart.natal,
        baselineMc: chart.mc,
        baselineLng: baselineLng,
      );
      final transitLines = chart.transit != null
          ? astro_lines.buildAstroLinesAt(
              planets: chart.transit!,
              gmstHours: viewGmst,
              frame: astro_lines.AstroFrame.transit,
            )
          : const <astro_lines.AstroLine>[];
      final progressedLines = chart.progressed != null
          ? astro_lines.buildAstroLinesAt(
              planets: chart.progressed!,
              gmstHours: viewGmst,
              frame: astro_lines.AstroFrame.progressed,
            )
          : const <astro_lines.AstroLine>[];
      final solarArcMap = chart.progressed != null
          ? astro_lines.solarArcPlanets(
              natal: chart.natal,
              progressed: chart.progressed!,
            )
          : const <String, double>{};
      final solarArcLines = solarArcMap.isNotEmpty
          ? astro_lines.buildAstroLinesAt(
              planets: solarArcMap,
              gmstHours: viewGmst,
              frame: astro_lines.AstroFrame.solarArc,
            )
          : const <astro_lines.AstroLine>[];
      final astroLines = [
        ...natalLines,
        ...transitLines,
        ...progressedLines,
        ...solarArcLines,
      ];
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
        _astroLinesCache = astroLines;
        _topCategory = topKey != null ? kindFromKey(topKey) : null;
        _loadingChart = false;
      });
      // トップカテゴリが確定したので Daily Transit Badge の状態を再評価
      await _checkDailyBadgeState();
      // 検索結果が残っていれば、新しい日付のスコアで再注入
      _reannotateSearchResults();
    } else {
      if (mounted) setState(() => _loadingChart = false);
    }
  }

  /// FF Label タップで循環切替するカテゴリの順序。
  /// 総合 → 癒し → 豊かさ → 恋愛 → 仕事 → 話す → 総合 ... の順で繰返す。
  static const _categoryCycle = <String>[
    'all', 'healing', 'money', 'love', 'work', 'communication',
  ];

  /// FF Label タップ時、_activeCategory を次のカテゴリへ進める。
  /// セクター描画も同フレームで再計算されるので扇状もリアルタイム切替される。
  void _cycleActiveCategory() {
    final idx = _categoryCycle.indexOf(_activeCategory);
    final nextIdx = (idx + 1) % _categoryCycle.length;
    setState(() => _activeCategory = _categoryCycle[nextIdx]);
    _reannotateSearchResults();
  }

  /// 検索結果距離・方位・スコアの起点座標。
  /// _searchVpIndex == -1: 地図中心、>= 0: 該当 VPSlot の座標。
  LatLng get _searchEffectiveCenter {
    if (_searchVpIndex >= 0 && _searchVpIndex < _vpSlotsCache.length) {
      final s = _vpSlotsCache[_searchVpIndex];
      return LatLng(s.lat, s.lng);
    }
    return _center;
  }

  /// 既存の検索結果（リスト + フォーカス1件）に、現在の中心・日付・カテゴリ・ソース
  /// で算出したスコアを再注入する。日付ピッカー・VP切替・カテゴリ切替から呼ぶ。
  void _reannotateSearchResults() {
    final hasHits = _searchHits.isNotEmpty;
    final hasFocus = _searchFocus != null;
    if (!hasHits && !hasFocus) return;
    final scores = _displayScores();
    final c = _searchEffectiveCenter;
    if (hasHits) {
      annotateHitsWithScores(
        hits: _searchHits,
        center: c,
        sectorScores: scores,
        scoreResult: _scoreResult,
      );
    }
    if (hasFocus) {
      annotateHitsWithScores(
        hits: [_searchFocus!],
        center: c,
        sectorScores: scores,
        scoreResult: _scoreResult,
      );
    }
    if (mounted) setState(() {});
  }

  // 旧 _pickDate / _resetDateToToday は MapTimeSlider 常時表示に置き換えで削除 (2026-04-29)。
  // 日付選択は MapTimeSlider の slider/▲▼/LIVE で完結する。

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

  Future<void> _openLocations() async {
    // C-2: 検索中なら検索地を「現在地」として渡す (VP Pinより検索地優先)
    final effective = _searchFocus != null
        ? LatLng(_searchFocus!.lat, _searchFocus!.lng)
        : _center;
    await _showSheet(LocationsScreen(
      center: effective,
      scoreResult: _scoreResult,
      sectorScores: _displayScores(),
      profile: _profile,
      onSelectSlot: (slot) => _rebuild(LatLng(slot.lat, slot.lng)),
      onNavigateToSanctuary: widget.onNavigateToSanctuary,
    ));
    // 戻ったタイミングでスロット編集が反映されている可能性 → マーカー再描画
    await _reloadLocationSlots();
  }

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

  // 旧 _formatSelectedDate は MapTimeSlider 内で表示するため削除 (2026-04-29)。

  /// 右上 Daily Transit Badge タップ時のハンドラ。
  /// プロフィール無 or トップカテゴリ未算出ならば何もしない。
  /// 「未閲覧（リセット時刻後初回）」: アニメ → 0.5s 余韻 → F1-c フルUI
  /// 「閲覧済み（同日2回目以降）」: アニメ無し、F1-c フルUI を直接フェードイン
  Future<void> _onDailyBadgeTap() async {
    if (_activeOverlay != null) return;
    if (_dailyTransitOpen) return;
    if (_noProfile) return;

    DominantFortuneKind? kind;
    if (_debugAlwaysShowOverlay && _debugCycleOverlayKinds) {
      kind = _debugCycleOrder[_debugCycleIdx];
      _debugCycleIdx = (_debugCycleIdx + 1) % _debugCycleOrder.length;
    } else {
      kind = _topCategory;
      if (_debugAlwaysShowOverlay && (kind == null || !_implementedOverlayKinds.contains(kind))) {
        kind = DominantFortuneKind.love;
      }
      if (kind == null) {
        // トップカテゴリ未算出: アニメ無しで F1-c だけ開く（カテゴリ表示は「TOP表示」）
        setState(() => _dailyTransitOpen = true);
        return;
      }
      if (!_implementedOverlayKinds.contains(kind)) {
        // アニメ未実装カテゴリ: F1-c のみ
        setState(() => _dailyTransitOpen = true);
        return;
      }
    }

    if (!mounted) return;

    // 同日2回目以降: アニメ skip して F1-c へ直接
    final shown = await SolaraStorage.wasOverlayShownToday(_overlayStorageKey);
    if (shown && !_debugAlwaysShowOverlay) {
      setState(() => _dailyTransitOpen = true);
      return;
    }

    // 初回: アニメ再生 → 完了後に F1-c 表示
    setState(() {
      _activeOverlay = kind;
      _dailyBadgeUnseen = false;
    });
    if (!_debugAlwaysShowOverlay) {
      await SolaraStorage.markOverlayShown(_overlayStorageKey);
    }
  }

  /// Dominant Fortune Overlay 完了時の処理。
  /// アニメ → 0.5s 余韻 → F1-c フルUI フェードイン
  Future<void> _onOverlayComplete() async {
    if (!mounted) return;
    setState(() => _activeOverlay = null);
    // 余韻 0.5 秒
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _dailyTransitOpen = true);
  }

  /// F1-c フル UI を閉じる。バッジは閲覧済み状態（光らない）に。
  void _onDailyTransitClose() {
    if (!mounted) return;
    setState(() {
      _dailyTransitOpen = false;
      _dailyBadgeUnseen = false;
    });
  }

  // 旧 _dailyTransitLocation / _dailyTransitLocationLabel は廃止 (2026-04-30)。
  // MapDailyTransitScreen 内部で VIEWPOINT dropdown により切替可能になった。
  // 親は出生地と vpSlots を渡すだけ。

  Future<void> _doSearch(String query) async {
    if (query.trim().length < 2) return;
    setState(() => _searching = true);
    // マップ中心 (現在の _center) を bias に渡し、Google 側で半径15kmを優先
    final hits = await searchPlaces(query, biasCenter: _center);
    annotateHitsWithScores(
      hits: hits,
      center: _searchEffectiveCenter,
      sectorScores: _displayScores(),
      scoreResult: _scoreResult,
    );
    if (!mounted) return;
    setState(() {
      _searchHits = hits;
      _searching = false;
      _searchOpen = false;
      _searchFocus = null; // 前回の focus は破棄
    });
    if (hits.length == 1) {
      _selectSearchHit(hits.first);
    } else if (hits.length > 1) {
      // 複数候補: zoom 11 で半径15km全体を見せ、中心をリスト上部へずらす
      _frameSearchArea(_center);
    }
  }

  /// 検索結果リストが画面下半分を覆う前提で、マップ中心を「南」にずらして
  /// 元の center が画面の上半分中央に来るようにする。
  /// ズームは都市内のエリア詳細が見える 13.0（オーナー判断 2026-04-30）。
  ///
  /// この時の (shifted, zoom) を保存しておき、hit 選択後に focus を閉じた際に
  /// `_restoreSearchListView` で同じ位置・ズームへ復元する。
  void _frameSearchArea(LatLng around) {
    final size = MediaQuery.of(context).size;
    // 検索結果リスト高さ = 画面の 45% (SearchResultList に渡している maxHeight と一致)
    // 上部の地図領域 (約55%) を広めに取り、店舗探索の視認性を上げる。
    final listH = size.height * 0.45;
    // リスト中心からのオフセット (この距離だけ地図中心を南に動かす)
    final offsetPx = listH / 2;
    // Web Mercator: 1° latitude = 256 * 2^zoom / 360 / cos(lat) px
    const zoom = 13.0;
    const zoomInt = 13;
    final pxPerLatDeg = 256 * (1 << zoomInt) /
        360 /
        math.cos(around.latitude * math.pi / 180);
    final offsetLat = offsetPx / pxPerLatDeg;
    final shifted = LatLng(around.latitude - offsetLat, around.longitude);
    _searchListCenter = shifted;
    _searchListZoom = zoom;
    try {
      _mapCtrl.move(shifted, zoom);
    } catch (_) {/* 初期化中は無視 */}
  }

  /// hit 選択後に focus を閉じた際、`_frameSearchArea` で記録した
  /// 元の一覧表示状態 (center, zoom) へ地図を戻す。
  /// 一覧表示前の状態が保存されていない場合は何もしない。
  void _restoreSearchListView() {
    final c = _searchListCenter;
    final z = _searchListZoom;
    if (c == null || z == null) return;
    try {
      _mapCtrl.move(c, z);
    } catch (_) {/* 初期化中は無視 */}
  }

  void _selectSearchHit(SearchHit hit) {
    final pos = LatLng(hit.lat, hit.lng);
    _mapCtrl.move(pos, 15);
    setState(() {
      _searchFocus = hit;
      // _searchHits は維持。focus を閉じるとリストが復帰する。
    });
  }

  /// 検索 focus 中の単一マーカー。
  /// リスト中の hit 順 (1〜20) をそのまま中心に表示し、選択した番号を保持する。
  /// 一覧マーカー(_buildSearchHitMarkers)より大きめ・影濃いめ。
  Marker _buildFocusedHitMarker() {
    final f = _searchFocus!;
    // _searchHits の中での位置 = リストでの番号
    // _selectSearchHit は _searchHits を破棄せず focus を立てるので indexOf が機能する。
    final idx = _searchHits.indexOf(f);
    final hasNumber = idx >= 0;
    return Marker(
      point: LatLng(f.lat, f.lng),
      width: 38,
      height: 38,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xE6C9A84C), // ゴールド (一覧マーカーと同色)
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xCC000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: hasNumber
            ? Text(
                '${idx + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF0C0C16),
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              )
            : null,
      ),
    );
  }

  /// 検索結果リスト中に地図上へ番号マーカー (1〜20) を描画する。
  /// 表示順 = リスト順 (Google RELEVANCE + locationBias)。
  /// タップで `_selectSearchHit` を呼び、リスト側でタップしたのと同等に focus する。
  List<Marker> _buildSearchHitMarkers() {
    final hits = _searchHits;
    final markers = <Marker>[];
    for (int i = 0; i < hits.length; i++) {
      final h = hits[i];
      markers.add(Marker(
        point: LatLng(h.lat, h.lng),
        width: 32,
        height: 32,
        // 円中心がピン先になるよう alignment 中央のままにする
        child: GestureDetector(
          onTap: () => _selectSearchHit(h),
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xE6C9A84C), // ゴールド円 (テーマ色)
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '${i + 1}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF0C0C16),
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
          ),
        ),
      ));
    }
    return markers;
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

  /// 🔴 Solara設計思想: ソフト/ハード独立2エネルギー版の方位データ。
  /// セクター描画は本メソッドの戻り値を `sectorEnergies` に渡す。
  /// _activeSrc によりトランジット/プログレス/合計を切替。
  /// （詳細: project_solara_design_philosophy.md）
  Map<String, DirectionEnergy>? _displayEnergies() {
    final comps = _activeCategory == 'all'
        ? _sectorComps
        : (_fComps[_activeCategory] ?? const <String, Map<String, double>>{});
    if (comps.isEmpty) return null;

    final useT = _activeSrc == 'transit' || _activeSrc == 'combined';
    final useP = _activeSrc == 'progressed' || _activeSrc == 'combined';

    final result = <String, DirectionEnergy>{};
    for (final d in dir16) {
      final c = comps[d] ?? const <String, double>{};
      double soft = 0;
      double hard = 0;
      if (useT) {
        soft += c['tSoft'] ?? 0;
        hard += c['tHard'] ?? 0;
      }
      if (useP) {
        soft += c['pSoft'] ?? 0;
        hard += c['pHard'] ?? 0;
      }
      result[d] = DirectionEnergy(soft: soft, hard: hard);
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

  /// Astro*Carto*Graphy モード起動。
  /// 現状を退避 → 世界規模ビュー(出生地経度・緯度20°・zoom 2.5)+ ダーク強制 +
  /// relocate/aspect/aspectAll ON + 不要レイヤー OFF。
  void _enterAstroCartoMode() {
    if (_chartResult == null || _profile == null) return;
    _savedCenter = _center;
    _savedZoom = _mapCtrl.camera.zoom;
    _savedLayers = Map<String, bool>.from(_layers);
    _savedAstroLayers = Map<String, bool>.from(_astroLayers);
    _savedMapStyle = _mapStyle;

    setState(() {
      _astroCartoMode = true;
      _layers['sectors'] = false;
      _layers['compass'] = false;
      _astroLayers['planetLines'] = false;
      _astroLayers['relocate'] = true;
      // CCG (D2): モード入時は natal を強制ON。Transit/Progressed/SolarArc は
      // ユーザーの直前選択を維持 (Pills UI で個別切替可能)。
      // aspectAll は強制ONしない (FORTUNE Pills でカテゴリ絞込みする UX 用)。
      // 「総合」タップで activeCategory='all' → 自動で全惑星 100% になる。
      _astroLayers['aspect'] = true;
      _mapStyle = MapStyle.osmHotDark;
      // 既存パネル/シート/ピンを片付け、世界規模ビューにフォーカス
      _layerPanelOpen = false;
      _astroPanelOpen = false;
      _vpPanelOpen = false;
      _searchOpen = false;
      _fortuneSheetOpen = false;
      _searchHits = [];
      _searchFocus = null;
      _relocateTapPoint = null;
      _zenithTapInfo = null;
    });
    SolaraStorage.saveMapStyleId(mapStyleConfigs[MapStyle.osmHotDark]!.id);

    // 出生地経度を中心に世界全景 (緯度20°≒赤道よりやや北で南北バランス良)
    final lng = _profile!.birthLng;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapCtrl.move(LatLng(20, lng), 2.5);
      } catch (_) {/* 初期化中は無視 */}
    });
  }

  /// Astro*Carto*Graphy モード解除。退避した状態を完全復元。
  void _exitAstroCartoMode() {
    if (_savedCenter == null) return;
    final restoreCenter = _savedCenter!;
    final restoreZoom = _savedZoom!;
    final restoreLayers = _savedLayers!;
    final restoreAstroLayers = _savedAstroLayers!;
    final restoreStyle = _savedMapStyle!;

    setState(() {
      _astroCartoMode = false;
      _layers
        ..clear()
        ..addAll(restoreLayers);
      _astroLayers
        ..clear()
        ..addAll(restoreAstroLayers);
      _mapStyle = restoreStyle;
      _relocateTapPoint = null;
      _zenithTapInfo = null;
    });
    SolaraStorage.saveMapStyleId(mapStyleConfigs[restoreStyle]!.id);
    _savedCenter = null;
    _savedZoom = null;
    _savedLayers = null;
    _savedAstroLayers = null;
    _savedMapStyle = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapCtrl.move(restoreCenter, restoreZoom);
      } catch (_) {/* 無視 */}
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
    // 物理戻るボタン (Android) で検索 focus → 検索結果リスト → 通常Map の順に
    // 段階的に閉じる。focus / hits 表示中は OS のデフォルト pop を抑制。
    return PopScope(
      canPop: _searchFocus == null && _searchHits.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_searchFocus != null) {
          // hits は維持 → リスト復帰 + 地図も検索一覧時の状態に戻す
          setState(() => _searchFocus = null);
          _restoreSearchListView();
        } else if (_searchHits.isNotEmpty) {
          setState(() {
            _searchHits = [];
            _searchListCenter = null;
            _searchListZoom = null;
          });
        }
      },
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    // 2026-04-29: NavBar 被り問題の根本解決。オーバーレイ群を内側の Padded Stack に
    // 集約し、bottom: 0 = NavBar の上端 として扱う。各 widget で navInset を
    // 手動加算する必要がなく、新規追加時の被りリスクが原則無くなる。
    // FlutterMap だけは全画面のまま (NavBar 越しに blur が効く視覚効果を保持)。

    return Stack(
      children: [
        // ── Map ──
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: _center, initialZoom: 14,
            minZoom: 2, maxZoom: 19,
            backgroundColor: mapStyleConfigs[_mapStyle]!.backgroundColor,
            // 回転ジェスチャー無効化 (2026-04-29):
            // Solara Map は北上固定前提 (16方位セクター・コンパス・VP Pin の方位概念が
            // 回転で破綻する)。ピンチズーム時の指のひねりで誤回転していた問題を解消。
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            // HTML: long-press 600ms → rebuild(nc, fly:true)
            onLongPress: (tapPos, latlng) => _rebuild(latlng),
            // Phase M2 + CCG: aspect (4フレーム何れか) / relocate ON時、タップで統合 popup
            // 設計: 論点10 (8-β) — 1タップで線情報+12ハウス情報を集約表示
            onTap: (tapPos, latlng) {
              if (_chartResult == null) return;
              final aspectOn = _astroLayers['aspect'] == true ||
                  _astroLayers['aspectTransit'] == true ||
                  _astroLayers['aspectProgressed'] == true ||
                  _astroLayers['aspectSolarArc'] == true;
              final relocateOn = _astroLayers['relocate'] == true;
              if (!aspectOn && !relocateOn) return;
              // aspect ONのみで近接線がない場合は popup を出さない (空表示防止)
              if (aspectOn && !relocateOn) {
                final near = _findNearbyAstroLines(latlng);
                if (near.isEmpty) return;
              }
              setState(() {
                _relocateTapPoint = latlng;
                _zenithTapInfo = null;
              });
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
              // 🔴 Solara設計思想: 2エネルギー独立描画
              sectorEnergies: _displayEnergies(),
              dimFactor: _astroLayers['relocate'] == true ? 0.4 : 1.0,
              activeCategory: _activeCategory,
            )),
            PolylineLayer(polylines: buildCompass(center: _center, visible: _layers['compass']!)),
            // HTML: addPlanetLines() — natal/progressed/transit 天体ライン
            // Phase M2 論点5: ASTRO『惑星ライン』メタトグル (planetLines) で全体ON/OFF
            if (_planetLines.isNotEmpty && (_astroLayers['planetLines'] ?? true))
              PolylineLayer(polylines: buildPlanetPolylines(
                lines: _planetLines, layers: _layers,
                planetGroupVis: _planetGroups, activeCategory: _activeCategory,
              )),
            if (_planetLines.isNotEmpty && (_astroLayers['planetLines'] ?? true))
              PlanetSymbolsLayer(
                lines: _planetLines, layers: _layers,
                planetGroupVis: _planetGroups, activeCategory: _activeCategory,
              ),
            // Phase M2 論点3 + Tier A #5 (CCG): 4フレームのアスペクト線
            // _visibleAstroLines() で _astroLayers の natal/transit/progressed/solarArc トグルから絞り込む
            if (_visibleAstroLines().isNotEmpty)
              PolylineLayer(polylines: buildAstroPolylines(
                lines: _visibleAstroLines(),
                activeCategory: _activeCategory,
                allPlanetMode: _astroLayers['aspectAll'] ?? false,
              )),
            // 天頂点マーカー (CCG): 表示中の全フレームの zenith を描画。
            // 動的フレーム (Transit/Prog/SArc) は時間で動くため CCG の核となる。
            // ACGモードでは natal を強制ON、通常Mapでは toggle 状況に従う。
            if (_zenithVisibleFrames().isNotEmpty && _astroLinesCache.isNotEmpty)
              MarkerLayer(markers: buildAstroZenithMarkers(
                lines: _astroLinesCache,
                activeCategory: _activeCategory,
                allPlanetMode: _astroLayers['aspectAll'] ?? false,
                framesWithZenith: _zenithVisibleFrames(),
                onTap: (planetKey, frame, point) => setState(() {
                  _zenithTapInfo = (planet: planetKey, frame: frame, point: point);
                  _relocateTapPoint = null; // 排他: 線+ハウス popup を閉じる
                }),
              )),
            // 16方位ラベル: モード中は世界規模ビューでは意味を成さないので非表示
            if (!_astroCartoMode)
              MarkerLayer(markers: buildDirLabels(center: _center)),
            // 登録地マーカー (出生地🌟+グロー / VP slots / Locations slots)
            // 通常Map / Astro*Carto*Graphy モード共通で表示。
            if (!_noProfile)
              MarkerLayer(markers: buildLocationMarkers(
                profile: _profile,
                vpSlots: _vpSlotsCache,
                locationSlots: _locSlotsCache,
                onTap: (name, point, isBirth) => setState(() {
                  _locationTapInfo = (name: name, point: point, isBirth: isBirth);
                }),
              )),
            // 検索結果リスト中: 各 hit に番号マーカー (1〜20) を描画。
            // タップで _selectSearchHit (= 該当 hit にズームイン + Focus popup)。
            // focus 中は数字マーカーを消し、下の CircleLayer のゴールド円のみ表示。
            if (_searchHits.isNotEmpty && _searchFocus == null)
              MarkerLayer(markers: _buildSearchHitMarkers()),
            // 検索 focus 中マーカー: リストでタップした番号(1〜20)を中心に表示。
            // 2026-04-30: 数字なし金色丸 → 番号付き金色丸に変更（オーナー要望）。
            // 一覧時マーカー(32x32)より少し大きく 38x38、影濃いめで「選択中」を強調。
            if (_searchFocus != null)
              MarkerLayer(markers: [_buildFocusedHitMarker()]),
            // VP Pin — HTML: draggable gold circle, dragend → rebuild
            // モード中は VP ピン非表示 (世界規模ビューでは中心の概念が無意味)
            if (!_astroCartoMode)
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

        // ── オーバーレイ全体: NavBar 上端までの領域に閉じ込める ──
        // SafeArea で Scaffold が自動設定する body padding.bottom (= NavBar 実高、
        // extendBody:true 時は NavBar が含まれる) を尊重する。これで端末や設定
        // ごとに変わる NavBar 高を Scaffold 任せで処理できる (手動計算で
        // ズレるリスクを排除)。
        // 内側の Stack 内では bottom: 0 = NavBar 上端。手動 navInset 不要。
        // 内側 SafeArea (popup 内等) は外側 SafeArea で消費済みのため二重 padding
        // しない。
        Positioned.fill(
          child: SafeArea(
            top: false, left: false, right: false,
            child: Stack(children: [

        // ── FF Label ──
        // モード中は「世界規模スコア」の概念が無いので非表示
        // 2026-04-30: ラベルタップでカテゴリ循環切替（オーナー要望）
        if (!_noProfile && !_astroCartoMode) Positioned(
          top: topPad + 2, left: 16,
          child: FortuneFilterLabel(
            sectorScores: _displayScores(),
            activeSrc: _activeSrc,
            activeCategory: _activeCategory,
            onTap: _cycleActiveCategory,
          ),
        ),

        // ── 日付タイムスライダー (旧日付バッジを置換、2026-04-29) ──
        // 通常Map / ACG モード共通で上部に常時表示。
        // ◀▶ 1日ステッパ + ±365日スライダー + LIVE ボタン + ⏰ で時刻行展開
        // 左端は left:60 でサイドボタン列 (left:16, 幅 ~40px) を回避。
        // 動的フレーム (Transit/Prog/SArc) ON 時は線が時刻連動で動く
        // Natal 単独でも 16方位スコア・FORTUNE は target date で再計算される
        Positioned(
          top: topPad + 44, left: 12, right: 12,
          child: MapTimeSlider(
            date: _selectedDate,
            onCommit: (d) async {
              setState(() => _selectedDate = d);
              await _loadProfileAndChart(targetDate: d);
            },
          ),
        ),

        // ── サイドボタン群（🔍 ☰ ✨ 📍 🗺 🔮 🌐） ──
        // 📅 日付ボタンは削除済み（左上の SelectedDateBadge から起動）
        // モード中は全サイドボタン非表示 (バナー × で復帰)
        if (!_astroCartoMode) MapSideButtons(
          topPad: topPad,
          searchOpen: _searchOpen,
          layerPanelOpen: _layerPanelOpen,
          astroPanelOpen: _astroPanelOpen,
          vpPanelOpen: _vpPanelOpen,
          onSearchTap: () => setState(() => _searchOpen = true),
          onLayerTap: () => setState(() {
            _layerPanelOpen = !_layerPanelOpen;
            if (_layerPanelOpen) _astroPanelOpen = false;
          }),
          onAstroPanelTap: () => setState(() {
            _astroPanelOpen = !_astroPanelOpen;
            if (_astroPanelOpen) _layerPanelOpen = false;
          }),
          onVpTap: () => setState(() => _vpPanelOpen = !_vpPanelOpen),
          onLocationsTap: _openLocations,
          onForecastTap: _openForecast,
          onAstroCartoTap: _enterAstroCartoMode,
        ),

        // ── Astro*Carto*Graphy モードバナー (上部中央) + カテゴリピル (下部中央) ──
        // 日付バッジ (top+44) との重なり回避のため top+2 に上げた (2026-04-29)
        if (_astroCartoMode) Positioned(
          top: topPad + 2, left: 0, right: 0,
          child: Center(child: AstroCartoBanner(onClose: _exitAstroCartoMode)),
        ),
        // 通常Map 用 TimeSlider は上部に常時表示 (上の SelectedDateBadge 置換コード参照)
        // ここは ACG モード用 UI の積み下ろし開始点

        // ── Search Bar ──
        if (_searchOpen) Positioned(
          top: topPad + 152, left: 16, right: 16,
          child: SearchBarOverlay(
            controller: _searchCtrl,
            onSubmitted: _doSearch,
            onClose: () => setState(() => _searchOpen = false),
          ),
        ),

        // ── Stella ──
        // モード中は世界規模ビューに集中させるため非表示
        if (!_astroCartoMode) Positioned(
          bottom: 10, left: 20, right: 20,
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

        // ── Daily Transit Badge（右上の日次トリガー） ──
        // ACGモード中は世界規模ビューを邪魔しないため非表示。
        // F1-c (2026-04-29 オーナー設計): タップで「今日の動き」を開く。
        // 未閲覧時は光るグロー演出、閲覧済みはトップカテゴリアイコン。
        if (!_astroCartoMode) Positioned(
          top: topPad + 6, right: 20,
          child: DailyTransitBadge(
            unseen: _dailyBadgeUnseen,
            topCategory: _topCategory,
            disabled: _noProfile,
            onTap: _onDailyBadgeTap,
          ),
        ),

        // ── 外側タップでパネルを閉じる（HTML: pointerdown outside → close）──
        if (_layerPanelOpen || _astroPanelOpen || _vpPanelOpen) Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              final wasVpOpen = _vpPanelOpen;
              setState(() {
                _layerPanelOpen = false;
                _astroPanelOpen = false;
                _vpPanelOpen = false;
              });
              // VP panel 内でスロット編集していた可能性を考慮し再読込
              if (wasVpOpen) _reloadLocationSlots();
            },
            child: const SizedBox.expand(),
          ),
        ),

        // ── Display Layer Panel (☰): 16方位/コンパス/MAPSTYLE ──
        if (_layerPanelOpen) Positioned(
          top: topPad + 152, left: 60,
          child: LayerPanel(
            view: LayerPanelView.display,
            layers: _layers,
            planetGroups: _planetGroups,
            astroLayers: _astroLayers,
            activeCategory: _activeCategory,
            mapStyle: _mapStyle,
            onLayerToggle: (k) => setState(() => _layers[k] = !(_layers[k] ?? false)),
            onPlanetGroupToggle: (k) => setState(() => _planetGroups[k] = !(_planetGroups[k] ?? false)),
            onAstroToggle: (k) => setState(() {
              _astroLayers[k] = !(_astroLayers[k] ?? false);
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

        // ── Astro Panel (✨): 惑星ライン/引越し/CCG 4 frame/CHART/PLANET GROUP/FORTUNE ──
        if (_astroPanelOpen) Positioned(
          top: topPad + 152, left: 60,
          child: LayerPanel(
            view: LayerPanelView.astro,
            layers: _layers,
            planetGroups: _planetGroups,
            astroLayers: _astroLayers,
            activeCategory: _activeCategory,
            mapStyle: _mapStyle,
            onLayerToggle: (k) => setState(() => _layers[k] = !(_layers[k] ?? false)),
            onPlanetGroupToggle: (k) => setState(() => _planetGroups[k] = !(_planetGroups[k] ?? false)),
            onAstroToggle: (k) => setState(() {
              _astroLayers[k] = !(_astroLayers[k] ?? false);
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
        // 📍ボタンは topPad+236 へ移動 (✨ ASTRO ボタン挿入のため)
        if (_vpPanelOpen) Positioned(
          top: topPad + 296, left: 60,
          child: VPPanel(
            activeTab: _vpTab,
            onTabChanged: (t) => setState(() => _vpTab = t),
            // C-2: 検索中なら検索地を「現在地」として渡す (VP Pinより検索地優先)
            center: _searchFocus != null
                ? LatLng(_searchFocus!.lat, _searchFocus!.lng)
                : _center,
            profile: _profile,
            onSlotSelected: (slot) {
              // HTML: onSelect → rebuild + close panel
              _rebuild(LatLng(slot.lat, slot.lng));
              setState(() => _vpPanelOpen = false);
              // パネル内でスロット編集していた可能性 → マーカー再描画
              _reloadLocationSlots();
            },
            onGeolocate: _geolocate,
          ),
        ),

        // ── Fortune Pull Tab ──（プロフィール未設定時 / モード中は非表示）
        if (!_noProfile && !_fortuneSheetOpen && !_astroCartoMode) Positioned(
          bottom: 0, left: 0, right: 0,
          child: Center(
            child: FortunePullTab(onTap: () => setState(() => _fortuneSheetOpen = true)),
          ),
        ),

        // ── Fortune Sheet ──
        if (!_noProfile && _fortuneSheetOpen && !_astroCartoMode) Positioned(
          bottom: 0, left: 0, right: 0,
          child: FortuneSheet(
            activeSrc: _activeSrc,
            activeCategory: _activeCategory,
            // 'all' 時は総合 sComp、それ以外はカテゴリ別 fComp を渡す
            sectorComps: _activeCategory == 'all'
                ? _sectorComps
                : (_fComps[_activeCategory] ?? _sectorComps),
            // E4: 2エネルギー詳細ポップアップ用データ
            sectorEnergies: _displayEnergies(),
            sectorContributors: _activeCategory == 'all'
                ? _scoreResult?.sContributors
                : _scoreResult?.fContributors[_activeCategory],
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

        // ── Search Result List（複数候補） ──
        // focus 中はリスト非表示。focus を閉じるとリスト復帰。
        if (_searchHits.isNotEmpty && _searchFocus == null) Positioned(
          bottom: 0, left: 8, right: 8,
          child: SearchResultList(
            hits: _searchHits,
            center: _searchEffectiveCenter,
            // 0.45 = ハーフサイズより少し小さめ。地図領域を広めに取る (オーナー判断)
            maxHeight: MediaQuery.of(context).size.height * 0.45,
            onTap: _selectSearchHit,
            onClose: () => setState(() {
              _searchHits = [];
              _searchListCenter = null;
              _searchListZoom = null;
              _searchVpIndex = -1; // 次回検索の起点を地図中心に戻す
            }),
            vpSlots: _vpSlotsCache,
            selectedVpIndex: _searchVpIndex,
            onVpChanged: (idx) {
              setState(() => _searchVpIndex = idx);
              _reannotateSearchResults();
            },
          ),
        ),

        // ── Search Focus Popup（単一選択後） ──
        if (_searchFocus != null) Positioned(
          bottom: 80, left: 16, right: 16,
          child: SearchFocusPopup(
            focus: _searchFocus!,
            center: _center,
            fComps: _fComps,
            activeSrc: _activeSrc,
            // ×タップ: focus 閉じる → リスト復帰 + 地図も一覧表示時へ復元
            onClose: () {
              setState(() => _searchFocus = null);
              _restoreSearchListView();
            },
            // 「ここへ移動」: 中心をその地点に移してリスト・focus 全て破棄
            onMoveToHit: () {
              final f = _searchFocus!;
              _rebuild(LatLng(f.lat, f.lng));
              setState(() {
                _searchFocus = null;
                _searchHits = [];
                _searchListCenter = null;
                _searchListZoom = null;
              });
            },
          ),
        ),

        // ── Searching spinner ──
        if (_searching) Positioned(
          top: topPad + 204, left: 16,
          child: const StatusBadge(label: '検索中…'),
        ),

        // ── Dominant Fortune Overlay ──
        if (_activeOverlay != null) Positioned.fill(
          child: DominantFortuneOverlay(
            key: ValueKey(_activeOverlay),
            kind: _activeOverlay!,
            onComplete: _onOverlayComplete,
          ),
        ),

        // ── F1-c: Daily Transit Full UI ──
        // _onDailyBadgeTap または _onOverlayComplete で _dailyTransitOpen=true。
        // 閉じる → _onDailyTransitClose で右上バッジ位置に縮小フェード。
        // 2026-04-30: 観測点を画面内 VIEWPOINT dropdown で切替可能に変更。
        // 親は出生地と VP slots 一式を渡すだけ。初期は自宅 → 自宅未登録なら出生地。
        // V2: natal を渡してイベント時刻のアスペクト context を併記
        if (_dailyTransitOpen && _profile != null) Positioned.fill(
          child: MapDailyTransitScreen(
            topCategory: _topCategory,
            birthLocation: LatLng(_profile!.birthLat, _profile!.birthLng),
            birthLocationName: _profile!.birthPlace.isNotEmpty
                ? _profile!.birthPlace
                : '出生地',
            vpSlots: _vpSlotsCache,
            natal: _chartResult?.natal,
            onClose: _onDailyTransitClose,
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

        // ── 天頂点タップ詳細 popup (CCG: 全フレーム対応) ──
        // 線+ハウス popup と排他 (どちらか片方のみ表示)。
        // 2026-04-30: 画面中央付近まで浮上させ、視認性を高める (オーナー要望)。
        if (_zenithTapInfo != null)
          Positioned.fill(
            child: SafeArea(
              child: GestureDetector(
                onTap: () => setState(() => _zenithTapInfo = null),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  color: const Color(0x77000000),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () {}, // popup自体のタップは閉じない
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.78,
                      ),
                      child: SingleChildScrollView(
                        child: _buildZenithPopup(_zenithTapInfo!),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // ── 登録地マーカータップ詳細 popup (出生地 / VP / Locations 共通) ──
        if (_locationTapInfo != null)
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: SafeArea(
              top: false,
              child: LocationMarkerPopup(
                name: _locationTapInfo!.name,
                point: _locationTapInfo!.point,
                isBirth: _locationTapInfo!.isBirth,
                onClose: () => setState(() => _locationTapInfo = null),
              ),
            ),
          ),

        // ── ACGモード下部 UI (popup より後に描画して常に最前面) ──
        // NavBar (80px) を避けて積み上げる:
        // bottom 92  → CategoryPills (FORTUNE 切替)
        // bottom 132 → FramePills    (Natal/Transit/Prog/SArc)
        // bottom 176 → TimeSlider    (動的フレーム ON 時のみ)
        if (_astroCartoMode) Positioned(
          left: 0, right: 0, bottom: 12,
          child: Center(
            child: AstroCartoCategoryPills(
              activeCategory: _activeCategory,
              onChanged: (k) => setState(() => _activeCategory = k),
            ),
          ),
        ),
        if (_astroCartoMode) Positioned(
          left: 0, right: 0, bottom: 52,
          child: Center(
            child: AstroCartoFramePills(
              astroLayers: _astroLayers,
              onToggle: (k) => setState(() {
                _astroLayers[k] = !(_astroLayers[k] ?? false);
              }),
            ),
          ),
        ),
        // ACGモード下部スライダーは廃止 (2026-04-29、上部常時表示に統一)
              ]), // Inner Stack 終端 (NavBar 上端までの overlay 領域)
          ), // SafeArea 終端
        ), // Positioned.fill 終端
      ],
    );
  }

  /// 天頂点 popup ビルダ。CCG: タップされた frame の zenith 座標を直接使う。
  Widget _buildZenithPopup(({String planet, astro_lines.AstroFrame frame, LatLng point}) info) {
    return AstroZenithPopup(
      planetKey: info.planet,
      zenith: info.point,
      frame: info.frame,
      onClose: () => setState(() => _zenithTapInfo = null),
    );
  }

  /// Phase M2 統合タップ popup (論点10 8-β):
  /// aspect ON で線情報、relocate ON で ASC/MC + 12ハウス、両方ONで統合表示。
  /// 比較ベースは home (現住所) 優先、未設定時は出生地。
  Widget _buildRelocationPopup(LatLng tap) {
    final p = _profile!;
    final chart = _chartResult!;
    final hasHome = !(p.homeLat == 0 && p.homeLng == 0);
    final baselineLng = hasHome ? p.homeLng : p.birthLng;
    final baselineLabel = hasHome ? '現住所' : '出生地';

    // CCG: aspect トグルは4フレームの何れか ON で有効
    final aspectOn = _astroLayers['aspect'] == true ||
        _astroLayers['aspectTransit'] == true ||
        _astroLayers['aspectProgressed'] == true ||
        _astroLayers['aspectSolarArc'] == true;
    final relocateOn = _astroLayers['relocate'] == true;

    // aspect ON 時のみ近接線検出 (Tier A #3、画面pixel距離 20px)
    // _findNearbyAstroLines が _visibleAstroLines() 経由で表示中フレームのみ対象にする。
    final List<astro_lines.NearbyAstroLine>? nearby = aspectOn
        ? _findNearbyAstroLines(tap)
        : null;

    // Tier S #2: ライン narrative API 用の natal 文脈を組み立てる
    int signOf(double lon) =>
        ((lon % 360 + 360) % 360 / 30).floor() % 12;
    final natalSummary = <String, int>{
      if (chart.houses.isNotEmpty) 'ascSign': signOf(chart.houses[0]),
      'mcSign': signOf(chart.mc),
      if (chart.natal['sun'] != null) 'sunSign': signOf(chart.natal['sun']!),
      if (chart.natal['moon'] != null)
        'moonSign': signOf(chart.natal['moon']!),
    };

    return MapRelocationPopup(
      tapLat: tap.latitude,
      tapLng: tap.longitude,
      natalPlanets: chart.natal,
      baselineMc: chart.mc,
      baselineLng: baselineLng,
      baselineHouses: chart.houses,
      baselineLabel: baselineLabel,
      showHouses: relocateOn,
      nearbyLines: nearby,
      natalSummary: natalSummary,
      userName: p.name.isNotEmpty ? p.name : null,
      onClose: () => setState(() => _relocateTapPoint = null),
    );
  }

  /// 登録地スロット (VP + Locations) を再読込してマーカー描画に反映する。
  /// 呼出タイミング: プロフィール初回ロード後 / VP panel 閉じた後 /
  /// Locations screen から戻った後 / 検索結果から登録した後。
  /// home は両 SlotManager の syncHome で先頭に同期される。
  Future<void> _reloadLocationSlots() async {
    await _vpSlotMgr.syncHome(_profile);
    await _locSlotMgr.syncHome(_profile);
    final vp = await _vpSlotMgr.load();
    final loc = await _locSlotMgr.load();
    if (!mounted) return;
    setState(() {
      _vpSlotsCache = vp;
      _locSlotsCache = loc;
    });
  }

  /// 近接アスペクト線を検出 (Tier A #3)。
  /// 通常Map / Astro*Carto*Graphy モード共通で画面pixel距離 (20px) で判定。
  /// km固定閾値はズームに比例して破綻するため不採用 (zoom 14 で 200km は ~21,000px)。
  /// camera は1度だけキャプチャして project に渡す
  /// (camera ゲッタを毎呼出すとインスタンス再生成のリスクがあるため)。
  /// CCG: 表示中の全フレームを跨いで近接判定する (Natal + Transit + ...)。
  List<astro_lines.NearbyAstroLine> _findNearbyAstroLines(LatLng tap) {
    final visible = _visibleAstroLines();
    if (visible.isEmpty) return const [];
    final cam = _mapCtrl.camera;
    return astro_lines.findNearbyLinesScreen(
      tapPx: cam.latLngToScreenOffset(tap),
      tapLatLng: tap,
      lines: visible,
      project: cam.latLngToScreenOffset,
      thresholdPx: 20,
    );
  }

  /// 天頂マーカーを表示するフレーム集合。
  /// 各 aspect トグル ON でそのフレームの天頂シンボルが描画される。
  /// 動的フレーム (T/P/SA) は時間で動くので時刻スライダーと連動する。
  Set<astro_lines.AstroFrame> _zenithVisibleFrames() {
    final s = <astro_lines.AstroFrame>{};
    if (_astroLayers['aspect'] == true) s.add(astro_lines.AstroFrame.natal);
    if (_astroLayers['aspectTransit'] == true) s.add(astro_lines.AstroFrame.transit);
    if (_astroLayers['aspectProgressed'] == true) s.add(astro_lines.AstroFrame.progressed);
    if (_astroLayers['aspectSolarArc'] == true) s.add(astro_lines.AstroFrame.solarArc);
    return s;
  }

  /// 現在 ON の aspect レイヤートグルから可視フレーム集合を導き、_astroLinesCache を絞り込む。
  /// CCG (Tier A #5): natal/transit/progressed/solarArc を独立にトグルできる。
  List<astro_lines.AstroLine> _visibleAstroLines() {
    if (_astroLinesCache.isEmpty) return const [];
    final visibleFrames = <astro_lines.AstroFrame>{};
    if (_astroLayers['aspect'] == true) {
      visibleFrames.add(astro_lines.AstroFrame.natal);
    }
    if (_astroLayers['aspectTransit'] == true) {
      visibleFrames.add(astro_lines.AstroFrame.transit);
    }
    if (_astroLayers['aspectProgressed'] == true) {
      visibleFrames.add(astro_lines.AstroFrame.progressed);
    }
    if (_astroLayers['aspectSolarArc'] == true) {
      visibleFrames.add(astro_lines.AstroFrame.solarArc);
    }
    if (visibleFrames.isEmpty) return const [];
    return _astroLinesCache
        .where((l) => visibleFrames.contains(l.frame))
        .toList();
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

}
