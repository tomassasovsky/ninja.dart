/// Invoice Ninja returned a non-200 response or invalid JSON where JSON 
/// was required.
class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Retries were exhausted for a transient network failure.
class NetworkException implements Exception {
  NetworkException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Lookup of a named entity (e.g. user) failed.
class LookupException implements Exception {
  LookupException(this.message);

  final String message;

  @override
  String toString() => message;
}
