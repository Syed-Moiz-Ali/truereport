import 'package:dio/dio.dart';

/// Cancellation handle for an in-flight request.
///
/// The app layer never imports `dio`; it receives this small wrapper from
/// `ApiClient`, cancels an upload, and checks [isCancelled] before continuing.
class RequestCancellation {
  final CancelToken _token = CancelToken();

  bool get isCancelled => _token.isCancelled;

  /// Internal transport token. Only `ApiClient` should read this.
  CancelToken get token => _token;

  void cancel([Object? reason]) {
    if (!_token.isCancelled) {
      _token.cancel(reason ?? 'cancelled');
    }
  }
}
