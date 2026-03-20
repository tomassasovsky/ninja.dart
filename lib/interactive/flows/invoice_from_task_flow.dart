import 'package:invoice_ninja_client/invoice_ninja_client.dart';
import 'package:invoice_ninja_scripts/date_hints.dart';
import 'package:invoice_ninja_scripts/interactive/draft_invoice_review.dart';
import 'package:invoice_ninja_scripts/interactive/pickers.dart';
import 'package:invoice_ninja_scripts/interactive/prompt_helpers.dart';
import 'package:invoice_ninja_scripts/operations.dart';
import 'package:mason_logger/mason_logger.dart';

/// Interactive: draft invoice from a task.
Future<void> runInvoiceFromTaskFlow(
  Logger log,
  InvoiceNinjaOps ops,
  InvoiceNinjaClient client,
) async {
  final limitClient = log.confirm(
    'Only list tasks for one client?',
  );
  String? filterClientId;
  if (limitClient) {
    final c = await pickClient(client, log);
    if (c == null) return;
    filterClientId = c.id;
  }

  final task = await pickTask(
    client,
    log,
    clientId: filterClientId,
    uninvoicedOnly: true,
  );
  if (task == null) return;
  final taskId = task.id;

  final overrideClient = log.confirm(
    'Use a different client on the invoice than the task?',
  );
  String? invoiceClientId;
  if (overrideClient) {
    final c = await pickClient(client, log);
    if (c == null) {
      log.warn('Cancelled.');
      return;
    }
    invoiceClientId = c.id;
  }

  final resolvedInvoiceClientId =
      (invoiceClientId != null && invoiceClientId.isNotEmpty)
      ? invoiceClientId
      : task.clientId;
  if (resolvedInvoiceClientId == null || resolvedInvoiceClientId.isEmpty) {
    log.warn('Task has no client_id — cannot build invoice.');
    return;
  }

  final dueHintProgress = log.progress(
    'Loading due date default from latest invoice',
  );
  int? offsetDays;
  try {
    offsetDays = await ops.previousInvoiceDueDateOffsetDaysForClient(
      resolvedInvoiceClientId,
    );
  } finally {
    dueHintProgress.complete();
  }
  final todayYmd = formatYmd(todayLocal());
  final defaultDueYmd = offsetDays != null
      ? addCalendarDaysYmd(todayYmd, offsetDays)
      : todayYmd;
  if (offsetDays != null) {
    log.detail(
      'Latest invoice: due date was $offsetDays day(s) after invoice date — '
      'using that as the default due date.',
    );
  } else {
    log.detail(
      'No prior invoice with both date and due_date — default due = today.',
    );
  }
  final dueRaw = log.prompt('Due date YYYY-MM-DD', defaultValue: defaultDueYmd);
  final dueTrimmed = dueRaw.trim();

  final typeId = promptInt(
    log,
    'Line type_id (1=product, 2=task)',
    defaultValue: 2,
  );
  final statusId = promptInt(
    log,
    'Invoice status_id (1=draft)',
    defaultValue: 1,
  );
  final publicNotes = log.prompt('Public notes (optional)', defaultValue: '');
  final linePath = log.prompt(
    'Extra line JSON file path (optional)',
    defaultValue: '',
  );

  final progress = log.progress('Creating invoice');
  final data = await ops.invoiceFromTask(
    taskId: taskId,
    clientId: invoiceClientId,
    typeId: typeId,
    statusId: statusId,
    publicNotes: publicNotes.trim().isEmpty ? null : publicNotes.trim(),
    lineJsonFilePath: linePath.trim().isEmpty ? null : linePath.trim(),
    dateYmd: todayYmd,
    dueDateYmd: dueTrimmed.isEmpty ? null : dueTrimmed,
  );
  progress.complete('Created');

  final detailProgress = log.progress('Loading invoice & client for review');
  late Invoice fullInvoice;
  late Client invoiceClient;
  try {
    fullInvoice = await client.invoices.get(data.id);
    invoiceClient = await client.clients.get(resolvedInvoiceClientId);
  } finally {
    detailProgress.complete();
  }

  await reviewDraftInvoiceAndMaybeSendEmail(
    log: log,
    ops: ops,
    invoice: fullInvoice,
    client: invoiceClient,
    task: task,
  );

  log.success('Open in app: ${client.config.joinPath('invoices/${data.id}')}');
}
