import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';

/// 時:分 ピッカー (時 + 分の 2 ドロップダウン、1 分単位)。
///
/// 出生時刻入力フォーム (sanctuary_profile_editor) と同じ操作感を提供する。
/// bottom sheet で表示し、決定時に `(hour, minute)` レコードを pop する。
///
/// 2026-05-07: 用途汎用化のため [title] / [subtitle] パラメータ追加。
///   - sanctuary_screen 1日リセット時刻: 引数省略でデフォルト文言
///   - horo_birth_panel 出生時刻 / horo_transit_panel トランジット時刻:
///     `title` / `subtitle: null` を指定して単純な時計設定として使う
class SanctuaryResetHourPicker extends StatefulWidget {
  final int initialHour;
  final int initialMinute;

  /// 上部タイトル文言。null なら build 側で t.resetPicker.title を使う。
  final String? title;

  /// 下のサブテキスト。null なら非表示。
  /// Sanctuary 用途の説明文を出すには呼び出し側で t.resetPicker.subtitle を渡す
  /// (slang の文言は const default にできないため、デフォルト値ではなく呼び出し側で注入する)。
  final String? subtitle;

  const SanctuaryResetHourPicker({
    super.key,
    required this.initialHour,
    this.initialMinute = 0,
    this.title,
    this.subtitle,
  });

  @override
  State<SanctuaryResetHourPicker> createState() => _SanctuaryResetHourPickerState();
}

class _SanctuaryResetHourPickerState extends State<SanctuaryResetHourPicker> {
  late int _hour;
  late int _minute;

  static final _hourOptions = List.generate(24, (i) => i);
  static final _minuteOptions = List.generate(60, (i) => i);

  @override
  void initState() {
    super.initState();
    _hour = widget.initialHour.clamp(0, 23);
    _minute = widget.initialMinute.clamp(0, 59);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title ?? t.resetPicker.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFF9D976),
                fontSize: 16,
                letterSpacing: 2,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                widget.subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFFACACAC), fontSize: 15, height: 1.5),
              ),
            ],
            const SizedBox(height: 22),
            // 時 / 分 を 2 ドロップダウンで選択 (出生時刻フォームと同じスタイル)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _dropdown(
                  value: _hour,
                  options: _hourOptions,
                  unit: t.resetPicker.unitHour,
                  onChanged: (v) => setState(() => _hour = v),
                ),
                const SizedBox(width: 18),
                _dropdown(
                  value: _minute,
                  options: _minuteOptions,
                  unit: t.resetPicker.unitMinute,
                  onChanged: (v) => setState(() => _minute = v),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0x99FFFFFF),
                fontSize: 15,
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFACACAC),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(t.resetPicker.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(
                      (hour: _hour, minute: _minute),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0x33F9D976),
                      foregroundColor: const Color(0xFFF9D976),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0x99F9D976)),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      t.resetPicker.confirm,
                      style: const TextStyle(
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown({
    required int value,
    required List<int> options,
    required String unit,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x22F9D976),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x66F9D976)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          dropdownColor: const Color(0xFF1A1A2E),
          style: const TextStyle(
            color: Color(0xFFF9D976),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          iconEnabledColor: const Color(0xFFF9D976),
          items: options
              .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text('${v.toString().padLeft(2, '0')} $unit'),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
