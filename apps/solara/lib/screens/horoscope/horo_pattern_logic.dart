import '../../utils/astro_math.dart';
import 'horo_constants.dart';

// ══════════════════════════════════════════════════
// Pattern Detection & 60-Day Prediction (pure functions)
// HTML: detectPatterns() + predictPatternCompletions()
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


  // Transit: approximate daily motion
  // Progressed (1day=1year): divide transit speed by 365.25
  double mockLon(int bodyIdx, int dayOffset) {
    const transitSpeeds = [1.0, 13.2, 1.2, 1.0, 0.5, 0.08, 0.03, 0.01, 0.006, 0.004];
    final factor = chartMode == 'np' ? 1.0 / 365.25 : 1.0;
    final speed = transitSpeeds[bodyIdx % 10] * factor;
    final baseLon = natal.values.elementAt(bodyIdx % natal.length);
    return normalize360(baseLon + speed * dayOffset + dayOffset * 0.1 * factor);
  }

  for (int i = 0; i < keys.length; i++) {
    for (int j = i + 1; j < keys.length; j++) {
      if (!personalKeys.contains(keys[i]) && !personalKeys.contains(keys[j])) continue;
      final dij = angDist(natal[keys[i]]!, natal[keys[j]]!);

      // Grand Trine completion
      if ((dij - 120).abs() <= 3) {
        final target = normalize360(natal[keys[i]]! + 120);
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
        final target = normalize360((natal[keys[i]]! + natal[keys[j]]!) / 2);
        for (int body = 0; body < 10; body++) {
          for (int day = 1; day <= daysAhead; day++) {
            final tLon = mockLon(body, day);
            if (angDist(tLon, target) <= 3 || angDist(tLon, normalize360(target + 180)) <= 3) {
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
        final target = normalize360(natal[keys[i]]! + 150);
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
