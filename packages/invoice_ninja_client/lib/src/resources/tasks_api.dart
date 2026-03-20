import 'package:invoice_ninja_client/src/models/api_response.dart';
import 'package:invoice_ninja_client/src/models/json_read.dart';
import 'package:invoice_ninja_client/src/models/task.dart';
import 'package:invoice_ninja_client/src/transport.dart';

class TasksApi {
  TasksApi(this._t);
  final InvoiceNinjaTransport _t;

  /// `POST /api/v1/tasks`
  Future<Task> create(Map<String, dynamic> body) async {
    final res = await _t.post('/api/v1/tasks', body);
    return Task.fromJson(parseResponseData(res));
  }

  /// `GET /api/v1/tasks` (all pages)
  Future<List<Task>> listAll([Map<String, String>? extraQuery]) async {
    final raw = await _t.fetchAllPages('/api/v1/tasks', extraQuery: extraQuery);
    return raw.map((e) => Task.fromJson(asJsonMap(e))).toList();
  }

  /// `GET /api/v1/tasks/{id}`
  Future<Task> get(String id, [Map<String, String>? query]) async {
    final res = await _t.get('/api/v1/tasks/$id', query);
    return Task.fromJson(parseResponseData(res));
  }
}
