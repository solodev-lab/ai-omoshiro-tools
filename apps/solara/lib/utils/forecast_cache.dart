import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'solara_storage.dart';

/// Forecast 1日分のスコア。Worker `/astro/forecast` の day item と同形。
class ForecastDay {
  final String date; // YYYY-MM-DD
  final double overall;
  final String topDir;
  final double topDirScore;
  final String? topFortune;
  final Map<String, double> catScores;

  ForecastDay({
    required this.date,
    required this.overall,
    required this.topDir,
    required this.topDirScore,
    required this.topFortune,
    required this.catScores,
  });

  factory ForecastDay.fromJson(Map<String, dynamic> j) => ForecastDay(
    date: j['date'] as String,
    overall: (j['overall'] as num).toDouble(),
    topDir: j['topDir'] as String? ?? 'N',
    topDirScore: (j['topDirScore'] as num?)?.toDouble() ?? 0,
    topFortune: j['topFortune'] as String?,
    catScores: (j['catScores'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toDouble())),
  );

  Map<String, dynamic> toJson() => {
    'date': date,
    'overall': overall,
    'topDir': topDir,
    'topDirScore': topDirScore,
    'topFortune': topFortune,
    'catScores': catScores,
  };
}

/// Forecast キャッシュ項目
class ForecastCache {
  final String profileHash;
  final DateTime fetchedAt;
  final List<ForecastDay> days;

  ForecastCache({
    required this.profileHash,
    required this.fetchedAt,
    required this.days,
  });

  Map<String, dynamic> toJson() => {
    'profileHash': profileHash,
    'fetchedAt': fetchedAt.toIso8601String(),
    'days': days.map((d) => d.toJson()).toList(),
  };

  factory ForecastCache.fromJson(Map<String, dynamic> j) => ForecastCache(
    profileHash: j['profileHash'] as String,
    fetchedAt: DateTime.parse(j['fetchedAt'] as String),
    days: (j['days'] as List).map((d) => ForecastDay.fromJson(d as Map<String, dynamic>)).toList(),
  );
}

const _forecastApiUrl = 'https://solara-api.solodev-lab.com/astro/forecast';
const _cacheKeyPrefix = 'solara_forecast_cache_';
const _cooldownKey = 'solara_forecast_last_fetch';

/// 出生情報のハッシュ。プロフィール変更を検知するために使う。
String profileHashOf(SolaraProfile p) {
  return '${p.birthDate}|${p.birthTime}|${p.birthLat.toStringAsFixed(4)}|${p.birthLng.toStringAsFixed(4)}|${p.birthTz}|${p.birthTzName ?? ''}';
}

/// クールダウン判定（同一プロフィールで 6時間以内の再取得は禁止）
const _cooldownHours = 6;

class ForecastRepo {
  /// yearOffset 0=今日起点の1年、1=翌年、2=翌々年...最大4（5年目）
  static String _cKey(String hash, int yearOffset) =>
      yearOffset == 0 ? '$_cacheKeyPrefix$hash' : '$_cacheKeyPrefix${hash}_y$yearOffset';
  static String _coolKey(String hash, int yearOffset) =>
      yearOffset == 0 ? '${_cooldownKey}_$hash' : '${_cooldownKey}_${hash}_y$yearOffset';

