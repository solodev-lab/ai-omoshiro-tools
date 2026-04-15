import 'package:flutter/material.dart';

import 'horo_constants.dart';
import '../../utils/fortune_api.dart';

// ══════════════════════════════════════════════════
// Astrology / Today View (full screen fortune reading)
// HTML: #astrologyView — buildTodayView() with FORTUNE_MOCK data
// (旧 HoroFortuneCards カルーセルは 2026-04-15 に削除: 未使用orphan)
// ══════════════════════════════════════════════════

// HTML exact: FORTUNE_MOCK data
const _fortuneMock = {
  'overall': {
    'text': '今日の星配置は、あなたの内側に眠る意志の力を呼び覚ます一日です。太陽と木星が緩やかにトラインを形成し、行動へのエネルギーと拡張の気風が自然と高まっています。午前中は特に直感が鋭く、長らく保留にしていた選択や決断に向き合う好機といえるでしょう。水星と金星のセクスタイルが知性とコミュニケーションを後押しし、周囲との対話から思わぬヒントが得られる暗示があります。午後にかけては月が蟹座に入り、感受性がさらに深まります。家族や親しい人との時間を大切にすると、心の充電ができるでしょう。夕方以降は火星のエネルギーが穏やかに高まるため、体を動かすことで気持ちがリフレッシュされます。全体的に、内なる声に従って行動することで、自然と良い流れに乗れる一日です。焦らず、自分のペースを信じて進んでみてください。',
    'direction': '🧭 北東が吉方位。新たな出会いや気づきが訪れやすい方角です。午前中に北東方向へ出かけると、思わぬ好機が生まれるかもしれません。',
  },
  'love': {
    'text': '金星と月のアスペクトが感受性を高め、心の距離が自然と縮まりやすい一日です。パートナーがいる方は、日常の中に小さな感謝を伝えると関係が深まります。フリーの方は、感性が開いている今日、心に響く出会いの予感があります。',
    'direction': '🧭 南東の方角に恋愛のエネルギーが集中しています。',
  },
  'money': {
    'text': '木星と水星の配置が金銭面の判断力を高めています。長期的な視点で資産や収入について考えるのに向いた一日です。衝動買いは控え、本当に価値のあるものに投資する意識を持つと良いでしょう。',
    'direction': '🧭 西の方角に金運の流れがあります。',
  },
  'career': {
    'text': '太陽と火星のエネルギーが重なり、仕事への推進力と自信が最高潮に達する一日です。プレゼンや提案、新しいプロジェクトの立ち上げに適しています。午後は特に集中力が増すので、重要なタスクはこの時間帯に。',
    'direction': '🧭 北の方角が仕事運を後押しします。',
  },
  'communication': {
    'text': '水星と金星の調和的なアスペクトが言葉に温かみと説得力を与えています。大切な人との会話、ビジネスの交渉、SNSでの発信——あらゆるコミュニケーションが好調です。誤解を恐れず、素直に気持ちを伝えてみましょう。',
    'direction': '🧭 東の方角でコミュニケーションが活性化します。',
  },
};

// 特殊アスペクトの解説テキスト
const _patternDescriptions = {
  'grandtrine': {
    'N': 'グランドトラインがネイタルチャートに成立しています。3つの天体が120°ずつ調和的に結ばれ、才能や恵みが自然と流れる配置です。この力を意識的に活かすことで、大きな成果を引き寄せることができるでしょう。',
    'T': 'トランジット天体がネイタル天体とグランドトラインを形成しています。宇宙の調和が今まさにあなたに降り注いでいます。流れに身を任せることで、物事が驚くほどスムーズに進む時期です。チャンスを逃さず、積極的に行動しましょう。',
    'P': 'プログレス天体がグランドトラインを完成させています。人生の深い層で調和のエネルギーが熟成し、長期的な幸運の流れが形成されつつあります。内面的な成長が外側の現実に反映される重要な時期です。',
  },
  'tsquare': {
    'N': 'Tスクエアがネイタルチャートに成立しています。緊張と葛藤のエネルギーが3つの天体間で生まれていますが、これは成長の原動力でもあります。頂点の天体が示すテーマに取り組むことで、大きな飛躍が期待できます。',
    'T': 'トランジット天体がTスクエアを活性化しています。一時的な緊張やプレッシャーを感じるかもしれませんが、それは変化と成長のサインです。課題に正面から向き合うことで、停滞を打破する力が得られるでしょう。',
    'P': 'プログレス天体がTスクエアを形成しています。人生の転換期を示す重要な配置です。内面的な葛藤が表面化しやすい時期ですが、この緊張を乗り越えることで人格的な成熟が進みます。',
  },
  'yod': {
    'N': 'ヨッド（神の指）がネイタルチャートに成立しています。運命的な使命を暗示する神秘的な配置です。頂点の天体が指し示す方向に、あなたの魂の目的が隠されています。直感を信じて、その道を探求してみましょう。',
    'T': 'トランジット天体がヨッドを完成させています。運命的な転機が訪れている暗示です。予期せぬ出来事や出会いが、人生の新しい方向性を示してくれるかもしれません。宇宙からのメッセージに耳を傾けてください。',
    'P': 'プログレス天体がヨッドを形成しています。魂のレベルで深い変容が起きている時期です。長年の謎が解けるような気づきや、人生の使命がより明確になる体験があるかもしれません。',
  },
};

