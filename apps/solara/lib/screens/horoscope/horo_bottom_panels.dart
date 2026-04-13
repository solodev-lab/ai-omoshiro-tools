import 'package:flutter/material.dart';

import '../../utils/solara_storage.dart';
import 'horo_constants.dart';

// ══════════════════════════════════════════════════
// Birth Section (BS tab)
// HTML: #bsBirth — profile info display
// ══════════════════════════════════════════════════

class HoroBirthPanel extends StatelessWidget {
  final SolaraProfile profile;
  const HoroBirthPanel({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('⚙ BIRTH DATA', style: TextStyle(fontSize: 12, color: Color(0xFFF6BD60), letterSpacing: 1)),
      const SizedBox(height: 10),
      _bsInfoRow('氏名 NAME', p.name.isEmpty ? '未設定' : p.name),
      _bsInfoRow('生年月日 DATE', p.birthDate),
      _bsInfoRow('出生時刻 TIME', p.birthTimeUnknown ? '不明' : p.birthTime),
      _bsInfoRow('出生地 BIRTHPLACE', p.birthPlace.isEmpty ? '未設定' : p.birthPlace),
      if (p.birthLat != 0) ...[
        _bsInfoRow('緯度/経度', '${p.birthLat.toStringAsFixed(4)} / ${p.birthLng.toStringAsFixed(4)}'),
      ],
      const SizedBox(height: 8),
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
}

// ══════════════════════════════════════════════════
// Transit Section (BS tab)
// HTML: #bsTransit — transit date/time/location
// ══════════════════════════════════════════════════

class HoroTransitPanel extends StatelessWidget {
  final String chartMode;
  const HoroTransitPanel({super.key, required this.chartMode});

  @override
  Widget build(BuildContext context) {
    final label = chartMode == 'np' ? 'プログレス更新' : 'トランジット更新';
    final btnColor = chartMode == 'np' ? const Color(0xFFB088FF) : const Color(0xFF6BB5FF);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(chartMode == 'np' ? '☽ PROGRESSED DATA' : '☾ TRANSIT DATA',
        style: const TextStyle(fontSize: 12, color: Color(0xFFF6BD60), letterSpacing: 1)),
      const SizedBox(height: 10),
      _bsInfoRow('日付 DATE', DateTime.now().toString().split(' ')[0]),
      _bsInfoRow('時刻 TIME', '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}'),
      const SizedBox(height: 8),
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

  Widget _bsInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888888), letterSpacing: 1)),
        const SizedBox(height: 3),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
}

// ══════════════════════════════════════════════════
// Planet Table
// HTML: .planet-row
// ══════════════════════════════════════════════════

