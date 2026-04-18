import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/galaxy_cycle.dart';
import '../theme/solara_colors.dart';
import '../utils/constellation_namer.dart';

// 12星座シンボル画像のファイル名 (assets/zodiac-symbols/*.webp)
const _zodiacFiles = [
  'aries', 'taurus', 'gemini', 'cancer',
  'leo', 'virgo', 'libra', 'scorpio',
  'sagittarius', 'capricorn', 'aquarius', 'pisces',
];

/// 刻星化 (Catasterism) 完了演出オーバーレイ
///
/// SPEC.md準拠: 8秒4ステージ
/// - 0.00-0.25 (0-2s): CONVERGENCE — Field星fade-in
/// - 0.25-0.375 (2-3s): IGNITION — Anchor星点灯
/// - 0.375-0.625 (3-5s): LINKING — MST edges描画進行 (ConstellationPainterは progress/0.6 で展開)
/// - 0.625-1.00 (5-8s): COMPLETE — 全体表示+名前+ボタン
class CatasterismFormationOverlay extends StatefulWidget {
  final GalaxyCycle cycle;
  final ui.Image? artImage;
  final VoidCallback onComplete;

  const CatasterismFormationOverlay({
    super.key,
    required this.cycle,
    this.artImage,
    required this.onComplete,
  });

  @override
  State<CatasterismFormationOverlay> createState() =>
      _CatasterismFormationOverlayState();
}

