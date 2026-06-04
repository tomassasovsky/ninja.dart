import 'package:invoice_ninja_client/invoice_ninja_client.dart';
import 'package:invoice_ninja_scripts/argentina_holidays.dart';
import 'package:invoice_ninja_scripts/time_log.dart';
import 'package:test/test.dart';

void main() {
  setUp(clearArgentinaRemoteCalendarOverrides);

  test('buildWeekdayTimeLog skips weekends', () {
    final log = buildWeekdayTimeLog(
      ranges: [(DateTime(2026, 2, 2), DateTime(2026, 2, 8))],
      startHour: 9,
      endHour: 17,
      useArgentinaOfficialCalendar: false,
    );
    // Mon 2 Feb – Sun 8 Feb → 5 weekdays
    expect(log.length, 5);
  });

  test('buildWeekdayTimeLog skips Argentina Carnival 2026', () {
    // Mon 16–Tue 17 Carnival; Wed 18 is first business day in range.
    final log = buildWeekdayTimeLog(
      ranges: [(DateTime(2026, 2, 16), DateTime(2026, 2, 18))],
      startHour: 9,
      endHour: 17,
    );
    expect(log.length, 1);
  });

  test('billableHoursFromTask sums time_log tuples', () {
    final task = Task.fromJson({
      'id': 't',
      'duration': 0,
      'time_log': '[[1000,10000,"",true],[10000,19000,"",true]]', // seconds
    });
    expect(billableHoursFromTask(task), closeTo(5.0, 0.001));
  });

  test('localHoursFromTimeLogEarliestSegment uses earliest segment', () {
    final late = DateTime(2026, 3, 20, 9).millisecondsSinceEpoch ~/ 1000;
    final lateEnd = DateTime(2026, 3, 20, 17).millisecondsSinceEpoch ~/ 1000;
    final early = DateTime(2026, 3, 10, 8).millisecondsSinceEpoch ~/ 1000;
    final earlyEnd = DateTime(2026, 3, 10, 16).millisecondsSinceEpoch ~/ 1000;
    final h = localHoursFromTimeLogEarliestSegment([
      [late, lateEnd],
      [early, earlyEnd],
    ]);
    expect(h, [8, 16]);
  });
}
