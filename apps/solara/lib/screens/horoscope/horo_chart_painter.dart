import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'horo_astro_glyphs.dart';

// ─── ローマ数字 (Ⅰ–Ⅻ) for antique house numbering ───
const List<String> _romanNumerals = [
  'Ⅰ', 'Ⅱ', 'Ⅲ', 'Ⅳ', 'Ⅴ', 'Ⅵ', 'Ⅶ', 'Ⅷ', 'Ⅸ', 'Ⅹ', 'Ⅺ', 'Ⅻ',
];

// ══════════════════════════════════════════════════
// Legend Item
// HTML: .legend-item { display:flex; align-items:center; gap:6px; }
// ══════════════════════════════════════════════════

class HoroLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  /// 'line' = 太バー (アスペクト線用), 'dot' = 丸 (惑星用)
  final String shape;
  const HoroLegendItem({
    super.key, required this.color, required this.label,
    this.shape = 'line',
  });

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (shape == 'dot')
        Container(width: 8, height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color))
      else
        Container(width: 14, height: 3,
          decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(1.5))),
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
  /// Breathing animation value 0.0–1.0 (for glow pulse)
  final double breath;
  /// Secondary chart (transit/progressed) ASC & MC — drawn at outer ring
  final double? secondaryAsc, secondaryMc;
  /// Prefix for secondary labels ('t' for transit, 'p' for progressed)
  final String secondaryLabelPrefix;

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
    this.breath = 0.5,
    this.secondaryAsc,
    this.secondaryMc,
    this.secondaryLabelPrefix = 't',
  });

  static const _pGlyphs ={'sun':'☉','moon':'☽','mercury':'☿','venus':'♀','mars':'♂',
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

      // Zodiac glyphs — image overlay drawn in horoscope_screen Stack (not here)
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
          Paint()..color = const Color(0x40FFFFFF)..strokeWidth = 0.8,
        );

        // Roman numeral house at innerR + 18 (antique serif, copper gold, larger)
        final numR = (innerR + 18 * scale);
        final nextIdx = (i + 1) % 12;
        final midHouseAngle = _lonToAngle((houseList[i] + houseList[nextIdx]) / 2 +
            (houseList[nextIdx] < houseList[i] ? 180 : 0));
        final houseRoman = _romanNumerals[i];
        final htp = TextPainter(
          text: TextSpan(
            text: houseRoman,
            style: GoogleFonts.cinzel(
              fontSize: 20 * scale,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFC9A84C).withAlpha(230),
              letterSpacing: 0.8,
              shadows: [
                Shadow(color: const Color(0xFFC9A84C).withAlpha(100), blurRadius: 4 * scale),
              ],
            ),
          ),
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
        (asc, 'A', const Color(0xFFFFD370)),
        (dsc, 'D', const Color(0xFFFFD370)),
        (mc, 'M', const Color(0xFFFFD370)),
        (ic, 'I', const Color(0xFFFFD370)),
      ];
      const glowPulse = 1.0; // fixed at brightest — no breathing on axes
      for (final (lon, label, color) in angleAxes) {
        final angle = _lonToAngle(lon);
        final p1 = Offset(cx + centerR * cos(angle), cy + centerR * sin(angle));
        final p2 = Offset(cx + zodiacInner * cos(angle), cy + zodiacInner * sin(angle));
        // Wide glow halo (replaces MaskFilter.blur 5px = saveLayer): 2-layer stacked stroke
        canvas.drawLine(p1, p2, Paint()
          ..color = color.withAlpha((0.10 * glowPulse * 255).round())
          ..strokeWidth = 10 * scale);
        canvas.drawLine(p1, p2, Paint()
          ..color = color.withAlpha((0.22 * glowPulse * 255).round())
          ..strokeWidth = 5 * scale);
        // Sharp line
        canvas.drawLine(p1, p2, Paint()
          ..color = color.withAlpha((0.55 * glowPulse * 255).round())
          ..strokeWidth = 1 * scale);
        // Label just outside zodiac band (slightly inward from previous 308)
        final labelR = (zodiacOuter + 8 * scale);
        final ltp = TextPainter(
          text: TextSpan(text: label, style: GoogleFonts.cinzel(
            fontSize: 22 * scale,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: color,
            shadows: [
              Shadow(color: color.withAlpha(160), blurRadius: 8 * scale),
              Shadow(color: color.withAlpha(90), blurRadius: 14 * scale),
            ],
          )),
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
              text: TextSpan(text: style.label, style: TextStyle(fontSize: 16 * scale, color: style.stroke)),
              textDirection: TextDirection.ltr,
            )..layout();
            ltp.paint(canvas, Offset(cxP - ltp.width / 2, cyP - 10 * scale - ltp.height / 2));
            // Planet glyphs below label (with source prefix)
            final pText = List.generate(pkeys.length, (i) =>
              '${sources[i]}${_pGlyphs[pkeys[i]] ?? pkeys[i]}').join('');
            final ptp = TextPainter(
              text: TextSpan(text: pText, style: TextStyle(fontSize: 14 * scale, color: style.stroke.withAlpha(153))),
              textDirection: TextDirection.ltr,
            )..layout();
            ptp.paint(canvas, Offset(cxP - ptp.width / 2, cyP + 10 * scale - ptp.height / 2));
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
          text: TextSpan(text: '☌', style: TextStyle(fontSize: 20 * scale, color: color)),
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

    // ── Planet glyphs (vector paths) with dramatic golden pulse ──
    // breath: 0..1, widen variance so it is clearly visible
    final pulse = 0.4 + 0.6 * breath;
    // 衝突回避: glyph表示用に longitude をずらした displayLon を計算
    // 真の位置にはドットを置き、ずらした位置にグリフを置く + leader line で接続
    // ASC/MC/DSC/IC は固定 anchor (動かさない)
    final natalAnchors = birthTimeUnknown ? <String, double>{} : {
      '_asc': asc,
      '_mc': mc,
      '_dsc': (asc + 180) % 360,
      '_ic': (mc + 180) % 360,
    };
    final natalDisplay = _spreadOverlappingPlanets(
      planets, minGapDeg: 8.0, anchors: natalAnchors);
    for (final e in planets.entries) {
      final trueAngle = _lonToAngle(e.value);
      final dotPos = Offset(cx + planetR * cos(trueAngle), cy + planetR * sin(trueAngle));

      // Expanding halo — radius grows with breath, opacity fades
      // (MaskFilter.blur 撤去 → 3 層 alpha 円で Gaussian-like falloff、saveLayer ゼロ)
      final haloR = (5 + 8 * breath) * scale;
      final haloAlpha = (0.55 * (1.0 - breath * 0.6) * 255).round();
      const haloColor = Color(0xFFF6BD60);
      canvas.drawCircle(dotPos, haloR + 8 * scale, Paint()
        ..color = haloColor.withAlpha((haloAlpha * 0.10).round().clamp(0, 255)));
      canvas.drawCircle(dotPos, haloR + 4 * scale, Paint()
        ..color = haloColor.withAlpha((haloAlpha * 0.28).round().clamp(0, 255)));
      canvas.drawCircle(dotPos, haloR, Paint()
        ..color = haloColor.withAlpha(haloAlpha));

      // Secondary expanding ring (stroke, for clear "pulse" read)
      canvas.drawCircle(dotPos, haloR + 3 * scale, Paint()
        ..color = const Color(0xFFF6BD60).withAlpha(((0.5 - 0.5 * breath) * 255).round().clamp(0, 255))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * scale);

      // Dot with breathing brightness (at true position)
      canvas.drawCircle(dotPos, (2.5 + 1.0 * breath) * scale,
        Paint()..color = Color.lerp(const Color(0xFFC9A84C), const Color(0xFFFFE89A), breath)!);

      // Displayed glyph position (may be shifted for overlap avoidance)
      final displayLon = natalDisplay[e.key] ?? e.value;
      final displayAngle = _lonToAngle(displayLon);
      final glyphOffset = 18 * scale;
      final gx = cx + (planetR + glyphOffset) * cos(displayAngle);
      final gy = cy + (planetR + glyphOffset) * sin(displayAngle);

      // Leader line when glyph was displaced
      if ((displayLon - e.value).abs() > 0.3) {
        final leaderStart = Offset(
          cx + (planetR + 4 * scale) * cos(trueAngle),
          cy + (planetR + 4 * scale) * sin(trueAngle));
        final leaderEnd = Offset(
          cx + (planetR + glyphOffset - 12 * scale) * cos(displayAngle),
          cy + (planetR + glyphOffset - 12 * scale) * sin(displayAngle));
        canvas.drawLine(leaderStart, leaderEnd, Paint()
          ..color = const Color(0xFFFFD370).withAlpha(120)
          ..strokeWidth = 0.8 * scale);
      }

      _drawVectorGlyph(canvas, planetGlyph(e.key), const Color(0xFFFFD370),
        gx, gy, 24 * scale, strokeWidth: 2.0 * scale, glow: true,
        glowIntensity: pulse);
    }

    // ── Secondary planet glyphs (transit/progressed at outer ring) ──
    // HTML: secondaryR = 248
    if (secondaryPlanets != null && secondaryPlanets!.isNotEmpty) {
      final secondaryR = 248 * scale;
      final secAnchors = <String, double>{
        '_sasc': ?secondaryAsc,
        '_smc': ?secondaryMc,
        if (secondaryAsc != null) '_sdsc': (secondaryAsc! + 180) % 360,
        if (secondaryMc != null) '_sic': (secondaryMc! + 180) % 360,
      };
      final secDisplay = _spreadOverlappingPlanets(
        secondaryPlanets!, minGapDeg: 7.0, anchors: secAnchors);
      // Lighter shade of secondaryColor for breathing bright state
      final secondaryBright = Color.lerp(secondaryColor, Colors.white, 0.55)!;
      for (final e in secondaryPlanets!.entries) {
        final trueAngle = _lonToAngle(e.value);
        final dotPos = Offset(cx + secondaryR * cos(trueAngle), cy + secondaryR * sin(trueAngle));

        // Expanding halo — 3-layer alpha (replaces MaskFilter.blur)
        final sHaloR = (5 + 8 * breath) * scale;
        final sHaloAlpha = (0.55 * (1.0 - breath * 0.6) * 255).round();
        canvas.drawCircle(dotPos, sHaloR + 8 * scale, Paint()
          ..color = secondaryBright.withAlpha((sHaloAlpha * 0.10).round().clamp(0, 255)));
        canvas.drawCircle(dotPos, sHaloR + 4 * scale, Paint()
          ..color = secondaryBright.withAlpha((sHaloAlpha * 0.28).round().clamp(0, 255)));
        canvas.drawCircle(dotPos, sHaloR, Paint()
          ..color = secondaryBright.withAlpha(sHaloAlpha));

        // Expanding ring (stroke, pulse outward)
        canvas.drawCircle(dotPos, sHaloR + 3 * scale, Paint()
          ..color = secondaryBright.withAlpha(((0.5 - 0.5 * breath) * 255).round().clamp(0, 255))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8 * scale);

        // Dot with breathing brightness
        canvas.drawCircle(dotPos, (2.5 + 1.0 * breath) * scale,
          Paint()..color = Color.lerp(secondaryColor, secondaryBright, breath)!);

        final displayLon = secDisplay[e.key] ?? e.value;
        final displayAngle = _lonToAngle(displayLon);
        final gx = cx + (secondaryR + 18 * scale) * cos(displayAngle);
        final gy = cy + (secondaryR + 18 * scale) * sin(displayAngle);

        // Leader line when displaced
        if ((displayLon - e.value).abs() > 0.3) {
          final leaderStart = Offset(
            cx + (secondaryR + 4 * scale) * cos(trueAngle),
            cy + (secondaryR + 4 * scale) * sin(trueAngle));
          final leaderEnd = Offset(
            cx + (secondaryR + 18 * scale - 12 * scale) * cos(displayAngle),
            cy + (secondaryR + 18 * scale - 12 * scale) * sin(displayAngle));
          canvas.drawLine(leaderStart, leaderEnd, Paint()
            ..color = secondaryColor.withAlpha(120)
            ..strokeWidth = 0.8 * scale);
        }

        _drawVectorGlyph(canvas, planetGlyph(e.key), secondaryColor,
          gx, gy, 24 * scale, strokeWidth: 1.9 * scale, glow: true);
      }
    }

    // ── Secondary ASC/MC/DSC/IC markers (transit/progressed) ──
    // 外周の secondaryR リング上に短いマーカー＋ラベル
    if (secondaryAsc != null && secondaryMc != null) {
      final sR = 248 * scale;
      final sDsc = (secondaryAsc! + 180) % 360;
      final sIc = (secondaryMc! + 180) % 360;
      final markers = [
        (secondaryAsc!, '${secondaryLabelPrefix}A', secondaryColor),
        (sDsc, '${secondaryLabelPrefix}D', secondaryColor),
        (secondaryMc!, '${secondaryLabelPrefix}M', secondaryColor),
        (sIc, '${secondaryLabelPrefix}I', secondaryColor),
      ];
      for (final (lon, label, color) in markers) {
        final a = _lonToAngle(lon);
        // Short tick: from sR-8 to sR+4
        final p1 = Offset(cx + (sR - 8 * scale) * cos(a), cy + (sR - 8 * scale) * sin(a));
        final p2 = Offset(cx + (sR + 4 * scale) * cos(a), cy + (sR + 4 * scale) * sin(a));
        // Glow halo (replaces MaskFilter.blur 4px = saveLayer): 2-layer stacked stroke
        canvas.drawLine(p1, p2, Paint()
          ..color = color.withAlpha(40)
          ..strokeWidth = 9 * scale);
        canvas.drawLine(p1, p2, Paint()
          ..color = color.withAlpha(80)
          ..strokeWidth = 4 * scale);
        // Sharp stroke
        canvas.drawLine(p1, p2, Paint()
          ..color = color
          ..strokeWidth = 1.5 * scale
          ..strokeCap = StrokeCap.round);
        // Label outside
        final labelR = sR + 18 * scale;
        final ltp = TextPainter(
          text: TextSpan(text: label, style: GoogleFonts.cinzel(
            fontSize: 18 * scale,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: color,
            shadows: [
              Shadow(color: color.withAlpha(140), blurRadius: 6 * scale),
            ],
          )),
          textDirection: TextDirection.ltr,
        )..layout();
        ltp.paint(canvas, Offset(
          cx + labelR * cos(a) - ltp.width / 2,
          cy + labelR * sin(a) - ltp.height / 2,
        ));
      }
    }

    // ── Center medallion — antique parchment disc with gold bezel ──
    final medalRect = Rect.fromCircle(center: center, radius: centerR);
    canvas.drawCircle(center, centerR, Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF1A1328), Color(0xFF0A0A14)],
      ).createShader(medalRect));
    // Gold breathing halo — replaces MaskFilter.blur with 2-layer stacked stroke ring
    final haloRadiusPulse = centerR + (2 + 10 * breath) * scale;
    final haloAlphaPulse = (0.55 * (1.0 - breath * 0.4) * 255).round().clamp(0, 255);
    final haloStroke = (3 + 2 * breath) * scale;
    canvas.drawCircle(center, haloRadiusPulse, Paint()
      ..color = const Color(0xFFF6BD60).withAlpha((haloAlphaPulse * 0.30).round().clamp(0, 255))
      ..style = PaintingStyle.stroke
      ..strokeWidth = haloStroke + (8 + 6 * breath) * scale);
    canvas.drawCircle(center, haloRadiusPulse, Paint()
      ..color = const Color(0xFFF6BD60).withAlpha(haloAlphaPulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = haloStroke);
    // Inner steady glow — 2-layer stacked stroke (replaces MaskFilter.blur 3px)
    final innerAlpha = ((0.3 + 0.3 * breath) * 255).round();
    canvas.drawCircle(center, centerR + 3 * scale, Paint()
      ..color = const Color(0xFFC9A84C).withAlpha((innerAlpha * 0.40).round().clamp(0, 255))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6 * scale);
    canvas.drawCircle(center, centerR + 3 * scale, Paint()
      ..color = const Color(0xFFC9A84C).withAlpha(innerAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale);
    // Double gold bezel
    canvas.drawCircle(center, centerR, Paint()
      ..color = const Color(0xFFC9A84C).withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale);
    canvas.drawCircle(center, centerR - 3 * scale, Paint()
      ..color = const Color(0xFFC9A84C).withAlpha(90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6 * scale);
    // Cardinal decorative dots
    for (int i = 0; i < 4; i++) {
      final a = (i * 90 - 90) * pi / 180;
      canvas.drawCircle(
        Offset(cx + (centerR - 1.5 * scale) * cos(a), cy + (centerR - 1.5 * scale) * sin(a)),
        1.4 * scale,
        Paint()..color = const Color(0xFFF6BD60).withAlpha(220));
    }

    // Center: ASC/度数は時刻ありのみ。時刻不明時は星座シンボル (Sun sign) だけ表示 (overlayで)
    if (!birthTimeUnknown) {
      final deg = (asc % 30).toStringAsFixed(1);
      // Line 1: "ASC"
      _drawCenterSerif(canvas, cx, cy - 26 * scale, 'ASC', 18 * scale,
        const Color(0xFFC9A84C).withAlpha(210),
        weight: FontWeight.w700, letterSpacing: 2.0);
      // Line 2: zodiac image overlay (rendered in Stack)
      // Line 3: degree — same weight as ASC label
      _drawCenterSerif(canvas, cx, cy + 26 * scale, '$deg°', 18 * scale,
        const Color(0xFFC9A84C).withAlpha(210),
        weight: FontWeight.w700, letterSpacing: 1.0);
    }
    // 時刻不明時はテキスト描画しない (星座シンボルのみ Stack 側で表示)
  }

  /// Draw centered Cinzel serif text (視認性優先 — Cormorant Garamondは廃止)
  void _drawCenterSerif(Canvas canvas, double cx, double y, String text,
      double fontSize, Color color,
      {FontWeight weight = FontWeight.w400,
      double letterSpacing = 0.3}) {
    final style = GoogleFonts.cinzel(
      fontSize: fontSize, color: color, fontWeight: weight,
      letterSpacing: letterSpacing);
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, y - tp.height / 2));
  }

  /// Draw a vector glyph (Path) centered at (cx, cy) with given size.
  /// Glyph paths are defined in a 24×24 unit box.
  void _drawVectorGlyph(Canvas canvas, Path glyph, Color color,
      double cx, double cy, double size,
      {double strokeWidth = 1.2, bool glow = false, double glowIntensity = 1.0}) {
    final s = size / 24.0;
    final matrix = Float64List.fromList([
      s, 0, 0, 0,
      0, s, 0, 0,
      0, 0, 1, 0,
      cx - size / 2, cy - size / 2, 0, 1,
    ]);
    final transformed = glyph.transform(matrix);

    // Glow layer (replaces MaskFilter.blur 3px = saveLayer): 2-layer stacked stroke
    if (glow) {
      canvas.drawPath(transformed, Paint()
        ..color = color.withAlpha((25 * glowIntensity).round().clamp(0, 255))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);
      canvas.drawPath(transformed, Paint()
        ..color = color.withAlpha((50 * glowIntensity).round().clamp(0, 255))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);
    }

    // Main stroke
    canvas.drawPath(transformed, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
  }

  /// 重なった惑星の表示経度を外側に広げて衝突回避。
  /// 真の位置は変えず、グリフ表示用の displayLon を返す。
  /// [anchors] はASC/MC/DSC/IC等の固定基準点 — これらは動かさず、
  ///          惑星側を押し退ける。
  Map<String, double> _spreadOverlappingPlanets(
      Map<String, double> src, {
      double minGapDeg = 8.0,
      Map<String, double>? anchors,
  }) {
    if (src.isEmpty) return <String, double>{};
    // 全点(惑星+anchor)をソート
    final items = <_SpreadItem>[
      for (final e in src.entries) _SpreadItem(e.key, e.value, false),
      if (anchors != null)
        for (final e in anchors.entries) _SpreadItem(e.key, e.value, true),
    ]..sort((a, b) => a.lon.compareTo(b.lon));

    // 隣接点が minGapDeg 以内なら同じクラスタ
    final clusters = <List<_SpreadItem>>[];
    var current = <_SpreadItem>[items.first];
    for (int i = 1; i < items.length; i++) {
      final gap = _angDistSigned(current.last.lon, items[i].lon).abs();
      if (gap < minGapDeg) {
        current.add(items[i]);
      } else {
        clusters.add(current);
        current = [items[i]];
      }
    }
    clusters.add(current);
    // 360°境界処理
    if (clusters.length >= 2) {
      final tail = clusters.last.last.lon;
      final head = clusters.first.first.lon;
      final wrapGap = ((head + 360) - tail).abs();
      if (wrapGap < minGapDeg) {
        clusters.first.insertAll(0, clusters.removeLast());
      }
    }

    final result = <String, double>{};
    for (final cluster in clusters) {
      if (cluster.length == 1) {
        // 単独 → そのまま (anchor でも planet でも)
        if (!cluster[0].isAnchor) result[cluster[0].key] = cluster[0].lon;
        continue;
      }
      final anchorsInCluster = cluster.where((c) => c.isAnchor).toList();
      final n = cluster.length;

      if (anchorsInCluster.isEmpty) {
        // anchor なし → 従来通り、重心を保って均等分散
        final anchor0 = cluster.first.lon;
        double sum = 0;
        for (final c in cluster) {
          var diff = c.lon - anchor0;
          while (diff > 180) { diff -= 360; }
          while (diff < -180) { diff += 360; }
          sum += diff;
        }
        final center = (anchor0 + sum / n) % 360;
        for (int i = 0; i < n; i++) {
          final offset = (i - (n - 1) / 2.0) * minGapDeg;
          result[cluster[i].key] = (center + offset + 360) % 360;
        }
      } else {
        // anchor あり → anchor位置固定、その周りに惑星を minGap間隔で配置
        // 元の経度順を維持したまま等間隔スロットに割当
        final pivot = anchorsInCluster.first.lon;
        final anchorIdx = cluster.indexOf(anchorsInCluster.first);
        for (int i = 0; i < n; i++) {
          if (cluster[i].isAnchor) continue; // anchorは動かさない (結果mapにも入れない)
          // anchorからの相対位置 (インデックス差) ベースで等間隔配置
          final slot = i - anchorIdx;
          result[cluster[i].key] = (pivot + slot * minGapDeg + 360) % 360;
        }
      }
    }
    return result;
  }

  /// 符号付き最短角度距離 (a→b)
  double _angDistSigned(double a, double b) {
    var d = b - a;
    while (d > 180) { d -= 360; }
    while (d < -180) { d += 360; }
    return d;
  }

  List<double> _defaultHouses() {
    // Equal house system fallback
    return List.generate(12, (i) => (asc + i * 30) % 360);
  }

  @override
  bool shouldRepaint(covariant HoroChartWheelPainter old) =>
      old.breath != breath ||
      old.planets != planets ||
      old.secondaryPlanets != secondaryPlanets ||
      old.secondaryAsc != secondaryAsc ||
      old.secondaryMc != secondaryMc ||
      old.asc != asc ||
      old.mc != mc ||
      old.aspects != aspects ||
      old.patterns != patterns;
}

/// 内部用: 惑星配置広げアルゴリズムの各点
class _SpreadItem {
  final String key;
  final double lon;
  final bool isAnchor; // true = 動かさない (ASC/MC等), false = 動かしてOK (惑星)
  _SpreadItem(this.key, this.lon, this.isAnchor);
}
