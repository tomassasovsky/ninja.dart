import 'package:invoice_ninja_client/invoice_ninja_client.dart';
import 'package:invoice_ninja_scripts/interactive/pickers.dart';
import 'package:mason_logger/mason_logger.dart';

/// Interactive: show user id/email from a picker.
Future<void> runLookupUserFlow(Logger log, InvoiceNinjaClient client) async {
  final u = await pickUser(client, log);
  if (u == null) return;
  log.success('id=${u.id}  email=${u.email}');
}
