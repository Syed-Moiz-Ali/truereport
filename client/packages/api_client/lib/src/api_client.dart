import 'dart:async';

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
    super.detail,
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
    _dio.interceptors.add(InterceptorsWrapper(onError: _handleAuthError));
  }

  final Dio _dio;

  String? accessToken;

  /// BCP-47 language code sent as `Accept-Language` on every request.
  String? acceptLanguage;

  /// Optional client marker sent as `X-Client` (for example
  /// `platform_admin`) so the backend can scope error response fields.
  String? clientName;

  /// Invoked once when an authenticated request is rejected with 401 and the
  /// refresh attempt fails (or no refresh is available).
  ///
  /// The session layer uses this to clear the stored session and route to
  /// sign-in. Public endpoints never trigger it.
  void Function()? onUnauthorized;

  /// Refreshes the access token, persists the new session, and returns the new
  /// token. Concurrent 401s share a single in-flight call.
  Future<String?> Function()? tokenRefresher;

  Future<String?>? _refreshInFlight;

  static const String _retryFlag = '__auth_retried__';

  /// Paths that must never carry a bearer token.
  ///
  /// Spring's resource server rejects an invalid token even on `permitAll`
  /// routes, so sending stale credentials to public endpoints would otherwise
  /// make language bootstrap and sign-in unrecoverable.
  static bool isAnonymousPath(String path) {
    final normalized = path.split('?').first;
    return normalized.startsWith('/api/v1/i18n/') ||
        normalized == '/api/v1/auth/login' ||
        normalized == '/api/v1/auth/refresh' ||
        normalized == '/api/v1/auth/2fa/verify' ||
        normalized.startsWith('/r/') ||
        normalized.startsWith('/report/');
  }

  Dio get raw => _dio;

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(headers: _authHeaders(path)),
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
        options: Options(headers: _authHeaders(path)),
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
        options: Options(headers: _authHeaders(path)),
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
        options: Options(headers: _headers(path, headers)),
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
        options: Options(headers: _headers(path, headers)),
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
        options: Options(headers: _headers(path, headers)),
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
        options: Options(headers: _authHeaders(path)),
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
            ..._headers(path, headers),
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
          headers: _authHeaders(path),
          responseType: ResponseType.bytes,
        ),
      );
      return response.data ?? <int>[];
    } on DioException catch (error) {
      throw _toFailure(error);
    }
  }

  Map<String, String> _headers(String path, Map<String, String>? extra) {
    return {..._authHeaders(path), ...?extra};
  }

  Map<String, String> _authHeaders(String path) {
    final headers = <String, String>{};
    final token = accessToken;
    if (!isAnonymousPath(path) && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final language = acceptLanguage;
    if (language != null && language.isNotEmpty) {
      headers['Accept-Language'] = language;
    }
    final client = clientName;
    if (client != null && client.isNotEmpty) {
      headers['X-Client'] = client;
    }
    return headers;
  }

  Future<void> _handleAuthError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final request = error.requestOptions;
    if (error.response?.statusCode != 401 || isAnonymousPath(request.path)) {
      handler.next(error);
      return;
    }
    final alreadyRetried = request.extra[_retryFlag] == true;
    final token = alreadyRetried ? null : await _refreshOnce();
    if (token == null || token.isEmpty) {
      accessToken = null;
      final notify = onUnauthorized;
      if (notify != null) {
        scheduleMicrotask(notify);
      }
      handler.next(error);
      return;
    }
    accessToken = token;
    request.extra[_retryFlag] = true;
    request.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await _dio.fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// One refresh at a time; concurrent 401s await the same future.
  Future<String?> _refreshOnce() {
    final existing = _refreshInFlight;
    if (existing != null) return existing;
    final refresher = tokenRefresher;
    if (refresher == null) return Future<String?>.value();
    final future = refresher().then<String?>(
      (value) => value,
      onError: (Object _) => null,
    );
    _refreshInFlight = future;
    future.whenComplete(() {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
      }
    });
    return future;
  }

  AppFailure _toFailure(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final problem = ProblemDetails.fromJson(data);
      return ApiFailure(
        code: problem.code,
        messageKey: problem.messageKey,
        traceId: problem.traceId,
        statusCode: problem.status ?? status,
        detail: problem.detail,
        errors: _errorList(data['errors']),
      );
    }
    return AppFailure(
      code: error.type.name.toUpperCase(),
      messageKey: 'error.network',
      statusCode: status,
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
