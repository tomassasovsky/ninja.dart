import 'package:invoice_ninja_client/invoice_ninja_client.dart';
import 'package:invoice_ninja_scripts/date_hints.dart';
import 'package:invoice_ninja_scripts/interactive/pickers.dart';
import 'package:invoice_ninja_scripts/interactive/prompt_helpers.dart';
import 'package:invoice_ninja_scripts/operations.dart';
import 'package:mason_logger/mason_logger.dart';

Future<String> _promptTaskDescription(
  Logger log,
  InvoiceNinjaOps ops,
  String projectId,
) async {
  final progress = log.progress(
    'Loading latest task description for this project',
  );
  String? apiDefault;
  try {
    apiDefault = await ops.latestTaskDescriptionForProject(projectId);
  } finally {
    progress.complete();
  }
  if (apiDefault != null && apiDefault.isNotEmpty) {
    log
      ..success(
        'Previous task on this project — press '
        'Enter to reuse, or type new text:',
      )
      ..info(apiDefault);
  } else {
    log.info('No previous task with a description on this project yet.');
  }
  while (true) {
    final s = log.prompt(
      'Task description',
      defaultValue: (apiDefault != null && apiDefault.isNotEmpty)
          ? apiDefault
          : null,
    );
    final trimmed = s.trim();
    if (trimmed.isNotEmpty) return trimmed;
    log.warn('Description cannot be empty.');
  }
}

/// Interactive: create a task with weekday time logs.
Future<void> runCreateTaskFlow(
  Logger log,
  InvoiceNinjaOps ops,
  InvoiceNinjaClient client,
) async {
  final c = await pickClient(client, log);
  if (c == null) return;
  final clientId = c.id;

  final proj = await pickProjectForClient(client, log, clientId);
  if (proj == null) return;
  final projectId = proj.id;

  final u = await pickUser(client, log);
  if (u == null) return;
  final userId = u.id;

  final description = await _promptTaskDescription(log, ops, projectId);

  PreviousInvoiceDateHint? invHint;
  final hintProgress = log.progress(
    'Loading last invoice (dates, rate, hours)',
  );
  try {
    invHint = await ops.previousInvoiceDateHintForClient(clientId);
  } finally {
    hintProgress.complete();
  }
  final today = todayLocal();
  if (invHint != null) {
    log.info(
      'Last invoice #${invHint.invoiceNumber} — calendar days covered by '
      'tasks on that invoice (from time logs): '
      '${formatYmd(invHint.coverageMin)} → ${formatYmd(invHint.coverageMax)}.',
    );
    final suggested = clampStartToEnd(
      nextWeekdayAfter(invHint.coverageMax),
      today,
    );
    log.detail(
      'Suggested first range start (next weekday after that coverage, '
      'clamped to today if needed): ${formatYmd(suggested)}.',
    );
    if (invHint.suggestedRate != null ||
        invHint.suggestedStartHour != null ||
        invHint.suggestedEndHour != null) {
      log.detail(
        'Defaults from that invoice: rate=${invHint.suggestedRate ?? '—'}  '
        'hours=${invHint.suggestedStartHour ?? '—'}'
        '–${invHint.suggestedEndHour ?? '—'} '
        '(local, from earliest time_log segment).',
      );
    }
  } else {
    log.info(
      'No invoice with task line items found for this client — '
      'using built-in defaults for rate, hours, and first date range.',
    );
  }

  final rate = promptDouble(
    log,
    'Hourly rate',
    defaultValue: invHint?.suggestedRate ?? 0,
  );
  final startHour = promptInt(
    log,
    'Start hour (local)',
    defaultValue: invHint?.suggestedStartHour ?? 9,
  );
  final endHour = promptInt(
    log,
    'End hour (local)',
    defaultValue: invHint?.suggestedEndHour ?? 17,
  );

  final ranges = <(DateTime, DateTime)>[];
  log.info(
    'Date ranges (weekdays only; inclusive YYYY-MM-DD). '
    'Blank start when done.',
  );
  var firstRange = true;
  while (true) {
    final String? startDefault;
    if (firstRange) {
      if (invHint != null) {
        startDefault = formatYmd(
          clampStartToEnd(nextWeekdayAfter(invHint.coverageMax), today),
        );
      } else {
        startDefault = formatYmd(today);
      }
    } else {
      startDefault = null;
    }

    final from = log.prompt(
      'Range start YYYY-MM-DD (blank when done)',
      defaultValue: startDefault,
    );
    if (from.trim().isEmpty) break;

    final to = log.prompt(
      'Range end YYYY-MM-DD',
      defaultValue: firstRange ? formatYmd(today) : null,
    );
    try {
      final a = DateTime.parse(from.trim());
      final b = DateTime.parse(to.trim());
      ranges.add((a, b));
      firstRange = false;
    } catch (_) {
      log.warn('Invalid date(s), try again.');
    }
  }

  if (ranges.isEmpty) {
    log.warn('No ranges — cancelled.');
    return;
  }

  final progress = log.progress('Creating task');
  final data = await ops.createTask(
    clientId: clientId,
    projectId: projectId,
    assignedUserId: userId,
    description: description,
    rate: rate,
    ranges: ranges,
    startHour: startHour,
    endHour: endHour,
  );
  progress.complete('Created');
  log.success('task id=${data.id}  number=${data.number}');
}
