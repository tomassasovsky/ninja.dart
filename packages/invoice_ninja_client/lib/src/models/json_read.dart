/// Safe reads from decoded JSON objects.
library;

Map<String, dynamic> asJsonMap(Object? v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  throw FormatException('Expected JSON object, got ${v.runtimeType}');
}

String? readString(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

int? readInt(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double readDouble(
  Map<String, dynamic> json,
  String key, [
  double defaultValue = 0,
]) {
  final v = json[key];
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? defaultValue;
  return defaultValue;
}

bool? readBool(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final t = v.toLowerCase();
    if (t == 'true' || t == '1') return true;
    if (t == 'false' || t == '0') return false;
  }
  return null;
}
