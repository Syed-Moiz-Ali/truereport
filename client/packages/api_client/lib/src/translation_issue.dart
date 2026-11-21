import 'package:core/core.dart';

import 'api_client.dart';

/// One entry from a `409 TRANSLATION_REVIEW_REQUIRED` publish gate.
///
/// The backend mirrors the issue list into the ProblemDetails `errors` array,
/// which [ApiClient] keeps on [ApiFailure]. Parsing lives here so both apps use
/// one shape and one parser.
class TranslationIssue {
  const TranslationIssue({
    required this.entityType,
    required this.entityId,
    required this.field,
    required this.lang,
    required this.reason,
  });

  final String entityType;
  final String entityId;
  final String field;
  final String lang;
  final String reason;

  /// Issues carried by [failure], or an empty list when it is not a review gate.
  static List<TranslationIssue> from(AppFailure failure) {
    if (failure is! ApiFailure || failure.errors.isEmpty) {
      return const <TranslationIssue>[];
    }
    return failure.errors
        .map(fromMap)
        .whereType<TranslationIssue>()
        .toList(growable: false);
  }

  /// Tolerant single-issue parser; returns null when the map is not an issue.
  static TranslationIssue? fromMap(Map<String, dynamic> json) {
    final entityType = _text(json['entityType']);
    final field = _text(json['field']);
    if (entityType.isEmpty || field.isEmpty) return null;
    return TranslationIssue(
      entityType: entityType,
      entityId: _text(json['entityId']),
      field: field,
      lang: _text(json['lang']),
      reason: _text(json['reason']),
    );
  }

  static String _text(Object? value) => value == null ? '' : '$value';
}
