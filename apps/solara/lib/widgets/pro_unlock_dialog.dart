// Pro 案内ダイアログ — Phase 2-6a / Phase 2-6b
//
// 設計: pro_candidates.md §7 + project_solara_security_principles.md
//
// 役割:
//   - Free ユーザーが Pro 限定機能をタップした時に表示する案内ダイアログ
//   - 「Pro でロック解除」の文体は Solara 世界観に揃える (吉凶禁止・寄り添い)
//   - Phase 2-6b 以降: 「Pro にアップグレード」ボタンが PaywallScreen を開く
//     (Offerings 未配信時は PaywallScreen 側で「ストア準備中」表示)
//
// 利用箇所:
//   - Map「この場所で相談する」CTA タップ (Free)
//   - Daily Transit「Stella に相談」CTA タップ (Free)
//   - 結果画面のシェアアイコン タップ (Free)
//   - その他 Pro ゲート対象機能のタップ (Phase 2-7 / 2-8 で配線)

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../screens/paywall_screen.dart';
import '../theme/solara_colors.dart';

/// Pro 限定機能の案内ダイアログを表示する。
///
/// [featureLabel] 機能名 (例: "Stella 相談", "結果のシェア")
/// [description] 機能の魅力を 1〜2 文で。Solara 世界観に揃える。
///
/// 戻り値: なし。ユーザーは「閉じる」または DEV では「Sanctuary で切替」を案内される。
Future<void> showProUnlockDialog(
  BuildContext context, {
  required String featureLabel,
  required String description,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x99000000),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          decoration: BoxDecoration(
            color: const Color(0xEE0C0C1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x44F6BD60)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: SolaraColors.solaraGold,
                    size: 22,
                  ),
                  SizedBox(width: 10),
                  Text(
                    '✦ Cosmic Pro',
                    style: TextStyle(
                      color: SolaraColors.solaraGoldLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '$featureLabel は Pro 機能です',
                style: const TextStyle(
                  color: SolaraColors.textPrimary,
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  color: SolaraColors.textSecondary,
                  fontSize: 13,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 20),
              if (kDebugMode) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x33D6915C),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0x66D6915C),
                    ),
                  ),
                  child: const Text(
                    '[DEV] Sanctuary → ✦ Cosmic Pro で Pro 状態を切替できます',
                    style: TextStyle(
                      color: SolaraColors.energyHardLight,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Phase 2-6b: アップグレードボタン → PaywallScreen を push。
              // 縦並びで overflow 回避 (380px 幅でも入りきる)。
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => const PaywallScreen(),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: SolaraColors.solaraGold,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Pro にアップグレード'),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: SolaraColors.textSecondary,
                  ),
                  child: const Text('閉じる'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
