/// Calendar helpers for task date ranges and invoice hints.
/// @docImport 'package:invoice_ninja_client/src/models/invoice.dart';
library;

export 'package:invoice_ninja_client/invoice_ninja_client.dart'
    show parseApiCalendarDate;

/// Date coverage derived from task time logs on an invoice.
class PreviousInvoiceDateHint {
  const PreviousInvoiceDateHint({
    required this.invoiceNumber,
    required this.invoiceId,
    required this.coverageMin,
    required this.coverageMax,
    this.suggestedRate,
    this.suggestedStartHour,
    this.suggestedEndHour,
  });

  final String invoiceNumber;
  final String invoiceId;
  final DateTime coverageMin;
  final DateTime coverageMax;

  /// From the first task line on the invoice (same order as line items).
  final double? suggestedRate;

  /// Local wall-clock hours inferred from the earliest `time_log` segment on
  /// the invoice.
  final int? suggestedStartHour;
  final int? suggestedEndHour;
}

(DateTime?, DateTime?) calendarBoundsFromTimeLogSeconds(
  List<List<int>> entries,
) {
  if (entries.isEmpty) return (null, null);
  DateTime? minD;
  DateTime? maxD;
  for (final e in entries) {
    if (e.length < 2) continue;
    final s = DateTime.fromMillisecondsSinceEpoch(e[0] * 1000);
    final en = DateTime.fromMillisecondsSinceEpoch(e[1] * 1000);
    final dayS = DateTime(s.year, s.month, s.day);
    final dayE = DateTime(en.year, en.month, en.day);
    minD = minD == null || dayS.isBefore(minD) ? dayS : minD;
    maxD = maxD == null || dayE.isAfter(maxD) ? dayE : maxD;
  }
  return (minD, maxD);
}

/// First weekday strictly after [day] (calendar date only).
DateTime nextWeekdayAfter(DateTime day) {
  var n = DateTime(day.year, day.month, day.day).add(const Duration(days: 1));
  while (n.weekday == DateTime.saturday || n.weekday == DateTime.sunday) {
    n = n.add(const Duration(days: 1));
  }
  return n;
}

DateTime todayLocal() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

String formatYmd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Strips time-of-day; use with [Invoice.date] / [Invoice.dueDate] from the API models.
DateTime? dateOnly(DateTime? d) =>
    d == null ? null : DateTime(d.year, d.month, d.day);

/// [ymd] must be `YYYY-MM-DD`. Adds [days] in calendar (local) terms.
String addCalendarDaysYmd(String ymd, int days) {
  final parsed = DateTime.parse(ymd);
  final base = DateTime(parsed.year, parsed.month, parsed.day);
  return formatYmd(base.add(Duration(days: days)));
}

/// If [suggestedStart] is after [end], use [end] so the default range is valid.
DateTime clampStartToEnd(DateTime suggestedStart, DateTime end) {
  return suggestedStart.isAfter(end) ? end : suggestedStart;
}
