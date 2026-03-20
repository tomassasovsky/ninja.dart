import 'dart:io';

import 'package:invoice_ninja_scripts/ninja_command_runner.dart';

/// Interactive CLI for Invoice Ninja (`dart run bin/ninja.dart`).
Future<void> main(List<String> args) async {
  final code = await NinjaCommandRunner().run(args);
  exit(code ?? 0);
}
