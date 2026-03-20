import 'package:invoice_ninja_client/invoice_ninja_client.dart';

/// Builds `[[startUnix, endUnix], ...]` for weekdays between [ranges]
/// inclusive, [startHour]–[endHour] local time each day.
List<List<int>> buildWeekdayTimeLog({
  required List<(DateTime, DateTime)> ranges,
  required int startHour,
  required int endHour,
}) {
  final entries = <List<int>>[];
  for (final (from, to) in ranges) {
    var d = from;
    while (!d.isAfter(to)) {
      if (d.weekday <= DateTime.friday) {
        entries.add([
          DateTime(d.year, d.month, d.day, startHour).millisecondsSinceEpoch ~/
              1000,
          DateTime(d.year, d.month, d.day, endHour).millisecondsSinceEpoch ~/
              1000,
        ]);
      }
      d = d.add(const Duration(days: 1));
    }
  }
  return entries;
}

/// Total hours represented by [timeLog] entries (each entry is [start, end]
/// Unix seconds).
double hoursFromTimeLogEntries(List<List<int>> timeLog) {
  var secs = 0;
  for (final e in timeLog) {
    if (e.length >= 2) secs += e[1] - e[0];
  }
  return secs / 3600.0;
}

/// Local wall-clock hours from the first segment in [entries] (after sorting by
/// start time), typically the earliest work block on an invoice.
///
/// Returns `null` if [entries] is empty or invalid.
List<int>? localHoursFromTimeLogEarliestSegment(List<List<int>> entries) {
  if (entries.isEmpty) return null;
  final sorted = [...entries]..sort((a, b) => a[0].compareTo(b[0]));
  final e = sorted.first;
  if (e.length < 2 || e[1] <= e[0]) return null;
  final s = DateTime.fromMillisecondsSinceEpoch(e[0] * 1000);
  final en = DateTime.fromMillisecondsSinceEpoch(e[1] * 1000);
  return [s.hour, en.hour];
}

/// Billable hours from a task (`duration` in seconds, or sum of `time_log`).
double billableHoursFromTask(Task task) {
  final duration = task.duration;
  if (duration != null && duration > 0) {
    return duration / 3600.0;
  }
  return hoursFromTimeLogEntries(timeLogEntryToSecondPairs(task.timeLog));
}