class HoroAstrologyView extends StatelessWidget {
  /// 各モードで成立中の特殊アスペクト
  final Map<String, List<Map<String, dynamic>>> natalPatterns;   // single (N-N)
  final Map<String, List<Map<String, dynamic>>> transitPatterns;  // nt (N-T)
  final Map<String, List<Map<String, dynamic>>> progressedPatterns; // np (N-P)

  /// Gemini API で生成された占い文 (カテゴリ別) — nullの場合はmockにfallback
  final Map<String, FortuneReading?> fortunes;
  final bool fortuneLoading;
  final String? fortuneError;
  final VoidCallback? onRetry;

  const HoroAstrologyView({
    super.key,
    this.natalPatterns = const {},
    this.transitPatterns = const {},
    this.progressedPatterns = const {},
    this.fortunes = const {},
    this.fortuneLoading = false,
    this.fortuneError,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('✦ TODAY\'S READING', style: TextStyle(
          fontSize: 14, color: Color(0xFFF6BD60), letterSpacing: 2, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          '${DateTime.now().month}/${DateTime.now().day} のホロスコープ運勢',
          style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
        ),
        const SizedBox(height: 16),
        // ローディング/エラーバナー
        if (fortuneLoading) _loadingBanner(),
        if (fortuneError != null && !fortuneLoading) _errorBanner(),
        ...fortuneCategories.map((cat) {
          final color = Color(cat['color'] as int);
          final catId = cat['id'] as String;
          final reading = fortunes[catId];
          final useApi = reading != null;
          final mock = _fortuneMock[catId];

          final text = useApi
              ? reading.reading
              : (mock?['text'] ?? '');
          final advice = useApi ? reading.advice : '';
          final direction = useApi
              ? (reading.direction.isNotEmpty ? '🧭 ${reading.direction}' : '')
              : (mock?['direction'] ?? '');
          final score = useApi ? reading.score : (cat['score'] as int);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withAlpha(12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withAlpha(50)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 36, height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: color.withAlpha(20),
                    border: Border.all(color: color.withAlpha(40)),
                  ),
                  child: Center(child: Text(cat['icon'] as String, style: const TextStyle(fontSize: 18)))),
                const SizedBox(width: 10),
                Text(cat['nameJP'] as String, style: TextStyle(
                  fontSize: 15, color: color, fontWeight: FontWeight.w700)),
                const Spacer(),
                // スコア表示
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFF6BD60), Color(0xFFF9D976)],
                  ).createShader(bounds),
                  child: Text('$score',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ]),
              const SizedBox(height: 12),
              if (fortuneLoading && !useApi)
                _skeletonLine()
              else
                Text(text, style: const TextStyle(fontSize: 13, color: Color(0xD9E8E0D0), height: 1.8)),
              if (advice.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('✦ ', style: TextStyle(fontSize: 12, color: Color(0xFFF6BD60))),
                  Expanded(child: Text(advice,
                    style: const TextStyle(fontSize: 12, color: Color(0xD9E8E0D0), height: 1.6, fontStyle: FontStyle.italic))),
                ]),
              ],
              if (direction.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0x0FF9D976),
                    border: Border.all(color: const Color(0x26F9D976)),
                  ),
                  child: Text(direction, style: const TextStyle(fontSize: 12, color: Color(0xFFF6BD60))),
                ),
              ],
            ]),
          );
        }),

        // ── 特殊アスペクト解説セクション ──
        ..._buildPatternSections(),
      ]),
    );
  }

  Widget _loadingBanner() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: const Color(0x14F6BD60),
      border: Border.all(color: const Color(0x33F6BD60)),
    ),
    child: const Row(children: [
      SizedBox(width: 16, height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF6BD60))),
      SizedBox(width: 10),
      Expanded(child: Text('Gemini AIが占い文を生成中…',
        style: TextStyle(fontSize: 12, color: Color(0xFFF6BD60)))),
    ]),
  );

  Widget _errorBanner() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: const Color(0x14FF6B6B),
      border: Border.all(color: const Color(0x33FF6B6B)),
    ),
    child: Row(children: [
      const Icon(Icons.cloud_off, size: 14, color: Color(0xFFFF9E9E)),
      const SizedBox(width: 8),
      const Expanded(child: Text('AI占い文の取得に失敗。仮テキストを表示中',
        style: TextStyle(fontSize: 11, color: Color(0xFFFF9E9E)))),
      if (onRetry != null)
        GestureDetector(
          onTap: onRetry,
          child: const Text('再試行',
            style: TextStyle(fontSize: 11, color: Color(0xFFF6BD60),
              decoration: TextDecoration.underline)),
        ),
    ]),
  );

  Widget _skeletonLine() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _skeletonBar(width: double.infinity),
    const SizedBox(height: 6),
    _skeletonBar(width: double.infinity),
    const SizedBox(height: 6),
    _skeletonBar(width: 180),
  ]);

  Widget _skeletonBar({double width = double.infinity}) => Container(
    height: 10, width: width,
    decoration: BoxDecoration(
      color: const Color(0x14FFFFFF),
      borderRadius: BorderRadius.circular(4),
    ),
  );

  List<Widget> _buildPatternSections() {
    final sections = <Widget>[];

    // ネイタル (N-N)
    final natalItems = _patternItems(natalPatterns, 'N');
    if (natalItems.isNotEmpty) {
      sections.addAll([
        const SizedBox(height: 8),
        _sectionHeader('✦ ネイタル特殊アスペクト', const Color(0xFFFFD370)),
        ...natalItems,
      ]);
    }

    // トランジット (N-T)
    final transitItems = _patternItems(transitPatterns, 'T');
    if (transitItems.isNotEmpty) {
      sections.addAll([
        const SizedBox(height: 8),
        _sectionHeader('☾ トランジット特殊アスペクト', const Color(0xFF6BB5FF)),
        ...transitItems,
      ]);
    }

    // プログレス (N-P)
    final progItems = _patternItems(progressedPatterns, 'P');
    if (progItems.isNotEmpty) {
      sections.addAll([
        const SizedBox(height: 8),
        _sectionHeader('☆ プログレス特殊アスペクト', const Color(0xFFB088FF)),
        ...progItems,
      ]);
    }

    return sections;
  }

  Widget _sectionHeader(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: TextStyle(
        fontSize: 13, color: color, fontWeight: FontWeight.w600, letterSpacing: 1)),
    );
  }

  List<Widget> _patternItems(Map<String, List<Map<String, dynamic>>> patterns, String sourceKey) {
    final items = <Widget>[];
    for (final type in ['grandtrine', 'tsquare', 'yod']) {
      for (final p in patterns[type] ?? []) {
        final style = patternStyles[type]!;
        final color = Color(style['color'] as int);
        final pKeys = p['planets'] as List<String>;
        final sources = p['sources'] as List<String>? ?? List.filled(pKeys.length, 'N');
        final planetText = List.generate(pKeys.length, (i) =>
          '${sources[i]}${planetGlyphs[pKeys[i]] ?? pKeys[i]}').join(' ');
        final desc = _patternDescriptions[type]?[sourceKey] ?? '';

        items.add(Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: color.withAlpha(15),
            border: Border.all(color: color.withAlpha(40)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                child: Text(style['labelJP'] as String, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Text(planetText, style: const TextStyle(fontSize: 12, color: Color(0xFFCCCCCC))),
            ]),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(desc, style: const TextStyle(fontSize: 13, color: Color(0xD9E8E0D0), height: 1.8)),
            ],
          ]),
        ));
      }
    }
    return items;
  }
}
