import 'package:invoice_ninja_client/src/models/api_response.dart';
import 'package:invoice_ninja_client/src/models/json_read.dart';
import 'package:invoice_ninja_client/src/models/project.dart';
import 'package:invoice_ninja_client/src/transport.dart';

class ProjectsApi {
  ProjectsApi(this._t);
  final InvoiceNinjaTransport _t;

  /// `POST /api/v1/projects`
  Future<Project> create(Map<String, dynamic> body) async {
    final res = await _t.post('/api/v1/projects', body);
    return Project.fromJson(parseResponseData(res));
  }

  /// `GET /api/v1/projects` (all pages)
  Future<List<Project>> listAll([Map<String, String>? extraQuery]) async {
    final raw = await _t.fetchAllPages(
      '/api/v1/projects',
      extraQuery: extraQuery,
    );
    return raw.map((e) => Project.fromJson(asJsonMap(e))).toList();
  }

  /// `GET /api/v1/projects/{id}`
  Future<Project> get(String id, [Map<String, String>? query]) async {
    final res = await _t.get('/api/v1/projects/$id', query);
    return Project.fromJson(parseResponseData(res));
  }
}
