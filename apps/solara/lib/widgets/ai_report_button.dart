import 'package:flutter/material.dart';
import '../utils/ai_report_api.dart';

/// AI 出力ユーザー報告ボタン (Google Generative AI Apps Policy 対応)。
///
/// 設計根拠: apps/solara/docs/store_compliance.md §3.1
///
/// Google Play は 2026-04-15 全面施行の Gen AI policy で「アプリ内で AI 出力を
/// 報告できる UI」を必須化。Solara は Stella 相談 / Tarot / Horo の 3 画面に
/// このボタンを設置する。
///
/// UI:
///   - 結果テキストの直下に小さく「✦ 不適切な内容を報告」リンク
///   - タップで BottomSheet (理由 7 択 + 自由記述 + 送信ボタン)
///   - 送信成功で snackbar「ご報告ありがとうございました」、失敗で再試行案内
///
/// 結果テキストが空のときは表示しない (= 報告対象がないので)。
class AiReportButton extends StatelessWidget {
  /// どの機能の出力か。'tarot' / 'consultation' / 'fortune' を想定。
  final String feature;

  /// 報告対象となる AI 出力本文。空文字なら何も表示しない。
  final String outputText;

  /// ボタンの上下マージン (画面ごとの密度に合わせて調整可)。
  final EdgeInsets padding;

  const AiReportButton({
    super.key,
    required this.feature,
    required this.outputText,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    if (outputText.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: Align(
        alignment: Alignment.center,
        child: TextButton.icon(
          icon: const Icon(
            Icons.flag_outlined,
            size: 14,
            color: Color(0xFF888270),
          ),
          label: const Text(
            '不適切な内容を報告',
            style: TextStyle(
              color: Color(0xFF888270),
              fontSize: 11,
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF888270),
            ),
          ),
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () => _openSheet(context),
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A24),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _AiReportSheet(
        feature: feature,
        outputText: outputText,
      ),
    );
  }
}

/// 報告 BottomSheet 内部実装。
class _AiReportSheet extends StatefulWidget {
  final String feature;
  final String outputText;
  const _AiReportSheet({required this.feature, required this.outputText});

  @override
  State<_AiReportSheet> createState() => _AiReportSheetState();
}

/// 報告理由の enum (UI 側固定)。Worker は文字列として保存するだけ。
class _ReportReason {
  final String value;
  final String label;
  final String hint;
  const _ReportReason(this.value, this.label, this.hint);
}

const List<_ReportReason> _kReasons = [
  _ReportReason('inappropriate', '不適切な内容', '差別的・暴力的・性的等の不快な表現'),
  _ReportReason('misinformation', '誤った専門助言',
      '「絶対に治る」「必ず儲かる」等、医療/金融/法律の断定表現'),
  _ReportReason('ethics', '倫理違反', '他人の心を断定 (読心)、占星術の解釈として不適切'),
  _ReportReason('quality', '品質問題', '文字化け、意味不明、空、繰り返し、未完成'),
  _ReportReason('hallucination', '事実誤認', '存在しない地名、間違った占星術用語、捏造'),
  _ReportReason('uncomfortable', '不快な表現', '過度に暗い、脅し、不安をあおる、悲観的すぎる'),
  _ReportReason('other', 'その他', '上記以外'),
];

class _AiReportSheetState extends State<_AiReportSheet> {
  String? _selected;
  final _freeTextCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _freeTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selected == null || _sending) return;
    setState(() => _sending = true);
    final ok = await AiReportApi.reportAiOutput(
      feature: widget.feature,
      reason: _selected!,
      outputText: widget.outputText,
      freeText: _freeTextCtrl.text.trim().isEmpty
          ? null
          : _freeTextCtrl.text.trim(),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'ご報告ありがとうございました。内容を確認いたします。'
              : '送信に失敗しました。電波の良いところで再度お試しください。',
          style: const TextStyle(fontSize: 13),
        ),
        backgroundColor: ok ? const Color(0xFF1F3322) : const Color(0xFF3A1A1A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // キーボード表示時に下から押し上げる
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ハンドル
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF555555),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'AI 出力の報告',
                style: TextStyle(
                  color: Color(0xFFE8E4D3),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'どのような問題があったか教えてください。内容を確認し、AI の品質改善に役立てます。',
                style: TextStyle(color: Color(0xFFB8B4A3), fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 16),
              // 理由選択
              ..._kReasons.map((r) => _ReasonTile(
                    reason: r,
                    selected: _selected == r.value,
                    onTap: () => setState(() => _selected = r.value),
                  )),
              const SizedBox(height: 12),
              // 自由記述 (任意)
              TextField(
                controller: _freeTextCtrl,
                maxLength: 500,
                maxLines: 3,
                style: const TextStyle(color: Color(0xFFE8E4D3), fontSize: 13),
                decoration: const InputDecoration(
                  hintText: '詳細 (任意・500 字以内)',
                  hintStyle: TextStyle(color: Color(0xFF666060)),
                  filled: true,
                  fillColor: Color(0xFF0A0A14),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF444444)),
                  ),
                  counterStyle: TextStyle(color: Color(0xFF666060), fontSize: 10),
                ),
              ),
              const SizedBox(height: 12),
              // 送信ボタン
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC9A84C),
                  foregroundColor: const Color(0xFF0A0A14),
                  disabledBackgroundColor: const Color(0xFF555555),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: (_selected == null || _sending) ? null : _submit,
                child: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('送信する',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル',
                    style: TextStyle(color: Color(0xFF888270), fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final _ReportReason reason;
  final bool selected;
  final VoidCallback onTap;
  const _ReasonTile({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2A2614) : const Color(0xFF0F0F18),
          border: Border.all(
            color: selected ? const Color(0xFFC9A84C) : const Color(0xFF333333),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: 18,
              color: selected ? const Color(0xFFC9A84C) : const Color(0xFF666666),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason.label,
                    style: const TextStyle(
                      color: Color(0xFFE8E4D3),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reason.hint,
                    style: const TextStyle(color: Color(0xFF888270), fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