class HoroPlanetTable extends StatelessWidget {
  final Map<String, double> natalPlanets;
  final double asc, mc;
  final bool birthTimeUnknown;
  const HoroPlanetTable({super.key, required this.natalPlanets, required this.asc, required this.mc, required this.birthTimeUnknown});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Align(
        alignment: Alignment.centerLeft,
        child: Text('☉ PLANET POSITIONS', style: TextStyle(
          fontSize: 12, color: Color(0xFFF6BD60), letterSpacing: 1)),
      ),
      const SizedBox(height: 10),
      if (!birthTimeUnknown) ...[
        _planetRow('ASC', 'ASC', asc),
        _planetRow('MC', 'MC', mc),
        _planetRow('DSC', 'DSC', (asc + 180) % 360),
        _planetRow('IC', 'IC', (mc + 180) % 360),
        Container(height: 1, color: const Color(0x0AFFFFFF), margin: const EdgeInsets.symmetric(vertical: 4)),
      ],
      ...natalPlanets.entries.map((e) => _planetRow(
        planetNamesJP[e.key] ?? e.key,
        planetGlyphs[e.key] ?? '?',
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
        SizedBox(width: 24, child: Text(glyph, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center)),
        SizedBox(width: 60, child: Text(name, style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12))),
        Text(signs[signIdx], style: TextStyle(color: Color(signColors[signIdx]), fontSize: 14)),
        const SizedBox(width: 4),
        Text('${deg.toStringAsFixed(1)}°', style: const TextStyle(
          color: Color(0xFFE8E0D0), fontFamily: 'Courier New', fontSize: 12)),
        const SizedBox(width: 4),
        Text(signNames[signIdx], style: TextStyle(
          color: Color(signColors[signIdx]).withAlpha(180), fontSize: 10)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════
// Filter Panel
// HTML: .filter-section, .filter-chips, .filter-chip
// ══════════════════════════════════════════════════

class HoroFilterPanel extends StatelessWidget {
  final Map<String, bool> qualityFilters;
  final Map<String, bool> pgroupFilters;
  final String? fortuneFilter;
  final VoidCallback onReset;
  final void Function(String key, bool value) onQualityChanged;
  final void Function(String key, bool value) onPgroupChanged;
  final ValueChanged<String?> onFortuneChanged;

  const HoroFilterPanel({
    super.key,
    required this.qualityFilters,
    required this.pgroupFilters,
    required this.fortuneFilter,
    required this.onReset,
    required this.onQualityChanged,
    required this.onPgroupChanged,
    required this.onFortuneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('ASPECT FILTER', style: TextStyle(fontSize: 11, color: Color(0xFF888888), letterSpacing: 1.5)),
        GestureDetector(
          onTap: onReset,
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
        _filterChip('ソフト（調和）', 'soft', const Color(0xFFC9A84C), qualityFilters['soft']!, (v) => onQualityChanged('soft', v)),
        _filterChip('ハード（緊張）', 'hard', const Color(0xFF6B5CE7), qualityFilters['hard']!, (v) => onQualityChanged('hard', v)),
        _filterChip('中立', 'neutral', const Color(0xFF26D0CE), qualityFilters['neutral']!, (v) => onQualityChanged('neutral', v)),
      ]),

      // B: Fortune Category
      _filterSection('B', '運勢カテゴリ', [
        _exclusiveChip('癒し', 'healing', const Color(0xFF26D0CE)),
        _exclusiveChip('金運', 'money', const Color(0xFFFFD370)),
        _exclusiveChip('恋愛運', 'love', const Color(0xFFFF6B9D)),
        _exclusiveChip('仕事運', 'career', const Color(0xFFFF8C42)),
        _exclusiveChip('コミュニケーション', 'communication', const Color(0xFF6BB5FF)),
      ]),

      // C: Planet Group
      _filterSection('C', '惑星グループ', [
        _filterChip('個人天体', 'personal', const Color(0xFFFFD370), pgroupFilters['personal']!, (v) => onPgroupChanged('personal', v)),
        _filterChip('社会天体', 'social', const Color(0xFF6BB5FF), pgroupFilters['social']!, (v) => onPgroupChanged('social', v)),
        _filterChip('世代天体', 'generational', const Color(0xFFB088FF), pgroupFilters['generational']!, (v) => onPgroupChanged('generational', v)),
      ]),
    ]);
  }

  Widget _filterSection(String badge, String title, List<Widget> chips) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0DFFFFFF))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
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
        Wrap(spacing: 4, runSpacing: 4, children: chips),
      ]),
    );
  }

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

  Widget _exclusiveChip(String label, String key, Color color) {
    final active = fortuneFilter == key;
    return GestureDetector(
      onTap: () => onFortuneChanged(active ? null : key),
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
}

// ══════════════════════════════════════════════════
// Aspect List
// HTML: aspect-lists-row in analysis-body
// ══════════════════════════════════════════════════

class HoroAspectList extends StatelessWidget {
  final List<Map<String, dynamic>> filteredAspects;
  final Set<String> hiddenAspects;
  final ValueChanged<String> onToggleAspect;
  const HoroAspectList({super.key, required this.filteredAspects, required this.hiddenAspects, required this.onToggleAspect});

  // Handle both planet keys and angle keys (asc/mc/dsc/ic)
  String _glyphFor(String key) => planetGlyphs[key] ?? angleGlyphs[key] ?? key.toUpperCase();
  String _nameFor(String key) => planetNamesJP[key] ?? angleNamesJP[key] ?? key.toUpperCase();

  @override
  Widget build(BuildContext context) {
    if (filteredAspects.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('アスペクトなし', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('△ ASPECTS (${filteredAspects.length})', style: const TextStyle(
        fontSize: 12, color: Color(0xFFF6BD60), letterSpacing: 1)),
      const SizedBox(height: 8),
      ...filteredAspects.take(15).map((a) {
        final key = '${a['type']}_${a['p1']}_${a['p2']}';
        final isHidden = hiddenAspects.contains(key);
        final isDimmed = a['dimmed'] as bool? ?? false;
        final isOff = isHidden || isDimmed;
        return GestureDetector(
          onTap: () => onToggleAspect(key),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0x08FFFFFF))),
            ),
            child: Opacity(
              opacity: isOff ? 0.25 : 1.0,
              child: Row(children: [
                SizedBox(width: 16, child: Text(isHidden ? '○' : '●',
                  style: TextStyle(fontSize: 14, color: isOff ? const Color(0xFF555555) : (a['color'] as Color)),
                  textAlign: TextAlign.center)),
                const SizedBox(width: 4),
                Text('${_glyphFor(a['p1'] as String)} ${_nameFor(a['p1'] as String)}',
                  style: const TextStyle(color: Color(0xFFE8E0D0), fontSize: 12)),
                Text(' — ', style: TextStyle(color: (a['color'] as Color).withAlpha(180), fontSize: 12)),
                Text('${_glyphFor(a['p2'] as String)} ${_nameFor(a['p2'] as String)}',
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
                  child: Text(
                    '${aspectSymbol[a['type']] ?? ''} ${aspectNameJP[a['type']] ?? a['type']}${(a['aspectAngle'] as double?)?.toInt() ?? 0}°',
                    style: TextStyle(color: a['color'] as Color, fontSize: 9)),
                ),
              ]),
            ),
          ),
        );
      }),
      if (filteredAspects.length > 15)
        Padding(padding: const EdgeInsets.only(top: 4),
          child: Text('... 他${filteredAspects.length - 15}件',
            style: const TextStyle(color: Color(0x99888888), fontSize: 10))),
    ]);
  }
}

