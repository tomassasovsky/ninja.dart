import 'package:invoice_ninja_client/invoice_ninja_client.dart';
import 'package:test/test.dart';

void main() {
  test('Task.fromJson reads core fields', () {
    final t = Task.fromJson({
      'id': 'abc',
      'client_id': 'c1',
      'description': 'Work',
      'rate': 30,
      'invoice_id': '',
      'time_log': '[]',
    });
    expect(t.id, 'abc');
    expect(t.clientId, 'c1');
    expect(t.rate, 30.0);
    expect(t.description, 'Work');
  });

  test('Invoice.fromJson parses line_items list', () {
    final inv = Invoice.fromJson({
      'id': 'inv1',
      'client_id': 'c1',
      'line_items': [
        {'task_id': 't1', 'type_id': 2},
      ],
    });
    expect(inv.id, 'inv1');
    expect(inv.lineItems.length, 1);
    expect(inv.lineItems.first.taskId, 't1');
    expect(inv.lineItems.first.typeId, 2);
  });
}
