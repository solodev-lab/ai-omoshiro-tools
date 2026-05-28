import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'solara_api.dart' show solaraForecastUrl;
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

/// 運勢サイクル（「◯◯期」）1件分。
/// 特定カテゴリが年内で高スコア状態を一定期間保った期間を表す。
class LifePeriod {
  final String category;   // 'love' | 'money' | 'healing' | 'work' | 'communication'
  final DateTime start;
  final DateTime end;
  final double avgScore;   // 期間内のカテゴリスコア平均
  final int days;          // 期間日数（両端含む）

  LifePeriod({
    required this.category,
    required this.start,
    required this.end,
    required this.avgScore,
    required this.days,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'avgScore': avgScore,
    'days': days,
  };

  factory LifePeriod.fromJson(Map<String, dynamic> j) => LifePeriod(
    category: j['category'] as String,
    start: DateTime.parse(j['start'] as String),
    end: DateTime.parse(j['end'] as String),
    avgScore: (j['avgScore'] as num).toDouble(),
    days: (j['days'] as num).toInt(),
  );
}

/// ForecastDay 列から各カテゴリの「◯◯期」を検出する。
/// - 各カテゴリの日次スコアを昇順ソートし上位 topPct% の閾値を決める
/// - その閾値以上が minDays 日以上連続する区間を抽出（maxGap 日以内の凹みは吸収）
/// - **minDays 以上の全区間を返す**（カテゴリ毎に複数件あり得る）
/// - 戻り値は (category, start) で昇順
List<LifePeriod> detectLifePeriods(
  List<ForecastDay> days, {
  // 標準化された設定（2026-04 調整）：
  // - topPct 0.15 → 各カテゴリ年間 約55日が閾値超え
  // - minDays 7 → 7日連続必須
  // 変更時は強制リフレッシュで再計算が必要（保存済み periods は旧値のまま）
  double topPct = 0.15,
  int minDays = 7,
  int maxGap = 2,
}) {
  if (days.isEmpty) return [];
  const cats = ['love', 'money', 'healing', 'work', 'communication'];
  final results = <LifePeriod>[];

  for (final cat in cats) {
    final scores = days.map((d) => d.catScores[cat] ?? 0.0).toList();
    final sorted = List<double>.from(scores)..sort((a, b) => b.compareTo(a));
    final cutIdx = (sorted.length * topPct).floor().clamp(1, sorted.length - 1);
    final threshold = sorted[cutIdx];
    if (threshold <= 0) continue;

    // 連続区間抽出
    int? runStart;
    int gap = 0;
    final runs = <(int, int)>[]; // (start, end) inclusive

    for (int i = 0; i < scores.length; i++) {
      final active = scores[i] >= threshold;
      if (active) {
        runStart ??= i;
        gap = 0;
      } else if (runStart != null) {
        gap++;
        if (gap > maxGap) {
          final end = i - gap;
          if (end >= runStart) runs.add((runStart, end));
          runStart = null;
          gap = 0;
        }
      }
    }
    if (runStart != null) {
      final end = scores.length - 1 - gap;
      if (end >= runStart) runs.add((runStart, end));
    }

    // minDays 以上の全期間を採用（カーソルで切替表示するため複数残す）
    for (final r in runs) {
      final len = r.$2 - r.$1 + 1;
      if (len < minDays) continue;
      double sum = 0;
      for (int i = r.$1; i <= r.$2; i++) { sum += scores[i]; }
      final sd = DateTime.parse('${days[r.$1].date}T00:00:00Z');
      final ed = DateTime.parse('${days[r.$2].date}T00:00:00Z');
      results.add(LifePeriod(
        category: cat, start: sd, end: ed, avgScore: sum / len, days: len,
      ));
    }
  }

  results.sort((a, b) {
    final c = a.category.compareTo(b.category);
    if (c != 0) return c;
    return a.start.compareTo(b.start);
  });
  return results;
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

const _forecastApiUrl = solaraForecastUrl;
// v2: 暦年(1/1〜12/31)ベースへ移行 (旧 v1 は今日起点ローリング)。プレフィックスを
// 変えることで旧ローリングキャッシュは読まれず、暦年データで再取得される。
const _cacheKeyPrefix = 'solara_forecast_cache_v2_';
const _cooldownKey = 'solara_forecast_last_fetch_v2';
// 運勢サイクル（LifePeriod）専用の永続キャッシュ。日次データの 6h cooldown とは独立。
// 保存値は profile + yearOffset 単位。プロフィール変更で hash が変わり実質クリア。
// 強制リフレッシュ（force=true）でのみ再計算される。
const _periodsKeyPrefix = 'solara_forecast_periods_v2_';
// 強運Top5 専用の永続キャッシュ。modes（overall + 5 カテゴリ）を一括保存。
const _top5KeyPrefix = 'solara_forecast_top5_v2_';
const _top5Modes = ['overall', 'love', 'money', 'healing', 'work', 'communication'];

/// 出生情報のハッシュ。プロフィール変更を検知するために使う。
String profileHashOf(SolaraProfile p) {
  return '${p.birthDate}|${p.birthTime}|${p.birthLat.toStringAsFixed(4)}|${p.birthLng.toStringAsFixed(4)}|${p.birthTz}|${p.birthTzName ?? ''}';
}

/// クールダウン定数（旧設計の名残、現在は未使用）。
///
/// 経緯:
///   - v1: 今日起点ローリング 1 年 → 日付が進むと結果が変わるので 6h cooldown 必須
///   - v2 (現行): 暦年(1/1〜12/31)ベース → (profileHash + yearOffset) で決定論的、
///     再 fetch する意味なし
///   - 2026-05-29: fetchFull() の cooldown 判定を撤廃して **永久キャッシュ** 化
///     (CF Workers /public/astro/forecast の CPU 上限超過 503 対策、ログ実観測)
///
/// cooldownRemaining() / _markFetched() / _coolKey() は将来 force=true の
/// 連打抑制等で復活させる余地のため残置。現在は実質 dead code だが、SharedPreferences
/// に書く側 (_markFetched) は fetchFull が呼んでおり、読む側 (cooldownRemaining) は
/// 外部参照ゼロ。
const _cooldownHours = 6;

class ForecastRepo {
  /// yearOffset 0=今日起点の1年、1=翌年、2=翌々年...最大4（5年目）
  static String _cKey(String hash, int yearOffset) =>
      yearOffset == 0 ? '$_cacheKeyPrefix$hash' : '$_cacheKeyPrefix${hash}_y$yearOffset';
  static String _coolKey(String hash, int yearOffset) =>
      yearOffset == 0 ? '${_cooldownKey}_$hash' : '${_cooldownKey}_${hash}_y$yearOffset';
  static String _periodsKey(String hash, int yearOffset) =>
      yearOffset == 0 ? '$_periodsKeyPrefix$hash' : '$_periodsKeyPrefix${hash}_y$yearOffset';
  static String _top5StorageKey(String hash, int yearOffset) =>
      yearOffset == 0 ? '$_top5KeyPrefix$hash' : '$_top5KeyPrefix${hash}_y$yearOffset';

  /// 運勢サイクルを取得：保存済みなら使い、なければ計算 → 保存。
  /// 同一プロフィール × 同一 yearOffset で 1回のみ計算される（永続）。
  /// - force=true: 保存値を破棄して再計算（強制リフレッシュ時のみ）
  /// - 日次データのキャッシュ（_cKey）が更新されても periods は再計算しない
  static Future<List<LifePeriod>> loadOrComputePeriods({
    required ForecastCache cache,
    required int yearOffset,
    bool force = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _periodsKey(cache.profileHash, yearOffset);
    if (!force) {
      final raw = prefs.getString(key);
      if (raw != null) {
        try {
          final list = (json.decode(raw) as List)
              .map((j) => LifePeriod.fromJson(j as Map<String, dynamic>))
              .toList();
          return list;
        } catch (_) {
          // 破損データはフォールスルーで再計算
        }
      }
    }
    final periods = detectLifePeriods(cache.days);
    await prefs.setString(
      key,
      json.encode(periods.map((p) => p.toJson()).toList()),
    );
    return periods;
  }

  /// 強運Top5 を取得：保存済みなら使い、なければ全 mode 分計算 → 保存。
  /// - 6 modes（overall + 5 fortune categories）×5日 を一括計算（並べ替えのみで安価）
  /// - mode 切替で再計算は走らない（保存値を即引く）
  /// - force=true で再計算
  static Future<Map<String, List<ForecastDay>>> loadOrComputeTop5({
    required ForecastCache cache,
    required int yearOffset,
    bool force = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _top5StorageKey(cache.profileHash, yearOffset);
    if (!force) {
      final raw = prefs.getString(key);
      if (raw != null) {
        try {
          final m = json.decode(raw) as Map<String, dynamic>;
          return m.map((k, v) => MapEntry(
                k,
                (v as List)
                    .map((j) => ForecastDay.fromJson(j as Map<String, dynamic>))
                    .toList(),
              ));
        } catch (_) {
          // 破損データはフォールスルーで再計算
        }
      }
    }
    final result = <String, List<ForecastDay>>{};
    for (final mode in _top5Modes) {
      final sorted = List<ForecastDay>.from(cache.days);
      if (mode == 'overall') {
        sorted.sort((a, b) => b.overall.compareTo(a.overall));
      } else {
        sorted.sort((a, b) =>
            (b.catScores[mode] ?? 0).compareTo(a.catScores[mode] ?? 0));
      }
      result[mode] = sorted.take(5).toList();
    }
    final encoded = result.map(
        (k, v) => MapEntry(k, v.map((d) => d.toJson()).toList()));
    await prefs.setString(key, json.encode(encoded));
    return result;
  }

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

  /// その年の日数 (平年365 / 閏年366)。
  static int _daysInYear(int year) =>
      DateTime(year + 1, 1, 1).difference(DateTime(year, 1, 1)).inDays;

  /// Worker /astro/forecast を呼び出して暦年(1/1〜12/31)分を取得。
  /// 強制キャッシュ無効化時は force=true で cooldown を無視する。
  /// yearOffset: 0=今年、1=来年、2=再来年...4=5年目 (= 今年+yearOffset の暦年)。
  /// - startDate 未指定時は (今年+yearOffset) の 1/1、days はその年の日数を自動設定。
  /// - Forecast スコアは日付ごとに確定的なので、暦年単位で取得・キャッシュすれば
  ///   日付が進んでも内容は変わらない (ローリング更新は廃止)。
  /// - キャッシュは yearOffset ごとに独立。
  static Future<ForecastCache?> fetchFull({
    required SolaraProfile profile,
    String? startDate,
    int days = 365,
    int step = 1,
    bool force = false,
    int yearOffset = 0,
  }) async {
    final hash = profileHashOf(profile);
    // 永久キャッシュ (2026-05-29): forecast は (profileHash + yearOffset) で
    // 決定論的に同じ結果になるため、キャッシュがあれば常に返す。
    //   - 出生情報を更新すると profileHash が変わるので、自然に新規 fetch される
    //   - 強制リフレッシュ (force=true) のみ再 fetch を許可
    //   - これによりサーバ /public/astro/forecast の CPU 上限超過リスク (503) も実質ゼロ
    if (!force) {
      final cached = await loadCached(hash, yearOffset: yearOffset);
      if (cached != null) return cached;
    }
    // 暦年ベース: startDate 未指定なら (今年 + yearOffset) の 1/1 から、その年の日数分。
    if (startDate == null) {
      final year = DateTime.now().year + yearOffset;
      startDate = '${year.toString().padLeft(4, "0")}-01-01';
      days = _daysInYear(year);
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
      // startDate は上で暦年 1/1 を必ずセット済み。
      body['startDate'] = startDate;

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

}
