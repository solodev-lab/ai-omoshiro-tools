import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/galaxy_cycle.dart';
import '../theme/solara_colors.dart';
import '../utils/constellation_namer.dart';
import '../utils/solara_storage.dart';
import '../utils/title_data.dart' as title_data;

// ─────────────────────────────────────────────────────────
// 刻星化背景アセット解決テーブル (★4-5 / ★3 / ★1-2 の3層)
//
// adjGroup = adjIdx ~/ 2 (20形容詞 → 10色グループ)
// 0:golden 1:silver 2:crimson 3:ethereal 4:mystic
// 5:silent 6:frozen 7:ancient 8:infinite 9:radiant
const _adjGroupNames = [
  'golden', 'silver', 'crimson', 'ethereal', 'mystic',
  'silent', 'frozen', 'ancient', 'infinite', 'radiant',
];
// ★1-2 (lite tier) は pisces_variants から色テーマでマッチした星座を選ぶ。
// adjGroup index → pisces_{X}.webp の X 値マップ。
const _liteZodiacByGroup = [
  'leo',       // 0 golden     → leo (gold/amber)
  'gemini',    // 1 silver     → gemini (silver/sapphire)
  'aries',     // 2 crimson    → aries (crimson/orange fire)
  'cancer',    // 3 ethereal   → cancer (pearlescent silver-blue)
  'scorpio',   // 4 mystic     → scorpio (deep crimson/purple)
  'capricorn', // 5 silent     → capricorn (slate grey/icy)
  'aquarius',  // 6 frozen     → aquarius (electric cyan/blue)
  'taurus',    // 7 ancient    → taurus (emerald/copper)
  'virgo',     // 8 infinite   → virgo (sage/wheat-gold near-white)
  'libra',     // 9 radiant    → libra (rose pink/lavender pastel)
];

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

  /// 完了時の「共有」ボタンタップ。null なら共有ボタンを出さない。
  /// 引数に形成演出の背景画像 (_bgImage) を渡す = 共有カードに背景を載せるため。
  /// (2026-05-17 Free 機能として追加。柱 3 = 自分の記録の道具)
  final void Function(ui.Image? bgImage)? onShare;

  const CatasterismFormationOverlay({
    super.key,
    required this.cycle,
    this.artImage,
    required this.onComplete,
    this.onShare,
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
    // 前画面(刻星化選択)からの切替時に Cycle 画面が一瞬透けないよう、
    // フェードインせず最初から完全不透明で出す。
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1),
      value: 1.0,
    );
    _preloadZodiacImages();
    _loadBgImage();
  }

  /// レアリティ × ユーザー太陽星座 × 形容詞グループ から背景アセットパスを解決。
  /// 候補リスト形式で返し、見つからなければ次を試す (最後は固定 fallback)。
  ///
  /// 🔴 (2026-05-19) 仕様改訂:
  ///   - ★5 のみ: bright/bright_{adjGroup}_{userZodiac}.webp (120 枚、太陽星座 × 形容詞色)
  ///   - ★4: variants_leo or variants_virgo (形容詞色テーマ星座 × 2 ベース、決定論的に A/B)
  ///   - ★3: variants_scorpio or variants_aquarius
  ///   - ★1-2: variants_pisces or variants_aries
  /// 旧 mystical/ と lite/ は廃止。
  ///
  /// 決定論的 A/B 選択:
  ///   cycle.id (millisecondsSinceEpoch 文字列) を seed にして 0/1 を決める。
  ///   同じサイクルなら毎回同じ画像が選ばれるので、 Star Atlas で再表示しても
  ///   背景が揺らがない。
  ///
  /// 形容詞によっては片方のフォルダしか画像が無いケース ([baseZodiac]_[themeZodiac]
  /// で themeZodiac == baseZodiac は存在しない):
  ///   ★4: golden (leo) → virgo_leo のみ / infinite (virgo) → leo_virgo のみ
  ///   ★3: mystic (scorpio) → aquarius_scorpio のみ / frozen (aquarius) → scorpio_aquarius のみ
  ///   ★1-2: crimson (aries) → pisces_aries のみ
  /// この場合は自動的に存在する側を優先順位先頭に置く。
  List<String> _resolveBgCandidates(int rarity, String? userZodiac, int adjIdx) {
    final group = (adjIdx ~/ 2).clamp(0, _adjGroupNames.length - 1);
    final groupName = _adjGroupNames[group];
    final themeZodiac = _liteZodiacByGroup[group];

    final candidates = <String>[];
    if (rarity >= 5) {
      // ★5 Mythic — bright (太陽星座 × 形容詞色 = 120 枚)
      final zodiac = userZodiac ?? 'aries';
      candidates.add(
          'assets/catasterism-bg/bright/bright_${groupName}_$zodiac.webp');
    } else {
      // ★4 / ★3 / ★1-2 — variants A/B から決定論的ランダム
      final (baseA, baseB) = _variantBasesFor(rarity);
      // cycle.id を seed に A/B を決定 (id は millisecondsSinceEpoch 文字列)
      final seed = int.tryParse(widget.cycle.id) ?? widget.cycle.nounIdx;
      // 上位ビットを使うことで隣接サイクル同士で A/B が偏らないように
      final pick = ((seed ~/ 1000) ^ adjIdx) & 1; // 0 or 1
      final firstBase = pick == 0 ? baseA : baseB;
      final secondBase = pick == 0 ? baseB : baseA;
      // 自身対応 (baseZodiac == themeZodiac) は欠落しているのでスキップ
      if (themeZodiac != firstBase) {
        candidates.add(
            'assets/catasterism-bg/variants_$firstBase/${firstBase}_$themeZodiac.webp');
      }
      if (themeZodiac != secondBase) {
        candidates.add(
            'assets/catasterism-bg/variants_$secondBase/${secondBase}_$themeZodiac.webp');
      }
    }
    // Fallback: 旧 catasterism_bg.webp (アセットが欠けていてもクラッシュさせない)
    candidates.add('assets/catasterism_bg.webp');
    return candidates;
  }

  /// レアリティ → variants の (A, B) ベース星座ペア。
  /// ★4: (leo, virgo) / ★3: (scorpio, aquarius) / ★1-2: (pisces, aries)
  (String, String) _variantBasesFor(int rarity) {
    if (rarity == 4) return ('leo', 'virgo');
    if (rarity == 3) return ('scorpio', 'aquarius');
    return ('pisces', 'aries'); // 1-2
  }

  Future<void> _loadBgImage() async {
    String? userZodiac;
    try {
      final profile = await SolaraStorage.loadProfile();
      if (profile != null && profile.birthDate.isNotEmpty) {
        userZodiac = title_data.getSunSign(profile.birthDate);
      }
    } catch (_) {}

    final candidates = _resolveBgCandidates(
      widget.cycle.rarity,
      userZodiac,
      widget.cycle.adjIdx,
    );
    for (final path in candidates) {
      try {
        final data = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        if (mounted) setState(() => _bgImage = frame.image);
        return;
      } catch (_) {
        // try next candidate
      }
    }
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
                        // 完成 (最終画面) では日本語「刻星化」を出さない。
                        if (!isComplete) ...[
                        const SizedBox(height: 4),
                        const Text(
                          '\u523b\u661f\u5316', // 刻星化
                          style: TextStyle(
                            color: SolaraColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        ],
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
                  // 完成 (最終画面) では日本語のステージ名 (完成) を出さない。
                  if (!isComplete)
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
                  // left/right に余白を入れ、名前/レアリティが長くても画面端で
                  // 切れず自動で折返す (横幅自動調節)。
                  Positioned(
                    bottom: 96,
                    left: 24,
                    right: 24,
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
                  // \u5b8c\u4e86\u30dc\u30bf\u30f3\u9818\u57df (fade in when finished)
                  // \u5171\u6709\u30dc\u30bf\u30f3 (\u4efb\u610f) + View in Star Atlas \u3092\u6a2a\u4e26\u3073\u3067\u914d\u7f6e\u3002
                  // \u5171\u6709\u30dc\u30bf\u30f3\u306f Free \u6a5f\u80fd (\u67f1 3 = \u8a18\u9332\u3092\u6b8b\u3059\u9053\u5177)\u3002
                  Positioned(
                    bottom: 32,
                    left: 32,
                    right: 32,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 600),
                      opacity: isFinished ? 1.0 : 0.0,
                      child: Row(
                        children: [
                          if (widget.onShare != null) ...[
                            // \u5171\u6709\u30dc\u30bf\u30f3 (icon-only\u3001\u5186\u5f62\u3001\u30b4\u30fc\u30eb\u30c9\u67a0)
                            GestureDetector(
                              onTap: isFinished
                                  ? () => widget.onShare?.call(_bgImage)
                                  : null,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: SolaraColors.solaraGold
                                        .withAlpha((0.6 * 255).round()),
                                    width: 1.5,
                                  ),
                                  color: const Color(0x44060A12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: SolaraColors.solaraGold
                                          .withAlpha((0.2 * 255).round()),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.ios_share,
                                  color: SolaraColors.solaraGoldLight,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: GestureDetector(
                              onTap: isFinished ? widget.onComplete : null,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
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
                                // \u5927\u30d5\u30a9\u30f3\u30c8\u3067\u3082 1 \u884c\u306b\u53ce\u3081\u308b (\u6298\u8fd4\u3057\u3067\u30dc\u30bf\u30f3\u304c
                                // \u7e26\u306b\u4f38\u3073\u3001\u4e0a\u306e\u540d\u524d/\u30ec\u30a2\u30ea\u30c6\u30a3\u3068\u91cd\u306a\u308b\u306e\u3092\u9632\u3050)\u3002
                                child: const Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'View in Star Atlas \u2728',
                                      maxLines: 1,
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
                        ],
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

    // ── 背景画像 (COMPLETE 段階でフェードイン) ──
    // 🔴 (2026-05-19) 全レアリティ 0.45 一律に統一。
    // 仕様改訂で variants_* は形容詞色 × ベース星座のリッチ画像 (旧 mystical
    // ほど抽象でも lite ほど控えめでもない)、 ★5 bright と同じ濃度感が自然。
    // レアリティ差別化はカード名・★星数・画像内容で行い、 濃度では行わない。
    // オーナー要望で 0.55 → 0.45 → 0.10 テスト経て 0.35 に決定 (2026-05-19)。
    const bgAlphaMax = 0.35;
    if (bgImage != null) {
      final bgAlpha = ((progress - 0.625) / 0.375).clamp(0.0, 1.0) * bgAlphaMax;
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

    // IGNITION 時の画面全体の白フラッシュは削除 (星の発火時の局所グロウは残る)
  }

  @override
  bool shouldRepaint(covariant _FormationPainter old) =>
      old.progress != progress || old.cycle != cycle;
}
