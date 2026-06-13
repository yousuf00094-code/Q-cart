/// Compile-time environment configuration.
///
/// Select an environment at build / run time via --dart-define:
///
///   Mock mode — fully offline with local sample data (default for web demo):
///     flutter run
///     flutter run --dart-define=APP_ENV=mock
///
///   Development (local backend, port 3000):
///     flutter run --dart-define=APP_ENV=dev
///
///   Staging:
///     flutter run --dart-define=APP_ENV=staging
///
///   Production (live backend):
///     flutter run --dart-define=APP_ENV=production
///     flutter build web --release --dart-define=APP_ENV=production
///
///   Explicit URL override (takes precedence over APP_ENV):
///     flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/v1
///
/// Note: on Android emulators use 10.0.2.2 instead of localhost.
class AppEnvironment {
  AppEnvironment._();

  // Compile-time constants — values are baked in at build time.
  // Default is 'mock' so the web demo works without a running backend.
  static const _env         = String.fromEnvironment('APP_ENV',      defaultValue: 'mock');
  static const _explicitUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// True when the app uses local mock data instead of the real API.
  static bool get useMockData => _env == 'mock';

  /// The API base URL for all network requests.
  /// An explicit API_BASE_URL always wins over APP_ENV.
  static String get apiBaseUrl {
    if (_explicitUrl.isNotEmpty) return _explicitUrl;
    switch (_env) {
      case 'mock':
        return 'http://localhost/mock';
      case 'dev':
        return 'http://localhost:3000/v1';
      case 'staging':
        return 'https://qcart-api-staging.onrender.com/v1';
      default:
        return 'https://qcart-api.onrender.com/v1';
    }
  }

  static String get name       => _env;
  static bool   get isDev        => _env == 'dev';
  static bool   get isStaging    => _env == 'staging';
  static bool   get isProduction => _env == 'production';
}
