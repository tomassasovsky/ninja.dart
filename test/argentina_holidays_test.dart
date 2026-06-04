import 'package:invoice_ninja_scripts/argentina_holidays.dart';
import 'package:test/test.dart';

void main() {
  setUp(clearArgentinaRemoteCalendarOverrides);

  test('Easter 2026 is April 5 (official calendar)', () {
    expect(argentinaEasterSunday(2026), DateTime(2026, 4, 5));
  });

  test('Güemes trasladable 2026 is June 15 (nominal June 17 Wed)', () {
    final set = argentinaNationalPublicHolidayYmdSet(2026);
    expect(set.contains('2026-06-15'), isTrue);
    expect(set.contains('2026-06-17'), isFalse);
  });

  test('tourism bridges 2026 from decree', () {
    final t = argentinaTourismNonWorkingYmdSet(2026);
    expect(t, containsAll(['2026-03-23', '2026-07-10', '2026-12-07']));
  });
}
