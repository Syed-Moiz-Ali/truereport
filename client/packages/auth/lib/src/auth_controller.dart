import 'package:api_client/api_client.dart';
import 'package:auth/src/auth_repository.dart';
import 'package:auth/src/session_store.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(config: ApiConfig.fromEnvironment());
  client.onUnauthorized = () {
    // Any 401 on an authenticated endpoint means the stored token is dead.
    // Clearing the session state makes the router redirect to /signin.
    try {
      ref.read(authControllerProvider.notifier).signOut();
    } on Object {
      // The controller may still be building during restore(); its own
      // 401 path clears the store in that case.
    }
  };
  client.tokenRefresher = () =>
      ref.read(authRepositoryProvider).refreshAccessToken();
  return client;
});

final apiEndpointsProvider = Provider<ApiEndpoints>((ref) {
  final config = ApiConfig.fromEnvironment();
  return ApiEndpoints(baseUrl: config.baseUrl);
});

final sessionStoreProvider = Provider<SessionStore>((ref) {
  return SecureSessionStore();
});

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((ref) {
      return AuthRepository(
        ref.watch(apiClientProvider),
        ref.watch(sessionStoreProvider),
        ref.watch(apiEndpointsProvider),
      );
    });

final authControllerProvider = AsyncNotifierProvider<AuthController, Session?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<Session?> {
  late final AuthRepository _repository;

  @override
  Future<Session?> build() {
    _repository = ref.watch(authRepositoryProvider);
    return _repository.restore();
  }

  Future<AuthResult> signIn(String email, String password) async {
    state = const AsyncLoading();
    try {
      final result = await _repository.signIn(email, password);
      if (result is AuthSuccess) {
        state = AsyncData(result.session);
      } else {
        state = const AsyncData(null);
      }
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<AuthResult> verifyTwoFactor(String challengeToken, String code) async {
    state = const AsyncLoading();
    try {
      final result = await _repository.verifyTwoFactor(challengeToken, code);
      if (result is AuthSuccess) {
        state = AsyncData(result.session);
      } else {
        state = const AsyncData(null);
      }
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncData(null);
  }
}
