import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'horo_antique_icons.dart';
import 'horo_constants.dart';
import 'horo_panel_shared.dart';

// ══════════════════════════════════════════════════
// Planet Table
// HTML: .planet-row
// ══════════════════════════════════════════════════

class HoroPlanetTable extends StatelessWidget {
  final Map<String, double> natalPlanets;
  final double asc, mc;
  final bool birthTimeUnknown;
  /// 2重円モード用: トランジット or プログレスの惑星位置
  final Map<String, double>? secondaryPlanets;
  /// 2重円モード用: トランジット or プログレスの ASC/MC (省略可)
  final double? secondaryAsc, secondaryMc;
  /// 'nt' → 'TRANSIT', 'np' → 'PROGRESSED', それ以外 null
  final String? chartMode;
  const HoroPlanetTable({
    super.key,
    required this.natalPlanets,
    required this.asc, required this.mc,
    required this.birthTimeUnknown,
    this.secondaryPlanets, this.secondaryAsc, this.secondaryMc,
    this.chartMode,
  });

  bool get _hasSecondary =>
      (chartMode == 'nt' || chartMode == 'np') &&
      secondaryPlanets != null && secondaryPlanets!.isNotEmpty;

  String get _secondaryLabel => chartMode == 'np' ? 'PROGRESSED' : 'TRANSIT';
  Color get _secondaryColor => chartMode == 'np'
      ? const Color(0xFFB088FF) : const Color(0xFF6BB5FF);
  AntiqueIcon get _secondaryIcon =>
      chartMode == 'np' ? AntiqueIcon.progressed : AntiqueIcon.transit;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (_hasSecondary) ...[
        // ── Top: Transit/Progressed ──
        Align(
          alignment: Alignment.centerLeft,
          child: Row(children: [
            AntiqueGlyph(icon: _secondaryIcon, size: 18, color: _secondaryColor),
            const SizedBox(width: 8),
            Text('$_secondaryLabel POSITIONS', style: GoogleFonts.cinzel(
              fontSize: 13, color: _secondaryColor,
              letterSpacing: 2.5, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 10),
        if (secondaryAsc != null && secondaryMc != null) ...[
          _planetRow('ASC', 'asc', secondaryAsc!, color: _secondaryColor),
          _planetRow('MC',  'mc',  secondaryMc!,  color: _secondaryColor),
          _planetRow('DSC', 'dsc', (secondaryAsc! + 180) % 360, color: _secondaryColor),
          _planetRow('IC',  'ic',  (secondaryMc!  + 180) % 360, color: _secondaryColor),
          Container(height: 1, color: const Color(0x0AFFFFFF), margin: const EdgeInsets.symmetric(vertical: 4)),
        ],
        ...secondaryPlanets!.entries.map((e) => _planetRow(
          planetNamesJP[e.key] ?? e.key,
          e.key,
          e.value,
          color: _secondaryColor,
        )),
        const SizedBox(height: 16),
      ],
      // ── Bottom: Natal ──
      Align(
        alignment: Alignment.centerLeft,
        child: Row(children: [
          const AntiqueGlyph(icon: AntiqueIcon.planets, size: 18,
            color: Color(0xFFF6BD60)),
          const SizedBox(width: 8),
          Text(_hasSecondary ? 'NATAL POSITIONS' : 'PLANET POSITIONS',
            style: GoogleFonts.cinzel(
              fontSize: 13, color: const Color(0xFFF6BD60),
              letterSpacing: 2.5, fontWeight: FontWeight.w600)),
        ]),
      ),
      const SizedBox(height: 10),
      if (!birthTimeUnknown) ...[
        _planetRow('ASC', 'asc', asc),
        _planetRow('MC', 'mc', mc),
        _planetRow('DSC', 'dsc', (asc + 180) % 360),
        _planetRow('IC', 'ic', (mc + 180) % 360),
        Container(height: 1, color: const Color(0x0AFFFFFF), margin: const EdgeInsets.symmetric(vertical: 4)),
      ],
      ...natalPlanets.entries.map((e) => _planetRow(
        planetNamesJP[e.key] ?? e.key,
        e.key,
        e.value)),
    ]);
  }

  Widget _planetRow(String name, String planetKey, double lon, {Color? color}) {
    final signIdx = (lon / 30).floor() % 12;
    final deg = lon % 30;
    final iconColor = color ?? const Color(0xFFFFD370);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0AFFFFFF))),
      ),
      child: Row(children: [
        SizedBox(width: 24, child: Center(
          child: PlanetVectorIcon(planetKey: planetKey, size: 18, color: iconColor),
        )),
        SizedBox(width: 60, child: Text(name, style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13))),
        ZodiacImageIcon(signIdx: signIdx, size: 18),
        const SizedBox(width: 4),
        Text('${deg.toStringAsFixed(1)}°', style: const TextStyle(
          color: Color(0xFFE8E0D0), fontFamily: 'Courier New', fontSize: 13)),
        const SizedBox(width: 4),
        Text(signNames[signIdx], style: TextStyle(
          color: Color(signColors[signIdx]).withAlpha(180), fontSize: 13)),
      ]),
    );
  }
}
