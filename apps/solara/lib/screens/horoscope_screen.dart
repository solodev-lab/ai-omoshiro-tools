import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/astro_houses.dart' show assignPlanetHouse;
import '../utils/solara_storage.dart';
import '../utils/fortune_api.dart';

import 'horoscope/horo_constants.dart';
import 'horoscope/horo_chart_painter.dart';
import 'horoscope/horo_fortune_cards.dart';
import 'horoscope/horo_bottom_panels.dart';
import 'horoscope/horo_ornament_painter.dart';
import 'horoscope/horo_antique_icons.dart';
import 'horoscope/horo_relocation_panel.dart';
import 'map/map_astro.dart' show fetchChart, ChartResult;
import 'sanctuary/sanctuary_profile_editor.dart';

part 'horoscope/horo_chart_data.dart';
part 'horoscope/horo_backdrop.dart';
part 'horoscope/horo_chart_view.dart';
part 'horoscope/horo_bottom_sheet.dart';

class HoroscopeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToSanctuary;
  const HoroscopeScreen({super.key, this.onNavigateToSanctuary});
  @override
  State<HoroscopeScreen> createState() => HoroscopeScreenState();
}

// 星座画像のファイル名 (牡羊座=0, 牡牛座=1, ...)
const List<String> _zodiacFilenames = [
  'aries', 'taurus', 'gemini', 'cancer', 'leo', 'virgo',
  'libra', 'scorpio', 'sagittarius', 'capricorn', 'aquarius', 'pisces',
];

