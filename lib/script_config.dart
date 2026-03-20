import 'dart:io';

import 'package:invoice_ninja_client/invoice_ninja_client.dart';

import 'package:invoice_ninja_scripts/profile_store.dart';

/// Missing or invalid environment / CLI configuration.
class ScriptConfigException implements Exception {
  ScriptConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Resolved credentials and base URL for scripts.
class ScriptConfig {
  ScriptConfig({required this.baseUri, required this.apiToken});

  final Uri baseUri;
  final String apiToken;

  InvoiceNinjaConfig toInvoiceNinjaConfig({
    void Function(String method, String path, int status, Object? body)?
    onRequest,
  }) {
    return InvoiceNinjaConfig(
      baseUri: baseUri,
      apiToken: apiToken,
      onRequest: onRequest,
    );
  }
}

/// Reads `INVOICE_NINJA_BASE_URL` and `INVOICE_NINJA_API_TOKEN` from the
/// environment.
ScriptConfig loadScriptConfigFromEnvironment() {
  return loadScriptConfig();
}

/// Strips `/api/v1` suffix and normalizes the app origin.
Uri normalizeInvoiceNinjaBaseUri(Uri uri) {
  if (uri.path.endsWith('/api/v1')) {
    return uri.replace(
      path: uri.path.replaceAll(RegExp(r'/api/v1/?$'), ''),
    );
  }
  return uri;
}

/// Resolves base URL and token from CLI, saved profiles, and environment.
///
/// Precedence (per field): **CLI flags → explicit `--profile` → default saved
/// profile → environment variables**.
///
/// Saved profiles therefore **override** `INVOICE_NINJA_*` env vars when a
/// default profile exists (avoids stale tokens in the shell masking the
/// keychain). To force env-only or override a profile, pass `--base-url` /
/// `--token`, or unset the variables you do not want.
///
/// When [allowProfileFallback] is `false`, only flags and environment are used
/// (for `--save-profile`).
///
/// [profileStore] is for tests; production code should omit it.
ScriptConfig loadScriptConfig({
  String? baseUrlOverride,
  String? tokenOverride,
  String? profileName,
  bool allowProfileFallback = true,
  ProfileStore? profileStore,
}) {
  if (!allowProfileFallback) {
    final base = _firstNonEmpty([
      baseUrlOverride,
      Platform.environment['INVOICE_NINJA_BASE_URL'],
    ]);
    final token = _firstNonEmpty([
      tokenOverride,
      Platform.environment['INVOICE_NINJA_API_TOKEN'],
    ]);
    if (base == null || base.isEmpty) {
      throw ScriptConfigException(
        'Missing base URL: pass --base-url / -b or set INVOICE_NINJA_BASE_URL '
        '(required for --save-profile).',
      );
    }
    if (token == null || token.isEmpty) {
      throw ScriptConfigException(
        'Missing API token: pass --token / -t or set INVOICE_NINJA_API_TOKEN '
        '(required for --save-profile).',
      );
    }
    final uri = normalizeInvoiceNinjaBaseUri(Uri.parse(base));
    return ScriptConfig(baseUri: uri, apiToken: token);
  }

  var base = _firstNonEmpty([baseUrlOverride]);
  var token = _firstNonEmpty([tokenOverride]);

  final store = profileStore ?? ProfileStore();
  final explicit = profileName?.trim();

  if (explicit != null && explicit.isNotEmpty) {
    final p = store.get(explicit);
    if (p == null) {
      throw ScriptConfigException(
        'Unknown profile "$explicit". '
        'Use --list-profiles or --save-profile to add one.',
      );
    }
    base ??= p.baseUrl;
    token ??= store.resolveToken(explicit);
  } else if (base == null || token == null) {
    final def = store.defaultProfileName;
    if (def != null) {
      final p = store.get(def);
      if (p != null) {
        base ??= p.baseUrl;
        token ??= store.resolveToken(def);
      }
    }
  }

  base ??= _firstNonEmpty([Platform.environment['INVOICE_NINJA_BASE_URL']]);
  token ??= _firstNonEmpty([Platform.environment['INVOICE_NINJA_API_TOKEN']]);

  if (base == null || base.isEmpty) {
    throw ScriptConfigException(
      'Missing base URL: set INVOICE_NINJA_BASE_URL or pass --base-url / -b, '
      'or use a saved profile (--profile / -p, or save one with --save-profile).',
    );
  }
  if (token == null || token.isEmpty) {
    throw ScriptConfigException(
      'Missing API token: set INVOICE_NINJA_API_TOKEN or pass --token / -t, '
      'or use a saved profile.',
    );
  }

  final uri = normalizeInvoiceNinjaBaseUri(Uri.parse(base));
  return ScriptConfig(baseUri: uri, apiToken: token);
}

String? _firstNonEmpty(List<String?> candidates) {
  for (final c in candidates) {
    final t = c?.trim();
    if (t != null && t.isNotEmpty) return t;
  }
  return null;
}
