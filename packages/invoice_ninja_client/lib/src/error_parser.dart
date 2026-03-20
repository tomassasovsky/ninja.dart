import 'dart:convert';

/// Parses Laravel-style JSON error bodies from Invoice Ninja.
String parseInvoiceNinjaApiError(String path, int status, String body) {
  try {
    final d = jsonDecode(body) as Map;
    final parts = <String>[];
    if (d['message'] != null) parts.add('${d['message']}');
    if (d['errors'] is Map) {
      (d['errors'] as Map).forEach(
        (k, v) => parts.add('  $k: ${v is List ? v.join(', ') : v}'),
      );
    }
    if (parts.isNotEmpty) return '$path → HTTP $status:\n${parts.join('\n')}';
  } catch (_) {}
  return '$path → HTTP $status: $body';
}
