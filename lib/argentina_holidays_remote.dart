/// Loads Argentina feriados from a **JSON HTTP API** and applies them as
/// overrides (`applyArgentinaRemoteCalendarForYear` in this package).
///
/// We do **not** scrape `argentina.gob.ar` HTML: pages often return 403 to
/// bots, markup changes, and there is no stable public schema. Third-party
/// [ArgentinaDatos](https://argentinadatos.com) exposes `GET /v1/feriados/{año}`
/// with the same calendar fields (inamovible, trasladable, puente).
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:invoice_ninja_scripts/argentina_holidays.dart';
import 'package:invoice_ninja_scripts/profile_store.dart';
import 'package:path/path.dart' as p;

/// Result of [refreshArgentinaHolidaysRemote] (one entry per requested year).
final class ArgentinaRemoteRefreshResult {
  const ArgentinaRemoteRefreshResult({
    required this.yearsUpdatedFromNetwork,
    required this.yearsUpdatedFromCache,
    required this.yearsFailed,
  });

  /// Fetched over HTTP and written to disk cache.
  final List<int> yearsUpdatedFromNetwork;

  /// Loaded from TTL cache on disk (no HTTP).
  final List<int> yearsUpdatedFromCache;

  /// No usable cache and HTTP failed (or non-200 / parse error).
  final List<int> yearsFailed;
}

/// JSON `GET https://api.argentinadatos.com/v1/feriados/{year}`.
///
/// Splits `tipo`: `puente` → tourism; `inamovible` and `trasladable` →
/// national public holidays.
({Set<String> national, Set<String> tourism}) parseArgentinaDatosFeriadosJson(
  String json,
) {
  final decoded = jsonDecode(json);
  if (decoded is! List<Object?>) {
    throw FormatException('expected JSON array', json);
  }
  final national = <String>{};
  final tourism = <String>{};
  for (final e in decoded) {
    if (e is! Map<String, dynamic>) continue;
    final fecha = e['fecha'];
    final tipo = e['tipo'];
    if (fecha is! String || fecha.length < 10) continue;
    final ymd = fecha.substring(0, 10);
    if (tipo == 'puente') {
      tourism.add(ymd);
    } else if (tipo == 'inamovible' || tipo == 'trasladable') {
      national.add(ymd);
    }
  }
  return (national: national, tourism: tourism);
}

bool _skipRemoteFromEnv() {
  final v =
      Platform.environment['INVOICE_NINJA_SKIP_FERIADOS_REMOTE']?.toLowerCase();
  return v == '1' || v == 'true' || v == 'yes';
}

String _cacheFilePath(int year) => p.join(
  ProfileStore.configDirectoryPath(),
  'feriados_remote_$year.json',
);

/// Reads [path] if younger than [ttl]; returns raw JSON body or `null`.
String? _readCacheIfFresh(String path, Duration ttl) {
  final f = File(path);
  if (!f.existsSync()) return null;
  final age = DateTime.now().difference(f.lastModifiedSync());
  if (age > ttl) return null;
  return f.readAsStringSync();
}

void _writeCache(String path, String jsonBody) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(jsonBody);
}

Future<String?> _httpGetBody(String url) async {
  final uri = Uri.parse(url);
  final res = await http
      .get(
        uri,
        headers: {
          'User-Agent': 'invoice_ninja_scripts (Dart; feriados refresh)',
          'Accept': 'application/json',
        },
      )
      .timeout(const Duration(seconds: 15));
  if (res.statusCode != 200) return null;
  return res.body;
}

/// Fetches calendar data for [years], applies overrides, and caches responses.
///
/// Set `INVOICE_NINJA_SKIP_FERIADOS_REMOTE=1` to keep embedded/local logic only
/// (no HTTP, no cache read).
///
/// [ttl] avoids hitting the API on every task creation; use [force] to ignore
/// TTL and re-fetch.
Future<ArgentinaRemoteRefreshResult> refreshArgentinaHolidaysRemote(
  Iterable<int> years, {
  bool force = false,
  Duration ttl = const Duration(hours: 24),
}) async {
  if (_skipRemoteFromEnv()) {
    return const ArgentinaRemoteRefreshResult(
      yearsUpdatedFromNetwork: [],
      yearsUpdatedFromCache: [],
      yearsFailed: [],
    );
  }

  final fromNet = <int>[];
  final fromCache = <int>[];
  final failed = <int>[];

  for (final year in years.toSet()) {
    final path = _cacheFilePath(year);
    String? body;

    if (!force) {
      body = _readCacheIfFresh(path, ttl);
      if (body != null) {
        try {
          final parsed = parseArgentinaDatosFeriadosJson(body);
          applyArgentinaRemoteCalendarForYear(
            year,
            nationalHolidayYmd: parsed.national,
            tourismPuenteYmd: parsed.tourism,
          );
          fromCache.add(year);
        } catch (_) {
          body = null;
        }
      }
    }

    if (body != null) continue;

    final url = 'https://api.argentinadatos.com/v1/feriados/$year';
    final fetched = await _httpGetBody(url);
    if (fetched == null) {
      failed.add(year);
      continue;
    }
    try {
      final parsed = parseArgentinaDatosFeriadosJson(fetched);
      applyArgentinaRemoteCalendarForYear(
        year,
        nationalHolidayYmd: parsed.national,
        tourismPuenteYmd: parsed.tourism,
      );
      _writeCache(path, fetched);
      fromNet.add(year);
    } catch (_) {
      failed.add(year);
    }
  }

  return ArgentinaRemoteRefreshResult(
    yearsUpdatedFromNetwork: fromNet,
    yearsUpdatedFromCache: fromCache,
    yearsFailed: failed,
  );
}
