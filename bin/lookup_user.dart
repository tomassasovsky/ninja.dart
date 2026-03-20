import 'dart:io';

import 'package:args/args.dart';
import 'package:invoice_ninja_scripts/invoice_ninja_scripts.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('first-name', help: 'User first name', mandatory: true)
    ..addOption('last-name', help: 'User last name', mandatory: true)
    ..addFlag('help', abbr: 'h', negatable: false);
  addApiOptions(parser);

  final r = parser.parse(args);
  if (r['help'] == true) {
    stdout
      ..writeln(
        'Usage: dart run bin/lookup_user.dart --first-name Tom --last-name Smith',
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
    final first = r['first-name'] as String;
    final last = r['last-name'] as String;
    final u = await InvoiceNinjaOps(
      ninja,
    ).lookupUser(firstName: first, lastName: last);
    stdout
      ..writeln('id: ${u.id}')
      ..writeln('email: ${u.email}');
  } on ScriptConfigException catch (e) {
    stderr.writeln('[ERROR] $e');
    exit(1);
  } on LookupException catch (e) {
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
