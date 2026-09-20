import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const root = 'https://whats.alattab.site/takhfid/api/v4';
  static const tokenKey = 'takhfid_access_token';

  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  Future<String?> token() async => (await prefs).getString(tokenKey);

  Future<void> saveToken(String value) async {
    await (await prefs).setString(tokenKey, value);
  }

  Future<void> clearToken() async {
    await (await prefs).remove(tokenKey);
  }

  Uri uri(
    String path, {
    Map<String, String>? query,
  }) {
    final base = Uri.parse(
      root + (path.startsWith('/') ? path : '/$path'),
    );
    return query == null || query.isEmpty
        ? base
        : base.replace(
            queryParameters: {
              ...base.queryParameters,
              ...query,
            },
          );
  }

  Future<Map<String, String>> headers({bool json = false}) async {
    final h = <String, String>{'Accept': 'application/json'};
    if (json) h['Content-Type'] = 'application/json';
    final value = await token();
    if (value != null && value.isNotEmpty) {
      h['Authorization'] = 'Bearer $value';
    }
    return h;
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await http
        .get(
          uri(path, query: query),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 20));
    return decode(response);
  }

  Future<dynamic> send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final h = await headers(json: true);
    final encoded = body == null ? null : jsonEncode(body);
    final url = uri(path);
    late http.Response response;

    if (method == 'POST') {
      response = await http
          .post(url, headers: h, body: encoded)
          .timeout(const Duration(seconds: 20));
    } else if (method == 'PUT') {
      response = await http
          .put(url, headers: h, body: encoded)
          .timeout(const Duration(seconds: 20));
    } else if (method == 'PATCH') {
      response = await http
          .patch(url, headers: h, body: encoded)
          .timeout(const Duration(seconds: 20));
    } else if (method == 'DELETE') {
      response = await http
          .delete(url, headers: h)
          .timeout(const Duration(seconds: 20));
    } else {
      throw UnsupportedError(method);
    }

    return decode(response);
  }

  Future<dynamic> multipart(
    String path, {
    required String fieldName,
    required String fileName,
    required List<int> bytes,
    Map<String, String>? fields,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      uri(path),
    );

    request.headers.addAll(await headers());

    if (fields != null) {
      request.fields.addAll(fields);
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: fileName,
      ),
    );

    final streamed = await request
        .send()
        .timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    return decode(response);
  }

  dynamic decode(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(
        response.body.isEmpty ? '{}' : response.body,
      );
    } catch (_) {
      body = <String, dynamic>{};
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map
          ? (body['error'] ?? body['message'] ?? 'خطأ في الخادم')
          : 'خطأ في الخادم';
      throw ApiException(
        response.statusCode,
        message.toString(),
      );
    }

    return body;
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(
    this.statusCode,
    this.message,
  );

  @override
  String toString() => 'ApiException($statusCode): $message';
}
