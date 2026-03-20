import 'dart:convert';
import 'dart:io';

import 'package:invoice_ninja_scripts/invoice_ninja_scripts.dart';
import 'package:test/test.dart';

void main() {
  test('ProfileStore roundtrip and default', () {
    final dir = Directory.systemTemp.createTempSync('inv_prof_');
    try {
      final f = File('${dir.path}/profiles.json');
      final mem = MemoryTokenStore();
      final store = ProfileStore(file: f, tokenStore: mem);
      expect(store.profileNamesSorted(), isEmpty);

      store.upsert('a', 'https://one.example.com', 'tok-a');
      expect(store.defaultProfileName, 'a');
      expect(mem.read('a'), 'tok-a');
      expect(store.get('a')?.baseUrl, 'https://one.example.com');
      expect(store.get('a')?.legacyApiToken, isNull);
      final onDisk = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      final profiles = onDisk['profiles']! as Map<String, dynamic>;
      expect(profiles['a'], {'baseUrl': 'https://one.example.com'});

      store.upsert(
        'b',
        'https://two.example.com',
        'tok-b',
        setAsDefault: false,
      );
      expect(store.defaultProfileName, 'a');

      store.setDefault('b');
      expect(store.defaultProfileName, 'b');

      store.remove('b');
      expect(mem.read('b'), isNull);
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  test('migrates v1 file with plaintext apiToken into token store', () {
    final dir = Directory.systemTemp.createTempSync('inv_mig_');
    try {
      final f = File('${dir.path}/profiles.json')
        ..writeAsStringSync(
          jsonEncode({
            'version': 1,
            'defaultProfile': 'a',
            'profiles': {
              'a': {
                'baseUrl': 'https://app.example.com',
                'apiToken': 'secret-token',
              },
            },
          }),
        );
      final mem = MemoryTokenStore();
      ProfileStore(file: f, tokenStore: mem).load();
      expect(mem.read('a'), 'secret-token');
      final v2 = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      final profilesV2 = v2['profiles']! as Map<String, dynamic>;
      expect(v2['version'], 2);
      expect(profilesV2['a'], {'baseUrl': 'https://app.example.com'});
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  test('loadScriptConfig fills from default profile', () {
    final dir = Directory.systemTemp.createTempSync('inv_cfg_');
    try {
      final f = File('${dir.path}/profiles.json');
      final mem = MemoryTokenStore();
      final store = ProfileStore(file: f, tokenStore: mem)
        ..upsert('tenant', 'https://app.example.com', 'secret-token');

      final cfg = loadScriptConfig(
        profileStore: store,
      );
      expect(cfg.baseUri.toString(), 'https://app.example.com');
      expect(cfg.apiToken, 'secret-token');
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  test('loadScriptConfig flags override profile', () {
    final dir = Directory.systemTemp.createTempSync('inv_cfg2_');
    try {
      final f = File('${dir.path}/profiles.json');
      final mem = MemoryTokenStore();
      final store = ProfileStore(file: f, tokenStore: mem)
        ..upsert('tenant', 'https://app.example.com', 'secret-token');

      final cfg = loadScriptConfig(
        baseUrlOverride: 'https://override.example.com',
        tokenOverride: 'override-tok',
        profileStore: store,
      );
      expect(cfg.baseUri.toString(), 'https://override.example.com');
      expect(cfg.apiToken, 'override-tok');
    } finally {
      dir.deleteSync(recursive: true);
    }
  });
}
