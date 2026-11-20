import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/features/reference/reference_failures.dart';
import 'package:reference_data/reference_data.dart';

ResponseBody _json(Object body, {int status = 200}) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
  },
);

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

Map<String, dynamic> _recordJson(String code, {int order = 0}) =>
    <String, dynamic>{
      'code': code,
      'labelKey': 'status.active',
      'tone': 'neutral',
      'icon': 'circle',
      'order': order,
      'selectable': true,
      'visibleFor': <String>['platform_admin'],
      'allowedNext': <String>[],
      'version': 2,
    };

ReferenceAdminApi _admin(_ScriptedAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
  dio.httpClientAdapter = adapter;
  return ReferenceAdminApi(
    ApiClient(
      config: const ApiConfig(baseUrl: 'http://localhost', environment: 'test'),
      dio: dio,
    ),
  );
}

ResponseBody _defaultResponse(RequestOptions options) {
  final path = options.path;
  if (path.endsWith('/impact')) {
    return _json(<String, dynamic>{
      'items': 2,
      'jobs': 0,
      'templates': 3,
      'documents': 0,
    });
  }
  if (path.contains('/transitions/')) {
    return _json(<dynamic>[
      <String, dynamic>{
        'fromCode': 'DRAFT',
        'toCode': 'SCHEDULED',
        'role': 'WORKSHOP_ADMIN',
        'guard': <String, dynamic>{},
        'version': 1,
      },
    ]);
  }
  if (path.endsWith('/reorder')) {
    return _json(<dynamic>[
      _recordJson('DRAFT'),
      _recordJson('ACTIVE', order: 1),
    ]);
  }
  return _json(_recordJson('CODE'));
}

