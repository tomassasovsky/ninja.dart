import 'package:invoice_ninja_scripts/argentina_holidays.dart';
import 'package:invoice_ninja_scripts/argentina_holidays_remote.dart';
import 'package:test/test.dart';

void main() {
  setUp(clearArgentinaRemoteCalendarOverrides);

  test('parseArgentinaDatosFeriadosJson splits national vs puente', () {
    const sample = '''
[
  {"fecha": "2026-03-23", "tipo": "puente", "nombre": "x"},
  {"fecha": "2026-05-01", "tipo": "inamovible", "nombre": "y"},
  {"fecha": "2026-06-15", "tipo": "trasladable", "nombre": "z"}
]''';
    final parsed = parseArgentinaDatosFeriadosJson(sample);
    expect(parsed.tourism, {'2026-03-23'});
    expect(parsed.national, {'2026-05-01', '2026-06-15'});
  });

  test('applyArgentinaRemoteCalendarForYear overrides computed sets', () {
    applyArgentinaRemoteCalendarForYear(
      2099,
      nationalHolidayYmd: {'2099-06-01'},
      tourismPuenteYmd: {'2099-12-01'},
    );
    expect(argentinaNationalPublicHolidayYmdSet(2099), {'2099-06-01'});
    expect(argentinaTourismNonWorkingYmdSet(2099), {'2099-12-01'});
  });
}
