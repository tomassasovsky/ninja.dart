import 'package:invoice_ninja_client/src/models/json_read.dart';

/// Extracts `data` object from a standard Invoice Ninja API wrapper.
Map<String, dynamic> parseResponseData(Map<String, dynamic> response) {
  final d = response['data'];
  return asJsonMap(d);
}