  /// キャッシュから読み込む（profileHash が一致する場合のみ有効）
  static Future<ForecastCache?> loadCached(String profileHash, {int yearOffset = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cKey(profileHash, yearOffset));
    if (raw == null) return null;
    try {
      return ForecastCache.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// クールダウン残時間（0ならfetch可）。年オフセットごとに独立。
  static Future<Duration> cooldownRemaining(String profileHash, {int yearOffset = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_coolKey(profileHash, yearOffset));
    if (raw == null) return Duration.zero;
    final last = DateTime.tryParse(raw);
    if (last == null) return Duration.zero;
    final elapsed = DateTime.now().difference(last);
    final cooldown = const Duration(hours: _cooldownHours);
    if (elapsed >= cooldown) return Duration.zero;
    return cooldown - elapsed;
  }

  static Future<void> _saveCache(ForecastCache cache, {int yearOffset = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cKey(cache.profileHash, yearOffset), json.encode(cache.toJson()));
  }

  static Future<void> _markFetched(String profileHash, {int yearOffset = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_coolKey(profileHash, yearOffset), DateTime.now().toIso8601String());
  }

  /// Worker /astro/forecast を呼び出して全365日取得。
  /// 強制キャッシュ無効化時は force=true で cooldown を無視する。
  /// yearOffset: 0=今日から1年、1=翌年、2=翌々年...4=5年目
  /// - yearOffset>0 で startDate 未指定時は today+yearOffset*365 を自動設定
  /// - キャッシュは yearOffset ごとに独立
  /// - API呼び出しは yearOffset ごとに1回のみ（複数年一括フェッチはしない）
  static Future<ForecastCache?> fetchFull({
    required SolaraProfile profile,
    String? startDate,
    int days = 365,
    int step = 1,
    bool force = false,
    int yearOffset = 0,
  }) async {
    final hash = profileHashOf(profile);
    if (!force) {
      final rem = await cooldownRemaining(hash, yearOffset: yearOffset);
      if (rem > Duration.zero) {
        final cached = await loadCached(hash, yearOffset: yearOffset);
        if (cached != null) return cached;
      }
    }
    // yearOffset>0 で startDate 未指定なら today+N*365日を自動セット
    if (yearOffset > 0 && startDate == null) {
      final start = DateTime.now().add(Duration(days: yearOffset * 365));
      startDate = '${start.year.toString().padLeft(4, "0")}-${start.month.toString().padLeft(2, "0")}-${start.day.toString().padLeft(2, "0")}';
    }

    try {
      final body = <String, dynamic>{
        'birthDate': profile.birthDate,
        'birthTime': profile.birthTime,
        'birthTz': profile.birthTz,
        'birthLat': profile.birthLat,
        'birthLng': profile.birthLng,
        'days': days,
        'step': step,
      };
      if (profile.birthTzName != null && profile.birthTzName!.isNotEmpty) {
        body['birthTzName'] = profile.birthTzName;
      }
      if (startDate != null) body['startDate'] = startDate;

      final resp = await http.post(
        Uri.parse(_forecastApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final list = (data['days'] as List).map((d) => ForecastDay.fromJson(d as Map<String, dynamic>)).toList();
        final cache = ForecastCache(
          profileHash: hash,
          fetchedAt: DateTime.now(),
          days: list,
        );
        await _saveCache(cache, yearOffset: yearOffset);
        await _markFetched(hash, yearOffset: yearOffset);
        return cache;
      }
      // 429: quota exceeded — 既存キャッシュがあれば返す
      if (resp.statusCode == 429) {
        return await loadCached(hash, yearOffset: yearOffset);
      }
    } catch (_) {
      // ネットワーク失敗 — 既存キャッシュがあれば返す
      return await loadCached(hash, yearOffset: yearOffset);
    }
    return null;
  }

  /// 月次差分更新。
  /// - 既存キャッシュの最終日 +1 日から、startDate+365 日まで取得し、マージ。
  /// - 新規取得日数 0 の場合は既存キャッシュを返す。
  /// - キャッシュ無ければ fetchFull にフォールバック。
  static Future<ForecastCache?> refreshIncremental({
    required SolaraProfile profile,
    int targetDays = 365,
  }) async {
    final hash = profileHashOf(profile);
    final existing = await loadCached(hash);
    if (existing == null) {
      return fetchFull(profile: profile, days: targetDays);
    }
    // 今日をウィンドウの開始として、既存末尾までの差分を算出
    final today = _todayKey();
    final lastDate = existing.days.isNotEmpty ? existing.days.last.date : today;

    // 既存が今日より過去で終わっているなら、その翌日以降を取得
    final lastD = DateTime.parse('${lastDate}T00:00:00Z');
    final todayD = DateTime.parse('${today}T00:00:00Z');
    final desiredEnd = todayD.add(Duration(days: targetDays - 1));

    if (!desiredEnd.isAfter(lastD)) {
      // 既存で足りているので、先頭を今日以降に切り詰めて返す
      final trimmed = existing.days.where((d) => d.date.compareTo(today) >= 0).toList();
      return ForecastCache(
        profileHash: hash,
        fetchedAt: existing.fetchedAt,
        days: trimmed,
      );
    }

    // 差分のみ取得（翌日〜desiredEnd まで）
    final diffStart = lastD.add(const Duration(days: 1));
    final diffDays = desiredEnd.difference(diffStart).inDays + 1;
    if (diffDays <= 0) return existing;
    if (diffDays > 370) {
      // ウィンドウ外 — fetchFull に戻す
      return fetchFull(profile: profile, days: targetDays, force: true);
    }
    final diffStartKey = '${diffStart.year.toString().padLeft(4, "0")}-${diffStart.month.toString().padLeft(2, "0")}-${diffStart.day.toString().padLeft(2, "0")}';
    final fresh = await fetchFull(
      profile: profile,
      startDate: diffStartKey,
      days: diffDays,
      force: true,
    );
    if (fresh == null) return existing;

    // 過去分（今日より前）を切り捨ててマージ
    final merged = <String, ForecastDay>{};
    for (final d in existing.days) {
      if (d.date.compareTo(today) >= 0) merged[d.date] = d;
    }
    for (final d in fresh.days) {
      merged[d.date] = d;
    }
    final mergedList = merged.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    final capped = mergedList.take(targetDays).toList();
    final out = ForecastCache(
      profileHash: hash,
      fetchedAt: DateTime.now(),
      days: capped,
    );
    await _saveCache(out);
    return out;
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, "0")}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")}';
  }
}
