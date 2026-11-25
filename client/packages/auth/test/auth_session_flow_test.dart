import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client/api_client.dart';
import 'package:auth/auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The startup contract this file pins:
///
/// 1. No saved token → signed out, no network call.
/// 2. Saved token → `GET /auth/me`.
/// 3. 401 on the profile → refresh with the stored refresh token.
/// 4. Refresh rejected / missing / renewed token also rejected → clear the
///    stored session, notify the session layer, go to sign-in.

class _FakeStore implements SessionStore {
  _FakeStore([this.value]);

  Map<String, dynamic>? value;
  int clears = 0;

  @override
  Future<void> save(Map<String, dynamic> session) async {
    value = Map<String, dynamic>.from(session);
  }

  @override
  Future<Map<String, dynamic>?> read() async {
    final current = value;
    return current == null ? null : Map<String, dynamic>.from(current);
  }

  @override
  Future<void> clear() async {
    value = null;
    clears++;
  }
}

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = <RequestOptions>[];

  int calls(String method, String path) => requests
      .where((request) => request.method == method && request.path == path)
      .length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
  },
);

ResponseBody _unauthorized() => _json(401, <String, Object?>{
  'code': 'AUTH_TOKEN_INVALID',
  'messageKey': 'error.unauthorized',
  'status': 401,
});

Map<String, Object?> _sessionJson({
  String access = 'access-1',
  String refresh = 'refresh-1',
}) => <String, Object?>{
  'accessToken': access,
  'refreshToken': refresh,
  'user': <String, Object?>{
    'id': 'user-1',
    'email': 'tech@truereport.test',
    'displayName': 'Tech',
    'platformAdmin': false,
    'totpEnabled': false,
  },
  'memberships': <Object?>[],
};

