import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';
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
    final pending = ref.watch(pendingSyncCountProvider).value ?? 0;
    return AppScaffold(
      appBar: AppBar(title: Text(l10n.reviewAndFinalize)),
      body: review.when(
        loading: () => Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: const LoadingSkeleton(lines: 6),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.lg),
            child: ErrorState(
              title: l10n.error,
              body: l10n.genericError,
              onRetry: () =>
                  ref.invalidate(inspectionReviewProvider(widget.jobId)),
              retryLabel: l10n.search,
            ),
          ),
        ),
        data: (value) => _Body(
          jobId: widget.jobId,
          review: value,
          checklist: checklist.value,
          pending: pending,
          busy: _busy,
          onFinalize: () => _finalize(value),
        ),
      ),
    );
  }

  Future<void> _finalize(ReviewResult review) async {
    final l10n = AppLocalizations.of(context);
    if (!review.ready) {
      return;
    }
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.finalizeConfirm,
      message: l10n.finalizeIrreversible,
      confirmLabel: l10n.finalize,
      cancelLabel: l10n.cancel,
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(technicianApiProvider)
          .finalize(widget.jobId, _idempotencyKey);
      ref.invalidate(technicianJobProvider(widget.jobId));
      ref.invalidate(technicianJobsProvider);
      ref.invalidate(inspectionChecklistProvider(widget.jobId));
      ref.invalidate(inspectionReviewProvider(widget.jobId));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.finalizedSuccessfully)));
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

class _Body extends ConsumerWidget {
  const _Body({
    required this.jobId,
    required this.review,
    required this.checklist,
    required this.pending,
    required this.busy,
    required this.onFinalize,
  });

  final String jobId;
  final ReviewResult review;
  final InspectionChecklist? checklist;
  final int pending;
  final bool busy;
  final VoidCallback onFinalize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final finalized = checklist?.job.status == 'FINALIZED';
    return ListView(
      padding: EdgeInsetsDirectional.all(context.spacing.lg),
      children: [
        SectionHeader(
          title: l10n.reviewAndFinalize,
          subtitle:
              '${review.completed}/${review.total} ${l10n.completedItems}',
        ),
        if (pending > 0) ...[
          StatusChip(
            label: l10n.savedOnPhone,
            tone: StatusTone.warning,
            icon: Icons.phone_iphone,
          ),
          SizedBox(height: context.spacing.md),
        ],
        if (review.warnings.isNotEmpty) ...[
          ...review.warnings.map(
            (warning) => Padding(
              padding: EdgeInsetsDirectional.only(bottom: context.spacing.sm),
              child: StatusChip(
                label: warning.code == 'EVIDENCE_PENDING_5B'
                    ? l10n.evidencePending
                    : warning.code,
                tone: StatusTone.warning,
                icon: Icons.info_outline,
              ),
            ),
          ),
          SizedBox(height: context.spacing.md),
        ],
        if (review.blocking.isNotEmpty) ...[
          SectionHeader(title: l10n.missingItems),
          ...review.blocking.map(
            (issue) => Padding(
              padding: EdgeInsetsDirectional.only(bottom: context.spacing.sm),
              child: Card(
                child: AppListTile(
                  leading: const Icon(Icons.error_outline),
                  title: issue.label ?? issue.code,
                  subtitle: issue.detail ?? issue.code,
                  onTap: issue.inspectionItemId == null
                      ? null
                      : () => context.push(
                          '/jobs/$jobId/items/${issue.inspectionItemId}',
                        ),
                ),
              ),
            ),
          ),
          SizedBox(height: context.spacing.lg),
        ],
        if (finalized)
          AppButton(
            label: l10n.finalizedReadOnly,
            onPressed: () => context.go('/jobs/$jobId/finalized'),
            variant: AppButtonVariant.tonal,
            expand: true,
          )
        else ...[
          AppButton(
            label: l10n.markReady,
            onPressed: review.ready && pending == 0 && !busy
                ? () async {
                    try {
                      await ref.read(technicianApiProvider).ready(jobId);
                      ref.invalidate(inspectionReviewProvider(jobId));
                      ref.invalidate(inspectionChecklistProvider(jobId));
                      ref.invalidate(technicianJobProvider(jobId));
                    } on Object {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.actionFailed)),
                        );
                      }
                    }
                  }
                : null,
            variant: AppButtonVariant.tonal,
            expand: true,
          ),
          SizedBox(height: context.spacing.sm),
          AppButton(
            label: l10n.approveAndGenerateReport,
            onPressed: review.ready && pending == 0 && !busy ? onFinalize : null,
            icon: Icons.lock_outline,
            expand: true,
          ),
          SizedBox(height: context.spacing.sm),
          Text(l10n.finalizeIrreversible, style: context.texts.bodySmall),
        ],
      ],
    );
  }
}
