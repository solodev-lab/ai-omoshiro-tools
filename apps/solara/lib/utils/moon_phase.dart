/// Lunar phase utilities based on Metonic cycle approximation.
/// Ported from mockup/shared/events.js getMoonPhase().
class MoonPhase {
  static const double _synodicMonth = 29.53059;

  // Known new moon: Jan 6, 2000 18:14 UTC
  static final DateTime _knownNewMoon =
      DateTime.utc(2000, 1, 6, 18, 14, 0);

  /// Returns fractional moon phase day (0.0 = new moon, ~14.76 = full moon).
  static double getPhaseDay(DateTime date) {
    final diff = date.toUtc().difference(_knownNewMoon);
    final daysSince = diff.inMilliseconds / 86400000.0;
    return ((daysSince % _synodicMonth) + _synodicMonth) % _synodicMonth;
  }

  /// Returns integer phase (0-29), matching the JS mockup behavior.
  static int getPhaseInt(DateTime date) => getPhaseDay(date).floor();

  static bool isNewMoon(DateTime date) {
    final p = getPhaseInt(date);
    return p == 0 || p == 1;
  }

  static bool isFullMoon(DateTime date) {
    final p = getPhaseInt(date);
    return p == 14 || p == 15;
  }

  /// Find the most recent new moon on or before [date].
  static DateTime findPreviousNewMoon(DateTime date) {
    final phase = getPhaseDay(date);
    // Subtract phase days to get back to new moon
    return date.subtract(Duration(
      hours: (phase * 24).round(),
    ));
  }

  /// Find the next new moon after [date].
  static DateTime findNextNewMoon(DateTime date) {
    final phase = getPhaseDay(date);
    final daysUntilNew = _synodicMonth - phase;
    return date.add(Duration(
      hours: (daysUntilNew * 24).round(),
    ));
  }

  /// Returns (cycleStart, cycleEnd) for the current lunar cycle.
  static (DateTime, DateTime) getCurrentCycleBounds(DateTime date) {
    final start = findPreviousNewMoon(date);
    final end = findNextNewMoon(date);
    return (
      DateTime(start.year, start.month, start.day),
      DateTime(end.year, end.month, end.day),
    );
  }

  /// How many total days in the current cycle.
  static int getCycleTotalDays(DateTime date) {
    final (start, end) = getCurrentCycleBounds(date);
    return end.difference(start).inDays;
  }

  /// Which day (0-based) in the current cycle is [date].
  static int getCurrentDayIndex(DateTime date) {
    final (start, _) = getCurrentCycleBounds(date);
    final today = DateTime(date.year, date.month, date.day);
    return today.difference(start).inDays;
  }

  /// Moon phase label and emoji.
  static ({String label, String emoji}) getPhaseInfo(DateTime date) {
    final p = getPhaseInt(date);
    if (p <= 1) return (label: 'New Moon', emoji: '\u{1F311}');
    if (p <= 6) return (label: 'Waxing Crescent', emoji: '\u{1F312}');
    if (p <= 8) return (label: 'First Quarter', emoji: '\u{1F313}');
    if (p <= 13) return (label: 'Waxing Gibbous', emoji: '\u{1F314}');
    if (p <= 16) return (label: 'Full Moon', emoji: '\u{1F315}');
    if (p <= 21) return (label: 'Waning Gibbous', emoji: '\u{1F316}');
    if (p <= 23) return (label: 'Last Quarter', emoji: '\u{1F317}');
    return (label: 'Waning Crescent', emoji: '\u{1F318}');
  }
}
