import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_reading.dart';
import '../models/galaxy_cycle.dart';
import '../models/lunar_intention.dart';

/// User profile data.
class SolaraProfile {
  final String name;
  final String birthDate; // YYYY-MM-DD
  final String birthTime; // HH:mm
  final bool birthTimeUnknown;
  final String birthPlace;
  final double birthLat;
  final double birthLng;
  final int birthTz; // UTC offset in hours (legacy fallback)
  final String? birthTzName; // IANA TZ name e.g. 'Asia/Tokyo' (DST-aware, C案)
  final String homeName; // HTML: p.homeName
  final double homeLat;  // HTML: p.homeLat
  final double homeLng;  // HTML: p.homeLng

  const SolaraProfile({
    this.name = '',
    this.birthDate = '',
    this.birthTime = '12:00',
    this.birthTimeUnknown = false,
    this.birthPlace = '',
    this.birthLat = 0,
    this.birthLng = 0,
    this.birthTz = 9,
    this.birthTzName,
    this.homeName = '',
    this.homeLat = 0,
    this.homeLng = 0,
  });

  bool get isComplete => birthDate.isNotEmpty && birthPlace.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'name': name,
    'birthDate': birthDate,
    'birthTime': birthTime,
    'birthTimeUnknown': birthTimeUnknown,
    'birthPlace': birthPlace,
    'birthLat': birthLat,
    'birthLng': birthLng,
    'birthTz': birthTz,
    'birthTzName': birthTzName,
    'homeName': homeName,
    'homeLat': homeLat,
    'homeLng': homeLng,
  };

  factory SolaraProfile.fromJson(Map<String, dynamic> j) => SolaraProfile(
    name: j['name'] ?? '',
    birthDate: j['birthDate'] ?? '',
    birthTime: j['birthTime'] ?? '12:00',
    birthTimeUnknown: j['birthTimeUnknown'] ?? false,
    birthPlace: j['birthPlace'] ?? '',
    birthLat: (j['birthLat'] ?? 0).toDouble(),
    birthLng: (j['birthLng'] ?? 0).toDouble(),
    birthTz: j['birthTz'] ?? 9,
    birthTzName: j['birthTzName'] as String?,
    homeName: j['homeName'] ?? '',
    homeLat: (j['homeLat'] ?? 0).toDouble(),
    homeLng: (j['homeLng'] ?? 0).toDouble(),
  );

  SolaraProfile copyWith({
    String? name,
    String? birthDate,
    String? birthTime,
    bool? birthTimeUnknown,
    String? birthPlace,
    double? birthLat,
    double? birthLng,
    int? birthTz,
    String? birthTzName,
    String? homeName,
    double? homeLat,
    double? homeLng,
  }) => SolaraProfile(
    name: name ?? this.name,
    birthDate: birthDate ?? this.birthDate,
    birthTime: birthTime ?? this.birthTime,
    birthTimeUnknown: birthTimeUnknown ?? this.birthTimeUnknown,
    birthPlace: birthPlace ?? this.birthPlace,
    birthLat: birthLat ?? this.birthLat,
    birthLng: birthLng ?? this.birthLng,
    birthTz: birthTz ?? this.birthTz,
    birthTzName: birthTzName ?? this.birthTzName,
    homeName: homeName ?? this.homeName,
    homeLat: homeLat ?? this.homeLat,
    homeLng: homeLng ?? this.homeLng,
  );
}

/// Persistence wrapper for Solara data.
class SolaraStorage {
  static const _profileKey = 'solara_profile';
  static const _currentReadingsKey = 'solara_current_cycle_readings';
  static const _completedCyclesKey = 'solara_galaxy_cycles';
  static const _intentionKey = 'solara_lunar_intention';
  static const _overlayShownKey = 'solara_overlay_shown';
  static const _mapStyleKey = 'solara_map_style';
  static const _dailyResetHourKey = 'solara_daily_reset_hour';
  static const _forecastColorModeKey = 'solara_forecast_color_mode';
  static const _forecastHighColorKey = 'solara_forecast_high_color';
  static const _forecastYearOffsetKey = 'solara_forecast_year_offset';

