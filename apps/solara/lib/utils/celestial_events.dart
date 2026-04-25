import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'solara_api.dart' show solaraWorkerBase;

/// Loads and provides celestial event data for intention generation.
///
/// データソース優先順:
/// 1. CF Worker API `/astro/events` (astronomy-engine リアル計算) → メモリキャッシュ
/// 2. 前回API取得成功時のキャッシュ（APIエラー時に使用）
/// 3. 静的JSON `assets/celestial_events_2026.json` (最終fallback)
///
/// themes (意図テーマ) は静的JSONのみ（手書きコンテンツ）
class CelestialEvents {
  static Map<int, MonthEvents>? _months; // 静的JSON
  static final Map<String, List<CelestialEvent>> _apiCache = {}; // APIキャッシュ (key: "year-month")
  static const _workerBase = solaraWorkerBase;

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

  // APIレスポンスから取得した新月日付キャッシュ (key: "year-month")
  static final Map<String, String?> _newMoonCache = {};

  /// CF Worker から1ヶ月分のイベント+新月日付を取得してキャッシュ。
  /// 成功→キャッシュ更新、失敗→既存キャッシュを返す、キャッシュも無い→静的JSON
  static Future<List<CelestialEvent>> _fetchAndCache(int year, int month) async {
    final key = '$year-$month';
    try {
      final uri = Uri.parse('$_workerBase/astro/events?year=$year&month=$month');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        final events = (body['events'] as List)
            .map((e) => CelestialEvent.fromJson(e as Map<String, dynamic>))
            .toList();
        _apiCache[key] = events;
        _newMoonCache[key] = body['newMoonDate'] as String?;

        return events;
      }
    } catch (_) {
      // network/parse error → fall through to month or empty fallback
    }
    if (_apiCache.containsKey(key)) return _apiCache[key]!;
    final fallback = _months?[month]?.events ?? [];

    return fallback;
  }

  /// 新月日付を取得（API→APIキャッシュ→静的JSON の3段fallback）
  static DateTime _getNewMoonDate(int year, int month) {
    final key = '$year-$month';
    // APIキャッシュ
    if (_newMoonCache.containsKey(key) && _newMoonCache[key] != null) {
      return DateTime.parse(_newMoonCache[key]!).toLocal();
    }
    // 静的JSON
    final m = _months?[month];
    if (m != null) return DateTime.parse(m.newMoonDate);
    // 最終fallback
    return DateTime(year, month, 15);
  }

  /// 当月新月〜翌々月新月（約2ヶ月分）のイベントを取得。
  /// 当月+翌月のAPIを呼び、日付範囲でフィルタして返す。
  static Future<List<CelestialEvent>> fetchCycleEvents(int year, int month) async {
    if (_months == null) await initialize();
    final nextMonth = month < 12 ? month + 1 : 1;
    final nextYear = month < 12 ? year : year + 1;
    final month3 = nextMonth < 12 ? nextMonth + 1 : 1;
    final year3 = nextMonth < 12 ? nextYear : nextYear + 1;

    // 当月+翌月を並列取得（イベント+新月日付がキャッシュされる）
    final results = await Future.wait([
      _fetchAndCache(year, month),
      _fetchAndCache(nextYear, nextMonth),
    ]);

    // 当月新月〜翌々月新月でフィルタ
    final newMoonDate = _getNewMoonDate(year, month);
    // 翌々月の新月日付を取得（キャッシュにない場合はAPIを呼ぶ）
    await _fetchAndCache(year3, month3); // endDate用にキャッシュ
    final endDate = _getNewMoonDate(year3, month3);

    final allEvents = results.expand((e) => e).toList();


    // 範囲フィルタ（newMoonDate <= event.date < endDate）
    final filtered = allEvents.where((e) {
      final d = e.localDate;
      if (d == null) return true;
      final pass = !d.isBefore(newMoonDate) && d.isBefore(endDate);

      return pass;
    }).toList();


    // 日付順ソート
    filtered.sort((a, b) {
      final da = a.localDate;
      final db = b.localDate;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });

    return filtered;
  }

  /// Get events for a given month (1-12). Returns null if year not loaded.
  /// (同期版 - 静的JSONのみ使用)
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
  final String? dateISO; // UTC ISO8601 (開始日)
  final String? endDateISO; // UTC ISO8601 (逆行等の終了日、無ければnull)
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
    this.endDateISO,
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
      endDateISO: json['endDate'] as String?,
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

  /// endDateISO (UTC) を端末のローカルタイムに変換
  DateTime? get localEndDate {
    if (endDateISO == null) return null;
    return DateTime.parse(endDateISO!).toLocal();
  }

  /// 端末ローカル日付で組み立てた日本語説明
  /// 全ての日付を端末タイムゾーンで変換して表示
  String get localDescJP {
    final ld = localDate;
    if (ld != null && descTemplateJP != null && planetJP != null && signJP != null) {
      final base = descTemplateJP!
          .replaceAll('{planet}', planetJP!)
          .replaceAll('{sign}', signJP!);
      final led = localEndDate;
      if (led != null) {
        // 期間イベント（逆行等）: '水星が魚座で逆行開始（2/26〜3/21）'
        return '$base（${ld.month}/${ld.day}〜${led.month}/${led.day}）';
      }
      // 単発イベント: '天王星が双子座へ移行（4/26）'
      return '$base（${ld.month}/${ld.day}）';
    }
    return descJP;
  }

  /// 端末ローカル日付で組み立てた英語説明
  String get localDesc {
    final ld = localDate;
    if (ld != null && descTemplate != null && planetEN != null && sign != null) {
      final base = descTemplate!
          .replaceAll('{planet}', planetEN!)
          .replaceAll('{sign}', sign!);
      final led = localEndDate;
      if (led != null) {
        return '$base (${ld.month}/${ld.day} - ${led.month}/${led.day})';
      }
      return '$base (${ld.month}/${ld.day})';
    }
    return desc;
  }
}
