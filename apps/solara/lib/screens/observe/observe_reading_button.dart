// 「📖 占いの全文を読みやすく表示」ボタン共通実装 (2026-05-19)。
//
// observe_history.dart (現在サイクル HISTORY) と observe_history_past.dart
// (過去サイクル HISTORY) の両方で使うため、 重複コードを 1 つに集約。
//
// 役割:
//   - Pro: タップで observe_reading_sheet を起動 (READING 全文を独立シート表示)
//   - Free: タップで Pro Unlock dialog 表示

import 'package:flutter/material.dart';

import '../../models/daily_reading.dart';
import '../../models/tarot_card.dart';
import '../../theme/solara_colors.dart';
import '../../utils/pro_status.dart';
import '../../widgets/pro_unlock_dialog.dart';
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
    final isPro = ProStatus.instance.isPro;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isPro) {
          showObserveReadingSheet(context, card: card, reading: reading);
        } else {
          showProUnlockDialog(
            context,
            featureLabel: '占いの全文を読み返す',
            description: '過去にカードを引いたときの Stella の言葉を、'
                '読書するように 1 枚画面に集中して読み返せます。',
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPro
                ? const Color(0x66F6BD60)
                : const Color(0x33F6BD60),
          ),
          color: isPro ? const Color(0x14F6BD60) : const Color(0x08F6BD60),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📖', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 6),
            const Flexible(
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
            if (!isPro) ...[
              const SizedBox(width: 6),
              const Icon(Icons.lock_outline,
                  size: 11, color: Color(0xFFF6BD60)),
              const SizedBox(width: 3),
              const Text('Pro',
                  style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFFF6BD60),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4)),
            ],
          ],
        ),
      ),
    );
  }
}
