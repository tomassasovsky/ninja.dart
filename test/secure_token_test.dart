import 'package:invoice_ninja_scripts/invoice_ninja_scripts.dart';
import 'package:test/test.dart';

void main() {
  group('credentialStoreKeySegment', () {
    test('preserves alphanumerics dots dashes', () {
      expect(credentialStoreKeySegment('client-a'), 'client-a');
      expect(credentialStoreKeySegment('org.co.uk'), 'org.co.uk');
    });

    test('replaces unsafe characters with underscores', () {
      expect(credentialStoreKeySegment('a b'), 'a_b');
      expect(credentialStoreKeySegment('foo/bar'), 'foo_bar');
    });

    test('empty becomes underscore', () {
      expect(credentialStoreKeySegment(''), '_');
      expect(credentialStoreKeySegment('   '), '___');
    });
  });

  group('MemoryTokenStore', () {
    test('write read delete', () {
      final s = MemoryTokenStore();
      expect(s.read('p'), isNull);
      s.write('p', 'secret');
      expect(s.read('p'), 'secret');
      s.delete('p');
      expect(s.read('p'), isNull);
    });

    test('overwrite updates value', () {
      final s = MemoryTokenStore()
        ..write('p', 'a')
        ..write('p', 'b');
      expect(s.read('p'), 'b');
    });
  });
}
