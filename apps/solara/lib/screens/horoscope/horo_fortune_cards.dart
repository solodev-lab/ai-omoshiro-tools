import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'horo_constants.dart';
import 'horo_antique_icons.dart';
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
    'direction': '🧭 西の方角に豊かさの流れがあります。',
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
  /// BIRTH DATAが編集されているか — trueなら警告バナーを表示
  final bool birthEdited;
  /// 外部から渡されるスクロールコントローラ (背景パララックス用)
  final ScrollController? scrollController;

  const HoroAstrologyView({
    super.key,
    this.natalPatterns = const {},
    this.transitPatterns = const {},
    this.progressedPatterns = const {},
    this.fortunes = const {},
    this.fortuneLoading = false,
    this.fortuneError,
    this.onRetry,
    this.birthEdited = false,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const AntiqueGlyph(icon: AntiqueIcon.reading, size: 20,
            color: Color(0xFFF6BD60)),
          const SizedBox(width: 8),
          Text("TODAY'S READING", style: GoogleFonts.cinzel(
            fontSize: 15, color: const Color(0xFFF6BD60),
            letterSpacing: 3.0, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        Text(
          '${DateTime.now().month}/${DateTime.now().day} のホロスコープ運勢',
          style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
        ),
        const SizedBox(height: 16),
        if (birthEdited) _birthEditedBanner(),
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
                // 数値スコア表示は廃止（占い文だけで完結させる方針）
              ]),
              const SizedBox(height: 12),
              if (fortuneLoading && !useApi)
                _skeletonLine()
              else
                Text(text, style: const TextStyle(fontSize: 15, color: Color(0xD9E8E0D0), height: 1.8)),
              if (advice.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2, right: 6),
                    child: AntiqueGlyph(icon: AntiqueIcon.pattern, size: 12,
                      color: Color(0xFFF6BD60), glow: false),
                  ),
                  Expanded(child: Text(advice,
                    style: const TextStyle(fontSize: 15, color: Color(0xD9E8E0D0), height: 1.6, fontStyle: FontStyle.italic))),
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
                  child: Text(direction, style: const TextStyle(fontSize: 15, color: Color(0xFFF6BD60))),
                ),
              ],
            ]),
          );
        }),

        // ── 特殊アスペクト解説セクション ──
        // (特殊アスペクト解説は 相タブの解説モーダル側へ移動)
      ]),
    );
  }

  Widget _birthEditedBanner() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: const Color(0x22FF9E6B),
      border: Border.all(color: const Color(0x66FF9E6B)),
    ),
    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.info_outline, size: 16, color: Color(0xFFFF9E6B)),
      SizedBox(width: 10),
      Expanded(child: Text(
        '星読みは元の出生情報のみ反映されます。\nBIRTH DATAの編集は星読みに反映されません。',
        style: TextStyle(fontSize: 12, color: Color(0xFFFF9E6B), height: 1.5))),
    ]),
  );

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

}
