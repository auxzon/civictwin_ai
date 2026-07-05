import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_config.dart';
import 'api_exception.dart';

/// Function that returns the current user's Firebase ID token, or null if
/// unauthenticated. Injected rather than calling `firebase_auth` directly
/// here, so this client stays testable without a real Firebase app.
typedef TokenProvider = Future<String?> Function();

/// Thin wrapper around [http.Client] for talking to the CivicTwin AI
/// backend (Decision 5/6: REST only, backend-mediated — this is the
/// *only* place Flutter makes network calls for application data).
class ApiClient {
  ApiClient({required TokenProvider tokenProvider, http.Client? httpClient})
    : _tokenProvider = tokenProvider,
      _httpClient = httpClient ?? http.Client();

  final TokenProvider _tokenProvider;
  final http.Client _httpClient;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String> queryParams = const {},
  }) async {
    final token = await _tokenProvider();
    if (token == null) {
      throw const ApiException(
        statusCode: 401,
        code: 'unauthenticated',
        message: 'No authenticated user. Sign in before calling the API.',
      );
    }

    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}$path',
    ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    final response = await _httpClient
        .get(uri, headers: {'Authorization': 'Bearer $token'})
        .timeout(AppConfig.apiTimeout);

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toApiException(response.statusCode, decoded);
    }

    return decoded;
  }

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final token = await _tokenProvider();
    if (token == null) {
      throw const ApiException(
        statusCode: 401,
        code: 'unauthenticated',
        message: 'No authenticated user. Sign in before calling the API.',
      );
    }

    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');

    final response = await _httpClient
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(AppConfig.apiTimeout);

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toApiException(response.statusCode, decoded);
    }

    return decoded;
  }

  ApiException _toApiException(int statusCode, Map<String, dynamic> decoded) {
    final error = decoded['error'] as Map<String, dynamic>?;
    return ApiException(
      statusCode: statusCode,
      code: error?['code'] as String? ?? 'unknown_error',
      message: error?['message'] as String? ?? 'An unknown error occurred.',
    );
  }

  void dispose() => _httpClient.close();
}
