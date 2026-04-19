import 'package:flutter/material.dart';

import 'horo_antique_icons.dart';
import 'horo_panel_shared.dart';

// ══════════════════════════════════════════════════
// Transit Section (BS tab)
// HTML: #bsTransit — transit date/time/location
// ══════════════════════════════════════════════════

class HoroTransitPanel extends StatelessWidget {
  final String chartMode;
  const HoroTransitPanel({super.key, required this.chartMode});

  @override
  Widget build(BuildContext context) {
    final label = chartMode == 'np' ? 'プログレス更新' : 'トランジット更新';
    final btnColor = chartMode == 'np' ? const Color(0xFFB088FF) : const Color(0xFF6BB5FF);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      horoAntiqueHeader(
        chartMode == 'np' ? AntiqueIcon.progressed : AntiqueIcon.transit,
        chartMode == 'np' ? 'PROGRESSED DATA' : 'TRANSIT DATA'),
      const SizedBox(height: 10),
      _bsInfoRow('日付 DATE', DateTime.now().toString().split(' ')[0]),
      _bsInfoRow('時刻 TIME', '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}'),
      const SizedBox(height: 8),
      Container(
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
          color: Color(0xFF0A0A14), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1))),
      ),
    ]);
  }

  Widget _bsInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888888), letterSpacing: 1)),
        const SizedBox(height: 3),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x0DFFFFFF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFFE8E0D0))),
        ),
      ]),
    );
  }
}
