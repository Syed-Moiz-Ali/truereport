import 'dart:async';
import 'dart:typed_data';

import 'package:api_client/api_client.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

ResponseBody _json(int status, [String body = '{}']) {
  return ResponseBody.fromString(
    body,
    status,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.respond);

  final FutureOr<ResponseBody> Function(RequestOptions options) respond;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ApiClient _client(_ScriptedAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
  dio.httpClientAdapter = adapter;
  return ApiClient(
    config: const ApiConfig(baseUrl: 'http://localhost', environment: 'test'),
    dio: dio,
  );
}

void main() {
  test('public endpoints never carry Authorization', () async {
    final adapter = _ScriptedAdapter((_) => _json(200));
    final client = _client(adapter)
      ..accessToken = 'dead-token'
      ..acceptLanguage = 'es'
      ..clientName = 'workshop_admin';

    await client.getDynamic('/api/v1/i18n/ui-messages/workshop_admin/manifest');
    await client.post(
      '/api/v1/auth/login',
      body: const <String, dynamic>{'email': 'a@b.c', 'password': 'x'},
    );
    await client.post(
      '/api/v1/auth/refresh',
      body: const <String, dynamic>{'refreshToken': 'r'},
    );
    await client.getDynamic('/r/public-token');
    await client.getDynamic('/report/public-token');
    await client.get('/api/v1/workshop/jobs');

    for (final request in adapter.requests.take(5)) {
      expect(
        request.headers.containsKey('Authorization'),
        isFalse,
        reason: 'Authorization leaked to ${request.path}',
      );
      expect(request.headers['Accept-Language'], 'es');
      expect(request.headers['X-Client'], 'workshop_admin');
    }
    expect(adapter.requests.last.headers['Authorization'], 'Bearer dead-token');
  });

  test('401 refreshes once and retries the original request', () async {
    final attempts = <String, int>{};
    final adapter = _ScriptedAdapter((options) {
      if (options.path == '/api/v1/workshop/jobs') {
        final count = (attempts[options.path] ?? 0) + 1;
        attempts[options.path] = count;
        if (count == 1) return _json(401);
        return _json(200, '{"ok":true}');
      }
      return _json(200);
    });
    final client = _client(adapter)..accessToken = 'stale-token';
    var refreshes = 0;
    client.tokenRefresher = () async {
      refreshes += 1;
      return 'fresh-token';
    };

    final data = await client.getDynamic('/api/v1/workshop/jobs');

    expect((data as Map<String, dynamic>)['ok'], isTrue);
    expect(refreshes, 1);
    expect(adapter.requests.length, 2);
    expect(adapter.requests[0].headers['Authorization'], 'Bearer stale-token');
    expect(adapter.requests[1].headers['Authorization'], 'Bearer fresh-token');
    expect(client.accessToken, 'fresh-token');
  });

  test('refresh failure signs out and surfaces the failure', () async {
    final adapter = _ScriptedAdapter((_) => _json(401));
    final client = _client(adapter)..accessToken = 'stale-token';
    var notified = 0;
    var refreshes = 0;
    client.onUnauthorized = () => notified += 1;
    client.tokenRefresher = () async {
      refreshes += 1;
      return null;
    };

    await expectLater(
      client.get('/api/v1/workshop/jobs'),
      throwsA(isA<AppFailure>()),
    );
    await Future<void>.delayed(Duration.zero);

    expect(refreshes, 1);
    expect(notified, 1);
    expect(client.accessToken, isNull);
  });

  test('concurrent 401s share exactly one refresh', () async {
    final attempts = <String, int>{};
    final adapter = _ScriptedAdapter((options) {
      final count = (attempts[options.path] ?? 0) + 1;
      attempts[options.path] = count;
      if (count == 1) return _json(401);
      return _json(200);
    });
    final client = _client(adapter)..accessToken = 'stale-token';
    var refreshes = 0;
    client.tokenRefresher = () async {
      refreshes += 1;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return 'fresh-token';
    };

    await Future.wait(<Future<dynamic>>[
      client.getDynamic('/api/v1/workshop/jobs'),
      client.getDynamic('/api/v1/workshop/staff'),
    ]);

    expect(refreshes, 1);
    expect(client.accessToken, 'fresh-token');
    expect(adapter.requests.length, 4);
  });

  test('401 on a public endpoint does not refresh or notify', () async {
    final adapter = _ScriptedAdapter((_) => _json(401));
    final client = _client(adapter)..accessToken = 'dead-token';
    var notified = 0;
    var refreshes = 0;
    client.onUnauthorized = () => notified += 1;
    client.tokenRefresher = () async {
      refreshes += 1;
      return 'fresh-token';
    };

    await expectLater(
      client.getDynamic('/api/v1/i18n/ui-messages/workshop_admin/manifest'),
      throwsA(isA<AppFailure>()),
    );
    await Future<void>.delayed(Duration.zero);

    expect(refreshes, 0);
    expect(notified, 0);
    expect(client.accessToken, 'dead-token');
  });
}
