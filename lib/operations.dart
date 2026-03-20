import 'dart:convert';
import 'dart:io';

import 'package:invoice_ninja_client/invoice_ninja_client.dart';

import 'package:invoice_ninja_scripts/api_time.dart';
import 'package:invoice_ninja_scripts/date_hints.dart';
import 'package:invoice_ninja_scripts/invoice_line_notes.dart';
import 'package:invoice_ninja_scripts/task_invoice.dart';
import 'package:invoice_ninja_scripts/time_log.dart';

/// Shared API actions used by both `bin/` scripts and the interactive CLI.
class InvoiceNinjaOps {
  InvoiceNinjaOps(this._client);
  final InvoiceNinjaClient _client;

  Future<Client> createClient(String name) async {
    final res = await _client.clients.create({
      'name': name,
      'contacts': [<String, dynamic>{}],
    });
    return res;
  }

  Future<Project> createProject({
    required String clientId,
    required String name,
    double taskRate = 0,
  }) async {
    final res = await _client.projects.create({
      'name': name,
      'client_id': clientId,
      'task_rate': taskRate,
    });
    return res;
  }

  Future<User> lookupUser({
    required String firstName,
    required String lastName,
  }) => _client.users.findByName(firstName, lastName);

  /// Most recently updated task on [projectId] with a non-empty `description`.
  /// Used as the default when creating another task on the same project.
  Future<String?> latestTaskDescriptionForProject(String projectId) async {
    final tasks = await _client.tasks.listAll();
    final filtered = tasks.where((t) => t.projectId == projectId).toList();
    if (filtered.isEmpty) return null;
    filtered.sort((a, b) => taskSortTime(b).compareTo(taskSortTime(a)));
    for (final t in filtered) {
      final d = t.description;
      if (d != null && d.trim().isNotEmpty) return d.trim();
    }
    return null;
  }

  Future<Task> createTask({
    required String clientId,
    required String projectId,
    required String assignedUserId,
    required String description,
    required double rate,
    required List<(DateTime, DateTime)> ranges,
    required int startHour,
    required int endHour,
  }) async {
    final timeLog = buildWeekdayTimeLog(
      ranges: ranges,
      startHour: startHour,
      endHour: endHour,
    );
    final res = await _client.tasks.create({
      'client_id': clientId,
      'project_id': projectId,
      'assigned_user_id': assignedUserId,
      'description': description,
      'rate': rate,
      'time_log': jsonEncode(timeLog),
    });
    return res;
  }

  /// Draft invoice with a task line item (see README if your instance needs
  /// extra fields).
  ///
  /// [dateYmd] defaults to today (local). [dueDateYmd] defaults from
  /// [previousInvoiceDueDateOffsetDaysForClient] when omitted or blank.
  Future<Invoice> invoiceFromTask({
    required String taskId,
    String? clientId,
    int typeId = 2,
    int statusId = 1,
    String? publicNotes,
    String? lineJsonFilePath,
    String? dateYmd,
    String? dueDateYmd,
  }) async {
    final task = await _client.tasks.get(taskId);

    final resolvedClientId = (clientId != null && clientId.trim().isNotEmpty)
        ? clientId.trim()
        : task.clientId;
    if (resolvedClientId == null || resolvedClientId.isEmpty) {
      throw StateError('Task has no client_id; provide clientId');
    }

    final rate = task.rate;
    final hours = billableHoursFromTask(task);
    if (hours <= 0) {
      throw StateError('Task has 0 billable hours (duration/time_log).');
    }

    if (taskHasInvoiceId(task)) {
      throw StateError(
        'Task is already invoiced (invoice_id=${task.invoiceId}).',
      );
    }

    final serviceName = invoiceServiceNameFromTask(task);
    final lineNotes = invoiceLineDescriptionFromTask(task);

    var lineItem = <String, dynamic>{
      'type_id': typeId,
      'task_id': taskId,
      'quantity': hours,
      'cost': rate,
      'notes': lineNotes,
      'product_key': serviceName,
    };

    if (lineJsonFilePath != null && lineJsonFilePath.isNotEmpty) {
      final extra =
          jsonDecode(File(lineJsonFilePath).readAsStringSync())
              as Map<String, dynamic>;
      lineItem = {...lineItem, ...extra, 'task_id': taskId};
    }

    final body = <String, dynamic>{
      'client_id': resolvedClientId,
      'status_id': statusId,
      'line_items': [lineItem],
    };
    if (publicNotes != null && publicNotes.isNotEmpty) {
      body['public_notes'] = publicNotes;
    }

    final invoiceDateYmd = (dateYmd != null && dateYmd.trim().isNotEmpty)
        ? dateYmd.trim()
        : formatYmd(todayLocal());
    var dueResolved = (dueDateYmd != null && dueDateYmd.trim().isNotEmpty)
        ? dueDateYmd.trim()
        : null;
    if (dueResolved == null) {
      final offsetDays = await previousInvoiceDueDateOffsetDaysForClient(
        resolvedClientId,
      );
      if (offsetDays != null) {
        dueResolved = addCalendarDaysYmd(invoiceDateYmd, offsetDays);
      }
    }
    if (dueResolved != null && dueResolved.isNotEmpty) {
      body['date'] = invoiceDateYmd;
      body['due_date'] = dueResolved;
    }

    return _client.invoices.create(body);
  }

