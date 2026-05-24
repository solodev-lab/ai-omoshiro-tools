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
            // 年/月/日 を枠なしで均等配置 (バランス重視)。年/月は数字タップで
            // 縦並び選択リスト、日は ◀ ▶ で ±1 日 (月末は翌月へ繰り上げ)。
            Expanded(child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _pickerBlock('年', localDate.year,
                    [for (int y = dateMin.year; y <= dateMax.year; y++) y],
                    (v) => onSetYmd(v, localDate.month, localDate.day)),
                _pickerBlock('月', localDate.month,
                    const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
                    (v) => onSetYmd(localDate.year, v, localDate.day)),
                _dayArrowBlock(localDate.day,
                    DateUtils.getDaysInMonth(localDate.year, localDate.month),
                    () => onShift(days: -1),
                    () => onShift(days: 1),
                    (v) => onSetYmd(localDate.year, localDate.month, v)),
              ],
            )),
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
            Expanded(child: _hourStepperBlock(context, localDate)),
            const SizedBox(width: 36),
          ]),
        ],
      ),
    );
  }

  /// 時刻ステッパーブロック (◀ HH:00 ▶)。
  /// ◀ で 1 時間戻し / ▶ で 1 時間進め (0 ⇄ 23 でラップ)。
  /// 中央は単一 Text「HH:00」(タップでダイアログ入力)。以前はインライン
  /// TextField + ':00' Text の混在で両者の高さが揃わなかったため、1 つの
  /// Text にまとめて高さズレを根本解消した。
  Widget _hourStepperBlock(BuildContext context, DateTime localDate) {
    final hh = displayHour.toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x33C9A84C)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(children: [
        _arrowBtn(Icons.arrow_left, () => onShiftHour(-1)),
        Expanded(child: GestureDetector(
          onTap: () => _editHour(context),
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Text('$hh:00',
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE8E0D0),
                    fontWeight: FontWeight.w600)),
          ),
        )),
        _arrowBtn(Icons.arrow_right, () => onShiftHour(1)),
      ]),
    );
  }

  /// 時刻 (0〜23) をダイアログで直接入力。◀ ▶ 以外で任意の時刻にしたいとき用。
  Future<void> _editHour(BuildContext context) async {
    final ctrl = TextEditingController(text: '$displayHour');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14142A),
        title: const Text('時刻 (0〜23)',
            style: TextStyle(color: Color(0xFFE8E0D0), fontSize: 14)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          cursorColor: const Color(0xFFC9A84C),
          style: const TextStyle(color: Color(0xFFE8E0D0), fontSize: 18),
          decoration: const InputDecoration(suffixText: '時'),
          onSubmitted: (_) => Navigator.pop(ctx, int.tryParse(ctrl.text)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル',
                  style: TextStyle(color: Color(0xFF888888)))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text)),
              child: const Text('OK',
                  style: TextStyle(color: Color(0xFFC9A84C)))),
        ],
      ),
    );
    if (result != null) onSetHour(result.clamp(0, 23));
  }

  /// 年/月: 枠なしのドロップダウン。数字タップで縦並びの選択リストが開く (△ なし)。
  /// 幅は内容ぶんだけ (Expanded しない) → 余白は日(◀▶)側に回る。
  Widget _pickerBlock(
      String unit, int value, List<int> options, ValueChanged<int> onSet) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          alignment: Alignment.center,
          dropdownColor: const Color(0xFF14142A),
          // △(▼)は出さない。数字タップで縦並びの選択リストが開く。
          icon: const SizedBox.shrink(),
          style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFE8E0D0),
              fontWeight: FontWeight.w600),
          items: [
            for (final o in options)
              DropdownMenuItem<int>(value: o, child: Text('$o')),
          ],
          onChanged: (v) {
            if (v != null) onSet(v);
          },
        ),
      ),
      Text(unit,
          style: const TextStyle(fontSize: 8, color: Color(0xFF666666))),
    ]);
  }

  /// 日: ◀ [数値] ▶ で 1 日ずつ移動。数値タップで直接入力も可。
  /// 年/月と同じく枠なし・コンパクト (◀ と ▶ を数値のすぐ両脇に置く)。
  Widget _dayArrowBlock(int value, int maxDay, VoidCallback onPrev,
      VoidCallback onNext, ValueChanged<int> onSet) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        _arrowBtn(Icons.arrow_left, onPrev),
        _DateNumberField(value: value, min: 1, max: maxDay, onCommit: onSet),
        _arrowBtn(Icons.arrow_right, onNext),
      ]),
      const Text('日',
          style: TextStyle(fontSize: 8, color: Color(0xFF666666))),
    ]);
  }

  /// 左右移動ボタン (◀ / ▶ = 黄色の三角アイコン)。日付・時刻で共用。
  /// テキスト三角は拡大時に下が切れたため Icon を使用 (size 固定で切れない)。
  Widget _arrowBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 40,
        height: 36,
        alignment: Alignment.center,
        child: Icon(icon, size: 34, color: const Color(0xFFC9A84C)),
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
      // 1.33x スケールで 12px→16px になるため、18 だと縦に切れる。24 に拡張。
      height: 24,
      child: TextField(
        controller: _ctrl,
        focusNode: _focus,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
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
