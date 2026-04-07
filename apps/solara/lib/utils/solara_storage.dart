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
  final int birthTz; // UTC offset in hours

  const SolaraProfile({
    this.name = '',
    this.birthDate = '',
    this.birthTime = '12:00',
    this.birthTimeUnknown = false,
    this.birthPlace = '',
    this.birthLat = 0,
    this.birthLng = 0,
    this.birthTz = 9,
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
  );
}

/// Persistence wrapper for Solara data.
class SolaraStorage {
  static const _profileKey = 'solara_profile';
  static const _currentReadingsKey = 'solara_current_cycle_readings';
  static const _completedCyclesKey = 'solara_galaxy_cycles';
  static const _intentionKey = 'solara_lunar_intention';
  static const _overlayShownKey = 'solara_overlay_shown';

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
    await saveCurrentReadings(readings);
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

  /// Track which overlay was shown today to avoid re-showing.
  static Future<bool> wasOverlayShownToday(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final key =
        '${_overlayShownKey}_${type}_${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return prefs.getBool(key) ?? false;
  }

  static Future<void> markOverlayShown(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final key =
        '${_overlayShownKey}_${type}_${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await prefs.setBool(key, true);
  }
}
