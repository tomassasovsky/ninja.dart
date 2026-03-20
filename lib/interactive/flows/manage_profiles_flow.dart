import 'package:invoice_ninja_scripts/profile_store.dart';
import 'package:mason_logger/mason_logger.dart';

enum _ProfilesMenu {
  addOrUpdate,
  setDefault,
  deleteProfile,
  back,
}

void _printProfiles(Logger log, ProfileStore store) {
  final data = store.load();
  final names = store.profileNamesSorted();
  log
    ..info('')
    ..info('Config file: ${store.storagePath}');
  if (names.isEmpty) {
    log.info('No profiles saved yet.');
    return;
  }
  final def = data.defaultProfile;
  for (final n in names) {
    final p = data.profiles[n]!;
    final mark = n == def ? ' (default)' : '';
    log.info('  • $n$mark  ${p.baseUrl}');
  }
}

/// Interactive: add/update/delete/set default saved API profiles.
Future<void> runManageProfilesFlow(Logger log) async {
  final store = ProfileStore();
  var done = false;
  while (!done) {
    _printProfiles(log, store);
    log.info('');
    final action = log.chooseOne<_ProfilesMenu>(
      'Profile actions',
      choices: _ProfilesMenu.values,
      display: (a) => switch (a) {
        _ProfilesMenu.addOrUpdate => 'Add or update profile',
        _ProfilesMenu.setDefault => 'Set default profile',
        _ProfilesMenu.deleteProfile => 'Delete profile',
        _ProfilesMenu.back => 'Back to main menu',
      },
    );

    switch (action) {
      case _ProfilesMenu.back:
        done = true;
      case _ProfilesMenu.addOrUpdate:
        final name = log.prompt('Profile name (short label)').trim();
        if (name.isEmpty) {
          log.warn('Cancelled.');
          continue;
        }
        final base = log
            .prompt('Base URL (e.g. https://invoice.example.com)')
            .trim();
        if (base.isEmpty) {
          log.warn('Cancelled.');
          continue;
        }
        final token = log.prompt('API token').trim();
        if (token.isEmpty) {
          log.warn('Cancelled.');
          continue;
        }
        final makeDefault = log.confirm(
          'Set as default profile?',
          defaultValue: true,
        );
        try {
          store.upsert(name, base, token, setAsDefault: makeDefault);
          log.success('Saved profile "$name".');
        } catch (e) {
          log.err('$e');
        }
      case _ProfilesMenu.setDefault:
        final names = store.profileNamesSorted();
        if (names.isEmpty) {
          log.warn('No profiles to choose from.');
          continue;
        }
        final pick = log.chooseOne<String>(
          'Default profile',
          choices: names,
          display: (s) => s,
        );
        try {
          store.setDefault(pick);
          log.success('Default is now "$pick".');
        } catch (e) {
          log.err('$e');
        }
      case _ProfilesMenu.deleteProfile:
        final names = store.profileNamesSorted();
        if (names.isEmpty) {
          log.warn('No profiles to delete.');
          continue;
        }
        final pick = log.chooseOne<String>(
          'Delete profile',
          choices: names,
          display: (s) => s,
        );
        if (!log.confirm('Remove "$pick" from disk?')) {
          continue;
        }
        store.remove(pick);
        log.success('Removed "$pick".');
    }
  }
}