  // --- Forecast heatmap display settings ---

  /// ヒートマップ色モード: 'relative' | 'absolute' | 'category'
  static Future<String> loadForecastColorMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_forecastColorModeKey) ?? 'relative';
  }

  static Future<void> saveForecastColorMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_forecastColorModeKey, mode);
  }

  /// 高スコア側の色: 'green' | 'red'
  static Future<String> loadForecastHighColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_forecastHighColorKey) ?? 'green';
  }

  static Future<void> saveForecastHighColor(String color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_forecastHighColorKey, color);
  }

  /// Forecast 画面で最後に見た年オフセット（0-4）
  static Future<int> loadForecastYearOffset() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_forecastYearOffsetKey) ?? 0).clamp(0, 4);
  }

  static Future<void> saveForecastYearOffset(int offset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_forecastYearOffsetKey, offset.clamp(0, 4));
  }

  // --- Map style ---

  static Future<String?> loadMapStyleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_mapStyleKey);
  }

  static Future<void> saveMapStyleId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mapStyleKey, id);
  }

  // --- Profile ---

  static Future<SolaraProfile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;
    return SolaraProfile.fromJson(json.decode(raw) as Map<String, dynamic>);
  }

  static Future<void> saveProfile(SolaraProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, json.encode(profile.toJson()));
  }

  // --- Current cycle readings ---

  static Future<List<DailyReading>> loadCurrentReadings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_currentReadingsKey);
    if (raw == null) return [];
    final list = json.decode(raw) as List;
    return list
        .map((e) => DailyReading.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveCurrentReadings(List<DailyReading> readings) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(readings.map((r) => r.toJson()).toList());
    await prefs.setString(_currentReadingsKey, raw);
  }

  static Future<void> addReading(DailyReading reading) async {
    final readings = await loadCurrentReadings();
    // Replace if same date exists
    readings.removeWhere((r) => r.date == reading.date);
    readings.add(reading);
    // HTML: if (hist.length > 50) hist.length = 50
    if (readings.length > 50) {
      readings.removeRange(0, readings.length - 50);
    }
    await saveCurrentReadings(readings);
  }

  static Future<void> clearReadings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentReadingsKey);
  }

  /// Update synchronicity text for a specific reading date.
  static Future<void> updateSynchronicity(String date, String text) async {
    final readings = await loadCurrentReadings();
    for (final r in readings) {
      if (r.date == date) {
        r.synchronicity = text;
        break;
      }
    }
    await saveCurrentReadings(readings);
  }

  /// Update an existing reading (matched by date) with new reading text.
  /// 用途: /tarot API 応答後に Gemini 生成テキストを保存する。
  static Future<void> updateReading(DailyReading updated) async {
    final readings = await loadCurrentReadings();
    for (final r in readings) {
      if (r.date == updated.date) {
        r.reading = updated.reading;
        // synchronicity はユーザー入力なので上書きしない
        break;
      }
    }
    await saveCurrentReadings(readings);
  }

  /// Remove a reading by date (used for the dev "reset today" button).
  /// 本番では呼ばれない想定。
  static Future<void> removeReadingByDate(String date) async {
    final readings = await loadCurrentReadings();
    readings.removeWhere((r) => r.date == date);
    await saveCurrentReadings(readings);
  }

  // --- Title Diagnosis persistence ---

  static const _titleKey = 'solara_title_data';

  static Future<Map<String, dynamic>?> loadTitleData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_titleKey);
    if (raw == null) return null;
    return json.decode(raw) as Map<String, dynamic>;
  }

  static Future<void> saveTitleData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_titleKey, json.encode(data));
  }

  static Future<DailyReading?> getTodayReading() async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final readings = await loadCurrentReadings();
    for (final r in readings) {
      if (r.date == dateStr) return r;
    }
    return null;
  }

  // --- Completed cycles ---

  static Future<List<GalaxyCycle>> loadCompletedCycles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_completedCyclesKey);
    if (raw == null) return [];
    final list = json.decode(raw) as List;
    return list
        .map((e) => GalaxyCycle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveCompletedCycle(GalaxyCycle cycle) async {
    final cycles = await loadCompletedCycles();
    cycles.add(cycle);
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(cycles.map((c) => c.toJson()).toList());
    await prefs.setString(_completedCyclesKey, raw);
  }

  static Future<void> clearCurrentReadings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentReadingsKey);
  }

  // --- Lunar intentions ---

  static Future<LunarIntention?> loadIntention(String cycleId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${_intentionKey}_$cycleId');
    if (raw == null) return null;
    return LunarIntention.fromJson(
        json.decode(raw) as Map<String, dynamic>);
  }

  static Future<void> saveIntention(LunarIntention intention) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_intentionKey}_${intention.cycleId}',
      json.encode(intention.toJson()),
    );
  }

  /// 1日の基準時刻（0-23時）。この時刻を跨ぐと「今日」が更新される。
  /// 例: 3 に設定すると、深夜3時を日付の区切りとして扱う。
  static Future<int> loadDailyResetHour() async {
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getInt(_dailyResetHourKey) ?? 0;
    return h.clamp(0, 23);
  }

  static Future<void> saveDailyResetHour(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyResetHourKey, hour.clamp(0, 23));
  }

  /// Sanctuary で設定されたアスペクトオーブ値を読み込む。
  /// SharedPreferences key: 'solara_orb_settings' (JSON)
  /// 戻り値: {conjunction, opposition, trine, square, sextile, quincunx,
  ///         semisextile, semisquare} の各 orb（°）。
  /// 未保存時はデフォルト値（Sanctuary の初期値と同じ）を返す。
  static Future<Map<String, double>> loadOrbSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('solara_orb_settings');
    final defaults = <String, double>{
      'conjunction': 2, 'opposition': 2, 'trine': 2, 'square': 2,
      'sextile': 2, 'quincunx': 2, 'semisextile': 1, 'semisquare': 1,
    };
    if (raw == null) return defaults;
    try {
      final m = json.decode(raw) as Map<String, dynamic>;
      final result = Map<String, double>.from(defaults);
      for (final k in m.keys) {
        final v = m[k];
        if (v is num) result[k] = v.toDouble();
      }
      return result;
    } catch (_) {
      return defaults;
    }
  }

  /// リセット時刻を考慮した「今日」の日付キー (YYYY-MM-DD)。
  /// 現在時刻がリセット時刻より前なら、前日の日付を返す。
  static Future<String> _logicalTodayKey() async {
    final hour = await loadDailyResetHour();
    var now = DateTime.now();
    if (now.hour < hour) {
      now = now.subtract(const Duration(days: 1));
    }
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Track which overlay was shown today to avoid re-showing.
  static Future<bool> wasOverlayShownToday(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final day = await _logicalTodayKey();
    final key = '${_overlayShownKey}_${type}_$day';
    return prefs.getBool(key) ?? false;
  }

  static Future<void> markOverlayShown(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final day = await _logicalTodayKey();
    final key = '${_overlayShownKey}_${type}_$day';
    await prefs.setBool(key, true);
  }

  /// Not today 押下回数（サイクルID単位で保存）
  static Future<int> getNotTodayCount(String cycleId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('not_today_count_$cycleId') ?? 0;
  }

  static Future<void> incrementNotTodayCount(String cycleId) async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt('not_today_count_$cycleId') ?? 0;
    await prefs.setInt('not_today_count_$cycleId', count + 1);
  }
}
