import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';
import 'session.dart';

/// Thin REST client over `package:http`.
///
/// - Prefixes every path with the API root.
/// - Attaches the bearer token from [Session] automatically.
/// - Decodes JSON and turns non-2xx responses into [ApiException]s, parsing the
///   backend's `{ "error": ..., "code": ... }` envelope when present.
/// - On 401 clears the session and calls [onUnauthenticated] if set.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// Set once in main.dart to navigate to the login screen on 401.
  static void Function()? onUnauthenticated;

  final http.Client _http = http.Client();

  Map<String, String> _headers({bool json = true}) {
    final h = <String, String>{'Accept': 'application/json'};
    if (json) h['Content-Type'] = 'application/json';
    final token = Session.instance.accessToken;
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = path.startsWith('http')
        ? path
        : '${AppConfig.apiRoot}${path.startsWith('/') ? '' : '/'}$path';
    final uri = Uri.parse(base);
    if (query == null || query.isEmpty) return uri;
    final qp = <String, String>{};
    query.forEach((k, v) {
      if (v != null) qp[k] = '$v';
    });
    return uri.replace(queryParameters: {...uri.queryParameters, ...qp});
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _http
          .get(_uri(path, query), headers: _headers())
          .timeout(AppConfig.httpTimeout));

  Future<dynamic> post(String path, {Object? body}) => _send(() => _http
      .post(_uri(path), headers: _headers(), body: jsonEncode(body ?? {}))
      .timeout(AppConfig.httpTimeout));

  Future<dynamic> put(String path, {Object? body}) => _send(() => _http
      .put(_uri(path), headers: _headers(), body: jsonEncode(body ?? {}))
      .timeout(AppConfig.httpTimeout));

  Future<dynamic> delete(String path) => _send(() => _http
      .delete(_uri(path), headers: _headers(json: false))
      .timeout(AppConfig.httpTimeout));

  /// Uploads a file via multipart/form-data to [path] (field name "file").
  /// Returns the decoded JSON body.
  Future<dynamic> uploadFile(String path, String filePath,
      {String field = 'file'}) async {
    final req = http.MultipartRequest('POST', _uri(path));
    final token = Session.instance.accessToken;
    if (token != null && token.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $token';
    }
    req.files.add(await http.MultipartFile.fromPath(field, filePath));
    return _send(() async {
      final streamed = await req.send().timeout(const Duration(seconds: 60));
      return http.Response.fromStream(streamed);
    });
  }

  Future<dynamic> _send(Future<http.Response> Function() run) async {
    http.Response res;
    try {
      res = await run();
    } catch (e) {
      throw ApiException(0, 'Network error. Check your connection.', code: 'network');
    }

    final contentType = res.headers['content-type'] ?? '';
    final body = res.body.isEmpty ? null : _tryDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      // A 2xx with HTML body almost always means an auth redirect was followed.
      if (contentType.contains('text/html')) {
        await Session.instance.clear();
        ApiClient.onUnauthenticated?.call();
        throw ApiException(401, 'Session expired. Please log in again.');
      }
      return body;
    }

    if (res.statusCode == 401) {
      await Session.instance.clear();
      debugPrint('[ApiClient] onUnauthenticated = ${ApiClient.onUnauthenticated}');
      ApiClient.onUnauthenticated?.call();
    }

    String message = 'Request failed (${res.statusCode})';
    String? code;
    if (body is Map) {
      message = (body['error'] ?? body['message'] ?? body['title'] ?? message).toString();
      code = body['code']?.toString();
    }
    throw ApiException(res.statusCode, message, code: code);
  }

  dynamic _tryDecode(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {
      return s;
    }
  }
}
