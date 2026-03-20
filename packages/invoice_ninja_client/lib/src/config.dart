/// @docImport 'package:invoice_ninja_client/invoice_ninja_client.dart';
library;

/// Connection and retry settings for [InvoiceNinjaClient].
class InvoiceNinjaConfig {
  InvoiceNinjaConfig({
    required Uri baseUri,
    required this.apiToken,
    this.timeout = const Duration(seconds: 60),
    this.maxRetries = 4,
    this.initialRetryDelay = const Duration(seconds: 3),
    this.onRequest,
  }) : baseUri = _normalizeBaseUri(baseUri);

  /// Base URL without a trailing slash, e.g. `https://app.example.com`
  final Uri baseUri;

  /// App URL path under [baseUri] (e.g. `invoices/abc`). Leading `/` on [path] is ignored.
  Uri joinPath(String path) {
    final p = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$baseUri/$p');
  }

  static Uri _normalizeBaseUri(Uri uri) {
    final s = uri.toString().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse(s);
  }

  /// `X-API-TOKEN` value.
  final String apiToken;

  final Duration timeout;
  final int maxRetries;
  final Duration initialRetryDelay;

  /// Optional hook for logging or auditing (method, path, status, decoded body
  /// or raw string).
  final void Function(String method, String path, int statusCode, Object? body)?
  onRequest;
}
