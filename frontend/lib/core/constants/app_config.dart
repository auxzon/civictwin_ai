/// Build-time application configuration.
///
/// Values are supplied via `--dart-define` at build/run time, e.g.:
///   flutter run -d chrome \
///     --dart-define=API_BASE_URL=http://localhost:8000/api/v1
///
/// Per the frozen coding standards ("Never hardcode URLs"), no default
/// production URL is baked in here — only a localhost fallback for local
/// development convenience.
abstract final class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  /// Request timeout for backend calls. Matches the backend's own
  /// 45-second hard timeout gate (EDD V2 Document 03) plus a small buffer
  /// so the client doesn't cancel a request the server is about to
  /// successfully complete.
  static const Duration apiTimeout = Duration(seconds: 50);
}
