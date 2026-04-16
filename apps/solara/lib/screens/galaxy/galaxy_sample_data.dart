import 'dart:math';
import '../../models/daily_reading.dart';
import '../../models/galaxy_cycle.dart';
import '../../utils/constellation_namer.dart';

/// デモ用サンプルデータ: Cycleに25個の星 + Star Atlasに61全星座
void injectGalaxySampleData(
  List<DailyReading?> days,
  List<GalaxyCycle> cycles,
  DateTime cycleStart,
  int totalDays,
) {
  final rng = Random(42);

  // ── Cycle: 25個のサンプル星を散りばめる ──
  for (int i = 0; i < 25 && i < totalDays; i++) {
    final dayIdx = (i * totalDays / 25).floor();
    if (dayIdx < days.length && days[dayIdx] == null) {
      final cardId = rng.nextInt(78);
      final isMajor = cardId < 22;
      final date = cycleStart.add(Duration(days: dayIdx));
      days[dayIdx] = DailyReading(
        date:
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        cardId: cardId,
        isMajor: isMajor,
        moonPhase: (dayIdx / totalDays * 29.53),
      );
    }
  }

  // ── Star Atlas: 61全星座のサンプル（テンプレート座標使用） ──
  if (cycles.isEmpty) {
    for (int nounIdx = 0; nounIdx < 61; nounIdx++) {
      final cycle = _buildSampleFromTemplate(nounIdx, cycleStart);
      cycles.add(cycle);
    }
  }
}

GalaxyCycle _buildSampleFromTemplate(int nounIdx, DateTime now) {
  final adjIdx = (nounIdx * 3 + 5) % 20;
  final start = now.subtract(Duration(days: 30 * (61 - nounIdx)));
  final end = start.add(const Duration(days: 29));
  final rng = Random(nounIdx * 1000 + 7);

  final template = ConstellationNamer.nounTemplates[nounIdx] ?? [];
  final anchorCount = template.length;
  final rarity = ConstellationNamer.calculateRarity(adjIdx, nounIdx);
  final minorCount = (rarity.stars * 3 + 2).clamp(2, 25 - anchorCount);
  final totalDots = anchorCount + minorCount;
  const goldenAngle = 137.508 * pi / 180;

  final readings = <DailyReading>[];
  final dots = <ConstellationDot>[];

  for (int i = 0; i < anchorCount; i++) {
    final cardId = (nounIdx * 7 + i * 11) % 78;
    final date = start.add(Duration(days: i));
    readings.add(DailyReading(
      date:
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      cardId: cardId, isMajor: true, moonPhase: i * 1.0,
    ));
    dots.add(ConstellationDot(
      x: template[i][0], y: template[i][1],
      z: (rng.nextDouble() - 0.5) * 1.0,
      dayIndex: i, cardId: cardId, isMajor: true,
    ));
  }

  for (int i = 0; i < minorCount; i++) {
    final cardId = (nounIdx * 13 + i * 17 + 22) % 78;
    final date = start.add(Duration(days: anchorCount + i));
    readings.add(DailyReading(
      date:
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      cardId: cardId, isMajor: false, moonPhase: (anchorCount + i) * 1.0,
    ));
    final angle = cardId * goldenAngle;
    final radius = 0.12 + (i / totalDots) * 0.3;
    final x = (0.5 + radius * cos(angle)).clamp(0.08, 0.92);
    final y = (0.5 + radius * sin(angle)).clamp(0.08, 0.92);
    dots.add(ConstellationDot(
      x: x, y: y, z: (rng.nextDouble() - 0.5) * 1.5,
      dayIndex: anchorCount + i, cardId: cardId, isMajor: false,
    ));
  }

  final nameEN = ConstellationNamer.buildName(adjIdx, nounIdx, en: true);
  final nameJP = ConstellationNamer.buildName(adjIdx, nounIdx, en: false);

  return GalaxyCycle(
    id: 'sample_$nounIdx',
    cycleStart: start, cycleEnd: end,
    readings: readings, seedCardId: readings.isNotEmpty ? readings.first.cardId : 0,
    nameEN: nameEN, nameJP: nameJP,
    dots: dots, rarity: rarity.stars, rarityLabel: rarity.label,
    adjIdx: adjIdx, nounIdx: nounIdx,
  );
}
