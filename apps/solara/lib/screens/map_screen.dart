import 'package:flutter/material.dart';
import '../theme/solara_colors.dart';
import '../widgets/glass_panel.dart';
import '../widgets/spiral_painter.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // Background gradient (placeholder for shader)
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Color(0xFF0C1D3A),
                Color(0xFF080C14),
              ],
            ),
          ),
        ),

        // Subtle star field
        ...List.generate(40, (i) {
          final rng = _SeededRandom(i * 7 + 3);
          return Positioned(
            left: rng.nextDouble() * MediaQuery.of(context).size.width,
            top: rng.nextDouble() * screenHeight * 0.7,
            child: Container(
              width: 1.5 + rng.nextDouble() * 1.5,
              height: 1.5 + rng.nextDouble() * 1.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(
                  alpha: 0.1 + rng.nextDouble() * 0.3,
                ),
              ),
            ),
          );
        }),

        // Spiral area (70% of screen)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: screenHeight * 0.7,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 48),
                Text(
                  'Day 12 of 28',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: SolaraColors.solaraGold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: CustomPaint(
                    painter: SpiralPainter(activeDays: 12, totalDays: 28),
                    size: Size.infinite,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Stella message bubble (bottom 20%)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: screenHeight * 0.20,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: GlassPanel(
              padding: const EdgeInsets.all(24),
              borderRadius: BorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: SolaraColors.solaraGold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Solara',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: SolaraColors.solaraGold,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Text(
                      'Good morning, Solar Spark. The stars are breathing with you today. Trust the spiral.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: SolaraColors.textPrimary.withValues(alpha: 0.9),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SeededRandom {
  int _seed;
  _SeededRandom(this._seed);

  double nextDouble() {
    _seed = (_seed * 16807 + 0) % 2147483647;
    return _seed / 2147483647;
  }
}
