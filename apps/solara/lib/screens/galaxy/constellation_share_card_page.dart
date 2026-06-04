// 星座カード共有画面 — Free 機能 (柱 3 看板)
//
// 設計: apps/solara/docs/pro_candidates.md §7.3 + class_share_card.dart のパターン踏襲
//
// 用途:
//   - 刻星化 (CatasterismFormationOverlay) 完了時に「共有」ボタンから起動
//   - Star Atlas カードの ⋯ メニューからも将来的に呼べる
//   - 縦長 1080×1920 (9:16) でレンダリング、OS 標準シェアシートで PNG を共有
//
// 設計原則 (class_share_card と統一):
//   - textScaler 1.0 固定で端末フォントサイズの影響を受けない
//   - 設計論理サイズ 360×640 で FittedBox スケール = 表示サイズ設定に不変
//   - pixelRatio = 1080 / boundary.size.width で動的計算 = 常に 1080 幅出力
//
// 思想ガード:
//   - 「吉凶判定しない」(design_philosophy) → レアリティの星 5 つを冗長な
//     "Common/Rare" 名称なしで表示 (Star Atlas カードと同方針 2026-05-17)

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../i18n/strings.g.dart';
import '../../models/galaxy_cycle.dart';
import '../../utils/constellation_namer.dart';
import '../../utils/solara_i18n.dart';
import '../../widgets/constellation_painter.dart';

const double _kTargetWidthPx = 1080.0;

class ConstellationShareCardPage extends StatefulWidget {
  final GalaxyCycle cycle;
  final ui.Image? artImage;

  /// 形成演出と同じ神殿/星雲の背景画像。非 null のとき共有カードに敷く。
  /// 形成演出からの共有 = 背景あり / 通常再生からの共有 = null で背景なし。
  final ui.Image? bgImage;

  const ConstellationShareCardPage({
    super.key,
    required this.cycle,
    this.artImage,
    this.bgImage,
  });

  @override
  State<ConstellationShareCardPage> createState() =>
      _ConstellationShareCardPageState();
}

