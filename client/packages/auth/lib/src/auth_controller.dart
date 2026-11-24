import 'package:api_client/api_client.dart';
import 'package:auth/src/app_env.dart';
import 'package:auth/src/auth_repository.dart';
import 'package:auth/src/session_store.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(config: AppEnv.apiConfig());
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
  return AppEnv.apiEndpoints();
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
    // Leave protected screens immediately. The router listens to this state and
    // must not wait for the logout round-trip (which can 401, hang or fail).
    ref.read(apiClientProvider).accessToken = null;
    state = const AsyncData(null);
    try {
      await _repository.signOut();
    } on Object {
      // Local sign-out already happened; make sure the stored session is gone.
      try {
        await ref.read(sessionStoreProvider).clear();
      } on Object {
        // Storage unavailable: the in-memory state is still signed out.
      }
    }
  }
}
