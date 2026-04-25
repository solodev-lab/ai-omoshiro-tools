/// Lunar phase utilities based on Jean Meeus "Astronomical Algorithms"
/// Chapter 49 — Phases of the Moon.
///
/// Precision: ±2-3 minutes for new/full moon times (vs ±17 hours with
/// simple Metonic cycle approximation).
///
/// Uses 14 correction terms for New Moon and Full Moon.
library;
import 'dart:math' as math;

class MoonPhase {
  static const double _synodicMonth = 29.530588861;

  // ──────────────────────────────────────────────
  //  Jean Meeus — compute lunation phase time (JDE)
  // ──────────────────────────────────────────────

  /// Returns the Julian Ephemeris Day of the given phase
  /// for the lunation nearest to [year] (decimal year).
  ///
  /// [phase]: 0 = New Moon, 0.25 = First Quarter,
  ///          0.5 = Full Moon, 0.75 = Last Quarter.
  static double _computePhaseJDE(double year, double phase) {
    // Approximate lunation number k
    double k = (year - 2000.0) * 12.3685;
    // Round k to nearest phase
    k = (k - phase).roundToDouble() + phase;

    // Time in Julian centuries from J2000.0
    final t = k / 1236.85;
    final t2 = t * t;
    final t3 = t2 * t;
    final t4 = t3 * t;

    // Mean phase JDE (Meeus eq. 49.1)
    double jde = 2451550.09766 +
        _synodicMonth * k +
        0.00015437 * t2 -
        0.000000150 * t3 +
        0.00000000073 * t4;

    // Sun's mean anomaly (M)
    final m = _deg2rad(2.5534 +
        29.10535670 * k -
        0.0000014 * t2 -
        0.00000011 * t3);

    // Moon's mean anomaly (M')
    final mp = _deg2rad(201.5643 +
        385.81693528 * k +
        0.0107582 * t2 +
        0.00001238 * t3 -
        0.000000058 * t4);

    // Moon's argument of latitude (F)
    final f = _deg2rad(160.7108 +
        390.67050284 * k -
        0.0016118 * t2 -
        0.00000227 * t3 +
        0.000000011 * t4);

    // Longitude of ascending node (Omega)
    final omega = _deg2rad(124.7746 -
        1.56375588 * k +
        0.0020672 * t2 +
        0.00000215 * t3);

    // Planetary arguments (A1, A2, A3)
    final a1 = _deg2rad(299.77 + 132.8475848 * k - 0.009173 * t2);
    final a2 = _deg2rad(251.88 + 0.016321 * k);
    final a3 = _deg2rad(251.83 + 26.651886 * k);

    // E factor for solar eccentricity
    final e = 1.0 - 0.002516 * t - 0.0000074 * t2;
    final e2 = e * e;

    double correction;

    if (phase == 0.0) {
      // New Moon corrections (14 terms)
      correction = -0.40720 * math.sin(mp) +
          0.17241 * e * math.sin(m) +
          0.01608 * math.sin(2 * mp) +
          0.01039 * math.sin(2 * f) +
          0.00739 * e * math.sin(mp - m) -
          0.00514 * e * math.sin(mp + m) +
          0.00208 * e2 * math.sin(2 * m) -
          0.00111 * math.sin(mp - 2 * f) -
          0.00057 * math.sin(mp + 2 * f) +
          0.00056 * e * math.sin(2 * mp + m) -
          0.00042 * math.sin(3 * mp) +
          0.00042 * e * math.sin(m + 2 * f) +
          0.00038 * e * math.sin(m - 2 * f) -
          0.00024 * e * math.sin(2 * mp - m);
    } else if (phase == 0.5) {
      // Full Moon corrections (14 terms)
      correction = -0.40614 * math.sin(mp) +
          0.17302 * e * math.sin(m) +
          0.01614 * math.sin(2 * mp) +
          0.01043 * math.sin(2 * f) +
          0.00734 * e * math.sin(mp - m) -
          0.00515 * e * math.sin(mp + m) +
          0.00209 * e2 * math.sin(2 * m) -
          0.00111 * math.sin(mp - 2 * f) -
          0.00057 * math.sin(mp + 2 * f) +
          0.00056 * e * math.sin(2 * mp + m) -
          0.00042 * math.sin(3 * mp) +
          0.00042 * e * math.sin(m + 2 * f) +
          0.00038 * e * math.sin(m - 2 * f) -
          0.00024 * e * math.sin(2 * mp - m);
    } else {
      // Quarter corrections (simplified — not used in Solara currently)
      correction = -0.62801 * math.sin(mp) +
          0.17172 * e * math.sin(m) -
          0.01183 * e * math.sin(mp + m) +
          0.00862 * math.sin(2 * mp) +
          0.00804 * math.sin(2 * f) +
          0.00454 * e * math.sin(mp - m) +
          0.00204 * e2 * math.sin(2 * m) -
          0.00180 * math.sin(mp - 2 * f) -
          0.00070 * math.sin(mp + 2 * f) -
          0.00040 * math.sin(3 * mp) -
          0.00034 * e * math.sin(2 * mp - m) +
          0.00032 * e * math.sin(m + 2 * f) +
          0.00032 * e * math.sin(m - 2 * f) -
          0.00028 * e2 * math.sin(mp + 2 * m);

      // Additional quarter correction (W)
      final w = 0.00306 -
          0.00038 * e * math.cos(m) +
          0.00026 * math.cos(mp) -
          0.00002 * math.cos(mp - m) +
          0.00002 * math.cos(mp + m) +
          0.00002 * math.cos(2 * f);
      correction += (phase == 0.25) ? w : -w;
    }

    jde += correction;

    // Additional corrections common to all phases
    jde += 0.000325 * math.sin(a1) +
        0.000165 * math.sin(a2) +
        0.000164 * math.sin(a3) +
        0.000126 * math.sin(omega);

    return jde;
  }

