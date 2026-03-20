import 'package:invoice_ninja_client/invoice_ninja_client.dart';
import 'package:invoice_ninja_scripts/interactive/pickers.dart';
import 'package:invoice_ninja_scripts/interactive/prompt_helpers.dart';
import 'package:invoice_ninja_scripts/operations.dart';
import 'package:mason_logger/mason_logger.dart';

/// Interactive: create a project on a client.
Future<void> runCreateProjectFlow(
  Logger log,
  InvoiceNinjaOps ops,
  InvoiceNinjaClient client,
) async {
  final c = await pickClient(client, log);
  if (c == null) return;
  final clientId = c.id;
  final name = log.prompt('New project name');
  if (name.trim().isEmpty) {
    log.warn('Cancelled.');
    return;
  }
  final rate = promptDouble(log, 'Task rate', defaultValue: 0);
  final progress = log.progress('Creating project');
  final data = await ops.createProject(
    clientId: clientId,
    name: name.trim(),
    taskRate: rate,
  );
  progress.complete('Created');
  log.success('id=${data.id}');
}