class _ConstellationShareCardPageState
    extends State<ConstellationShareCardPage> {
  final GlobalKey _captureKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw 'capture target not found';

      final boundaryWidth = boundary.size.width;
      final pixelRatio =
          boundaryWidth > 0 ? _kTargetWidthPx / boundaryWidth : 3.0;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw 'byteData null';

      final tmpDir = await getTemporaryDirectory();
      final file = await File('${tmpDir.path}/solara_constellation.png').create();
      await file.writeAsBytes(byteData.buffer.asUint8List());

      final rawName = isEnLocale()
          ? widget.cycle.nameEN
          : (widget.cycle.nameJP.isNotEmpty
              ? widget.cycle.nameJP
              : widget.cycle.nameEN);
      final name =
          rawName.startsWith('The ') ? rawName.substring(4) : rawName;
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: t.shareConstellation.shareText(name: name),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.shareConstellation.shareFailed(e: e))),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFEAEAEA)),
        title: Text(t.shareConstellation.appBarTitle,
            style: const TextStyle(color: Color(0xFFEAEAEA))),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: RepaintBoundary(
                      key: _captureKey,
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: const TextScaler.linear(1.0),
                        ),
                        child: _buildShareImage(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: GestureDetector(
                onTap: _sharing ? null : _share,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF9D976), Color(0xFFE8A840)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF9D976).withValues(alpha: 0.25),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _sharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF0A0A14),
                            ),
                          )
                        : Text(
                            t.shareConstellation.shareButton,
                            style: const TextStyle(
                              color: Color(0xFF0A0A14),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// シェア画像本体 — 9:16 縦長、設計論理 360×640 を FittedBox でスケール。
  Widget _buildShareImage() {
    const double designW = 360.0;
    const double designH = 640.0;

    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: designW,
        height: designH,
        child: _buildShareImageInner(designW, designH),
      ),
    );
  }

  Widget _buildShareImageInner(double w, double h) {
    final cycle = widget.cycle;
    final accent = const Color(0xFFF9D976);
    final readable = accent.withValues(alpha: 0.88);

    final paddingH = w * 0.06;
    final paddingV = w * 0.05;

    final usableH = h - paddingV * 2;
    final topH = usableH * 0.18;
    final canvasAreaH = usableH * 0.50;
    final bottomH = usableH * 0.32;

    final fsHeader = w * 0.045;
    final fsSubtitle = w * 0.028;
    final fsNameJP = w * 0.080;
    final fsNameEN = w * 0.040;
    final fsMeta = w * 0.034;

    final canvasSide = canvasAreaH.clamp(120.0, w * 0.86);
    final displayJP =
        cycle.nameJP.isNotEmpty ? cycle.nameJP : cycle.nameEN;
    final rawEN = cycle.nameEN.startsWith('The ')
        ? cycle.nameEN.substring(4)
        : cycle.nameEN;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F1A36), Color(0xFF050811)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 形成演出からの共有: 神殿/星雲の背景を敷く (背景あり版)。
            if (widget.bgImage != null) ...[
              Positioned.fill(
                child: RawImage(image: widget.bgImage, fit: BoxFit.cover),
              ),
              // 名前/レアリティの可読性のため上下を暗くする。
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: const [
                        Color(0xD9050811),
                        Color(0x4D050811),
                        Color(0xE6050811),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ],
            // 背景: 星屑 (画面全体に薄く敷くゴールドのグレア)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.3),
                    radius: 0.9,
                    colors: [
                      const Color(0xFFF9D976).withValues(alpha: 0.10),
                      const Color(0x00000000),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
              child: Column(
                children: [
                  // ── 上段: SOLARA + Your Constellation ──
                  SizedBox(
                    height: topH,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'S O L A R A',
                          style: TextStyle(
                            color: readable,
                            fontSize: fsHeader,
                            letterSpacing: 7,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        SizedBox(height: w * 0.012),
                        Text(
                          '— Your Constellation —',
                          style: TextStyle(
                            color: readable.withValues(alpha: 0.70),
                            fontSize: fsSubtitle,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── 中央: 星座本体 (ConstellationPainter progress=1.0) ──
                  SizedBox(
                    height: canvasAreaH,
                    child: Center(
                      child: SizedBox(
                        width: canvasSide,
                        height: canvasSide,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0x99060A12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0x33F9D976), width: 1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CustomPaint(
                              painter: ConstellationPainter(
                                cycle: cycle,
                                progress: 1.0,
                                cameraAngle: 0,
                                artImage: widget.artImage,
                                flipX: ConstellationNamer.isFlipX(
                                    cycle.nounIdx),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ── 下段: 星座名 + 星 + 日付 ──
                  // EN ロケールは英名のみを主役に (日本語名/副題は非表示)。
                  // 月の儀式オーバーレイと同じ「EN主・JP非表示」方針 (英語化Phase 2)。
                  SizedBox(
                    height: bottomH,
                    child: Column(
                      children: [
                        if (isEnLocale())
                          Text(
                            rawEN,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cinzel(
                              color: const Color(0xFFEAEAEA),
                              fontSize: fsNameJP * 0.92,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        else ...[
                          Text(
                            displayJP,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFFEAEAEA),
                              fontSize: fsNameJP,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: w * 0.008),
                          Text(
                            rawEN,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cinzel(
                              color: readable.withValues(alpha: 0.85),
                              fontSize: fsNameEN,
                              letterSpacing: 2.5,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        SizedBox(height: w * 0.030),
                        // 星 5 つ Icon ベース (Star Atlas カードと統一、textScaler 不変)
                        _ShareCardRarityStars(rarity: cycle.rarity, size: w * 0.048),
                        SizedBox(height: w * 0.024),
                        Text(
                          cycle.dateRangeLabel,
                          style: TextStyle(
                            color: readable.withValues(alpha: 0.70),
                            fontSize: fsMeta,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareCardRarityStars extends StatelessWidget {
  final int rarity;
  final double size;
  const _ShareCardRarityStars({required this.rarity, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = rarity >= 4
        ? const Color(0xFFF9D976)
        : rarity >= 3
            ? const Color(0xFFB080FF)
            : const Color(0xFFBFBFBF);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 5; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.05),
            child: Icon(
              i < rarity ? Icons.star_rounded : Icons.star_border_rounded,
              size: size,
              color:
                  i < rarity ? color : color.withValues(alpha: 0.28),
            ),
          ),
      ],
    );
  }
}
