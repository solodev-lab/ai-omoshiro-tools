import 'dart:math';
import 'package:flutter/material.dart';
import '../models/daily_reading.dart';
import '../models/tarot_card.dart';
import '../theme/solara_colors.dart';
import '../utils/moon_phase.dart';
import '../utils/solara_storage.dart';
import '../utils/tarot_data.dart';
import '../widgets/glass_panel.dart';

class ObserveScreen extends StatefulWidget {
  const ObserveScreen({super.key});

  @override
  State<ObserveScreen> createState() => _ObserveScreenState();
}

class _ObserveScreenState extends State<ObserveScreen> {
  double _moodValue = 0.0;
  bool _cardFlipped = false;
  TarotCard? _drawnCard;
  bool _alreadyDrawnToday = false;

  @override
  void initState() {
    super.initState();
    _checkTodayReading();
  }

  Future<void> _checkTodayReading() async {
    final today = await SolaraStorage.getTodayReading();
    if (today != null && mounted) {
      setState(() {
        _drawnCard = TarotData.getCard(today.cardId);
        _cardFlipped = true;
        _alreadyDrawnToday = true;
      });
    }
  }

  Future<void> _drawCard() async {
    if (_alreadyDrawnToday) {
      // Already drawn today — just flip to show the same card
      setState(() => _cardFlipped = !_cardFlipped);
      return;
    }

    // Draw a random card from the 78-card deck
    final rng = Random();
    final card = TarotData.allCards[rng.nextInt(78)];

    // Save to Galaxy storage
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final reading = DailyReading(
      date: dateStr,
      cardId: card.id,
      isMajor: card.isMajor,
      moonPhase: MoonPhase.getPhaseDay(now),
    );
    await SolaraStorage.addReading(reading);

    setState(() {
      _drawnCard = card;
      _cardFlipped = true;
      _alreadyDrawnToday = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [Color(0xFF0C1D3A), Color(0xFF080C14)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Text(
                'OBSERVE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: SolaraColors.solaraGold,
                      letterSpacing: 3.0,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'How does your orbit feel?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),

              const SizedBox(height: 40),

              // Mood Slider
              GlassPanel(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Stillness',
                            style: Theme.of(context).textTheme.labelSmall),
                        Text(
                          _moodLabel,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: SolaraColors.solaraGold,
                          ),
                        ),
                        Text('Radiance',
                            style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: SolaraColors.solaraGold,
                        inactiveTrackColor:
                            SolaraColors.textSecondary.withValues(alpha: 0.2),
                        thumbColor: SolaraColors.solaraGoldLight,
                        overlayColor:
                            SolaraColors.solaraGold.withValues(alpha: 0.1),
                        trackHeight: 2,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: _moodValue,
                        min: -1.0,
                        max: 1.0,
                        onChanged: (v) => setState(() => _moodValue = v),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Tarot Card
              Text(
                _alreadyDrawnToday ? 'TODAY\'S CARD' : 'TAP TO DRAW',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 2.0,
                    ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: GestureDetector(
                  onTap: _drawCard,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: _cardFlipped && _drawnCard != null
                        ? _buildCardFront(_drawnCard!)
                        : _buildCardBack(),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String get _moodLabel {
    if (_moodValue < -0.5) return 'Deep Rest';
    if (_moodValue < 0.0) return 'Stillness';
    if (_moodValue < 0.5) return 'Calm';
    return 'Radiant';
  }

  Widget _buildCardBack() {
    return Container(
      key: const ValueKey('back'),
      constraints: const BoxConstraints(maxWidth: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C1D3A), Color(0xFF1A2F5A)],
        ),
        border: Border.all(
          color: SolaraColors.solaraGold.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Center(
        child: Opacity(
          opacity: 0.5,
          child: Image.asset(
            'assets/solara_logo.png',
            width: 80,
            height: 80,
          ),
        ),
      ),
    );
  }

  Widget _buildCardFront(TarotCard card) {
    final gradientColors = _cardGradient(card);
    final glowColor = card.isMajor
        ? SolaraColors.planetColor(card.planet ?? 'sun')
        : SolaraColors.elementColor(card.element);

    return Container(
      key: ValueKey('front-${card.id}'),
      constraints: const BoxConstraints(maxWidth: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
        border: Border.all(
          color: glowColor.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.2),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              card.emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            if (card.isMajor)
              Text(
                _romanNumeral(card.id),
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w300,
                  letterSpacing: 4,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              card.nameEN,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              card.nameJP,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              card.isMajor
                  ? '${card.element[0].toUpperCase()}${card.element.substring(1)} \u00B7 ${card.planet?[0].toUpperCase()}${card.planet?.substring(1) ?? ''}'
                  : '${card.suit?[0].toUpperCase()}${card.suit?.substring(1) ?? ''} \u00B7 ${card.element[0].toUpperCase()}${card.element.substring(1)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                card.keyword,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _cardGradient(TarotCard card) {
    if (card.isMajor) {
      final c = SolaraColors.planetColor(card.planet ?? 'sun');
      return [
        Color.lerp(const Color(0xFF0C1D3A), c, 0.3)!,
        Color.lerp(const Color(0xFF080C14), c, 0.15)!,
      ];
    }
    switch (card.element) {
      case 'fire':
        return [SolaraColors.fireStart, SolaraColors.fireEnd.withValues(alpha: 0.6)];
      case 'water':
        return [SolaraColors.waterStart, SolaraColors.waterEnd.withValues(alpha: 0.6)];
      case 'air':
        return [
          const Color(0xFF2A2A3A),
          SolaraColors.airEnd.withValues(alpha: 0.4),
        ];
      case 'earth':
        return [SolaraColors.earthStart, SolaraColors.earthEnd.withValues(alpha: 0.6)];
      default:
        return [const Color(0xFF0C1D3A), const Color(0xFF1A2F5A)];
    }
  }

  String _romanNumeral(int id) {
    const numerals = [
      '0', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X',
      'XI', 'XII', 'XIII', 'XIV', 'XV', 'XVI', 'XVII', 'XVIII', 'XIX', 'XX', 'XXI',
    ];
    return id < numerals.length ? numerals[id] : '$id';
  }
}
