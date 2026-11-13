import 'package:api_client/src/api_config.dart';
import 'package:api_client/src/problem_details.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// Failure carrying the localized field errors returned in a ProblemDetails
/// payload. It extends [AppFailure] so existing callers keep working.
class ApiFailure extends AppFailure {
  const ApiFailure({
    required super.code,
    required super.messageKey,
    super.traceId,
    super.statusCode,
    this.errors = const <Map<String, dynamic>>[],
  });

  final List<Map<String, dynamic>> errors;
}

class ApiClient {
  ApiClient({required ApiConfig config, Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: config.baseUrl)) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers.putIfAbsent('X-Request-Id', () => const Uuid().v7());
          handler.next(options);
        },
      ),
    );
    // Debug-only HTTP trace. Pure-Dart debug check (no flutter dependency).
    // Bodies are NEVER logged (login posts carry the password).
    var debug = false;
    assert(() {
      debug = true;
      return true;
    }());
    if (debug) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
          // ignore: avoid_print — debug-only trace; api_client has no flutter dep for debugPrint.
          logPrint: (obj) => print('[Api] $obj'),
        ),
      );
    }
  }

  final Dio _dio;

  String? accessToken;

  /// BCP-47 language code sent as `Accept-Language` on every request.
  String? acceptLanguage;

  Dio get raw => _dio;

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(headers: _authHeaders()),
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw _toFailure(error);
    }
  }

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        options: Options(headers: _authHeaders()),
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw _toFailure(error);
    }
  }

  Future<dynamic> getDynamic(String path, {Map<String, dynamic>? query}) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: query,
        options: Options(headers: _authHeaders()),
      );
      return response.data;
    } on DioException catch (error) {
      throw _toFailure(error);
    }
  }

  Future<dynamic> postDynamic(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: body,
        options: Options(headers: _headers(headers)),
      );
      return response.data;
    } on DioException catch (error) {
      throw _toFailure(error);
    }
  }

  Future<dynamic> putDynamic(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        path,
        data: body,
        options: Options(headers: _headers(headers)),
      );
      return response.data;
    } on DioException catch (error) {
      throw _toFailure(error);
    }
  }

  Future<dynamic> deleteDynamic(
    String path, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(
        path,
        options: Options(headers: _headers(headers)),
      );
      return response.data;
    } on DioException catch (error) {
      throw _toFailure(error);
    }
  }

  Future<dynamic> postForm(String path, FormData form) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: form,
        options: Options(headers: _authHeaders()),
      );
      return response.data;
    } on DioException catch (error) {
      throw _toFailure(error);
    }
  }

  Future<void> putBytes(
    String path, {
    required List<int> bytes,
    required String contentType,
    Map<String, String>? headers,
  }) async {
    await putBytesWithHeaders(
      path,
      bytes: bytes,
      contentType: contentType,
      headers: headers,
    );
  }

  Future<dynamic> putBytesWithHeaders(
    String path, {
    required List<int> bytes,
    required String contentType,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        path,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            ..._headers(headers),
            'Content-Type': contentType,
            'Content-Length': bytes.length.toString(),
          },
        ),
      );
      return response.data;
    } on DioException catch (error) {
      throw _toFailure(error);
    }
  }

  Future<List<int>> getBytes(String path, {Map<String, dynamic>? query}) async {
    try {
      final response = await _dio.get<List<int>>(
        path,
        queryParameters: query,
        options: Options(
          headers: _authHeaders(),
          responseType: ResponseType.bytes,
        ),
      );
      return response.data ?? <int>[];
    } on DioException catch (error) {
      throw _toFailure(error);
    }
  }

  Map<String, String> _headers(Map<String, String>? extra) {
    return {..._authHeaders(), ...?extra};
  }

  Map<String, String> _authHeaders() {
    final headers = <String, String>{};
    final token = accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final language = acceptLanguage;
    if (language != null && language.isNotEmpty) {
      headers['Accept-Language'] = language;
    }
    return headers;
  }

  AppFailure _toFailure(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final problem = ProblemDetails.fromJson(data);
      return ApiFailure(
        code: problem.code,
        messageKey: problem.messageKey,
        traceId: problem.traceId,
        statusCode: problem.status ?? error.response?.statusCode,
        errors: _errorList(data['errors']),
      );
    }
    return AppFailure(
      code: error.type.name.toUpperCase(),
      messageKey: 'error.network',
      statusCode: error.response?.statusCode,
    );
  }

  List<Map<String, dynamic>> _errorList(dynamic value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }
    return value
        .whereType<Map>()
        .map(
          (item) => item.map(
            (key, fieldValue) => MapEntry(key.toString(), fieldValue),
          ),
        )
        .toList(growable: false);
  }
}
