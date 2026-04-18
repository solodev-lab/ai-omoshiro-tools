import 'dart:ui';

// ══════════════════════════════════════════════════════════════
// Astrology Glyph Paths — elegant thin-stroke vector symbols
// All paths defined in 24×24 unit box, caller scales via Matrix4
// ══════════════════════════════════════════════════════════════

/// Zodiac sign paths (index 0-11 = Aries..Pisces)
Path zodiacGlyph(int index) {
  switch (index) {
    case 0: return _aries();
    case 1: return _taurus();
    case 2: return _gemini();
    case 3: return _cancer();
    case 4: return _leo();
    case 5: return _virgo();
    case 6: return _libra();
    case 7: return _scorpio();
    case 8: return _sagittarius();
    case 9: return _capricorn();
    case 10: return _aquarius();
    case 11: return _pisces();
    default: return Path();
  }
}

/// Planet glyph paths by key
Path planetGlyph(String key) {
  switch (key) {
    case 'sun': return _sun();
    case 'moon': return _moon();
    case 'mercury': return _mercury();
    case 'venus': return _venus();
    case 'mars': return _mars();
    case 'jupiter': return _jupiter();
    case 'saturn': return _saturn();
    case 'uranus': return _uranus();
    case 'neptune': return _neptune();
    case 'pluto': return _pluto();
    default: return Path();
  }
}

// ─────────────────────────────────────
// Zodiac Signs
// ─────────────────────────────────────

// ♈ Aries — two ram horns curving outward from center
Path _aries() {
  return Path()
    // left horn
    ..moveTo(12, 22)
    ..cubicTo(12, 16, 4, 12, 4, 6)
    ..cubicTo(4, 2, 8, 2, 8, 6)
    // right horn
    ..moveTo(12, 22)
    ..cubicTo(12, 16, 20, 12, 20, 6)
    ..cubicTo(20, 2, 16, 2, 16, 6);
}

// ♉ Taurus — circle with horns on top
Path _taurus() {
  return Path()
    // circle
    ..addOval(const Rect.fromLTWH(7, 11, 10, 10))
    // left horn
    ..moveTo(7, 13)
    ..cubicTo(4, 8, 3, 3, 6, 2)
    // right horn
    ..moveTo(17, 13)
    ..cubicTo(20, 8, 21, 3, 18, 2);
}

// ♊ Gemini — two vertical pillars with top/bottom arcs
Path _gemini() {
  return Path()
    // left pillar
    ..moveTo(8, 4)
    ..lineTo(8, 20)
    // right pillar
    ..moveTo(16, 4)
    ..lineTo(16, 20)
    // top arc
    ..moveTo(4, 6)
    ..quadraticBezierTo(12, 0, 20, 6)
    // bottom arc
    ..moveTo(4, 18)
    ..quadraticBezierTo(12, 24, 20, 18);
}

// ♋ Cancer — two interlocking crescents (69 shape)
Path _cancer() {
  return Path()
    // upper crescent (opening right)
    ..moveTo(18, 8)
    ..cubicTo(18, 4, 12, 2, 6, 5)
    ..cubicTo(4, 6, 4, 9, 6, 9)
    ..cubicTo(8, 9, 8, 7, 7, 6)
    // lower crescent (opening left)
    ..moveTo(6, 16)
    ..cubicTo(6, 20, 12, 22, 18, 19)
    ..cubicTo(20, 18, 20, 15, 18, 15)
    ..cubicTo(16, 15, 16, 17, 17, 18)
    // connecting bar
    ..moveTo(6, 9)
    ..lineTo(18, 9)
    ..moveTo(6, 15)
    ..lineTo(18, 15);
}

// ♌ Leo — loop with swooping mane
Path _leo() {
  return Path()
    // circle
    ..addOval(const Rect.fromLTWH(3, 10, 8, 8))
    // tail swooping up and right
    ..moveTo(11, 14)
    ..cubicTo(14, 14, 17, 10, 17, 6)
    ..cubicTo(17, 3, 15, 2, 13, 4)
    ..cubicTo(12, 6, 14, 8, 17, 6)
    // final flick
    ..cubicTo(19, 4, 21, 5, 21, 8);
}

