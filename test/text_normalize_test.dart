import 'package:invoice_ninja_scripts/text_normalize.dart';
import 'package:test/test.dart';

void main() {
  test('Spanish accents match ASCII', () {
    expect(normalizeForSearch('Tomás'), normalizeForSearch('tomas'));
    expect(containsNormalized('Tomás Sasovsky', 'tomas'), isTrue);
    expect(containsNormalized('José María', 'jose'), isTrue);
    expect(containsNormalized('Niño', 'nino'), isTrue);
  });
}
