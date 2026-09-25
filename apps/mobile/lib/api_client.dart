import 'dart:convert';

import 'package:http/http.dart' as http;

typedef AccessTokenProvider = Future<String?> Function();

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({
    required this.baseUrl,
    this.accessTokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final AccessTokenProvider? accessTokenProvider;
  final http.Client _client;

  Future<Map<String, dynamic>> get(String path) =>
      _request('GET', path);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) =>
      _request('POST', path, body: body);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = await accessTokenProvider?.call();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final normalizedBase =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final requestUri = Uri.parse('$normalizedBase$normalizedPath');

    final http.Response response;
    try {
      response = switch (method) {
        'GET' => await _client.get(requestUri, headers: headers),
        'POST' => await _client.post(
            requestUri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          ),
        _ => throw ApiException('Unsupported HTTP method: $method'),
      };
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error or server unreachable: $e');
    }

    Map<String, dynamic> decoded = <String, dynamic>{};
    if (response.body.isNotEmpty) {
      try {
        final parsed = jsonDecode(response.body);
        if (parsed is Map<String, dynamic>) {
          decoded = parsed;
        } else {
          decoded = {'value': parsed};
        }
      } catch (_) {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw ApiException(
            response.body.isNotEmpty ? response.body : 'Request failed',
            statusCode: response.statusCode,
          );
        }
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Request failed';
      final error = decoded['error'];
      if (error is Map<String, dynamic> && error['message'] != null) {
        message = error['message'].toString();
      } else if (decoded['detail'] != null) {
        final detail = decoded['detail'];
        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          message = first is Map
              ? (first['msg']?.toString() ?? detail.toString())
              : detail.toString();
        } else {
          message = detail.toString();
        }
      } else if (decoded['message'] != null) {
        message = decoded['message'].toString();
      }
      throw ApiException(message, statusCode: response.statusCode);
    }

    if (decoded['success'] == false) {
      final error = decoded['error'];
      final message = error is Map<String, dynamic>
          ? (error['message']?.toString() ?? 'Request failed')
          : (decoded['message']?.toString() ?? 'Request failed');
      throw ApiException(message, statusCode: response.statusCode);
    }

    if (decoded.containsKey('data')) {
      final data = decoded['data'];
      return data is Map<String, dynamic> ? data : {'value': data};
    }

    return decoded;
  }

  void close() => _client.close();
}
