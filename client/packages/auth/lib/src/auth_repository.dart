import 'dart:async';

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

/// Owns the stored session and every credential round-trip.
///
/// Session lifecycle (all paths end in either a usable session or sign-in):
/// 1. [restore] reads the token saved on the device. No token → signed out.
/// 2. With a token it asks the API for the profile (`GET /auth/me`).
/// 3. A 401 is renewed transparently by [ApiClient] using the stored refresh
///    token, then the profile call is retried once.
/// 4. If renewal fails, no refresh token exists, or the renewed token is also
///    rejected, the local session is cleared and `onUnauthorized` sends the
///    router to sign-in.
class AuthRepository {
  AuthRepository(this._api, this._store, this._endpoints);

  final ApiClient _api;
  final SessionStore _store;
  final ApiEndpoints _endpoints;
  bool _signingOut = false;

  /// Incremented whenever a sign-in/2FA writes new credentials.
  ///
  /// Long-running work (a slow [restore] or [signOut] round-trip) captures the
  /// epoch first and refuses to clear the store if a newer sign-in happened in
  /// the meantime. Otherwise a stale 401 cleanup could wipe a fresh login and
  /// leave the app authenticated in memory but unauthenticated on the wire.
  int _epoch = 0;

  Future<Session?> restore() async {
    final epoch = _epoch;
    Map<String, dynamic>? stored;
    try {
      stored = await _store.read();
    } on Object {
      // Secure storage unavailable (keystore reset, unsupported platform):
      // behave like a first launch instead of crashing the router.
      _log('restore: local storage unreadable');
      return null;
    }
    if (_epoch != epoch) return null;
    if (stored == null) {
      _log('restore: no saved session');
      return null;
    }

    final Session session;
    try {
      session = Session.fromJson(stored);
    } on Object {
      _log('restore: saved session is unreadable, clearing it');
      await _clearLocal(epoch);
      return null;
    }
    if (session.accessToken.isEmpty || session.refreshToken.isEmpty) {
      // A session we cannot renew is only good until the access token expires.
      // Treat incomplete local data as signed out, as the flow requires.
      _log('restore: saved session is incomplete, clearing it');
      await _clearLocal(epoch);
      return null;
    }

    _api.accessToken = session.accessToken;
    _log('restore: token found, checking profile (${_endpoints.authMe})');
    try {
      // Bounded: a stalled profile call must not leave the router in its
      // loading state forever. The refresh inside has its own timeout.
      await _api.get(_endpoints.authMe).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      _log('restore: profile check timed out, keeping the session');
      return session;
    } on AppFailure catch (failure) {
      if (failure.statusCode == 401) {
        // ApiClient has already tried the refresh token and retried once.
        // Reaching 401 here means the session cannot be renewed.
        _log('restore: profile rejected with 401, clearing the session');
        await _clearLocal(epoch);
        return null;
      }
      // Offline or server unavailable: keep the last known session so the
      // technician app can still open cached work.
      _log(
        'restore: profile unavailable (${failure.statusCode}), keeping session',
      );
      return session;
    }
    // A sign-out may have landed while the profile call was in flight, in
    // which case the store is gone and the session must not come back.
    final current = await _currentStoredSession(epoch);
    if (current == null) {
      _log('restore: session disappeared while checking the profile');
      return null;
    }
    _log('restore: profile ok, session restored');
    return current;
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

  /// Changes the signed-in user's password. The server verifies the current
  /// password and revokes every other session; this one keeps working.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.post(
      _endpoints.authChangePassword,
      body: <String, dynamic>{
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<AuthResult> verifyTwoFactor(String challengeToken, String code) async {
    final json = await _api.post(
      _endpoints.authVerifyTwoFactor,
      body: <String, dynamic>{'challengeToken': challengeToken, 'code': code},
    );
    return _handleAuthJson(json);
  }

  Future<Session> refresh(String refreshToken) async {
    final json = await _api.post(
      _endpoints.authRefresh,
      body: <String, dynamic>{'refreshToken': refreshToken},
    );
    final session = Session.fromJson(json);
    _api.accessToken = session.accessToken;
    await _store.save(json);
    return session;
  }

  Future<String?> refreshAccessToken() async {
    _log('refresh: requested');
    Map<String, dynamic>? stored;
    try {
      stored = await _store.read();
    } on Object catch (error) {
      _log('refresh: could not read the stored session ($error)');
      return null;
    }
    final refreshToken = stored?['refreshToken'];
    if (refreshToken is! String || refreshToken.isEmpty) {
      _log('refresh: no refresh token stored');
      return null;
    }
    try {
      final session = await refresh(refreshToken);
      _log('refresh: access token renewed');
      return session.accessToken;
    } on Object {
      // 401 (revoked/expired/reused) or a transient failure: the client
      // treats a null answer as a dead session and signs out.
      _log('refresh: failed, session is not renewable');
      return null;
    }
  }

  Future<void> signOut() async {
    if (_signingOut) return;
    _signingOut = true;
    final epoch = _epoch;
    try {
      // Revoke the server-side session only when we still hold that session.
      // Posting without a token always 401s and pollutes the logs.
      final token = _api.accessToken;
      if (epoch == _epoch && token != null && token.isNotEmpty) {
        await _api.post(_endpoints.authLogout, body: const <String, dynamic>{});
      }
    } on Object {
      // Local sign-out must always succeed, even offline.
    } finally {
      await _clearLocal(epoch);
      _signingOut = false;
    }
  }

  Future<AuthResult> _handleAuthJson(Map<String, dynamic> json) async {
    if (json['requiresTwoFactor'] == true) {
      return AuthChallenge(json['challengeToken'] as String);
    }
    final session = Session.fromJson(json);
    _epoch++;
    _api.accessToken = session.accessToken;
    try {
      await _store.save(json);
    } on Object {
      // A storage write failure must not block a valid sign-in; the session
      // simply will not survive a restart, and sign-in can be repeated.
      _log('sign-in: could not persist the session');
    }
    return AuthSuccess(session);
  }

  /// Clears the local session unless a newer sign-in superseded [epoch].
  ///
  /// Bumping the epoch invalidates any restore that is still in flight, so a
  /// late profile response cannot resurrect a session that was just cleared.
  Future<void> _clearLocal(int epoch) async {
    if (_epoch != epoch) return;
    _epoch++;
    _api.accessToken = null;
    try {
      await _store.clear();
    } on Object {
      // Storage unavailable: the in-memory token is still gone.
    }
  }

  /// The stored session may have been rotated by a transparent refresh while
  /// the profile call was in flight. Return the newest tokens, not the ones
  /// read before the request.
  Future<Session?> _currentStoredSession(int epoch) async {
    if (_epoch != epoch) return null;
    try {
      final stored = await _store.read();
      if (stored == null) return null;
      return Session.fromJson(stored);
    } on Object {
      return null;
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[Auth] $message');
    }
  }
}
