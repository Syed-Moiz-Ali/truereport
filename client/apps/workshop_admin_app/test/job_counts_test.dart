import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const _countsJson = <String, dynamic>{
  'draft': 1,
  'scheduled': 2,
  'newScheduled': 3,
  'assigned': 4,
  'inProgress': 5,
  'readyToFinalize': 6,
  'finalized': 7,
  'finalizedToday': 8,
  'cancelled': 9,
  'total': 10,
};

HttpAdminApi _apiWith({
  required bool fail,
  required List<String> requestedPaths,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        requestedPaths.add(options.path);
        if (fail) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            ),
          );
          return;
        }
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: _countsJson,
          ),
        );
      },
    ),
  );
  final client = ApiClient(
    config: const ApiConfig(
      baseUrl: 'http://localhost:8080',
      environment: 'test',
    ),
    dio: dio,
  );
  return HttpAdminApi(
    client,
    const ApiEndpoints(baseUrl: 'http://localhost:8080'),
  );
}

void main() {
  test('workshopJobCounts centralises the counts path', () {
    expect(
      const ApiEndpoints(baseUrl: '').workshopJobCounts,
      '/api/'
      'v1/workshop/jobs/counts',
    );
  });

  test('jobCounts hits the counts endpoint and maps every field', () async {
    final requestedPaths = <String>[];
    final counts = await _apiWith(
      fail: false,
      requestedPaths: requestedPaths,
    ).jobCounts();

    expect(requestedPaths, [
      '/api/'
      'v1/workshop/jobs/counts',
    ]);
    expect(counts.draft, 1);
    expect(counts.scheduled, 2);
    expect(counts.newScheduled, 3);
    expect(counts.assigned, 4);
    expect(counts.inProgress, 5);
    expect(counts.readyToFinalize, 6);
    expect(counts.finalized, 7);
    expect(counts.finalizedToday, 8);
    expect(counts.cancelled, 9);
    expect(counts.total, 10);
    expect(counts.active, 4 + 5);
  });

  test('jobCounts failure propagates instead of inventing numbers', () async {
    final requestedPaths = <String>[];
    final api = _apiWith(fail: true, requestedPaths: requestedPaths);

    // Must throw: no derived tier, no hardcoded fallback object.
    await expectLater(api.jobCounts(), throwsA(anything));
    expect(requestedPaths, [
      '/api/'
      'v1/workshop/jobs/counts',
    ]);
  });
}
