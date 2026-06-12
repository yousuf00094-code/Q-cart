/// Compile-time environment configuration.
///
/// Select an environment at build / run time via --dart-define:
///
///   Development (local backend, port 3000):
///     flutter run --dart-define=APP_ENV=dev
///
///   Staging:
///     flutter run --dart-define=APP_ENV=staging
///
///   Production (default — no flag required):
///     flutter run
///     flutter build web --release
///
///   Explicit URL override (takes precedence over APP_ENV):
///     flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/v1
///
///   Using a preset file (Flutter >= 3.7):
///     flutter run --dart-define-from-file=dart_defines/dev.json
///
/// Note: on Android emulators use 10.0.2.2 instead of localhost.
class AppEnvironment {
  AppEnvironment._();

  // Compile-time constants — values are baked in at build time.
  static const _env         = String.fromEnvironment('APP_ENV',      defaultValue: 'production');
  static const _explicitUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// The API base URL for all network requests.
  /// An explicit API_BASE_URL always wins over APP_ENV.
  static String get apiBaseUrl {
    if (_explicitUrl.isNotEmpty) return _explicitUrl;
    switch (_env) {
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
  static bool   get isProduction => _env != 'dev' && _env != 'staging';
}
