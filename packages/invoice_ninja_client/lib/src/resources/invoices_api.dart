import 'package:invoice_ninja_client/src/models/api_response.dart';
import 'package:invoice_ninja_client/src/models/invoice.dart';
import 'package:invoice_ninja_client/src/models/json_read.dart';
import 'package:invoice_ninja_client/src/transport.dart';

class InvoicesApi {
  InvoicesApi(this._t);
  final InvoiceNinjaTransport _t;

  /// `POST /api/v1/invoices`
  Future<Invoice> create(Map<String, dynamic> body) async {
    final res = await _t.post('/api/v1/invoices', body);
    return Invoice.fromJson(parseResponseData(res));
  }

  /// `GET /api/v1/invoices` (all pages)
  Future<List<Invoice>> listAll([Map<String, String>? extraQuery]) async {
    final raw = await _t.fetchAllPages(
      '/api/v1/invoices',
      extraQuery: extraQuery,
    );
    return raw.map((e) => Invoice.fromJson(asJsonMap(e))).toList();
  }

  /// `GET /api/v1/invoices/{id}`
  Future<Invoice> get(String id, [Map<String, String>? query]) async {
    final res = await _t.get('/api/v1/invoices/$id', query);
    return Invoice.fromJson(parseResponseData(res));
  }

  /// `POST /api/v1/invoices/bulk` with `action: email` — queues email for each
  /// invitation on the invoice (see Invoice Ninja server behavior).
  Future<void> bulkEmail(List<String> invoiceIds) async {
    await _t.post('/api/v1/invoices/bulk', {
      'action': 'email',
      'ids': invoiceIds,
    });
  }

  /// Creates a draft invoice with one line item that references a task (same
  /// idea as UI "Add to Invoice").
  ///
  /// [lineItem] should match your instance — see `GET /api/v1/invoices/{id}` from a UI-created invoice.
  /// Typical fields: `task_id`, `type_id` (task vs product), `quantity`,
  /// `cost`, `notes`, `product_key`.
  Future<Invoice> createDraftWithTaskLine({
    required String clientId,
    required String taskId,
    required Map<String, dynamic> lineItem,
    int statusId = 1,
    String? publicNotes,
    String? privateNotes,
  }) {
    return create({
      'client_id': clientId,
      'status_id': statusId,
      'line_items': [
        {...lineItem, 'task_id': taskId},
      ],
      'public_notes': ?publicNotes,
      'private_notes': ?privateNotes,
    });
  }
}
