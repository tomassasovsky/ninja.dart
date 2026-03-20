import 'package:invoice_ninja_client/src/models/json_read.dart';

/// Single line on an invoice (`line_items[]`).
class InvoiceLineItem {
  const InvoiceLineItem({
    this.taskId,
    this.typeId,
    this.quantity,
    this.cost,
    this.lineTotal,
    this.notes,
    this.productKey,
  });

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) {
    final q = json['quantity'];
    final c = json['cost'];
    final lt = json['line_total'];
    return InvoiceLineItem(
      taskId: readString(json, 'task_id'),
      typeId: readInt(json, 'type_id'),
      quantity: q is num ? q.toDouble() : double.tryParse('$q'),
      cost: c is num ? c.toDouble() : double.tryParse('$c'),
      lineTotal: lt is num ? lt.toDouble() : double.tryParse('$lt'),
      notes: readString(json, 'notes'),
      productKey: readString(json, 'product_key'),
    );
  }

  final String? taskId;
  final int? typeId;
  final double? quantity;
  final double? cost;

  /// Server-computed line total when present (`line_total`).
  final double? lineTotal;
  final String? notes;
  final String? productKey;
}
