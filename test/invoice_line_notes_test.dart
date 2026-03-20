import 'package:invoice_ninja_client/invoice_ninja_client.dart';
import 'package:invoice_ninja_scripts/invoice_line_notes.dart';
import 'package:test/test.dart';

void main() {
  test('invoiceTitleFromTaskDescription strips trailing HTML block', () {
    expect(
      invoiceTitleFromTaskDescription(
        'My Service <div class="task-time-details">x</div>',
      ),
      'My Service',
    );
    expect(invoiceTitleFromTaskDescription('  Plain  '), 'Plain');
  });

  test('service name vs description body (Invoice Ninja columns)', () {
    final t0 = DateTime(2026, 3, 16, 9);
    final t1 = DateTime(2026, 3, 16, 17);
    final task = Task.fromJson({
      'id': 'x',
      'description': 'Software Engineering / Development hourly',
      'time_log': [
        [t0.millisecondsSinceEpoch ~/ 1000, t1.millisecondsSinceEpoch ~/ 1000],
      ],
    });
    expect(
      invoiceServiceNameFromTask(task),
      'Software Engineering / Development hourly',
    );
    expect(invoiceLineDescriptionFromTask(task), 'Mar 16, 2026 8hs');
  });

  test('billableHoursByDayFromTimeLog sums multiple segments per day', () {
    final d = DateTime(2026, 3, 10);
    final m = billableHoursByDayFromTimeLog([
      [
        DateTime(d.year, d.month, d.day, 9).millisecondsSinceEpoch ~/ 1000,
        DateTime(d.year, d.month, d.day, 13).millisecondsSinceEpoch ~/ 1000,
      ],
      [
        DateTime(d.year, d.month, d.day, 14).millisecondsSinceEpoch ~/ 1000,
        DateTime(d.year, d.month, d.day, 18).millisecondsSinceEpoch ~/ 1000,
      ],
    ]);
    expect(m[DateTime(2026, 3, 10)], closeTo(8.0, 1e-9));
  });
}
