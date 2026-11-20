import 'dart:async';
import 'dart:typed_data';

import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/platform_config_api.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';

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

ResponseBody _json(Object body) => ResponseBody.fromString(
  body is String ? body : '{"rules":[{"resultCode":"DEFECT_FOUND","minPhotos":2,"minVideos":1,"minNotesChars":12,"requiredEvidenceType":"PHOTO","minDurationSeconds":6,"maxDurationSeconds":60}]}',
  200,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
  },
);

void main() {
  test(
    'evidence rules save through the existing item-config endpoint',
    () async {
      final adapter = _ScriptedAdapter(
        (_) => _json(
          '[{"resultCode":"DEFECT_FOUND","minPhotos":2,"minVideos":1,"minNotesChars":12,"requiredEvidenceType":"PHOTO","minDurationSeconds":6,"maxDurationSeconds":60}]',
        ),
      );
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      dio.httpClientAdapter = adapter;
      final api = ApiClient(
        config: const ApiConfig(
          baseUrl: 'http://localhost',
          environment: 'test',
        ),
        dio: dio,
      );
      final configApi = PlatformConfigApi(
        api,
        const ApiEndpoints(baseUrl: 'http://localhost'),
      );

      final saved = await configApi.replaceEvidenceRules(
        'item-1',
        'ver-1',
        const <EvidenceRule>[
          EvidenceRule(
            resultCode: 'DEFECT_FOUND',
            minPhotos: 2,
            minVideos: 1,
            minNotesChars: 12,
            requiredEvidenceType: 'PHOTO',
            minDurationSeconds: 6,
            maxDurationSeconds: 60,
          ),
        ],
      );

      expect(adapter.requests.single.method, 'PUT');
      expect(
        adapter.requests.single.path,
        '/api/v1/platform/master/items/item-1/versions/ver-1/evidence-rules',
      );
      final body = adapter.requests.single.data as Map<String, dynamic>;
      expect((body['rules'] as List<dynamic>).single, <String, dynamic>{
        'resultCode': 'DEFECT_FOUND',
        'minPhotos': 2,
        'minVideos': 1,
        'minNotesChars': 12,
        'requiredEvidenceType': 'PHOTO',
        'minDurationSeconds': 6,
        'maxDurationSeconds': 60,
      });
      expect(saved.single.minPhotos, 2);
      expect(saved.single.requiredEvidenceType, 'PHOTO');
      expect(saved.single.minDurationSeconds, 6);
      expect(saved.single.maxDurationSeconds, 60);
    },
  );
}
