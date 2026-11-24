import 'package:auth/auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(AppEnv.debugReset);
  tearDown(AppEnv.debugReset);

  test('defaults point at the local backend with no .env loaded', () {
    expect(AppEnv.baseUrl, 'http://localhost:8080');
    expect(AppEnv.environment, 'dev');
    expect(AppEnv.isLocalBackend, isTrue);
    expect(AppEnv.isProduction, isFalse);
  });

  test('apiConfig and apiEndpoints share the one base url', () {
    AppEnv.debugOverride(
      baseUrl: 'https://api.example.com',
      environment: 'prod',
    );

    expect(AppEnv.apiConfig().baseUrl, 'https://api.example.com');
    expect(AppEnv.apiConfig().isProduction, isTrue);
    expect(
      AppEnv.apiEndpoints().absolute('/api/v1/auth/me'),
      'https://api.example.com/api/v1/auth/me',
    );
    expect(AppEnv.isProduction, isTrue);
    expect(AppEnv.isLocalBackend, isFalse);
  });

  test('release guard throws for prod builds on localhost', () {
    AppEnv.debugOverride(environment: 'prod');
    expect(AppEnv.assertConfiguredForRelease, throwsStateError);
  });
}