// ♍ Virgo — M with downward curl
Path _virgo() {
  return Path()
    ..moveTo(3, 20)
    ..lineTo(3, 8)
    ..cubicTo(3, 4, 8, 4, 8, 8)
    ..lineTo(8, 14)
    ..moveTo(8, 8)
    ..cubicTo(8, 4, 13, 4, 13, 8)
    ..lineTo(13, 14)
    ..moveTo(13, 8)
    ..cubicTo(13, 4, 18, 4, 18, 8)
    ..lineTo(18, 18)
    ..cubicTo(18, 22, 22, 22, 22, 18)
    // cross stroke
    ..moveTo(16, 16)
    ..lineTo(22, 16);
}

// ♎ Libra — balance beam with two pans
Path _libra() {
  return Path()
    // bottom line
    ..moveTo(4, 20)
    ..lineTo(20, 20)
    // top curve (scale beam)
    ..moveTo(4, 14)
    ..quadraticBezierTo(12, 8, 20, 14)
    // center pillar
    ..moveTo(12, 14)
    ..lineTo(12, 20)
    // upper equal line
    ..moveTo(4, 14)
    ..lineTo(20, 14);
}

// ♏ Scorpio — M with arrow tail
Path _scorpio() {
  return Path()
    ..moveTo(3, 20)
    ..lineTo(3, 8)
    ..cubicTo(3, 4, 8, 4, 8, 8)
    ..lineTo(8, 16)
    ..moveTo(8, 8)
    ..cubicTo(8, 4, 13, 4, 13, 8)
    ..lineTo(13, 16)
    ..moveTo(13, 8)
    ..cubicTo(13, 4, 18, 4, 18, 8)
    ..lineTo(18, 20)
    // arrow
    ..lineTo(22, 16)
    ..moveTo(18, 20)
    ..lineTo(22, 20);
}

// ♐ Sagittarius — diagonal arrow
Path _sagittarius() {
  return Path()
    // shaft
    ..moveTo(4, 20)
    ..lineTo(20, 4)
    // arrowhead
    ..moveTo(13, 4)
    ..lineTo(20, 4)
    ..lineTo(20, 11)
    // cross bar
    ..moveTo(6, 14)
    ..lineTo(14, 14)
    ..moveTo(10, 10)
    ..lineTo(10, 18);
}

// ♑ Capricorn — V-loop with tail
Path _capricorn() {
  return Path()
    ..moveTo(3, 4)
    ..lineTo(3, 16)
    ..cubicTo(3, 20, 7, 20, 10, 16)
    ..cubicTo(13, 12, 14, 12, 15, 14)
    ..cubicTo(16, 17, 18, 20, 20, 20)
    ..cubicTo(22, 20, 22, 17, 20, 15)
    ..cubicTo(18, 13, 16, 15, 18, 17);
}

// ♒ Aquarius — two parallel wavy lines
Path _aquarius() {
  return Path()
    // top wave
    ..moveTo(3, 9)
    ..lineTo(6, 6)
    ..lineTo(9, 9)
    ..lineTo(12, 6)
    ..lineTo(15, 9)
    ..lineTo(18, 6)
    ..lineTo(21, 9)
    // bottom wave
    ..moveTo(3, 16)
    ..lineTo(6, 13)
    ..lineTo(9, 16)
    ..lineTo(12, 13)
    ..lineTo(15, 16)
    ..lineTo(18, 13)
    ..lineTo(21, 16);
}

// ♓ Pisces — two facing arcs with horizontal bar
Path _pisces() {
  return Path()
    // left arc
    ..moveTo(6, 4)
    ..cubicTo(2, 8, 2, 16, 6, 20)
    // right arc
    ..moveTo(18, 4)
    ..cubicTo(22, 8, 22, 16, 18, 20)
    // horizontal bar
    ..moveTo(4, 12)
    ..lineTo(20, 12);
}

// ─────────────────────────────────────
// Planet Symbols
// ─────────────────────────────────────

// ☉ Sun — circle with center dot
Path _sun() {
  return Path()
    ..addOval(const Rect.fromLTWH(4, 4, 16, 16))
    ..addOval(const Rect.fromLTWH(10.5, 10.5, 3, 3));
}

