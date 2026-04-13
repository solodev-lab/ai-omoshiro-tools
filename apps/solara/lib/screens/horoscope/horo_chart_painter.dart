import 'dart:math';
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════
// Legend Item
// HTML: .legend-item { display:flex; align-items:center; gap:6px; }
// ══════════════════════════════════════════════════

class HoroLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const HoroLegendItem({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
    ]);
  }
}

// ══════════════════════════════════════════════════
// Chart Wheel Painter — HTML SVG 600x600 準拠
// HTML: renderChart() — exact coordinate system & radii
// ══════════════════════════════════════════════════

class HoroChartWheelPainter extends CustomPainter {
  final Map<String, double> planets;
  final Map<String, double>? secondaryPlanets;
  final Color secondaryColor;
  final double asc, mc;
  final List<Map<String, dynamic>> aspects;
  final List<Color> signColors;
  final bool showHouses;
  final List<double>? houses;
  final String userName;
  final String userDate;
  final String userTime;
  final bool birthTimeUnknown;
  /// HTML: detectPatterns() result — drawn as polygons on chart
  final Map<String, List<Map<String, dynamic>>>? patterns;

  HoroChartWheelPainter({
    required this.planets,
    this.secondaryPlanets,
    this.secondaryColor = const Color(0xFF6BB5FF),
    required this.asc,
    required this.mc,
    required this.aspects,
    required this.signColors,
    this.showHouses = true,
    this.houses,
    this.userName = '',
    this.userDate = '',
    this.userTime = '',
    this.birthTimeUnknown = false,
    this.patterns,
  });

  static const _glyphs = ['♈','♉','♊','♋','♌','♍','♎','♏','♐','♑','♒','♓'];
  static const _pGlyphs = {'sun':'☉','moon':'☽','mercury':'☿','venus':'♀','mars':'♂',
    'jupiter':'♃','saturn':'♄','uranus':'♅','neptune':'♆','pluto':'♇'};

  // HTML: toRad(asc - lon + 180) — ASC points to bottom (180°)
  double _lonToAngle(double lon) => (asc - lon + 180) * pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.width / 600;

    // HTML exact radii
    final zodiacOuter = 295 * scale;   // HTML: zodiacOuter = zodiacInner + 25 = 295
    final zodiacInner = 270 * scale;   // HTML: zodiacInner = 270
    final innerR = 220 * scale;        // HTML: innerR = 220
    final planetR = 185 * scale;       // HTML: planetR = 185
    final aspectR = 215 * scale;       // HTML: aspectR = innerR - 5 = 215
    final centerR = 50 * scale;        // HTML: centerR = 50

    final center = Offset(cx, cy);

    // ── Circles ──
    // HTML: outer circle at zodiacInner=270, inner circle at innerR=220
    canvas.drawCircle(center, zodiacOuter, Paint()..color = const Color(0x26FFFFFF)..style = PaintingStyle.stroke..strokeWidth = 1);
    canvas.drawCircle(center, zodiacInner, Paint()..color = const Color(0x26FFFFFF)..style = PaintingStyle.stroke..strokeWidth = 1);
    canvas.drawCircle(center, innerR, Paint()..color = const Color(0x26FFFFFF)..style = PaintingStyle.stroke..strokeWidth = 0.8);

