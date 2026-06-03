import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n/strings.g.dart';
import '../utils/legal_urls.dart';
import '../utils/solara_storage.dart';

/// AI 生成同意モーダル (Apple 5.1.2(i) / Google Generative AI Apps Policy)。
///
/// 設計根拠: apps/solara/docs/store_compliance.md §2.1 / §5.2
///
/// 構造 (6 章):
///   §0 はじめに                       — ユーザーへの開発者メッセージ
///   §1 本アプリは娯楽・自己探求を目的 — Apple 4.3(b) Spam + 1.4.1 Medical
///   §2 第三者へのデータ送信について   — Apple 5.1.2(i)
///   §3 Gemini AI が生成するコンテンツ — Google Gen AI Policy
///   §4 重要な意思決定について         — 占い系特有のリスク回避 + リンク
///   §5 同意の取扱いについて           — 同意 UX 運用説明
///
/// 初回起動時に一度だけ表示し、同意を SolaraStorage に永続化する。
/// 同意拒否時は確認モーダル「本アプリのご利用には同意が必要です」を出し、
/// [戻る] のみ提供。アプリは閉じず ConsentScreen に留まる (両 OS 共通)。
/// 背景画像: Gemini 3.1 Flash 生成、forging.webp に寄せた歓迎演出。
class AiConsentScreen extends StatelessWidget {
  /// 同意完了時に呼ばれる。main.dart 側で setState で SolaraHome に差し替わる。
  final VoidCallback onConsented;
  const AiConsentScreen({super.key, required this.onConsented});

  Future<void> _handleAgree(BuildContext context) async {
    await SolaraStorage.saveAiConsentNow();
    if (!context.mounted) return;
    onConsented();
  }

  Future<void> _handleDecline(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        title: Text(
          t.aiConsent.declineDialog.title,
          style: const TextStyle(color: Color(0xFFE8E4D3), fontSize: 18),
        ),
        content: Text(
          t.aiConsent.declineDialog.body,
          style: const TextStyle(
              color: Color(0xFFB8B4A3), fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              t.aiConsent.back,
              style: const TextStyle(color: Color(0xFFC9A84C)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLegalUrl(BuildContext context, String url) async {
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
          content: Text(t.aiConsent.linkOpenFailed(url: url)),
          backgroundColor: const Color(0xFF1A2438),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/onboarding-bg/ai_consent.webp',
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.4,
                  colors: [Color(0xFF1F0D38), Color(0xFF050208)],
                ),
              ),
            ),
          ),
          // 文字読みやすさ確保用の半透明オーバーレイ
          Container(color: Colors.black.withValues(alpha: 0.70)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    '✦ Solara ✦',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFC9A84C),
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.aiConsent.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFB8B4A3), fontSize: 13),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Section(
                            heading: t.aiConsent.intro.heading,
                            body: t.aiConsent.intro.body,
                          ),
                          SizedBox(height: 22),
                          _Section(
                            heading: t.aiConsent.entertainment.heading,
                            body: t.aiConsent.entertainment.body,
                          ),
                          SizedBox(height: 22),
                          _Section(
                            heading: t.aiConsent.thirdParty.heading,
                            body: t.aiConsent.thirdParty.body,
                          ),
                          SizedBox(height: 22),
                          _Section(
                            heading: t.aiConsent.geminiContent.heading,
                            body: t.aiConsent.geminiContent.body,
                          ),
                          SizedBox(height: 22),
                          _Section(
                            heading: t.aiConsent.decisions.heading,
                            body: t.aiConsent.decisions.body,
                            footer: _LegalLinks(
                              onPrivacyTap: () =>
                                _openLegalUrl(context, LegalUrls.privacyPolicy),
                              onTermsTap: () =>
                                _openLegalUrl(context, LegalUrls.termsOfService),
                            ),
                          ),
                          SizedBox(height: 22),
                          _Section(
                            heading: t.aiConsent.consentHandling.heading,
                            body: t.aiConsent.consentHandling.body,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC9A84C),
                      foregroundColor: const Color(0xFF0A0A14),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _handleAgree(context),
                    child: Text(
                      t.aiConsent.agree,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _handleDecline(context),
                    child: Text(
                      t.aiConsent.decline,
                      style: const TextStyle(color: Color(0xFF888270), fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String heading;
  final String body;
  final Widget? footer;
  const _Section({required this.heading, required this.body, this.footer});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: const TextStyle(
            color: Color(0xFFC9A84C),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: const TextStyle(
            color: Color(0xFFE8E4D3),
            fontSize: 13,
            height: 1.7,
          ),
        ),
        if (footer != null) ...[
          const SizedBox(height: 12),
          footer!,
        ],
      ],
    );
  }
}

class _LegalLinks extends StatelessWidget {
  final VoidCallback onPrivacyTap;
  final VoidCallback onTermsTap;
  const _LegalLinks({required this.onPrivacyTap, required this.onTermsTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _LinkPill(label: t.aiConsent.links.privacy, onTap: onPrivacyTap),
        _LinkPill(label: t.aiConsent.links.terms, onTap: onTermsTap),
      ],
    );
  }
}

class _LinkPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LinkPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x33C9A84C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFC9A84C).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE8E4D3),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.open_in_new,
              size: 12,
              color: Color(0xFFC9A84C),
            ),
          ],
        ),
      ),
    );
  }
}
