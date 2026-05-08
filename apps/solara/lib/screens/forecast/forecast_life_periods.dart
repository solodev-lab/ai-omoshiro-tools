import 'package:flutter/material.dart';
import '../../utils/forecast_cache.dart';
import '../../widgets/info_popup.dart';
import '../map/map_constants.dart';

/// 期間ラベル定義（カテゴリ → (日本語名, 絵文字)）
const Map<String, (String, String)> lifePeriodLabels = {
  'love':          ('モテ期', '💗'),
  'money':         ('豊かさ期', '💰'),
  'healing':       ('癒し期', '🌿'),
  'work':          ('仕事期', '⚙'),
  'communication': ('発信期', '💬'),
};

/// 「◯◯期」セクション — 永続保存された運勢サイクルを表示
/// - カテゴリ毎に1件（end >= today の最初の期間）を表示
/// - 過去のみのカテゴリは非表示
class ForecastLifePeriodsSection extends StatelessWidget {
  /// 全期間（カテゴリ混在、loadOrComputePeriods の戻り値）
  final List<LifePeriod> periods;

  /// 開始日を Map で見るタップ時のコールバック（null なら Map ボタン非表示）
  final void Function(DateTime date)? onJumpToDate;

  const ForecastLifePeriodsSection({
    super.key,
    required this.periods,
    this.onJumpToDate,
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

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('▸ あなたの運勢サイクル',
            style: TextStyle(fontSize: 11, color: Color(0xFFC9A84C), letterSpacing: 2)),
        const SizedBox(width: 4),
        // ⓘ 運勢サイクル説明 popup
        GestureDetector(
          onTap: () => _showLifePeriodsInfo(context),
          behavior: HitTestBehavior.opaque,
          child: const Padding(
            padding: EdgeInsets.all(2),
            child: Icon(Icons.info_outline,
                size: 13, color: Color(0xCCAAAAAA)),
          ),
        ),
      ]),
      const SizedBox(height: 4),
      const Text('今日以降に到来する期間を表示（7日以上の継続）',
          style: TextStyle(fontSize: 9, color: Color(0xFF666666))),
      const SizedBox(height: 10),
      if (visibleCats.isEmpty) Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('今日以降に予測される期間なし',
            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.45))),
      ) else for (final cat in visibleCats)
        _periodRow(context, cat, byCategory[cat]!, today),
    ]);
  }

  Widget _periodRow(BuildContext context, String cat, List<LifePeriod> list, DateTime today) {
    int idx = list.indexWhere((p) => !p.end.isBefore(today));
    if (idx < 0) idx = list.length - 1;
    final p = list[idx];

    final label = lifePeriodLabels[cat];
    final (name, emoji) = label ?? (cat, '✨');
    final color = categoryColors[cat] ?? const Color(0xFFC9A84C);
    final startLabel = '${p.start.month}/${p.start.day.toString().padLeft(2, "0")}';
    final endLabel = '${p.end.month}/${p.end.day.toString().padLeft(2, "0")}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 24,
            child: Text(emoji, style: const TextStyle(fontSize: 14))),
        SizedBox(width: 62,
            child: Text(name,
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600))),
        Expanded(child: Text('$startLabel 〜 $endLabel',
            style: const TextStyle(fontSize: 11, color: Color(0xFFE8E0D0)))),
        SizedBox(width: 50,
            child: Text('${p.days}日間',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 10, color: Color(0xFF888888)))),
        if (onJumpToDate != null) IconButton(
          icon: const Icon(Icons.map_outlined, size: 16, color: Color(0xFF888888)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          tooltip: '開始日を Map で見る',
          onPressed: () {
            onJumpToDate!(DateTime.utc(p.start.year, p.start.month, p.start.day, 3, 0, 0));
            Navigator.of(context).maybePop();
          },
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
      children: const [
        Text(
          '運勢サイクルとは',
          style: TextStyle(
              color: Color(0xFFC9A84C), fontSize: 14, letterSpacing: 1),
        ),
        SizedBox(height: 10),
        Text(
          '【表示の意味】',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4),
        Text(
          '今後 1 年で、各カテゴリ (恋愛 / 豊かさ / 癒し /\n'
          '仕事 / 話す) のエネルギーが強く流れる「期間」を\n'
          '表示します。\n\n'
          '例:「💗 モテ期 6/15 〜 7/2 (18 日間)」\n'
          '　 → 6/15 から 7/2 まで関係性のエネルギーが\n'
          '　   継続して強い時期',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        SizedBox(height: 10),
        Text(
          '【表示条件】',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4),
        Text(
          '・今日以降に到来する期間のみ表示\n'
          '　(過ぎた期間は非表示)\n'
          '・7 日以上連続して強い場合のみ「期間」と認定\n'
          '　(短い波は表示しない)\n'
          '・カテゴリごとに最も近い 1 件ずつ表示',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        SizedBox(height: 10),
        Text(
          '【活用方法】',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4),
        Text(
          '「いつ動くか」の長期計画に。\n'
          '各期間の開始日を 🗺 ボタンで Map に飛ばして、\n'
          'その日の方角・時間と組み合わせて活用できます。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
      ],
    ),
  );
}
