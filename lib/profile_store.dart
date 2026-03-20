import 'dart:convert';
import 'dart:io';

import 'package:invoice_ninja_scripts/secure_token.dart';
import 'package:path/path.dart' as p;

/// One saved tenant: base URL in JSON; API token in the OS secure store.
class SavedProfile {
  const SavedProfile({required this.baseUrl, this.legacyApiToken});

  final String baseUrl;

  /// Only while loading a v1 `profiles.json` before migration; always null on
  /// disk.
  final String? legacyApiToken;

  Map<String, dynamic> toJson() => {
    'baseUrl': baseUrl,
  };

  static SavedProfile? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final b = json['baseUrl'];
    if (b is! String || b.trim().isEmpty) return null;
    final t = json['apiToken'];
    final legacy = t is String && t.trim().isNotEmpty ? t.trim() : null;
    return SavedProfile(baseUrl: b.trim(), legacyApiToken: legacy);
  }
}

/// Persisted profile file (`profiles.json`). Tokens are **not** stored here
/// (v2+).
class ProfilesFile {
  const ProfilesFile({
    required this.version,
    required this.profiles,
    this.defaultProfile,
  });

  factory ProfilesFile.empty() => const ProfilesFile(
    version: currentVersion,
    profiles: {},
  );

  factory ProfilesFile.fromJson(Map<String, dynamic> json) {
    final raw = json['profiles'];
    final map = <String, SavedProfile>{};
    if (raw is Map) {
      for (final e in raw.entries) {
        final name = e.key.toString().trim();
        if (name.isEmpty) continue;
        final sp = SavedProfile.fromJson(
          e.value is Map<String, dynamic>
              ? e.value as Map<String, dynamic>
              : null,
        );
        if (sp != null) map[name] = sp;
      }
    }
    final def = json['defaultProfile'];
    final ver = json['version'];
    return ProfilesFile(
      version: ver is int ? ver : 1,
      profiles: map,
      defaultProfile: def is String && def.trim().isNotEmpty
          ? def.trim()
          : null,
    );
  }

  static const int currentVersion = 2;

  final int version;
  final String? defaultProfile;
  final Map<String, SavedProfile> profiles;

  Map<String, dynamic> toJson() => {
    'version': version,
    if (defaultProfile != null) 'defaultProfile': defaultProfile,
    'profiles': profiles.map((k, v) => MapEntry(k, v.toJson())),
  };
}

/// Reads and writes profile metadata; API tokens live in [TokenStore].
class ProfileStore {
  ProfileStore({File? file, TokenStore? tokenStore})
    : _file = file ?? File(_defaultConfigFilePath()),
      _tokenStore = tokenStore ?? OsTokenStore();

  final File _file;
  final TokenStore _tokenStore;

  /// Absolute path to `profiles.json` (base URLs only).
  String get storagePath => _file.path;

