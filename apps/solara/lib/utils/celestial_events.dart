import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

/// Loads and provides celestial event data for intention generation.
///
/// データソース:
/// - themes (意図テーマ): 静的JSON `assets/celestial_events_2026.json` (手書きコンテンツ)
/// - events (天体イベント): CF Worker `/astro/events` でリアル計算 (astronomy-engine)
///   → API失敗時は静的JSONにfallback
class CelestialEvents {
  static Map<int, MonthEvents>? _months;
  static const _workerBase = 'https://solara-api.solodev-lab.workers.dev';

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

  /// CF Worker にリアル計算を要求。失敗時は静的JSONを返す。
  /// 成功時: 静的JSONのthemes + リアル計算events で更新したMonthEvents
  static Future<MonthEvents?> fetchMonthEvents(int year, int month) async {
    if (_months == null) await initialize();
    final cached = _months?[month];
    try {
      final uri = Uri.parse('$_workerBase/astro/events?year=$year&month=$month');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        final apiEvents = (body['events'] as List)
            .map((e) => CelestialEvent.fromJson(e as Map<String, dynamic>))
            .toList();
        if (cached != null) {
          return cached.copyWithEvents(apiEvents);
        }
      }
    } catch (_) { /* network error → fallback */ }
    return cached;
  }

  /// Get events for a given month (1-12). Returns null if year not loaded.
  /// (同期版 - 静的JSONのみ使用。リアル計算が欲しい場合は fetchMonthEvents を使う)
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
  /// localDescJP/localDesc を使用 → UTC→端末ローカル日付で正しく表示
  String eventSummary({String lang = 'en'}) {
    if (events.isEmpty) return '';
    return events
        .map((e) => lang == 'jp' ? e.localDescJP : e.localDesc)
        .join('\n');
  }

  /// API経由のリアル計算eventsで置換した新MonthEventsを返す
  MonthEvents copyWithEvents(List<CelestialEvent> newEvents) {
    return MonthEvents(
      month: month,
      newMoonDate: newMoonDate,
      newMoonSign: newMoonSign,
      newMoonSignJP: newMoonSignJP,
      fullMoonDate: fullMoonDate,
      fullMoonName: fullMoonName,
      fullMoonNameJP: fullMoonNameJP,
      events: newEvents,
      themesEN: themesEN,
      themesJP: themesJP,
    );
  }
}

class CelestialEvent {
  final String type; // retrograde, ingress, eclipse, conjunction, node_shift
  final String planet;
  final String desc; // (legacy / fallback) 完成済みの説明文
  final String descJP; // (legacy / fallback) 完成済みの説明文

  // API からの追加フィールド (dateはUTC ISO, テンプレートは日付抜き)
  final String? dateISO; // UTC ISO8601
  final String? planetEN;
  final String? planetJP;
  final String? sign;
  final String? signJP;
  final String? descTemplate; // 例: '{planet} enters {sign}'
  final String? descTemplateJP; // 例: '{planet}が{sign}へ移行'

  const CelestialEvent({
    required this.type,
    required this.planet,
    required this.desc,
    required this.descJP,
    this.dateISO,
    this.planetEN,
    this.planetJP,
    this.sign,
    this.signJP,
    this.descTemplate,
    this.descTemplateJP,
  });

  factory CelestialEvent.fromJson(Map<String, dynamic> json) {
    return CelestialEvent(
      type: json['type'] as String,
      planet: json['planet'] as String,
      desc: (json['desc'] ?? '') as String,
      descJP: (json['descJP'] ?? '') as String,
      dateISO: json['date'] as String?,
      planetEN: json['planetEN'] as String?,
      planetJP: json['planetJP'] as String?,
      sign: json['sign'] as String?,
      signJP: json['signJP'] as String?,
      descTemplate: json['descTemplate'] as String?,
      descTemplateJP: json['descTemplateJP'] as String?,
    );
  }

  /// dateISO (UTC) を端末のローカルタイムに変換
  DateTime? get localDate {
    if (dateISO == null) return null;
    return DateTime.parse(dateISO!).toLocal();
  }

  /// ローカル日付で動的組み立てした日本語説明
  /// 例: '天王星が双子座へ移行（4/26）'
  /// APIからの descTemplateJP がある場合に使用、無ければ legacy descJP を返す
  String get localDescJP {
    if (descTemplateJP != null && planetJP != null && signJP != null) {
      final ld = localDate;
      final dateSuffix = ld != null ? '（${ld.month}/${ld.day}）' : '';
      return descTemplateJP!
              .replaceAll('{planet}', planetJP!)
              .replaceAll('{sign}', signJP!) +
          dateSuffix;
    }
    return descJP;
  }

  /// ローカル日付で動的組み立てした英語説明
  String get localDesc {
    if (descTemplate != null && planetEN != null && sign != null) {
      final ld = localDate;
      final dateSuffix = ld != null ? ' (${ld.month}/${ld.day})' : '';
      return descTemplate!
              .replaceAll('{planet}', planetEN!)
              .replaceAll('{sign}', sign!) +
          dateSuffix;
    }
    return desc;
  }
}
