import 'dart:math';
import '../../models/daily_reading.dart';
import '../../models/galaxy_cycle.dart';
import '../../utils/constellation_namer.dart';
import '../../utils/moon_phase.dart';
import '../../utils/tarot_data.dart';

// ══════════════════════════════════════════════════
// Constellation Builder
// HTML: formConstellation() — builds GalaxyCycle from past-cycle readings
// ══════════════════════════════════════════════════

GalaxyCycle? formConstellation(
    List<DailyReading> readings, DateTime currentCycleStart) {
  if (readings.isEmpty) return null;

  // Find the cycle these readings belong to
  final firstDate = DateTime.parse(readings.first.date);
  final (prevStart, prevEnd) = MoonPhase.getCurrentCycleBounds(firstDate);

  // Determine seed card (most frequent major arcana)
  final majorCounts = <int, int>{};
  final suitCounts = <String, int>{};
  for (final r in readings) {
    if (r.isMajor) {
      majorCounts[r.cardId] = (majorCounts[r.cardId] ?? 0) + 1;
    } else {
      final card = TarotData.getCard(r.cardId);
      if (card.suit != null) {
        suitCounts[card.suit!] = (suitCounts[card.suit!] ?? 0) + 1;
      }
    }
  }

  int seedCardId;
  if (majorCounts.isNotEmpty) {
    seedCardId = majorCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  } else if (suitCounts.isNotEmpty) {
    final topSuit = suitCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    final suitOffset = {'wands': 0, 'cups': 14, 'swords': 28, 'pentacles': 42};
    seedCardId = 22 + (suitOffset[topSuit] ?? 0);
  } else {
    seedCardId = 0;
  }

  // Generate name (v2: 1,220 combos with dedup)
  final nameResult = ConstellationNamer.generate(
    seedCardId: seedCardId,
    date: prevStart,
  );
  final rarity = ConstellationNamer.calculateRarity(
    nameResult.adjIdx,
    nameResult.nounIdx,
  );

  // HTML exact: Place dots — Majors on NOUN_TEMPLATE positions, Minors via Golden Angle
  const goldenAngle = 137.508 * pi / 180;
  final dots = <ConstellationDot>[];
  final rng = Random(seedCardId + prevStart.millisecondsSinceEpoch);

  // Separate major/minor readings
  final majorReadings = <DailyReading>[];
  final minorReadings = <DailyReading>[];
  for (final r in readings) {
    if (r.isMajor) majorReadings.add(r);
    else minorReadings.add(r);
  }

  // Place Majors on template positions (HTML: getTemplatePositions)
  final templatePos = ConstellationNamer.getTemplatePositions(
    nameResult.nounIdx, majorReadings.length, seedCardId * 100 + prevStart.day,
  );
  for (int i = 0; i < majorReadings.length; i++) {
    final r = majorReadings[i];
    final rDate = DateTime.parse(r.date);
    final dayIdx = rDate.difference(prevStart).inDays;
    final nx = templatePos[i][0];
    final ny = templatePos[i][1];
    final zLayer = (r.cardId % 3) - 1;
    final zJitter = (rng.nextDouble() - 0.5) * 0.4;
    dots.add(ConstellationDot(
      x: nx.clamp(0.08, 0.92),
      y: ny.clamp(0.08, 0.92),
      z: (zLayer + zJitter).clamp(-1.0, 1.0),
      dayIndex: dayIdx,
      cardId: r.cardId,
      isMajor: true,
    ));
  }

  // Place Minors via Golden Angle (HTML: placeCycleDots minors section)
  for (int i = 0; i < minorReadings.length; i++) {
    final r = minorReadings[i];
    final rDate = DateTime.parse(r.date);
    final dayIdx = rDate.difference(prevStart).inDays;
    final angle = r.cardId * goldenAngle;
    final radius = 0.15 + (i / max(1, minorReadings.length)) * 0.28;
    final x = 0.5 + radius * cos(angle);
    final y = 0.5 + radius * sin(angle);
    final zLayer = (r.cardId % 3) - 1;
    final zJitter = (rng.nextDouble() - 0.5) * 0.4;
    dots.add(ConstellationDot(
      x: x.clamp(0.08, 0.92),
      y: y.clamp(0.08, 0.92),
      z: (zLayer + zJitter).clamp(-1.0, 1.0),
      dayIndex: dayIdx,
      cardId: r.cardId,
      isMajor: false,
    ));
  }

  dots.sort((a, b) => a.dayIndex.compareTo(b.dayIndex));

  return GalaxyCycle(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    cycleStart: prevStart,
    cycleEnd: prevEnd,
    readings: readings,
    seedCardId: seedCardId,
    nameEN: nameResult.en,
    nameJP: nameResult.jp,
    dots: dots,
    rarity: rarity.stars,
    rarityLabel: rarity.label,
    adjIdx: nameResult.adjIdx,
    nounIdx: nameResult.nounIdx,
  );
}
