// 過去サイクル履歴パネル — 月サイクルをまたいで GalaxyCycle に取り込まれた
// 過去 readings を、 cycle 別にグルーピングして閲覧する。
//
// 設計 (2026-05-19、 オーナー要望):
// - 柱3 原則「Free でも自分の記録は永久に残る」徹底
// - 現在サイクルの readings は ObserveHistoryPanel で見える
// - 過去サイクルの readings は GalaxyCycle.readings に取り込まれて
//   通常の HISTORY 画面からは見えなくなっていた → 本 widget で復活
//
// 注: MVP として SYNCHRONICITY メモは表示のみ (編集は後フェーズ)。
// 完了サイクルに含まれる reading の synchronicity は cycle.readings 内に
// 凍結状態で残るため、 編集には completed_cycles 全体の再書込が必要で、
// オペレーションコストが高い。 まずは閲覧から。

import 'package:flutter/material.dart';

import '../../models/daily_reading.dart';
import '../../models/galaxy_cycle.dart';
import '../../models/tarot_card.dart';
import '../../theme/solara_colors.dart';
import '../../utils/solara_storage.dart';
import '../../utils/tarot_data.dart';
import '../../widgets/memo_text_field.dart';
import 'observe_constants.dart';
import 'observe_reading_button.dart';

class ObserveHistoryPastPanel extends StatefulWidget {
  final List<GalaxyCycle> cycles;
  const ObserveHistoryPastPanel({super.key, required this.cycles});

  @override
  State<ObserveHistoryPastPanel> createState() =>
      _ObserveHistoryPastPanelState();
}

class _ObserveHistoryPastPanelState extends State<ObserveHistoryPastPanel> {
  /// 展開中の cycle id (1 件のみ展開、複数同時展開しない設計)
  String? _expandedCycleId;

  /// 展開中の reading の date (cycle 内で 1 件のみ)
  String? _expandedReadingDate;

