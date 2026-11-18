import 'package:api_client/api_client.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_admin_app/src/admin_api.dart';

/// Error-seam tests for the clean job API.
///
/// The job screens collapse most mutation failures into one generic message
/// today (`docs/api/contracts.md` §Error mapping): a 409 `JOB_ALREADY_ASSIGNED`
/// and a 409 `JOB_NOT_ASSIGNABLE` are indistinguishable to the UI. That is a
/// copy fix, not this wave. What this file pins is the layer underneath: the
/// transport must hand the caller **distinct, typed** failures with the HTTP
/// status and the server code intact, so a later copy change has something
/// truthful to switch on.
///
/// These call the production `HttpAdminApi`, so `ProblemDetails` parsing,
/// `ApiFailure` construction and the endpoint paths all run for real.

class _Responder {
  const _Responder({
    required this.status,
    required this.body,
    this.type = DioExceptionType.badResponse,
  });

  final int? status;
  final Map<String, dynamic> body;
  final DioExceptionType type;
}

Map<String, dynamic> _problem({
  required String code,
  required String messageKey,
  required int status,
}) => <String, dynamic>{
  'code': code,
  'messageKey': messageKey,
  'status': status,
  'title': 'Request failed',
  'detail': 'Contract fixture for $code',
  'traceId': 'trace-$code',
};

HttpAdminApi _api(
  _Responder responder, {
  List<String>? requestedPaths,
  List<Map<String, dynamic>?>? requestedBodies,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        requestedPaths?.add(options.path);
        requestedBodies?.add(
          options.data is Map<String, dynamic>
              ? options.data as Map<String, dynamic>
              : null,
        );
        handler.reject(
          DioException(
            requestOptions: options,
            type: responder.type,
            response: responder.status == null
                ? null
                : Response<dynamic>(
                    requestOptions: options,
                    statusCode: responder.status,
                    data: responder.body,
                  ),
          ),
        );
      },
    ),
  );
  return HttpAdminApi(
    ApiClient(
      config: const ApiConfig(
        baseUrl: 'http://localhost:8080',
        environment: 'test',
      ),
      dio: dio,
    ),
    const ApiEndpoints(baseUrl: 'http://localhost:8080'),
  );
}

Future<AppFailure> _failure(Future<Object?> call) async {
  try {
    await call;
  } on AppFailure catch (failure) {
    return failure;
  }
  fail('expected an AppFailure');
}

