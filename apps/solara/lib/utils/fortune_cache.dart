import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'fortune_api.dart' show FortuneReading;
import 'forecast_cache.dart' show profileHashOf;
import 'solara_storage.dart' show SolaraProfile;

/// Horo「今日の占い」の永続キャッシュ。
///
/// 目的: アプリを再起動しても、同日・同プロフィールなら Gemini を再度叩かず
/// 即表示する (コスト削減 + 即時表示)。従来は画面 state の in-memory キャッシュ
/// のみで、コールドスタートのたびに fetchChart + fetchFortune を呼んでいた。
///
/// キー: プロフィールハッシュ (出生情報) 単位で 1 行。中身に当日の日付を持ち、
/// 別日になれば自然失効 (= 0 時で日付が変わると次回 fetch)。Forecast と同じく
/// プロフィール変更 (birth 情報) でハッシュが変わり実質クリアされる。
///
/// カテゴリは Free=overall のみ / Pro=5 カテゴリ。保存済みが必要カテゴリを
/// 網羅していなければ呼出側で再 fetch する (Free→Pro 昇格時など)。
class FortuneCacheRepo {
  static const _prefix = 'solara_fortune_cache_v1_';

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _key(SolaraProfile p) => '$_prefix${profileHashOf(p)}';

  /// 同日・同プロフィールのキャッシュ (category -> FortuneReading) を返す。
  /// 別日 / 別プロフィール / 未保存 / 破損 は null。
  static Future<Map<String, FortuneReading>?> load(
      SolaraProfile profile, DateTime day) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(profile));
    if (raw == null) return null;
    try {
      final j = json.decode(raw) as Map<String, dynamic>;
      if (j['date'] != _dateStr(day)) return null; // 別日 = 失効
      final readings = (j['readings'] as Map<String, dynamic>).map(
        (k, v) =>
            MapEntry(k, FortuneReading.fromJson(v as Map<String, dynamic>)),
      );
      return readings;
    } catch (_) {
      return null;
    }
  }

  /// カテゴリ別 readings を保存する (値が null のカテゴリは除外)。
  /// 全て null (生成失敗) の場合は何も保存しない (失敗をキャッシュしない)。
  static Future<void> save(SolaraProfile profile, DateTime day,
      Map<String, FortuneReading?> fortunes) async {
    final readings = <String, dynamic>{};
    fortunes.forEach((k, v) {
      if (v != null) readings[k] = v.toJson();
    });
    if (readings.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(profile),
      json.encode({'date': _dateStr(day), 'readings': readings}),
    );
  }
}