  @override
  Widget build(BuildContext context) {
    // 新しいサイクルが先頭になるよう effectiveFormedAt 降順で並べる。
    final ordered = widget.cycles.toList()
      ..sort((a, b) => b.effectiveFormedAt.compareTo(a.effectiveFormedAt));

    if (ordered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Text(
          '過去のサイクルはまだありません\n\n'
          '月が満ちて新しいサイクルに入ると、\n'
          'それまでのタロット履歴がここに残ります。',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF666666), fontSize: 12, height: 1.8),
        ),
      );
    }

    return ListView.builder(
      itemCount: ordered.length,
      itemBuilder: (ctx, i) => _buildCycleCard(ordered[i]),
    );
  }

  Widget _buildCycleCard(GalaxyCycle cycle) {
    final expanded = _expandedCycleId == cycle.id;
    final formed = cycle.effectiveFormedAt.toLocal();
    final dateLabel =
        '${formed.year}/${formed.month.toString().padLeft(2, '0')}/${formed.day.toString().padLeft(2, '0')}';
    final count = cycle.readings.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0x800F0F1E),
        border: Border.all(color: const Color(0x33F9D976)),
      ),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() {
            _expandedCycleId = expanded ? null : cycle.id;
            _expandedReadingDate = null;
          }),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            cycle.nameJP.isNotEmpty
                                ? cycle.nameJP
                                : cycle.nameEN,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFE8E0D0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '★${cycle.rarity}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: SolaraColors.solaraGoldLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$dateLabel · $count 件',
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF888888)),
                    ),
                  ],
                ),
              ),
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                size: 24,
                color: const Color(0xFFC9A84C),
              ),
            ]),
          ),
        ),
        if (expanded) _buildReadingsList(cycle),
      ]),
    );
  }

  Widget _buildReadingsList(GalaxyCycle cycle) {
    if (cycle.readings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Text(
          'このサイクルにはタロット履歴がありません',
          style: TextStyle(fontSize: 11, color: Color(0xFF666666)),
        ),
      );
    }
    // 新しい reading が上に来るよう日付降順
    final readings = cycle.readings.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return Container(
      decoration: const BoxDecoration(
        color: Color(0x660A0A14),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        children: [
          for (final r in readings) _buildReadingRow(cycle, r),
        ],
      ),
    );
  }

  Widget _buildReadingRow(GalaxyCycle cycle, DailyReading r) {
    final card = TarotData.getCard(r.cardId);
    final elColor = Color(elementColors[card.element] ?? 0xFFC9A84C);
    final expanded = _expandedReadingDate == r.date;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0x660F0F1E),
        border: Border(left: BorderSide(color: elColor, width: 2)),
      ),
      child: Column(children: [
        InkWell(
          onTap: () => setState(
              () => _expandedReadingDate = expanded ? null : r.date),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(children: [
              SizedBox(
                  width: 30,
                  child: Text(card.emoji,
                      style: const TextStyle(fontSize: 22),
                      textAlign: TextAlign.center)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(card.nameJP,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFE8E0D0),
                              fontWeight: FontWeight.w500,
                            )),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        r.reversed ? '逆' : '正',
                        style: TextStyle(
                          fontSize: 10,
                          color: r.reversed
                              ? const Color(0xFFB088FF)
                              : const Color(0xFFC9A84C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Text(r.date,
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF666666))),
                  ],
                ),
              ),
              Icon(expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20, color: const Color(0xFFC9A84C)),
            ]),
          ),
        ),
        if (expanded) _buildReadingDetail(cycle, card, r),
      ]),
    );
  }

  Widget _buildReadingDetail(GalaxyCycle cycle, TarotCard card, DailyReading r) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (r.question != null && r.question!.isNotEmpty) ...[
          const Row(children: [
            Text('❓', style: TextStyle(fontSize: 10, color: Color(0xFFC9A84C))),
            SizedBox(width: 4),
            Text('QUESTION',
                style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFFC9A84C),
                    letterSpacing: 1)),
          ]),
          const SizedBox(height: 4),
          Text(r.question!,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xCCE8E0D0), height: 1.6)),
          const SizedBox(height: 10),
        ],
        if (r.reading.isNotEmpty) ...[
          const Row(children: [
            Text('🔮', style: TextStyle(fontSize: 10, color: Color(0xFFC9A84C))),
            SizedBox(width: 4),
            Text('READING',
                style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFFC9A84C),
                    letterSpacing: 1)),
          ]),
          const SizedBox(height: 4),
          Text(r.reading,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xD9E8E0D0), height: 1.7)),
          const SizedBox(height: 6),
          ObserveFullReadingButton(card: card, reading: r),
          const SizedBox(height: 10),
        ],
        // 🔴 (2026-05-19) 過去サイクルのメモも編集可能に変更。
        // SolaraStorage.updateCompletedCycleReadingSynchronicity で完了サイクル
        // 内の reading.synchronicity を直接書き換える (全 cycles 書き戻し)。
        // ローカル DailyReading も同期して再描画時に最新値が見えるようにする。
        const Row(children: [
          Text('🔗', style: TextStyle(fontSize: 10, color: Color(0xFF888888))),
          SizedBox(width: 4),
          Text('SYNCHRONICITY',
              style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF888888),
                  letterSpacing: 1)),
        ]),
        const SizedBox(height: 4),
        MemoTextField(
          key: ValueKey('past-memo-${cycle.id}-${r.date}'),
          initialText: r.synchronicity,
          hintText: '当時の気づきをメモ...',
          onChanged: (text) {
            r.synchronicity = text;
            SolaraStorage.updateCompletedCycleReadingSynchronicity(
                cycle.id, r.date, text);
          },
        ),
      ]),
    );
  }
}

// _FullReadingButton は observe_reading_button.dart の ObserveFullReadingButton
// に統合 (2026-05-19、 observe_history.dart 側との重複を解消)。