void main() {
  group('HTTP status → distinct AppFailure', () {
    test('401 keeps code, status and message key', () async {
      final failure = await _failure(
        _api(
          _Responder(
            status: 401,
            body: _problem(
              code: 'UNAUTHENTICATED',
              messageKey: 'error.unauthenticated',
              status: 401,
            ),
          ),
        ).cleanJob('job-1'),
      );
      expect(failure, isA<ApiFailure>());
      expect(failure.code, 'UNAUTHENTICATED');
      expect(failure.statusCode, 401);
      expect(failure.messageKey, 'error.unauthenticated');
      expect(failure.traceId, 'trace-UNAUTHENTICATED');
    });

    test('403 is distinct from 401', () async {
      final failure = await _failure(
        _api(
          _Responder(
            status: 403,
            body: _problem(
              code: 'FORBIDDEN',
              messageKey: 'error.forbidden',
              status: 403,
            ),
          ),
        ).cleanJob('job-1'),
      );
      expect(failure.code, 'FORBIDDEN');
      expect(failure.statusCode, 403);
    });

    test('404 is distinct from an authorisation failure', () async {
      final failure = await _failure(
        _api(
          _Responder(
            status: 404,
            body: _problem(
              code: 'JOB_NOT_FOUND',
              messageKey: 'error.notFound',
              status: 404,
            ),
          ),
        ).cleanJob('missing'),
      );
      expect(failure.code, 'JOB_NOT_FOUND');
      expect(failure.statusCode, 404);
    });

    test('409 JOB_ALREADY_ASSIGNED is distinguishable', () async {
      final failure = await _failure(
        _api(
          _Responder(
            status: 409,
            body: _problem(
              code: 'JOB_ALREADY_ASSIGNED',
              messageKey: 'error.conflict',
              status: 409,
            ),
          ),
        ).assignCleanJob('job-1', 'tech-1', null, version: 7),
      );
      expect(failure.code, 'JOB_ALREADY_ASSIGNED');
      expect(failure.statusCode, 409);
    });

    test(
      '409 JOB_NOT_ASSIGNABLE is distinguishable from JOB_ALREADY_ASSIGNED',
      () async {
        final failure = await _failure(
          _api(
            _Responder(
              status: 409,
              body: _problem(
                code: 'JOB_NOT_ASSIGNABLE',
                messageKey: 'error.conflict',
                status: 409,
              ),
            ),
          ).assignCleanJob('job-1', 'tech-1', null, version: 7),
        );
        expect(failure.code, 'JOB_NOT_ASSIGNABLE');
        expect(failure.code, isNot('JOB_ALREADY_ASSIGNED'));
        expect(failure.statusCode, 409);
      },
    );

    test(
      'a stale optimistic-concurrency version surfaces as a conflict',
      () async {
        final failure = await _failure(
          _api(
            _Responder(
              status: 409,
              body: _problem(
                code: 'JOB_VERSION_CONFLICT',
                messageKey: 'error.conflict',
                status: 409,
              ),
            ),
          ).cancelCleanJob('job-1', 'Customer cancelled', version: 2),
        );
        expect(failure.code, 'JOB_VERSION_CONFLICT');
        expect(failure.statusCode, 409);
      },
    );

    test('5xx is distinct from every 4xx', () async {
      final failure = await _failure(
        _api(
          _Responder(
            status: 500,
            body: _problem(
              code: 'INTERNAL_ERROR',
              messageKey: 'error.server',
              status: 500,
            ),
          ),
        ).cleanJobCounts(),
      );
      expect(failure.code, 'INTERNAL_ERROR');
      expect(failure.statusCode, 500);
    });

    test('a transport failure has a code but no HTTP status', () async {
      final failure = await _failure(
        _api(
          const _Responder(
            status: null,
            body: <String, dynamic>{},
            type: DioExceptionType.connectionError,
          ),
        ).cleanJob('job-1'),
      );
      expect(failure.statusCode, isNull);
      expect(failure.code, 'CONNECTIONERROR');
      expect(failure.messageKey, 'error.network');
    });
  });

  group('queries reach the clean endpoints with the right parameters', () {
    test('cleanJobs sends page/size/status/search and never legacy', () async {
      final paths = <String>[];
      await _failure(
        _api(
          _Responder(
            status: 500,
            body: _problem(
              code: 'INTERNAL_ERROR',
              messageKey: 'error.server',
              status: 500,
            ),
          ),
          requestedPaths: paths,
        ).cleanJobs(page: 2, size: 5, status: 'PENDING_REVIEW', search: 'DXB'),
      );
      expect(paths, [const ApiEndpoints(baseUrl: '').workshopCleanJobs]);
      expect(paths.single.contains('legacy'), isFalse);
    });

    test('cleanJobCounts reads the counts endpoint', () async {
      final paths = <String>[];
      await _failure(
        _api(
          _Responder(
            status: 500,
            body: _problem(
              code: 'INTERNAL_ERROR',
              messageKey: 'error.server',
              status: 500,
            ),
          ),
          requestedPaths: paths,
        ).cleanJobCounts(),
      );
      expect(paths, [const ApiEndpoints(baseUrl: '').workshopCleanJobCounts]);
    });

    test('assignCleanJob forwards technician, reason and version', () async {
      final bodies = <Map<String, dynamic>?>[];
      await _failure(
        _api(
          _Responder(
            status: 409,
            body: _problem(
              code: 'JOB_ALREADY_ASSIGNED',
              messageKey: 'error.conflict',
              status: 409,
            ),
          ),
          requestedBodies: bodies,
        ).assignCleanJob('job-1', 'tech-9', 'Cover shift', version: 12),
      );
      expect(bodies.single, {
        'technicianId': 'tech-9',
        'reason': 'Cover shift',
        'version': 12,
      });
    });
  });
}