// ══════════════════════════════════════════════════
// Pattern Detection & 60-Day Prediction Panel
// HTML: detectPatterns() + predictPatternCompletions() + renderPredictions()
// ══════════════════════════════════════════════════

/// HTML: detectPatterns(aspects, natal, secondary)
/// Detect Grand Trine / T-Square / Yod from natal + optional secondary pool.
/// Each planet entry carries source ('N' or 'T'/'P') for display.
/// [chartMode]: 'single' = natal only, 'nt' = natal+transit, 'np' = natal+progressed
Map<String, List<Map<String, dynamic>>> detectPatterns(
  Map<String, double> natal, {
  Map<String, double>? secondary,
  String chartMode = 'single',
}) {
  final patterns = <String, List<Map<String, dynamic>>>{'grandtrine': [], 'tsquare': [], 'yod': []};
  final personalKeys = {'sun', 'moon', 'mercury', 'venus', 'mars'};

  // Build pool: each entry = {key, lon, source}
  final pool = <Map<String, dynamic>>[];
  for (final e in natal.entries) {
    pool.add({'key': e.key, 'lon': e.value, 'source': 'N'});
  }
  if (secondary != null && chartMode != 'single') {
    final src = chartMode == 'np' ? 'P' : 'T';
    for (final e in secondary.entries) {
      pool.add({'key': e.key, 'lon': e.value, 'source': src});
    }
  }

  double angDist(double a, double b) {
    final d = (a - b).abs() % 360;
    return d > 180 ? 360 - d : d;
  }
  bool hasPersonal(List<Map<String, dynamic>> trio) =>
    trio.any((p) => personalKeys.contains(p['key']));
  // HTML: countNatal >= 2
  bool enoughNatal(List<Map<String, dynamic>> trio) =>
    trio.where((p) => p['source'] == 'N').length >= 2;
  String triKey(List<Map<String, dynamic>> trio) {
    final keys = trio.map((p) => '${p['source']}${p['key']}').toList()..sort();
    return keys.join(',');
  }

  final po = patternOrbSettings;
  final seen = <String>{};

  for (int i = 0; i < pool.length; i++) {
    for (int j = i + 1; j < pool.length; j++) {
      final dij = angDist(pool[i]['lon'] as double, pool[j]['lon'] as double);

      // Grand Trine: 120° between each pair
      if ((dij - 120).abs() <= po['grandtrine']!) {
        for (int k = j + 1; k < pool.length; k++) {
          if ((angDist(pool[i]['lon'] as double, pool[k]['lon'] as double) - 120).abs() > po['grandtrine']!) continue;
          if ((angDist(pool[j]['lon'] as double, pool[k]['lon'] as double) - 120).abs() > po['grandtrine']!) continue;
          final trio = [pool[i], pool[j], pool[k]];
          if (!hasPersonal(trio) || !enoughNatal(trio)) continue;
          final tk = triKey(trio);
          if (seen.contains(tk)) continue;
          seen.add(tk);
          patterns['grandtrine']!.add({
            'planets': trio.map((p) => p['key'] as String).toList(),
            'sources': trio.map((p) => p['source'] as String).toList(),
          });
        }
      }

      // T-Square: 180° opp + 2×90° sq
      if ((dij - 180).abs() <= po['tsquare_opp']!) {
        for (int k = 0; k < pool.length; k++) {
          if (k == i || k == j) continue;
          if ((angDist(pool[i]['lon'] as double, pool[k]['lon'] as double) - 90).abs() > po['tsquare_sq']!) continue;
          if ((angDist(pool[j]['lon'] as double, pool[k]['lon'] as double) - 90).abs() > po['tsquare_sq']!) continue;
          final trio = [pool[i], pool[j], pool[k]];
          if (!hasPersonal(trio) || !enoughNatal(trio)) continue;
          final tk = triKey(trio);
          if (seen.contains(tk)) continue;
          seen.add(tk);
          patterns['tsquare']!.add({
            'planets': trio.map((p) => p['key'] as String).toList(),
            'sources': trio.map((p) => p['source'] as String).toList(),
            'apex': pool[k]['key'],
          });
        }
      }

      // Yod: 60° sextile + 2×150° quincunx
      if ((dij - 60).abs() <= po['yod_sextile']!) {
        for (int k = 0; k < pool.length; k++) {
          if (k == i || k == j) continue;
          if ((angDist(pool[i]['lon'] as double, pool[k]['lon'] as double) - 150).abs() > po['yod_quincunx']!) continue;
          if ((angDist(pool[j]['lon'] as double, pool[k]['lon'] as double) - 150).abs() > po['yod_quincunx']!) continue;
          final trio = [pool[i], pool[j], pool[k]];
          if (!hasPersonal(trio) || !enoughNatal(trio)) continue;
          final tk = triKey(trio);
          if (seen.contains(tk)) continue;
          seen.add(tk);
          patterns['yod']!.add({
            'planets': trio.map((p) => p['key'] as String).toList(),
            'sources': trio.map((p) => p['source'] as String).toList(),
            'apex': pool[k]['key'],
          });
        }
      }
    }
  }

  return patterns;
}