void main() {
  const baseUrl = 'http://test.local';
  const mePath = '/api/v1/auth/me';
  const refreshPath = '/api/v1/auth/refresh';

  late ApiClient client;
  late _StubAdapter adapter;

  ApiClient buildClient(
    Future<ResponseBody> Function(RequestOptions options) handler,
  ) {
    adapter = _StubAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: baseUrl))..httpClientAdapter = adapter;
    return ApiClient(
      config: const ApiConfig(baseUrl: baseUrl, environment: 'dev'),
      dio: dio,
    );
  }

  test('no saved token: signed out without touching the network', () async {
    final store = _FakeStore();
    client = buildClient((_) async => _unauthorized());
    final repository = AuthRepository(
      client,
      store,
      const ApiEndpoints(baseUrl: baseUrl),
    );

    expect(await repository.restore(), isNull);
    expect(adapter.requests, isEmpty);
    expect(store.clears, 0);
  });

  test('saved token: profile is fetched with the bearer token', () async {
    final store = _FakeStore(_sessionJson());
    client = buildClient((options) async {
      if (options.path == mePath) {
        return _json(200, <String, Object?>{'user': _sessionJson()['user']});
      }
      return _unauthorized();
    });
    final repository = AuthRepository(
      client,
      store,
      const ApiEndpoints(baseUrl: baseUrl),
    );

    final session = await repository.restore();

    expect(session, isNotNull);
    expect(session!.accessToken, 'access-1');
    expect(adapter.calls('GET', mePath), 1);
    expect(adapter.requests.single.headers['Authorization'], 'Bearer access-1');
  });

  test(
    'expired token: refresh renews it and the profile retry succeeds',
    () async {
      final store = _FakeStore(_sessionJson());
      var meCalls = 0;
      client = buildClient((options) async {
        if (options.path == mePath) {
          meCalls++;
          return meCalls == 1
              ? _unauthorized()
              : _json(200, <String, Object?>{'user': _sessionJson()['user']});
        }
        if (options.path == refreshPath) {
          return _json(
            200,
            _sessionJson(access: 'access-2', refresh: 'refresh-2'),
          );
        }
        return _unauthorized();
      });
      final repository = AuthRepository(
        client,
        store,
        const ApiEndpoints(baseUrl: baseUrl),
      );
      // Mirrors the production wiring in apiClientProvider.
      client.tokenRefresher = repository.refreshAccessToken;

      final session = await repository.restore();

      expect(session, isNotNull);
      expect(session!.accessToken, 'access-2');
      expect(session.refreshToken, 'refresh-2');
      expect(adapter.calls('POST', refreshPath), 1);
      expect(adapter.calls('GET', mePath), 2);
      // The rotated pair must be persisted, not just held in memory.
      expect(store.value?['accessToken'], 'access-2');
      expect(store.value?['refreshToken'], 'refresh-2');
      expect(client.accessToken, 'access-2');
    },
  );

  test(
    'refresh rejected: session is cleared and sign-in is requested',
    () async {
      final store = _FakeStore(_sessionJson());
      var notified = 0;
      client = buildClient((options) async {
        if (options.path == mePath) return _unauthorized();
        if (options.path == refreshPath) return _unauthorized();
        return _unauthorized();
      });
      client.onUnauthorized = () => notified++;
      final repository = AuthRepository(
        client,
        store,
        const ApiEndpoints(baseUrl: baseUrl),
      );
      client.tokenRefresher = repository.refreshAccessToken;

      expect(await repository.restore(), isNull);
      // onUnauthorized is scheduled as a microtask.
      await Future<void>.delayed(Duration.zero);

      expect(store.value, isNull);
      expect(client.accessToken, isNull);
      expect(notified, 1);
    },
  );

  test(
    'renewed token rejected too: session is cleared (no endless 401)',
    () async {
      final store = _FakeStore(_sessionJson());
      var notified = 0;
      client = buildClient((options) async {
        if (options.path == mePath) return _unauthorized();
        if (options.path == refreshPath) {
          return _json(
            200,
            _sessionJson(access: 'access-2', refresh: 'refresh-2'),
          );
        }
        return _unauthorized();
      });
      client.onUnauthorized = () => notified++;
      final repository = AuthRepository(
        client,
        store,
        const ApiEndpoints(baseUrl: baseUrl),
      );
      client.tokenRefresher = repository.refreshAccessToken;

      expect(await repository.restore(), isNull);
      await Future<void>.delayed(Duration.zero);

      expect(adapter.calls('POST', refreshPath), 1);
      expect(adapter.calls('GET', mePath), 2);
      expect(store.value, isNull);
      expect(client.accessToken, isNull);
      expect(notified, 1);
    },
  );

  test('refresh token missing locally: treated as signed out', () async {
    final store = _FakeStore(_sessionJson(refresh: ''));
    client = buildClient((options) async {
      return _json(200, <String, Object?>{'user': _sessionJson()['user']});
    });
    final repository = AuthRepository(
      client,
      store,
      const ApiEndpoints(baseUrl: baseUrl),
    );

    expect(await repository.restore(), isNull);
    expect(store.value, isNull);
    expect(adapter.requests, isEmpty);
  });

  test('unreadable saved session: cleared instead of crashing', () async {
    final store = _FakeStore(<String, dynamic>{'accessToken': 'only-a-token'});
    client = buildClient((_) async => _unauthorized());
    final repository = AuthRepository(
      client,
      store,
      const ApiEndpoints(baseUrl: baseUrl),
    );

    expect(await repository.restore(), isNull);
    expect(store.value, isNull);
  });

  test(
    'profile unavailable (500): last known session is kept for offline',
    () async {
      final store = _FakeStore(_sessionJson());
      client = buildClient((options) async {
        if (options.path == mePath) {
          return _json(500, <String, Object?>{
            'code': 'SERVER_ERROR',
            'messageKey': 'error.unknown',
            'status': 500,
          });
        }
        return _unauthorized();
      });
      final repository = AuthRepository(
        client,
        store,
        const ApiEndpoints(baseUrl: baseUrl),
      );

      final session = await repository.restore();

      expect(session, isNotNull);
      expect(session!.accessToken, 'access-1');
      expect(store.value, isNotNull);
    },
  );

  test('auth controller survives a provider rebuild (invalidate)', () async {
    final container = ProviderContainer.test(
      overrides: [sessionStoreProvider.overrideWithValue(_FakeStore())],
    );

    expect(await container.read(authControllerProvider.future), isNull);
    // Regression: `build()` used to assign a `late final` repository, so the
    // second build threw LateInitializationError and the router kept showing
    // the previous session while every request 401'd.
    container.invalidate(authControllerProvider);
    expect(await container.read(authControllerProvider.future), isNull);
  });
}
