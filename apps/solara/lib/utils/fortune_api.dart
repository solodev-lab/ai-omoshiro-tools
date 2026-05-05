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
/// planetHouses: {sun: 10, moon: 4, ...} 各惑星のハウス番号 (1-12)。
///   出生時刻不明 / Worker 接続失敗時は null を渡すこと（Worker 側がハウス言及を避ける）。
Future<FortuneReading?> fetchFortune({
  required String category,
  String lang = 'ja',
  Map<String, double>? natal,
  Map<String, int>? planetHouses,
  List<Map<String, dynamic>>? aspects,
  Map<String, List<Map<String, dynamic>>>? patterns,
  String? date,
  String? userName,
}) async {
  try {
    final body = <String, dynamic>{
      'category': category,
      'lang': lang,
      'natal': ?natal,
      'planetHouses': ?planetHouses,
      'aspects': ?aspects,
      'patterns': ?patterns,
      'date': ?date,
      if (userName != null && userName.isNotEmpty) 'userName': userName,
    };
    final res = await http.post(
      Uri.parse('$solaraWorkerBase/fortune'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    ).timeout(const Duration(seconds: 60)); // LLM生成は数秒〜30秒。死神等の強烈カードは安全フィルターで遅い

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

// ──────────────────────────────────────────────────
// Relocation API — /relocation エンドポイント (Gemini生成のリロケーション解説)
// 関連: worker/src/relocation.js
// Phase B: 静的テンプレート (horo_relocation_templates.dart) を動的解説で上書き。
// 失敗時は null fallback、呼出側 (horo_relocation_panel.dart) で静的テンプレ表示。
// ──────────────────────────────────────────────────

class RelocationNarrative {
  /// planet ('sun' 等) → 動的解説文。変化なし or APIで生成されなかった惑星はキー無し。
  final Map<String, String> planetNarratives;
  /// ASC 動的解説文。変化なしの場合は空文字。
  final String ascNarrative;
  /// MC 動的解説文。変化なしの場合は空文字。
  final String mcNarrative;
  /// 総合サマリー（パネル先頭表示用）
  final String summary;
  final String lang;

  const RelocationNarrative({
    required this.planetNarratives,
    required this.ascNarrative,
    required this.mcNarrative,
    required this.summary,
    required this.lang,
  });

  factory RelocationNarrative.fromJson(Map<String, dynamic> j) {
    final shiftsList = (j['shifts'] as List?) ?? [];
    final planetMap = <String, String>{};
    for (final s in shiftsList) {
      if (s is Map<String, dynamic>) {
        final planet = s['planet'] as String?;
        final narrative = s['narrative'] as String?;
        if (planet != null && narrative != null && narrative.isNotEmpty) {
          planetMap[planet] = narrative;
        }
      }
    }
    return RelocationNarrative(
      planetNarratives: planetMap,
      ascNarrative: j['ascNarrative'] as String? ?? '',
      mcNarrative: j['mcNarrative'] as String? ?? '',
      summary: j['summary'] as String? ?? '',
      lang: j['lang'] as String? ?? 'ja',
    );
  }

  /// 全項目が空 = サーバー側で「変化なし」判定。呼出側はこの場合 null と同等扱いで静的テンプレに任せる。
  bool get isEmpty =>
      planetNarratives.isEmpty &&
      ascNarrative.isEmpty &&
      mcNarrative.isEmpty &&
      summary.isEmpty;
}

/// /relocation を叩いてリロケーション解説を取得。
/// shifts: [{planet, fromHouse, toHouse}] (変化なし含む全惑星でも、変化ありでも可)
/// ascChange / mcChange: {fromSign, toSign} 0-11 (null は変化なし or 算出不可)
/// 失敗時は null。呼出側で静的テンプレートにフォールバックすること。
Future<RelocationNarrative?> fetchRelocationNarrative({
  required List<Map<String, dynamic>> shifts,
  Map<String, int>? ascChange,
  Map<String, int>? mcChange,
  String? birthPlaceName,
  String? homeName,
  String? userName,
  String lang = 'ja',
}) async {
  try {
    final body = <String, dynamic>{
      'shifts': shifts,
      'ascChange': ?ascChange,
      'mcChange': ?mcChange,
      if (birthPlaceName != null && birthPlaceName.isNotEmpty) 'birthPlaceName': birthPlaceName,
      if (homeName != null && homeName.isNotEmpty) 'homeName': homeName,
      if (userName != null && userName.isNotEmpty) 'userName': userName,
      'lang': lang,
    };
    final res = await http.post(
      Uri.parse('$solaraWorkerBase/relocation'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    ).timeout(const Duration(seconds: 60)); // LLM生成は数秒〜30秒

    if (res.statusCode == 200) {
      return RelocationNarrative.fromJson(
        json.decode(res.body) as Map<String, dynamic>,
      );
    }
  } catch (_) {
    // network / LLM error → null fallback
  }
  return null;
}

// ──────────────────────────────────────────────────
// Tarot API — /tarot エンドポイント (Gemini生成のタロット占い文)
// 関連: worker/src/tarot.js
// ──────────────────────────────────────────────────

class TarotReading {
  final int cardId;
  final bool reversed;
  final String reading;
  final String lang;

  const TarotReading({
    required this.cardId,
    required this.reversed,
    required this.reading,
    required this.lang,
  });

  factory TarotReading.fromJson(Map<String, dynamic> j) => TarotReading(
        cardId: (j['cardId'] as num?)?.toInt() ?? 0,
        reversed: j['reversed'] as bool? ?? false,
        reading: j['reading'] as String? ?? '',
        lang: j['lang'] as String? ?? 'ja',
      );
}

/// /tarot を叩いて1枚引きの Reading を生成する。
/// 失敗時は null。呼び出し側で静的テンプレート fallback すること。
///
/// [moonPhase] は 0.0〜29.53（[MoonPhase.getPhaseDay]）。
/// [planet] は major arcana のみ存在することが多い（minor は null）。
Future<TarotReading?> fetchTarotReading({
  required int cardId,
  required bool reversed,
  required String nameJP,
  String? nameEN,
  required String keyword,
  required String element,
  String? planet,
  double? moonPhase,
  String? userName,
  String lang = 'ja',
}) async {
  try {
    final body = <String, dynamic>{
      'cardId': cardId,
      'reversed': reversed,
      'nameJP': nameJP,
      'nameEN': ?nameEN,
      'keyword': keyword,
      'element': element,
      'planet': ?planet,
      'moonPhase': ?moonPhase,
      if (userName != null && userName.isNotEmpty) 'userName': userName,
      'lang': lang,
    };
    final res = await http.post(
      Uri.parse('$solaraWorkerBase/tarot'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    ).timeout(const Duration(seconds: 60)); // 死神等の強烈カードは安全フィルターで遅延

    if (res.statusCode == 200) {
      return TarotReading.fromJson(
        json.decode(res.body) as Map<String, dynamic>,
      );
    }
  } catch (_) {
    // network / LLM error → null fallback
  }
  return null;
}

// computeFortuneScore + fortuneApiPlanets 削除 (audit dead-symbol, 2026-05-06):
// オフライン表示用のスコア再計算ロジックだったが UI から呼ばれず。
// Worker (worker/src/fortune.js) 側のサーバー計算結果を直接使う設計に
// 移行済みのため不要。必要になったら git log から復元可能。
