import 'package:mason_logger/mason_logger.dart';

double promptDouble(Logger log, String message, {double? defaultValue}) {
  while (true) {
    final s = log.prompt(message, defaultValue: defaultValue?.toString());
    final v = double.tryParse(s.trim());
    if (v != null) return v;
    if (defaultValue != null && s.trim().isEmpty) return defaultValue;
    log.warn('Enter a valid number.');
  }
}

int promptInt(Logger log, String message, {int? defaultValue}) {
  while (true) {
    final s = log.prompt(message, defaultValue: defaultValue?.toString());
    final v = int.tryParse(s.trim());
    if (v != null) return v;
    if (defaultValue != null && s.trim().isEmpty) return defaultValue;
    log.warn('Enter a valid integer.');
  }
}
