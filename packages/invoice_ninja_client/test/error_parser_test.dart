import 'package:invoice_ninja_client/invoice_ninja_client.dart';
import 'package:test/test.dart';

void main() {
  test('parseInvoiceNinjaApiError includes field errors', () {
    const body = '{"message":"Validation","errors":{"client_id":["Invalid"]}}';
    final msg = parseInvoiceNinjaApiError('/api/v1/tasks', 422, body);
    expect(msg, contains('Validation'));
    expect(msg, contains('client_id'));
  });
}
