import 'dart:convert';

/// One `[start, end]` segment of a task `time_log` (Unix seconds).
class TimeLogEntry {
  const TimeLogEntry({
    required this.startUnixSeconds,
    required this.endUnixSeconds,
  });

  final int startUnixSeconds;
  final int endUnixSeconds;
}

/// Parses Invoice Ninja `time_log` (JSON array string, decoded list, 
/// or absent).
List<TimeLogEntry> parseTimeLogRaw(Object? raw) {
  if (raw == null) return const [];
  if (raw is String) {
    if (raw.trim().isEmpty) return const [];
    final decoded = jsonDecode(raw);
    return parseTimeLogRaw(decoded);
  }
  if (raw is List) {
    final out = <TimeLogEntry>[];
    for (final e in raw) {
      if (e is! List || e.length < 2) continue;
      final a = (e[0] as num).toInt();
      final b = (e[1] as num).toInt();
      if (b > a) {
        out.add(TimeLogEntry(startUnixSeconds: a, endUnixSeconds: b));
      }
    }
    return out;
  }
  return const [];
}

/// Shape expected by hour/calendar helpers: `[[startSec, endSec], ...]`.
List<List<int>> timeLogEntryToSecondPairs(List<TimeLogEntry> entries) =>
    entries.map((e) => [e.startUnixSeconds, e.endUnixSeconds]).toList();
