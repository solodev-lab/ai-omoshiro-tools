// 共通メモ入力欄 — 200 字 cap + 自前カウンタ「N/200」+ saved 通知
//
// 利用箇所:
//   - タロット HISTORY の SYNCHRONICITY メモ (observe_history.dart)
//   - 称号変遷の各エントリのメモ (title_history_screen.dart)
//
// Stella 相談の自由記述 (_FreeTextField) は Flutter の counterText を
// そのまま使っているが、本 widget はラベル右肩にリアルタイム表示する
// 用途のため、TextField.counterText='' で抑止して自前で出す。
//
// 親側で onChanged を受け、永続化 (SharedPreferences 等) する責務を持つ。
// 本 widget 自体は「saved」通知アニメだけ担当 (1500ms 表示)。

import 'package:flutter/material.dart';
import '../theme/solara_colors.dart';

class MemoTextField extends StatefulWidget {
  /// 初期テキスト (永続化済みの値)
  final String initialText;

  /// 入力変更時のコールバック。親側で SharedPreferences 等に書き込む。
  final ValueChanged<String> onChanged;

  /// ラベル (例: 'NOTE', 'SYNCHRONICITY')。空なら出さない。
  final String label;

  /// ラベル横に並ぶアイコン文字 (絵文字推奨、例: '🔗')。空なら出さない。
  final String labelIcon;

  /// 入力欄プレースホルダー
  final String hintText;

  /// 文字数上限
  final int maxLength;

  /// 表示最小行数
  final int minLines;

  /// 表示最大行数 (null = 無制限。Flutter は超過分を内部スクロール)
  final int? maxLines;

  const MemoTextField({
    super.key,
    required this.initialText,
    required this.onChanged,
    this.label = '',
    this.labelIcon = '',
    this.hintText = '',
    this.maxLength = 200,
    this.minLines = 2,
    this.maxLines,
  });

  @override
  State<MemoTextField> createState() => _MemoTextFieldState();
}

class _MemoTextFieldState extends State<MemoTextField> {
  late final TextEditingController _ctrl;
  bool _showSaved = false;
  int _length = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialText);
    _length = widget.initialText.characters.length;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    widget.onChanged(text);
    setState(() {
      _length = text.characters.length;
      _showSaved = true;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showSaved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasLabel = widget.label.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                if (widget.labelIcon.isNotEmpty) ...[
                  Text(widget.labelIcon,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF666666))),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF666666),
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '$_length/${widget.maxLength}',
                  style: TextStyle(
                    fontSize: 10,
                    color: _length >= widget.maxLength
                        ? SolaraColors.solaraGoldLight
                        : const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        TextField(
          controller: _ctrl,
          onChanged: _onChanged,
          maxLength: widget.maxLength,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          style: const TextStyle(
              fontSize: 12, color: Color(0xFFE8E0D0), height: 1.5),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(color: Color(0xFF444444)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            filled: true,
            fillColor: const Color(0x990F0F1E),
            // counterText='' でデフォルトの「N / M」表示を抑止。
            // ラベル右肩で自前表示しているため二重を避ける。ラベル無しの場合は
            // ここでだけ表示するため空でなくする。
            counterText: hasLabel ? '' : null,
            counterStyle: TextStyle(
              color: SolaraColors.textSecondary.withValues(alpha: 0.6),
              fontSize: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0x1FC9A84C)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0x1FC9A84C)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0x4DC9A84C)),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: AnimatedOpacity(
            opacity: _showSaved ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('saved',
                  style: TextStyle(fontSize: 9, color: Color(0xFFC9A84C))),
            ),
          ),
        ),
      ],
    );
  }
}