void main() {
  test('writes use the live reference contract paths and bodies', () async {
    final adapter = _ScriptedAdapter(_defaultResponse);
    final admin = _admin(adapter);
    const write = ReferenceWrite(
      code: 'NEW_CODE',
      labelKey: 'status.active',
      tone: 'info',
      icon: 'flag',
      order: 4,
      selectable: false,
      visibleFor: <String>['platform_admin'],
    );

    await admin.createStatus('job', write);
    var request = adapter.requests.last;
    expect(request.method, 'POST');
    expect(request.path, '/api/v1/reference/statuses/job');
    var body = request.data as Map<String, dynamic>;
    expect(body['code'], 'NEW_CODE');
    expect(body['labelKey'], 'status.active');
    expect(body['tone'], 'info');
    expect(body['order'], 4);
    expect(body['selectable'], isFalse);
    expect(body['visibleFor'], <String>['platform_admin']);
    expect(body['allowedNext'], isEmpty);

    await admin.updateStatus('job', 'NEW_CODE', write);
    request = adapter.requests.last;
    expect(request.method, 'PUT');
    expect(request.path, '/api/v1/reference/statuses/job/NEW_CODE');

    await admin.publishStatus('job', 'NEW_CODE');
    request = adapter.requests.last;
    expect(request.method, 'POST');
    expect(request.path, '/api/v1/reference/statuses/job/NEW_CODE/publish');

    await admin.retireStatus('job', 'NEW_CODE');
    request = adapter.requests.last;
    expect(request.path, '/api/v1/reference/statuses/job/NEW_CODE/retire');

    await admin.reorderStatuses('job', <({String code, int order})>[
      (code: 'DRAFT', order: 0),
      (code: 'ACTIVE', order: 1),
    ]);
    request = adapter.requests.last;
    expect(request.method, 'PUT');
    expect(request.path, '/api/v1/reference/statuses/job/reorder');
    expect(request.data, <Map<String, Object?>>[
      <String, Object?>{'code': 'DRAFT', 'order': 0},
      <String, Object?>{'code': 'ACTIVE', 'order': 1},
    ]);

    await admin.createEnum('role', write);
    expect(adapter.requests.last.path, '/api/v1/reference/enums/role');

    await admin.updateEnum('role', 'NEW_CODE', write);
    request = adapter.requests.last;
    expect(request.method, 'PUT');
    expect(request.path, '/api/v1/reference/enums/role/NEW_CODE');

    await admin.publishEnum('role', 'NEW_CODE');
    expect(
      adapter.requests.last.path,
      '/api/v1/reference/enums/role/NEW_CODE/publish',
    );

    await admin.retireEnum('role', 'NEW_CODE');
    expect(
      adapter.requests.last.path,
      '/api/v1/reference/enums/role/NEW_CODE/retire',
    );

    await admin.reorderEnums('role', <({String code, int order})>[
      (code: 'TECHNICIAN', order: 0),
      (code: 'PLATFORM_ADMIN', order: 1),
    ]);
    request = adapter.requests.last;
    expect(request.method, 'PUT');
    expect(request.path, '/api/v1/reference/enums/role/reorder');
    expect(request.data, <Map<String, Object?>>[
      <String, Object?>{'code': 'TECHNICIAN', 'order': 0},
      <String, Object?>{'code': 'PLATFORM_ADMIN', 'order': 1},
    ]);

    await admin.replaceTransitions('job', <ReferenceTransition>[
      const ReferenceTransition(
        fromCode: 'DRAFT',
        toCode: 'SCHEDULED',
        role: 'WORKSHOP_ADMIN',
      ),
    ]);
    request = adapter.requests.last;
    expect(request.method, 'PUT');
    expect(request.path, '/api/v1/reference/transitions/job');
    expect(request.data, <Map<String, Object?>>[
      <String, Object?>{
        'fromCode': 'DRAFT',
        'toCode': 'SCHEDULED',
        'role': 'WORKSHOP_ADMIN',
        'guard': <String, Object?>{},
      },
    ]);

    final impact = await admin.impact('job', 'NEW_CODE');
    request = adapter.requests.last;
    expect(request.method, 'GET');
    expect(request.path, '/api/v1/reference/job/NEW_CODE/impact');
    expect(impact.items, 2);
    expect(impact.templates, 3);
  });

  test('409 REFERENCE_IN_USE keeps the server ProblemDetails shape', () async {
    const detail =
        'Reference is still in use: 2 items, 0 jobs, 3 templates, 0 documents';
    final adapter = _ScriptedAdapter(
      (_) => _json(<String, dynamic>{
        'code': 'REFERENCE_IN_USE',
        'messageKey': 'error.conflict',
        'detail': detail,
        'status': 409,
      }, status: 409),
    );
    final admin = _admin(adapter);

    await expectLater(
      admin.retireStatus('job', 'ACTIVE'),
      throwsA(
        isA<ApiFailure>()
            .having((error) => error.code, 'code', 'REFERENCE_IN_USE')
            .having((error) => error.statusCode, 'statusCode', 409)
            .having((error) => error.detail, 'detail', detail),
      ),
    );

    // The fallback parser reads the same counts the dialog shows.
    final parsed = impactFromDetail(detail);
    expect(parsed?.items, 2);
    expect(parsed?.jobs, 0);
    expect(parsed?.templates, 3);
    expect(parsed?.documents, 0);
    expect(parsed?.isEmpty, isFalse);
  });

  test(
    '422 LABEL_KEY_UNKNOWN and 403 FORBIDDEN stay distinguishable',
    () async {
      for (final entry in <({int status, String code, String detail})>[
        (
          status: 422,
          code: 'LABEL_KEY_UNKNOWN',
          detail: 'labelKey is not present in the UI catalogs: nope',
        ),
        (status: 403, code: 'FORBIDDEN', detail: 'Forbidden'),
      ]) {
        final adapter = _ScriptedAdapter(
          (_) => _json(<String, dynamic>{
            'code': entry.code,
            'messageKey': 'error.failure',
            'detail': entry.detail,
            'status': entry.status,
          }, status: entry.status),
        );
        final admin = _admin(adapter);
        await expectLater(
          admin.createStatus(
            'job',
            const ReferenceWrite(code: 'NEW', labelKey: 'nope'),
          ),
          throwsA(
            isA<ApiFailure>()
                .having((error) => error.code, 'code', entry.code)
                .having(
                  (error) => error.statusCode,
                  'statusCode',
                  entry.status,
                ),
          ),
        );
      }
    },
  );
}
