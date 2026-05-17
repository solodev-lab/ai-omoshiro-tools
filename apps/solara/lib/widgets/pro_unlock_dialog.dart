// Pro 案内ダイアログ — Phase 2-6a / Phase 2-6b + Phase 2 RASP 連携
//
// 設計: pro_candidates.md §7 + project_solara_security_principles.md
//
// 役割:
//   - Free ユーザーが Pro 限定機能をタップした時に表示する案内ダイアログ
//   - 「Pro でロック解除」の文体は Solara 世界観に揃える (吉凶禁止・寄り添い)
//   - Phase 2-6b 以降: 「Pro にアップグレード」ボタンが PaywallScreen を開く
//     (Offerings 未配信時は PaywallScreen 側で「ストア準備中」表示)
//   - Phase 2 RASP: 端末が改変検知された場合 (`DeviceSecurityStatus.isCompromised`)
//     はアップグレード CTA を出さず、セキュリティ通知に切り替える
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
import '../utils/device_security_status.dart';

/// Pro 限定機能の案内ダイアログを表示する。
///
/// [featureLabel] 機能名 (例: "Stella 相談", "結果のシェア")
/// [description] 機能の魅力を 1〜2 文で。Solara 世界観に揃える。
///
/// 端末が改変検知 (DeviceSecurityStatus.isCompromised) されている場合は
/// アップグレード CTA を出さず、セキュリティ案内に切り替える (Pro 購入しても
/// 改変端末では機能が使えない旨を伝え、課金後の不信感を未然に防ぐ)。
///
/// 戻り値: なし。
Future<void> showProUnlockDialog(
  BuildContext context, {
  required String featureLabel,
  required String description,
}) {
  final compromised = DeviceSecurityStatus.instance.isCompromised;
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
            border: Border.all(
              color: compromised
                  ? const Color(0x66E07A6E) // 軽い赤味 (security 注意)
                  : const Color(0x44F6BD60),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: compromised
                ? _buildCompromisedContent(ctx, featureLabel)
                : _buildProUpsellContent(context, ctx, featureLabel, description),
          ),
        ),
      ),
    ),
  );
}

/// 通常 Pro アップセル content (端末安全)。
List<Widget> _buildProUpsellContent(
  BuildContext outerContext,
  BuildContext ctx,
  String featureLabel,
  String description,
) {
  return [
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x33D6915C),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0x66D6915C)),
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
          Navigator.of(outerContext).push<void>(
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
  ];
}

/// 端末改変検知時の content。
/// アップグレード CTA を出さず、Free 機能は使える旨と原因の手がかりを提示。
List<Widget> _buildCompromisedContent(BuildContext ctx, String featureLabel) {
  return [
    const Row(
      children: [
        Icon(
          Icons.shield_outlined,
          color: SolaraColors.energyHardLight,
          size: 22,
        ),
        SizedBox(width: 10),
        Text(
          '✦ デバイスのセキュリティ確認',
          style: TextStyle(
            color: SolaraColors.energyHardLight,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ],
    ),
    const SizedBox(height: 16),
    Text(
      '$featureLabel は今この端末では利用できません',
      style: const TextStyle(
        color: SolaraColors.textPrimary,
        fontSize: 15,
        height: 1.5,
        fontWeight: FontWeight.w500,
      ),
    ),
    const SizedBox(height: 8),
    const Text(
      'デバイスに改変や解析ツール (root化、Frida、Jailbreak、エミュレータ等) '
      'の兆候を検知しました。\n\n'
      'Pro 機能を安全に提供できないためロックされています。\n'
      '無料機能はそのままご利用いただけます。',
      style: TextStyle(
        color: SolaraColors.textSecondary,
        fontSize: 13,
        height: 1.7,
      ),
    ),
    const SizedBox(height: 20),
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
  ];
}
