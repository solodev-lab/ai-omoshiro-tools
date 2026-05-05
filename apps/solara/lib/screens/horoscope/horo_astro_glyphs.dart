import 'dart:ui';

// ══════════════════════════════════════════════════════════════
// Astrology Glyph Paths — elegant thin-stroke vector symbols
// All paths defined in 24×24 unit box, caller scales via Matrix4
// ══════════════════════════════════════════════════════════════

// zodiacGlyph(int) + _aries..._pisces 削除 (audit dead-symbol, 2026-05-06):
// Horoscope 画面の chart 描画は planetGlyph のみ使用。Zodiac sign 表示は
// SVG asset 画像 (assets/zodiac/) で行うため Path 版は不要だった。
// 必要になったら git log から復元可能 (12 関数 / 約 200 行)。

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
