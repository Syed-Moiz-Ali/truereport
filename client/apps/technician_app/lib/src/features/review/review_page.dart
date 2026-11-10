import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/features/profile/profile_sheet.dart';
import 'package:technician_app/src/features/review/final_review_view.dart';
import 'package:technician_app/src/features/review/finalize_view.dart';
import 'package:technician_app/src/technician_providers.dart';
import 'package:uuid/uuid.dart';

class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  late final String _idempotencyKey = const Uuid().v7();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final review = ref.watch(inspectionReviewProvider(widget.jobId));
    final checklist = ref.watch(inspectionChecklistProvider(widget.jobId));
    final job = ref.watch(technicianJobProvider(widget.jobId));
    final loading = review.isLoading || checklist.isLoading || job.isLoading;
    final error = review.error ?? checklist.error ?? job.error;
    if (error != null &&
        review.value == null &&
        checklist.value == null &&
        job.value == null) {
      return AppScaffold(
        appBar: AppBar(title: Text(l10n.reviewAndFinalize)),
        body: Center(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.lg),
            child: ErrorState(
              title: l10n.error,
              body: l10n.genericError,
              onRetry: () {
                ref.invalidate(inspectionReviewProvider(widget.jobId));
                ref.invalidate(inspectionChecklistProvider(widget.jobId));
                ref.invalidate(technicianJobProvider(widget.jobId));
              },
              retryLabel: l10n.retryAction,
            ),
          ),
        ),
      );
    }
    if (loading ||
        review.value == null ||
        checklist.value == null ||
        job.value == null) {
      return AppScaffold(
        appBar: AppBar(title: Text(l10n.reviewAndFinalize)),
        body: Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: const LoadingSkeleton(lines: 6),
        ),
      );
    }

    final reviewValue = review.value!;
    final checklistValue = checklist.value!;
    final jobValue = job.value!;
    final blocked = reviewValue.blocking.isNotEmpty || !reviewValue.ready;

    if (blocked) {
      return FinalReviewView(
        job: jobValue,
        review: reviewValue,
        busy: _busy,
        onOpenIssue: (issue) {
          if (issue.inspectionItemId != null) {
            context.push(
              '/jobs/${widget.jobId}/items/${issue.inspectionItemId}',
            );
          }
        },
        onContinue: () {
          ref.invalidate(inspectionReviewProvider(widget.jobId));
        },
        onBack: () => context.pop(),
        onProfile: () => showTechnicianProfile(context, ref),
      );
    }

    return FinalizeView(
      job: jobValue,
      review: reviewValue,
      checklist: checklistValue,
      busy: _busy,
      finalized: jobValue.status == 'FINALIZED',
      onFinalize: () => _finalize(reviewValue),
      onBack: () => context.pop(),
      onProfile: () => showTechnicianProfile(context, ref),
    );
  }

  Future<void> _finalize(ReviewResult review) async {
    final l10n = AppLocalizations.of(context);
    if (!review.ready || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(technicianApiProvider)
          .finalize(widget.jobId, _idempotencyKey);
      if (result.status != 'FINALIZED') {
        throw StateError('Finalize did not return FINALIZED');
      }
      ref.invalidate(technicianJobProvider(widget.jobId));
      ref.invalidate(technicianJobsProvider);
      ref.invalidate(inspectionChecklistProvider(widget.jobId));
      ref.invalidate(inspectionReviewProvider(widget.jobId));
      ref.invalidate(technicianReportProvider(widget.jobId));
      if (mounted) {
        context.go('/jobs/${widget.jobId}/finalized');
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
