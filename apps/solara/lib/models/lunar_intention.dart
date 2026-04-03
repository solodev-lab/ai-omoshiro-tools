/// Represents a user's chosen intention for a lunar cycle.
class LunarIntention {
  final String cycleId; // "2026-04" format
  final String chosenText; // EN
  final String chosenTextJP; // JP
  final DateTime chosenAt; // when intention was set (new moon)
  final String newMoonSign; // "Aries"
  final MidpointCheck? midpoint; // full moon check-in
  final CrystallizationResult? crystallization; // end-of-cycle self-assessment

  const LunarIntention({
    required this.cycleId,
    required this.chosenText,
    required this.chosenTextJP,
    required this.chosenAt,
    required this.newMoonSign,
    this.midpoint,
    this.crystallization,
  });

  LunarIntention copyWith({
    MidpointCheck? midpoint,
    CrystallizationResult? crystallization,
  }) {
    return LunarIntention(
      cycleId: cycleId,
      chosenText: chosenText,
      chosenTextJP: chosenTextJP,
      chosenAt: chosenAt,
      newMoonSign: newMoonSign,
      midpoint: midpoint ?? this.midpoint,
      crystallization: crystallization ?? this.crystallization,
    );
  }

  Map<String, dynamic> toJson() => {
        'cycleId': cycleId,
        'chosenText': chosenText,
        'chosenTextJP': chosenTextJP,
        'chosenAt': chosenAt.toIso8601String(),
        'newMoonSign': newMoonSign,
        'midpoint': midpoint?.toJson(),
        'crystallization': crystallization?.toJson(),
      };

  factory LunarIntention.fromJson(Map<String, dynamic> json) {
    return LunarIntention(
      cycleId: json['cycleId'] as String,
      chosenText: json['chosenText'] as String,
      chosenTextJP: json['chosenTextJP'] as String,
      chosenAt: DateTime.parse(json['chosenAt'] as String),
      newMoonSign: json['newMoonSign'] as String,
      midpoint: json['midpoint'] != null
          ? MidpointCheck.fromJson(json['midpoint'] as Map<String, dynamic>)
          : null,
      crystallization: json['crystallization'] != null
          ? CrystallizationResult.fromJson(
              json['crystallization'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Full moon midpoint check-in.
class MidpointCheck {
  final DateTime checkedAt;
  final int rating; // 1-3: 1=struggling, 2=working on it, 3=feeling it

  const MidpointCheck({required this.checkedAt, required this.rating});

  Map<String, dynamic> toJson() => {
        'checkedAt': checkedAt.toIso8601String(),
        'rating': rating,
      };

  factory MidpointCheck.fromJson(Map<String, dynamic> json) {
    return MidpointCheck(
      checkedAt: DateTime.parse(json['checkedAt'] as String),
      rating: json['rating'] as int,
    );
  }
}

/// End-of-cycle crystallization self-assessment.
class CrystallizationResult {
  final DateTime assessedAt;
  final bool released; // did the user feel they released it?

  const CrystallizationResult({required this.assessedAt, required this.released});

  Map<String, dynamic> toJson() => {
        'assessedAt': assessedAt.toIso8601String(),
        'released': released,
      };

  factory CrystallizationResult.fromJson(Map<String, dynamic> json) {
    return CrystallizationResult(
      assessedAt: DateTime.parse(json['assessedAt'] as String),
      released: json['released'] as bool,
    );
  }
}
