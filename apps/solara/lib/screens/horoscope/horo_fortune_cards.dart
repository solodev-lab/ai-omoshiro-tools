import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'horo_constants.dart';
import 'horo_antique_icons.dart';
import '../../i18n/strings.g.dart';
import '../../utils/fortune_api.dart';
import '../../widgets/ai_disclaimer_footer.dart';
import '../../widgets/ai_report_button.dart';
import '../../utils/solara_i18n.dart';

// ══════════════════════════════════════════════════
// Astrology / Today View (full screen fortune reading)
// HTML: #astrologyView — buildTodayView() with FORTUNE_MOCK data
// (旧 HoroFortuneCards カルーセルは 2026-04-15 に削除: 未使用orphan)
// ══════════════════════════════════════════════════

// HTML exact: FORTUNE_MOCK data
// 旧: 取得失敗時に出す mock 仮テキスト。2026-06-03 撤去。
// 失敗は fake で取り繕わず素直に「失敗+再試行」を出す方針 (タロット/拠点と統一)。

class HoroAstrologyView extends StatelessWidget {
  /// 各モードで成立中の特殊アスペクト
  final Map<String, List<Map<String, dynamic>>> natalPatterns;   // single (N-N)
  final Map<String, List<Map<String, dynamic>>> transitPatterns;  // nt (N-T)
  final Map<String, List<Map<String, dynamic>>> progressedPatterns; // np (N-P)

  /// Stella が生成した占い文 (カテゴリ別) — nullの場合はmockにfallback
  final Map<String, FortuneReading?> fortunes;
  final bool fortuneLoading;
  final String? fortuneError;
  final VoidCallback? onRetry;
  /// BIRTH DATAが編集されているか — trueなら警告バナーを表示
  final bool birthEdited;
  /// 外部から渡されるスクロールコントローラ (背景パララックス用)
  final ScrollController? scrollController;

  /// Phase A1 (2026-05-17): Pro 状態。
  /// false=Free は overall のみフル表示、残り 4 カテゴリは殻ティーザー
  /// (タイトル + アイコン + 🔒 + skeleton bars、Gemini は呼ばれない)。
  /// true=Pro は全 5 カテゴリをフル表示。
  final bool isPro;

  /// Free ユーザーが殻ティーザーカードをタップしたときのハンドラ。
  /// 親 (`HoroscopeScreen._showFortuneProUnlock`) で `showProUnlockDialog` を出す。
  final ValueChanged<Map<String, dynamic>>? onLockedCategoryTap;

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
    this.isPro = false,
    this.onLockedCategoryTap,
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
          t.horoDisplay.horoOfDate(date: '${DateTime.now().month}/${DateTime.now().day}'),
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

          // Phase A1: Free ユーザーは overall 以外を殻ティーザー化。
          // 「🔴 殻ティーザーは Free ユーザーで Gemini を 1 回も呼ばないこと」
          // (pro_candidates.md §7.1) — 親側で fetch 自体をスキップしている。
          final isLockedForFree = !isPro && catId != 'overall';
          if (isLockedForFree) {
            return _lockedTeaserCard(cat, color);
          }

          // 取得できていない (失敗 / 未取得) かつロード中でない → mock で取り繕わず
          // カード自体を出さない (上部の失敗バナー + 再試行が状況を説明する。2026-06-03)。
          if (!useApi && !fortuneLoading) return const SizedBox.shrink();

          final text = useApi ? reading.reading : '';
          final advice = useApi ? reading.advice : '';

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
                Text(categoryLabel(cat['id'] as String), style: TextStyle(
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
              // AI 出力ユーザー報告 (Google Gen AI Policy)。本物の Gemini 出力時のみ表示。
              // 詳細: docs/store_compliance.md §3.1 / widgets/ai_report_button.dart
              if (useApi) ...[
                AiReportButton(
                  feature: 'fortune',
                  outputText: advice.isNotEmpty ? '$text\n\n$advice' : text,
                  padding: const EdgeInsets.only(top: 4),
                ),
                // 解釈は 1 つに過ぎない旨の注記 (ホロスコープにエビデンスがある旨)。
                StellaInterpretationNote(
                  text: t.horoDisplay.stellaNote,
                ),
                // disclaimer footer — 報告ボタンの直下に常時。
                // 🔴 const にしない: 永続タブ (Horo) 内の const は言語切替で再ビルド
                // されず disclaimer.ai が旧ロケールのまま残る (slang global t 対策)。
                AiDisclaimerFooter(padding: EdgeInsets.zero),
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
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.info_outline, size: 16, color: Color(0xFFFF9E6B)),
      const SizedBox(width: 10),
      Expanded(child: Text(
        t.horoDisplay.birthDataNote,
        style: const TextStyle(fontSize: 12, color: Color(0xFFFF9E6B), height: 1.5))),
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
    child: Row(children: [
      const SizedBox(width: 16, height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF6BD60))),
      const SizedBox(width: 10),
      Expanded(child: Text(t.consultResult.loading,
        style: const TextStyle(fontSize: 12, color: Color(0xFFF6BD60)))),
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
      Expanded(child: Text(t.disclaimer.fetchFailed,
        style: const TextStyle(fontSize: 11, color: Color(0xFFFF9E9E), height: 1.5))),
      if (onRetry != null)
        GestureDetector(
          onTap: onRetry,
          child: Text(t.common.tryAgain,
            style: const TextStyle(fontSize: 11, color: Color(0xFFF6BD60),
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

  /// Phase A1: Free ユーザー向け殻ティーザーカード。
  /// タイトル + アイコン + 🔒 + 静的スケルトン (Gemini 呼ばない)。
  /// タップで親が showProUnlockDialog を出す。
  /// dim 配色 (alpha 8/30/60) で「触れるが今は読めない」シグナルを送る。
  Widget _lockedTeaserCard(Map<String, dynamic> cat, Color color) {
    final nameJP = categoryLabel(cat['id'] as String);
    final icon = cat['icon'] as String;
    return GestureDetector(
      onTap: onLockedCategoryTap == null
          ? null
          : () => onLockedCategoryTap!(cat),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withAlpha(8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: color.withAlpha(14),
                  border: Border.all(color: color.withAlpha(30)),
                ),
                child: Center(
                  child: Text(icon,
                      style: const TextStyle(fontSize: 18, color: Color(0x99FFFFFF))),
                ),
              ),
              const SizedBox(width: 10),
              Text(nameJP, style: TextStyle(
                fontSize: 15,
                color: color.withAlpha(140),
                fontWeight: FontWeight.w700,
              )),
              const Spacer(),
              // 🔒 lock + Pro バッジ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x66F6BD60)),
                  color: const Color(0x22F6BD60),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 12, color: Color(0xFFF6BD60)),
                    SizedBox(width: 4),
                    Text('Pro',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFF6BD60),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 14),
            // スケルトン 3 行 (静的、shimmer なし — 演出より読み取りやすさ優先)
            _skeletonBar(width: double.infinity),
            const SizedBox(height: 6),
            _skeletonBar(width: double.infinity),
            const SizedBox(height: 6),
            _skeletonBar(width: 220),
            const SizedBox(height: 12),
            // 静かな誘導文
            Text(
              t.horoDisplay.proOpenReading(name: nameJP),
              style: TextStyle(
                fontSize: 12,
                color: color.withAlpha(140),
                fontStyle: FontStyle.italic,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
