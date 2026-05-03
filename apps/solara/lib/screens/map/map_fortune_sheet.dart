import 'package:flutter/material.dart';

import '../../utils/direction_energy.dart';
import 'map_constants.dart';
import 'map_direction_popup.dart';
import 'map_widgets.dart';

/// pct() from HTML: 0-5 → 0-83.3%, 5-10 → 83.3-100%
double pctValue(double v) {
  if (v <= 5) return (v / 5) * (100 * 5 / 6);
  return (5 / 6) * 100 + (1 / 6) * 100 * ((v - 5) / 5).clamp(0, 1);
}

/// HTML: .ff-label { top:52px; left:16px; inline-flex row: ff-tag + ff-bars }
class FortuneFilterLabel extends StatelessWidget {
  final Map<String, double> sectorScores;
  final String activeSrc;
  final String activeCategory;
  /// タップでカテゴリ次へ切替 (2026-04-30 オーナー要望)。
  /// 渡されない場合はタップ無効。
  final VoidCallback? onTap;

  const FortuneFilterLabel({
    super.key,
    required this.sectorScores,
    required this.activeSrc,
    required this.activeCategory,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = sectorScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.isEmpty) return const SizedBox();

    final top2 = sorted.where((e) => e.value > 0.01).take(2).toList();
    final maxScore = top2.isNotEmpty ? top2.first.value : 1.0;
    final catColor = categoryColors[activeCategory] ?? const Color(0xFFC9A84C);

    // 端末幅に応じてレイアウト寸法を可変化:
    //   - 左ラベル (合計/総合) を画面幅の 32% で頭打ち + ellipsis
    //     → 英語表記 (Total/Communication) でも他要素を圧迫しない
    //   - 方角ラベル幅 44 (旧 32) → "東南東" 3 文字が 1 行に収まる
    //   - バー幅は LayoutBuilder で残幅から逆算 (60-110 px clamp)
    final screenW = MediaQuery.of(context).size.width;
    final leftLabelMax = screenW * 0.32;
    const dirLabelW = 44.0;
    const valueLabelW = 28.0;
    const innerHPad = 10.0;  // Container horizontal padding (片側)
    const sideMargin = 16.0;  // 親 Positioned の left:16 分
    // 残幅 = 画面幅 − サイドマージン − 左ラベル − Container padding × 2
    //         − 6 (左ラベルとバー列の間) − dirLabelW − 4 − valueLabelW − 4
    final reserved = sideMargin + leftLabelMax + innerHPad * 2 + 6 + dirLabelW + 4 + valueLabelW + 4;
    final barW = (screenW - reserved).clamp(60.0, 110.0);

    // ClipRRect で境界半径を維持しつつ、sub-pixel オーバーフローを視覚的に吸収
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: innerHPad, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xB30A0A14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x4DC9A84C)),
        ),
        // IntrinsicWidth は使わない — dry layout の sub-pixel 丸め誤差で 0.x px
        // オーバーフロー警告が出ることがある。mainAxisSize.min だけで十分。
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: leftLabelMax),
              child: Text(
                '${srcLabels[activeSrc] ?? '合計'} / ${categoryLabels[activeCategory] ?? '総合'}',
                style: const TextStyle(fontSize: 10, color: Color(0xFFC9A84C), letterSpacing: 0.5, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (top2.isNotEmpty) ...[
              const SizedBox(width: 6),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: top2.map((e) {
                  final pct = (e.value / maxScore).clamp(0.0, 1.0);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(width: dirLabelW, child: Text(
                        dir16JP[e.key] ?? e.key,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF888888), fontWeight: FontWeight.w500),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: barW, height: 5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0x15FFFFFF),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: pct,
                            child: Container(
                              decoration: BoxDecoration(
                                color: catColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(width: valueLabelW, child: Text(
                        e.value.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 8, fontFamily: 'monospace', color: Color(0xFFF6BD60), fontWeight: FontWeight.w600),
                        textAlign: TextAlign.right,
                      )),
                    ]),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}

/// Fortune Sheet — HTML: .fs { bottom:80px; border-radius:16px 16px 0 0; }
class FortuneSheet extends StatelessWidget {
  final String activeSrc;
  final String activeCategory;
  final Map<String, Map<String, double>> sectorComps;
  /// E4: 2エネルギー詳細ポップアップ用。指定時、各方角行をタップで詳細を表示。
  final Map<String, DirectionEnergy>? sectorEnergies;
  /// E4: アスペクト attribution 用（行タップ時の詳細に表示）。
  final Map<String, List<AspectContribution>>? sectorContributors;
  final ValueChanged<String> onSrcChanged;
  final ValueChanged<String> onCatChanged;
  final VoidCallback onClose;

  const FortuneSheet({
    super.key,
    required this.activeSrc,
    required this.activeCategory,
    required this.sectorComps,
    this.sectorEnergies,
    this.sectorContributors,
    required this.onSrcChanged,
    required this.onCatChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF20A0A19),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: Color(0x40C9A84C))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) > 0) onClose();
            },
            onVerticalDragUpdate: (details) {
              if ((details.primaryDelta ?? 0) > 8) onClose();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              alignment: Alignment.center,
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x40FFFFFF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          _buildSrcTabs(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LegendDot(color: compColors['tSoft']!, label: 'Tソフト'),
                const SizedBox(width: 8),
                LegendDot(color: compColors['tHard']!, label: 'Tハード'),
                const SizedBox(width: 8),
                LegendDot(color: compColors['pSoft']!, label: 'Pソフト'),
                const SizedBox(width: 8),
                LegendDot(color: compColors['pHard']!, label: 'Pハード'),
              ],
            ),
          ),
          _buildCatTabs(),
          SizedBox(
            height: 185,
            child: RawScrollbar(
              thumbColor: const Color(0x40C9A84C),
              radius: const Radius.circular(2),
              thickness: 3,
              thumbVisibility: true,
              child: Builder(builder: (rowsContext) => ListView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                children: _buildFortuneRows(rowsContext),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSrcTabs() {
    const srcs = [('combined', '合計'), ('transit', 'トランジット'), ('progressed', 'プログレス')];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x14FFFFFF))),
      ),
      child: Row(
        children: srcs.map((s) {
          final active = activeSrc == s.$1;
          return GestureDetector(
            onTap: () => onSrcChanged(s.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(
                  color: active ? const Color(0xFFC9A84C) : Colors.transparent, width: 2)),
              ),
              child: Text(s.$2, style: TextStyle(fontSize: 11,
                color: active ? const Color(0xFFC9A84C) : const Color(0xFF666666))),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCatTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0FFFFFFF))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categoryColors.entries.map((e) {
            final active = activeCategory == e.key;
            return GestureDetector(
              onTap: () => onCatChanged(e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(
                    color: active ? const Color(0xFFC9A84C) : Colors.transparent, width: 2)),
                ),
                child: Text(categoryLabels[e.key] ?? e.key, style: TextStyle(fontSize: 10,
                  color: active ? const Color(0xFFC9A84C) : const Color(0xFF666666))),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  List<Widget> _buildFortuneRows(BuildContext rowsContext) {
    final ck = activeSrc == 'transit' ? ['tSoft', 'tHard']
             : activeSrc == 'progressed' ? ['pSoft', 'pHard']
             : compKeys;

    final dt = <String, double>{};
    for (final d in dir16) {
      final c = sectorComps[d] ?? {};
      double t = 0;
      for (final k in ck) { t += (c[k] ?? 0); }
      dt[d] = t;
    }

    final sorted = dir16.toList()..sort((a, b) => (dt[b] ?? 0).compareTo(dt[a] ?? 0));
    final visible = sorted.where((d) => (dt[d] ?? 0) > 0.01).toList();

    return List.generate(visible.length, (i) {
      final dir = visible[i];
      final total = dt[dir]!;
      final pct = (pctValue(total) / 100).clamp(0.0, 1.0);
      final comp = sectorComps[dir] ?? {};
      final isLast = i == visible.length - 1;

      final segs = <Widget>[];
      for (final k in ck) {
        final v = comp[k] ?? 0;
        if (v < 0.001) continue;
        segs.add(Expanded(
          flex: (v * 1000).round(),
          child: Container(color: compColors[k]),
        ));
      }

      // E4: 2エネルギー詳細を表示できる場合は行をタップ可能にする。
      final canShowDetail = sectorEnergies != null && sectorEnergies![dir] != null;
      final rowContent = Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: Color(0x0AFFFFFF))),
        ),
        child: Row(children: [
          SizedBox(width: 36, child: Text(dir16JP[dir] ?? dir,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFB49774)))),
          Expanded(
            child: Container(
              height: 14, margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0x0AFFFFFF),
                borderRadius: BorderRadius.circular(7),
              ),
              child: LayoutBuilder(builder: (ctx, constraints) {
                final barW = constraints.maxWidth;
                return Stack(children: [
                  for (int t = 1; t <= 5; t++)
                    Positioned(
                      left: barW * t / 6, top: 0, bottom: 0,
                      child: Container(width: 1, color: const Color(0x21FFFFFF)),
                    ),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: pct,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Row(children: segs.isNotEmpty ? segs : [Expanded(child: Container())]),
                    ),
                  ),
                ]);
              }),
            ),
          ),
          SizedBox(width: 48, child: Text(total.toStringAsFixed(1),
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFFF6BD60)),
            textAlign: TextAlign.right)),
          if (canShowDetail)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.chevron_right, size: 14, color: Color(0x88888888)),
            ),
        ]),
      );

      if (!canShowDetail) return rowContent;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showDirectionEnergyPopup(
          rowsContext,
          direction: dir,
          energy: sectorEnergies![dir]!,
          contributors: sectorContributors?[dir] ?? const [],
          categoryLabel: categoryLabels[activeCategory],
        ),
        child: rowContent,
      );
    });
  }
}
