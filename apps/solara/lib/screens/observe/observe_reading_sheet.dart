// タロット履歴 — 「📖 占いの全文を読みやすく表示」シート (Free 開放 2026-06-03)
//
// 設計:
//   - HISTORY 詳細展開でも READING 本文は表示されるが、一覧で全文を見ると
//     圧迫感がある。希望者だけ集中して読める読書モードを提供する。
//   - 縦スクロール 1 ページ、フォント大きめ・行間広め。
//   - 装飾は最小限 (カード名 + 日付ヘッダ + READING 本文 + close)。
//
// 呼出: observe/observe_history.dart の _FullReadingButton から
//       showObserveReadingSheet(context, card, reading) で起動。

import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../../models/daily_reading.dart';
import '../../models/tarot_card.dart';
import '../../theme/solara_colors.dart';
import 'observe_constants.dart';

Future<void> showObserveReadingSheet(
  BuildContext context, {
  required TarotCard card,
  required DailyReading reading,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    builder: (ctx) => _ReadingSheet(card: card, reading: reading),
  );
}

class _ReadingSheet extends StatelessWidget {
  final TarotCard card;
  final DailyReading reading;
  const _ReadingSheet({required this.card, required this.reading});

  @override
  Widget build(BuildContext context) {
    final elColor = Color(elementColors[card.element] ?? 0xFFC9A84C);
    final maxH = MediaQuery.of(context).size.height * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xF20A0A14),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: elColor.withValues(alpha: 0.55), width: 2),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── grab handle ──
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // ── header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 12, 6),
                child: Row(children: [
                  Text(card.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(children: [
                          Flexible(
                            child: Text(card.nameJP,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFFE8E0D0),
                                  fontWeight: FontWeight.w500,
                                )),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            reading.reversed ? t.observe.posShortReversed : t.observe.posShortUpright,
                            style: TextStyle(
                              fontSize: 11,
                              color: reading.reversed
                                  ? const Color(0xFFB088FF)
                                  : const Color(0xFFC9A84C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 2),
                        Text('${reading.date} · ${card.keyword}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF888888),
                            )),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 22, color: Color(0xFFAAAAAA)),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ]),
              ),
              const Divider(height: 1, color: Color(0x1AFFFFFF)),
              // ── body: READING 全文 (Pro でここを集中して読める) ──
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (reading.question != null &&
                          reading.question!.isNotEmpty) ...[
                        const Row(children: [
                          Text('❓',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFFC9A84C))),
                          SizedBox(width: 4),
                          Text('QUESTION',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFC9A84C),
                                  letterSpacing: 1.2)),
                        ]),
                        const SizedBox(height: 8),
                        Text(
                          reading.question!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xCCE8E0D0),
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                      const Row(children: [
                        Text('🔮',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFFC9A84C))),
                        SizedBox(width: 4),
                        Text('READING',
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFC9A84C),
                                letterSpacing: 1.2)),
                      ]),
                      const SizedBox(height: 10),
                      SelectableText(
                        reading.reading,
                        style: const TextStyle(
                          fontSize: 15,
                          color: SolaraColors.textPrimary,
                          height: 2.0,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
