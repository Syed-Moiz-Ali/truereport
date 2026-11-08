class ApiConfig {
  const ApiConfig({required this.baseUrl, required this.environment});

  // Dev-tunnel default so plain `flutter run` (e.g. IDE button, no
  // --dart-define-from-file) still reaches the local server from Android.
  // Pass API_BASE_URL explicitly to override (prod must never use this).
  static const String _defaultBaseUrl =
      'https://56zk48dj-8080.inc1.devtunnels.ms';
  static const String _environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  final String baseUrl;
  final String environment;

  factory ApiConfig.fromEnvironment() =>
      const ApiConfig(baseUrl: _baseUrl, environment: _environment);

  bool get isProduction => environment == 'prod';
}
