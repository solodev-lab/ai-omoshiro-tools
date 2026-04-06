import 'daily_reading.dart';

class ConstellationDot {
  final double x; // normalized 0-1 (final 2D position)
  final double y; // normalized 0-1 (final 2D position)
  final double z; // depth layer: -1.0(奥), 0.0(中), 1.0(手前)
  final int dayIndex;
  final int cardId;
  final bool isMajor;

  const ConstellationDot({
    required this.x,
    required this.y,
    this.z = 0.0,
    required this.dayIndex,
    required this.cardId,
    required this.isMajor,
  });

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'z': z,
        'dayIndex': dayIndex,
        'cardId': cardId,
        'isMajor': isMajor,
      };

  factory ConstellationDot.fromJson(Map<String, dynamic> json) {
    return ConstellationDot(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num?)?.toDouble() ?? 0.0,
      dayIndex: json['dayIndex'] as int,
      cardId: json['cardId'] as int,
      isMajor: json['isMajor'] as bool,
    );
  }
}

class GalaxyCycle {
  final String id;
  final DateTime cycleStart;
  final DateTime cycleEnd;
  final List<DailyReading> readings;
  final int seedCardId;
  final String nameEN;
  final String nameJP;
  final List<ConstellationDot> dots;
  final int rarity; // 1-5 stars (1=Common, 5=Mythic)
  final String rarityLabel; // "Common", "Uncommon", "Rare", "Legendary", "Mythic"

  const GalaxyCycle({
    required this.id,
    required this.cycleStart,
    required this.cycleEnd,
    required this.readings,
    required this.seedCardId,
    required this.nameEN,
    required this.nameJP,
    required this.dots,
    this.rarity = 1,
    this.rarityLabel = 'Common',
  });

  String get dateRangeLabel {
    final s = cycleStart;
    final e = cycleEnd;
    return '${_monthName(s.month)} ${s.day} - ${_monthName(e.month)} ${e.day}';
  }

  static String _monthName(int m) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[m];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cycleStart': cycleStart.toIso8601String(),
        'cycleEnd': cycleEnd.toIso8601String(),
        'readings': readings.map((r) => r.toJson()).toList(),
        'seedCardId': seedCardId,
        'nameEN': nameEN,
        'nameJP': nameJP,
        'dots': dots.map((d) => d.toJson()).toList(),
        'rarity': rarity,
        'rarityLabel': rarityLabel,
      };

  factory GalaxyCycle.fromJson(Map<String, dynamic> json) {
    return GalaxyCycle(
      id: json['id'] as String,
      cycleStart: DateTime.parse(json['cycleStart'] as String),
      cycleEnd: DateTime.parse(json['cycleEnd'] as String),
      readings: (json['readings'] as List)
          .map((r) => DailyReading.fromJson(r as Map<String, dynamic>))
          .toList(),
      seedCardId: json['seedCardId'] as int,
      nameEN: json['nameEN'] as String,
      nameJP: json['nameJP'] as String,
      dots: (json['dots'] as List)
          .map((d) => ConstellationDot.fromJson(d as Map<String, dynamic>))
          .toList(),
      rarity: json['rarity'] as int? ?? 1,
      rarityLabel: json['rarityLabel'] as String? ?? 'Common',
    );
  }
}
