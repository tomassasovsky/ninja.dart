import 'dart:io';

import 'package:args/args.dart';

import 'package:invoice_ninja_scripts/profile_store.dart';
import 'package:invoice_ninja_scripts/script_config.dart';

/// Standard API flags for all scripts (env overrides, saved profiles).
void addApiOptions(ArgParser parser) {
  parser
    ..addOption('base-url', abbr: 'b', help: 'Override INVOICE_NINJA_BASE_URL')
    ..addOption('token', abbr: 't', help: 'Override INVOICE_NINJA_API_TOKEN')
    ..addOption(
      'profile',
      abbr: 'p',
      help: 'Use this saved profile (base URL + token on disk)',
    )
    ..addOption(
      'save-profile',
      help: 'Save credentials from flags/env under this name and exit',
    )
    ..addFlag(
      'list-profiles',
      negatable: false,
      help: 'List saved profiles and exit',
    )
    ..addOption(
      'delete-profile',
      help: 'Remove a saved profile by name and exit',
    );
}

/// Loads [ScriptConfig] from environment and CLI (including `--profile`).
ScriptConfig configFromArgs(ArgResults r) {
  return loadScriptConfig(
    baseUrlOverride: r['base-url'] as String?,
    tokenOverride: r['token'] as String?,
    profileName: r['profile'] as String?,
  );
}

/// Handles profile maintenance flags. Returns an exit code if the process
/// should terminate; `null` means continue and load API config as usual.
int? tryProfileCliExitCode(ArgResults r) {
  if (r['list-profiles'] == true) {
    final store = ProfileStore();
    final data = store.load();
    final names = store.profileNamesSorted();
    if (names.isEmpty) {
      stdout
        ..writeln(
          'No saved profiles. Store: ${ProfileStore.configDirectoryPath()}',
        )
        ..writeln(
          'Create:  ninja --save-profile NAME -b https://... -t TOKEN',
        );
      return 0;
    }
    final def = data.defaultProfile;
    stdout
      ..writeln('Saved profiles (${ProfileStore.configDirectoryPath()}):')
      ..writeln();
    for (final n in names) {
      final p = data.profiles[n]!;
      final fullTok = store.resolveToken(n);
      final mark = n == def ? ' (default)' : '';
      final tok = fullTok == null || fullTok.isEmpty
          ? '— (missing)'
          : fullTok.length <= 8
          ? '***'
          : '${fullTok.substring(0, 4)}…'
                '${fullTok.substring(fullTok.length - 4)}';
      stdout
        ..writeln('$n$mark')
        ..writeln('  ${p.baseUrl}')
        ..writeln('  token: $tok (stored in OS keychain / credential vault)')
        ..writeln();
    }
    return 0;
  }

  final del = r['delete-profile'] as String?;
  if (del != null && del.trim().isNotEmpty) {
    final store = ProfileStore();
    final name = del.trim();
    if (store.get(name) == null) {
      stderr.writeln('No profile named "$name".');
      return 1;
    }
    store.remove(name);
    stdout.writeln('Removed profile "$name".');
    return 0;
  }

  final save = r['save-profile'] as String?;
  if (save != null && save.trim().isNotEmpty) {
    final cfg = loadScriptConfig(
      baseUrlOverride: r['base-url'] as String?,
      tokenOverride: r['token'] as String?,
      allowProfileFallback: false,
    );
    ProfileStore().upsert(save.trim(), cfg.baseUri.toString(), cfg.apiToken);
    stdout.writeln(
      'Saved profile "${save.trim()}" (default) under '
      '${ProfileStore.configDirectoryPath()}.',
    );
    return 0;
  }

  return null;
}