    // ── 12 Zodiac sign sectors ──
    for (int i = 0; i < 12; i++) {
      // HTML: sign boundary at asc - i*30 + 180
      final signLon = (i * 30).toDouble();
      final boundaryAngle = _lonToAngle(signLon);

      // Radial line from zodiacInner to zodiacOuter
      canvas.drawLine(
        Offset(cx + zodiacInner * cos(boundaryAngle), cy + zodiacInner * sin(boundaryAngle)),
        Offset(cx + zodiacOuter * cos(boundaryAngle), cy + zodiacOuter * sin(boundaryAngle)),
        Paint()..color = const Color(0x14FFFFFF)..strokeWidth = 0.5,
      );

      // Glyph at midpoint of sector
      final midLon = signLon + 15;
      final midAngle = _lonToAngle(midLon);
      final glyphR = (zodiacOuter + zodiacInner) / 2;
      final tp = TextPainter(
        text: TextSpan(text: _glyphs[i], style: TextStyle(fontSize: 14 * scale, color: signColors[i].withAlpha(180))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(
        cx + glyphR * cos(midAngle) - tp.width / 2,
        cy + glyphR * sin(midAngle) - tp.height / 2,
      ));
    }

    // ── House lines & Angle axes (skip if birth time unknown) ──
    if (showHouses && !birthTimeUnknown) {
      final houseList = houses ?? _defaultHouses();

      for (int i = 0; i < 12; i++) {
        final angle = _lonToAngle(houseList[i]);
        // HTML: house line from innerR to zodiacInner
        canvas.drawLine(
          Offset(cx + innerR * cos(angle), cy + innerR * sin(angle)),
          Offset(cx + zodiacInner * cos(angle), cy + zodiacInner * sin(angle)),
          Paint()..color = const Color(0x1FFFFFFF)..strokeWidth = 0.7,
        );

        // HTML: house number at innerR + 14
        final numR = (innerR + 14 * scale);
        final nextIdx = (i + 1) % 12;
        final midHouseAngle = _lonToAngle((houseList[i] + houseList[nextIdx]) / 2 +
            (houseList[nextIdx] < houseList[i] ? 180 : 0));
        final houseNum = '${i + 1}';
        final htp = TextPainter(
          text: TextSpan(text: houseNum, style: TextStyle(fontSize: 8 * scale, color: const Color(0x66FFFFFF))),
          textDirection: TextDirection.ltr,
        )..layout();
        htp.paint(canvas, Offset(
          cx + numR * cos(midHouseAngle) - htp.width / 2,
          cy + numR * sin(midHouseAngle) - htp.height / 2,
        ));
      }

      // HTML: 4 Angle axes ASC-DSC, MC-IC (full-width lines)
      final dsc = (asc + 180) % 360;
      final ic = (mc + 180) % 360;
      final angleAxes = [
        (asc, 'ASC', const Color(0xFFFFD370)),
        (dsc, 'DSC', const Color(0xFFFFD370)),
        (mc, 'MC', const Color(0xFF6BB5FF)),
        (ic, 'IC', const Color(0xFF6BB5FF)),
      ];
      for (final (lon, label, color) in angleAxes) {
        final angle = _lonToAngle(lon);
        // HTML: line from center area to zodiacInner, color at 25% opacity
        canvas.drawLine(
          Offset(cx + centerR * cos(angle), cy + centerR * sin(angle)),
          Offset(cx + zodiacInner * cos(angle), cy + zodiacInner * sin(angle)),
          Paint()..color = color.withAlpha(64)..strokeWidth = 1,
        );
        // HTML: label at zodiacInner - 12
        final labelR = zodiacInner - 12 * scale;
        final ltp = TextPainter(
          text: TextSpan(text: label, style: TextStyle(
            fontSize: 10 * scale, fontWeight: FontWeight.bold, color: color)),
          textDirection: TextDirection.ltr,
        )..layout();
        ltp.paint(canvas, Offset(
          cx + labelR * cos(angle) - ltp.width / 2,
          cy + labelR * sin(angle) - ltp.height / 2,
        ));
      }
    }

    // ── Pattern polygons (Grand Trine / T-Square / Yod) ──
    // HTML: buildPatternPolygons() — polygon at r*0.6, fill 12%, stroke 60%
    if (patterns != null) {
      const patternColors = {
        'grandtrine': (fill: Color(0x1FC9A84C), stroke: Color(0x99C9A84C), label: 'Grand Trine'),
        'tsquare': (fill: Color(0x1F6B5CE7), stroke: Color(0x996B5CE7), label: 'T-Square'),
        'yod': (fill: Color(0x1F26D0CE), stroke: Color(0x9926D0CE), label: 'Yod'),
      };
      for (final type in ['grandtrine', 'tsquare', 'yod']) {
        final style = patternColors[type];
        if (style == null) continue;
        for (final p in patterns![type] ?? []) {
          final pkeys = p['planets'] as List<String>;
          final sources = p['sources'] as List<String>? ?? List.filled(pkeys.length, 'N');
          final points = <Offset>[];
          double sumX = 0, sumY = 0;
          for (int pi = 0; pi < pkeys.length; pi++) {
            final k = pkeys[pi];
            final src = sources[pi];
            // N=natal位置, T/P=secondary位置
            final lon = (src == 'N') ? (planets[k] ?? 0) : (secondaryPlanets?[k] ?? planets[k] ?? 0);
            final angle = _lonToAngle(lon);
            final r = innerR * 0.85;
            final px = cx + r * cos(angle);
            final py = cy + r * sin(angle);
            points.add(Offset(px, py));
            sumX += px;
            sumY += py;
          }
          if (points.length >= 3) {
            final path = Path()..addPolygon(points, true);
            canvas.drawPath(path, Paint()..color = style.fill);
            canvas.drawPath(path, Paint()..color = style.stroke..style = PaintingStyle.stroke..strokeWidth = 2 * scale);
            // Label at center
            final cxP = sumX / pkeys.length;
            final cyP = sumY / pkeys.length;
            final ltp = TextPainter(
              text: TextSpan(text: style.label, style: TextStyle(fontSize: 9 * scale, color: style.stroke)),
              textDirection: TextDirection.ltr,
            )..layout();
            ltp.paint(canvas, Offset(cxP - ltp.width / 2, cyP - 6 * scale - ltp.height / 2));
            // Planet glyphs below label (with source prefix)
            final pText = List.generate(pkeys.length, (i) =>
              '${sources[i]}${_pGlyphs[pkeys[i]] ?? pkeys[i]}').join('');
            final ptp = TextPainter(
              text: TextSpan(text: pText, style: TextStyle(fontSize: 8 * scale, color: style.stroke.withAlpha(153))),
              textDirection: TextDirection.ltr,
            )..layout();
            ptp.paint(canvas, Offset(cxP - ptp.width / 2, cyP + 6 * scale - ptp.height / 2));
          }
        }
      }
    }

    // ── Aspect lines ──
    // HTML: aspectR = innerR - 5, stroke-width 1.5, dynamic opacity
    for (final a in aspects) {
      final lon1 = a['lon1'] as double? ?? planets[a['p1']]  ?? 0;
      final lon2 = a['lon2'] as double? ?? planets[a['p2']] ?? 0;
      final ang1 = _lonToAngle(lon1);
      final ang2 = _lonToAngle(lon2);
      final diff = a['diff'] as double? ?? 0;
      final aspAngle = a['aspectAngle'] as double? ?? 0;
      final orb = a['orb'] as double? ?? 2.0;
      final dimmed = a['dimmed'] as bool? ?? false;
      final baseOpacity = (1.0 - (diff - aspAngle).abs() / orb * 0.5).clamp(0.2, 1.0);
      final opacity = dimmed ? baseOpacity * 0.15 : baseOpacity;
      final color = (a['color'] as Color).withAlpha((opacity * 0.95 * 255).round());

      if (aspAngle == 0) {
        // Conjunction: 線が見えないので、両惑星の位置にハイライトリングを描画
        for (final lon in [lon1, lon2]) {
          final ang = _lonToAngle(lon);
          canvas.drawCircle(
            Offset(cx + planetR * cos(ang), cy + planetR * sin(ang)),
            8 * scale,
            Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5 * scale,
          );
        }
        // 中点に☌マーク
        final midLon = (lon1 + lon2) / 2;
        final midAng = _lonToAngle(midLon);
        final tp = TextPainter(
          text: TextSpan(text: '☌', style: TextStyle(fontSize: 10 * scale, color: color)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(
          cx + (planetR - 18 * scale) * cos(midAng) - tp.width / 2,
          cy + (planetR - 18 * scale) * sin(midAng) - tp.height / 2,
        ));
      } else {
        canvas.drawLine(
          Offset(cx + aspectR * cos(ang1), cy + aspectR * sin(ang1)),
          Offset(cx + aspectR * cos(ang2), cy + aspectR * sin(ang2)),
          Paint()..color = color..strokeWidth = 1.5 * scale,
        );
      }
    }

    // ── Planet glyphs ──
    // HTML: dot at r=2, glyph above at y-10
    for (final e in planets.entries) {
      final angle = _lonToAngle(e.value);
      final glyph = _pGlyphs[e.key] ?? '?';

      // Small dot
      canvas.drawCircle(
        Offset(cx + planetR * cos(angle), cy + planetR * sin(angle)),
        2 * scale,
        Paint()..color = const Color(0xFFFFD370),
      );

      // Glyph above dot (offset by ~10 units outward)
      final glyphOffset = 10 * scale;
      final gx = cx + (planetR + glyphOffset) * cos(angle);
      final gy = cy + (planetR + glyphOffset) * sin(angle);
      final tp = TextPainter(
        text: TextSpan(text: glyph, style: TextStyle(fontSize: 13 * scale, color: const Color(0xFFFFD370))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(gx - tp.width / 2, gy - tp.height / 2));
    }

    // ── Secondary planet glyphs (transit/progressed at outer ring) ──
    // HTML: secondaryR = 248
    if (secondaryPlanets != null && secondaryPlanets!.isNotEmpty) {
      final secondaryR = 248 * scale;
      for (final e in secondaryPlanets!.entries) {
        final angle = _lonToAngle(e.value);
        final glyph = _pGlyphs[e.key] ?? '?';
        // Small dot
        canvas.drawCircle(
          Offset(cx + secondaryR * cos(angle), cy + secondaryR * sin(angle)),
          2 * scale,
          Paint()..color = secondaryColor,
        );
        // Glyph
        final gx = cx + (secondaryR + 10 * scale) * cos(angle);
        final gy = cy + (secondaryR + 10 * scale) * sin(angle);
        final tp = TextPainter(
          text: TextSpan(text: glyph, style: TextStyle(fontSize: 12 * scale, color: secondaryColor)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(gx - tp.width / 2, gy - tp.height / 2));
      }
    }

    // ── Center circle ──
    // HTML: centerR=50, filled dark, name/date/ASC info
    canvas.drawCircle(center, centerR, Paint()..color = const Color(0xD90A0A14));
    canvas.drawCircle(center, centerR, Paint()..color = const Color(0x14FFFFFF)..style = PaintingStyle.stroke..strokeWidth = 0.5);

    // HTML: user name at cy-20, date at cy-6, ASC at cy+6
    if (userName.isNotEmpty) {
      _drawCenterText(canvas, cx, cy - 20 * scale, userName, 10 * scale, const Color(0xFFE8E0D0));
    }
    if (userDate.isNotEmpty) {
      final dateTimeStr = '$userDate $userTime';
      _drawCenterText(canvas, cx, cy - 6 * scale, dateTimeStr, 7 * scale, const Color(0xFF888888));
    }
    if (!birthTimeUnknown) {
      final ascText = 'ASC ${_formatDegree(asc)}';
      _drawCenterText(canvas, cx, cy + 6 * scale, ascText, 7 * scale, const Color(0xFF666666));
    } else {
      _drawCenterText(canvas, cx, cy + 6 * scale, '時刻不明', 7 * scale, const Color(0xFF666666));
    }
  }

  void _drawCenterText(Canvas canvas, double cx, double y, String text, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: fontSize, color: color)),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, y - tp.height / 2));
  }

  String _formatDegree(double lon) {
    final signIdx = (lon / 30).floor() % 12;
    final deg = (lon % 30).toStringAsFixed(1);
    return '$deg° ${_glyphs[signIdx]}';
  }

  List<double> _defaultHouses() {
    // Equal house system fallback
    return List.generate(12, (i) => (asc + i * 30) % 360);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
