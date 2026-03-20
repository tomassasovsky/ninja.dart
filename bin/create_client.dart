import 'dart:io';

import 'package:args/args.dart';
import 'package:invoice_ninja_scripts/invoice_ninja_scripts.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('name', abbr: 'n', help: 'Client display name', mandatory: true)
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage');
  addApiOptions(parser);

  final r = parser.parse(args);
  if (r['help'] == true) {
    stdout
      ..writeln('Usage: dart run bin/create_client.dart --name "Acme Co"')
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
    stdout.writeln('Creating client "$name"…');
    final data = await InvoiceNinjaOps(ninja).createClient(name);
    stdout
      ..writeln('id: ${data.id}')
      ..writeln('number: ${data.number}');
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