  /// Sends the invoice email via `POST /api/v1/invoices/bulk` (`action: email`).
  /// The server emails every invitation on the invoice (one email per
  /// invitation).
  Future<void> sendInvoiceEmail(String invoiceId) async {
    await _client.invoices.bulkEmail([invoiceId]);
  }

  /// Most recently updated invoice for [clientId] that includes task line
  /// items; coverage [PreviousInvoiceDateHint.coverageMin]–
  /// [PreviousInvoiceDateHint.coverageMax] from those tasks' `time_log`
  /// (calendar days), plus [PreviousInvoiceDateHint.suggestedRate] / suggested hours from those tasks.
  Future<PreviousInvoiceDateHint?> previousInvoiceDateHintForClient(
    String clientId,
  ) async {
    final invoices = await _client.invoices.listAll();
    final forClient = invoices.where((i) => i.clientId == clientId).toList()
      ..sort((a, b) => invoiceSortTime(b).compareTo(invoiceSortTime(a)));
    for (final inv in forClient) {
      final id = inv.id;
      if (id.isEmpty) continue;
      final full = await _client.invoices.get(id);
      final taskIds = <String>[];
      final seen = <String>{};
      for (final item in full.lineItems) {
        final tid = item.taskId;
        if (tid != null && tid.isNotEmpty && seen.add(tid)) taskIds.add(tid);
      }
      if (taskIds.isEmpty) continue;
      DateTime? minDay;
      DateTime? maxDay;
      final allSegments = <List<int>>[];
      double? firstTaskRate;
      for (final tid in taskIds) {
        final t = await _client.tasks.get(tid);
        final tl = timeLogEntryToSecondPairs(t.timeLog);
        allSegments.addAll(tl);
        firstTaskRate ??= t.rate;
        final (mn, mx) = calendarBoundsFromTimeLogSeconds(tl);
        if (mn != null && (minDay == null || mn.isBefore(minDay))) {
          minDay = mn;
        }
        if (mx != null && (maxDay == null || mx.isAfter(maxDay))) {
          maxDay = mx;
        }
      }
      if (minDay == null || maxDay == null) continue;
      final invoiceNum = full.number ?? '?';
      final hours = localHoursFromTimeLogEarliestSegment(allSegments);
      return PreviousInvoiceDateHint(
        invoiceNumber: invoiceNum,
        invoiceId: id,
        coverageMin: minDay,
        coverageMax: maxDay,
        suggestedRate: firstTaskRate,
        suggestedStartHour: hours != null ? hours[0] : null,
        suggestedEndHour: hours != null ? hours[1] : null,
      );
    }
    return null;
  }

  /// Calendar days between `due_date` and `date` on the client's most recently
  /// updated invoice (full GET), or `null` if none have both fields.
  Future<int?> previousInvoiceDueDateOffsetDaysForClient(
    String clientId,
  ) async {
    final invoices = await _client.invoices.listAll();
    final forClient = invoices.where((i) => i.clientId == clientId).toList()
      ..sort((a, b) => invoiceSortTime(b).compareTo(invoiceSortTime(a)));
    for (final inv in forClient) {
      final id = inv.id;
      if (id.isEmpty) continue;
      final full = await _client.invoices.get(id);
      final invoiceDay = dateOnly(full.date);
      final dueDay = dateOnly(full.dueDate);
      if (invoiceDay == null || dueDay == null) continue;
      return dueDay.difference(invoiceDay).inDays;
    }
    return null;
  }
}
