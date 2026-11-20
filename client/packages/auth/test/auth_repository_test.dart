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
}
