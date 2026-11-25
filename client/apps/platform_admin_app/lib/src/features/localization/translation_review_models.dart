import 'package:flutter/foundation.dart';

/// Backend wire scope for "every business content entity, no UI text".
const String contentScopeType = 'CONTENT';

/// Backend wire entity type for static interface strings.
const String interfaceTextScopeType = 'UI_MESSAGE';

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
    required this.jobs,
    this.targets = 0,
  });

  final String lang;
  final Map<String, int> states;
  final int safetyCriticalPendingReview;
  final int safetyCriticalBlocked;
  final TranslationJobProgress jobs;

  /// English source values in scope (0 = the server cannot count them), so the
  /// desk can show "3913 of 3926 translated" instead of a lonely "Pending: 0".
  final int targets;

  int get translated => total;

  /// Rows can outnumber targets (a deleted item keeps its translations), so the
  /// coverage number must never read "409 of 388".
  int get covered => targets > 0 ? total.clamp(0, targets) : total;

  int get missing => targets > 0 ? (targets - total).clamp(0, targets) : 0;

  int countOf(String state) => states[state] ?? 0;

  int get total => states.values.fold(0, (sum, value) => sum + value);

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
      jobs: TranslationJobProgress.fromJson(
        json['jobs'] is Map
            ? (json['jobs'] as Map).map((k, v) => MapEntry(k.toString(), v))
            : const <String, dynamic>{},
      ),
      targets: _int(json['targets']),
    );
  }
}

@immutable
class FailedTranslationJob {
  const FailedTranslationJob({
    required this.entityType,
    required this.entityId,
    required this.field,
    required this.source,
    required this.error,
  });

  final String entityType;
  final String entityId;
  final String field;
  final String source;
  final String error;

  factory FailedTranslationJob.fromJson(Map<String, dynamic> json) =>
      FailedTranslationJob(
        entityType: _text(json['entityType']),
        entityId: _text(json['entityId']),
        field: _text(json['field']),
        source: _text(json['source']),
        error: _text(json['error']),
      );
}

/// Background machine-translation progress for the selected language + scope.@immutable
class TranslationJobProgress {
  const TranslationJobProgress({
    required this.pending,
    required this.running,
    required this.done,
    required this.failed,
  });

  const TranslationJobProgress.empty()
    : pending = 0,
      running = 0,
      done = 0,
      failed = 0;

  final int pending;
  final int running;
  final int done;
  final int failed;

  int get total => pending + running + done + failed;

  /// Jobs still queued or in flight.
  int get active => pending + running;

  double get fraction => total == 0 ? 0 : done / total;

  factory TranslationJobProgress.fromJson(Map<String, dynamic> json) =>
      TranslationJobProgress(
        pending: _int(json['pending']),
        running: _int(json['running']),
        done: _int(json['done']),
        failed: _int(json['failed']),
      );
}

/// Result of a backfill preview or run.
@immutable
class ContentBackfillResult {
  const ContentBackfillResult({required this.enqueued, required this.skipped});

  final int enqueued;
  final int skipped;

  factory ContentBackfillResult.fromJson(Map<String, dynamic> json) =>
      ContentBackfillResult(
        enqueued: _int(json['enqueued']),
        skipped: _int(json['skipped']),
      );
}

/// Result of a bulk approval run (or its dry-run preview).
@immutable
class BulkApproveResult {
  const BulkApproveResult({
    required this.approved,
    required this.lang,
    required this.dryRun,
  });

  final int approved;
  final String lang;
  final bool dryRun;

  factory BulkApproveResult.fromJson(Map<String, dynamic> json) =>
      BulkApproveResult(
        approved: _int(json['approved']),
        lang: _text(json['lang']),
        dryRun: json['dryRun'] == true,
      );
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
