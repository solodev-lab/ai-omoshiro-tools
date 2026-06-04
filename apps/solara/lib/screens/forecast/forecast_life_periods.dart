import 'package:flutter/material.dart';
import '../../i18n/strings.g.dart';
import '../../utils/forecast_cache.dart';
import '../../utils/solara_i18n.dart';
import '../../widgets/info_popup.dart';
import '../map/map_constants.dart';
import 'forecast_section_header.dart';

/// 期間ラベル定義（カテゴリ → (日本語名, 絵文字)）
const Map<String, (String, String)> lifePeriodLabels = {
  'love':          ('モテ期', '💗'),
  'money':         ('豊かさ期', '💰'),
  'healing':       ('癒し期', '🌿'),
  'work':          ('仕事期', '⚙'),
  'communication': ('発信期', '💬'),
};

/// 英語ロケール用カテゴリラベル (短い 1 単語に揃える。
/// 行内の固定幅 (98px) で太字表示しても 1 行に収まる範囲)。
// money は正典で「豊かさ/Abundance」固定 (Wealth/Money は吉凶回避で不可)。
const Map<String, String> lifePeriodLabelsEn = {
  'love':          'Love',
  'money':         'Abundance',
  'healing':       'Healing',
  'work':          'Work',
  'communication': 'Voice',
};

/// 「◯◯期」セクション — 永続保存された運勢サイクルを表示
/// - カテゴリ毎に1件（end >= today の最初の期間）を表示
/// - 過去のみのカテゴリは非表示
class ForecastLifePeriodsSection extends StatelessWidget {
  /// 全期間（カテゴリ混在、loadOrComputePeriods の戻り値）
  final List<LifePeriod> periods;

  const ForecastLifePeriodsSection({
    super.key,
    required this.periods,
  });

  @override
  Widget build(BuildContext context) {
    final byCategory = <String, List<LifePeriod>>{};
    for (final p in periods) {
      byCategory.putIfAbsent(p.category, () => []).add(p);
    }
    for (final list in byCategory.values) {
      list.sort((a, b) => a.start.compareTo(b.start));
    }

    final today = DateTime.now().toUtc();
    final visibleCats = <String>[];
    for (final cat in lifePeriodLabels.keys) {
      final list = byCategory[cat] ?? [];
      if (list.isEmpty) continue;
      if (list.any((p) => !p.end.isBefore(today))) visibleCats.add(cat);
    }

    // カテゴリ名列を「表示中の最長名の実測幅」に固定 → 日付列の開始位置が揃い、
    // かつ端末/アプリのフォント拡大 (実効 ~2x) でも "豊かさ期" 等が切れない。
    final scaler = MediaQuery.textScalerOf(context);
    final isJPmeasure = !isEnLocale();
    double nameW = 0;
    for (final cat in visibleCats) {
      final jaName = lifePeriodLabels[cat]?.$1 ?? cat;
      final nm = isJPmeasure ? jaName : (lifePeriodLabelsEn[cat] ?? jaName);
      final tp = TextPainter(
        text: TextSpan(
            text: nm,
            style:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        textScaler: scaler,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (tp.width > nameW) nameW = tp.width;
    }
    nameW = nameW.ceilToDouble() + 2;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ForecastSectionHeader(
        label: t.forecast.cycles.title,
        onInfo: () => _showLifePeriodsInfo(context),
      ),
      const SizedBox(height: 4),
      Text(t.forecast.cycles.hint,
          style: const TextStyle(fontSize: 9, color: Color(0xFF666666))),
      const SizedBox(height: 10),
      if (visibleCats.isEmpty) Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(t.forecast.cycles.empty,
            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.45))),
      ) else for (final cat in visibleCats)
        _periodRow(context, cat, byCategory[cat]!, today, nameW),
    ]);
  }

  Widget _periodRow(BuildContext context, String cat, List<LifePeriod> list, DateTime today, double nameW) {
    int idx = list.indexWhere((p) => !p.end.isBefore(today));
    if (idx < 0) idx = list.length - 1;
    final p = list[idx];

    // slang ゲートと一致させる (端末 en でも override 未設定なら ja のまま)。
    final isJP = !isEnLocale();
    final label = lifePeriodLabels[cat];
    final (jaName, emoji) = label ?? (cat, '✨');
    // 表示名は ja/en 切替。英語ラベル未定義カテゴリは ja にフォールバック。
    final name = isJP ? jaName : (lifePeriodLabelsEn[cat] ?? jaName);
    final color = categoryColors[cat] ?? const Color(0xFFC9A84C);
    final startLabel = '${p.start.month}/${p.start.day.toString().padLeft(2, "0")}';
    final endLabel = '${p.end.month}/${p.end.day.toString().padLeft(2, "0")}';
    final sep = isEnLocale() ? ' - ' : ' 〜 ';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 24,
            child: Text(emoji, style: const TextStyle(fontSize: 14))),
        // emoji と名前が近く見えるため隙間を入れる (英語 ~2x で特に窮屈)。
        const SizedBox(width: 8),
        // カテゴリ名列は「表示中の最長名の実測幅 (nameW)」に固定 → 日付列が揃い、
        // フォント拡大でも切れない (旧 80px 固定は実効 ~2x で "豊かさ期" が見切れた)。
        SizedBox(
          width: nameW,
          child: Text(
            name,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Text('$startLabel$sep$endLabel',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFFE8E0D0)))),
        SizedBox(
          width: 66,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(isJP ? '${p.days}日間' : '${p.days}d',
                maxLines: 1,
                style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
          ),
        ),
      ]),
    );
  }
}

/// 運勢サイクル説明 popup (見出し横の i ボタンから開く)。
void _showLifePeriodsInfo(BuildContext context) {
  showInfoPopup(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.forecast.cycles.infoTitle,
          style: const TextStyle(
              color: Color(0xFFC9A84C), fontSize: 14, letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        Text(
          t.forecast.cycles.s1Title,
          style: const TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          t.forecast.cycles.s1Body,
          style: const TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 10),
        Text(
          t.forecast.cycles.s2Title,
          style: const TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          t.forecast.cycles.s2Body,
          style: const TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 10),
        Text(
          t.forecast.cycles.s3Title,
          style: const TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          t.forecast.cycles.s3Body,
          style: const TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 10),
        Text(
          t.forecast.cycles.footer,
          style: const TextStyle(
              color: Color(0xFF999999), fontSize: 11, height: 1.5),
        ),
      ],
    ),
  );
}
