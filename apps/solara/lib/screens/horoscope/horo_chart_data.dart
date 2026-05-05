part of '../horoscope_screen.dart';

// ══════════════════════════════════════════════════
// Chart data generation + aspect/pattern logic
// horoscope_screen.dart の part として HoroscopeScreenState の
// private field にアクセスして惑星配置・アスペクトを算出する。
// ══════════════════════════════════════════════════

extension _HoroChartData on HoroscopeScreenState {
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
    // transit ASC/MC — rotates rapidly with time of day
    final hourFrac = (now.hour + now.minute / 60.0) / 24.0;
    _secondaryAsc = (hourFrac * 360 + rng.nextDouble() * 30) % 360;
    _secondaryMc = (_secondaryAsc! + 90 + rng.nextDouble() * 10 - 5) % 360;
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
    // progressed ASC/MC — slowly advances from natal (~1° per year)
    _secondaryAsc = (_asc + yearsLived + rng.nextDouble() * 5) % 360;
    _secondaryMc = (_mc + yearsLived + rng.nextDouble() * 3) % 360;
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
    final diff = angDist(lon1, lon2);
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

  /// モードに合致するパターンのみ抽出 (メモ化対応)
  /// single: N-Nのみ, nt: Tを含むもののみ, np: Pを含むもののみ
  Map<String, List<Map<String, dynamic>>> _modeFilteredPatterns() {
    _refreshCacheKey();
    _cachedDetectPatterns ??= detectPatterns(
      _natalPlanets, secondary: _secondaryPlanets, chartMode: _chartMode);
    final all = _cachedDetectPatterns!;
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

  /// 指定モードで成立する特殊アスペクトを取得 (メモ化対応)
  Map<String, List<Map<String, dynamic>>> _patternsForMode(String mode) {
    _refreshCacheKey();
    final cached = _patternsForModeCache[mode];
    if (cached != null) return cached;
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
    _patternsForModeCache[mode] = result;
    return result;
  }

  /// 60日予測 (メモ化対応 — natal/mode が変わらなければ再計算しない)
  List<Map<String, dynamic>> _memoizedPredictions() {
    if (_chartMode == 'single') return [];
    _refreshCacheKey();
    if (_cachedPredictions != null && _predictionsCacheMode == _chartMode) {
      return _cachedPredictions!;
    }
    _cachedPredictions = predictPatternCompletions(
      _natalPlanets, chartMode: _chartMode);
    _predictionsCacheMode = _chartMode;
    return _cachedPredictions!;
  }

  /// パターン表示フィルタ（個別 ON/OFF + モードフィルタ）
  /// _hiddenPatterns に含まれるキーのパターンは除外する。
  Map<String, List<Map<String, dynamic>>> _visiblePatterns() {
    final filtered = _modeFilteredPatterns();
    return {
      for (final type in ['grandtrine', 'tsquare', 'yod'])
        type: (filtered[type] ?? [])
            .where((p) => !_hiddenPatterns.contains(horoActivePatternKey(type, p)))
            .toList(),
    };
  }
}