  /// Config directory for this app (created on first save).
  static String configDirectoryPath() {
    if (Platform.isWindows) {
      final app = Platform.environment['APPDATA'];
      if (app != null && app.isNotEmpty) {
        return p.join(app, 'invoicing-ninja');
      }
    }
    final xdg = Platform.environment['XDG_CONFIG_HOME']?.trim();
    if (xdg != null && xdg.isNotEmpty) {
      return p.join(xdg, 'invoicing-ninja');
    }
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty) {
      return p.join(home, '.config', 'invoicing-ninja');
    }
    throw StateError('Cannot resolve config directory (HOME / APPDATA).');
  }

  static String _defaultConfigFilePath() =>
      p.join(configDirectoryPath(), 'profiles.json');

  /// Returns the API token for [profileName] (OS store, or legacy only before
  /// migration).
  String? resolveToken(String profileName) {
    final data = load();
    final p = data.profiles[profileName];
    if (p == null) return null;
    final fromOs = _tokenStore.read(profileName)?.trim();
    if (fromOs != null && fromOs.isNotEmpty) return fromOs;
    final legacy = p.legacyApiToken?.trim();
    if (legacy != null && legacy.isNotEmpty) return legacy;
    return null;
  }

  ProfilesFile load() {
    if (!_file.existsSync()) return ProfilesFile.empty();
    try {
      final text = _file.readAsStringSync();
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        var data = ProfilesFile.fromJson(decoded);
        if (data.version < ProfilesFile.currentVersion) {
          _migrateToCurrent(data);
          final text2 = _file.readAsStringSync();
          final decoded2 = jsonDecode(text2);
          if (decoded2 is Map<String, dynamic>) {
            data = ProfilesFile.fromJson(decoded2);
          }
        }
        return data;
      }
    } on FormatException {
      // ignore
    } catch (_) {
      // ignore
    }
    return ProfilesFile.empty();
  }

  void _migrateToCurrent(ProfilesFile data) {
    for (final e in data.profiles.entries) {
      final legacy = e.value.legacyApiToken;
      if (legacy != null && legacy.isNotEmpty) {
        _tokenStore.write(e.key, legacy);
      }
    }
    save(
      ProfilesFile(
        version: ProfilesFile.currentVersion,
        profiles: {
          for (final e in data.profiles.entries)
            e.key: SavedProfile(baseUrl: e.value.baseUrl),
        },
        defaultProfile: data.defaultProfile,
      ),
    );
  }

  void save(ProfilesFile data) {
    final dir = _file.parent;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final tmp = File(
      '${_file.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    try {
      const encoder = JsonEncoder.withIndent('  ');
      tmp.writeAsStringSync('${encoder.convert(data.toJson())}\n');
      if (_file.existsSync()) {
        _file.deleteSync();
      }
      tmp.renameSync(_file.path);
    } finally {
      if (tmp.existsSync()) {
        tmp.deleteSync();
      }
    }
    _restrictReadPermissions();
  }

  void _restrictReadPermissions() {
    if (Platform.isWindows) return;
    try {
      final r = Process.runSync('chmod', ['600', _file.path]);
      if (r.exitCode != 0) {
        // ignore
      }
    } catch (_) {
      // ignore
    }
  }

  SavedProfile? get(String name) => load().profiles[name];

  String? get defaultProfileName {
    final data = load();
    final d = data.defaultProfile;
    if (d != null && d.isNotEmpty && data.profiles.containsKey(d)) return d;
    return null;
  }

  void upsert(
    String name,
    String baseUrl,
    String apiToken, {
    bool setAsDefault = true,
  }) {
    final n = name.trim();
    if (n.isEmpty) {
      throw ArgumentError('Profile name must not be empty.');
    }
    final data = load();
    final next = Map<String, SavedProfile>.from(data.profiles);
    _tokenStore.write(n, apiToken.trim());
    next[n] = SavedProfile(baseUrl: baseUrl.trim());
    var def = data.defaultProfile;
    if (setAsDefault || def == null || def.isEmpty || !next.containsKey(def)) {
      def = n;
    }
    save(
      ProfilesFile(
        version: ProfilesFile.currentVersion,
        profiles: next,
        defaultProfile: def,
      ),
    );
  }

  void remove(String name) {
    final n = name.trim();
    if (n.isEmpty) return;
    final data = load();
    if (!data.profiles.containsKey(n)) return;
    _tokenStore.delete(n);
    final next = Map<String, SavedProfile>.from(data.profiles)..remove(n);
    var def = data.defaultProfile;
    if (def == n) {
      if (next.isEmpty) {
        def = null;
      } else {
        final keys = next.keys.toList()..sort();
        def = keys.first;
      }
    }
    save(
      ProfilesFile(
        version: ProfilesFile.currentVersion,
        profiles: next,
        defaultProfile: def,
      ),
    );
  }

  void setDefault(String name) {
    final n = name.trim();
    if (n.isEmpty) return;
    final data = load();
    if (!data.profiles.containsKey(n)) {
      throw StateError('Unknown profile "$n".');
    }
    save(
      ProfilesFile(
        version: ProfilesFile.currentVersion,
        profiles: data.profiles,
        defaultProfile: n,
      ),
    );
  }

  List<String> profileNamesSorted() {
    final names = load().profiles.keys.toList()..sort();
    return names;
  }
}
