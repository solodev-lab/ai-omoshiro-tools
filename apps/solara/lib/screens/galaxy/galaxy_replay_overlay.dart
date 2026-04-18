import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/galaxy_cycle.dart';
import '../../utils/constellation_namer.dart';
import '../../widgets/constellation_painter.dart';

// ══════════════════════════════════════════════════
// Replay Overlay
// HTML: #replayModal — catasterism (刻星化) camera animation
// Phase 1: Camera 55°→0° (0-3s)
// Phase 2: Line connections (3-4.5s)
// Phase 3: Name + rarity fade-in (4.5-6.5s)
// ══════════════════════════════════════════════════

class GalaxyReplayOverlay extends StatelessWidget {
  final GalaxyCycle cycle;
  final AnimationController controller;
  final ui.Image? artImage;
  final VoidCallback onClose;

  const GalaxyReplayOverlay({
    super.key,
    required this.cycle,
    required this.controller,
    required this.artImage,
    required this.onClose,
  });

  static const double _cameraAngle55 = 55 * pi / 180; // ~0.96 rad

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: const Color(0xF5020408), // rgba(2,4,10,0.96)
        child: Center(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final t = controller.value;
              final cameraT = (t / 0.46).clamp(0.0, 1.0);
              final easedCamera = Curves.easeInOutCubic.transform(cameraT);
              final cameraAngle = _cameraAngle55 * (1.0 - easedCamera);
              final lineT = ((t - 0.46) / 0.23).clamp(0.0, 1.0);
              final fadeT = ((t - 0.69) / 0.31).clamp(0.0, 1.0);
              final painterProgress = cameraT * 0.4 + lineT * 0.6;

              return SizedBox(
                width: 340,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // replay title — 端末言語でEN or JP を1つだけ表示
                  Opacity(opacity: fadeT, child: Builder(builder: (ctx) {
                    final isJP = Localizations.localeOf(ctx).languageCode == 'ja';
                    final rawName = isJP && cycle.nameJP.isNotEmpty
                        ? cycle.nameJP : cycle.nameEN;
                    final name = rawName.startsWith('The ')
                        ? rawName.substring(4) : rawName;
                    return Text(
                      name,
                      style: isJP
                        ? const TextStyle(
                            color: Color(0xFFEAEAEA), fontSize: 22,
                            fontWeight: FontWeight.w600, letterSpacing: 2)
                        : GoogleFonts.cinzel(
                            color: const Color(0xFFEAEAEA), fontSize: 22,
                            fontWeight: FontWeight.w700, letterSpacing: 2.5),
                      textAlign: TextAlign.center,
                    );
                  })),
                  const SizedBox(height: 20),
                  // HTML: #replayCanvas
                  Container(
                    width: 300, height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xCC060A12),
                      border: Border.all(color: const Color(0x1AFFFFFF)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CustomPaint(
                        painter: ConstellationPainter(
                          cycle: cycle, progress: painterProgress, cameraAngle: cameraAngle,
                          artImage: artImage,
                          flipX: ConstellationNamer.isFlipX(cycle.nounIdx)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // サブ情報 — Cinzelで統一 (大きめサイズ)
                  Opacity(opacity: fadeT, child: Column(children: [
                    Text('${cycle.dots.length} stars · ${cycle.dots.where((d) => d.isMajor).length} anchors',
                      style: GoogleFonts.cinzel(
                        fontSize: 16, color: const Color(0xFFCCCCCC),
                        letterSpacing: 1.5, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(cycle.rarityLabel, style: GoogleFonts.cinzel(
                        fontSize: 18, color: const Color(0xFFEAEAEA),
                        letterSpacing: 2.2, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      Text('${'★' * cycle.rarity}${'☆' * (5 - cycle.rarity)}',
                        style: TextStyle(fontSize: 18, letterSpacing: 2.5,
                          color: cycle.rarity >= 4 ? const Color(0xFFF9D976)
                              : cycle.rarity >= 3 ? const Color(0xFFB080FF) : const Color(0xFF888888))),
                    ]),
                    const SizedBox(height: 10),
                    Text(cycle.dateRangeLabel, style: GoogleFonts.cinzel(
                      fontSize: 15, color: const Color(0xFFCCCCCC),
                      letterSpacing: 1.3, fontWeight: FontWeight.w600)),
                  ])),
                  const SizedBox(height: 24),
                  // Close ボタン
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x33FFFFFF)),
                      ),
                      child: Text('← Back to Star Atlas', style: GoogleFonts.cinzel(
                        fontSize: 12, color: const Color(0xFFACACAC),
                        letterSpacing: 1.8, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ]),
              );
            },
          ),
        ),
      ),
    );
  }
}
