import 'package:flutter/material.dart';
import '../utils/solara_storage.dart';

/// AI 生成同意モーダル (Apple 5.1.2(i) / Google Generative AI Apps Policy)。
///
/// 設計根拠: apps/solara/docs/store_compliance.md §2.1 / §5.2
///
/// - Apple 2025-11-13 改定で「第三者 AI へのデータ送信は明示同意必須」と
///   明文化された (5.1.2(i))。Reviewer は onboarding 同意 / プライバシー
///   ポリシー / App Privacy 質問票の 3 点を line-by-line で比較する。
/// - 初回起動時に一度だけ表示し、同意を SolaraStorage に永続化する
///   (saveAiConsentNow → ISO8601 文字列で保存)。再起動で再表示しない。
/// - 同意を拒否した場合は、確認モーダルで「同意しないと利用できない」と
///   伝え、戻るボタンのみ提供 (アプリは閉じない、ConsentScreen に留まる)。
///   オーナーが同意するまでホーム画面で閉じてもらう導線。
class AiConsentScreen extends StatelessWidget {
  /// 同意完了時に呼ばれる。main.dart 側で SolaraHome へ pushReplacement する。
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
          '同意が必要です',
          style: TextStyle(color: Color(0xFFE8E4D3), fontSize: 18),
        ),
        content: const Text(
          'Solara の占星術解釈・タロット・AI 相談機能をご利用いただくには、'
          'Google Gemini AI への送信に同意していただく必要があります。\n\n'
          'もう一度ご検討いただくか、ホームボタン (またはホームへスワイプ) で'
          'アプリを閉じてください。',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text(
                '✦ Solara',
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
                    children: const [
                      _ParagraphSection(
                        heading: '◆ アプリの目的',
                        body:
                          'Solara が提供する占星術・タロット・AI 相談はすべて、'
                          '娯楽および自己探求のためのものです。'
                          '医療・法律・金融・心理に関する専門的な助言ではありません。'
                          '将来の出来事を予測・保証するものでもありません。',
                      ),
                      SizedBox(height: 18),
                      _ParagraphSection(
                        heading: '◆ AI による生成について',
                        body:
                          'タロット解釈・Stella 相談・今日の占いの文章は、'
                          'Google の Gemini AI が生成しています。'
                          'あなたの出生情報 (生年月日・出生時刻・出生地) と'
                          '相談で入力したテキストは、解釈生成のために'
                          'Google のサーバーへ送信されます。',
                      ),
                      SizedBox(height: 18),
                      _ParagraphSection(
                        heading: '◆ 重要な意思決定について',
                        body:
                          'Solara の読み解きは、あなた自身の内省を助けるための「鏡」です。'
                          '移住・転職・結婚など人生の重要な判断は、'
                          'ご自身の意思と、ご家族・専門家への相談に基づいて行ってください。',
                      ),
                      SizedBox(height: 18),
                      _ParagraphSection(
                        heading: '◆ 同意の記録について',
                        body:
                          '「同意して始める」を押すと、この同意の事実を端末内に記録します。'
                          '次回以降は表示されません。'
                          'プライバシーポリシーと利用規約は Sanctuary 画面からいつでも確認できます。',
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
    );
  }
}

class _ParagraphSection extends StatelessWidget {
  final String heading;
  final String body;
  const _ParagraphSection({required this.heading, required this.body});

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
      ],
    );
  }
}
