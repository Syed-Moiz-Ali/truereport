import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/features/jobs/publish_checklist_page.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

class ApproveIssuePage extends ConsumerStatefulWidget {
  const ApproveIssuePage({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<ApproveIssuePage> createState() => _ApproveIssuePageState();
}

class _ApproveIssuePageState extends ConsumerState<ApproveIssuePage> {
  final _reason = TextEditingController();
  final _safetyCapReason = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    _safetyCapReason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final job = ref.watch(cleanJobProvider(widget.jobId));
    final review = ref.watch(jobReviewProvider(widget.jobId));
    return AppScaffold(
      appBar: AppBar(title: Text(l10n.jobsApproveTitle)),
      body: ListView(
        padding: EdgeInsetsDirectional.all(context.spacing.lg),
        children: [
          SectionHeader(
            title: l10n.jobsApproveTitle,
            subtitle: l10n.jobsApproveSubtitle,
          ),
          if (_error != null) ...[
            JobInlineError(message: _error!),
            SizedBox(height: context.spacing.md),
          ],
          job.when(
            loading: () => const LoadingSkeleton(lines: 4),
            error: (error, _) => ErrorState(
              title: l10n.error,
              body: l10n.commonLoadFailed,
              retryLabel: l10n.retryAction,
              onRetry: () => ref.invalidate(cleanJobProvider(widget.jobId)),
            ),
            data: (value) => _summary(context, value),
          ),
          SizedBox(height: context.spacing.md),
          review.when(
            loading: () => const LoadingSkeleton(lines: 2),
            error: (error, _) =>
                Text(l10n.commonLoadFailed, style: context.texts.bodySmall),
            data: (value) => _scorePanel(context, value),
          ),
          SizedBox(height: context.spacing.md),
          JobPanel(
            title: l10n.jobsReviewTitle,
            icon: Icons.edit_note_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _reason,
                  label: l10n.jobsApproveReasonOptional,
                  maxLines: 2,
                ),
                SizedBox(height: context.spacing.sm),
                AppTextField(
                  controller: _safetyCapReason,
                  label: l10n.jobsSafetyCapReason,
                  maxLines: 2,
                ),
                SizedBox(height: context.spacing.md),
                Wrap(
                  spacing: context.spacing.sm,
                  runSpacing: context.spacing.sm,
                  children: [
                    AppButton(
                      key: const Key('jobs-approve-button'),
                      label: l10n.jobsApprove,
                      onPressed: _busy ? null : _approve,
                      isLoading: _busy,
                      icon: Icons.verified_outlined,
                    ),
                    AppButton(
                      key: const Key('jobs-reject-button'),
                      label: l10n.jobsReject,
                      onPressed: _busy ? null : _reject,
                      icon: Icons.block_outlined,
                      variant: AppButtonVariant.tonal,
                    ),
                    AppButton(
                      key: const Key('jobs-checklist-link'),
                      label: l10n.jobsOpenPublishChecklist,
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    PublishChecklistPage(jobId: widget.jobId),
                              ),
                            ),
                      icon: Icons.playlist_add_check_outlined,
                      variant: AppButtonVariant.text,
                    ),
                  ],
                ),
                SizedBox(height: context.spacing.sm),
                Text(
                  l10n.jobsRejectHint,
                  style: context.texts.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary(BuildContext context, CleanJob job) {
    final l10n = AppLocalizations.of(context);
    return JobPanel(
      title: l10n.jobsSummary,
      icon: Icons.assignment_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          JobKeyValue(label: l10n.jobsReference, value: job.reference),
          JobKeyValue(label: l10n.customerName, value: job.customerName),
          JobKeyValue(
            label: l10n.vehicle,
            value: '${job.vehicleMake} ${job.vehicleModel}'.trim(),
          ),
          JobKeyValue(
            label: l10n.jobsAssignedTechnician,
            value: job.assignedTechnicianName ?? l10n.unassigned,
          ),
          JobKeyValue(
            label: l10n.jobsScore,
            value: formatScore(context, job.score),
          ),
          JobKeyValue(
            label: l10n.jobsGrade,
            value: job.gradeCode ?? l10n.commonNotAvailable,
          ),
          JobKeyValue(
            label: l10n.safetyCap,
            value: job.safetyCapApplied
                ? (job.safetyCapReason ?? l10n.jobsSafetyCapApplied)
                : l10n.jobsSafetyCapNotApplied,
          ),
        ],
      ),
    );
  }

  Widget _scorePanel(BuildContext context, JobReview review) {
    final l10n = AppLocalizations.of(context);
    return JobPanel(
      title: l10n.jobsReviewTitle,
      icon: Icons.speed_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: context.spacing.sm,
            runSpacing: context.spacing.sm,
            children: [
              StatusChip(
                label:
                    '${l10n.jobsItemsAssessed}: '
                    '${formatNumber(context, review.itemsAssessed)} / '
                    '${formatNumber(context, review.itemsTotal)}',
                tone: StatusTone.info,
                icon: Icons.checklist_outlined,
              ),
              StatusChip(
                label:
                    '${l10n.jobsScorePreview}: '
                    '${formatScore(context, review.scorePreview)}',
                tone: StatusTone.neutral,
                icon: Icons.speed_outlined,
              ),
              StatusChip(
                label:
                    '${l10n.jobsGradePreview}: '
                    '${review.gradePreview ?? l10n.commonNotAvailable}',
                tone: StatusTone.success,
                icon: Icons.grade_outlined,
              ),
              if (review.safetyCapPreview != null)
                StatusChip(
                  label:
                      '${l10n.jobsSafetyCapPreview}: '
                      '${review.safetyCapPreview}',
                  tone: StatusTone.warning,
                  icon: Icons.shield_outlined,
                ),
            ],
          ),
          SizedBox(height: context.spacing.md),
          if (review.findings.isEmpty)
            Text(l10n.jobsNoFindings)
          else
            for (final finding in review.findings)
              JobKeyValue(
                label: localizedText(
                  context,
                  en: finding.labelEn,
                  ar: finding.labelAr,
                ),
                value: finding.resultCode ?? l10n.commonNotAvailable,
              ),
        ],
      ),
    );
  }

  Future<void> _approve() async {
    final l10n = AppLocalizations.of(context);
    final job = ref.read(cleanJobProvider(widget.jobId)).value;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(adminApiProvider)
          .approveJob(
            widget.jobId,
            reason: _nullIfEmpty(_reason.text),
            safetyCapReason: _nullIfEmpty(_safetyCapReason.text),
            version: job?.version,
          );
      ref.invalidate(cleanJobProvider(widget.jobId));
      ref.invalidate(jobReviewProvider(widget.jobId));
      ref.invalidate(publishChecklistProvider(widget.jobId));
      ref.invalidate(cleanJobCountsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.jobsApproved)));
      }
    } on Object {
      if (mounted) {
        setState(() => _error = l10n.commonActionFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _reject() async {
    final l10n = AppLocalizations.of(context);
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = l10n.commonReasonRequired);
      return;
    }
    final job = ref.read(cleanJobProvider(widget.jobId)).value;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(adminApiProvider)
          .rejectJob(
            widget.jobId,
            _reason.text.trim(),
            version: job?.version,
          );
      ref.invalidate(cleanJobProvider(widget.jobId));
      ref.invalidate(jobReviewProvider(widget.jobId));
      ref.invalidate(cleanJobCountsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.jobsRejected)));
      }
    } on Object {
      if (mounted) {
        setState(() => _error = l10n.commonActionFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String? _nullIfEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
