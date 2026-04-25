import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════
// ── Orb Overlay (Bottom Sheet) ──
// HTML: birth-overlay > birth-card for Aspect Orbs
// ══════════════════════════════════════════════════

class SanctuaryOrbOverlay extends StatefulWidget {
  final Map<String, double> orbValues;
  const SanctuaryOrbOverlay({super.key, required this.orbValues});

  @override
  State<SanctuaryOrbOverlay> createState() => _SanctuaryOrbOverlayState();
}

class _SanctuaryOrbOverlayState extends State<SanctuaryOrbOverlay> {
  late Map<String, double> _vals;

  static const _majorAspects = [
    ('Conjunction (0°)', 'conjunction', 2.0),
    ('Opposition (180°)', 'opposition', 2.0),
    ('Trine (120°)', 'trine', 2.0),
    ('Square (90°)', 'square', 2.0),
    ('Sextile (60°)', 'sextile', 2.0),
  ];

  static const _minorAspects = [
    ('Quincunx (150°)', 'quincunx', 2.0),
    ('Semi-Sextile (30°)', 'semisextile', 1.0),
    ('Semi-Square (45°)', 'semisquare', 1.0),
  ];

  // HTML exact: PATTERN_ORBS (5 entries)
  static const _patternOrbs = [
    ('Grand Trine (120°)', 'grandtrine', 3.0),
    ('T-Square Opp (180°)', 'tsquare_opp', 3.0),
    ('T-Square Sq (90°)', 'tsquare_sq', 2.5),
    ('Yod Sextile (60°)', 'yod_sextile', 2.5),
    ('Yod Quincunx (150°)', 'yod_quincunx', 1.5),
  ];

  @override
  void initState() {
    super.initState();
    _vals = Map.from(widget.orbValues);
  }

  void _reset() {
    setState(() {
      for (final a in _majorAspects) {
        _vals[a.$2] = a.$3;
      }
      for (final a in _minorAspects) {
        _vals[a.$2] = a.$3;
      }
      for (final a in _patternOrbs) {
        _vals[a.$2] = a.$3;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xF2040810), // rgba(4,8,16,0.95)
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0x1AFFFFFF))),
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: ListView(
          controller: scrollCtrl,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // HTML: .birth-title { font-size:16px; font-weight:700; color:#F9D976; letter-spacing:1px; }
                const Text('🔭 Aspect Orbs',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFF9D976), letterSpacing: 1)),
                Row(children: [
                  GestureDetector(
                    onTap: _reset,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x40F9D976)),
                      ),
                      child: const Text('リセット', style: TextStyle(fontSize: 12, color: Color(0xFFF9D976))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0x14FFFFFF),
                      ),
                      child: const Center(child: Text('✕', style: TextStyle(fontSize: 18, color: Color(0xFFACACAC)))),
                    ),
                  ),
                ]),
              ],
            ),
            const SizedBox(height: 20),

            // Major Aspects
            const _OrbSectionLabel('MAJOR ASPECTS'),
            const SizedBox(height: 8),
            ..._majorAspects.map((a) => _orbRow(a.$1, a.$2, a.$3)),

            const SizedBox(height: 16),

            // Minor Aspects
            const _OrbSectionLabel('MINOR ASPECTS'),
            const SizedBox(height: 8),
            ..._minorAspects.map((a) => _orbRow(a.$1, a.$2, a.$3)),

            const SizedBox(height: 16),

            // HTML exact: Pattern Orbs
            const _OrbSectionLabel('PATTERNS'),
            const SizedBox(height: 8),
            ..._patternOrbs.map((a) => _orbRow(a.$1, a.$2, a.$3)),

            const SizedBox(height: 24),

            // Save button
            GestureDetector(
              onTap: () => Navigator.pop(context, _vals),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFFF9D976), Color(0xFFE8A840)],
                  ),
                ),
                child: const Center(
                  child: Text('保存する', style: TextStyle(
                    color: Color(0xFF0A0A14), fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HTML: .orb-row { padding:8px 10px; border-radius:10px; background:rgba(255,255,255,0.03); }
  Widget _orbRow(String label, String key, double defaultVal) {
    final val = _vals[key] ?? defaultVal;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF), // rgba(255,255,255,0.03)
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // HTML: .orb-name { font-size:12px; color:#ACACAC; min-width:120px; }
          SizedBox(width: 120,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFACACAC)))),
          // − button
          _orbPmBtn('−', () {
            if (val > 0.5) setState(() => _vals[key] = val - 0.5);
          }),
          // Slider with default value mark
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFFF9D976),
                inactiveTrackColor: const Color(0x1AFFFFFF),
                thumbColor: const Color(0xFFF9D976),
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: LayoutBuilder(builder: (ctx, constraints) {
                // Slider track padding = overlayRadius (14) on each side
                const padEach = 14.0;
                final trackW = constraints.maxWidth - padEach * 2;
                final ratio = (defaultVal - 0.5) / (8.0 - 0.5);
                final markX = padEach + ratio * trackW;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Slider(
                      value: val, min: 0.5, max: 8.0,
                      divisions: 15,
                      onChanged: (v) => setState(() => _vals[key] = (v * 2).round() / 2),
                    ),
                    // HTML: .orb-default-mark
                    Positioned(
                      left: markX - 0.5, top: 10, bottom: 10,
                      child: IgnorePointer(
                        child: Container(width: 1, color: const Color(0x40F9D976)),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          // HTML: .orb-val { font-size:13px; color:#F9D976; min-width:36px; text-align:center; }
          SizedBox(width: 36,
            child: Text('${val.toStringAsFixed(1)}°',
              style: TextStyle(fontSize: 13, color: const Color(0xFFF9D976), fontWeight: FontWeight.w600,
                decoration: val == defaultVal ? TextDecoration.underline : null),
              textAlign: TextAlign.center)),
          // + button
          _orbPmBtn('+', () {
            if (val < 8.0) setState(() => _vals[key] = val + 0.5);
          }),
        ],
      ),
    );
  }

  // HTML: .orb-pm { width:26px; height:26px; border-radius:50%; border:1px solid rgba(249,217,118,0.3); color:#F9D976; }
  Widget _orbPmBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 26, height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x4DF9D976)),
      ),
      child: Center(child: Text(label, style: const TextStyle(color: Color(0xFFF9D976), fontSize: 16))),
    ),
  );
}

class _OrbSectionLabel extends StatelessWidget {
  final String text;
  const _OrbSectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(fontSize: 12, color: Color(0xFFACACAC), letterSpacing: 0.5, fontWeight: FontWeight.w600));
}
