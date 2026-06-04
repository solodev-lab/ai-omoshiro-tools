import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../sanctuary/sanctuary_profile_editor.dart' show DateSlashFormatter;
import 'horo_antique_icons.dart';
import 'horo_location_input.dart' show HoroLocationInput;
import 'horo_panel_shared.dart';

// ══════════════════════════════════════════════════
// Transit Section (BS tab)
// HTML: #bsTransit — transit date/time/location
//
// 2026-05-05: 日付/時刻を編集可能にし、`onUpdate` callback で親 (horoscope_screen)
// に任意日時を伝えて transit/progressed を再計算できるよう拡張。
// 永続化なし: パネル毎回 `DateTime.now()` で初期化される。
//   - 日付入力: sanctuary_profile_editor の `DateSlashFormatter` 流用
//   - 時刻入力: 時/分の独立プルダウン (HoroHourMinuteDropdown)。
//                2026-05-07 BottomSheet 廃止、インライン編集に統一。
// ══════════════════════════════════════════════════

class HoroTransitPanel extends StatefulWidget {
  final String chartMode;

  /// 場所欄の初期値 (現住所→出生地)。relocate (ハウス=ASC/MC) 計算に使う。
  final double? initialLat;
  final double? initialLng;
  final String? initialPlaceName;

  /// 「トランジット/プログレス更新」ボタン押下時に呼ばれる。
  /// 引数は編集中の日付 + 時刻を合成した DateTime (local) と、場所 (lat/lng)。
  /// 場所は relocate ハウス計算用 (惑星は地心なので場所非依存)。
  final void Function(DateTime when, double? lat, double? lng)? onUpdate;

  const HoroTransitPanel({
    super.key,
    required this.chartMode,
    this.initialLat,
    this.initialLng,
    this.initialPlaceName,
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

  // 場所欄 (HoroLocationInput) の現在値。更新時に relocate として渡す。
  double? _lat;
  double? _lng;

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
    _lat = widget.initialLat;
    _lng = widget.initialLng;
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.chartMode == 'np' ? t.horoPanel.progressUpdate : t.horoPanel.transitUpdate;
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
          Text(t.horoPanel.dateLabel,
              style: const TextStyle(fontSize: 11, color: Color(0xFF888888), letterSpacing: 1)),
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

      // ── 時刻編集: 時/分の独立プルダウン (BottomSheet 廃止、2026-05-07)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.horoPanel.timeLabel,
              style: const TextStyle(fontSize: 11, color: Color(0xFF888888), letterSpacing: 1)),
          const SizedBox(height: 3),
          HoroHourMinuteDropdown(
            hour: _hour,
            minute: _minute,
            onHourChanged: (v) => setState(() => _hour = v),
            onMinuteChanged: (v) => setState(() => _minute = v),
          ),
        ]),
      ),

      // ── 場所編集 (relocate ハウス=ASC/MC 計算用。option 1: 本質/現実トグルの代替) ──
      // 惑星は地心なので場所では変わらない。初期=現住所→出生地。
      HoroLocationInput(
        initialLat: widget.initialLat,
        initialLng: widget.initialLng,
        initialPlaceName: widget.initialPlaceName,
        placeLabel: t.horoPanel.placeLabel,
        showTimezone: false,
        onChanged: (lat, lng, place, tz) {
          _lat = lat;
          _lng = lng;
        },
      ),

      const SizedBox(height: 8),

      // ── 「更新」ボタン: callback に編集日時を渡す
      GestureDetector(
        onTap: widget.onUpdate == null ? null : () {
          final when = DateTime(_date.year, _date.month, _date.day, _hour, _minute);
          widget.onUpdate!(when, _lat, _lng);
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