class HoroscopeScreenState extends State<HoroscopeScreen>
    with TickerProviderStateMixin {
  // ── 2-profile model ──
  // _baseProfile:    ストレージと同期。星読み (Fortune) 計算の基礎。
  // _workingProfile: 画面上で編集可能。チャート描画に使われる。
  // 編集されると _isEdited = true、画面離脱で base に戻る。
  SolaraProfile? _baseProfile;
  SolaraProfile? _workingProfile;
  // 便利getter — 既存コードで _profile 参照している所に影響なし
  SolaraProfile? get _profile => _workingProfile;
  bool get _isEdited => _baseProfile != null && _workingProfile != null &&
      !_profilesEqual(_baseProfile!, _workingProfile!);

  bool _loading = true;
  bool _birthTimeUnknown = false;

  // Breathing animation controller (4s cycle, sinusoidal 0..1..0)
  late final AnimationController _breathCtl;
  // Slow nebula parallax rotation (他のモード用・星読み画面では停止)
  late final AnimationController _rotCtl;
  // 星読み画面のスクロールで駆動される垂直シフト (px)
  final ValueNotifier<double> _readingParallax = ValueNotifier(0.0);
  final ScrollController _readingScrollCtl = ScrollController();

  // HTML: chartMode 'single' | 'nt' | 'np' | 'astrology'
  String _chartMode = 'single';

  // ハウス基準モード: false = 本質モード(出生地), true = 現実モード(現住所/relocate)
  // homeLat/Lng が有効なら loadProfile() でデフォルト true にする。
  bool _relocateMode = false;

  /// 現住所(homeLat/Lng)が有効値か(0/0でないか)
  bool get _hasValidHome {
    final p = _profile;
    return p != null && !(p.homeLat == 0 && p.homeLng == 0);
  }

  // HTML: bottom sheet 3-state: mini(52px) / half(~280px) / full(~500px)
  int _bsState = 1; // 0=mini, 1=half, 2=full

  // Bottom sheet — HTML: bs-tab: ⚙ 誕生 / ☾ 経過(hidden unless nt/np) / ☉ 天体 / ⚙ 絞込 / △ 相
  String _bsTab = 'birth';


  // Planet data — Worker /astro/chart 経由（接続失敗時のみモック乱数にフォールバック）
  final Map<String, double> _natalPlanets = {};
  Map<String, double> _secondaryPlanets = {}; // transit or progressed
  double _asc = 0, _mc = 0;
  // secondary (transit/progressed) ASC/MC — null if unused
  double? _secondaryAsc, _secondaryMc;
  // 12ハウス cusp度数配列（Placidus, [0]=1H, [9]=10H=MC等）。
  // birthTime 不明 / Worker接続失敗時は空配列。
  // _houses: 現在の表示で使うハウス（toggleの結果に応じて切替わる)
  // _natalHouses / _relocateHouses: 1重円+home有効時に並列fetchで両方保持
  // (リロケーション解説パネルで natal vs relocate を比較するため)
  List<double> _houses = [];
  List<double> _natalHouses = [];
  List<double> _relocateHouses = [];
  // 同様に asc/mc も両方保持
  double _natalAsc = 0, _natalMc = 0;
  double _relocateAsc = 0, _relocateMc = 0;
  List<Map<String, dynamic>> _aspects = [];

  /// 星読み(astrology)モードでは現実ベース固定。1重円・2重円ではトグル尊重。
  bool get _effectiveRelocateMode {
    if (_chartMode == 'astrology') return _hasValidHome; // 星読みは現実固定(homeあれば)
    return _relocateMode && _hasValidHome;
  }

  /// 惑星の黄経からハウス番号(1-12)を算出。
  /// houses 配列が空ならnullを返す（出生時刻不明 or API失敗時）。
  int? _planetHouse(double planetLon) => assignPlanetHouse(planetLon, _houses);

  // Aspect filters — HTML: activeFilters
  final Map<String, bool> _qualityFilters = {'soft': true, 'hard': true, 'neutral': true};
  final Map<String, bool> _pgroupFilters = {'personal': true, 'social': true, 'generational': true};
  String? _fortuneFilter;
  final Set<String> _hiddenAspects = {};
  // 個別パターン／予測の非表示キー (horoActivePatternKey / horoPredictionKey で付与)
  // デフォルト全表示。チェックを外すとキーが追加される。
  final Set<String> _hiddenPatterns = {};

  // ── メモ化キャッシュ (チャートや予測の重複計算を防止) ──
  String? _cacheKey;
  Map<String, List<Map<String, dynamic>>>? _cachedDetectPatterns;
  List<Map<String, dynamic>>? _cachedPredictions;
  String? _predictionsCacheMode;
  final Map<String, Map<String, List<Map<String, dynamic>>>> _patternsForModeCache = {};

  /// natal + secondary + chartMode の現在状態を表すキー
  String _currentCacheKey() {
    final sb = StringBuffer();
    const keys = ['sun','moon','mercury','venus','mars','jupiter','saturn','uranus','neptune','pluto'];
    for (final k in keys) {
      sb.write((_natalPlanets[k] ?? 0).toStringAsFixed(3));
      sb.write('|');
    }
    for (final k in keys) {
      sb.write((_secondaryPlanets[k] ?? 0).toStringAsFixed(3));
      sb.write('|');
    }
    sb.write(_chartMode);
    return sb.toString();
  }

  /// キャッシュを現在状態に合わせる (natal/secondary/mode が変わっていれば無効化)
  void _refreshCacheKey() {
    final k = _currentCacheKey();
    if (k != _cacheKey) {
      _cacheKey = k;
      _cachedDetectPatterns = null;
      _cachedPredictions = null;
      _predictionsCacheMode = null;
      _patternsForModeCache.clear();
    }
  }

  // Fortune readings (Gemini経由取得 / カテゴリ別キャッシュ)
  final Map<String, FortuneReading?> _fortunes = {};
  bool _fortuneLoading = false;
  String? _fortuneError;
  DateTime? _fortuneFetchedAt;

  @override
  void initState() {
    super.initState();
    // 6秒周期 (呼吸テンポを落として自然に)
    _breathCtl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 6000),
    )..repeat(reverse: true);
    _rotCtl = AnimationController(
      vsync: this, duration: const Duration(seconds: 180),
    )..repeat();
    // 星読み画面でのスクロール量を監視 (パララックス用)
    _readingScrollCtl.addListener(() {
      _readingParallax.value = _readingScrollCtl.offset * 0.15;
    });
    loadProfile();
  }

  @override
  void dispose() {
    _breathCtl.dispose();
    _rotCtl.dispose();
    _readingScrollCtl.dispose();
    _readingParallax.dispose();
    super.dispose();
  }

  /// astrology (星読み) モード時に _rotCtl を停止、それ以外は再開
  void _syncRotationByMode() {
    if (_chartMode == 'astrology') {
      if (_rotCtl.isAnimating) _rotCtl.stop();
    } else {
      if (!_rotCtl.isAnimating) _rotCtl.repeat();
    }
  }

  Future<void> loadProfile() async {
    final p = await SolaraStorage.loadProfile();
    if (p != null && p.isComplete) {
      _birthTimeUnknown = p.birthTimeUnknown;
      // 現住所が登録されていればデフォルトで現実モード(リロケーション)を使う
      _relocateMode = !(p.homeLat == 0 && p.homeLng == 0);
      // Worker /astro/chart 取得 → 失敗時はモックにフォールバック
      await _fetchRealChart(p);
    }
    setState(() {
      _baseProfile = p;
      _workingProfile = p;
      _loading = false;
    });
    if (p != null && p.isComplete) {
      _loadFortunes();
    }
  }

  /// 編集後の profile を working 側にのみ反映。storage は触らない。
  Future<void> _applyWorkingProfile(SolaraProfile newProfile) async {
    if (!newProfile.isComplete) return;
    _workingProfile = newProfile;
    _birthTimeUnknown = newProfile.birthTimeUnknown;
    // チャートを再取得 (natal / secondary 両方)
    await _fetchRealChart(newProfile);
    if (!mounted) return;
    setState(() {
      _recalcAspects();
      // Fortune は base のまま — 再取得しない
    });
  }

  /// Worker /astro/chart からチャートを取得。失敗時はモック乱数にフォールバック。
  /// _natalPlanets / _secondaryPlanets / _asc / _mc / _houses を更新する。
  Future<void> _fetchRealChart(SolaraProfile p) async {
    // モード判定: nt なら transit, np なら progressed, それ以外は natal のみ
    String mode;
    switch (_chartMode) {
      case 'nt':
        mode = 'both'; // natal + transit
        break;
      case 'np':
        mode = 'both'; // natal + progressed
        break;
      default:
        mode = 'natal';
    }

    // 出生時刻不明なら正午で代用 (Worker側で houses が不完全になるのを許容)
    final birthTime = p.birthTimeUnknown ? '12:00' : p.birthTime;

    // 1重円+home有効時: natal/relocate 2本を並列fetchして両方保持
    // (リロケーション解説パネルで比較するため)
    // 他モード: 1本のみ (_effectiveRelocateMode に従う)
    final hasHome = !(p.homeLat == 0 && p.homeLng == 0);
    final wantBothCharts = _chartMode == 'single' && hasHome;

    ChartResult? chart;
    ChartResult? natalChart;
    ChartResult? relocateChart;

    if (wantBothCharts) {
      // 並列実行 (Worker計算は軽いので2倍にしてもUX影響は小さい)
      final results = await Future.wait([
        fetchChart(
          birthDate: p.birthDate, birthTime: birthTime,
          birthLat: p.birthLat, birthLng: p.birthLng,
          birthTz: p.birthTz, birthTzName: p.birthTzName,
          mode: mode, houseSystem: 'placidus',
        ),
        fetchChart(
          birthDate: p.birthDate, birthTime: birthTime,
          birthLat: p.birthLat, birthLng: p.birthLng,
          birthTz: p.birthTz, birthTzName: p.birthTzName,
          mode: mode, houseSystem: 'placidus',
          relocateLat: p.homeLat, relocateLng: p.homeLng,
        ),
      ]);
      natalChart = results[0];
      relocateChart = results[1];
      chart = _effectiveRelocateMode ? relocateChart : natalChart;
    } else {
      // 単一fetch
      final useRelocate = _effectiveRelocateMode;
      chart = await fetchChart(
        birthDate: p.birthDate,
        birthTime: birthTime,
        birthLat: p.birthLat,
        birthLng: p.birthLng,
        birthTz: p.birthTz,
        birthTzName: p.birthTzName,
        mode: mode,
        houseSystem: 'placidus',
        relocateLat: useRelocate ? p.homeLat : null,
        relocateLng: useRelocate ? p.homeLng : null,
      );
      // 単一fetchの場合は natal/relocate キャッシュは更新しない
      // (1重円に戻った時に再fetchで埋まる)
    }

    if (chart != null) {
      // API成功: 実データを格納
      _natalPlanets
        ..clear()
        ..addAll(chart.natal);
      _asc = chart.asc;
      _mc = chart.mc;
      _houses = p.birthTimeUnknown ? [] : List<double>.from(chart.houses);

      // 並列fetchの場合: natal/relocate 両方のhouses & ASC/MCをキャッシュ
      // (リロケーション解説パネルで比較するため)
      if (natalChart != null && relocateChart != null && !p.birthTimeUnknown) {
        _natalHouses = List<double>.from(natalChart.houses);
        _relocateHouses = List<double>.from(relocateChart.houses);
        _natalAsc = natalChart.asc;
        _natalMc = natalChart.mc;
        _relocateAsc = relocateChart.asc;
        _relocateMc = relocateChart.mc;
      } else if (!wantBothCharts) {
        // 単一fetch時はキャッシュをクリア(古い値が残らないように)
        _natalHouses = [];
        _relocateHouses = [];
      }

      if (_chartMode == 'nt' && chart.transit != null) {
        _secondaryPlanets = Map<String, double>.from(chart.transit!);
        // transit ASC/MC は Worker レスポンスに無いため近似計算（時間経過ベース）
        final hourFrac = (DateTime.now().hour + DateTime.now().minute / 60.0) / 24.0;
        _secondaryAsc = (hourFrac * 360) % 360;
        _secondaryMc = (_secondaryAsc! + 90) % 360;
      } else if (_chartMode == 'np' && chart.progressed != null) {
        _secondaryPlanets = Map<String, double>.from(chart.progressed!);
        final parts = p.birthDate.split('-').map(int.parse).toList();
        final birthDate = DateTime(parts[0], parts[1], parts[2]);
        final yearsLived = DateTime.now().difference(birthDate).inDays / 365.25;
        _secondaryAsc = (_asc + yearsLived) % 360;
        _secondaryMc = (_mc + yearsLived) % 360;
      } else {
        _secondaryPlanets = {};
        _secondaryAsc = null;
        _secondaryMc = null;
      }

      _recalcAspects();
    } else {
      // API失敗: モックにフォールバック
      _houses = [];
      _natalHouses = [];
      _relocateHouses = [];
      _generateMockChart(p);
      // モック時の progressed モードは別途乱数生成
      if (_chartMode == 'np') {
        _generateProgressedPlanets();
        _recalcAspects();
      }
    }
  }

  /// base に戻す (編集リセット)
  void _resetWorkingProfile() {
    if (_baseProfile == null) return;
    _applyWorkingProfile(_baseProfile!);
  }

  /// Profile Editor (Sanctuary共用) を push。結果をworking側にのみ反映。
  Future<void> _openProfileEditor() async {
    if (_workingProfile == null) return;
    final edited = await Navigator.of(context).push<SolaraProfile>(
      MaterialPageRoute(
        builder: (_) => SanctuaryProfileEditorPage(profile: _workingProfile),
      ),
    );
    if (edited != null) {
      // storage には保存しない — workingのみ更新
      _applyWorkingProfile(edited);
    }
  }

  /// 2つのプロファイルが同じか判定 (isEdited計算用)
  bool _profilesEqual(SolaraProfile a, SolaraProfile b) {
    return a.name == b.name &&
        a.birthDate == b.birthDate &&
        a.birthTime == b.birthTime &&
        a.birthTimeUnknown == b.birthTimeUnknown &&
        a.birthPlace == b.birthPlace &&
        a.birthLat == b.birthLat &&
        a.birthLng == b.birthLng &&
        a.birthTz == b.birthTz &&
        a.birthTzName == b.birthTzName;
  }

  // (画面離脱時の自動リセットは不要 — 他タブから戻ってくる時に
  // main.dart の _onTabTap が loadProfile() を呼び、_workingProfile が
  // _baseProfile で上書きされることで自動的にリセットされる)

  /// 全5カテゴリの占い文を並列取得 (Gemini API経由)
  /// 同日中は再取得しない (キャッシュ)
  Future<void> _loadFortunes({bool force = false}) async {
    if (_fortuneLoading) return;
    final today = DateTime.now();
    if (!force &&
        _fortuneFetchedAt != null &&
        _fortuneFetchedAt!.year == today.year &&
        _fortuneFetchedAt!.month == today.month &&
        _fortuneFetchedAt!.day == today.day &&
        _fortunes.length == fortuneCategories.length) {
      return; // 同日キャッシュ有効
    }
    setState(() {
      _fortuneLoading = true;
      _fortuneError = null;
    });

    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final aspects = _aspects
        .map((a) => {
              'p1': a['p1'],
              'p2': a['p2'],
              'type': a['type'],
              'quality': a['quality'],
              'diff': a['diff'],
              'aspectAngle': a['aspectAngle'],
              'orb': a['orb'],
            })
        .cast<Map<String, dynamic>>()
        .toList();
    // パターン情報をAPIに渡せる形式に整形
    final allPatterns = detectPatterns(_natalPlanets, secondary: _secondaryPlanets, chartMode: _chartMode);
    final patternsPayload = <String, List<Map<String, dynamic>>>{};
    for (final type in ['grandtrine', 'tsquare', 'yod']) {
      patternsPayload[type] = (allPatterns[type] ?? [])
          .map((p) => {
                'planets': (p['planets'] as List).cast<String>(),
              })
          .toList();
    }

    // 各惑星のハウス番号（1-12）。houses が空（出生時刻不明 / API失敗）なら null。
    final planetHouses = <String, int>{};
    if (_houses.length == 12) {
      for (final entry in _natalPlanets.entries) {
        final h = _planetHouse(entry.value);
        if (h != null) planetHouses[entry.key] = h;
      }
    }

    try {
      // 並列fetch
      final futures = fortuneCategories.map((cat) async {
        final id = cat['id'] as String;
        final reading = await fetchFortune(
          category: id,
          lang: 'ja',
          natal: _natalPlanets,
          planetHouses: planetHouses.isEmpty ? null : planetHouses,
          aspects: aspects,
          patterns: patternsPayload,
          date: dateStr,
          userName: _profile?.name,
        );
        return MapEntry(id, reading);
      }).toList();
      final results = await Future.wait(futures);
      if (!mounted) return;
      setState(() {
        _fortunes
          ..clear()
          ..addEntries(results);
        _fortuneFetchedAt = today;
        _fortuneLoading = false;
        // 全てnullなら失敗扱い
        if (results.every((e) => e.value == null)) {
          _fortuneError = 'Fortune API に接続できませんでした';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fortuneLoading = false;
        _fortuneError = '$e';
      });
    }
  }

  // ══════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _mysticalBackdrop(
        child: const Center(child: CircularProgressIndicator(color: Color(0xFFF6BD60))),
      );
    }
    if (!(_profile?.isComplete ?? false)) return _buildNoProfile();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _mysticalBackdrop(
        child: SafeArea(
          child: Column(children: [
            // ── Top bar with hamburger ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(children: [
                // ハウス基準モードトグル(本質/現実) — 出生地ハウス vs 現住所リロケーション
                // 星読みモードは現実固定なのでトグル非表示
                if (_chartMode != 'astrology') _buildHouseModeToggle(),
                const Spacer(),
                // HTML: .chart-menu-btn
                PopupMenuButton<String>(
                  onSelected: (mode) async {
                    // HTML: setChartMode() — reset filters + (re)fetch secondary planets
                    _chartMode = mode;
                    // 'relocate' タブは1重円のみ表示 → モード変更で誕生に戻す
                    if (_bsTab == 'relocate' && mode != 'single') _bsTab = 'birth';
                    _qualityFilters.updateAll((k, v) => true);
                    _pgroupFilters.updateAll((k, v) => true);
                    _fortuneFilter = null;
                    _secondaryAsc = null;
                    _secondaryMc = null;
                    // mode 切替で transit/progressed が必要 → /astro/chart 再取得
                    // また 'single' 入りで natal/relocate 両並列が必要、'astrology' 入りで現実固定切替
                    // → 'single' / 'astrology' に切り替わる時も再取得が必要
                    final p = _workingProfile;
                    if (p != null && p.isComplete) {
                      await _fetchRealChart(p);
                    } else {
                      _recalcAspects();
                    }
                    _syncRotationByMode();
                    if (mounted) setState(() {});
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
                  fortunes: _fortunes,
                  fortuneLoading: _fortuneLoading,
                  fortuneError: _fortuneError,
                  onRetry: () => _loadFortunes(force: true),
                  birthEdited: _isEdited,
                  scrollController: _readingScrollCtl,
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

  /// ハウス基準モードトグル: 本質(出生地) ⇔ 現実(現住所)
  /// homeLat/Lng が未設定なら「現実」側はdisabled (グレーアウト)。
  Widget _buildHouseModeToggle() {
    final hasHome = _hasValidHome;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xEB0C0C1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x4DF6BD60)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _toggleSegment(
          label: '本質',
          tooltip: '出生地ベースのハウス',
          active: !_relocateMode,
          enabled: true,
          onTap: () => _setRelocateMode(false),
        ),
        Container(width: 1, height: 20, color: const Color(0x4DF6BD60)),
        _toggleSegment(
          label: '現実',
          tooltip: hasHome ? '現住所ベースのハウス(リロケーション)' : 'サンクチュアリで現住所を設定してください',
          active: _relocateMode,
          enabled: hasHome,
          onTap: () => _setRelocateMode(true),
        ),
      ]),
    );
  }

  Widget _toggleSegment({
    required String label,
    required String tooltip,
    required bool active,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final fg = !enabled
        ? const Color(0x66ACACAC)
        : active
            ? const Color(0xFF0C0C1A)
            : const Color(0xFFACACAC);
    final bg = active && enabled ? const Color(0xFFF6BD60) : Colors.transparent;
    final w = Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: GoogleFonts.notoSansJp(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
    return Tooltip(message: tooltip, child: w);
  }

  Future<void> _setRelocateMode(bool value) async {
    if (_relocateMode == value) return;
    if (value && !_hasValidHome) return;
    setState(() => _relocateMode = value);
    final p = _workingProfile;
    if (p != null && p.isComplete) {
      await _fetchRealChart(p);
      if (mounted) setState(() {});
    }
  }
}
