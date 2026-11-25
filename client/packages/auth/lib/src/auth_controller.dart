import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:auth/src/app_env.dart';
import 'package:auth/src/auth_repository.dart';
import 'package:auth/src/session_store.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  // The session client must outlive individual screens. Riverpod 3 can
  // dispose a provider as soon as it has no listeners, which invalidated the
  // `ref` held by callbacks while the ApiClient was still in use.
  ref.keepAlive();
  // The auth callbacks are wired by AuthController.build(), NOT here.
  //
  // Reading authRepositoryProvider from this provider's `ref` is a circular
  // dependency (the repository watches this client). Riverpod threw
  // `CircularDependencyError` the moment a refresh was attempted, so the
  // refresh silently never ran and the app stayed on a dead session.
  return ApiClient(config: AppEnv.apiConfig());
});

final apiEndpointsProvider = Provider<ApiEndpoints>((ref) {
  return AppEnv.apiEndpoints();
});

final sessionStoreProvider = Provider<SessionStore>((ref) {
  // Same lifetime as the session itself: one store for the whole app.
  ref.keepAlive();
  return SecureSessionStore();
});

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((ref) {
      // Keeps the sign-out guard and the session epoch stable for the app
      // lifetime instead of resetting them when a screen stops listening.
      ref.keepAlive();
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
  /// Resolved on demand instead of stored in `build()`.
  ///
  /// Riverpod can run `build()` again on the same notifier (invalidate/retry).
  /// A `late final` field made that second run throw LateInitializationError,
  /// which left the provider in an error state while the router still saw the
  /// previous session — the app stayed on a protected screen and 401'd
  /// forever instead of going to sign-in.
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// True while [build] is restoring; a 401 during that window is reported by
  /// the restore result instead of mutating state mid-build.
  bool _restoring = false;
  bool _expireRequested = false;
  bool _disposed = false;

  @override
  Future<Session?> build() async {
    _disposed = false;
    _expireRequested = false;
    ref.onDispose(() => _disposed = true);

    final repository = ref.watch(authRepositoryProvider);
    final client = ref.watch(apiClientProvider);

    // Session callbacks are wired here, using this controller's own methods.
    // This is the only place that knows both the client and the repository,
    // so it cannot create the circular dependency described in
    // apiClientProvider.
    client.tokenRefresher = repository.refreshAccessToken;
    client.onUnauthorized = () {
      if (_disposed) return;
      if (_restoring) {
        _expireRequested = true;
        return;
      }
      unawaited(signOut());
    };

    _restoring = true;
    try {
      final session = await repository.restore();
      if (_expireRequested) {
        _expireRequested = false;
        unawaited(repository.signOut());
        return null;
      }
      return session;
    } finally {
      _restoring = false;
    }
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

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> signOut() async {
    // Leave protected screens immediately. The router listens to this state and
    // must not wait for the logout round-trip (which can hang or be offline).
    state = const AsyncData(null);
    // The repository keeps the token for the revoke call and always clears it
    // locally afterwards, so a failed round-trip can never leave a stale token
    // on the wire (that used to make the next request 401 with no way back).
    try {
      await _repository.signOut();
    } on Object {
      // Local sign-out already happened; make sure the session is gone.
      ref.read(apiClientProvider).accessToken = null;
      try {
        await ref.read(sessionStoreProvider).clear();
      } on Object {
        // Storage unavailable: the in-memory state is still signed out.
      }
    }
  }
}
