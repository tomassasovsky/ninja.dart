import 'dart:io';

import 'package:args/args.dart';
import 'package:invoice_ninja_scripts/invoice_ninja_scripts.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('client-id', help: 'Client hashed id', mandatory: true)
    ..addOption('name', abbr: 'n', help: 'Project name', mandatory: true)
    ..addOption(
      'task-rate',
      help: 'Default task rate (numeric)',
      defaultsTo: '0',
    )
    ..addFlag('help', abbr: 'h', negatable: false);
  addApiOptions(parser);

  final r = parser.parse(args);
  if (r['help'] == true) {
    stdout
      ..writeln(
        'Usage: dart run bin/create_project.dart --client-id xxx --name "My project"',
      )
      ..writeln(parser.usage);
    exit(0);
  }
  final profileExit = tryProfileCliExitCode(r);
  if (profileExit != null) exit(profileExit);

  InvoiceNinjaClient? client;
  try {
    final cfg = configFromArgs(r);
    final ninja = InvoiceNinjaClient(config: cfg.toInvoiceNinjaConfig());
    client = ninja;
    final name = r['name'] as String;
    final clientId = r['client-id'] as String;
    final rate = double.tryParse(r['task-rate'] as String) ?? 0;
    stdout.writeln('Creating project "$name" for client $clientId…');
    final data = await InvoiceNinjaOps(
      ninja,
    ).createProject(clientId: clientId, name: name, taskRate: rate);
    stdout.writeln('id: ${data.id}');
  } on ScriptConfigException catch (e) {
    stderr.writeln('[ERROR] $e');
    exit(1);
  } on ApiException catch (e) {
    stderr.writeln('[ERROR] API: $e');
    exit(1);
  } on NetworkException catch (e) {
    stderr.writeln('[ERROR] Network: $e');
    exit(1);
  } catch (e, st) {
    stderr.writeln('[ERROR] $e\n$st');
    exit(1);
  } finally {
    client?.close();
  }
}
