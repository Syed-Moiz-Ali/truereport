import 'package:api_client/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Single shared environment for every TrueReport app.
///
/// The base URL lives in ONE `.env` file: `packages/auth/.env`.
/// All apps (technician, workshop admin, platform admin) resolve the backend
/// through here, so there is exactly one URL to change.
///
/// Priority: `--dart-define=API_BASE_URL=...` > `.env` > localhost default.
///
/// Call [load] once from `main()` before `runApp`:
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await AppEnv.load();
///   runApp(...);
/// }
/// ```
abstract final class AppEnv {
  /// Local backend default. Dev-only convenience so plain `flutter run`
  /// and unit tests (no `.env` on disk) still reach the server.
  ///
  /// Release builds must set a real URL in `.env` — see [baseUrl].
  static const String _devBaseUrl = 'http://localhost:8080';

  static String _baseUrl = _devBaseUrl;
  static String _environment = 'dev';
  static bool _loaded = false;

  /// Backend origin (no trailing `/api/v1` — see [ApiEndpoints]).
  static String get baseUrl => _baseUrl;

  /// Compile-time environment name: `dev` | `staging` | `prod`.
  static String get environment => _environment;

  /// `true` when this build targets production.
  static bool get isProduction => _environment == 'prod';

  /// `true` when the build is still pointing at the local dev backend.
  static bool get isLocalBackend =>
      _baseUrl == _devBaseUrl ||
      _baseUrl.startsWith('http://localhost') ||
      _baseUrl.startsWith('http://127.0.0.1');

  /// Loads the shared `.env`. Never throws: without the file (unit tests,
  /// missing asset) the dev defaults stay in effect.
  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      // Bundled inside an app the file lives under packages/auth/;
      // running inside the auth package itself it is just .env.
      try {
        await dotenv.load(fileName: 'packages/auth/.env');
      } on Object {
        await dotenv.load(fileName: '.env');
      }
      final envUrl = dotenv.env['API_BASE_URL']?.trim();
      if (envUrl != null && envUrl.isNotEmpty) _baseUrl = envUrl;
      final envName = dotenv.env['APP_ENV']?.trim();
      if (envName != null && envName.isNotEmpty) _environment = envName;
    } on Object {
      // No .env available: keep dev defaults.
    }
    // An explicit --dart-define always wins (CI / e2e overrides).
    const defineUrl = String.fromEnvironment('API_BASE_URL');
    if (defineUrl.isNotEmpty) _baseUrl = defineUrl;
    const defineEnv = String.fromEnvironment('APP_ENV');
    if (defineEnv.isNotEmpty) _environment = defineEnv;
  }

  /// Fail fast on a misconfigured release build.
  ///
  /// Call from `main()` before `runApp` when you want CI/release builds to
  /// crash loudly instead of silently talking to localhost.
  static void assertConfiguredForRelease() {
    if (isProduction && isLocalBackend) {
      throw StateError(
        'AppEnv: prod build still points at the dev backend ($_baseUrl). '
        'Set API_BASE_URL in packages/auth/.env or pass '
        '--dart-define=API_BASE_URL=https://api.example.com',
      );
    }
  }

  /// Canonical [ApiConfig] for this build.
  static ApiConfig apiConfig() =>
      ApiConfig(baseUrl: _baseUrl, environment: _environment);

  /// Canonical [ApiEndpoints] for this build.
  static ApiEndpoints apiEndpoints() => ApiEndpoints(baseUrl: _baseUrl);

  /// Test-only escape hatch; unit tests never call [load].
  @visibleForTesting
  static void debugOverride({String? baseUrl, String? environment}) {
    _loaded = true;
    if (baseUrl != null) _baseUrl = baseUrl;
    if (environment != null) _environment = environment;
  }

  /// Test-only reset back to the dev defaults.
  @visibleForTesting
  static void debugReset() {
    _loaded = false;
    _baseUrl = _devBaseUrl;
    _environment = 'dev';
    dotenv.clean();
  }
}
