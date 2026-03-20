import 'package:invoice_ninja_client/invoice_ninja_client.dart';

/// `true` if [task] is already linked to an invoice / marked invoiced.
///
/// Index/list payloads sometimes omit `invoice_id`; prefer a [Task] from
/// `GET /api/v1/tasks/{id}` when filtering.
bool taskHasInvoiceId(Task task) {
  if (task.invoiced ?? false) return true;
  if (task.invoiced == false) return false;

  final id = task.invoiceId;
  if (id == null) return false;
  final s = id.trim();
  if (s.isEmpty || s == '0' || s.toLowerCase() == 'false') return false;
  return true;
}
