/// Internal: retryable network/transport failure.
class TransientException implements Exception {
  TransientException(this.message);

  final String message;

  @override
  String toString() => message;
}
