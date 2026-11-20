import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reference_data/reference_data.dart';

ResponseBody _json(
  int status,
  Object body, {
  Map<String, List<String>>? headers,
}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      ...?headers,
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

ApiClient _api(_ScriptedAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
  dio.httpClientAdapter = adapter;
  return ApiClient(
    config: const ApiConfig(baseUrl: 'http://localhost', environment: 'test'),
    dio: dio,
  );
}

Map<String, dynamic> _record(
  String code, {
  String? labelKey,
  String tone = 'neutral',
  int order = 0,
  bool selectable = true,
  List<String> visibleFor = const <String>[],
}) {
  return <String, dynamic>{
    'code': code,
    'labelKey': labelKey ?? 'jobsStatus$code',
    'tone': tone,
    'icon': 'circle',
    'order': order,
    'selectable': selectable,
    'visibleFor': visibleFor,
    'allowedNext': <String>[],
    'version': 3,
  };
}

void main() {
  group('parsing', () {
    test('accepts wrapper objects, string numbers and missing fields', () {
      final records = parseRecords(<String, dynamic>{
        'items': <dynamic>[
          <String, dynamic>{
            'code': 'ASSIGNED',
            'labelKey': 'jobsStatusAssigned',
            'tone': 'info',
            'order': '2',
            'selectable': 'true',
            'visibleFor': <dynamic>['queue', 7],
          },
          <String, dynamic>{'code': 'DRAFT', 'labelKey': 'draft'},
          <String, dynamic>{'labelKey': 'noCode'},
        ],
      });

      expect(records.map((record) => record.code), <String>[
        'DRAFT',
        'ASSIGNED',
      ]);
      final assigned = records.last;
      expect(assigned.order, 2);
      expect(assigned.selectable, isTrue);
      expect(assigned.visibleFor, <String>['queue']);
      expect(assigned.version, 0);
    });

    test('dropdown values and transitions parse tolerantly', () {
      final values = parseValues(<dynamic>[
        <String, dynamic>{
          'code': 'FRONT',
          'labelKey': 'locationFront',
          'order': 1,
          'parentCode': 'BODY',
        },
        <String, dynamic>{'code': 'REAR', 'labelKey': 'locationRear'},
      ]);
      expect(values.map((value) => value.code), <String>['REAR', 'FRONT']);
      expect(values.last.parentCode, 'BODY');

      final transitions = StatusTransitions.fromJson(<String, dynamic>{
        'entity': 'job',
        'current': 'PENDING_REVIEW',
        'allowedNext': <dynamic>['APPROVED', 'REJECTED'],
      }, entity: 'job');
      expect(transitions.current, 'PENDING_REVIEW');
      expect(transitions.allowedNext, <String>['APPROVED', 'REJECTED']);
    });

    test('models carry keys, never English label text', () {
      final record = ReferenceRecord.fromJson(_record('ASSIGNED'));
      expect(record.labelKey, 'jobsStatusASSIGNED');
      expect(record.toJson().containsKey('label'), isFalse);
      expect(record.toJson()['labelKey'], 'jobsStatusASSIGNED');
    });
  });

  group('repository cache', () {
    test(
      'reuses the ETag and accepts 304 without refetching the body',
      () async {
        var calls = 0;
        final adapter = _ScriptedAdapter((options) {
          calls += 1;
          if (calls == 1) {
            return _json(
              200,
              <dynamic>[_record('ASSIGNED', tone: 'info', order: 2)],
              headers: <String, List<String>>{
                'etag': <String>['"v1"'],
              },
            );
          }
          expect(options.headers['If-None-Match'], '"v1"');
          return _json(304, const <String, dynamic>{});
        });
        final repository = ReferenceRepository(_api(adapter));

        final first = await repository.statuses('job');
        final second = await repository.statuses('job');

        expect(first.single.code, 'ASSIGNED');
        expect(second.single.code, 'ASSIGNED');
        expect(adapter.requests, hasLength(2));
        expect(adapter.requests.last.headers['If-None-Match'], '"v1"');
      },
    );

    test('falls back to the persistent cache when the network fails', () async {
      final store = InMemoryReferenceStore();
      final online = _ScriptedAdapter(
        (_) => _json(200, <dynamic>[_record('DRAFT', order: 1)]),
      );
      final firstRepository = ReferenceRepository(_api(online), store: store);
      final first = await firstRepository.statuses('job');
      expect(first.single.code, 'DRAFT');

      final offline = _ScriptedAdapter(
        (_) => _json(500, const <String, dynamic>{}),
      );
      final secondRepository = ReferenceRepository(_api(offline), store: store);
      final cached = await secondRepository.statuses('job');

      expect(cached.single.code, 'DRAFT');
    });

    test('provider resolves records through the configured client', () async {
      final adapter = _ScriptedAdapter(
        (_) => _json(200, <dynamic>[_record('PUBLISHED', tone: 'success')]),
      );
      final container = ProviderContainer(
        overrides: [
          referenceApiProvider.overrideWithValue(_api(adapter)),
          referenceStoreProvider.overrideWithValue(InMemoryReferenceStore()),
        ],
      );
      addTearDown(container.dispose);

      final records = await container.read(statusesProvider('job').future);
      expect(records.single.code, 'PUBLISHED');
      expect(records.single.labelKey, 'jobsStatusPUBLISHED');
    });
  });

  group('draft visibility', () {
    test(
      'the client read omits drafts and includeDraft exposes them',
      () async {
        final adapter = _ScriptedAdapter((options) {
          final includeDraft =
              options.uri.queryParameters['includeDraft'] == 'true';
          return _json(200, <dynamic>[
            if (includeDraft) _record('DRAFT', order: 0),
            _record('PUBLISHED', order: 1),
          ]);
        });
        final repository = ReferenceRepository(_api(adapter));

        final live = await repository.statuses('job');
        final all = await repository.statuses('job', includeDraft: true);

        expect(live.map((record) => record.code), <String>['PUBLISHED']);
        expect(all.map((record) => record.code), <String>[
          'DRAFT',
          'PUBLISHED',
        ]);
        expect(draftCodes(all, live), <String>{'DRAFT'});
        expect(draftCodes(all, all), isEmpty);
        expect(
          adapter.requests.first.uri.queryParameters.containsKey(
            'includeDraft',
          ),
          isFalse,
        );
        expect(
          adapter.requests.last.uri.queryParameters['includeDraft'],
          'true',
        );
      },
    );

    test('admin providers always request drafts', () async {
      final adapter = _ScriptedAdapter(
        (_) => _json(200, <dynamic>[_record('DRAFT')]),
      );
      final container = ProviderContainer(
        overrides: [
          referenceApiProvider.overrideWithValue(_api(adapter)),
          referenceStoreProvider.overrideWithValue(InMemoryReferenceStore()),
        ],
      );
      addTearDown(container.dispose);

      final records = await container.read(adminStatusesProvider('job').future);
      expect(records.single.code, 'DRAFT');
      expect(
        adapter.requests.single.uri.queryParameters['includeDraft'],
        'true',
      );
    });

    test('status parses when present and drives the draft set', () {
      final draft = ReferenceRecord.fromJson(<String, dynamic>{
        ..._record('DRAFTED'),
        'status': 'DRAFT',
      });
      final live = ReferenceRecord.fromJson(<String, dynamic>{
        ..._record('LIVE'),
        'status': 'PUBLISHED',
      });
      final legacy = ReferenceRecord.fromJson(_record('LEGACY'));

      expect(draft.status, 'DRAFT');
      expect(live.status, 'PUBLISHED');
      expect(legacy.status, isNull);

      // Status wins when present, even if the published list is unavailable.
      expect(draftCodes(<ReferenceRecord>[draft, live], const []), <String>{
        'DRAFTED',
      });
      // Without status, the published diff remains the fallback.
      expect(
        draftCodes(<ReferenceRecord>[legacy], const <ReferenceRecord>[]),
        <String>{'LEGACY'},
      );
      expect(
        draftCodes(<ReferenceRecord>[legacy], <ReferenceRecord>[legacy]),
        isEmpty,
      );
    });
  });
}