  // ──────────────────────────────────────────────
  //  JDE ↔ DateTime conversion
  // ──────────────────────────────────────────────

  static DateTime _jdeToDateTime(double jde) {
    // Convert JDE to Unix timestamp
    // J2000.0 = 2451545.0 = 2000-01-01 12:00:00 UTC
    final daysSinceJ2000 = jde - 2451545.0;
    final msSinceJ2000 = (daysSinceJ2000 * 86400000).round();
    final j2000 = DateTime.utc(2000, 1, 1, 12, 0, 0);
    return j2000.add(Duration(milliseconds: msSinceJ2000));
  }

  static double _dateTimeToDecimalYear(DateTime dt) {
    final utc = dt.toUtc();
    final yearStart = DateTime.utc(utc.year, 1, 1);
    final yearEnd = DateTime.utc(utc.year + 1, 1, 1);
    final fraction = utc.difference(yearStart).inMilliseconds /
        yearEnd.difference(yearStart).inMilliseconds;
    return utc.year + fraction;
  }

  static double _deg2rad(double deg) => deg * math.pi / 180.0;

  // ──────────────────────────────────────────────
  //  Public API — drop-in replacements
  // ──────────────────────────────────────────────

  /// Find the most recent New Moon on or before [date].
  static DateTime findPreviousNewMoon(DateTime date) {
    final year = _dateTimeToDecimalYear(date);
    // Start searching from a slightly earlier date
    var searchYear = year - 0.05;
    DateTime result;
    do {
      result = _jdeToDateTime(_computePhaseJDE(searchYear, 0.0));
      searchYear += _synodicMonth / 365.25;
    } while (result.isBefore(date) &&
        date.difference(result).inDays > _synodicMonth.ceil());

    // If we overshot, go back one lunation
    if (result.isAfter(date)) {
      searchYear = _dateTimeToDecimalYear(date) - (_synodicMonth / 365.25);
      result = _jdeToDateTime(_computePhaseJDE(searchYear, 0.0));
    }

    // Verify: result should be <= date
    if (result.isAfter(date)) {
      searchYear -= _synodicMonth / 365.25;
      result = _jdeToDateTime(_computePhaseJDE(searchYear, 0.0));
    }

    return result;
  }

