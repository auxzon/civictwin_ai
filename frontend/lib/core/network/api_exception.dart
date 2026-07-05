/// Exception thrown when the backend returns a non-2xx response.
///
/// Mirrors the unified error shape produced by `core/exceptions.py`:
/// `{"error": {"code": "...", "message": "..."}}`.
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  final int statusCode;
  final String code;
  final String message;

  /// True for HTTP 401/403 — the caller should re-authenticate.
  bool get isAuthError => statusCode == 401 || statusCode == 403;

  /// True for HTTP 429 — the caller hit the backend's rate limit
  /// (15 req/min per EDD V2 Document 03).
  bool get isRateLimited => statusCode == 429;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
