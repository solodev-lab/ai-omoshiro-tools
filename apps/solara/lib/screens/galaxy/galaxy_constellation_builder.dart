import 'dart:math';
import '../../models/daily_reading.dart';
import '../../models/galaxy_cycle.dart';
import '../../utils/constellation_namer.dart';
import '../../utils/moon_phase.dart';
import '../../utils/tarot_data.dart';

// ══════════════════════════════════════════════════
// Constellation Builder
// HTML: formConstellation() — builds GalaxyCycle from past-cycle readings
//
// 設計方針: 名前・色・レアリティはユーザーのreadingsから生成（個別性）、
// 視覚要素(dots/edges/art)はnounIdxで完全決定（全ユーザー共通の正本形）。
// → Star Atlasの「同じGriffinは誰にとっても同じGriffin」を実現。
// → jitter/サンプリング/補間/Minor昇格/Crescent特殊処理は全て廃止。
// ══════════════════════════════════════════════════

GalaxyCycle? formConstellation(
    List<DailyReading> readings, DateTime currentCycleStart,
    {Set<String>? usedNames}) {
  if (readings.isEmpty) return null;

  // Find the cycle these readings belong to
  final firstDate = DateTime.parse(readings.first.date);
  final (prevStart, prevEnd) = MoonPhase.getCurrentCycleBounds(firstDate);

  // ─── seedCardId 決定 (最頻出Major or スート fallback) ───
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

  // ─── 名前生成 (adj × noun ハッシュ + dedup) ───
  final nameResult = ConstellationNamer.generate(
    seedCardId: seedCardId,
    date: prevStart,
    usedNames: usedNames,
  );
  final rarity = ConstellationNamer.calculateRarity(
    nameResult.adjIdx,
    nameResult.nounIdx,
  );

  // ─── dots配置: gallery方式 (nounIdx決定論、全ユーザー共通) ───
  // Anchors: template[i] をそのまま使用 (jitter/サンプリング/補間なし)
  // Minors: Golden Angle で rarity ベースの個数、synthetic cardId
  const goldenAngle = 137.508 * pi / 180;
  final dots = <ConstellationDot>[];
  final template = ConstellationNamer.nounTemplates[nameResult.nounIdx] ?? [];
  final anchorCount = template.length;
  final minorCount = (rarity.stars * 3 + 2).clamp(2, 25 - anchorCount);
  final totalDots = anchorCount + minorCount;
  // nounIdx固定シード → 同じ星座は毎回同じdots生成 (z-layer微揺らぎも決定論)
  final rng = Random(nameResult.nounIdx * 1000 + 7);

  // Anchors: テンプレート座標を直接使用
  for (int i = 0; i < anchorCount; i++) {
    final cardId = (nameResult.nounIdx * 7 + i * 11) % 78;
    dots.add(ConstellationDot(
      x: template[i][0],
      y: template[i][1],
      z: (rng.nextDouble() - 0.5) * 1.0,
      dayIndex: i,
      cardId: cardId,
      isMajor: true,
    ));
  }

  // Minors: Golden Angle配置、synthetic cardId
  for (int i = 0; i < minorCount; i++) {
    final cardId = (nameResult.nounIdx * 13 + i * 17 + 22) % 78;
    final angle = cardId * goldenAngle;
    final radius = 0.12 + (i / totalDots) * 0.3;
    final x = (0.5 + radius * cos(angle)).clamp(0.08, 0.92);
    final y = (0.5 + radius * sin(angle)).clamp(0.08, 0.92);
    dots.add(ConstellationDot(
      x: x,
      y: y,
      z: (rng.nextDouble() - 0.5) * 1.5,
      dayIndex: anchorCount + i,
      cardId: cardId,
      isMajor: false,
    ));
  }

  return GalaxyCycle(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    cycleStart: prevStart,
    cycleEnd: prevEnd,
    readings: readings, // ユーザーの実readingsは履歴として保持
    seedCardId: seedCardId,
    nameEN: nameResult.en,
    nameJP: nameResult.jp,
    dots: dots, // gallery方式で決定論生成
    rarity: rarity.stars,
    rarityLabel: rarity.label,
    adjIdx: nameResult.adjIdx,
    nounIdx: nameResult.nounIdx,
  );
}
