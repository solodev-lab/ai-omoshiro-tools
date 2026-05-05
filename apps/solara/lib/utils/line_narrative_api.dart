// Astro*Carto*Graphy Line Narrative API — Tier S #2
// 関連: worker/src/line_narrative.js
//
// A*C*G ライン (natal / transit 2フレーム × 10惑星 × 4アングル) の
// タップ詳細解説を Gemini で動的取得する。
//
// 設計:
//   - 失敗時は null fallback (呼出側で静的辞書にフォールバック)
//   - メモリ LRU キャッシュ最大 100 件。同条件のリクエストはキャッシュ再利用
//   - キャッシュキーは {frame, planet, angle, latRound, lngRound, lang, transitHour}
//     latRound/lngRound は 0.1° (≒11km) 単位で丸める

import 'dart:collection';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'solara_api.dart' show solaraWorkerBase;

class LineNarrative {
  final String title;
  final String narrative;
  final String softNote;
  final String hardNote;
  final String lang;

  const LineNarrative({
    required this.title,
    required this.narrative,
    required this.softNote,
    required this.hardNote,
    required this.lang,
  });

  factory LineNarrative.fromJson(Map<String, dynamic> j) => LineNarrative(
        title: j['title'] as String? ?? '',
        narrative: j['narrative'] as String? ?? '',
        softNote: j['softNote'] as String? ?? '',
        hardNote: j['hardNote'] as String? ?? '',
        lang: j['lang'] as String? ?? 'ja',
      );

  bool get isEmpty =>
      title.isEmpty && narrative.isEmpty && softNote.isEmpty && hardNote.isEmpty;
}

const int _maxCacheEntries = 100;
final LinkedHashMap<String, LineNarrative> _cache = LinkedHashMap();

String _buildCacheKey({
  required String frame,
  required String planet,
  required String angle,
  required double tappedLat,
  required double tappedLng,
  required String lang,
  String? transitDate,
}) {
  final latR = (tappedLat * 10).round();
  final lngR = (tappedLng * 10).round();
  final transitHour = transitDate == null
      ? ''
      : (transitDate.length >= 13 ? transitDate.substring(0, 13) : transitDate);
  return '$frame|$planet|${angle.toUpperCase()}|$latR|$lngR|$lang|$transitHour';
}

void _putCache(String key, LineNarrative value) {
  _cache.remove(key);
  _cache[key] = value;
  while (_cache.length > _maxCacheEntries) {
    _cache.remove(_cache.keys.first);
  }
}

LineNarrative? _peekCache(String key) {
  final v = _cache.remove(key);
  if (v == null) return null;
  _cache[key] = v; // LRU 再挿入
  return v;
}

/// /astro/line-narrative を叩いて A*C*G ライン解説を取得。
/// 失敗時 null fallback。呼出側で astro_glossary 静的辞書にフォールバックすること。
Future<LineNarrative?> fetchLineNarrative({
  required String frame, // 'natal' | 'transit'
  required String planet, // 'venus' 等
  required String angle, // 'ASC' | 'MC' | 'DSC' | 'IC'
  required double tappedLat,
  required double tappedLng,
  String? tappedPlaceName,
  Map<String, int>? natalSummary, // {ascSign, mcSign, sunSign, moonSign}
  String? transitDate, // ISO8601 (frame=='transit' のとき)
  String? userName,
  String lang = 'ja',
}) async {
  final cacheKey = _buildCacheKey(
    frame: frame,
    planet: planet,
    angle: angle,
    tappedLat: tappedLat,
    tappedLng: tappedLng,
    lang: lang,
    transitDate: transitDate,
  );
  final cached = _peekCache(cacheKey);
  if (cached != null) return cached;

  try {
    final body = <String, dynamic>{
      'frame': frame,
      'planet': planet,
      'angle': angle.toUpperCase(),
      'tappedLat': tappedLat,
      'tappedLng': tappedLng,
      if (tappedPlaceName != null && tappedPlaceName.isNotEmpty)
        'tappedPlaceName': tappedPlaceName,
      if (natalSummary != null && natalSummary.isNotEmpty)
        'natalSummary': natalSummary,
      if (transitDate != null && transitDate.isNotEmpty)
        'transitDate': transitDate,
      if (userName != null && userName.isNotEmpty) 'userName': userName,
      'lang': lang,
    };
    final res = await http
        .post(
          Uri.parse('$solaraWorkerBase/astro/line-narrative'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        )
        .timeout(const Duration(seconds: 60));

    if (res.statusCode == 200) {
      final result = LineNarrative.fromJson(
        json.decode(res.body) as Map<String, dynamic>,
      );
      if (!result.isEmpty) {
        _putCache(cacheKey, result);
      }
      return result;
    }
  } catch (_) {
    // network / LLM error → null fallback
  }
  return null;
}

