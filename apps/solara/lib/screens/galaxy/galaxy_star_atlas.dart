import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../models/galaxy_cycle.dart';
import '../../utils/constellation_namer.dart';
import '../../widgets/constellation_painter.dart';

// ══════════════════════════════════════════════════════════════════════════
// STAR ATLAS TAB
// HTML: galaxy.html L461-470 (#panel-atlas > .atlas-content)
// CSS:  galaxy.html L231-267 + shared/styles.css .screen-h1/h2/.glass
// JS:   galaxy.html L1710-1736 (renderGalaxyCards)
// ══════════════════════════════════════════════════════════════════════════

/// STAR ATLAS タブ本体。HTML の `.atlas-content` と中のグリッドを描画する。
/// `.stella-msg` は親 (galaxy_screen.dart) 側で描画されるためここには含めない。
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
    // 空状態: HTMLにはグリッド空の状態は明示されていないので、案内のみ出す。
    if (completedCycles.isEmpty) {
      return _EmptyState();
    }

    // HTML: .atlas-content { padding: 0 16px 100px; gap:20px; overflow-y:auto; }
    // ※bottom:100px は Stella + Bottom Nav のぶんを予約。
    // Stella は親側で別途描画されるので、ここは単にその 100px を空けるだけ。
    // (Flutter側では親Column末尾にStellaが追加されるため、100pxは過剰になる。)
    // → HTMLと等価に保つため、ここでは bottom:16px (atlas-contentの内側余白) にとどめ、
    //   残り 84px (= Stella分) は親側でStellaを配置することで確保する。
    const double hPad = 16; // .atlas-content horizontal padding
    const double bPad = 16; // 下余白 (Stella は親側)
    const double headerInset = 4; // ヘッダーdivのインラインstyle: padding:0 4px
    const double gap = 20; // .atlas-content gap

    return CustomScrollView(
      // HTML: .atlas-content::-webkit-scrollbar { display:none; }
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ─── Header ────────────────────────────────────────────────────────
        // HTML: <div style="padding:0 4px;"> screen-h1 / screen-h2 </div>
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(hPad + headerInset, 0, hPad + headerInset, 0),
          sliver: const SliverToBoxAdapter(child: _AtlasHeader()),
        ),
        // HTML: .atlas-content gap:20px (ヘッダーとグリッドの間)
        const SliverToBoxAdapter(child: SizedBox(height: gap)),

        // ─── Constellation Grid ────────────────────────────────────────────
        // HTML: .constellation-grid {
        //   display:grid;
        //   grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
        //   gap: 12px;
        // }
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(hPad, 0, hPad, bPad),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200, // minmax(160px, 1fr) を近似
              crossAxisSpacing: 12, // HTML: gap:12px
              mainAxisSpacing: 12,
              childAspectRatio: 0.75, // HTML: .const-card { aspect-ratio: 0.75 }
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final cycle = completedCycles[completedCycles.length - 1 - index];
                return _ConstellationCard(
                  cycle: cycle,
                  artImage: artImages[cycle.nounIdx],
                  onTap: () => onOpenReplay(cycle),
                );
              },
              childCount: completedCycles.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// HEADER — .screen-h1 / .screen-h2
// shared/styles.css L311-312
// ══════════════════════════════════════════════════════════════════════════

