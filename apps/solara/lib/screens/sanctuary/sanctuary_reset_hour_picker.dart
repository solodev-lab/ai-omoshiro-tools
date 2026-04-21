import 'package:flutter/material.dart';

/// 1日の開始時刻ピッカー（時計風ホイール）。
/// bottom sheet で表示して、選択された hour (0-23) を pop 時に返す。
class SanctuaryResetHourPicker extends StatefulWidget {
  final int initial;
  const SanctuaryResetHourPicker({super.key, required this.initial});

  @override
  State<SanctuaryResetHourPicker> createState() => _SanctuaryResetHourPickerState();
}

class _SanctuaryResetHourPickerState extends State<SanctuaryResetHourPicker> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial.clamp(0, 23);
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
            const Text(
              '✦ 1日の開始時刻',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFF9D976),
                fontSize: 16,
                letterSpacing: 2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'この時刻を跨ぐと「今日のタップボタン」がリセットされます',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFACACAC), fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 180,
              child: ListWheelScrollView.useDelegate(
                controller: FixedExtentScrollController(initialItem: _selected),
                itemExtent: 44,
                perspective: 0.003,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (i) => setState(() => _selected = i),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 24,
                  builder: (_, i) => Center(
                    child: Text(
                      '${i.toString().padLeft(2, '0')}:00',
                      style: TextStyle(
                        color: i == _selected
                            ? const Color(0xFFF9D976)
                            : const Color(0x99FFFFFF),
                        fontSize: i == _selected ? 22 : 17,
                        fontWeight:
                            i == _selected ? FontWeight.w600 : FontWeight.w400,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
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
                    child: const Text('キャンセル'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_selected),
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
                    child: const Text(
                      '決定',
                      style: TextStyle(
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
}
