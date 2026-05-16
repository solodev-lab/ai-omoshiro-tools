import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/galaxy_cycle.dart';
import '../../utils/constellation_namer.dart';
import '../../utils/pro_status.dart';
import '../../widgets/constellation_painter.dart';
import '../horoscope/horo_antique_icons.dart';
import 'galaxy_archive_filter.dart';

// ══════════════════════════════════════════════════════════════════════════
// STAR ATLAS TAB
// HTML: galaxy.html L461-470 (#panel-atlas > .atlas-content)
// CSS:  galaxy.html L231-267 + shared/styles.css .screen-h1/h2/.glass
// JS:   galaxy.html L1710-1736 (renderGalaxyCards)
// ══════════════════════════════════════════════════════════════════════════

/// STAR ATLAS タブ本体。HTML の `.atlas-content` と中のグリッドを描画する。
/// `.stella-msg` は親 (galaxy_screen.dart) 側で描画されるためここには含めない。
///
/// C2/C5 (柱 3) 統合:
///   - 上部に [GalaxyArchiveFilterBar] (検索/レアリティ/ソート、Pro 限定)
///   - カード長押しで [onLongPressCard] を呼ぶ (親側で形成演出再生 + エクスポート
///     メニューを開く、いずれも Pro 機能)
class GalaxyStarAtlasTab extends StatefulWidget {
  final List<GalaxyCycle> completedCycles;
  final Map<int, ui.Image> artImages;
  final ValueChanged<GalaxyCycle> onOpenReplay;

  /// カードを長押しした時に呼ばれる (省略可)。Pro 機能メニューの起点。
  final ValueChanged<GalaxyCycle>? onLongPressCard;

  const GalaxyStarAtlasTab({
    super.key,
    required this.completedCycles,
    required this.artImages,
    required this.onOpenReplay,
    this.onLongPressCard,
  });

  @override
  State<GalaxyStarAtlasTab> createState() => _GalaxyStarAtlasTabState();
}

class _GalaxyStarAtlasTabState extends State<GalaxyStarAtlasTab> {
  GalaxyArchiveFilter _filter = const GalaxyArchiveFilter();

  @override
  void initState() {
    super.initState();
    ProStatus.instance.addListener(_onProChanged);
  }

  @override
  void dispose() {
    ProStatus.instance.removeListener(_onProChanged);
    super.dispose();
  }

  void _onProChanged() {
    if (!mounted) return;
    // Free に降格された時はフィルタを初期状態に戻して結果が消えないようにする
    // (柱 3 原則: Free の記録閲覧を阻害しない)。
    if (!ProStatus.instance.isPro && _filter.isActive) {
      setState(() => _filter = const GalaxyArchiveFilter());
    } else {
      setState(() {}); // バー UI の文言を切替させる
    }
  }

  @override
  Widget build(BuildContext context) {
    // 空状態: HTMLにはグリッド空の状態は明示されていないので、案内のみ出す。
    if (widget.completedCycles.isEmpty) {
      return _EmptyState();
    }

    final isPro = ProStatus.instance.isPro;
    // completedCycles は呼出側で「古い順」のことが多いため、Filter 内で
    // sort を再適用してから表示する。
    final visible = _filter.apply(widget.completedCycles);

    const double hPad = 16;
    const double bPad = 16;
    const double headerInset = 4;
    const double gap = 12;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(hPad + headerInset, 0, hPad + headerInset, 0),
          sliver: const SliverToBoxAdapter(child: _AtlasHeader()),
        ),
        // ─── Filter Bar (C2 Pro) ────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
          sliver: SliverToBoxAdapter(
            child: GalaxyArchiveFilterBar(
              filter: _filter,
              isPro: isPro,
              onChanged: (f) => setState(() => _filter = f),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: gap)),