class _AtlasHeader extends StatelessWidget {
  const _AtlasHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        // HTML: .screen-h1 { font-size:24px; font-weight:700; color:#EAEAEA; font-family:Libre Caslon Text }
        Text(
          'Star Atlas',
          style: TextStyle(
            fontFamily: 'LibreCaslonText',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFFEAEAEA),
            height: 1.0,
          ),
        ),
        // HTML: .screen-h2 { font-size:13px; font-weight:300; color:#ACACAC; margin-top:4px; font-family:DM Sans }
        SizedBox(height: 4),
        Text(
          'Your completed cosmic cycles',
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 13,
            fontWeight: FontWeight.w300,
            color: Color(0xFFACACAC),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// CARD — .const-card
// HTML: L247-266 + JS L1713-1735
// ══════════════════════════════════════════════════════════════════════════

class _ConstellationCard extends StatelessWidget {
  final GalaxyCycle cycle;
  final ui.Image? artImage;
  final VoidCallback onTap;

  const _ConstellationCard({
    required this.cycle,
    required this.artImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // HTML: const baseColor = adjColors[cycle.adjIdx];
    //       const lightBase = lightenHex(baseColor, 0.5);  // 白方向に50%
    final baseColor = ConstellationNamer.adjColor(cycle.adjIdx);
    final lightBase = Color.lerp(baseColor, Colors.white, 0.5) ?? baseColor;

    // HTML JS L1141-1142:
    //   cardBgGrad: [lightBase@0.08, lightBase@0.03]
    //   cardBorder: lightBase@0.30
    final bgTop = lightBase.withAlpha((0.08 * 255).round());
    final bgBottom = lightBase.withAlpha((0.03 * 255).round());
    final borderColor = lightBase.withAlpha((0.30 * 255).round());

    // HTML: NOUN_SHAPES[nounIdx] (shape type label)
    final shapeType = (cycle.nounIdx >= 0 && cycle.nounIdx < ConstellationNamer.nounShapes.length)
        ? ConstellationNamer.nounShapes[cycle.nounIdx]
        : 'open';

    // HTML: rarityStarsHTML(cycle.stars) — color by rarity
    final rarity = cycle.rarity;
    final starColor = rarity >= 4
        ? const Color(0xFFF9D976)
        : rarity >= 3
            ? const Color(0xFFB080FF)
            : const Color(0xFF888888);
    final rarityText = '${'★' * rarity}${'☆' * (5 - rarity)}';

    // HTML: anchors = dots.filter(d => d.isMajor).length
    final anchorCount = cycle.dots.where((d) => d.isMajor).length;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        // HTML: .const-card { border-radius:20px; padding:14px; }
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          // HTML: background: linear-gradient(135deg, cardBgGrad[0], cardBgGrad[1]);
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgTop, bgBottom],
          ),
          borderRadius: BorderRadius.circular(20),
          // HTML: border: 1px solid cardBorder;
          border: Border.all(color: borderColor, width: 1),
        ),
        // HTML: flex-direction:column; justify-content:space-between;
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HTML: .const-mini { flex:1; display:flex; align-items:center; justify-content:center; }
            //       <canvas width=80 height=80 style="border-radius:10px">
            Expanded(
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: CustomPaint(
                      painter: MiniConstellationPainter(
                        cycle: cycle,
                        artImage: artImage,
                        flipX: ConstellationNamer.isFlipX(cycle.nounIdx),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ─── Meta block (HTML JS L1724-1731) ───────────────────────────
            // 行1: shape label (左) + rarity stars (右)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // HTML: .const-date { font-size:10px; color:#ACACAC; }
                // 実際はshapeTypeラベルを表示 (L1726)
                Flexible(
                  child: Text(
                    shapeType,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 10,
                      color: Color(0xFFACACAC),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // HTML: rarityStarsHTML(cycle.stars)
                Text(
                  rarityText,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 10,
                    color: starColor,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            // 行2: nameEN (.const-seed) — margin-top:2px
            const SizedBox(height: 2),
            Text(
              cycle.nameEN,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFEAEAEA),
                height: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            // 行3: nameJP — font-size:11px; color:#ACACAC
            if (cycle.nameJP.isNotEmpty)
              Text(
                cycle.nameJP,
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 11,
                  color: Color(0xFFACACAC),
                  height: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            // 行4: "X stars · Y anchors · rarityLabel"
            // HTML: font-size:10px; color:rgba(172,172,172,0.6); margin-top:2px
            const SizedBox(height: 2),
            Text(
              '${cycle.dots.length} stars · $anchorCount anchors · ${cycle.rarityLabel}',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 10,
                color: const Color(0xFFACACAC).withAlpha((0.6 * 255).round()),
                height: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ══════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✦',
                style: TextStyle(
                  fontSize: 48,
                  color: const Color(0xFFF9D976).withAlpha(77),
                )),
            const SizedBox(height: 16),
            const Text(
              'Star Atlas',
              style: TextStyle(
                fontFamily: 'LibreCaslonText',
                color: Color(0xFFEAEAEA),
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete a lunar cycle to form\nyour first constellation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DMSans',
                color: Color(0xFFACACAC),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
