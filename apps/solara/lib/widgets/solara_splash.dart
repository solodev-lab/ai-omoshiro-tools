import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// コールド起動時に [child] (= SolaraHome / Map) の上へ一瞬だけ被せる
/// スプラッシュ overlay。Map の初期化 (chart 計算 / タイル読込) の待ち時間を
/// 視覚的に埋めつつ、ブランド (Solara) を印象づける。
///
/// 設計:
///   - 起動ごとに 3 枚 (dawn / twilight / cosmic、ミュシャ調 神秘祭壇) から
///     ランダムで 1 枚を選ぶ。
///   - フェードイン → ホールド → フェードアウト の単一シーケンス。終わると
///     ツリーから自分を外し、以後は素通り (child だけが残る)。
///   - 表示中はタップを吸収し、裏の Map を誤操作させない。
///
/// 文字 (Solara + サブタイトル) は画像に焼き込まず、ここで重ねる
/// (画像の中央バンドは静かな発光余白として生成済み)。
class SolaraSplash extends StatefulWidget {
  final Widget child;
  const SolaraSplash({super.key, required this.child});

  @override
  State<SolaraSplash> createState() => _SolaraSplashState();
}

class _SolaraSplashState extends State<SolaraSplash>
    with SingleTickerProviderStateMixin {
  static const _images = <String>[
    'assets/splash-bg/gold.webp',
    'assets/splash-bg/azure.webp',
    'assets/splash-bg/rose.webp',
  ];
  static const _subtitle = 'Follow Stella through the living stars.';

  late final String _image;
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _image = _images[Random().nextInt(_images.length)];

    // フェードイン(700ms) → ホールド(1500ms) → フェードアウト(800ms) = 計3.0s。
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 700,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 1500),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 800,
      ),
    ]).animate(_ctrl);

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _done = true);
      }
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        // 表示中はタップ吸収。フェード値で IgnorePointer を切替え、消える瞬間に素通り。
        // _splashLayer() は child として一度だけ生成し、毎フレームの再構築を避ける。
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _opacity,
            builder: (ctx, child) => IgnorePointer(
              ignoring: _opacity.value < 0.05,
              child: Opacity(opacity: _opacity.value, child: child),
            ),
            child: _splashLayer(),
          ),
        ),
      ],
    );
  }

  Widget _splashLayer() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 背景画像 (フォールバックは intro 同系のラジアルグラデ) ──
        Image.asset(
          _image,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [Color(0xFF1A0820), Color(0xFF050208)],
              ),
            ),
          ),
        ),
        // ── コンテンツ: Solara + サブタイトル ──
        // 中央の発光星 (★) と重ならないよう、星のすぐ下 (中央やや下) に配置。
        // 背景は純黒なので中央スクリムは不要 (星の輝きを潰さない)。文字シャドウのみで可読。
        Align(
          alignment: const Alignment(0, 0.42),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Solara',
                  style: GoogleFonts.cinzel(
                    fontSize: 52,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF9D976),
                    letterSpacing: 4,
                    shadows: const [
                      Shadow(color: Color(0xCCF9D976), blurRadius: 24),
                      Shadow(color: Color(0xCC000000), blurRadius: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFFEAEAEA),
                    letterSpacing: 0.6,
                    height: 1.5,
                    shadows: const [
                      Shadow(color: Color(0xCC000000), blurRadius: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