/// Mock 60-day prediction — find when transit/progressed planets complete patterns
/// [chartMode]: 'nt' = transit speeds, 'np' = progressed speeds (1day=1year → very slow)
List<Map<String, dynamic>> predictPatternCompletions(Map<String, double> natal, {int daysAhead = 60, String chartMode = 'nt'}) {
  final predictions = <Map<String, dynamic>>[];
  final keys = natal.keys.toList();
  final personalKeys = {'sun', 'moon', 'mercury', 'venus', 'mars'};
  final now = DateTime.now();
  final sourceLabel = chartMode == 'np' ? 'P' : 'T';

  double angDist(double a, double b) {
    final d = (a - b).abs() % 360;
    return d > 180 ? 360 - d : d;
  }
  double norm360(double v) => ((v % 360) + 360) % 360;

  // Transit: approximate daily motion
  // Progressed (1day=1year): divide transit speed by 365.25
  double mockLon(int bodyIdx, int dayOffset) {
    const transitSpeeds = [1.0, 13.2, 1.2, 1.0, 0.5, 0.08, 0.03, 0.01, 0.006, 0.004];
    final factor = chartMode == 'np' ? 1.0 / 365.25 : 1.0;
    final speed = transitSpeeds[bodyIdx % 10] * factor;
    final baseLon = natal.values.elementAt(bodyIdx % natal.length);
    return norm360(baseLon + speed * dayOffset + dayOffset * 0.1 * factor);
  }

  for (int i = 0; i < keys.length; i++) {
    for (int j = i + 1; j < keys.length; j++) {
      if (!personalKeys.contains(keys[i]) && !personalKeys.contains(keys[j])) continue;
      final dij = angDist(natal[keys[i]]!, natal[keys[j]]!);

      // Grand Trine completion
      if ((dij - 120).abs() <= 3) {
        final target = norm360(natal[keys[i]]! + 120);
        for (int body = 0; body < 10; body++) {
          for (int day = 1; day <= daysAhead; day++) {
            final tLon = mockLon(body, day);
            if (angDist(tLon, target) <= 3) {
              predictions.add({
                'type': 'grandtrine', 'natalPair': [keys[i], keys[j]],
                'transitBody': keys.length > body ? keys[body] : 'sun', 'source': sourceLabel,
                'daysUntil': day,
                'dateEstimate': now.add(Duration(days: day)),
              });
              break;
            }
          }
        }
      }

      // T-Square completion
      if ((dij - 180).abs() <= 3) {
        final target = norm360((natal[keys[i]]! + natal[keys[j]]!) / 2);
        for (int body = 0; body < 10; body++) {
          for (int day = 1; day <= daysAhead; day++) {
            final tLon = mockLon(body, day);
            if (angDist(tLon, target) <= 3 || angDist(tLon, norm360(target + 180)) <= 3) {
              predictions.add({
                'type': 'tsquare', 'natalPair': [keys[i], keys[j]],
                'transitBody': keys.length > body ? keys[body] : 'sun', 'source': sourceLabel,
                'daysUntil': day,
                'dateEstimate': now.add(Duration(days: day)),
              });
              break;
            }
          }
        }
      }

      // Yod completion
      if ((dij - 60).abs() <= 2.5) {
        final target = norm360(natal[keys[i]]! + 150);
        for (int body = 0; body < 10; body++) {
          for (int day = 1; day <= daysAhead; day++) {
            final tLon = mockLon(body, day);
            if (angDist(tLon, target) <= 2.5) {
              predictions.add({
                'type': 'yod', 'natalPair': [keys[i], keys[j]],
                'transitBody': keys.length > body ? keys[body] : 'sun', 'source': sourceLabel,
                'daysUntil': day,
                'dateEstimate': now.add(Duration(days: day)),
              });
              break;
            }
          }
        }
      }
    }
  }

  predictions.sort((a, b) => (a['daysUntil'] as int).compareTo(b['daysUntil'] as int));
  return predictions.take(5).toList();
}

