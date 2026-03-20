import 'package:invoice_ninja_client/invoice_ninja_client.dart';
import 'package:invoice_ninja_scripts/task_invoice.dart';
import 'package:test/test.dart';

void main() {
  test('taskHasInvoiceId', () {
    expect(
      taskHasInvoiceId(Task.fromJson({'id': 'a', 'invoice_id': ''})),
      false,
    );
    expect(
      taskHasInvoiceId(Task.fromJson({'id': 'a', 'invoice_id': '0'})),
      false,
    );
    expect(
      taskHasInvoiceId(Task.fromJson({'id': 'a', 'invoice_id': null})),
      false,
    );
    expect(
      taskHasInvoiceId(Task.fromJson({'id': 'a', 'invoice_id': 'abc123'})),
      true,
    );
    expect(
      taskHasInvoiceId(Task.fromJson({'id': 'a', 'invoiced': true})),
      true,
    );
    expect(
      taskHasInvoiceId(
        Task.fromJson({'id': 'a', 'invoiced': false, 'invoice_id': ''}),
      ),
      false,
    );
  });
}
