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
    final freeRemaining = st?.freeRemaining;
    final freeLimit = st?.freeLimit;
    final purchased = st?.purchasedBalance ?? 0;
    final hasFree = (freeRemaining ?? 0) > 0;
    final hasPaid = purchased > 0;
    // タイトル: 実際に「次に消費される」種別を表示。
    // 設計（project_solara_stella_free_credits）= 消費順は 無料週次 → 購入残高。
    final String titleText;
    if (hasFree) {
      titleText = '無料クレジットを使う';
    } else if (hasPaid) {
      titleText = '有料クレジットを使う';
    } else {
      titleText = 'クレジットを使う';
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
        const SizedBox(height: 14),
        // 残数バッジ: 無料 / 有料 の両方を常に表示。
        // 値が古くならないよう、呼出側（consultation_input_logic._showStartPopup）が
        // 直前に fetchConsultationCredits を await して status を最新化してから表示する。
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
              Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: SolaraColors.solaraGoldLight, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    '無料クレジット',
                    style: TextStyle(
                      color: SolaraColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    (freeRemaining != null && freeLimit != null)
                        ? '残り $freeRemaining / $freeLimit 回'
                        : '残り回数を確認中',
                    style: const TextStyle(
                      color: SolaraColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 24, top: 2),
                child: Text(
                  '毎週月曜日に補充',
                  style: TextStyle(
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
              Row(
                children: [
                  const Icon(Icons.add_circle_outline,
                      color: SolaraColors.solaraGoldLight, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    '有料クレジット',
                    style: TextStyle(
                      color: SolaraColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '残り $purchased 回',
                    style: const TextStyle(
                      color: SolaraColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 24, top: 2),
                child: Text(
                  '失効なし（購入分は端末を変えても残る）',
                  style: TextStyle(
                    color: SolaraColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
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
