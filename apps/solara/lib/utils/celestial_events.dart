import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Loads and provides celestial event data for intention generation.
class CelestialEvents {
  static Map<int, MonthEvents>? _months;

  static Future<void> initialize() async {
    if (_months != null) return;
    final jsonStr =
        await rootBundle.loadString('assets/celestial_events_2026.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final months = <int, MonthEvents>{};

    for (final m in data['months'] as List) {
      final map = m as Map<String, dynamic>;
      final month = map['month'] as int;
      months[month] = MonthEvents.fromJson(map);
    }
    _months = months;
  }

  /// Get events for a given month (1-12). Returns null if year not loaded.
  static MonthEvents? getMonth(int month) => _months?[month];

  /// Get intention themes for a month. Returns 3 choices in EN and JP.
  static ({List<String> en, List<String> jp}) getThemes(int month) {
    final m = _months?[month];
    if (m != null) {
      return (en: m.themesEN, jp: m.themesJP);
    }
    // Fallback generic themes
    return (
      en: [
        'Holding on to what no longer serves you',
        'Fear of the unknown',
        'Self-doubt that blocks growth',
      ],
      jp: [
        'もう役に立たないものへの執着',
        '未知への恐れ',
        '成長を妨げる自己疑念',
      ],
    );
  }
}

class MonthEvents {
  final int month;
  final String newMoonDate;
  final String newMoonSign;
  final String newMoonSignJP;
  final String fullMoonDate;
  final String fullMoonName;
  final String fullMoonNameJP;
  final List<CelestialEvent> events;
  final List<String> themesEN;
  final List<String> themesJP;

  const MonthEvents({
    required this.month,
    required this.newMoonDate,
    required this.newMoonSign,
    required this.newMoonSignJP,
    required this.fullMoonDate,
    required this.fullMoonName,
    required this.fullMoonNameJP,
    required this.events,
    required this.themesEN,
    required this.themesJP,
  });

  factory MonthEvents.fromJson(Map<String, dynamic> json) {
    final themes = json['themes'] as Map<String, dynamic>;
    return MonthEvents(
      month: json['month'] as int,
      newMoonDate: json['newMoonDate'] as String,
      newMoonSign: json['newMoonSign'] as String,
      newMoonSignJP: json['newMoonSignJP'] as String,
      fullMoonDate: json['fullMoonDate'] as String,
      fullMoonName: json['fullMoonName'] as String,
      fullMoonNameJP: json['fullMoonNameJP'] as String,
      events: (json['events'] as List)
          .map((e) => CelestialEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      themesEN: (themes['en'] as List).cast<String>(),
      themesJP: (themes['jp'] as List).cast<String>(),
    );
  }

  /// Format active events as a summary string.
  String eventSummary({String lang = 'en'}) {
    if (events.isEmpty) return '';
    return events
        .map((e) => lang == 'jp' ? e.descJP : e.desc)
        .join('\n');
  }
}

class CelestialEvent {
  final String type; // retrograde, ingress, eclipse, conjunction, node_shift
  final String planet;
  final String desc;
  final String descJP;

  const CelestialEvent({
    required this.type,
    required this.planet,
    required this.desc,
    required this.descJP,
  });

  factory CelestialEvent.fromJson(Map<String, dynamic> json) {
    return CelestialEvent(
      type: json['type'] as String,
      planet: json['planet'] as String,
      desc: json['desc'] as String,
      descJP: json['descJP'] as String,
    );
  }
}
