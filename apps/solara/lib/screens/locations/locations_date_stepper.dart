import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;

/// Locations 画面の日付ステッパー（年▲▼ 月▲▼ 日▲▼ + 「今日」リセット）。
/// 数値部分は直接タップして手入力も可能（[_DateNumberField]）。
/// 親の `_selectedDate` は変更せず Locations 内ローカル状態として動く。
class LocationsDateStepper extends StatelessWidget {
  /// 現在表示中の日付（UTC・正午）
  final DateTime displayDate;

  /// 許容範囲（min/max）
  final DateTime dateMin;
  final DateTime dateMax;

  /// 「今日」ボタン押下時のコールバック（null なら表示しない＝今日の状態）
  final VoidCallback? onResetToToday;

  /// データ再取得中インジケータ（true ならスピナー表示）
  final bool refetching;

  /// ▲▼ オフセット移動コールバック
  final void Function({int years, int months, int days}) onShift;

  /// 年/月/日を直接指定するコールバック（手入力用、内部で範囲＋日数クランプ）
  final void Function(int year, int month, int day) onSetYmd;

  const LocationsDateStepper({
    super.key,
    required this.displayDate,
    required this.dateMin,
    required this.dateMax,
    required this.onResetToToday,
    required this.refetching,
    required this.onShift,
    required this.onSetYmd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(children: [
        const Text('日付',
            style: TextStyle(fontSize: 10, color: Color(0xFF888888), letterSpacing: 1.5)),
        const SizedBox(width: 12),
        Expanded(child: Row(children: [
          _stepperBlock('年', displayDate.year,
              min: dateMin.year, max: dateMax.year,
              onDelta: (d) => onShift(years: d),
              onSet: (v) => onSetYmd(v, displayDate.month, displayDate.day)),
          const SizedBox(width: 6),
          _stepperBlock('月', displayDate.month,
              min: 1, max: 12,
              onDelta: (d) => onShift(months: d),
              onSet: (v) => onSetYmd(displayDate.year, v, displayDate.day)),
          const SizedBox(width: 6),
          _stepperBlock('日', displayDate.day,
              min: 1, max: DateUtils.getDaysInMonth(displayDate.year, displayDate.month),
              onDelta: (d) => onShift(days: d),
              onSet: (v) => onSetYmd(displayDate.year, displayDate.month, v)),
        ])),
        if (refetching) const Padding(
          padding: EdgeInsets.only(left: 8),
          child: SizedBox(width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFC9A84C)),
          ),
        ) else if (onResetToToday != null) IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          icon: const Icon(Icons.refresh, color: Color(0xFFC9A84C), size: 16),
          tooltip: '今日に戻す',
          onPressed: onResetToToday,
        ),
      ]),
    );
  }

  Widget _stepperBlock(String unit, int value, {
    required int min,
    required int max,
    required ValueChanged<int> onDelta,
    required ValueChanged<int> onSet,
  }) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x33C9A84C)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _DateNumberField(value: value, min: min, max: max, onCommit: onSet),
            Text(unit,
                style: const TextStyle(fontSize: 8, color: Color(0xFF666666))),
          ],
        )),
        Column(mainAxisSize: MainAxisSize.min, children: [
          _stepBtn('▲', () => onDelta(1)),
          _stepBtn('▼', () => onDelta(-1)),
        ]),
      ]),
    ));
  }

  Widget _stepBtn(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 18, height: 14,
        alignment: Alignment.center,
        child: Text(label,
            style: const TextStyle(fontSize: 9, color: Color(0xFFC9A84C))),
      ),
    );
  }
}

/// 数値を直接タイプして編集できるフィールド（年/月/日 共通）。
/// - 親（ステッパー）は [value] を渡す。フォーカス無し時は外部更新に追従。
/// - 編集確定（Enter or フォーカス離脱）で [onCommit] を呼ぶ。
/// - 範囲外の値は [min] / [max] でクランプ。空文字や非数値は元の値に戻す。
class _DateNumberField extends StatefulWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onCommit;

  const _DateNumberField({
    required this.value,
    required this.min,
    required this.max,
    required this.onCommit,
  });

  @override
  State<_DateNumberField> createState() => _DateNumberFieldState();
}

class _DateNumberFieldState extends State<_DateNumberField> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.value}');
    _focus = FocusNode();
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _DateNumberField old) {
    super.didUpdateWidget(old);
    // 外部更新（▲▼ボタン等）に追従。編集中はユーザー入力を優先。
    if (!_focus.hasFocus && widget.value.toString() != _ctrl.text) {
      _ctrl.text = '${widget.value}';
    }
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) _commit();
  }

  void _commit() {
    final n = int.tryParse(_ctrl.text);
    if (n == null) {
      _ctrl.text = '${widget.value}';
      return;
    }
    final clamped = n.clamp(widget.min, widget.max);
    if (clamped.toString() != _ctrl.text) _ctrl.text = '$clamped';
    if (clamped != widget.value) widget.onCommit(clamped);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 18,
      child: TextField(
        controller: _ctrl,
        focusNode: _focus,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        cursorColor: const Color(0xFFC9A84C),
        cursorWidth: 1,
        style: const TextStyle(
          fontSize: 12, color: Color(0xFFE8E0D0), fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
        ),
        onTap: () => _ctrl.selection = TextSelection(
          baseOffset: 0, extentOffset: _ctrl.text.length),
        onSubmitted: (_) {
          _commit();
          _focus.unfocus();
        },
      ),
    );
  }
}
