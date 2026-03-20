import 'package:invoice_ninja_scripts/date_hints.dart';
import 'package:test/test.dart';

void main() {
  group('nextWeekdayAfter', () {
    test('skips weekend after Friday', () {
      final fri = DateTime(2026, 3, 13); // Friday
      final mon = nextWeekdayAfter(fri);
      expect(mon.weekday, DateTime.monday);
      expect(mon, DateTime(2026, 3, 16));
    });

    test('Monday after Sunday', () {
      final sun = DateTime(2026, 3, 15);
      final mon = nextWeekdayAfter(sun);
      expect(mon, DateTime(2026, 3, 16));
    });
  });

  group('clampStartToEnd', () {
    test('returns start when not after end', () {
      final start = DateTime(2026, 3, 10);
      final end = DateTime(2026, 3, 20);
      expect(clampStartToEnd(start, end), start);
    });

    test('clamps to end when start is after end', () {
      final start = DateTime(2026, 3, 25);
      final end = DateTime(2026, 3, 20);
      expect(clampStartToEnd(start, end), end);
    });
  });

  group('parseApiCalendarDate / addCalendarDaysYmd', () {
    test('parses YYYY-MM-DD', () {
      expect(parseApiCalendarDate('2026-03-16'), DateTime(2026, 3, 16));
    });

    test('addCalendarDaysYmd', () {
      expect(addCalendarDaysYmd('2026-03-16', 7), '2026-03-23');
    });
  });

  group('calendarBoundsFromTimeLogSeconds', () {
    test('returns min/max calendar days (local)', () {
      final startSec = DateTime(2026, 3, 10, 12).millisecondsSinceEpoch ~/ 1000;
      final endSec = DateTime(2026, 3, 12, 15).millisecondsSinceEpoch ~/ 1000;
      final (min, max) = calendarBoundsFromTimeLogSeconds([
        [startSec, endSec],
      ]);
      expect(min, DateTime(2026, 3, 10));
      expect(max, DateTime(2026, 3, 12));
    });
  });
}
