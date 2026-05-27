// Consultation Result — クレジット関連サブウィジェット (part of consultation_result_screen.dart)
//
// Stella 相談 クレジット制 (設計 project_solara_stella_free_credits.md) の結果画面向け
// 表示部品を分離: 402 ブロックボックス + 残量バナー。
// 本体 (consultation_result_widgets.dart) が 500 行 (HARD) を超えたため切り出した。

part of 'consultation_result_screen.dart';

/// Free 試食ゲートで 402 ブロックされた時のペイウォール誘導ボックス。
/// 理由 (creditExhausted / proOnlyMode / proOnlyRefresh) で文言を出し分ける。
class _ConsultationBlockedBox extends StatelessWidget {
  final ConsultationBlock reason;
  final VoidCallback onUpgrade;
  final VoidCallback onBuyCredits;
  const _ConsultationBlockedBox({
    required this.reason,
    required this.onUpgrade,
    required this.onBuyCredits,
  });

  @override
  Widget build(BuildContext context) {
    // 「購入導線を主ボタンに出す」ケース:
    //   - Free 相談残切れ (creditExhausted)
    //   - Pro 週次キャップ到達 (proWeeklyExhausted、2026-05-27 追加)
    // → どちらも追加クレジット購入 or 月曜リセット待ち (= 共通 UX)。
    final exhausted = reason == ConsultationBlock.creditExhausted ||
        reason == ConsultationBlock.proWeeklyExhausted;
    final isProExhausted = reason == ConsultationBlock.proWeeklyExhausted;
    // Pro 同期遅延 (425) は購入消費されていないので「使い切りました」UI と別物。
    // ボタン (購入/Pro 誘導) を出さず、本文で「数十秒後に再試行」を案内する。
    final isProSyncPending = reason == ConsultationBlock.proSyncPending;
    final (title, body) = switch (reason) {
      ConsultationBlock.proOnlyMode => (
          'このモードは Cosmic Pro で',
          'おでかけ以外の相談 (移住・旅行) は Cosmic Pro で読み解けます。',
        ),
      ConsultationBlock.proOnlyRefresh => (
          '候補の出し直しは Cosmic Pro で',
          '別の候補を何度でも見比べられます。',
        ),
      ConsultationBlock.proWeeklyExhausted => (
          '今週の Pro 相談上限に達しました',
          'Cosmic Pro は週 100 回まで Stella に相談できます。'
              '月曜日に補充されます。すぐ続けるなら、追加クレジットの購入が選べます。',
        ),
      ConsultationBlock.proSyncPending => (
          'Pro 状態を同期しています',
          'Cosmic Pro の課金状態をストアと再確認しています。クレジットは消費されていません。'
              '数十秒待ってからもう一度お試しください。',
        ),
      _ => (
          '相談クレジットを使い切りました',
          '無料の Stella 相談は週ごとに補充されます。すぐ続けるなら、'
              '追加クレジットの購入か、回数無制限の Cosmic Pro が選べます。',
        ),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome,
                color: SolaraColors.solaraGold,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: SolaraColors.textPrimary,
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: const TextStyle(
                  color: SolaraColors.textSecondary,
                  fontSize: 13,
                  height: 1.7,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // 残量切れ時 (Free / Pro 週次) のみ「クレジット購入」を主ボタンに、
              // Pro 副ボタンは Free exhausted のみ (Pro 週次 exhausted では非表示 =
              // 既に Pro なので Pro を勧める意味がない)。
              // proSyncPending (425) は同期中なのでボタン無し (本文だけで案内)。
              if (isProSyncPending) ...const [
                // 同期待ち。アクションボタンは出さない (リトライはユーザーが「もう一度相談」を押す)。
                SizedBox.shrink(),
              ] else if (exhausted) ...[
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onBuyCredits,
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0x1AF6BD60),
                      foregroundColor: SolaraColors.solaraGold,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0x44F6BD60)),
                      ),
                    ),
                    child: const Text('追加クレジットを購入'),
                  ),
                ),
                if (!isProExhausted) ...[
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: onUpgrade,
                    style: TextButton.styleFrom(
                      foregroundColor: SolaraColors.textSecondary,
                    ),
                    child: const Text('✦ Cosmic Pro で無制限にする'),
                  ),
                ],
              ] else
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onUpgrade,
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0x1AF6BD60),
                      foregroundColor: SolaraColors.solaraGold,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0x44F6BD60)),
                      ),
                    ),
                    child: const Text('✦ Cosmic Pro を見る'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// 2026-05-26: _FreeCreditsBanner 撤去（結果画面上部のクレジット残バナー）。
// クレジット残は Sanctuary 最上部 + 入力画面の開始ポップアップで提示する設計に統一。
