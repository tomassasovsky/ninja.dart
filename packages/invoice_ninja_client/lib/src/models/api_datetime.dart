/// Parses API date/time values into [DateTime].
library;

/// Instant in time (`created_at`, `updated_at`): unix seconds/ms or ISO string.
DateTime? parseApiInstant(Object? v) {
  if (v == null) return null;
  if (v is int) {
    final ms = v >= 1000000000000 ? v : v * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
  if (v is num) {
    final i = v.toInt();
    final ms = i >= 1000000000000 ? i : i * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
  if (v is String) {
    final t = v.trim();
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    if (n != null) {
      final ms = n >= 1000000000000 ? n : n * 1000;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return DateTime.tryParse(t);
  }
  return null;
}

/// Calendar day only (`date`, `due_date`): `YYYY-MM-DD`, unix seconds/ms, or [DateTime].
DateTime? parseApiCalendarDate(Object? v) {
  if (v == null) return null;
  if (v is DateTime) {
    return DateTime(v.year, v.month, v.day);
  }
  if (v is String) {
    final t = v.trim();
    if (t.isEmpty) return null;
    final d = DateTime.tryParse(t);
    if (d != null) return DateTime(d.year, d.month, d.day);
  }
  if (v is num) {
    final i = v.toInt();
    final ms = i >= 1000000000000 ? i : i * 1000;
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateTime(d.year, d.month, d.day);
  }
  return null;
}
