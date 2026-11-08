import 'package:api_client/api_client.dart';
import 'package:auth/src/session_store.dart';
import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

sealed class AuthResult {
  const AuthResult();
}

final class AuthSuccess extends AuthResult {
  const AuthSuccess(this.session);

  final Session session;
}

final class AuthChallenge extends AuthResult {
  const AuthChallenge(this.challengeToken);

  final String challengeToken;
}

class AuthRepository {
  AuthRepository(this._api, this._store, this._endpoints);

  final ApiClient _api;
  final SessionStore _store;
  final ApiEndpoints _endpoints;

  Future<Session?> restore() async {
    final stored = await _store.read();
    if (stored == null) {
      return null;
    }
    final session = Session.fromJson(stored);
    _api.accessToken = session.accessToken;
    try {
      await _api.get(_endpoints.authMe);
      return session;
    } on AppFailure catch (failure) {
      if (failure.statusCode == 401) {
        await _store.clear();
        _api.accessToken = null;
        return null;
      }
      // Offline or server unavailable: keep the last known session.
      return session;
    }
  }

  Future<AuthResult> signIn(String email, String password) async {
    final target = _endpoints.authLogin;
    if (kDebugMode) {
      // Never log the password.
      debugPrint('[Auth] POST $target email=${email.trim()}');
    }
    try {
      final json = await _api.post(
        target,
        body: <String, dynamic>{'email': email.trim(), 'password': password},
      );
      if (kDebugMode) {
        debugPrint(
          '[Auth] POST $target ok requiresTwoFactor=${json['requiresTwoFactor']}',
        );
      }
      return await _handleAuthJson(json);
    } on AppFailure catch (failure) {
      if (kDebugMode) {
        debugPrint(
          '[Auth] POST $target failed '
          'code=${failure.code} status=${failure.statusCode}',
        );
      }
      rethrow;
    }
  }

  Future<AuthResult> verifyTwoFactor(String challengeToken, String code) async {
    final json = await _api.post(
      _endpoints.authVerifyTwoFactor,
      body: <String, dynamic>{'challengeToken': challengeToken, 'code': code},
    );
    return _handleAuthJson(json);
  }

  Future<Session?> refresh(String refreshToken) async {
    final json = await _api.post(
      _endpoints.authRefresh,
      body: <String, dynamic>{'refreshToken': refreshToken},
    );
    final session = Session.fromJson(json);
    _api.accessToken = session.accessToken;
    await _store.save(json);
    return session;
  }

  Future<void> signOut() async {
    try {
      await _api.post(_endpoints.authLogout, body: const <String, dynamic>{});
    } on AppFailure {
      // Local sign-out must always succeed.
    } finally {
      _api.accessToken = null;
      await _store.clear();
    }
  }

  Future<AuthResult> _handleAuthJson(Map<String, dynamic> json) async {
    if (json['requiresTwoFactor'] == true) {
      return AuthChallenge(json['challengeToken'] as String);
    }
    final session = Session.fromJson(json);
    _api.accessToken = session.accessToken;
    await _store.save(json);
    return AuthSuccess(session);
  }
}
