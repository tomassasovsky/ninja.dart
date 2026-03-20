/// Minimal surface used by resource APIs (avoids circular imports).
abstract class InvoiceNinjaTransport {
  Future<Map<String, dynamic>> get(String path, [Map<String, String>? query]);

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body);

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body);

  Future<List<dynamic>> fetchAllPages(
    String path, {
    Map<String, String>? extraQuery,
  });

  void close();
}
