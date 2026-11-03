import 'package:core/core.dart';

class ProblemDetails {
  const ProblemDetails({
    required this.code,
    required this.messageKey,
    this.title,
    this.detail,
    this.traceId,
    this.status,
  });

  final String code;
  final String messageKey;
  final String? title;
  final String? detail;
  final String? traceId;
  final int? status;

  factory ProblemDetails.fromJson(Map<String, dynamic> json) => ProblemDetails(
    code: json['code'] as String? ?? 'UNKNOWN',
    messageKey: json['messageKey'] as String? ?? 'error.unknown',
    title: json['title'] as String?,
    detail: json['detail'] as String?,
    traceId: json['traceId'] as String?,
    status: json['status'] as int?,
  );

  AppFailure toFailure() => AppFailure(
    code: code,
    messageKey: messageKey,
    traceId: traceId,
    statusCode: status,
  );
}
