import 'package:flutter_test/flutter_test.dart';
import 'package:solara/utils/moon_phase.dart';

void main() {
  // 2026 new moon dates computed by Jean Meeus algorithm
  // Verified against USNO/NASA for 2024 dates (±2 min accuracy)
  // 2026 dates cross-checked with algorithm output
  final newMoons2026 = [
    DateTime.utc(2026, 1, 18, 19, 53),
    DateTime.utc(2026, 2, 17, 12, 3),
    DateTime.utc(2026, 3, 19, 1, 26),
    DateTime.utc(2026, 4, 17, 11, 53),
    DateTime.utc(2026, 5, 16, 20, 3),
    DateTime.utc(2026, 6, 15, 2, 56),
    DateTime.utc(2026, 7, 14, 9, 45),
    DateTime.utc(2026, 8, 12, 17, 38),
    DateTime.utc(2026, 9, 11, 3, 28),
    DateTime.utc(2026, 10, 10, 15, 51),
    DateTime.utc(2026, 11, 9, 7, 4),
    DateTime.utc(2026, 12, 9, 0, 53),
  ];

  group('Verified precision against known past dates', () {
    final knownDates = {
      DateTime.utc(2000, 1, 6, 18, 14): 'Jan 2000 New Moon',
      DateTime.utc(2024, 1, 11, 11, 57): 'Jan 2024 New Moon',
      DateTime.utc(2024, 3, 10, 9, 0): 'Mar 2024 New Moon',
      DateTime.utc(2024, 7, 5, 22, 57): 'Jul 2024 New Moon',
      DateTime.utc(2024, 12, 1, 6, 21): 'Dec 2024 New Moon',
    };

    for (final entry in knownDates.entries) {
      test(entry.value, () {
        final actual = entry.key;
        final searchDate = actual.add(const Duration(days: 2));
        final computed = MoonPhase.findPreviousNewMoon(searchDate);
        final diffMinutes = (computed.difference(actual).inMinutes).abs();
        expect(diffMinutes, lessThan(5),
            reason: '${entry.value}: ${diffMinutes}min error (max 5min)');
      });
    }
  });

  group('findPreviousNewMoon consistency', () {
    for (int i = 0; i < newMoons2026.length; i++) {
      final expected = newMoons2026[i];
      test('${expected.month}月 New Moon', () {
        final searchDate = expected.add(const Duration(days: 5));
        final computed = MoonPhase.findPreviousNewMoon(searchDate);
        final diffMinutes = (computed.difference(expected).inMinutes).abs();
        expect(diffMinutes, lessThan(5));
      });
    }
  });

  group('findNextNewMoon consistency', () {
    for (int i = 0; i < newMoons2026.length - 1; i++) {
      test('${newMoons2026[i].month}月 → next', () {
        final searchDate = newMoons2026[i].add(const Duration(days: 1));
        final nextNew = MoonPhase.findNextNewMoon(searchDate);
        final expected = newMoons2026[i + 1];
        final diffMinutes = (nextNew.difference(expected).inMinutes).abs();
        expect(diffMinutes, lessThan(5));
      });
    }
  });

  group('Phase detection', () {
    test('New Moon day detection', () {
      // Jan 18, 2026 is a New Moon
      expect(MoonPhase.isNewMoon(DateTime.utc(2026, 1, 18, 20, 0)), isTrue);
      expect(MoonPhase.isNewMoon(DateTime.utc(2026, 1, 19, 12, 0)), isTrue);
      // 5 days later is NOT new moon
      expect(MoonPhase.isNewMoon(DateTime.utc(2026, 1, 23)), isFalse);
    });

    test('Full Moon day detection', () {
      // Feb 1-2, 2026 is Full Moon
      expect(MoonPhase.isFullMoon(DateTime.utc(2026, 2, 1, 22, 0)), isTrue);
      expect(MoonPhase.isFullMoon(DateTime.utc(2026, 2, 2, 12, 0)), isTrue);
      // 5 days later is NOT full moon
      expect(MoonPhase.isFullMoon(DateTime.utc(2026, 2, 7)), isFalse);
    });
  });

  group('Cycle management', () {
    test('Cycle ID matches new moon date', () {
      final date = DateTime.utc(2026, 1, 25);
      final id = MoonPhase.getCycleId(date);
      expect(id, equals('2026-01-18'));
    });

    test('Day index is within bounds', () {
      for (int d = 0; d < 29; d++) {
        final date = DateTime.utc(2026, 1, 19).add(Duration(days: d));
        final dayIdx = MoonPhase.getCurrentDayIndex(date);
        final total = MoonPhase.getCycleTotalDays(date);
        expect(dayIdx, greaterThanOrEqualTo(0));
        expect(dayIdx, lessThan(total));
      }
    });

    test('Total days is ~29-30', () {
      for (final nm in newMoons2026) {
        final mid = nm.add(const Duration(days: 10));
        final total = MoonPhase.getCycleTotalDays(mid);
        expect(total, inInclusiveRange(28, 31));
      }
    });

    test('Phase info returns valid data for all phases', () {
      for (int d = 0; d < 30; d++) {
        final date = DateTime.utc(2026, 1, 18).add(Duration(days: d));
        final info = MoonPhase.getPhaseInfo(date);
        expect(info.label, isNotEmpty);
        expect(info.labelJP, isNotEmpty);
        expect(info.emoji, isNotEmpty);
      }
    });

    test('Illumination ranges from ~0 to ~1 across a cycle', () {
      double minIllum = 1.0;
      double maxIllum = 0.0;
      for (int d = 0; d < 30; d++) {
        final date = DateTime.utc(2026, 1, 18).add(Duration(days: d));
        final illum = MoonPhase.getIllumination(date);
        expect(illum, greaterThanOrEqualTo(0.0));
        expect(illum, lessThanOrEqualTo(1.0));
        if (illum < minIllum) minIllum = illum;
        if (illum > maxIllum) maxIllum = illum;
      }
      // New moon should be near 0, full moon near 1
      expect(minIllum, lessThan(0.05));
      expect(maxIllum, greaterThan(0.95));
    });
  });
}
