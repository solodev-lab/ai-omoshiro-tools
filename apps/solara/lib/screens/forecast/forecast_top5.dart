import 'package:flutter/material.dart';
import '../../utils/forecast_cache.dart';
import '../map/map_constants.dart';

/// 強運Top5 セクション — 永続保存された Top5 を mode 別に表示
/// mode 切替で再計算しない（loadOrComputeTop5 が永続化）
class ForecastTop5Section extends StatelessWidget {
  /// mode → 上位5日（loadOrComputeTop5 の戻り値）
  final Map<String, List<ForecastDay>> top5;

  /// 現在の表示 mode（'overall' | 'love' | 'money' | 'healing' | 'work' | 'communication'）
  final String mode;

  /// mode 切替コールバック
  final ValueChanged<String> onModeChange;

  /// 行タップで該当日を選択するコールバック
  final ValueChanged<ForecastDay> onSelect;

  /// その日を Map で見るコールバック（null なら Map ボタン非表示）
  final void Function(DateTime date)? onJumpToDate;

  const ForecastTop5Section({
    super.key,
    required this.top5,
    required this.mode,
    required this.onModeChange,
    required this.onSelect,
    this.onJumpToDate,
  });

  @override
  Widget build(BuildContext context) {
    final list = top5[mode] ?? const <ForecastDay>[];
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('▸ 強運Top5',
          style: TextStyle(fontSize: 11, color: Color(0xFFC9A84C), letterSpacing: 2)),
      const SizedBox(height: 8),
      _modeSelector(),
      const SizedBox(height: 10),
      for (int i = 0; i < list.length; i++) _row(context, i, list[i]),
    ]);
  }

  Widget _modeSelector() {
    final modes = <Map<String, Object>>[
      {'key': 'overall', 'label': '総合', 'color': const Color(0xFFC9A84C)},
      {'key': 'love', 'label': '恋愛', 'color': categoryColors['love']!},
      {'key': 'money', 'label': '金運', 'color': categoryColors['money']!},
      {'key': 'healing', 'label': '癒し', 'color': categoryColors['healing']!},
      {'key': 'work', 'label': '仕事', 'color': categoryColors['work']!},
      {'key': 'communication', 'label': '話す', 'color': categoryColors['communication']!},
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final m in modes)
          _seg(m['key'] as String, m['label'] as String, m['color'] as Color),
      ]),
    );
  }

  Widget _seg(String key, String label, Color color) {
    final active = mode == key;
    return GestureDetector(
      onTap: () => onModeChange(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        margin: const EdgeInsets.only(right: 5),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.22) : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? color : const Color(0x22FFFFFF)),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 10,
              color: active ? color : const Color(0xFF888888),
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            )),
      ),
    );
  }

  /// 順位マーカー: 👑 / 🥈 / 🥉 / ⭐ / ✨（1位=王冠、以降はメダル→星の段階表示）
  static const _rankMarkers = ['👑', '🥈', '🥉', '⭐', '✨'];

  Widget _row(BuildContext context, int rank, ForecastDay d) {
    final parts = d.date.split('-');
    final dateLabel = '${parts[1]}/${parts[2]}';

    final isOverall = mode == 'overall';
    final score = isOverall ? d.overall : (d.catScores[mode] ?? 0);
    final modeColor = isOverall
        ? const Color(0xFFC9A84C)
        : (categoryColors[mode] ?? const Color(0xFFE8E0D0));
    final marker = rank < _rankMarkers.length ? _rankMarkers[rank] : '#${rank + 1}';

    return InkWell(
      onTap: () => onSelect(d),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(width: 28,
              child: Center(child: Text(marker,
                  style: const TextStyle(fontSize: 16)))),
          SizedBox(width: 50,
              child: Text(dateLabel,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFE8E0D0)))),
          Expanded(child: Text('${dir16JP[d.topDir] ?? d.topDir}方位',
              style: const TextStyle(fontSize: 10, color: Color(0xFF999999)))),
          Text(score.toStringAsFixed(1),
              style: TextStyle(fontSize: 11, color: modeColor, fontWeight: FontWeight.w600)),
          if (onJumpToDate != null) IconButton(
            icon: const Icon(Icons.map_outlined, size: 16, color: Color(0xFF888888)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            tooltip: 'その日をMapで見る',
            onPressed: () {
              final ps = d.date.split('-').map(int.parse).toList();
              final date = DateTime.utc(ps[0], ps[1], ps[2], 3, 0, 0);
              onJumpToDate!(date);
              Navigator.of(context).maybePop();
            },
          ),
        ]),
      ),
    );
  }
}
