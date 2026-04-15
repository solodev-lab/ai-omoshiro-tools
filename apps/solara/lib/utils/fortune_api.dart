// Fortune API - /fortune エンドポイント (Gemini生成の占い文取得)
// 関連: worker/src/fortune.js
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'solara_api.dart' show solaraWorkerBase;

/// Fortune APIレスポンス
class FortuneReading {
  final String category;
  final int score;
  final String reading;
  final String advice;
  final String direction;
  final String lang;

  const FortuneReading({
    required this.category,
    required this.score,
    required this.reading,
    required this.advice,
    required this.direction,
    required this.lang,
  });

  factory FortuneReading.fromJson(Map<String, dynamic> j) => FortuneReading(
    category: j['category'] as String? ?? 'overall',
    score: (j['score'] as num?)?.toInt() ?? 50,
    reading: j['reading'] as String? ?? '',
    advice: j['advice'] as String? ?? '',
    direction: j['direction'] as String? ?? '',
    lang: j['lang'] as String? ?? 'ja',
  );
}

/// /fortune を叩いて占い文を取得
/// category: overall|love|money|career|communication
/// aspects: chartから生成したアスペクト配列 [{p1,p2,type,quality,diff,aspectAngle,orb}, ...]
/// patterns: {grandtrine:[], tsquare:[], yod:[]} (planets配列含む)
Future<FortuneReading?> fetchFortune({
  required String category,
  String lang = 'ja',
  Map<String, double>? natal,
  List<Map<String, dynamic>>? aspects,
  Map<String, List<Map<String, dynamic>>>? patterns,
  String? date,
  String? userName,
}) async {
  try {
    final body = <String, dynamic>{
      'category': category,
      'lang': lang,
      if (natal != null) 'natal': natal,
      if (aspects != null) 'aspects': aspects,
      if (patterns != null) 'patterns': patterns,
      if (date != null) 'date': date,
      if (userName != null && userName.isNotEmpty) 'userName': userName,
    };
    final res = await http.post(
      Uri.parse('$solaraWorkerBase/fortune'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    ).timeout(const Duration(seconds: 30)); // LLM生成は数秒かかる

    if (res.statusCode == 200) {
      return FortuneReading.fromJson(
        json.decode(res.body) as Map<String, dynamic>,
      );
    }
  } catch (_) {
    // network / LLM error → null fallback
  }
  return null;
}

// ── Fortune API カテゴリの親和惑星 ──
// worker/src/fortune.js の FORTUNE_CATEGORIES と完全一致 (LLM入力と score計算で使用)
// ⚠️ horo_constants.fortunePlanets (UIフィルタ用、key='healing') とは別用途:
//   - こちら: API/LLM 向け、key='overall' (全体運)
//   - あちら: Horo画面の絞込チップ、key='healing' (癒し運)
//   キーが 4/5 重複するが、意味が違うので統合しない
const fortuneApiPlanets = {
  'overall': ['sun', 'moon', 'jupiter'],
  'love': ['venus', 'mars', 'moon'],
  'money': ['venus', 'jupiter', 'saturn'],
  'career': ['saturn', 'venus', 'sun'],
  'communication': ['mercury', 'moon', 'jupiter'],
};

/// 関連惑星のアスペクト強度からスコア (20-95) を算出。
/// worker側 computeCategoryScore と同ロジック (オフライン表示用)。
int computeFortuneScore(String category, List<Map<String, dynamic>> aspects) {
  final planets = fortuneApiPlanets[category];
  if (planets == null) return 50;
  final rel = planets.toSet();

  double influence = 0;
  for (final a in aspects) {
    final p1 = a['p1'] as String?;
    final p2 = a['p2'] as String?;
    if (!rel.contains(p1) && !rel.contains(p2)) continue;

    final orb = (a['orb'] as num?)?.toDouble() ?? 2.0;
    final diff = (a['diff'] as num?)?.toDouble() ?? 0.0;
    final angle = (a['aspectAngle'] as num?)?.toDouble() ?? 0.0;
    final diffFromExact = (diff - angle).abs();
    final tightness = (1 - diffFromExact / orb).clamp(0.0, 1.0);

    final q = a['quality'] as String? ?? 'neutral';
    if (q == 'soft') {
      influence += 10 * tightness;
    } else if (q == 'hard') {
      influence -= 6 * tightness;
    } else {
      influence += 3 * tightness;
    }
  }

  final score = (50 + influence).round();
  return score.clamp(20, 95);
}