class _CatasterismFormationOverlayState
    extends State<CatasterismFormationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _fadeController;
  // 12星座シンボル画像 (preload)
  final List<ui.Image?> _zodiacImages = List.filled(12, null);
  ui.Image? _bgImage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..forward();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _preloadZodiacImages();
    _loadBgImage();
  }

  Future<void> _loadBgImage() async {
    try {
      final data = await rootBundle.load('assets/catasterism_bg.webp');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (mounted) setState(() => _bgImage = frame.image);
    } catch (_) {}
  }

  Future<void> _preloadZodiacImages() async {
    for (int i = 0; i < _zodiacFiles.length; i++) {
      try {
        final data = await rootBundle.load('assets/zodiac-symbols/${_zodiacFiles[i]}.webp');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        if (mounted) {
          setState(() => _zodiacImages[i] = frame.image);
        }
      } catch (_) {
        // 画像が無くてもクラッシュさせない (Unicode fallback)
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String _stageLabel(double p) {
    if (p < 0.25) return 'CONVERGENCE';
    if (p < 0.375) return 'IGNITION';
    if (p < 0.625) return 'LINKING';
    return 'COMPLETE';
  }

  String _stageLabelJP(double p) {
    if (p < 0.25) return '\u96c6\u6765'; // 集来
    if (p < 0.375) return '\u70b9\u706f'; // 点灯
    if (p < 0.625) return '\u9023\u7d50'; // 連結
    return '\u5b8c\u6210'; // 完成
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
      child: Container(
        color: const Color(0xFF040810),
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final p = _controller.value;
              final isComplete = p >= 0.625;
              final isFinished = p >= 0.99;
              return Stack(
                children: [
                  // Top: Catasterism title
                  Positioned(
                    top: 24,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        const Text(
                          '\u2728 Catasterism',
                          style: TextStyle(
                            color: SolaraColors.solaraGold,
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '\u523b\u661f\u5316', // 刻星化
                          style: TextStyle(
                            color: SolaraColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Constellation animation — 画面全体に描画（グローがクリップされないように）
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _FormationPainter(
                        cycle: widget.cycle,
                        progress: p,
                        artImage: widget.artImage,
                        bgImage: _bgImage,
                        zodiacImages: _zodiacImages,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  // Stage label (above constellation)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.18,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          '\u2737 ${_stageLabel(p)}',
                          key: ValueKey(_stageLabel(p)),
                          style: const TextStyle(
                            color: SolaraColors.solaraGold,
                            fontSize: 14,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.18 + 22,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          _stageLabelJP(p),
                          key: ValueKey(_stageLabelJP(p)),
                          style: const TextStyle(
                            color: SolaraColors.textSecondary,
                            fontSize: 11,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Cycle info (bottom, fade in at COMPLETE)
                  Positioned(
                    bottom: 96,
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 600),
                      opacity: isComplete ? 1.0 : 0.0,
                      child: Column(
                        children: [
                          Text(
                            widget.cycle.nameEN.startsWith('The ')
                              ? widget.cycle.nameEN.substring(4)
                              : widget.cycle.nameEN,
                            style: const TextStyle(
                              color: SolaraColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.cycle.nameJP,
                            style: const TextStyle(
                              color: SolaraColors.solaraGold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${'\u2605' * widget.cycle.rarity}${'\u2606' * (5 - widget.cycle.rarity)}  \u00b7  ${widget.cycle.rarityLabel}',
                            style: const TextStyle(
                              color: SolaraColors.textSecondary,
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // "View in Star Atlas" button (fade in when finished)
                  Positioned(
                    bottom: 32,
                    left: 32,
                    right: 32,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 600),
                      opacity: isFinished ? 1.0 : 0.0,
                      child: GestureDetector(
                        onTap: isFinished ? widget.onComplete : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFF9D976),
                                Color(0xFFC4923A),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: SolaraColors.solaraGold
                                    .withAlpha((0.4 * 255).round()),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'View in Star Atlas \u2728',
                              style: TextStyle(
                                color: Color(0xFF1A0F00),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Skip button (top right, only during animation)
                  if (!isFinished)
                    Positioned(
                      top: 24,
                      right: 24,
                      child: TextButton(
                        onPressed: () => _controller
                            .animateTo(1.0, duration: Duration.zero),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: SolaraColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
          ], // Stack children
        ), // Stack
      ), // Container
    ); // FadeTransition
  }
}

/// 4ステージ専用Painter
/// - CONVERGENCE (0.000-0.250): 散らばった初期位置 → テンプレート位置へlerp
/// - IGNITION (0.250-0.375): 全星到着完了+白フラッシュ+Anchor glow boost
/// - LINKING (0.375-0.625): MST edges を1本ずつ順番描画
/// - COMPLETE (0.625-1.000): 星座絵フェードイン+全体表示
class _FormationPainter extends CustomPainter {
  final GalaxyCycle cycle;
  final double progress;
  final ui.Image? artImage;
  final ui.Image? bgImage;
  final List<ui.Image?> zodiacImages;

  // 各dot固定の初期散らばり位置 (cycle.id seed で決定論的)
  late final List<Offset> _initialNorm;

  _FormationPainter({
    required this.cycle,
    required this.progress,
    this.artImage,
    this.bgImage,
    required this.zodiacImages,
  }) {
    final rng = Random(cycle.id.hashCode);
    _initialNorm = List.generate(
      cycle.dots.length,
      (_) => Offset(
        0.05 + rng.nextDouble() * 0.9,
        0.05 + rng.nextDouble() * 0.9,
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (cycle.dots.isEmpty) return;

    final color = ConstellationNamer.adjColor(cycle.adjIdx);
    final glowColor = Colors.white.withAlpha((0.9 * 255).round());

    // ── 星座エリア: 画面中央の正方形 (padding 32px相当) ──
    final side = size.width - 64;
    final areaLeft = (size.width - side) / 2;
    final areaTop = (size.height - side) / 2;

    // 正規化座標(0-1) → 画面座標に変換するヘルパー
    Offset toScreen(double nx, double ny) =>
        Offset(areaLeft + nx * side, areaTop + ny * side);

    // ── ステージ別進捗 (各 0.0-1.0) ──
    final convergence = (progress / 0.25).clamp(0.0, 1.0);
    final ignition = ((progress - 0.25) / 0.125).clamp(0.0, 1.0);
    final linking = ((progress - 0.375) / 0.25).clamp(0.0, 1.0);
    final complete = ((progress - 0.625) / 0.375).clamp(0.0, 1.0);

    // ── 背景画像 (2秒目からフェードイン、最大50%) ──
    if (bgImage != null) {
      final bgAlpha = ((progress - 0.625) / 0.375).clamp(0.0, 1.0) * 0.25;
      if (bgAlpha > 0) {
        canvas.drawImageRect(
          bgImage!,
          Rect.fromLTWH(0, 0, bgImage!.width.toDouble(), bgImage!.height.toDouble()),
          Offset.zero & size,
          Paint()..color = Color.fromRGBO(255, 255, 255, bgAlpha),
        );
      }
    }

    // ── 星位置の補間 (CONVERGENCE中はlerp、それ以降は最終位置) ──
    final easedConv = Curves.easeInOut.transform(convergence);
    final positions = <Offset>[];
    for (int i = 0; i < cycle.dots.length; i++) {
      final dot = cycle.dots[i];
      final initial = toScreen(_initialNorm[i].dx, _initialNorm[i].dy);
      final target = toScreen(dot.x, dot.y);
      positions.add(Offset.lerp(initial, target, easedConv)!);
    }

    // ── 星座絵 (COMPLETE でフェードイン) — screen合成で黒を透明に ──
    // BlendMode.screen: 黒(0)→影響なし、白(1)→加算で明るく、中間色→鮮やかに残る
    if (artImage != null && complete > 0) {
      final artDst = Rect.fromLTWH(areaLeft, areaTop, side, side);
      canvas.drawImageRect(
        artImage!,
        Rect.fromLTWH(0, 0, artImage!.width.toDouble(), artImage!.height.toDouble()),
        artDst,
        Paint()
          ..blendMode = BlendMode.screen
          ..color = Color.fromRGBO(255, 255, 255, complete),
      );
    }

    final cx = size.width / 2;
    final cy = size.height / 2;

    // ── 背景radial gradient (IGNITION以降ほんのり) — 画面全体に広がる ──
    if (ignition > 0) {
      final bgGrad = ui.Gradient.radial(
        Offset(cx, cy),
        size.height * 0.6,
        [
          color.withAlpha((0.15 * ignition * 255).round()),
          color.withAlpha((0.02 * ignition * 255).round()),
        ],
      );
      canvas.drawRect(Offset.zero & size, Paint()..shader = bgGrad);
    }

    // ── IGNITION 演出: 中央から12本の放射状光線 — 画面全体に届く ──
    final ignitionPulse = ignition > 0 && ignition < 1
        ? sin(ignition * pi)
        : 0.0;
    if (ignitionPulse > 0) {
      final innerR = side * 0.18;
      final outerR = size.height * (0.35 + ignitionPulse * 0.25);
      for (int i = 0; i < 12; i++) {
        final ang = (i / 12) * 2 * pi + ignition * 0.6;
        final s = Offset(cx + innerR * cos(ang), cy + innerR * sin(ang));
        final e = Offset(cx + outerR * cos(ang), cy + outerR * sin(ang));
        canvas.drawLine(
          s, e,
          Paint()
            ..color = Colors.white.withAlpha((ignitionPulse * 0.7 * 255).round())
            ..strokeWidth = 1.2
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
      final centerGlow = ui.Gradient.radial(
        Offset(cx, cy),
        side * 0.3 * ignitionPulse,
        [
          const Color(0xFFF9D976).withAlpha((ignitionPulse * 0.7 * 255).round()),
          Colors.transparent,
        ],
      );
      canvas.drawCircle(
        Offset(cx, cy),
        side * 0.3 * ignitionPulse,
        Paint()..shader = centerGlow,
      );
    }

    // ── Field星 (Minor) 描画 ──
    for (int i = 0; i < cycle.dots.length; i++) {
      if (cycle.dots[i].isMajor) continue;
      final pos = positions[i];
      final alpha = (0.4 + 0.6 * convergence).clamp(0.0, 1.0);
      canvas.drawCircle(pos, 1.8,
          Paint()..color = color.withAlpha((alpha * 255).round()));
    }

    // ── MST edges (LINKING以降) ──
    if (linking > 0) {
      final anchorIndices = <int>[];
      final anchorPositions = <Offset>[];
      for (int i = 0; i < cycle.dots.length; i++) {
        if (cycle.dots[i].isMajor) {
          anchorIndices.add(i);
          anchorPositions.add(positions[i]);
        }
      }
      final shapeType = (cycle.nounIdx >= 0 &&
              cycle.nounIdx < ConstellationNamer.nounShapes.length)
          ? ConstellationNamer.nounShapes[cycle.nounIdx]
          : 'open';
      final edges = ConstellationNamer.buildEdges(anchorPositions, shapeType);
      // 1本ずつ順番描画 (linking進捗で本数決定)
      final drawCount = (edges.length * linking).ceil().clamp(0, edges.length);
      for (int i = 0; i < drawCount; i++) {
        final e = edges[i];
        if (e.from >= anchorPositions.length || e.to >= anchorPositions.length) continue;
        final a1 = anchorPositions[e.from];
        final a2 = anchorPositions[e.to];
        // Glow
        canvas.drawLine(a1, a2, Paint()
          ..color = glowColor
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
        // Main line
        canvas.drawLine(a1, a2, Paint()
          ..color = color
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
      }
    }

    // ── Anchor星 (Major) 描画 ──
    // IGNITION中は glow size と core size を増幅 (sin山形)
    final glowR = 12.0 + ignitionPulse * 8.0;
    final coreR = 4.5 + ignitionPulse * 2.0;
    for (int i = 0; i < cycle.dots.length; i++) {
      if (!cycle.dots[i].isMajor) continue;
      final pos = positions[i];
      // Glow (白ベース)
      final gg = ui.Gradient.radial(
        pos, glowR, [
          Colors.white,
          Colors.transparent,
        ],
      );
      canvas.drawCircle(pos, glowR, Paint()..shader = gg);
      // Core (属性色)
      canvas.drawCircle(pos, coreR, Paint()..color = color);
    }

    // ── 12星座記号リング: IGNITION〜LINKING通して表示 ──
    // 表示期間 progress 0.25-0.625 (1.5秒間) → fade-in 0.25-0.32 / hold / fade-out 0.55-0.625
    double zodiacAlpha = 0.0;
    if (progress >= 0.25 && progress < 0.625) {
      if (progress < 0.32) {
        zodiacAlpha = (progress - 0.25) / 0.07; // fade in
      } else if (progress > 0.55) {
        zodiacAlpha = (0.625 - progress) / 0.075; // fade out
      } else {
        zodiacAlpha = 1.0; // hold
      }
      zodiacAlpha = zodiacAlpha.clamp(0.0, 1.0);
    }
    if (zodiacAlpha > 0) {
      final glyphRadius = side * 0.45;
      const imgSize = 36.0; // 描画サイズ
      final rotation = (progress - 0.25) * 1.0; // ゆっくり回転
      for (int i = 0; i < 12; i++) {
        final ang = (i / 12) * 2 * pi - pi / 2 + rotation;
        final pos = Offset(cx + glyphRadius * cos(ang), cy + glyphRadius * sin(ang));
        // 背景glow (ゴールド円)
        canvas.drawCircle(
          pos, 22,
          Paint()
            ..color = const Color(0xFFF9D976).withAlpha((zodiacAlpha * 0.18 * 255).round())
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
        );
        // 12星座シンボル画像描画 (黒背景→透明変換)
        final img = zodiacImages[i];
        if (img != null) {
          final imgPaint = Paint()
            ..colorFilter = ColorFilter.matrix([
              1, 0, 0, 0, 0,
              0, 1, 0, 0, 0,
              0, 0, 1, 0, 0,
              0.299 * zodiacAlpha, 0.587 * zodiacAlpha, 0.114 * zodiacAlpha, 0, 0,
            ]);
          canvas.drawImageRect(
            img,
            Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
            Rect.fromCenter(center: pos, width: imgSize, height: imgSize),
            imgPaint,
          );
        }
      }
    }

    // ── IGNITION中の白フラッシュ (sin山形、控えめに調整) ──
    if (ignitionPulse > 0) {
      final flashAlpha = ignitionPulse * 0.20; // 0.35→0.20 (光線・記号と被るので控えめ)
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.white.withAlpha((flashAlpha * 255).round()),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FormationPainter old) =>
      old.progress != progress || old.cycle != cycle;
}
