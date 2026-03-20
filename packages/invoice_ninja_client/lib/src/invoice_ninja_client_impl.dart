import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:invoice_ninja_client/src/config.dart';
import 'package:invoice_ninja_client/src/error_parser.dart';
import 'package:invoice_ninja_client/src/exceptions.dart';
import 'package:invoice_ninja_client/src/internal/transient.dart';
import 'package:invoice_ninja_client/src/resources/clients_api.dart';
import 'package:invoice_ninja_client/src/resources/invoices_api.dart';
import 'package:invoice_ninja_client/src/resources/projects_api.dart';
import 'package:invoice_ninja_client/src/resources/tasks_api.dart';
import 'package:invoice_ninja_client/src/resources/users_api.dart';
import 'package:invoice_ninja_client/src/transport.dart';

/// HTTP client for Invoice Ninja API v1 with resource accessors.
class InvoiceNinjaClient implements InvoiceNinjaTransport {
  InvoiceNinjaClient({
    required InvoiceNinjaConfig config,
    http.Client? httpClient,
  }) : _config = config,
       _client = httpClient ?? http.Client() {
    clients = ClientsApi(this);
    projects = ProjectsApi(this);
    users = UsersApi(this);
    tasks = TasksApi(this);
    invoices = InvoicesApi(this);
  }

  final InvoiceNinjaConfig _config;
  final http.Client _client;

  late final ClientsApi clients;
  late final ProjectsApi projects;
  late final UsersApi users;
  late final TasksApi tasks;
  late final InvoicesApi invoices;

  InvoiceNinjaConfig get config => _config;

  @override
  void close() {
    _client.close();
  }

  @override
  Future<Map<String, dynamic>> get(String path, [Map<String, String>? query]) =>
      _retry('GET $path', () => _request('GET', path, q: query));

  @override
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      _retry('POST $path', () => _request('POST', path, body: body));

  @override
  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) =>
      _retry('PUT $path', () => _request('PUT', path, body: body));

  @override
  Future<List<dynamic>> fetchAllPages(
    String path, {
    Map<String, String>? extraQuery,
  }) async {
    final items = <dynamic>[];
    var page = 1;
    while (true) {
      final q = {'per_page': '100', 'page': '$page', ...?extraQuery};
      final res = await get(path, q);
      final data = res['data'];
      if (data is! List) {
        throw ApiException('Expected list at "data" from $path');
      }
      items.addAll(data);
      final meta = res['meta'];
      final pagination = meta is Map<String, dynamic>
          ? meta['pagination']
          : null;
      final totalPagesRaw = pagination is Map<String, dynamic>
          ? pagination['total_pages']
          : null;
      final totalPages = _asInt(totalPagesRaw) ?? 1;
      if (page >= totalPages) break;
      page++;
    }
    return items;
  }

  int? _asInt(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = _config.baseUri.toString().replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Map<String, String> get _headers => {
    'X-API-TOKEN': _config.apiToken,
    'X-Requested-With': 'XMLHttpRequest',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<T> _retry<T>(String label, Future<T> Function() fn) async {
    var delay = _config.initialRetryDelay;
    for (var attempt = 1; attempt <= _config.maxRetries; attempt++) {
      try {
        return await fn();
      } on TransientException catch (e) {
        if (attempt == _config.maxRetries) {
          throw NetworkException('$label: $e');
        }
        await Future<void>.delayed(delay);
        delay = delay * 2;
      }
    }
    throw StateError('unreachable');
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, String>? q,
    Map<String, dynamic>? body,
  }) async {
    final uri = _uri(path, q);
    try {
      final encoded = body != null ? jsonEncode(body) : null;
      final http.Response res;
      switch (method) {
        case 'GET':
          res = await _client
              .get(uri, headers: _headers)
              .timeout(_config.timeout);
        case 'POST':
          res = await _client
              .post(uri, headers: _headers, body: encoded)
              .timeout(_config.timeout);
        case 'PUT':
          res = await _client
              .put(uri, headers: _headers, body: encoded)
              .timeout(_config.timeout);
        default:
          throw ArgumentError('Unsupported: $method');
      }
      final decoded = _tryDecode(res.body);
      _config.onRequest?.call(method, path, res.statusCode, decoded);
      if (res.statusCode != 200) {
        throw ApiException(
          parseInvoiceNinjaApiError(path, res.statusCode, res.body),
        );
      }
      return jsonDecode(res.body) as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw TransientException('timed out after ${_config.timeout.inSeconds}s');
    } on SocketException catch (e) {
      throw TransientException('socket: ${e.message}');
    } on http.ClientException catch (e) {
      throw TransientException('client: ${e.message}');
    } on FormatException catch (e) {
      throw ApiException('Invalid JSON in $method $path — $e');
    }
  }

  Object? _tryDecode(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {
      return s;
    }
  }
}
