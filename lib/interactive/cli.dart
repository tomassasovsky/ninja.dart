import 'package:invoice_ninja_client/invoice_ninja_client.dart';
import 'package:invoice_ninja_scripts/interactive/flows/create_client_flow.dart';
import 'package:invoice_ninja_scripts/interactive/flows/create_project_flow.dart';
import 'package:invoice_ninja_scripts/interactive/flows/create_task_flow.dart';
import 'package:invoice_ninja_scripts/interactive/flows/invoice_from_task_flow.dart';
import 'package:invoice_ninja_scripts/interactive/flows/lookup_user_flow.dart';
import 'package:invoice_ninja_scripts/interactive/flows/manage_profiles_flow.dart';
import 'package:invoice_ninja_scripts/operations.dart';
import 'package:mason_logger/mason_logger.dart';

enum _MainAction {
  manageProfiles,
  createClient,
  createProject,
  lookupUser,
  createTask,
  invoiceFromTask,
  exit,
}

/// Runs the interactive menu until the user exits.
///
/// Uses [mason_logger](https://pub.dev/packages/mason_logger) for spinners and
/// arrow-key selection (requires a terminal).
///
/// Individual flows live under `lib/interactive/flows/`.
Future<void> runInteractiveCli(
  InvoiceNinjaClient client, {
  Logger? logger,
}) async {
  final log = logger ?? Logger();
  final ops = InvoiceNinjaOps(client);

  log
    ..info('Invoice Ninja — interactive')
    ..detail('${client.config.baseUri}')
    ..detail('↑/↓ or j/k to move, Enter/Space to select (mason_logger)')
    ..info('');

  var running = true;
  while (running) {
    final action = log.chooseOne<_MainAction>(
      'What would you like to do?',
      choices: _MainAction.values,
      display: (a) => switch (a) {
        _MainAction.manageProfiles => 'Manage saved profiles',
        _MainAction.createClient => 'Create client',
        _MainAction.createProject => 'Create project',
        _MainAction.lookupUser => 'Look up user',
        _MainAction.createTask => 'Create task (weekday time log)',
        _MainAction.invoiceFromTask => 'Create draft invoice from task',
        _MainAction.exit => 'Exit',
      },
    );

    try {
      switch (action) {
        case _MainAction.manageProfiles:
          await runManageProfilesFlow(log);
        case _MainAction.createClient:
          await runCreateClientFlow(log, ops);
        case _MainAction.createProject:
          await runCreateProjectFlow(log, ops, client);
        case _MainAction.lookupUser:
          await runLookupUserFlow(log, client);
        case _MainAction.createTask:
          await runCreateTaskFlow(log, ops, client);
        case _MainAction.invoiceFromTask:
          await runInvoiceFromTaskFlow(log, ops, client);
        case _MainAction.exit:
          running = false;
      }
    } on ApiException catch (e) {
      log.err('[API] $e');
    } on NetworkException catch (e) {
      log.err('[Network] $e');
    } on LookupException catch (e) {
      log.err('[Lookup] $e');
    } catch (e, st) {
      log
        ..err('[Error] $e')
        ..detail('$st');
    }

    if (running && action != _MainAction.exit) {
      log.info('');
    }
  }

  log.success('Goodbye.');
}
