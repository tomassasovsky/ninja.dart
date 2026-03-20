import 'dart:convert';
import 'dart:io';

/// Append-only JSONL log under `logs/` for debugging API calls.
class JsonlLogger {
  JsonlLogger._(this._sink, this.path);

  final IOSink _sink;
  final String path;

  static Future<JsonlLogger> open(String basename) async {
    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceFirst('T', '_')
        .substring(0, 19);
    await Directory('logs').create(recursive: true);
    final file = File('logs/${basename}_$ts.jsonl');
    return JsonlLogger._(file.openWrite(), file.path);
  }

  void log(String event, Object? data) {
    _sink.writeln(
      jsonEncode({
        'ts': DateTime.now().toIso8601String(),
        'event': event,
        'data': data,
      }),
    );
  }

  Future<void> close() async {
    await _sink.flush();
    await _sink.close();
  }
}
