// Solara Sanctuary 法務リンクメニュー (Phase 2 launch_checklist)
//
// 役割:
//   Sanctuary > ✦ App セクションの「Terms & Privacy」エントリから開く法務情報 popup。
//   ペイウォール外からも EULA / プライバシー / 特商法 / 解約方法へアクセス可能にする。
//
// 設計:
//   - popup は project_solara_popup_pattern.md の統一仕様に従い `showInfoPopup` 経由
//   - URL は LegalUrls (utils/legal_urls.dart) 単一情報源を参照、ハードコード禁止
//   - 解約方法のみ iOS/Android で deep link 切替 (PaywallScreen と同じロジック)
//
// 設計思想:
//   launch_checklist Phase 2 残: プライバシー/EULA/特商法 Sanctuary 単独リンク [WIP] → [x]
//   公開ブロッカー B5 (Apple Review 3.1.2) は Paywall 内 4 リンクで充足済。本ファイルは
//   ストア公開後の継続アクセス手段 (ユーザーが Paywall 通らなくなっても法務情報を見られる) の確保。

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../i18n/strings.g.dart';
import '../../utils/legal_urls.dart';
import '../../widgets/info_popup.dart';

/// Sanctuary > ✦ App の「Terms & Privacy」エントリから開く法務情報 popup。
///
/// 4 リンク (利用規約 / プライバシー / 特商法 / 解約方法) を縦並びで表示。
/// タップで `url_launcher.launchUrl(mode: externalApplication)` で外部ブラウザを開く。
/// 解約方法のみ iOS = `apps.apple.com/account/subscriptions`、Android = Play Store、
/// その他は静的 `howToCancel` 案内ページ。
Future<void> showSanctuaryLegalMenu(BuildContext context) {
  return showInfoPopup(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            t.legalMenu.heading,
            style: const TextStyle(
              color: Color(0xFFF9D976),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _LegalRow(
          label: t.legalMenu.eula,
          onTap: () => _openUrl(context, LegalUrls.termsOfService),
        ),
        _LegalRow(
          label: t.paywall.legal.privacy,
          onTap: () => _openUrl(context, LegalUrls.privacyPolicy),
        ),
        _LegalRow(
          label: t.paywall.legal.sctaNotice,
          onTap: () => _openUrl(context, LegalUrls.specifiedCommercialTransactions),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(color: Color(0x33F9D976), height: 1, thickness: 1),
        ),
        _LegalRow(
          label: t.paywall.legal.cancelMethod,
          onTap: () => _openCancelGuide(context),
        ),
      ],
    ),
  );
}

Future<void> _openUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  bool ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.legalMenu.openFailed(url: url)),
        backgroundColor: const Color(0xFF1A2438),
      ),
    );
  }
}

/// iOS = 設定アプリの Subscriptions deep link、Android = Play Store の課金管理、
/// その他 (Web/desktop debug 等) = 静的 howToCancel ページ。
/// PaywallScreen._openCancelGuide と同じ振り分け。
Future<void> _openCancelGuide(BuildContext context) async {
  await openSubscriptionSettings(context);
}

/// 端末のサブスクリプション設定 deep link を直接開く (Cosmic Pro 加入中の解約導線)。
/// iOS = 設定アプリ → Apple ID → サブスクリプション
/// Android = Play Store → 定期購入
/// その他 = Web 解約案内ページ
/// Sanctuary > Cosmic Pro 加入中バナーから直接呼ばれる public API。
Future<void> openSubscriptionSettings(BuildContext context) async {
  String url;
  if (!kIsWeb && Platform.isIOS) {
    url = LegalUrls.iosSubscriptionsDeepLink;
  } else if (!kIsWeb && Platform.isAndroid) {
    url = LegalUrls.androidSubscriptionsDeepLink;
  } else {
    url = LegalUrls.howToCancel;
  }
  await _openUrl(context, url);
}

class _LegalRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LegalRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFE8E0D0),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
            const Icon(
              Icons.open_in_new,
              size: 16,
              color: Color(0x99F9D976),
            ),
          ],
        ),
      ),
    );
  }
}
