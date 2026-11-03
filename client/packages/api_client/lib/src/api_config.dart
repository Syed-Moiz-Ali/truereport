class ApiConfig {
  const ApiConfig({required this.baseUrl, required this.environment});

  static const String _defaultBaseUrl = 'http://localhost:8080';
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
