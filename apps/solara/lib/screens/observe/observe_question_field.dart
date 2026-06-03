part of '../observe_screen.dart';

// ══════════════════════════════════════════════════
// A3 (2026-05-17): Pro 専用「相談者のテーマ」質問入力欄 + Free 誘導 CTA。
//
// 設計: pro_candidates.md §7.1 (柱1 = 事業の核、Pro=質問入力欄 + thinking ON)。
// 🔴 プロンプト注入対策: テーマ内の指示には Worker 側で従わない設計 (tarot.js buildPrompt)。
// 🔴 コンテンツ安全性: 医療/法律/自傷に断定アドバイスせず専門家相談を勧める。
//
// このファイルは `observe_screen.dart` の State<_ObserveScreenState> に
// part of で連結され、`_questionController` / `_alreadyDrawnToday` 等の
// private state にアクセスする。
// ══════════════════════════════════════════════════

extension _QuestionFieldWidgets on ObserveScreenState {
  /// Pro 専用: 「相談者のテーマ」入力欄。
  /// 200 字 cap (内部・Worker 側でも cap)。引き済みなら disabled。
  /// 入力内容は fetchTarotReading の `question` パラメータで Worker に送られ、
  /// プロンプトに「テーマ」として埋め込まれる (注入指示には従わない設計)。
  ///
  /// 表示:
  ///   - ヘッダー右肩に「任意・N/200」リアルタイム文字数
  ///   - 入力欄は 5 行までは見せ、超過分は内部スクロール (引いた後に
  ///     テーマ全文が確認できるよう、十分な視認領域を確保)
  ///   - 入力欄の fillColor を深く落として自分の文字が背景に同化しないように
  Widget buildQuestionField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x44C9A84C)),
        color: const Color(0x14C9A84C),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFE9D29A)),
            const SizedBox(width: 6),
            const Text(
              '今日のテーマ',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFE9D29A),
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0x66F6BD60)),
              ),
              child: const Text('Pro',
                  style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFFF6BD60),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4)),
            ),
            const Spacer(),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _questionController,
              builder: (_, value, _) {
                final n = value.text.characters.length;
                return Text(
                  '任意・$n/200',
                  style: TextStyle(
                    fontSize: 10,
                    color: n >= 200
                        ? const Color(0xFFF6BD60)
                        : const Color(0xFF888888),
                  ),
                );
              },
            ),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: _questionController,
            enabled: !_alreadyDrawnToday,
            maxLength: 200,
            maxLines: 5,
            minLines: 1,
            style: const TextStyle(fontSize: 13, color: Color(0xFFE8E0D0)),
            decoration: InputDecoration(
              hintText: _alreadyDrawnToday
                  ? '本日は引き済みです (明日また)'
                  : '例: 新しいプロジェクトを始めるべきか迷っている',
              hintStyle: const TextStyle(
                  fontSize: 12, color: Color(0xFF666666), height: 1.4),
              counterText: '',
              filled: true,
              fillColor: const Color(0xCC050510),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0x33C9A84C)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0x33C9A84C)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0x66F6BD60)),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0x22444444)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Free 向け誘導: 質問欄を見せず、「Pro でテーマを添えられる」と説明する CTA。
  Widget buildQuestionFieldTeaser() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showProUnlockDialog(
        context,
        featureLabel: '質問つきタロット',
        description: '「今日のテーマ」を 200 字以内で添えると、Stella がそのテーマに'
            '寄り添ってカードを読み解きます。Cosmic Pro では、より '
            '深い読み解きも一緒に解放されます。',
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0x33C9A84C), Color(0x14C9A84C)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x55C9A84C)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFE9D29A)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '今日のテーマを添えて引く',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFFE9D29A),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Cosmic Pro でテーマ欄が開き、Stella がそれに寄り添って読みます。',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xCCE8E0D0),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x66F6BD60)),
                color: const Color(0x22F6BD60),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 10, color: Color(0xFFF6BD60)),
                  SizedBox(width: 3),
                  Text('Pro',
                      style: TextStyle(
                          fontSize: 9,
                          color: Color(0xFFF6BD60),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
