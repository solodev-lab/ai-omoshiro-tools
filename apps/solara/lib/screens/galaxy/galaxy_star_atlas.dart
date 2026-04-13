import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../models/galaxy_cycle.dart';
import '../../utils/constellation_namer.dart';
import '../../widgets/constellation_painter.dart';

// ══════════════════════════════════════════════════
// Star Atlas Tab
// HTML: .atlas-content
// ══════════════════════════════════════════════════

class GalaxyStarAtlasTab extends StatelessWidget {
  final List<GalaxyCycle> completedCycles;
  final Map<int, ui.Image> artImages;
  final ValueChanged<GalaxyCycle> onOpenReplay;

  const GalaxyStarAtlasTab({
    super.key,
    required this.completedCycles,
    required this.artImages,
    required this.onOpenReplay,
  });

  @override
  Widget build(BuildContext context) {
    if (completedCycles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('✦', style: TextStyle(fontSize: 48, color: const Color(0xFFF9D976).withAlpha(77))),
            const SizedBox(height: 16),
            const Text('Star Atlas', style: TextStyle(
              color: Color(0xFFEAEAEA), fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Complete a lunar cycle to form\nyour first constellation.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFACACAC), fontSize: 13, height: 1.5)),
          ]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(children: [
        // HTML: .screen-h1 "Star Atlas" + .screen-h2 "Your completed cosmic cycles"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('Star Atlas', style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFFEAEAEA))),
            SizedBox(height: 4),
            Text('Your completed cosmic cycles', style: TextStyle(
              fontSize: 13, color: Color(0xFFACACAC))),
          ]),
        ),
        const SizedBox(height: 12),
        // HTML: .constellation-grid { display:grid; grid-template-columns:repeat(auto-fill, minmax(160px, 1fr)); gap:12px; }
        Expanded(child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180, crossAxisSpacing: 12, mainAxisSpacing: 12,
            childAspectRatio: 0.62,
          ),
          itemCount: completedCycles.length,
          itemBuilder: (context, index) {
            final cycle = completedCycles[completedCycles.length - 1 - index];
            return _buildConstellationCard(cycle);
          },
        )),
      ]),
    );
  }

  // HTML: .const-card { border-radius:20px; padding:14px; aspect-ratio:0.75; }
  Widget _buildConstellationCard(GalaxyCycle cycle) {
    final adjColor = ConstellationNamer.adjColor(cycle.adjIdx);
    final anchorCount = cycle.dots.where((d) => d.isMajor).length;
    final starColor = cycle.rarity >= 4 ? const Color(0xFFF9D976)
        : cycle.rarity >= 3 ? const Color(0xFFB080FF) : const Color(0xFF888888);
    final starsText = '${'★' * cycle.rarity}${'☆' * (5 - cycle.rarity)}';

    return GestureDetector(
      onTap: () => onOpenReplay(cycle),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [adjColor.withAlpha((0.12 * 255).round()), adjColor.withAlpha((0.03 * 255).round())],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: adjColor.withAlpha((0.25 * 255).round())),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Center(child: CustomPaint(
            painter: MiniConstellationPainter(
              cycle: cycle,
              artImage: artImages[cycle.nounIdx],
              flipX: ConstellationNamer.isFlipX(cycle.nounIdx),
            ),
            size: const Size(80, 80),
          ))),
          const SizedBox(height: 6),
          // 日付
          Text(cycle.dateRangeLabel, style: const TextStyle(fontSize: 9, color: Color(0xFFACACAC)),
            overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          // 名前
          Text(cycle.nameEN, style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFEAEAEA)),
            overflow: TextOverflow.ellipsis, maxLines: 1),
          if (cycle.nameJP.isNotEmpty)
            Text(cycle.nameJP, style: const TextStyle(fontSize: 10, color: Color(0xFFACACAC)),
              overflow: TextOverflow.ellipsis, maxLines: 1),
          const SizedBox(height: 2),
          // レアリティ + メタ
          Text(starsText, style: TextStyle(fontSize: 9, color: starColor, letterSpacing: 1)),
          Text('${cycle.dots.length} stars · $anchorCount anchors',
            style: const TextStyle(fontSize: 9, color: Color(0x99ACACAC)),
            overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}