/// Prediction panel widget
class HoroPredictionPanel extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> activePatterns;
  final List<Map<String, dynamic>> predictions;
  final Map<String, bool> patternVisible;
  final void Function(String type, bool value) onPatternToggle;
  const HoroPredictionPanel({
    super.key,
    required this.activePatterns,
    required this.predictions,
    required this.patternVisible,
    required this.onPatternToggle,
  });

  @override
  Widget build(BuildContext context) {
    final hasActive = activePatterns.values.any((l) => l.isNotEmpty);
    if (!hasActive && predictions.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('✦ PATTERN PREDICTIONS', style: TextStyle(
        fontSize: 12, color: Color(0xFFF6BD60), letterSpacing: 1)),
      const SizedBox(height: 8),

      // Pattern visibility toggles
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final type in ['grandtrine', 'tsquare', 'yod'])
          if ((activePatterns[type] ?? []).isNotEmpty || predictions.any((p) => p['type'] == type))
            _patternToggle(type),
      ]),
      const SizedBox(height: 8),

      // Active patterns (OFFなら暗く表示)
      for (final type in ['grandtrine', 'tsquare', 'yod'])
        for (final p in activePatterns[type] ?? [])
          Opacity(
            opacity: (patternVisible[type] ?? true) ? 1.0 : 0.25,
            child: _activeItem(type, p),
          ),

      // Upcoming predictions (OFFなら暗く表示)
      for (final pred in predictions)
        Opacity(
          opacity: (patternVisible[pred['type']] ?? true) ? 1.0 : 0.25,
          child: _predictionItem(pred),
        ),
    ]);
  }

  Widget _patternToggle(String type) {
    final style = patternStyles[type]!;
    final color = Color(style['color'] as int);
    final visible = patternVisible[type] ?? true;
    return GestureDetector(
      onTap: () => onPatternToggle(type, !visible),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: visible ? color : const Color(0x1AFFFFFF)),
          color: visible ? color.withAlpha(25) : const Color(0x08FFFFFF),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(visible ? '●' : '○', style: TextStyle(fontSize: 10, color: visible ? color : const Color(0xFF555555))),
          const SizedBox(width: 4),
          Text(style['labelJP'] as String, style: TextStyle(fontSize: 10, color: visible ? color : const Color(0xFF888888))),
        ]),
      ),
    );
  }

  Widget _activeItem(String type, Map<String, dynamic> pattern) {
    final style = patternStyles[type]!;
    final color = Color(style['color'] as int);
    final pKeys = pattern['planets'] as List<String>;
    final sources = pattern['sources'] as List<String>? ?? List.filled(pKeys.length, 'N');
    final planets = List.generate(pKeys.length, (i) =>
      '${sources[i]}${planetGlyphs[pKeys[i]] ?? pKeys[i]}').join(' ');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x08FFFFFF)))),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: color.withAlpha(34), borderRadius: BorderRadius.circular(4)),
          child: Text(style['labelJP'] as String, style: TextStyle(fontSize: 10, color: color)),
        ),
        const SizedBox(width: 8),
        Text(planets, style: const TextStyle(fontSize: 11, color: Color(0xFFCCCCCC))),
        const Spacer(),
        const Text('✔ 成立中', style: TextStyle(fontSize: 10, color: Color(0xFFC9A84C))),
      ]),
    );
  }

  Widget _predictionItem(Map<String, dynamic> pred) {
    final type = pred['type'] as String;
    final style = patternStyles[type]!;
    final color = Color(style['color'] as int);
    final days = pred['daysUntil'] as int;
    final date = pred['dateEstimate'] as DateTime;
    final timeLabel = days < 1 ? 'まもなく' : '${days}日後';
    final dateStr = '${date.year}/${date.month}/${date.day}';
    final p1 = planetGlyphs[pred['natalPair'][0]] ?? '';
    final p2 = planetGlyphs[pred['natalPair'][1]] ?? '';
    final tBody = planetGlyphs[pred['transitBody']] ?? '';
    final src = pred['source'] as String? ?? 'T';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x08FFFFFF)))),
      child: Row(children: [
        Container(width: 6, height: 6, decoration: const BoxDecoration(
          shape: BoxShape.circle, color: Color(0xFFF6BD60))),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: color.withAlpha(34), borderRadius: BorderRadius.circular(4)),
          child: Text(style['labelJP'] as String, style: TextStyle(fontSize: 10, color: color)),
        ),
        const SizedBox(width: 6),
        Text('N$p1-N$p2 + $src$tBody', style: const TextStyle(fontSize: 10, color: Color(0xFFCCCCCC))),
        const Spacer(),
        Text(timeLabel, style: const TextStyle(fontSize: 10, color: Color(0xFFF6BD60))),
        const SizedBox(width: 4),
        Text(dateStr, style: const TextStyle(fontSize: 9, color: Color(0xFF666666))),
      ]),
    );
  }
}
