// Consultation 開始確認ポップアップ (Free ユーザー向け)
// (part of 'consultation_input_screen.dart')
//
// 「相談を始める」を押したとき、Free ユーザーに無料クレジットの残数・補充タイミング・
// 追加購入導線を案内するポップアップ。Pro はスキップ、「次回以降表示しない」で抑制可能。
// showInfoPopup 経由で表示する (widgets/info_popup.dart、popup 統一規約に準拠)。

part of 'consultation_input_screen.dart';

class _StartConsultPopup extends StatefulWidget {
  /// 直近に取得したクレジット状況 (null = 取得失敗 / 未取得)。
  final ConsultationCreditStatus? status;

  /// 「次回以降表示しない」の初期チェック状態。
  final bool initialHide;

  /// 「相談を始める」で続行 (呼出側で proceed フラグを立てる)。
  final VoidCallback onContinue;

  /// 「クレジットを購入」で購入シートを開く (呼出側 State が処理)。
  final VoidCallback onBuy;

  /// チェック状態が変わるたびに通知 (端末保存は呼出側 State)。
  final ValueChanged<bool> onHideChanged;

  const _StartConsultPopup({
    required this.status,
    required this.initialHide,
    required this.onContinue,
    required this.onBuy,
    required this.onHideChanged,
  });

  @override
  State<_StartConsultPopup> createState() => _StartConsultPopupState();
}

class _StartConsultPopupState extends State<_StartConsultPopup> {
  late bool _hide = widget.initialHide;

  @override
  Widget build(BuildContext context) {
    final st = widget.status;
    final remaining = st?.freeRemaining;
    final limit = st?.freeLimit;
    final purchased = st?.purchasedBalance ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '無料相談を使います',
          style: TextStyle(
            color: SolaraColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        // 残数バッジ: 「残り N/3 回」(残数ベース) + 毎週月曜日に補充
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0x14F6BD60),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x33F6BD60)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: SolaraColors.solaraGoldLight, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (remaining != null && limit != null)
                          ? '今週の無料相談  残り $remaining/$limit 回'
                          : '今週の無料相談  残り回数を確認中',
                      style: const TextStyle(
                        color: SolaraColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      purchased > 0
                          ? '毎週月曜日に補充 ・ 購入クレジット $purchased'
                          : '毎週月曜日に補充',
                      style: const TextStyle(
                        color: SolaraColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          '無料の Stella 相談は週 3 回まで（毎週月曜日に補充）。'
          '使い切っても追加クレジット購入か Cosmic Pro で続けられます。',
          style: TextStyle(
            color: SolaraColors.textSecondary,
            fontSize: 12,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 4),
        // 次回以降表示しない
        InkWell(
          onTap: () {
            setState(() => _hide = !_hide);
            widget.onHideChanged(_hide);
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  _hide ? Icons.check_box : Icons.check_box_outline_blank,
                  color: _hide
                      ? SolaraColors.solaraGoldLight
                      : SolaraColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  '次回以降表示しない',
                  style: TextStyle(
                    color: SolaraColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // クレジット購入ボタン
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onBuy();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: SolaraColors.solaraGoldLight,
              side: const BorderSide(color: SolaraColors.solaraGold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('クレジットを購入'),
          ),
        ),
        const SizedBox(height: 8),
        // 相談を始める (続行)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              widget.onContinue();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SolaraColors.solaraGold,
              foregroundColor: SolaraColors.celestialBlueDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
            child: const Text('相談を始める'),
          ),
        ),
      ],
    );
  }
}
