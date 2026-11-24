/// Plain value object carried into [ApiClient].
///
/// The environment itself lives in ONE place: `AppEnv` in the `auth`
/// package (`packages/auth/lib/src/app_env.dart`), shared by every app.
/// This class intentionally reads no `--dart-define`, ships no default URL
/// and loads no `.json` — pass the values in explicitly.
class ApiConfig {
  const ApiConfig({required this.baseUrl, required this.environment});

  final String baseUrl;
  final String environment;

  bool get isProduction => environment == 'prod';
}
