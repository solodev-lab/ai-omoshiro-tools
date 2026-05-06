part of '../horoscope_screen.dart';

// ══════════════════════════════════════════════════
// Chart scroll view + zodiac images + legend
// horoscope_screen.dart の part としてチャート描画を担当。
// ══════════════════════════════════════════════════

extension _HoroChartView on HoroscopeScreenState {
  /// 外周12星座画像 (黒透過 + 輝度→alpha)
  List<Widget> _buildZodiacImages(double chartSize, double asc) {
    final base = chartSize / 600.0; // scale
    final r = 282.5 * base; // (zodiacOuter + zodiacInner) / 2
    final imgSize = chartSize * 0.07;
    final cx = chartSize / 2;
    final cy = chartSize / 2;
    return List.generate(12, (i) {
      final midLon = i * 30 + 15;
      // lonToAngle = (asc - lon + 180) * pi/180 (チャートペインターと同じ式)
      final angleRad = (asc - midLon + 180) * pi / 180;
      final x = cx + r * cos(angleRad) - imgSize / 2;
      final y = cy + r * sin(angleRad) - imgSize / 2;
      return Positioned(
        left: x, top: y,
        width: imgSize, height: imgSize,
        child: IgnorePointer(child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            1, 0, 0, 0, 0,
            0, 1, 0, 0, 0,
            0, 0, 1, 0, 0,
            1.70, 5.72, 0.58, 0, 0, // 純黒のみ透明
          ]),
          child: Image.asset(
            'assets/zodiac-symbols/${_zodiacFilenames[i]}.webp',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        )),
      );
    });
  }

  Widget _buildChartScrollView() {
    final screenW = MediaQuery.of(context).size.width;
    final chartAsp = _chartAspects();
    // 2026-04-29: 縦に短い端末で chart が bottom sheet に被る問題を解決。
    // chart サイズは画面幅と利用可能な縦幅の両方を考慮し、min を採用。
    // 200px 下限はクランプで担保 (これ以下は読めなくなるため)。
    return LayoutBuilder(builder: (ctx, constraints) {
      final maxH = constraints.maxHeight;
      // 上部 padding (8) + ラベル等の余白 ~24px を引いた純粋な chart 描画域
      final availH = maxH - 32;
      final chartSize = min(screenW - 16, availH).clamp(200.0, 600.0);
      return Listener(
        // chart 領域への pointer down で anim 再覚醒 (30s 再カウント)。
        // GestureDetector 内蔵の子 (惑星 tap 等) は影響を受けない。
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => wakeAnimations(),
        child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(children: [
          const SizedBox(height: 8),
          Center(child: SizedBox(
            width: chartSize, height: chartSize,
          child: AnimatedBuilder(
            animation: _breathCtl,
            builder: (context, _) {
              // easeInOut → 20段階に離散化 (80%の無駄な再描画削減)
              final rawBreath = Curves.easeInOut.transform(_breathCtl.value);
              final breath = (rawBreath * 20).round() / 20.0;
              return Stack(
                clipBehavior: Clip.none,  // labels drawn outside chart bounds (A/D/M/I)
                children: [
                // ── Parchment base disc (plain, no astrological diagrams) ──
                Positioned.fill(child: ClipOval(
                  child: Opacity(
                    opacity: 0.75,
                    child: Image.asset(
                      'assets/horo-bg/parchment_base.webp',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                )),
                // Slight golden bloom overlay
                Positioned.fill(child: ClipOval(child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Color(0x22C9A84C),
                        Color(0x00000000),
                      ],
                      stops: const [0.0, 0.8],
                    ),
                  ),
                ))),
                // ── Watermark title (Cinzel serif) ──
                Positioned(
                  top: chartSize * 0.42 - 8, left: 0, right: 0,
                  child: Center(child: Text('SOLARA', style: GoogleFonts.cinzel(
                    fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 6,
                    color: const Color(0xFFC9A84C).withAlpha(60),
                  ))),
                ),
                // ── Chart wheel ──
                CustomPaint(
                  size: Size(chartSize, chartSize),
                  painter: HoroChartWheelPainter(
                    planets: _natalPlanets, asc: _asc, mc: _mc,
                    aspects: chartAsp,
                    signColors: signColors.map((c) => Color(c)).toList(),
                    showHouses: !_birthTimeUnknown,
                    birthTimeUnknown: _birthTimeUnknown,
                    userName: _profile?.name ?? '',
                    userDate: _profile?.birthDate ?? '',
                    userTime: _profile?.birthTime ?? '',
                    secondaryPlanets: (_chartMode == 'nt' || _chartMode == 'np') ? _secondaryPlanets : null,
                    secondaryAsc: (_chartMode == 'nt' || _chartMode == 'np') ? _secondaryAsc : null,
                    secondaryMc: (_chartMode == 'nt' || _chartMode == 'np') ? _secondaryMc : null,
                    secondaryLabelPrefix: _chartMode == 'np' ? 'p' : 't',
                    secondaryColor: _chartMode == 'np'
                      ? const Color(0xFFB088FF)
                      : const Color(0xFF6BB5FF),
                    patterns: _visiblePatterns(),
                    breath: breath,
                  ),
                ),
                // ── Antique ornament frame (on top of wheel, outside) ──
                Positioned.fill(child: CustomPaint(
                  painter: HoroOrnamentPainter(breath: breath, asc: _asc),
                )),
                // ── 12 zodiac sign images around outer ring ──
                ..._buildZodiacImages(chartSize, _asc),
                // ── Center zodiac image — 時刻あり: ASC sign / 時刻不明: Sun sign ──
                Positioned.fill(child: Center(
                  child: SizedBox(
                    // 時刻不明時はテキストがないので大きめに表示
                    width: chartSize * (_birthTimeUnknown ? 0.14 : 0.09),
                    height: chartSize * (_birthTimeUnknown ? 0.14 : 0.09),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.matrix(<double>[
                        1, 0, 0, 0, 0,
                        0, 1, 0, 0, 0,
                        0, 0, 1, 0, 0,
                        // alpha = luminance * 8 — 純黒のみ透明
                        1.70, 5.72, 0.58, 0, 0,
                      ]),
                      child: Image.asset(
                        'assets/zodiac-symbols/${_zodiacFilenames[(((_birthTimeUnknown
                          ? (_natalPlanets['sun'] ?? 0)
                          : _asc) / 30).floor() % 12)]}.webp',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                )),
              ]);
            },
          ),
        )),
          const SizedBox(height: 12),
          _buildChartLegend(),
          const SizedBox(height: 20),
        ]),
      ),
      );
    });
  }

  Widget _buildChartLegend() {
    final showSecondary = _chartMode == 'nt' || _chartMode == 'np';
    return Wrap(
      spacing: 16, runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        // アスペクト線 (太バー表示)
        const HoroLegendItem(color: Color(0xFFC9A84C), label: 'ソフト', shape: 'line'),
        const HoroLegendItem(color: Color(0xFF6B5CE7), label: 'ハード', shape: 'line'),
        const HoroLegendItem(color: Color(0xFF26D0CE), label: '中立', shape: 'line'),
        // 惑星ドット (丸表示) — 2重モード時のみネイタル凡例を追加
        if (showSecondary) ...[
          const HoroLegendItem(color: Color(0xFFFFD370), label: 'ネイタル', shape: 'dot'),
          if (_chartMode == 'nt')
            const HoroLegendItem(color: Color(0xFF6BB5FF), label: 'トランジット', shape: 'dot'),
          if (_chartMode == 'np')
            const HoroLegendItem(color: Color(0xFFB088FF), label: 'プログレス', shape: 'dot'),
        ],
      ],
    );
  }
}
