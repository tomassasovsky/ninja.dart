import 'package:invoice_ninja_client/invoice_ninja_client.dart';

int _ms(DateTime? d) => d?.millisecondsSinceEpoch ?? 0;

/// Best-effort comparable time for sorting tasks.
int taskSortTime(Task t) {
  final u = _ms(t.updatedAt);
  if (u > 0) return u;
  return _ms(t.createdAt);
}

/// Best-effort comparable time for sorting invoices.
int invoiceSortTime(Invoice i) {
  final u = _ms(i.updatedAt);
  if (u > 0) return u;
  return _ms(i.createdAt);
}
