import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/solara_storage.dart';
import '../utils/fortune_api.dart';

import 'horoscope/horo_constants.dart';
import 'horoscope/horo_chart_painter.dart';
import 'horoscope/horo_fortune_cards.dart';
import 'horoscope/horo_bottom_panels.dart';
import 'horoscope/horo_ornament_painter.dart';
import 'horoscope/horo_antique_icons.dart';
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

  // HTML: bottom sheet 3-state: mini(52px) / half(~280px) / full(~500px)
  int _bsState = 1; // 0=mini, 1=half, 2=full

  // Bottom sheet — HTML: bs-tab: ⚙ 誕生 / ☾ 経過(hidden unless nt/np) / ☉ 天体 / ⚙ 絞込 / △ 相
  String _bsTab = 'birth';


  // Planet data (mock until CF Worker deployed)
  Map<String, double> _natalPlanets = {};
  Map<String, double> _secondaryPlanets = {}; // transit or progressed
  double _asc = 0, _mc = 0;
  // secondary (transit/progressed) ASC/MC — null if unused
  double? _secondaryAsc, _secondaryMc;
  List<Map<String, dynamic>> _aspects = [];

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
      _generateMockChart(p);
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
  void _applyWorkingProfile(SolaraProfile newProfile) {
    if (!newProfile.isComplete) return;
    setState(() {
      _workingProfile = newProfile;
      _birthTimeUnknown = newProfile.birthTimeUnknown;
      // チャート planets を再生成 (natal / secondary 両方)
      _generateMockChart(newProfile);
      if (_chartMode == 'nt') _generateTransitPlanets();
      else if (_chartMode == 'np') _generateProgressedPlanets();
      _recalcAspects();
      // Fortune は base のまま — 再取得しない
    });
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

    try {
      // 並列fetch
      final futures = fortuneCategories.map((cat) async {
        final id = cat['id'] as String;
        final reading = await fetchFortune(
          category: id,
          lang: 'ja',
          natal: _natalPlanets,
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
                const Spacer(),
                // HTML: .chart-menu-btn
                PopupMenuButton<String>(
                  onSelected: (mode) {
                    // HTML: setChartMode() — reset filters + generate secondary planets
                    _chartMode = mode;
                    _qualityFilters.updateAll((k, v) => true);
                    _pgroupFilters.updateAll((k, v) => true);
                    _fortuneFilter = null;
                    _secondaryAsc = null;
                    _secondaryMc = null;
                    if (mode == 'nt') { _generateTransitPlanets(); }
                    else if (mode == 'np') { _generateProgressedPlanets(); }
                    _recalcAspects();
                    _syncRotationByMode();
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
}
