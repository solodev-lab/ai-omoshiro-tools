import 'dart:math';
import 'package:flutter/material.dart';

/// Background scene for the Tarot Draw screen.
///
/// Layers (bottom → top):
///   1. Deep-space radial gradient
///   2. Altar photo (zodiac wheel seen from overhead at 45°, with the
///      twelve Roman-numeral houses and candles baked into the image)
///   3. Five personal planets (Sun/Moon/Mercury/Venus/Mars) floating
///      on the altar ring, each with a ground shadow that drops straight
///      down then is tugged toward the altar center by the candle light
///   4. Occasional alpha-keyed shooting-star streaks
///   5. Foreground tabs/card/panels (passed in as `child`)
///
/// Planet positions approximate the current night-sky longitudes
/// (snapshot — ok to be static, this screen isn't a live chart).
class TarotAltarScene extends StatefulWidget {
  final Widget child;
  const TarotAltarScene({super.key, required this.child});

  @override
  State<TarotAltarScene> createState() => _TarotAltarSceneState();
}

class _TarotAltarSceneState extends State<TarotAltarScene>
    with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _meteorCtrl;
  final Random _rng = Random();
  int _meteorIdx = 0;                  // 0..2, which meteor asset
  double _meteorRotation = 0;          // radians — 180° for R→L, 90° for L→R
  Offset _meteorStart = Offset.zero;
  Offset _meteorEnd = Offset.zero;
  double _meteorScale = 1.0;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _meteorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scheduleNextMeteor();
  }

  void _scheduleNextMeteor() {
    // Random 20-90 seconds between meteors
    final delay = Duration(seconds: 20 + _rng.nextInt(71));
    Future.delayed(delay, () {
      if (!mounted) return;
      _triggerMeteor();
    });
  }

  void _triggerMeteor() {
    final size = MediaQuery.of(context).size;
    _meteorIdx = _rng.nextInt(3);

    // Source image has its head pointing to the upper-right.
    // Rotate 180° so the head points lower-left for right→left streaks;
    // rotate 90° (CW) so the head points lower-right for left→right streaks.
    final leftToRight = _rng.nextBool();
    final tiltDeg = -12.0 + _rng.nextDouble() * 22.0; // small jitter

    final double fromX, fromY, dx, dy;
    if (leftToRight) {
      fromX = size.width * (_rng.nextDouble() * 0.35);
      fromY = size.height * (0.08 + _rng.nextDouble() * 0.18);
      dx = size.width * (0.55 + _rng.nextDouble() * 0.3);
      dy = size.height * (0.2 + _rng.nextDouble() * 0.2);
      _meteorRotation = (pi / 2) + tiltDeg * pi / 180;
    } else {
      fromX = size.width * (0.65 + _rng.nextDouble() * 0.35);
      fromY = size.height * (0.08 + _rng.nextDouble() * 0.18);
      dx = -size.width * (0.55 + _rng.nextDouble() * 0.3);
      dy = size.height * (0.2 + _rng.nextDouble() * 0.2);
      _meteorRotation = pi + tiltDeg * pi / 180;
    }

    _meteorStart = Offset(fromX, fromY);
    _meteorEnd = Offset(fromX + dx, fromY + dy);
    _meteorScale = 0.55 + _rng.nextDouble() * 0.35;

    _meteorCtrl.forward(from: 0).whenComplete(_scheduleNextMeteor);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _meteorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Deep-space gradient
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -1),
                  radius: 1.1,
                  colors: [Color(0xFF0F2850), Color(0xFF080C14)],
                  stops: [0.0, 0.55],
                ),
              ),
            ),

            // 2. Altar image — sized with contain-style math so the wheel
            //    is never clipped. Explicit Positioned keeps the wheel
            //    centered and anchored to the bottom (with shift).
            Positioned(
              left: _altarLayout(w, h).left,
              top: _altarLayout(w, h).top,
              width: _altarLayout(w, h).width,
              height: _altarLayout(w, h).height,
              child: Image.asset('assets/tarot_scene/altar.png'),
            ),

            // (Roman numerals are now baked into altar.png itself, so the
            //  Flutter-side painter is no longer needed.)

            // 3. Planets floating around the altar
            ..._buildPlanets(w, h),

            // 4. Shooting star overlay
            AnimatedBuilder(
              animation: _meteorCtrl,
              builder: (_, __) => _meteorCtrl.value > 0 && _meteorCtrl.value < 1
                  ? _buildMeteor()
                  : const SizedBox.shrink(),
            ),

            // 5. Foreground content (tabs, card, panels)
            widget.child,
          ],
        );
      },
    );
  }

  // ── Altar & planet layout ─────────────────────────────────
  // How far the altar sinks below the screen bottom edge (fraction of h).
  // 0 = bottom of image flush with screen bottom.
  // Negative = image lifted UP so the bottom of the altar is visible.
  static const double _altarBottomShift = -0.04;

  // Altar wheel metrics inside the SOURCE image (0..1 of image dims).
  // Current source is 1024×1024 (1:1): wheel ellipse sits centered-low,
  // ~45% of image width horizontally, ~22% of image height vertically.
  static const double _altarCenterYInImg = 0.56;
  static const double _altarRingRxInImg = 0.45;
  static const double _altarRingRyInImg = 0.22;

  /// Computes the altar image's actual on-screen rectangle and the ring
  /// ellipse metrics, using contain-like sizing so the wheel never clips.
  _AltarLayout _altarLayout(double w, double h) {
    const imgRatioWH = 1024.0 / 1024.0;  // source w / h (square)
    final double imgW, imgH;
    if (w / h > imgRatioWH) {
      imgH = h;
      imgW = h * imgRatioWH;
    } else {
      imgW = w;
      imgH = w / imgRatioWH;
    }
    final left = (w - imgW) / 2;
    final bottom = h + h * _altarBottomShift;  // off-screen extension
    final top = bottom - imgH;
    final cx = left + imgW / 2;
    final cy = top + imgH * _altarCenterYInImg;
    final rx = imgW * _altarRingRxInImg;
    final ry = imgH * _altarRingRyInImg;
    return _AltarLayout(
      left: left, top: top, width: imgW, height: imgH,
      cx: cx, cy: cy, rx: rx, ry: ry,
    );
  }

  /// Five personal planets at approximate current-sky longitudes.
  /// Screen coord convention: lonDeg 0°=E, 90°=N(top), 180°=W, 270°=S(bot).
  /// The baseline ellipse + shadow rule below were tuned from a cardinal
  /// demo so that planets land naturally on every bearing.
  static const List<_PlanetDef> _planets = [
    _PlanetDef('sun',     lonDeg: 30,  size: 54, z: 2),  // Taurus ~0°
    _PlanetDef('moon',    lonDeg: 100, size: 33, z: 2),  // Cancer ~10°
    _PlanetDef('mercury', lonDeg: 18,  size: 38, z: 1),  // Aries ~18°
    _PlanetDef('venus',   lonDeg: 358, size: 44, z: 1),  // Pisces ~28°
    _PlanetDef('mars',    lonDeg: 118, size: 44, z: 1),  // Cancer ~28°
  ];

  List<Widget> _buildPlanets(double w, double h) {
    final layout = _altarLayout(w, h);
    final cx = layout.cx;
    // Ellipse calibrated from the cardinal-direction demo:
    //   North (sin=-1) → cy - ry  should match the "good" Moon spot
    //   South (sin=+1) → cy + ry  should match the "good" Sun spot
    //   Resulting in a vertically-stretched ring, shifted slightly up.
    final cy = layout.cy - h * 0.05;
    final rx = layout.rx * 0.68;
    final ry = layout.ry * 0.68 + h * 0.03;
    // Sort by y so nearer-camera planets paint on top (painter's algorithm)
    final sorted = List<_PlanetDef>.from(_planets)
      ..sort((a, b) {
        final ay = sin(-a.lonDeg * pi / 180);
        final by = sin(-b.lonDeg * pi / 180);
        return ay.compareTo(by);
      });
    // Two-pass build so ALL shadows render beneath ALL planet sprites.
    final shadowLayer = <Widget>[];
    final planetLayer = <Widget>[];
    for (final p in sorted) {
      final rad = -p.lonDeg * pi / 180;
      final baseX = cx + rx * cos(rad);
      final baseY = cy + ry * sin(rad);
      final phase = p.lonDeg / 360.0;

      // Per-axis shadow offset rule (simple, deterministic):
      //   baseDrop  +0.6 × size     …  anchor point directly below planet
      //   south component (0..1)    …  move the anchor UP by 0.4 × size
      //   east-west component       …  west→right, east→left, ±0.4 × size
      // No mixing between axes — north planets get no vertical correction,
      // planets on the equator (E/W) get no vertical correction.
      final astroRad = p.lonDeg * pi / 180;       // astrological rad (CCW)
      final southness = max(0.0, -sin(astroRad));  // +1 true south, 0 else
      final eastwest = cos(astroRad);              // +1 true east, -1 true west
      final baseDrop = p.size * 0.60;
      final yCorr = -southness * p.size * 0.40;      // up, toward planet
      final xCorr = -eastwest * p.size * 0.25;       // east→left, west→right
      final shadowW = p.size * 1.75;
      final shadowH = p.size * 0.45;
      final shadowCX = baseX + xCorr;
      final shadowCY = baseY + baseDrop + yCorr;

      // Shadow (drawn in the shadow layer below every planet)
      shadowLayer.add(AnimatedBuilder(
        animation: _floatCtrl,
        builder: (_, __) {
          final t = (_floatCtrl.value + phase) * 2 * pi;
          final dy = sin(t) * 3.5;
          final dx = cos(t * 2) * 1.5;
          return Positioned(
            left: shadowCX - shadowW / 2 + dx,
            top: shadowCY - shadowH / 2 + dy,
            child: IgnorePointer(
              child: Container(
                width: shadowW,
                height: shadowH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(shadowW, shadowH),
                  ),
                  gradient: const RadialGradient(
                    colors: [Color(0xF5000000), Color(0x00000000)],
                    stops: [0.0, 0.95],
                  ),
                ),
              ),
            ),
          );
        },
      ));

      // Planet itself (above ALL shadows)
      planetLayer.add(AnimatedBuilder(
        animation: _floatCtrl,
        builder: (_, __) {
          final t = (_floatCtrl.value + phase) * 2 * pi;
          final dy = sin(t) * 3.5;
          final dx = cos(t * 2) * 1.5;
          final scale = 1.0 + sin(t * 3) * 0.02;
          return Positioned(
            left: baseX - p.size / 2 + dx,
            top: baseY - p.size / 2 + dy,
            child: Transform.scale(
              scale: scale,
              child: _planetSprite(p),
            ),
          );
        },
      ));
    }
    return [...shadowLayer, ...planetLayer];
  }

  Widget _planetSprite(_PlanetDef p) {
    // Shadows are now drawn separately in _buildPlanets so they can be
    // offset toward the altar center. Here we only render the halo (Sun)
    // and the planet sphere.
    final bool isSun = p.name == 'sun';

    return SizedBox(
      width: p.size,
      height: p.size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Sun blaze — three pulsing halo layers (outer red-orange,
          // mid orange, inner yellow) with staggered phases for a
          // "burning" shimmer. Additively blended so the hot core glows.
          if (isSun) _buildSunBlaze(p.size),

          Positioned(
            top: 0,
            child: Image.asset(
              // Saturn's rings can't be represented in an equirectangular
              // sphere texture, so we use the still image with its true
              // single ring plane instead of the rotation WebP.
              p.name == 'saturn'
                  ? 'assets/tarot_scene/planets/saturn_alpha.png'
                  : 'assets/tarot_scene/planet_rotations/${p.name}.webp',
              width: p.size,
              height: p.size,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ),
        ],
      ),
    );
  }

  /// Multi-layer pulsating "blaze" for the Sun — outer red-orange, mid
  /// orange, inner yellow, each breathing at a different rate for a
  /// shimmering flame feel. Blended additively to brighten the core.
  Widget _buildSunBlaze(double size) {
    return Positioned(
      top: -size * 0.9,
      left: -size * 0.9,
      width: size * 2.8,
      height: size * 2.8,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _floatCtrl,
          builder: (_, __) {
            final t = _floatCtrl.value * 2 * pi;
            final s1 = 1.00 + sin(t) * 0.08;            // outer, slow
            final s2 = 1.00 + sin(t * 2 + 1.2) * 0.10;  // mid, double speed
            final s3 = 1.00 + sin(t * 3 + 2.4) * 0.06;  // inner, fast
            final o2 = 0.75 + 0.25 * sin(t * 2 + 1.2);
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer hot corona (deep orange/red, widest)
                Transform.scale(
                  scale: s1,
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0x66FF4A14),
                          Color(0x00000000),
                        ],
                        stops: [0.30, 1.0],
                      ),
                    ),
                  ),
                ),
                // Mid flame layer (orange)
                Opacity(
                  opacity: o2,
                  child: Transform.scale(
                    scale: s2,
                    child: FractionallySizedBox(
                      widthFactor: 0.75,
                      heightFactor: 0.75,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color(0xBBFFA040),
                              Color(0x00000000),
                            ],
                            stops: [0.20, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Inner bright core (yellow)
                Transform.scale(
                  scale: s3,
                  child: FractionallySizedBox(
                    widthFactor: 0.55,
                    heightFactor: 0.55,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0xEEFFF0B8),
                            Color(0x00000000),
                          ],
                          stops: [0.15, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMeteor() {
    final t = Curves.easeInOutCubic.transform(_meteorCtrl.value);
    final x = _meteorStart.dx + (_meteorEnd.dx - _meteorStart.dx) * t;
    final y = _meteorStart.dy + (_meteorEnd.dy - _meteorStart.dy) * t;
    final asset = switch (_meteorIdx) {
      0 => 'assets/tarot_scene/shooting_stars/meteor_short_alpha.png',
      1 => 'assets/tarot_scene/shooting_stars/meteor_mid_alpha.png',
      _ => 'assets/tarot_scene/shooting_stars/meteor_long_alpha.png',
    };
    // Quick fade in/out so the head pops in mid-flight
    final opacity = _meteorCtrl.value < 0.15
        ? _meteorCtrl.value / 0.15
        : _meteorCtrl.value > 0.85
            ? (1 - _meteorCtrl.value) / 0.15
            : 1.0;
    return Positioned(
      left: x,
      top: y,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: _meteorRotation,
          alignment: Alignment.center,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Image.asset(
              asset,
              width: 87 * _meteorScale,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanetDef {
  final String name;
  final double lonDeg;
  final double size;
  final int z;
  const _PlanetDef(
    this.name, {
    required this.lonDeg,
    required this.size,
    required this.z,
  });
}

class _AltarLayout {
  final double left;
  final double top;
  final double width;
  final double height;
  final double cx;
  final double cy;
  final double rx;
  final double ry;
  const _AltarLayout({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.cx,
    required this.cy,
    required this.rx,
    required this.ry,
  });
}

