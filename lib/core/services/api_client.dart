import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';

class ApiClient {
  static String get baseUrl => AppEnvironment.apiBaseUrl;

  static String? _accessToken;

  static void setToken(String token) => _accessToken = token;
  static void clearToken() => _accessToken = null;
  static bool get hasToken => _accessToken != null;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  static Future<Map<String, dynamic>> get(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    return _handle(response);
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: json.encode(body),
    );
    return _handle(response);
  }

  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: json.encode(body),
    );
    return _handle(response);
  }

  static Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: json.encode(body),
    );
    return _handle(response);
  }

  static Future<void> delete(String path) async {
    final response = await http.delete(Uri.parse('$baseUrl$path'), headers: _headers);
    _handle(response);
  }

  static Future<Map<String, dynamic>> uploadFile(
      String path, String filePath, String fieldName) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);
    if (_accessToken != null) {
      request.headers['Authorization'] = 'Bearer $_accessToken';
    }
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handle(response);
  }

  static Map<String, dynamic> _handle(http.Response response) {
    final decoded = json.decode(utf8.decode(response.bodyBytes));
    final body = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'data': decoded};

    if (response.statusCode >= 400) {
      final err = body['error'] as Map<String, dynamic>?;
      throw ApiException(
        message: err?['message']?.toString() ?? 'Request failed',
        code: err?['code']?.toString() ?? 'UNKNOWN',
        statusCode: response.statusCode,
      );
    }
    return body;
  }
}

class ApiException implements Exception {
  final String message;
  final String code;
  final int statusCode;

  const ApiException({
    required this.message,
    required this.code,
    required this.statusCode,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden    => statusCode == 403;
  bool get isNotFound     => statusCode == 404;
  bool get isConflict     => statusCode == 409;
  bool get isValidation   => statusCode == 422;

  @override
  String toString() => 'ApiException[$statusCode/$code]: $message';
}
