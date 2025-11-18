import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<http.Response> get(
      String endpoint, {
        Map<String, String>? headers,
        Duration timeout = const Duration(seconds: 10),
      }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await _client
        .get(
      uri,
      headers: _defaultHeaders(headers),
    )
        .timeout(timeout);
  }

  Future<http.Response> post(
      String endpoint, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
        Duration timeout = const Duration(seconds: 10),
      }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await _client
        .post(
      uri,
      headers: _defaultHeaders(headers),
      body: body != null ? json.encode(body) : null,
    )
        .timeout(timeout);
  }

  Future<http.Response> put(
      String endpoint, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
        Duration timeout = const Duration(seconds: 10),
      }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await _client
        .put(
      uri,
      headers: _defaultHeaders(headers),
      body: body != null ? json.encode(body) : null,
    )
        .timeout(timeout);
  }

  Future<http.Response> delete(
      String endpoint, {
        Map<String, String>? headers,
        Duration timeout = const Duration(seconds: 10),
      }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await _client
        .delete(
      uri,
      headers: _defaultHeaders(headers),
    )
        .timeout(timeout);
  }

  Map<String, String> _defaultHeaders(Map<String, String>? customHeaders) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  void close() {
    _client.close();
  }
}