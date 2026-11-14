class AppFailure implements Exception {
  const AppFailure({
    required this.code,
    required this.messageKey,
    this.traceId,
    this.statusCode,
    this.detail,
  });

  final String code;
  final String messageKey;
  final String? traceId;
  final int? statusCode;
  final String? detail;

  @override
  String toString() => 'AppFailure(code: $code, messageKey: $messageKey)';
}
