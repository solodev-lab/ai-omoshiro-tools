// Tarot カテゴリ選択 確認ポップアップ
//
// 全体運以外のカテゴリ chip をタップしたときに表示する。
// - 現在のクレジット残 (無料 / 購入) を提示
// - 「引く」 = カテゴリ確定 (この後ユーザーがカードをタップして 1 クレジット消費)
// - 「キャンセル」/ × / 外タップ = 全体運に戻す (呼出側で判定)
// - 「クレジットを購入」 = 追加クレジット購入シート (呼出側で開く)
//
// showInfoPopup 経由 (popup 統一規約)。呼出側は returned bool で proceed/cancel を判定。
// 設計参考: consultation_start_popup.dart
//
// 関連: project_solara_stella_free_credits.md (1 クレジット = AI 占い 1 回)

import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../../theme/solara_colors.dart';
import '../../utils/consultation_api.dart';
import '../../widgets/info_popup.dart';

/// カテゴリ確認ポップアップを開く。
///
/// 戻り値:
///   - true  : 「引く」が押された (カテゴリを確定して Tarot 画面に戻る)
///   - false : それ以外 (× / 外タップ / キャンセル / 購入シート遷移)
///            呼出側は全体運に戻すか、購入シートを処理する。
Future<bool> showTarotCategoryPopup({
  required BuildContext context,
  required String categoryLabel,
  required ConsultationCreditStatus? status,
  required VoidCallback onBuy,
}) async {
  var proceed = false;
  await showInfoPopup(
    context: context,
    child: _TarotCategoryPopupBody(
      categoryLabel: categoryLabel,
      status: status,
      onProceed: () => proceed = true,
      onBuy: onBuy,
    ),
  );
  return proceed;
}

class _TarotCategoryPopupBody extends StatelessWidget {
  final String categoryLabel;
  final ConsultationCreditStatus? status;
  final VoidCallback onProceed;
  final VoidCallback onBuy;

  const _TarotCategoryPopupBody({
    required this.categoryLabel,
    required this.status,
    required this.onProceed,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final st = status;
    final freeRemaining = st?.freeRemaining;
    final freeLimit = st?.freeLimit;
    final purchased = st?.purchasedBalance ?? 0;
    final hasFree = (freeRemaining ?? 0) > 0;
    final hasPaid = purchased > 0;
    // 2026-05-26 改修: クレジット 0 (Free 試食使い切り × 購入残高 0) の場合は
    // 「引く」ボタンを disabled にして「クレジットを購入」のみ強調する。
    final hasAnyCredit = hasFree || hasPaid;

    // タイトル: 次に消費されるクレジット種別を反映 (消費順=無料→購入)。
    final String titleText;
    if (hasFree) {
      titleText = t.observe.creditTitleFree;
    } else if (hasPaid) {
      titleText = t.observe.creditTitlePaid;
    } else {
      titleText = t.observe.creditTitleNone;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          titleText,
          style: const TextStyle(
            color: SolaraColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          t.observe.catLine(label: categoryLabel),
          style: const TextStyle(
            color: SolaraColors.solaraGoldLight,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0x14F6BD60),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x33F6BD60)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 無料クレジット ──
              // 残数文字列が長い場合に Spacer ではみ出るのを防ぐため、
              // 残数側を Expanded + TextAlign.end で右寄せ + 自動縮退。
              Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: SolaraColors.solaraGoldLight, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    t.observe.freeCredits,
                    style: const TextStyle(
                      color: SolaraColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (freeRemaining != null && freeLimit != null)
                          ? t.observe.freeRemaining(remaining: freeRemaining, limit: freeLimit)
                          : t.observe.freeChecking,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: SolaraColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 2),
                child: Text(
                  t.observe.weeklyRefill,
                  style: const TextStyle(
                    color: SolaraColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              const Divider(
                height: 16,
                thickness: 0.6,
                color: Color(0x22F6BD60),
              ),
              // ── 有料クレジット ──
              // 無料クレジット行と同じ overflow 対策。
              Row(
                children: [
                  const Icon(Icons.add_circle_outline,
                      color: SolaraColors.solaraGoldLight, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    t.observe.paidCredits,
                    style: const TextStyle(
                      color: SolaraColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.observe.paidRemaining(n: purchased),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: SolaraColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 2),
                child: Text(
                  t.observe.noExpiry,
                  style: const TextStyle(
                    color: SolaraColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onBuy();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: SolaraColors.solaraGoldLight,
              side: const BorderSide(color: SolaraColors.solaraGold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: Text(t.observe.buyCredits),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SolaraColors.textSecondary,
                    side: const BorderSide(color: Color(0x33FFFFFF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(t.observe.cancel),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  // クレジット 0 個なら「引く」を disabled (= onPressed: null)。
                  onPressed: hasAnyCredit
                      ? () {
                          onProceed();
                          Navigator.of(context).pop();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SolaraColors.solaraGold,
                    foregroundColor: SolaraColors.celestialBlueDark,
                    disabledBackgroundColor: const Color(0x33FFFFFF),
                    disabledForegroundColor: SolaraColors.textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                  child: Text(t.observe.draw),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
