// 「📖 占いの全文を読みやすく表示」ボタン共通実装 (2026-05-19)。
//
// observe_history.dart (現在サイクル HISTORY) と observe_history_past.dart
// (過去サイクル HISTORY) の両方で使うため、 重複コードを 1 つに集約。
//
// 役割: タップで observe_reading_sheet を起動 (READING 全文を独立シート表示)。
//   2026-06-03: Pro 限定を撤去し、Free でも使えるよう開放 (オーナー指示)。

import 'package:flutter/material.dart';

import '../../models/daily_reading.dart';
import '../../models/tarot_card.dart';
import '../../theme/solara_colors.dart';
import 'observe_reading_sheet.dart';

class ObserveFullReadingButton extends StatelessWidget {
  final TarotCard card;
  final DailyReading reading;
  const ObserveFullReadingButton({
    super.key,
    required this.card,
    required this.reading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          showObserveReadingSheet(context, card: card, reading: reading),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x66F6BD60)),
          color: const Color(0x14F6BD60),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📖', style: TextStyle(fontSize: 11)),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                '全文を読みやすく表示',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: SolaraColors.solaraGoldLight,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
