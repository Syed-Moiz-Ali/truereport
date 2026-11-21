import 'package:flutter/foundation.dart';

/// One row of the content-translation review queue.
@immutable
class TranslationReviewItem {
  const TranslationReviewItem({
    required this.entityType,
    required this.entityId,
    required this.field,
    required this.lang,
    required this.body,
    required this.origin,
    required this.status,
    required this.provider,
    required this.sourceText,
    required this.safetyCritical,
    required this.reviewNote,
  });

  final String entityType;
  final String entityId;
  final String field;
  final String lang;
  final String body;
  final String origin;
  final String status;
  final String provider;
  final String sourceText;
  final bool safetyCritical;
  final String reviewNote;

  /// Stable row key for lists and keys.
  String get id => '$entityType/$entityId/$field/$lang';

  factory TranslationReviewItem.fromJson(Map<String, dynamic> json) =>
      TranslationReviewItem(
        entityType: _text(json['entityType']),
        entityId: _text(json['entityId']),
        field: _text(json['field']),
        lang: _text(json['lang']),
        body: _text(json['body']),
        origin: _text(json['origin']),
        status: _text(json['status']),
        provider: _text(json['provider']),
        sourceText: _text(json['sourceText']),
        safetyCritical: json['safetyCritical'] == true,
        reviewNote: _text(json['reviewNote']),
      );
}

/// Counters for one language, straight from the backend.
@immutable
class TranslationReviewSummary {
  const TranslationReviewSummary({
    required this.lang,
    required this.states,
    required this.safetyCriticalPendingReview,
    required this.safetyCriticalBlocked,
  });

  final String lang;
  final Map<String, int> states;
  final int safetyCriticalPendingReview;
  final int safetyCriticalBlocked;

  int countOf(String state) => states[state] ?? 0;

  factory TranslationReviewSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['states'];
    final states = <String, int>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        if (key is String) {
          states[key] = value is num ? value.toInt() : 0;
        }
      });
    }
    return TranslationReviewSummary(
      lang: _text(json['lang']),
      states: states,
      safetyCriticalPendingReview: _int(json['safetyCriticalPendingReview']),
      safetyCriticalBlocked: _int(json['safetyCriticalBlocked']),
    );
  }
}

/// Review states the backend accepts for the `state` filter.
abstract final class TranslationReviewState {
  static const String pending = 'PENDING_REVIEW';
  static const String reviewed = 'REVIEWED';
  static const String stale = 'STALE';

  static const List<String> filters = <String>[pending, reviewed, stale];
}

/// Review actions the backend accepts.
abstract final class TranslationReviewAction {
  static const String approve = 'APPROVE';
  static const String edit = 'EDIT';
  static const String reject = 'REJECT';
}

String _text(Object? value) => value == null ? '' : '$value';

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