// ☽ Moon — crescent
Path _moon() {
  return Path()
    ..moveTo(16, 4)
    ..cubicTo(10, 4, 6, 8, 6, 12)
    ..cubicTo(6, 16, 10, 20, 16, 20)
    ..cubicTo(12, 18, 10, 15, 10, 12)
    ..cubicTo(10, 9, 12, 6, 16, 4);
}

// ☿ Mercury — circle + cross below + crescent on top
Path _mercury() {
  return Path()
    // crescent on top
    ..moveTo(7, 5)
    ..cubicTo(7, 1, 17, 1, 17, 5)
    // circle
    ..addOval(const Rect.fromLTWH(7, 5, 10, 10))
    // vertical stem
    ..moveTo(12, 15)
    ..lineTo(12, 22)
    // horizontal cross
    ..moveTo(8, 19)
    ..lineTo(16, 19);
}

// ♀ Venus — circle with cross below
Path _venus() {
  return Path()
    ..addOval(const Rect.fromLTWH(6, 2, 12, 12))
    // vertical stem
    ..moveTo(12, 14)
    ..lineTo(12, 22)
    // horizontal cross
    ..moveTo(8, 18)
    ..lineTo(16, 18);
}

// ♂ Mars — circle with arrow upper-right
Path _mars() {
  return Path()
    ..addOval(const Rect.fromLTWH(3, 9, 12, 12))
    // diagonal to arrow
    ..moveTo(13, 11)
    ..lineTo(20, 4)
    // arrowhead
    ..moveTo(15, 4)
    ..lineTo(20, 4)
    ..lineTo(20, 9);
}

// ♃ Jupiter — stylized 4 / 2-like shape
Path _jupiter() {
  return Path()
    // curved top
    ..moveTo(4, 4)
    ..cubicTo(8, 2, 12, 5, 12, 9)
    ..lineTo(12, 20)
    // horizontal bar
    ..moveTo(4, 14)
    ..lineTo(20, 14)
    // left serif
    ..moveTo(8, 11)
    ..lineTo(4, 14);
}

// ♄ Saturn — cross + curved tail
Path _saturn() {
  return Path()
    // cross top
    ..moveTo(8, 2)
    ..lineTo(14, 2)
    ..moveTo(11, 2)
    ..lineTo(11, 10)
    // curved body
    ..cubicTo(15, 10, 17, 12, 17, 15)
    ..cubicTo(17, 18, 14, 20, 11, 18)
    // tail
    ..cubicTo(9, 16, 8, 20, 6, 22);
}

// ♅ Uranus — circle with H shape + dot
Path _uranus() {
  return Path()
    // left vertical
    ..moveTo(6, 4)
    ..lineTo(6, 14)
    // right vertical
    ..moveTo(18, 4)
    ..lineTo(18, 14)
    // horizontal bar
    ..moveTo(6, 9)
    ..lineTo(18, 9)
    // circle below
    ..addOval(const Rect.fromLTWH(8, 14, 8, 8))
    // dot on top
    ..addOval(const Rect.fromLTWH(10.5, 1, 3, 3));
}

// ♆ Neptune — trident
Path _neptune() {
  return Path()
    // vertical shaft
    ..moveTo(12, 4)
    ..lineTo(12, 22)
    // prongs
    ..moveTo(4, 8)
    ..cubicTo(4, 3, 12, 2, 12, 4)
    ..moveTo(20, 8)
    ..cubicTo(20, 3, 12, 2, 12, 4)
    // horizontal bar
    ..moveTo(4, 8)
    ..lineTo(20, 8)
    // cross
    ..moveTo(8, 18)
    ..lineTo(16, 18);
}

// ♇ Pluto — arc on top of circle with cross below
Path _pluto() {
  return Path()
    // arc/crescent on top
    ..moveTo(6, 10)
    ..cubicTo(6, 3, 18, 3, 18, 10)
    // circle
    ..addOval(const Rect.fromLTWH(8, 8, 8, 8))
    // vertical stem
    ..moveTo(12, 16)
    ..lineTo(12, 22)
    // horizontal cross
    ..moveTo(8, 19)
    ..lineTo(16, 19);
}
