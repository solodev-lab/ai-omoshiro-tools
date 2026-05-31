import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
        title: const Text(
          '本アプリのご利用には同意が必要です',
          style: TextStyle(color: Color(0xFFE8E4D3), fontSize: 18),
        ),
        content: const Text(
          'Solara をご利用いただくためには、「ご利用前のおしらせ」にご記載の'
          '内容にご同意いただく必要がございます。同意なしではご利用いただけません。\n\n'
          'もう一度ご確認いただくか、Solara をアンインストールしてください。'
          '本アプリでは、ユーザーの個人情報を含む一切のデータを受け取って'
          'おりませんので、安心してアンインストールしていただけます。',
          style: TextStyle(color: Color(0xFFB8B4A3), fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              '戻る',
              style: TextStyle(color: Color(0xFFC9A84C)),
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
          content: Text('リンクを開けませんでした: $url'),
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
                  const Text(
                    'ご利用前のおしらせ',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFB8B4A3), fontSize: 13),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Section(
                            heading: '◆ はじめに',
                            body:
                              'このアプリは広大な宇宙のデータを1つにまとめたアプリです。'
                              'その瞬間1点において占星術を使い解釈する時、膨大なデータが実は存在します。'
                              'このアプリはその膨大なデータを判断材料としてあなたに提供する、とても便利なアプリです。\n\n'
                              'アプリが解釈して生成する文章やデータはエビデンスとして列挙してあり、'
                              'そのエビデンスから導き出される1つの解釈としてあなたに提示しています。\n\n'
                              'エビデンスを元に様々な解釈もできるので、'
                              '本アプリからの提示は、解釈の一つの例に過ぎません。'
                              '本アプリで、提示する文章において違和感を感じた場合は、'
                              'エビデンスをもとにご自身の解釈を加えてみてください。'
                              '是非、本アプリのデータを活用してあなた自身で占星術を試して頂けると幸いです。\n\n'
                              '本アプリは現役の占星術師である私が作りました。'
                              'あなたの人生が、あなたらしく輝いて生きられるように願っています。\n'
                              '私はあなたの幸せを祈っています。'
                              'あなたと本アプリを通して出会えた事に感謝します。ありがとう。\n\n'
                              'ー Solara 開発者より',
                          ),
                          SizedBox(height: 22),
                          const _Section(
                            heading: '◆ 本アプリは娯楽・自己探求を目的としています',
                            body:
                              'Solara の以下のすべての機能は、娯楽および自己探求のための手段です。\n\n'
                              '・出生図・トランジット・プログレスなどの占星術\n'
                              '・タロットカードの引きと解釈\n'
                              '・Stella との相談\n'
                              '・星読み\n'
                              '・地図上のアストロカートグラフィと方位スコア表示\n\n'
                              '医療・法律・金融・心理に関する専門的な助言ではありません。'
                              '将来の出来事を予測・保証するものでもありません。',
                          ),
                          SizedBox(height: 22),
                          const _Section(
                            heading: '◆ 第三者へのデータ送信について',
                            body:
                              '本アプリは、サービス提供のために以下の第三者サービスへ'
                              'データを送信します:\n\n'
                              '・Apple / Google ─ 不正利用防止 (デバイス認証) のため。'
                              '認証情報を送信します。\n'
                              '・Google Gemini AI ─ 占星術を元にした解釈文章生成及び'
                              'タロット解釈文章生成のため。あなたの出生情報 (生年月日・'
                              '出生時刻・出生地) と相談で入力したテキストを送信します。\n'
                              '・RevenueCat ─ 課金管理のため。匿名 ID と購入情報を送信します。',
                          ),
                          SizedBox(height: 22),
                          const _Section(
                            heading: '◆ Gemini AI が生成するコンテンツについて',
                            body:
                              '本アプリは、以下の機能で Google の Gemini AI を利用して'
                              '文章を生成しています:\n\n'
                              '・タロット ─ 引いたカードの解釈文章\n'
                              '・Stella 相談 ─ あなたの問いへの占星術相談の解釈文章\n'
                              '・星読み ─ 5 カテゴリ別 (恋愛 / 豊かさ / 仕事 / 対話 / 全体) の解釈文章\n'
                              '・リロケーション (地図) ─ 地図上で選択した地点の占星術解釈文章',
                          ),
                          SizedBox(height: 22),
                          _Section(
                            heading: '◆ 重要な意思決定について',
                            body:
                              'Solara の読み解きは、あなた自身を理解するための参考情報です。'
                              '不正確だったり、あなたに合わない内容になる場合もあります。\n\n'
                              '違和感を感じた結果は鵜呑みにせず、'
                              '移住・転職・結婚など人生の重要な判断は、ご自身の意思と、'
                              'ご家族・専門家への相談に基づいて行ってください。\n\n'
                              'データの詳しい取扱いは下記をご確認ください。',
                            footer: _LegalLinks(
                              onPrivacyTap: () =>
                                _openLegalUrl(context, LegalUrls.privacyPolicy),
                              onTermsTap: () =>
                                _openLegalUrl(context, LegalUrls.termsOfService),
                            ),
                          ),
                          SizedBox(height: 22),
                          const _Section(
                            heading: '◆ 同意の取扱いについて',
                            body:
                              '「同意して始める」を押すと、この「ご利用前のおしらせ」に'
                              '記載されている事項に同意した事実を端末内に記録します。'
                              '次回以降は表示されません。'
                              '（規約変更の際は再度のご案内をさせて頂く場合がございます）\n\n'
                              '同意しない場合は、画面下の「同意しない」をタップしていただき、'
                              'Solara をアンインストールしてください。この時点では、'
                              '本アプリではユーザーの個人情報含む一切のデータを'
                              '受け取っておりません。',
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
                    child: const Text(
                      '同意して始める',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _handleDecline(context),
                    child: const Text(
                      '同意しない',
                      style: TextStyle(color: Color(0xFF888270), fontSize: 14),
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
        _LinkPill(label: 'プライバシーポリシー', onTap: onPrivacyTap),
        _LinkPill(label: '利用規約', onTap: onTermsTap),
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
