import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/tarot_card.dart';

/// Loads and indexes the 78-card tarot deck from the bundled asset.
class TarotData {
  static List<TarotCard>? _allCards;

  static Future<void> initialize() async {
    if (_allCards != null) return;

    final jsonStr = await rootBundle.loadString('assets/tarot_planet_map.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final cards = <TarotCard>[];

    // Major Arcana (ids 0-21)
    final majors = data['majorArcana'] as List;
    for (final m in majors) {
      cards.add(TarotCard.fromMajorJson(m as Map<String, dynamic>));
    }

    // Minor Arcana (ids 22-77)
    final suits = data['suitMapping'] as Map<String, dynamic>;
    final minors = data['minorArcana'] as List;
    for (int i = 0; i < minors.length; i++) {
      final m = minors[i] as Map<String, dynamic>;
      final suitKey = m['suit'] as String;
      final suitInfo = suits[suitKey] as Map<String, dynamic>;
      // HTML: getCardInfo() for minor → SUIT_MAP[suit].planets[0]
      final suitPlanets = (suitInfo['planets'] as List?)?.cast<String>();
      cards.add(TarotCard.fromMinorJson(
        m,
        id: 22 + i,
        element: suitInfo['element'] as String,
        suitEmoji: suitInfo['emoji'] as String,
        planet: suitPlanets?.isNotEmpty == true ? suitPlanets!.first : null,
      ));
    }

    _allCards = cards;
  }

  static List<TarotCard> get allCards {
    assert(_allCards != null, 'Call TarotData.initialize() first');
    return _allCards!;
  }

  static TarotCard getCard(int id) => allCards[id];

  static List<TarotCard> get majorArcana =>
      allCards.where((c) => c.isMajor).toList();

  static List<TarotCard> get minorArcana =>
      allCards.where((c) => !c.isMajor).toList();
}
