import 'dart:io';

import 'package:args/args.dart';
import 'package:invoice_ninja_scripts/invoice_ninja_scripts.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('client-id', help: 'Client hashed id', mandatory: true)
    ..addOption('project-id', help: 'Project hashed id', mandatory: true)
    ..addOption('assigned-user-id', help: 'User hashed id', mandatory: true)
    ..addOption(
      'description',
      abbr: 'd',
      help: 'Task description',
      mandatory: true,
    )
    ..addOption('rate', help: 'Hourly rate', mandatory: true)
    ..addMultiOption(
      'range',
      help: 'Inclusive weekday date range YYYY-MM-DD:YYYY-MM-DD (repeatable)',
    )
    ..addOption('start-hour', defaultsTo: '9')
    ..addOption('end-hour', defaultsTo: '17')
    ..addFlag('help', abbr: 'h', negatable: false);
  addApiOptions(parser);

  final r = parser.parse(args);
  if (r['help'] == true) {
    stdout
      ..writeln(
        'Usage: dart run bin/create_task.dart --client-id ... --project-id ... '
        '--assigned-user-id ... --description "..." --rate 30 '
        '--range 2026-02-02:2026-02-13 --range 2026-02-23:2026-03-13',
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

    final rangeStrs = r['range'] as List<String>;
    if (rangeStrs.isEmpty) {
      stderr.writeln(
        '[ERROR] Provide at least one --range YYYY-MM-DD:YYYY-MM-DD',
      );
      exit(1);
    }
    final ranges = <(DateTime, DateTime)>[];
    for (final s in rangeStrs) {
      final parts = s.split(':');
      if (parts.length != 2) {
        stderr.writeln(
          '[ERROR] Bad --range "$s" (expected YYYY-MM-DD:YYYY-MM-DD)',
        );
        exit(1);
      }
      ranges.add((DateTime.parse(parts[0]), DateTime.parse(parts[1])));
    }

    final startHour = int.parse(r['start-hour'] as String);
    final endHour = int.parse(r['end-hour'] as String);
    final rate = double.parse(r['rate'] as String);

    final timeLog = buildWeekdayTimeLog(
      ranges: ranges,
      startHour: startHour,
      endHour: endHour,
    );

    stdout.writeln(
      'Time entries: ${timeLog.length} weekdays, '
      '${timeLog.length * (endHour - startHour)} hours total',
    );

    final data = await InvoiceNinjaOps(ninja).createTask(
      clientId: r['client-id'] as String,
      projectId: r['project-id'] as String,
      assignedUserId: r['assigned-user-id'] as String,
      description: r['description'] as String,
      rate: rate,
      ranges: ranges,
      startHour: startHour,
      endHour: endHour,
    );
    stdout
      ..writeln('task id: ${data.id}')
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
