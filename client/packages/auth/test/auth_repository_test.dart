import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client/api_client.dart';
import 'package:auth/auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _UnauthorizedAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{}',
      401,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _InMemorySessionStore implements SessionStore {
  _InMemorySessionStore(this.stored);

  Map<String, dynamic>? stored;
  int clears = 0;

  @override
  Future<void> clear() async {
    clears += 1;
    stored = null;
  }

  @override
  Future<Map<String, dynamic>?> read() async => stored;

  @override
  Future<void> save(Map<String, dynamic> session) async {
    stored = session;
  }
}

Map<String, dynamic> _sessionJson() => <String, dynamic>{
  'accessToken': 'rotated-token',
  'refreshToken': 'refresh-token',
  'user': <String, dynamic>{
    'id': 'user-1',
    'email': 'admin@example.test',
    'displayName': 'Admin',
    'platformAdmin': false,
    'totpEnabled': false,
  },
  'memberships': <dynamic>[
    <String, dynamic>{
      'workshopId': 'workshop-1',
      'workshopName': 'Workshop',
      'role': 'WORKSHOP_ADMIN',
    },
  ],
};

Map<String, dynamic> _rotatedSessionJson() {
  final json = _sessionJson();
  json['accessToken'] = 'new-access';
  json['refreshToken'] = 'new-refresh';
  return json;
}

/// Answers `/auth/refresh` with a rotated pair (or a 401) and records requests.
class _RefreshAdapter implements HttpClientAdapter {
  _RefreshAdapter({this.fail = false});

  final bool fail;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final headers = <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    };
    if (options.path == '/api/v1/auth/refresh') {
      if (fail) {
        return ResponseBody.fromString(
          '{"status":401,"code":"AUTH_TOKEN_INVALID"}',
          401,
          headers: headers,
        );
      }
      return ResponseBody.fromString(
        jsonEncode(_rotatedSessionJson()),
        200,
        headers: headers,
      );
    }
    return ResponseBody.fromString('{"status":"UP"}', 200, headers: headers);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('401 from the session check clears the stored session', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
    final adapter = _UnauthorizedAdapter();
    dio.httpClientAdapter = adapter;
    final api = ApiClient(
      config: const ApiConfig(baseUrl: 'http://localhost', environment: 'test'),
      dio: dio,
    )..accessToken = 'rotated-token';
    final store = _InMemorySessionStore(_sessionJson());
    final repository = AuthRepository(
      api,
      store,
      const ApiEndpoints(baseUrl: 'http://localhost'),
    );

    final restored = await repository.restore();

    expect(restored, isNull);
    expect(store.clears, 1);
    expect(store.stored, isNull);
    expect(api.accessToken, isNull);
    expect(adapter.requests.single.path, '/api/v1/auth/me');
    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer rotated-token',
    );
  });

  test(
    'refresh rotates the pair and persists it for the next launch',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      final adapter = _RefreshAdapter();
      dio.httpClientAdapter = adapter;
      final api = ApiClient(
        config: const ApiConfig(
          baseUrl: 'http://localhost',
          environment: 'test',
        ),
        dio: dio,
      )..accessToken = 'stale-access';
      final store = _InMemorySessionStore(_sessionJson());
      final repository = AuthRepository(
        api,
        store,
        const ApiEndpoints(baseUrl: 'http://localhost'),
      );

      final token = await repository.refreshAccessToken();

      expect(token, 'new-access');
      expect(api.accessToken, 'new-access');
      expect(store.stored?['accessToken'], 'new-access');
      // The rotated refresh token must replace the old one, otherwise the next
      // refresh would be treated as reuse.
      expect(store.stored?['refreshToken'], 'new-refresh');
      final request = adapter.requests.single;
      expect(request.path, '/api/v1/auth/refresh');
      expect(request.data, <String, dynamic>{'refreshToken': 'refresh-token'});
      expect(request.headers.containsKey('Authorization'), isFalse);
    },
  );

  test('refresh failure returns null and keeps the stored session', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
    final adapter = _RefreshAdapter(fail: true);
    dio.httpClientAdapter = adapter;
    final api = ApiClient(
      config: const ApiConfig(baseUrl: 'http://localhost', environment: 'test'),
      dio: dio,
    )..accessToken = 'stale-access';
    final store = _InMemorySessionStore(_sessionJson());
    final repository = AuthRepository(
      api,
      store,
      const ApiEndpoints(baseUrl: 'http://localhost'),
    );

    final token = await repository.refreshAccessToken();

    expect(token, isNull);
    expect(store.clears, 0);
    expect(store.stored?['refreshToken'], 'refresh-token');
    expect(api.accessToken, 'stale-access');
  });
}
