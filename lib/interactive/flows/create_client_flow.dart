import 'package:invoice_ninja_scripts/operations.dart';
import 'package:mason_logger/mason_logger.dart';

/// Interactive: create a client.
Future<void> runCreateClientFlow(Logger log, InvoiceNinjaOps ops) async {
  final name = log.prompt('Client name');
  if (name.trim().isEmpty) {
    log.warn('Cancelled.');
    return;
  }
  final progress = log.progress('Creating client');
  final data = await ops.createClient(name.trim());
  progress.complete('Created');
  log.success('id=${data.id}  number=${data.number}');
}
