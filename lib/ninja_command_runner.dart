import 'dart:io';

import 'package:args/args.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:invoice_ninja_client/invoice_ninja_client.dart';
import 'package:invoice_ninja_scripts/cli_common.dart';
import 'package:invoice_ninja_scripts/interactive/cli.dart';
import 'package:invoice_ninja_scripts/script_config.dart';
import 'package:mason_logger/mason_logger.dart';

/// Interactive CLI with shell tab completion ([`cli_completion`](https://pub.dev/packages/cli_completion)).
///
/// Run `ninja install-completion-files` (or rely on first-run install) then
/// restart the shell.
class NinjaCommandRunner extends CompletionCommandRunner<int> {
  NinjaCommandRunner() : super('ninja', 'Invoice Ninja — interactive CLI') {
    addApiOptions(argParser);
  }

  @override
  String get invocation => '$executableName [options]';

  @override
  bool get enableAutoInstall => true;

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    final cmd = topLevelResults.command?.name;

    if (cmd == 'completion' ||
        cmd == 'install-completion-files' ||
        cmd == 'uninstall-completion-files' ||
        cmd == 'help') {
      return super.runCommand(topLevelResults);
    }

    if (cmd != null) {
      stderr
        ..writeln('Unknown command: $cmd\n')
        ..writeln(usage);
      return 1;
    }

    if (enableAutoInstall) {
      // Subclass hook; analyzer: member is library-internal in cli_completion.
      // ignore: invalid_use_of_internal_member
      tryInstallCompletionFiles(Level.error);
    }

    if (topLevelResults.flag('help')) {
      _printHelp();
      return 0;
    }

    final profileExit = tryProfileCliExitCode(topLevelResults);
    if (profileExit != null) return profileExit;

    InvoiceNinjaClient? client;
    try {
      final cfg = configFromArgs(topLevelResults);
      client = InvoiceNinjaClient(config: cfg.toInvoiceNinjaConfig());
      await runInteractiveCli(client);
      return 0;
    } on ScriptConfigException catch (e) {
      stderr.writeln('[ERROR] $e');
      return 1;
    } finally {
      client?.close();
    }
  }

  void _printHelp() {
    stdout
      ..writeln('Interactive Invoice Ninja CLI (mason_logger).')
      ..writeln('Requires a terminal for arrow-key menus and spinners.')
      ..writeln()
      ..writeln('Environment:')
      ..writeln('  INVOICE_NINJA_BASE_URL   e.g. https://invoice.example.com')
      ..writeln('  INVOICE_NINJA_API_TOKEN  API token')
      ..writeln()
      ..writeln('Saved profiles: --list-profiles, --save-profile,')
      ..writeln('  --delete-profile, --profile / -p')
      ..writeln()
      ..writeln('Shell completion:')
      ..writeln('  $executableName install-completion-files')
      ..writeln()
      ..writeln('Options:')
      ..writeln(argParser.usage);
  }
}
