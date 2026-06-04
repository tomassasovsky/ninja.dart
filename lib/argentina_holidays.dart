/// Argentina national calendar: feriados inamovibles, trasladables
/// (Ley 27.399), Carnival and Good Friday (Gregorian Easter), and decreed
/// tourism non-working days (días no laborables con fines turísticos) when
/// published per year.
library;

/// Western (Gregorian) Easter Sunday for [year] (algorithm Meeus/Jones/Butcher).
DateTime argentinaEasterSunday(int year) {
  final a = year % 19;
  final b = year ~/ 100;
  final c = year % 100;
  final d = b ~/ 4;
  final e = b % 4;
  final f = (b + 8) ~/ 25;
  final g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4;
  final k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final day = ((h + l - 7 * m + 114) % 31) + 1;
  return DateTime(year, month, day);
}

/// Nominal commemoration date moved to the observed Monday (Ley 27.399).
DateTime _trasladableObservedMonday(DateTime nominal) {
  final w = nominal.weekday;
  if (w == DateTime.monday) return nominal;
  if (w == DateTime.tuesday) return nominal.subtract(const Duration(days: 1));
  if (w == DateTime.wednesday) {
    return nominal.subtract(const Duration(days: 2));
  }
  if (w == DateTime.thursday) return nominal.add(const Duration(days: 4));
  if (w == DateTime.friday) return nominal.add(const Duration(days: 3));
  if (w == DateTime.saturday) return nominal.add(const Duration(days: 2));
  if (w == DateTime.sunday) return nominal.add(const Duration(days: 1));
  throw ArgumentError.value(w, 'weekday', 'expected 1–7');
}

void _addYmd(Set<String> out, int y, int m, int d) {
  out.add(
    '${y.toString().padLeft(4, '0')}-'
    '${m.toString().padLeft(2, '0')}-'
    '${d.toString().padLeft(2, '0')}',
  );
}

/// When set by [applyArgentinaRemoteCalendarForYear] (remote JSON refresh),
/// replaces the computed national holiday set for that year.
final Map<int, Set<String>> _remoteNationalByYear = {};

/// When set by [applyArgentinaRemoteCalendarForYear], replaces embedded
/// tourism bridge dates for that year.
final Map<int, Set<String>> _remoteTourismByYear = {};

/// Applies HTTP-fetched calendar data for [year] (national vs puente/tourism).
void applyArgentinaRemoteCalendarForYear(
  int year, {
  required Set<String> nationalHolidayYmd,
  required Set<String> tourismPuenteYmd,
}) {
  _remoteNationalByYear[year] = Set<String>.from(nationalHolidayYmd);
  _remoteTourismByYear[year] = Set<String>.from(tourismPuenteYmd);
}

/// Clears remote overrides (e.g. after tests).
void clearArgentinaRemoteCalendarOverrides() {
  _remoteNationalByYear.clear();
  _remoteTourismByYear.clear();
}

/// Feriados nacionales (inamovibles + trasladables + movable religious) for
/// [year], as `YYYY-MM-DD` (Argentina local calendar dates).
Set<String> argentinaNationalPublicHolidayYmdSet(int year) {
  final remote = _remoteNationalByYear[year];
  if (remote != null) return Set<String>.from(remote);

  final out = <String>{};

  // Inamovibles (fixed calendar day).
  _addYmd(out, year, 1, 1);
  _addYmd(out, year, 3, 24);
  _addYmd(out, year, 4, 2);
  _addYmd(out, year, 5, 1);
  _addYmd(out, year, 5, 25);
  _addYmd(out, year, 6, 20);
  _addYmd(out, year, 7, 9);
  _addYmd(out, year, 12, 8);
  _addYmd(out, year, 12, 25);

  final easter = argentinaEasterSunday(year);
  // Carnival Monday & Tuesday (48 and 47 days before Easter Sunday).
  final carnivalMon = easter.subtract(const Duration(days: 48));
  final carnivalTue = easter.subtract(const Duration(days: 47));
  _addYmd(out, carnivalMon.year, carnivalMon.month, carnivalMon.day);
  _addYmd(out, carnivalTue.year, carnivalTue.month, carnivalTue.day);

  // Viernes Santo.
  final goodFriday = easter.subtract(const Duration(days: 2));
  _addYmd(out, goodFriday.year, goodFriday.month, goodFriday.day);

  // Trasladables (observed Monday).
  final gue = _trasladableObservedMonday(DateTime(year, 6, 17));
  _addYmd(out, gue.year, gue.month, gue.day);
  final san = _trasladableObservedMonday(DateTime(year, 8, 17));
  _addYmd(out, san.year, san.month, san.day);
  final div = _trasladableObservedMonday(DateTime(year, 10, 12));
  _addYmd(out, div.year, div.month, div.day);
  final sob = _trasladableObservedMonday(DateTime(year, 11, 20));
  _addYmd(out, sob.year, sob.month, sob.day);

  return out;
}

/// Decreed tourism non-working days (`YYYY-MM-DD`) when known; other years
/// return an empty set (add new years when the Boletín Oficial publishes them).
Set<String> argentinaTourismNonWorkingYmdSet(int year) {
  final remote = _remoteTourismByYear[year];
  if (remote != null) return Set<String>.from(remote);
  return _tourismByYear[year] ?? <String>{};
}

/// Per Resolución 164/2025 (Boletín Oficial) and prior decrees — extend when new
/// years are published.
const _tourismByYear = <int, Set<String>>{
  2026: {'2026-03-23', '2026-07-10', '2026-12-07'},
};

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Calendar date [d] (time-of-day ignored) is a national public holiday.
bool isArgentinaNationalPublicHoliday(DateTime d) {
  final key = _ymd(DateTime(d.year, d.month, d.day));
  return argentinaNationalPublicHolidayYmdSet(d.year).contains(key);
}

/// Tourism bridge day (día no laborable con fines turísticos), if decreed for
/// [d]'s year.
bool isArgentinaTourismNonWorkingDay(DateTime d) {
  final key = _ymd(DateTime(d.year, d.month, d.day));
  return argentinaTourismNonWorkingYmdSet(d.year).contains(key);
}

/// True for Saturday/Sunday, national holidays, and optionally tourism bridges.
bool isArgentinaOfficialNonWorkingDay(
  DateTime d, {
  bool includeTourismBridges = true,
}) {
  final day = DateTime(d.year, d.month, d.day);
  if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
    return true;
  }
  if (isArgentinaNationalPublicHoliday(day)) return true;
  if (includeTourismBridges && isArgentinaTourismNonWorkingDay(day)) {
    return true;
  }
  return false;
}

/// Weekday that is not a national holiday or (when enabled) tourism bridge.
bool isArgentinaBusinessDay(
  DateTime d, {
  bool includeTourismBridges = true,
}) {
  return !isArgentinaOfficialNonWorkingDay(
    d,
    includeTourismBridges: includeTourismBridges,
  );
}
