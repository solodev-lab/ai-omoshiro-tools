import 'package:flutter/material.dart';

import 'horo_antique_icons.dart';
import 'horo_info_row.dart';
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
      HoroInfoRow('日付 DATE', DateTime.now().toString().split(' ')[0]),
      HoroInfoRow('時刻 TIME', '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}'),
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

}
