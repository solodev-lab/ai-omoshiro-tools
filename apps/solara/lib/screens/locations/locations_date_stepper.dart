import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;

/// Locations 画面の日付ステッパー（年▲▼ 月▲▼ 日▲▼ + 「今日」リセット）。
/// 2026-05-08: 日付の下に時刻 (HH:00) 行を追加 (常時表示)。
///   表示形式は Map 画面と同じ HH:00、UI は date stepper と同じ ▲▼ ボタン。
/// 数値部分は直接タップして手入力も可能（[_DateNumberField]）。
/// 親の `_selectedDate` は変更せず Locations 内ローカル状態として動く。
class LocationsDateStepper extends StatelessWidget {
  /// 現在表示中の日付（UTC・現在時刻含む）
  final DateTime displayDate;

  /// 現在表示中のローカル時刻 (0..23) — 時刻行に表示される値
  final int displayHour;

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

  /// 時刻オフセット移動コールバック (▲▼ で 1 時間移動、0 ⇄ 23 でラップ)
  final void Function(int delta) onShiftHour;

  /// 時刻を直接指定するコールバック (手入力用、0..23 でクランプ)
  final void Function(int hour) onSetHour;

  const LocationsDateStepper({
    super.key,
    required this.displayDate,
    required this.displayHour,
    required this.dateMin,
    required this.dateMax,
    required this.onResetToToday,
    required this.refetching,
    required this.onShift,
    required this.onSetYmd,
    required this.onShiftHour,
    required this.onSetHour,
  });

  @override
  Widget build(BuildContext context) {
    // ローカルローカル化された displayDate (年月日表示用)
    final localDate = displayDate.toLocal();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 行1: 日付ステッパー ──
          Row(children: [
            const Text('日付',
                style: TextStyle(fontSize: 10, color: Color(0xFF888888), letterSpacing: 1.5)),
            const SizedBox(width: 12),
            Expanded(child: Row(children: [
              _stepperBlock('年', localDate.year,
                  min: dateMin.year, max: dateMax.year,
                  onDelta: (d) => onShift(years: d),
                  onSet: (v) => onSetYmd(v, localDate.month, localDate.day)),
              const SizedBox(width: 6),
              _stepperBlock('月', localDate.month,
                  min: 1, max: 12,
                  onDelta: (d) => onShift(months: d),
                  onSet: (v) => onSetYmd(localDate.year, v, localDate.day)),
              const SizedBox(width: 6),
              _stepperBlock('日', localDate.day,
                  min: 1, max: DateUtils.getDaysInMonth(localDate.year, localDate.month),
                  onDelta: (d) => onShift(days: d),
                  onSet: (v) => onSetYmd(localDate.year, localDate.month, v)),
            ])),
            // 右端は常に 28x28 の固定枠。refetching=スピナー / 通常=「今日に戻す」ボタン（今日状態では薄色 disabled）。
            // 固定幅にすることで、年月日ボタン押下や再読込でレイアウトがブレない。
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: SizedBox(
                width: 28, height: 28,
                child: refetching
                  ? const Padding(
                      padding: EdgeInsets.all(7),
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFC9A84C)),
                    )
                  : IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      icon: Icon(
                        Icons.today,
                        color: onResetToToday != null
                          ? const Color(0xFFC9A84C)
                          : const Color(0x33C9A84C),
                        size: 16,
                      ),
                      tooltip: '今日に戻す',
                      onPressed: onResetToToday,
                    ),
              ),
            ),
          ]),
          // ── 行2: 時刻ステッパー (常時表示、Map 画面と同じ HH:00 形式) ──
          // 2026-05-08: ユーザー要望で日付の下に時刻表示を常時化。
          // UI は date stepper と同じ ▲▼ ボタン、表示は HH:00 (Map 形式)。
          // 右端の今日ボタン領域 (28+8=36px) と幅を揃えて視覚的に整列。
          const SizedBox(height: 4),
          Row(children: [
            const Text('時刻',
                style: TextStyle(fontSize: 10, color: Color(0xFF888888), letterSpacing: 1.5)),
            const SizedBox(width: 12),
            Expanded(child: _hourStepperBlock(localDate)),
            const SizedBox(width: 36),
          ]),
        ],
      ),
    );
  }

  /// 時刻ステッパーブロック (HH:00 表示 + ▲▼ ボタン)。
  /// ▲▼ は 1 時間移動 (0 ⇄ 23 でラップ)。
  /// HH 部分は直接タップして手入力可能 ([_HourNumberField])。
  Widget _hourStepperBlock(DateTime localDate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x33C9A84C)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Expanded(child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _HourNumberField(value: displayHour, onCommit: onSetHour),
              const Text(':00',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE8E0D0),
                      fontWeight: FontWeight.w600)),
            ],
          ),
        )),
        Column(mainAxisSize: MainAxisSize.min, children: [
          _stepBtn('▲', () => onShiftHour(1)),
          _stepBtn('▼', () => onShiftHour(-1)),
        ]),
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

/// 時 (hour) を直接タイプして編集できるフィールド。
/// _DateNumberField と同じ仕組み (フォーカス離脱で commit、範囲外クランプ)
/// だが、表示幅を 24px に絞り「HH:00」表示の HH 部分にちょうど収まるように
/// している。値範囲は固定で 0..23 (時刻なので明示)。
class _HourNumberField extends StatefulWidget {
  final int value;
  final ValueChanged<int> onCommit;

  const _HourNumberField({required this.value, required this.onCommit});

  @override
  State<_HourNumberField> createState() => _HourNumberFieldState();
}

class _HourNumberFieldState extends State<_HourNumberField> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.value.toString().padLeft(2, '0'));
    _focus = FocusNode();
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _HourNumberField old) {
    super.didUpdateWidget(old);
    final padded = widget.value.toString().padLeft(2, '0');
    if (!_focus.hasFocus && padded != _ctrl.text) {
      _ctrl.text = padded;
    }
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) _commit();
  }

  void _commit() {
    final n = int.tryParse(_ctrl.text);
    if (n == null) {
      _ctrl.text = widget.value.toString().padLeft(2, '0');
      return;
    }
    final clamped = n.clamp(0, 23);
    final padded = clamped.toString().padLeft(2, '0');
    if (padded != _ctrl.text) _ctrl.text = padded;
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
      width: 26,
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
