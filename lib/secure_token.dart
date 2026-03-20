import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Stores API tokens outside of config files (OS keychain / credential vault).
abstract class TokenStore {
  void write(String profileName, String token);

  /// Returns null if no token is stored for [profileName].
  String? read(String profileName);

  void delete(String profileName);
}

/// In-memory store for tests.
class MemoryTokenStore implements TokenStore {
  final Map<String, String> _m = {};

  @override
  void write(String profileName, String token) {
    _m[profileName] = token;
  }

  @override
  String? read(String profileName) => _m[profileName];

  @override
  void delete(String profileName) {
    _m.remove(profileName);
  }
}

/// Sanitized segment used in macOS Keychain account strings, libsecret
/// attributes, and Windows credential target names.
String credentialStoreKeySegment(String profileName) {
  final s = profileName.replaceAll(RegExp(r'[^\w\-\.]'), '_');
  return s.isEmpty ? '_' : s;
}

/// Uses **macOS Keychain** (`security`), **Linux libsecret** (`secret-tool`),
/// or **Windows Credential Manager** (`CredWrite` / `CredRead` via `package:win32`).
///
/// API tokens are **not** written to `profiles.json`.
class OsTokenStore implements TokenStore {
  static const _service = 'dev.invoicing-ninja.cli';

  String _account(String profileName) =>
      'profile:${credentialStoreKeySegment(profileName)}';

  static String _winTarget(String profileName) =>
      '$_service/token/${credentialStoreKeySegment(profileName)}';

  @override
  void write(String profileName, String token) {
    if (Platform.isMacOS) {
      _macWrite(profileName, token);
    } else if (Platform.isLinux) {
      _linuxWrite(profileName, token);
    } else if (Platform.isWindows) {
      _windowsWrite(profileName, token);
    } else {
      throw UnsupportedError(
        'OS secure token storage is not implemented for '
        '${Platform.operatingSystem}.',
      );
    }
  }

  @override
  String? read(String profileName) {
    if (Platform.isMacOS) {
      return _macRead(profileName);
    }
    if (Platform.isLinux) {
      return _linuxRead(profileName);
    }
    if (Platform.isWindows) {
      return _windowsRead(profileName);
    }
    return null;
  }

  @override
  void delete(String profileName) {
    if (Platform.isMacOS) {
      _macDelete(profileName);
    } else if (Platform.isLinux) {
      _linuxDelete(profileName);
    } else if (Platform.isWindows) {
      _windowsDelete(profileName);
    }
  }

  // --- macOS ---

  void _macWrite(String profileName, String token) {
    final account = _account(profileName);
    _macDelete(profileName);
    final r = Process.runSync('security', [
      'add-generic-password',
      '-a',
      account,
      '-s',
      _service,
      '-w',
      token,
      '-U',
    ]);
    if (r.exitCode != 0) {
      throw StateError(
        'Keychain: ${r.stderr}${r.stdout}',
      );
    }
  }

  String? _macRead(String profileName) {
    final account = _account(profileName);
    final r = Process.runSync('security', [
      'find-generic-password',
      '-a',
      account,
      '-s',
      _service,
      '-w',
    ]);
    if (r.exitCode != 0) return null;
    return r.stdout.toString().trim();
  }

  void _macDelete(String profileName) {
    final account = _account(profileName);
    Process.runSync('security', [
      'delete-generic-password',
      '-a',
      account,
      '-s',
      _service,
    ]);
  }

  // --- Linux (libsecret) ---

  static bool get _linuxSecretToolAvailable {
    final r = Process.runSync('/bin/sh', [
      '-c',
      'command -v secret-tool >/dev/null 2>&1',
    ]);
    return r.exitCode == 0;
  }

  static String _bashSingleQuote(String s) => "'${s.replaceAll("'", r"'\''")}'";

  void _linuxWrite(String profileName, String token) {
    if (!_linuxSecretToolAvailable) {
      throw StateError(
        'Linux: `secret-tool` not found. Install libsecret (e.g. Debian/Ubuntu: '
        '`libsecret-tools`, Fedora: `libsecret-tools`) so API tokens can be '
        'stored in the session keyring instead of plain text.',
      );
    }
    final tmp = File(
      '${Directory.systemTemp.path}/invn_${DateTime.now().microsecondsSinceEpoch}.tmp',
    )..writeAsStringSync(token, flush: true);
    Process.runSync('chmod', ['600', tmp.path]);
    try {
      final label = 'invoicing-ninja $profileName';
      final cmd =
          'secret-tool store --label=${_bashSingleQuote(label)} '
          'application org.invoicing-ninja profile '
          '${_bashSingleQuote(profileName)} '
          '< ${_bashSingleQuote(tmp.path)}';
      final r = Process.runSync('/bin/sh', ['-c', cmd]);
      if (r.exitCode != 0) {
        throw StateError(
          'secret-tool: ${r.stderr}${r.stdout}',
        );
      }
    } finally {
      if (tmp.existsSync()) tmp.deleteSync();
    }
  }

  String? _linuxRead(String profileName) {
    if (!_linuxSecretToolAvailable) return null;
    final r = Process.runSync('secret-tool', [
      'lookup',
      'application',
      'org.invoicing-ninja',
      'profile',
      profileName,
    ]);
    if (r.exitCode != 0) return null;
    return r.stdout.toString().trim();
  }

  void _linuxDelete(String profileName) {
    if (!_linuxSecretToolAvailable) return;
    Process.runSync('secret-tool', [
      'clear',
      'application',
      'org.invoicing-ninja',
      'profile',
      profileName,
    ]);
  }

  // --- Windows ---

  void _windowsWrite(String profileName, String token) {
    final target = _winTarget(profileName);
    final pTarget = target.toNativeUtf16();
    final pUser = 'invoice_ninja_scripts'.toNativeUtf16();
    final bytes = utf8.encode(token);
    final blob = Uint8List.fromList(bytes).allocatePointer();

    final credential = calloc.allocate<CREDENTIAL>(sizeOf<CREDENTIAL>())
      ..ref.Type = CRED_TYPE_GENERIC
      ..ref.TargetName = pTarget
      ..ref.Persist = CRED_PERSIST_LOCAL_MACHINE
      ..ref.UserName = pUser
      ..ref.CredentialBlob = blob
      ..ref.CredentialBlobSize = bytes.length;

    try {
      if (CredWrite(credential, 0) != TRUE) {
        throw WindowsException(HRESULT_FROM_WIN32(GetLastError()));
      }
    } finally {
      calloc
        ..free(blob)
        ..free(credential)
        ..free(pTarget)
        ..free(pUser);
    }
  }

  String? _windowsRead(String profileName) {
    final target = _winTarget(profileName);
    final pTarget = target.toNativeUtf16();
    final credPointer = calloc.allocate<Pointer<CREDENTIAL>>(
      sizeOf<Pointer<CREDENTIAL>>(),
    );

    try {
      if (CredRead(pTarget, CRED_TYPE_GENERIC, 0, credPointer) != TRUE) {
        return null;
      }
      final cred = credPointer.value.ref;
      final blob = cred.CredentialBlob.asTypedList(cred.CredentialBlobSize);
      return utf8.decode(blob);
    } finally {
      if (credPointer.value.address != 0) {
        CredFree(credPointer.value);
      }
      calloc
        ..free(credPointer)
        ..free(pTarget);
    }
  }

  void _windowsDelete(String profileName) {
    final target = _winTarget(profileName);
    final pTarget = target.toNativeUtf16();
    try {
      CredDelete(pTarget, CRED_TYPE_GENERIC, 0);
    } finally {
      calloc.free(pTarget);
    }
  }
}
