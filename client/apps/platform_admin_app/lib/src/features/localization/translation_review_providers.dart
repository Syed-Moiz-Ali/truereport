import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import 'translation_review_models.dart';

class _ReviewLanguage extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? code) => state = code;
}

class _ReviewFilter extends Notifier<String> {
  @override
  String build() => TranslationReviewState.pending;

  void select(String state) => this.state = state;
}

/// Target language for the review queue. Null means "not chosen yet"; the
/// screen resolves it from the app language or the first served language.
final translationReviewLanguageProvider =
    NotifierProvider<_ReviewLanguage, String?>(_ReviewLanguage.new);

/// Active state filter (`PENDING_REVIEW`, `REVIEWED`, `STALE`).
final translationReviewStateProvider = NotifierProvider<_ReviewFilter, String>(
  _ReviewFilter.new,
);

/// Languages that actually carry content translations. The UI-message registry
/// is English-only by design, so it cannot drive this selector.
final translationReviewLanguagesProvider =
    FutureProvider.autoDispose<List<PlatformLanguage>>(
      (ref) => ref.watch(platformConfigApiProvider).contentLanguages(),
    );

/// One page of the review queue for a language, state and scope.
final translationReviewQueueProvider = FutureProvider.autoDispose
    .family<
      List<TranslationReviewItem>,
      ({String lang, String state, String entityType, int page})
    >(
      (ref, key) => ref
          .watch(platformConfigApiProvider)
          .contentReview(
            lang: key.lang,
            state: key.state,
            entityType: key.entityType.isEmpty ? null : key.entityType,
            page: key.page,
            size: 50,
          ),
    );

/// Jobs the provider could not translate, with the English source and reason.
final failedTranslationJobsProvider = FutureProvider.autoDispose
    .family<List<FailedTranslationJob>, ({String lang, String entityType})>(
      (ref, key) => ref
          .watch(platformConfigApiProvider)
          .contentFailedJobs(
            lang: key.lang,
            entityType: key.entityType.isEmpty ? null : key.entityType,
          ),
    );

/// Summary counters for a language and scope.
final translationReviewSummaryProvider = FutureProvider.autoDispose
    .family<TranslationReviewSummary, ({String lang, String entityType})>(
      (ref, key) => ref
          .watch(platformConfigApiProvider)
          .contentReviewSummary(
            key.lang,
            entityType: key.entityType.isEmpty ? null : key.entityType,
          ),
    );

/// Review actions. Every result comes back from the server and both the queue
/// and the summary are invalidated, so no state exists only on the client.
class TranslationReviewActions {
  TranslationReviewActions(this._ref);

  final Ref _ref;

  Future<TranslationReviewItem> approve(TranslationReviewItem item) =>
      _review(item, TranslationReviewAction.approve);

  Future<TranslationReviewItem> edit(TranslationReviewItem item, String body) =>
      _review(item, TranslationReviewAction.edit, body: body.trim());

  Future<TranslationReviewItem> reject(
    TranslationReviewItem item,
    String note,
  ) => _review(item, TranslationReviewAction.reject, note: note.trim());

  /// Approves every pending non-safety row for [lang]. [dryRun] returns the
  /// count without changing anything.
  Future<BulkApproveResult> bulkApprove(
    String lang, {
    bool dryRun = false,
    List<String>? entityTypes,
  }) async {
    final result = await _ref
        .read(platformConfigApiProvider)
        .bulkApproveContent(
          lang: lang,
          dryRun: dryRun,
          entityTypes: entityTypes,
        );
    if (!dryRun) {
      _ref.invalidate(translationReviewQueueProvider);
      _ref.invalidate(translationReviewSummaryProvider);
    }
    return result;
  }

  Future<BulkApproveResult> approveSelected(
    String lang,
    List<TranslationReviewItem> items,
  ) async {
    final result = await _ref
        .read(platformConfigApiProvider)
        .approveSelectedContent(lang: lang, items: items);
    _ref.invalidate(translationReviewQueueProvider);
    _ref.invalidate(translationReviewSummaryProvider);
    return result;
  }

  Future<TranslationReviewItem> _review(
    TranslationReviewItem item,
    String action, {
    String? body,
    String? note,
  }) async {
    final result = await _ref
        .read(platformConfigApiProvider)
        .reviewContent(
          entityType: item.entityType,
          entityId: item.entityId,
          field: item.field,
          lang: item.lang,
          action: action,
          body: body,
          note: note,
        );
    _ref.invalidate(translationReviewQueueProvider);
    _ref.invalidate(translationReviewSummaryProvider);
    return result;
  }
}

final translationReviewActionsProvider = Provider<TranslationReviewActions>(
  TranslationReviewActions.new,
);
