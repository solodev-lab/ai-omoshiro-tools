import 'package:flutter/material.dart';

import '../sanctuary/sanctuary_profile_editor.dart' show DateSlashFormatter;
import '../sanctuary/sanctuary_reset_hour_picker.dart';
import 'horo_antique_icons.dart';
import 'horo_panel_shared.dart';

// ══════════════════════════════════════════════════
// Transit Section (BS tab)
// HTML: #bsTransit — transit date/time/location
//
// 2026-05-05: 日付/時刻を編集可能にし、`onUpdate` callback で親 (horoscope_screen)
// に任意日時を伝えて transit/progressed を再計算できるよう拡張。
// 永続化なし: パネル毎回 `DateTime.now()` で初期化される。
//   - 日付入力: sanctuary_profile_editor の `DateSlashFormatter` 流用
//   - 時刻入力: sanctuary_screen 「日付リセット時刻設定」と同じ
//                `SanctuaryResetHourPicker` を BottomSheet で表示
// ══════════════════════════════════════════════════

class HoroTransitPanel extends StatefulWidget {
  final String chartMode;
  /// 「トランジット/プログレス更新」ボタン押下時に呼ばれる。
  /// 引数は編集中の日付 + 時刻を合成した DateTime (local)。
  final ValueChanged<DateTime>? onUpdate;

  const HoroTransitPanel({
    super.key,
    required this.chartMode,
    this.onUpdate,
  });

  @override
  State<HoroTransitPanel> createState() => _HoroTransitPanelState();
}

class _HoroTransitPanelState extends State<HoroTransitPanel> {
  late TextEditingController _dateCtrl;
  late DateTime _date;
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
    _hour = now.hour;
    _minute = now.minute;
    _dateCtrl = TextEditingController(
      text: '${_date.year}/${_date.month.toString().padLeft(2, '0')}/'
            '${_date.day.toString().padLeft(2, '0')}',
    );
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showModalBottomSheet<({int hour, int minute})>(
      context: context,
      backgroundColor: const Color(0xFF0A0E1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SanctuaryResetHourPicker(
        initialHour: _hour,
        initialMinute: _minute,
      ),
    );
    if (picked == null) return;
    setState(() {
      _hour = picked.hour;
      _minute = picked.minute;
    });
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.chartMode == 'np' ? 'プログレス更新' : 'トランジット更新';
    final btnColor = widget.chartMode == 'np'
        ? const Color(0xFFB088FF)
        : const Color(0xFF6BB5FF);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      horoAntiqueHeader(
        widget.chartMode == 'np' ? AntiqueIcon.progressed : AntiqueIcon.transit,
        widget.chartMode == 'np' ? 'PROGRESSED DATA' : 'TRANSIT DATA'),
      const SizedBox(height: 10),

      // ── 日付編集: sanctuary_profile_editor の生年月日と同じ TextField + DateSlashFormatter
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('日付 DATE',
              style: TextStyle(fontSize: 11, color: Color(0xFF888888), letterSpacing: 1)),
          const SizedBox(height: 3),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: TextField(
              controller: _dateCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13, color: Color(0xFFE8E0D0)),
              decoration: const InputDecoration(
                isDense: true, border: InputBorder.none,
                hintText: 'YYYY/MM/DD',
                hintStyle: TextStyle(color: Color(0x59ACACAC)),
              ),
              inputFormatters: [DateSlashFormatter()],
              onChanged: (v) {
                final parts = v.split('/');
                if (parts.length == 3 && parts[2].length == 2) {
                  final y = int.tryParse(parts[0]);
                  final m = int.tryParse(parts[1]);
                  final d = int.tryParse(parts[2]);
                  if (y != null && m != null && d != null &&
                      y > 1900 && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
                    setState(() => _date = DateTime(y, m, d));
                  }
                }
              },
            ),
          ),
        ]),
      ),

      // ── 時刻編集: sanctuary_screen の「1日の開始時刻」設定と同じ BottomSheet ピッカー
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('時刻 TIME',
              style: TextStyle(fontSize: 11, color: Color(0xFF888888), letterSpacing: 1)),
          const SizedBox(height: 3),
          GestureDetector(
            onTap: _pickTime,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x0DFFFFFF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              child: Text(
                '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 13, color: Color(0xFFE8E0D0)),
              ),
            ),
          ),
        ]),
      ),

      const SizedBox(height: 8),

      // ── 「更新」ボタン: callback に編集日時を渡す
      GestureDetector(
        onTap: widget.onUpdate == null ? null : () {
          final when = DateTime(_date.year, _date.month, _date.day, _hour, _minute);
          widget.onUpdate!(when);
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [btnColor, btnColor.withAlpha(200)],
            ),
          ),
          child: Center(child: Text(label, style: const TextStyle(
            color: Color(0xFF0A0A14), fontSize: 13,
            fontWeight: FontWeight.w600, letterSpacing: 1))),
        ),
      ),
    ]);
  }
}
