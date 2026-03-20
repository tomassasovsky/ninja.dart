import 'dart:io';

import 'package:args/args.dart';
import 'package:invoice_ninja_scripts/invoice_ninja_scripts.dart';

/// Creates a **draft** invoice (`status_id` 1) with one line item linked to a
/// task, similar to the UI "Add to invoice" flow.
///
/// Line item shape is version-dependent. This script builds a **minimal** task
/// line (`type_id` 2 = task, `task_id`, `quantity` hours, `cost` rate). If your
/// instance rejects the payload, run `GET /api/v1/invoices/{id}` on an invoice you created
/// from the UI and align fields (see README).
Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('task-id', help: 'Task hashed id', mandatory: true)
    ..addOption('client-id', help: 'Client hashed id (default: from task)')
    ..addOption(
      'type-id',
      help: 'Line item type (1=product, 2=task — verify for your build)',
      defaultsTo: '2',
    )
    ..addOption('status-id', help: 'Invoice status (1=draft)', defaultsTo: '1')
    ..addOption('public-notes')
    ..addOption(
      'line-json-file',
      help: 'Optional JSON file: extra line_item fields to merge',
    )
    ..addOption(
      'invoice-date',
      help: 'Invoice date YYYY-MM-DD (default: today)',
    )
    ..addOption(
      'due-date',
      help:
          'Due date YYYY-MM-DD (default: from latest invoice offset or today)',
    )
    ..addFlag('help', abbr: 'h', negatable: false);
  addApiOptions(parser);

  final r = parser.parse(args);
  if (r['help'] == true) {
    stdout
      ..writeln('Usage: dart run bin/invoice_from_task.dart --task-id <id>')
      ..writeln(parser.usage);
    exit(0);
  }
  final profileExit = tryProfileCliExitCode(r);
  if (profileExit != null) exit(profileExit);

  InvoiceNinjaClient? client;
  try {
    final cfg = configFromArgs(r);
    final ninja = InvoiceNinjaClient(config: cfg.toInvoiceNinjaConfig());
    client = ninja;

    final taskId = r['task-id'] as String;
    final clientOpt = r['client-id'] as String?;
    final resolvedClientId = (clientOpt != null && clientOpt.trim().isNotEmpty)
        ? clientOpt.trim()
        : null;
    final typeId = int.parse(r['type-id'] as String);
    final statusId = int.parse(r['status-id'] as String);
    final lineJsonPath = r['line-json-file'] as String?;
    final pub = r['public-notes'] as String?;
    final invoiceDateOpt = r['invoice-date'] as String?;
    final dueDateOpt = r['due-date'] as String?;

    final inv = await InvoiceNinjaOps(ninja).invoiceFromTask(
      taskId: taskId,
      clientId: resolvedClientId,
      typeId: typeId,
      statusId: statusId,
      publicNotes: (pub?.trim().isNotEmpty ?? false) ? pub : null,
      lineJsonFilePath: lineJsonPath != null && lineJsonPath.isNotEmpty
          ? lineJsonPath
          : null,
      dateYmd: invoiceDateOpt != null && invoiceDateOpt.trim().isNotEmpty
          ? invoiceDateOpt.trim()
          : null,
      dueDateYmd: dueDateOpt != null && dueDateOpt.trim().isNotEmpty
          ? dueDateOpt.trim()
          : null,
    );
    stdout
      ..writeln('invoice id: ${inv.id}')
      ..writeln('number: ${inv.number}');
  } on ScriptConfigException catch (e) {
    stderr.writeln('[ERROR] $e');
    exit(1);
    // StateError from pickers (e.g. empty list): one-line CLI message, not a
    // stack.
    // ignore: avoid_catching_errors
  } on StateError catch (e) {
    stderr.writeln('[ERROR] $e');
    exit(1);
  } on ApiException catch (e) {
    stderr.writeln('[ERROR] API: $e');
    exit(1);
  } on NetworkException catch (e) {
    stderr.writeln('[ERROR] Network: $e');
    exit(1);
  } catch (e, st) {
    stderr.writeln('[ERROR] $e\n$st');
    exit(1);
  } finally {
    client?.close();
  }
}
