part of '../horoscope_screen.dart';

// ══════════════════════════════════════════════════
// Mystical backdrop + No-profile message
// horoscope_screen.dart の part として
// State 内の controller / scroll parallax にアクセスする。
// ══════════════════════════════════════════════════

extension _HoroBackdrop on HoroscopeScreenState {
  /// Mystical cosmic backdrop:
  /// [1] deep radial base color
  /// [2] slowly rotating nebula image (full-screen, 25% opacity)
  /// [3] subtle vignette over the whole thing
  Widget _mysticalBackdrop({required Widget child}) {
    return Stack(children: [
      // base radial
      const Positioned.fill(child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center, radius: 1.3,
            colors: [Color(0xFF1A0F2E), Color(0xFF050810)],
          ),
        ),
      )),
      // nebula — 星読み: 静止 + スクロールで垂直パララックス、それ以外: 緩やか回転
      Positioned.fill(child: IgnorePointer(child: ClipRect(
        child: _chartMode == 'astrology'
          // ── 星読み: _rotCtl 停止・スクロール量で Y 方向にシフト ──
          ? ValueListenableBuilder<double>(
              valueListenable: _readingParallax,
              builder: (_, dy, _) => Opacity(
                opacity: 0.35,
                child: Transform.translate(
                  offset: Offset(0, -dy), // 下にスクロールすると背景が上に少し動く
                  child: Transform.scale(
                    scale: 1.5,
                    child: Image.asset(
                      'assets/horo-bg/cosmic_nebula.webp',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            )
          // ── 通常モード: 従来通り緩やかに回転 ──
          : AnimatedBuilder(
              animation: _rotCtl,
              builder: (_, _) => Opacity(
                opacity: 0.35,
                child: Transform.scale(
                  scale: 1.5,
                  child: Transform.rotate(
                    angle: _rotCtl.value * 2 * pi,
                    child: Image.asset(
                      'assets/horo-bg/cosmic_nebula.webp',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
      ))),
      // soft vignette (60% at edges — weaker to let nebula show through top/bottom)
      const Positioned.fill(child: IgnorePointer(child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center, radius: 1.0,
            colors: [Color(0x00000000), Color(0xB3000000)],
            stops: [0.55, 1.0],
          ),
        ),
      ))),
      // actual content
      child,
    ]);
  }

  /// プロフィール未設定時の案内画面
  Widget _buildNoProfile() {
    return _mysticalBackdrop(
      child: SafeArea(child: Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0x14F9D976),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x40F9D976)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const AntiqueGlyph(icon: AntiqueIcon.reading, size: 32,
              color: Color(0xFFF6BD60)),
            const SizedBox(height: 8),
            const Text('SANCTUARYでプロフィールを設定すると、\nあなた専用のホロスコープが表示されます',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFFF6BD60))),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => widget.onNavigateToSanctuary?.call(),
              child: const Text('設定する →', style: TextStyle(fontSize: 12, color: Color(0xFFF9D976),
                decoration: TextDecoration.underline)),
            ),
          ]),
        ),
      ))),
    );
  }
}
