import 'dart:io';

/// Placeholder entrypoint — use the specific scripts in `bin/` instead.
void main(List<String> args) {
  stdout
    ..writeln('Use one of:')
    ..writeln('  dart run bin/create_client.dart --help')
    ..writeln('  dart run bin/create_project.dart --help')
    ..writeln('  dart run bin/lookup_user.dart --help')
    ..writeln('  dart run bin/create_task.dart --help')
    ..writeln('  dart run bin/invoice_from_task.dart --help')
    ..writeln('  dart run bin/ninja.dart --help   # interactive menu');
  exit(0);
}
