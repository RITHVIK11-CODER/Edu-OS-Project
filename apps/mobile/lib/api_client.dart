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

    final requestUri = Uri.parse('$baseUrl$path');
    final response = switch (method) {
      'GET' => await _client.get(requestUri, headers: headers),
      'POST' => await _client.post(
          requestUri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        ),
      _ => throw ApiException('Unsupported HTTP method: $method'),
    };

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded['error'];
      final message = error is Map<String, dynamic>
          ? (error['message']?.toString() ?? 'Request failed')
          : 'Request failed';
      throw ApiException(message, statusCode: response.statusCode);
    }

    if (decoded['success'] == false) {
      final error = decoded['error'];
      final message = error is Map<String, dynamic>
          ? (error['message']?.toString() ?? 'Request failed')
          : 'Request failed';
      throw ApiException(message, statusCode: response.statusCode);
    }

    final data = decoded['data'];
    return data is Map<String, dynamic> ? data : {'value': data};
  }

  void close() => _client.close();
}
