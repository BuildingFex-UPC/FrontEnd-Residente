/// Backend endpoint configuration.
///
/// The base URL is injected at build time with `--dart-define=API_BASE_URL=...`
/// so the same code can hit localhost in development and the deployed backend
/// in production without source changes.
class ApiConfig {
  static const String defaultBaseUrl = 'https://backend-1-lgr7.onrender.com';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );
}