  /// Find the next New Moon after [date].
  static DateTime findNextNewMoon(DateTime date) {
    final year = _dateTimeToDecimalYear(date);
    var searchYear = year;
    DateTime result;
    do {
      result = _jdeToDateTime(_computePhaseJDE(searchYear, 0.0));
      searchYear += _synodicMonth / 365.25;
    } while (!result.isAfter(date));
    return result;
  }

  /// Find the Full Moon nearest to [date] within the current cycle.
  static DateTime findFullMoonInCycle(DateTime date) {
    final prevNew = findPreviousNewMoon(date);
    final year = _dateTimeToDecimalYear(prevNew);
    // Full moon is ~0.5 lunation after new moon
    final searchYear = year + (_synodicMonth / 2) / 365.25;
    return _jdeToDateTime(_computePhaseJDE(searchYear, 0.5));
  }

  /// Returns fractional moon phase day (0.0 = new moon, ~14.76 = full moon).
  /// Uses Jean Meeus new moon times for accurate cycle boundaries.
  static double getPhaseDay(DateTime date) {
    final prevNew = findPreviousNewMoon(date);
    final diff = date.toUtc().difference(prevNew);
    return diff.inMilliseconds / 86400000.0;
  }

  /// Returns integer phase (0-29).
  static int getPhaseInt(DateTime date) => getPhaseDay(date).floor();

  /// Is today a New Moon day? (within ±1 day of exact new moon)
  static bool isNewMoon(DateTime date) {
    final phaseDay = getPhaseDay(date);
    return phaseDay < 1.5;
  }

  /// Is today the Full Moon day? (the single closest day to exact full moon)
  static bool isFullMoon(DateTime date) {
    final fullMoon = findFullMoonInCycle(date);
    final noon = DateTime.utc(date.year, date.month, date.day, 12);
    final diff = noon.difference(fullMoon).inHours.abs();
    return diff < 12; // only the single day whose noon is closest
  }

  /// Returns (cycleStart, cycleEnd) for the current lunar cycle.
  static (DateTime, DateTime) getCurrentCycleBounds(DateTime date) {
    final start = findPreviousNewMoon(date);
    final end = findNextNewMoon(date);
    return (
      DateTime.utc(start.year, start.month, start.day),
      DateTime.utc(end.year, end.month, end.day),
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
    final today = DateTime.utc(date.year, date.month, date.day);
    return today.difference(start).inDays;
  }

  /// Generate a unique cycle ID from the new moon date.
  static String getCycleId(DateTime date) {
    final prevNew = findPreviousNewMoon(date);
    return '${prevNew.year}-${prevNew.month.toString().padLeft(2, '0')}-${prevNew.day.toString().padLeft(2, '0')}';
  }

  /// Moon phase label and emoji.
  static ({String label, String labelJP, String emoji}) getPhaseInfo(
      DateTime date) {
    final p = getPhaseInt(date);
    if (p <= 1) {
      return (label: 'New Moon', labelJP: '新月', emoji: '\u{1F311}');
    }
    if (p <= 6) {
      return (
        label: 'Waxing Crescent',
        labelJP: '三日月',
        emoji: '\u{1F312}'
      );
    }
    if (p <= 8) {
      return (label: 'First Quarter', labelJP: '上弦の月', emoji: '\u{1F313}');
    }
    if (p <= 13) {
      return (
        label: 'Waxing Gibbous',
        labelJP: '十三夜月',
        emoji: '\u{1F314}'
      );
    }
    if (p <= 16) {
      return (label: 'Full Moon', labelJP: '満月', emoji: '\u{1F315}');
    }
    if (p <= 21) {
      return (
        label: 'Waning Gibbous',
        labelJP: '十八夜月',
        emoji: '\u{1F316}'
      );
    }
    if (p <= 23) {
      return (label: 'Last Quarter', labelJP: '下弦の月', emoji: '\u{1F317}');
    }
    return (
      label: 'Waning Crescent',
      labelJP: '二十六夜月',
      emoji: '\u{1F318}'
    );
  }

  /// Get the illumination fraction (0.0 to 1.0).
  static double getIllumination(DateTime date) {
    final phase = getPhaseDay(date);
    // Approximate illumination using cosine
    return (1.0 - math.cos(2.0 * math.pi * phase / _synodicMonth)) / 2.0;
  }
}