        // ─── Result count notice (絞込結果) ─────────────────────────────────
        if (_filter.isActive)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(hPad + 4, 0, hPad, 6),
            sliver: SliverToBoxAdapter(
              child: Text(
                '${visible.length} 件 / 全 ${widget.completedCycles.length} 件',
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  color: Color(0xFF999999),
                  fontSize: 11,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),

        // ─── Constellation Grid ─────────────────────────────────────────────
        if (visible.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(hPad, 16, hPad, bPad),
            sliver: const SliverToBoxAdapter(child: _NoMatchState()),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(hPad, 0, hPad, bPad),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final cycle = visible[index];
                  return _ConstellationCard(
                    cycle: cycle,
                    artImage: widget.artImages[cycle.nounIdx],
                    onTap: () => widget.onOpenReplay(cycle),
                    onLongPress: widget.onLongPressCard != null
                        ? () => widget.onLongPressCard!(cycle)
                        : null,
                  );
                },
                childCount: visible.length,
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
      children: [
        Text(
          'Star Atlas',
          style: GoogleFonts.cinzel(
            fontSize: 24, fontWeight: FontWeight.w700,
            color: const Color(0xFFEAEAEA), height: 1.0,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your completed cosmic cycles',
          style: GoogleFonts.cinzel(
            fontSize: 12, fontWeight: FontWeight.w400,
            color: const Color(0xFFACACAC), letterSpacing: 1.5,
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
  final VoidCallback? onLongPress;

  const _ConstellationCard({
    required this.cycle,
    required this.artImage,
    required this.onTap,
    this.onLongPress,
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

    // (shapeType 変数は UI 表示を削除したため除去済み)
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
      onLongPress: onLongPress,
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

            // 星座名 — 端末言語でEN/JP切替 (日本語=JP、それ以外=EN)
            // maxLines:2 で長い名前は "形容詞 / 名詞" に折り返し
            const SizedBox(height: 4),
            Builder(builder: (ctx) {
              final isJP = Localizations.localeOf(ctx).languageCode == 'ja';
              // 既存データの "The " プレフィックスは表示時に除去 (後方互換)
              final rawName = isJP && cycle.nameJP.isNotEmpty
                  ? cycle.nameJP : cycle.nameEN;
              final name = rawName.startsWith('The ')
                  ? rawName.substring(4) : rawName;
              return Text(
                name,
                style: isJP
                  ? const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: Color(0xFFEAEAEA), height: 1.2)
                  : GoogleFonts.cinzel(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: const Color(0xFFEAEAEA),
                      height: 1.2, letterSpacing: 1.2),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              );
            }),
            // Meta line 1: stars · anchors — 名称との間を広めに
            const SizedBox(height: 7),
            Text(
              '${cycle.dots.length} stars · $anchorCount anchors',
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFFB8B8B8),
                letterSpacing: 0.5,
                height: 1.0, // meta2 に近づけるため詰める
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            // Meta line 2: rarityLabel + star rating — meta1 にピッタリ寄せる
            const SizedBox(height: 1),
            Text(
              '${cycle.rarityLabel}  $rarityText',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: starColor,
                letterSpacing: 1.2,
                height: 1.1,
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
// NO MATCH STATE (フィルタ結果 0 件)
// ══════════════════════════════════════════════════════════════════════════

class _NoMatchState extends StatelessWidget {
  const _NoMatchState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Center(
        child: Text(
          '条件に合うサイクルはありません',
          style: GoogleFonts.cinzel(
            color: const Color(0xFFACACAC),
            fontSize: 13,
            letterSpacing: 1.0,
          ),
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
            AntiqueGlyph(
              icon: AntiqueIcon.pattern, size: 56,
              color: const Color(0xFFF9D976).withAlpha(100),
              glow: false,
            ),
            const SizedBox(height: 16),
            Text(
              'Star Atlas',
              style: GoogleFonts.cinzel(
                color: const Color(0xFFEAEAEA),
                fontSize: 24, fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
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
