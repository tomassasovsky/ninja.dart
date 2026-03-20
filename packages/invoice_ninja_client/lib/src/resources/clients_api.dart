import 'package:invoice_ninja_client/src/models/api_response.dart';
import 'package:invoice_ninja_client/src/models/client.dart';
import 'package:invoice_ninja_client/src/models/json_read.dart';
import 'package:invoice_ninja_client/src/transport.dart';

class ClientsApi {
  ClientsApi(this._t);
  final InvoiceNinjaTransport _t;

  /// `POST /api/v1/clients`
  Future<Client> create(Map<String, dynamic> body) async {
    final res = await _t.post('/api/v1/clients', body);
    return Client.fromJson(parseResponseData(res));
  }

  /// `GET /api/v1/clients` (all pages)
  Future<List<Client>> listAll([Map<String, String>? extraQuery]) async {
    final raw = await _t.fetchAllPages(
      '/api/v1/clients',
      extraQuery: extraQuery,
    );
    return raw.map((e) => Client.fromJson(asJsonMap(e))).toList();
  }

  /// `GET /api/v1/clients/{id}`
  Future<Client> get(String id, [Map<String, String>? query]) async {
    final res = await _t.get('/api/v1/clients/$id', query);
    return Client.fromJson(parseResponseData(res));
  }
}
