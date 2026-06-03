import 'package:flutter/material.dart';
import '../../utils/forecast_cache.dart';
import '../../widgets/info_popup.dart';
import '../map/map_constants.dart';
import 'forecast_section_header.dart';

/// 強運Top5 セクション — 永続保存された Top5 を mode 別に表示
/// mode 切替で再計算しない（loadOrComputeTop5 が永続化）
class ForecastTop5Section extends StatelessWidget {
  /// mode → 上位5日（loadOrComputeTop5 の戻り値）
  final Map<String, List<ForecastDay>> top5;

  /// 現在の表示 mode（'overall' | 'love' | 'money' | 'healing' | 'work' | 'communication'）
  final String mode;

  /// 集計対象の暦年 (西暦)。見出し右に表示する。Top5 はこの年の 1/1〜12/31 から算出。
  final int year;

  /// mode 切替コールバック
  final ValueChanged<String> onModeChange;

  /// 行タップで該当日を選択するコールバック
  final ValueChanged<ForecastDay> onSelect;

  const ForecastTop5Section({
    super.key,
    required this.top5,
    required this.mode,
    required this.year,
    required this.onModeChange,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final list = top5[mode] ?? const <ForecastDay>[];
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ForecastSectionHeader(
        label: 'ハイライトTop5',
        onInfo: () => _showTop5Info(context),
        // 集計対象の暦年 (西暦) を右端に表示。
        trailing: Text('$year年',
            style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFC9A84C),
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600)),
      ),
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
      {'key': 'money', 'label': '豊かさ', 'color': categoryColors['money']!},
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

  Widget _row(BuildContext _, int rank, ForecastDay d) {
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
          // アイコンと日付の間の余白を広げる。
          const SizedBox(width: 16),
          // 固定幅をやめ 1 行強制 (2 列しか無く余裕があるので折返し不要)。
          Text(dateLabel,
              maxLines: 1,
              softWrap: false,
              style: const TextStyle(fontSize: 14, color: Color(0xFFE8E0D0))),
          // 方位表示は撤去 (2026-05-13)。数字が「方位スコア」と誤読されるのを
          // 防ぐため。方位情報は行タップで開く選択日詳細パネルで確認できる。
          const Spacer(),
          Text(score.toStringAsFixed(1),
              style: TextStyle(fontSize: 11, color: modeColor, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

/// 強運Top5 説明 popup (見出し横の i ボタンから開く)。
void _showTop5Info(BuildContext context) {
  showInfoPopup(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'ハイライト Top5 の読み方',
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
          '表示中の年 (1/1〜12/31) で、選択中の\n'
          'カテゴリのスコアが最も高い 5 日を表示します。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        SizedBox(height: 10),
        Text(
          '【カテゴリ切替】',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4),
        Text(
          '総合 / 恋愛 / 豊かさ / 癒し / 仕事 / 話す から選択。\n'
          '選んだカテゴリの上位 5 日が表示されます。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        SizedBox(height: 10),
        Text(
          '【順位マーカー】',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4),
        Text(
          '👑 1 位 / 🥈 2 位 / 🥉 3 位 / ⭐ 4 位 / ✨ 5 位',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        SizedBox(height: 10),
        Text(
          '【行の見方】',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4),
        Text(
          '日付 — 選択中カテゴリのその日のスコア\n'
          'タップで選択日詳細にジャンプ。\n'
          '(その日の高まる方位は選択日詳細で確認できます)',
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
          '「動きどころ」の短期ピンポイント計画に。\n'
          '特に 1 位の日は、そのカテゴリのテーマで動くと\n'
          'エネルギーが特に強く流れる日です。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        SizedBox(height: 10),
        Text(
          '※ 同じ日でも Map で開いた数字とは別の指標です\n'
          '(場所・時刻に依存しない計算)。\n'
          '詳細は画面上部 ❓ ボタンの「Map 画面の数字との関係」へ。',
          style: TextStyle(
              color: Color(0xFF999999), fontSize: 11, height: 1.5),
        ),
      ],
    ),
  );
}
