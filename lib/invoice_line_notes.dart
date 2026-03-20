/// Formats draft invoice line `notes` for task lines — see repo `format`
/// sample.
library;

import 'package:invoice_ninja_client/invoice_ninja_client.dart';

const _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Visible title: text before any `<div` (Invoice Ninja HTML in descriptions).
/// Trims; if empty returns [fallback].
String invoiceTitleFromTaskDescription(String raw, {String fallback = 'Task'}) {
  final idx = raw.toLowerCase().indexOf('<div');
  final title = (idx >= 0 ? raw.substring(0, idx) : raw).trim();
  return title.isEmpty ? fallback : title;
}

String _formatInvoiceDate(DateTime d) =>
    '${_months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';

String _formatHoursLabel(double hours) {
  final r = hours.round();
  if ((hours - r).abs() < 1e-9) return '${r}hs';
  return '${hours.toStringAsFixed(1)}hs';
}

/// Splits [startSec]–[endSec] across local calendar days and adds hours to
/// [byDay].
void addBillableHoursByDay(
  Map<DateTime, double> byDay,
  int startSec,
  int endSec,
) {
  if (endSec <= startSec) return;
  final start = DateTime.fromMillisecondsSinceEpoch(startSec * 1000);
  final end = DateTime.fromMillisecondsSinceEpoch(endSec * 1000);
  final startDay = DateTime(start.year, start.month, start.day);
  final endDay = DateTime(end.year, end.month, end.day);
  if (startDay == endDay) {
    byDay[startDay] = (byDay[startDay] ?? 0) + (endSec - startSec) / 3600.0;
    return;
  }
  final midnight = startDay.add(const Duration(days: 1));
  final splitSec =
      (midnight.millisecondsSinceEpoch - start.millisecondsSinceEpoch) ~/ 1000;
  addBillableHoursByDay(byDay, startSec, startSec + splitSec);
  addBillableHoursByDay(byDay, startSec + splitSec, endSec);
}

/// Per-day hours from [timeLog] entries (local calendar days).
Map<DateTime, double> billableHoursByDayFromTimeLog(List<List<int>> timeLog) {
  final byDay = <DateTime, double>{};
  for (final e in timeLog) {
    if (e.length < 2) continue;
    addBillableHoursByDay(byDay, e[0], e[1]);
  }
  return byDay;
}

/// **Description** column only: one line per local calendar day
/// (`Mar 16, 2026 8hs`).
///
/// Invoice Ninja shows **Service** separately — use
/// [invoiceServiceNameFromTask] for `product_key`.
String formatInvoiceLineDescriptionBodyFromTimeLog(List<List<int>> timeLog) {
  final byDay = billableHoursByDayFromTimeLog(timeLog);
  final days = byDay.keys.toList()..sort();
  return days
      .map((d) => '${_formatInvoiceDate(d)} ${_formatHoursLabel(byDay[d]!)}')
      .join('\n');
}

/// **Service** column (`product_key`): plain title from task `description`
/// (before `<div`).
String invoiceServiceNameFromTask(Task task) {
  final desc = task.description ?? '';
  return invoiceTitleFromTaskDescription(desc);
}

/// **Description** column (`notes`): daily lines from `time_log` only.
String invoiceLineDescriptionFromTask(Task task) {
  return formatInvoiceLineDescriptionBodyFromTimeLog(
    timeLogEntryToSecondPairs(task.timeLog),
  );
}
