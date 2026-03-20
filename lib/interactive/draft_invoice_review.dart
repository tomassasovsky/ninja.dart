import 'package:invoice_ninja_client/invoice_ninja_client.dart';
import 'package:invoice_ninja_scripts/date_hints.dart';
import 'package:invoice_ninja_scripts/invoice_line_notes.dart';
import 'package:invoice_ninja_scripts/operations.dart';
import 'package:mason_logger/mason_logger.dart';

enum _EmailNextStep {
  /// Do not send.
  skip,

  /// `POST /api/v1/invoices/bulk` with `action: email`.
  sendViaApi,
}

String _invoiceStatusLabel(int? statusId) {
  switch (statusId) {
    case 1:
      return 'Draft';
    case 2:
      return 'Sent';
    case 3:
      return 'Partial';
    case 4:
      return 'Paid';
    case -1:
      return 'Archived';
    default:
      return statusId == null ? '—' : 'status_id=$statusId';
  }
}

String? _ymd(DateTime? d) => d == null ? null : formatYmd(d);

String _money(double? v) {
  if (v == null) return '—';
  final s = v.toStringAsFixed(2);
  if (s.endsWith('.00')) return s.substring(0, s.length - 3);
  return s;
}

ClientContact? _contactFor(String? contactId, Client client) {
  if (contactId == null || contactId.isEmpty) return null;
  for (final c in client.contacts) {
    if (c.id == contactId) return c;
  }
  return null;
}

String _describeInvitation(InvoiceInvitation inv, Client client) {
  final match = _contactFor(inv.clientContactId, client);
  if (match != null) {
    final em = match.email?.trim();
    final primary = (match.isPrimary ?? false) ? ' [primary]' : '';
    if (em != null && em.isNotEmpty) {
      return '${match.displayName} <$em>$primary';
    }
    return '${match.displayName} (no email on file)$primary';
  }
  final link = inv.link?.trim();
  if (link != null && link.isNotEmpty) {
    return 'Invitation ${inv.id}  portal: $link';
  }
  return 'Invitation ${inv.id}  contact_id=${inv.clientContactId ?? "—"}';
}

double? _lineItemTotal(InvoiceLineItem line) {
  if (line.lineTotal != null) return line.lineTotal;
  final q = line.quantity;
  final c = line.cost;
  if (q == null || c == null) return null;
  return q * c;
}

/// Prints [InvoiceLineItem.notes] line-by-line (e.g. per-day hours from task
/// time logs).
void _logLineItemNotes(Logger log, InvoiceLineItem line) {
  final raw = line.notes?.trim();
  if (raw == null || raw.isEmpty) return;
  final lines = raw
      .split(RegExp(r'\r?\n'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (lines.isEmpty) return;

  final header = line.typeId == 2 ? 'Time (by day)' : 'Notes';
  log.info('     $header:');
  for (final ln in lines) {
    log.info('       $ln');
  }
}

/// Prints a full draft summary and asks whether to send invoice emails.
Future<void> reviewDraftInvoiceAndMaybeSendEmail({
  required Logger log,
  required InvoiceNinjaOps ops,
  required Invoice invoice,
  required Client client,
  required Task task,
}) async {
  log
    ..info('')
    ..info('────────── Draft invoice (review) ──────────')
    ..info('Number     ${invoice.number ?? "—"}')
    ..info('ID         ${invoice.id}')
    ..info('Status     ${_invoiceStatusLabel(invoice.statusId)}')
    ..info('Amount     ${_money(invoice.amount)}')
    ..info('Balance    ${_money(invoice.balance)}')
    ..info('Invoice    ${_ymd(invoice.date) ?? "—"}')
    ..info('Due        ${_ymd(invoice.dueDate) ?? "—"}')
    ..info('Client     ${client.name ?? "—"}  (#${client.number ?? "—"})');
  if (invoice.publicNotes != null && invoice.publicNotes!.trim().isNotEmpty) {
    log
      ..info('Public notes:')
      ..info(invoice.publicNotes!.trim());
  }
  if (invoice.privateNotes != null && invoice.privateNotes!.trim().isNotEmpty) {
    log.detail('Private notes: ${invoice.privateNotes!.trim()}');
  }

  log
    ..info('')
    ..info('Line items:');
  var i = 0;
  for (final line in invoice.lineItems) {
    i++;
    final title = (line.productKey?.trim().isNotEmpty ?? false)
        ? line.productKey!.trim()
        : 'Line $i';
    final qty = line.quantity;
    final cost = line.cost;
    final total = _lineItemTotal(line);
    final typeLabel = switch (line.typeId) {
      1 => 'product',
      2 => 'task',
      _ => 'type_${line.typeId ?? "?"}',
    };
    log.info(
      '  $i. $title  [$typeLabel]  '
      '${qty ?? "—"} × ${_money(cost)} ${_money(total)}',
    );
    _logLineItemNotes(log, line);
  }

  log.info('');
  final desc = task.description ?? '';
  final title = invoiceTitleFromTaskDescription(desc);
  log.info('Task       #${task.number ?? "?"} — $title');
  if (task.id.isNotEmpty) {
    log.detail('Task id    ${task.id}');
  }

  log
    ..info('')
    ..info('Email / portal (invoice invitations):');
  if (invoice.invitations.isEmpty) {
    log.warn(
      '  No invitations on this invoice yet — '
      'email may not be deliverable until the server creates them.',
    );
  } else {
    for (final inv in invoice.invitations) {
      log.info('  • ${_describeInvitation(inv, client)}');
    }
    log.detail(
      'Invoice Ninja sends one email per invitation above when you choose '
      '"Send via API".',
    );
  }

  log
    ..info('──────────────────────────────────────────────')
    ..info('');

  final step = log.chooseOne<_EmailNextStep>(
    'Send invoice email?',
    choices: const [_EmailNextStep.skip, _EmailNextStep.sendViaApi],
    display: (s) => switch (s) {
      _EmailNextStep.skip => 'No — keep as draft (no email)',
      _EmailNextStep.sendViaApi =>
        'Yes — send email now (all invitations above)',
    },
  );

  switch (step) {
    case _EmailNextStep.skip:
      log.info('Skipping email.');
    case _EmailNextStep.sendViaApi:
      if (invoice.invitations.isEmpty) {
        log.warn(
          'No invitations — cannot send email via API. '
          'Open the invoice in the app or retry after a refresh.',
        );
        return;
      }
      final progress = log.progress('Sending invoice email');
      try {
        await ops.sendInvoiceEmail(invoice.id);
      } finally {
        progress.complete();
      }
      log.success('Email queued for sending (invoice id=${invoice.id}).');
  }
}
