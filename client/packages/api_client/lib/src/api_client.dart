import 'package:api_client/src/api_config.dart';
import 'package:api_client/src/problem_details.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

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

  Future<dynamic> putDynamic(String path, {Object? body}) async {
    try {
      final response = await _dio.put<dynamic>(
        path,
        data: body,
        options: Options(headers: _authHeaders()),
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
    try {
      await _dio.put<void>(
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
    } on DioException catch (error) {
      throw _toFailure(error);
    }
  }

  Future<List<int>> getBytes(String path) async {
    try {
      final response = await _dio.get<List<int>>(
        path,
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
      return ProblemDetails.fromJson(data).toFailure();
    }
    return AppFailure(
      code: error.type.name.toUpperCase(),
      messageKey: 'error.network',
      statusCode: error.response?.statusCode,
    );
  }
}
