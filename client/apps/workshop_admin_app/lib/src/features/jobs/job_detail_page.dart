import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/approve_job_page.dart';
import 'package:workshop_admin_app/src/features/jobs/job_documents_page.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/features/jobs/public_link_page.dart';
import 'package:workshop_admin_app/src/features/jobs/publish_checklist_page.dart';
import 'package:workshop_admin_app/src/labels.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

class JobDetailPage extends ConsumerWidget {
  const JobDetailPage({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final job = ref.watch(cleanJobProvider(jobId));
    return AppScaffold(
      appBar: AppBar(
        title: Text(l10n.jobsDetailTitle),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: () {
              ref.invalidate(cleanJobProvider(jobId));
              ref.invalidate(jobReviewProvider(jobId));
              ref.invalidate(jobAssignmentsProvider(jobId));
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: job.when(
        loading: () => Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: const LoadingSkeleton(lines: 6),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.lg),
            child: ErrorState(
              title: l10n.error,
              body: l10n.commonLoadFailed,
              retryLabel: l10n.retryAction,
              onRetry: () => ref.invalidate(cleanJobProvider(jobId)),
            ),
          ),
        ),
        data: (value) => _JobDetailBody(job: value),
      ),
    );
  }
}

class _JobDetailBody extends ConsumerStatefulWidget {
  const _JobDetailBody({required this.job});

  final CleanJob job;

  @override
  ConsumerState<_JobDetailBody> createState() => _JobDetailBodyState();
}

class _JobDetailBodyState extends ConsumerState<_JobDetailBody> {
  bool _busy = false;

  CleanJob get job => widget.job;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final review = ref.watch(jobReviewProvider(job.id));
    final assignments = ref.watch(jobAssignmentsProvider(job.id));
    return ListView(
      padding: EdgeInsetsDirectional.all(context.spacing.lg),
      children: [
        SectionHeader(
          title: job.reference,
          titleDirection: TextDirection.ltr,
          subtitle: job.customerName,
        ),
        JobPanel(
          title: l10n.jobsSummary,
          icon: Icons.assignment_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: context.spacing.sm,
                runSpacing: context.spacing.sm,
                children: [
                  StatusChip(
                    label: jobStatusLabel(l10n, job.status),
                    tone: jobStatusTone(job.status),
                  ),
                  if (job.reviewStatus.isNotEmpty)
                    StatusChip(
                      label: '${l10n.jobsReviewStatus}: '
                          '${jobStatusLabel(l10n, job.reviewStatus)}',
                      tone: StatusTone.neutral,
                      icon: Icons.rate_review_outlined,
                    ),
                  if (job.publicationStatus.isNotEmpty)
                    StatusChip(
                      label: '${l10n.jobsPublicationStatus}: '
                          '${jobStatusLabel(l10n, job.publicationStatus)}',
                      tone: StatusTone.info,
                      icon: Icons.public_outlined,
                    ),
                ],
              ),
              SizedBox(height: context.spacing.md),
              JobKeyValue(
                label: l10n.customerName,
                value: job.customerName,
              ),
              JobKeyValue(
                label: l10n.customerPhone,
                value: job.customerPhone ?? l10n.commonNotAvailable,
                valueDirection: TextDirection.ltr,
              ),
              JobKeyValue(
                label: l10n.customerEmail,
                value: job.customerEmail ?? l10n.commonNotAvailable,
                valueDirection: TextDirection.ltr,
              ),
              JobKeyValue(
                label: l10n.vehicle,
                value: '${job.vehicleMake} ${job.vehicleModel}'.trim(),
              ),
              JobKeyValue(
                label: l10n.vehicleVin,
                value: job.vehicleVin ?? l10n.commonNotAvailable,
                valueDirection: TextDirection.ltr,
              ),
              JobKeyValue(
                label: l10n.vehiclePlate,
                value: job.vehiclePlate ?? l10n.commonNotAvailable,
                valueDirection: TextDirection.ltr,
              ),
              JobKeyValue(
                label: l10n.jobsFieldOdometer,
                value: job.odometerValue == null
                    ? l10n.commonNotAvailable
                    : '${formatNumber(context, job.odometerValue!)} '
                          '${job.odometerUnit ?? ''}',
              ),
              JobKeyValue(
                label: l10n.jobsFieldTransmission,
                value: job.transmission ?? l10n.commonNotAvailable,
              ),
              JobKeyValue(
                label: l10n.jobsFieldFuelType,
                value: job.fuelType ?? l10n.commonNotAvailable,
              ),
              JobKeyValue(
                label: l10n.template,
                value:
                    '${localizedText(context, en: job.templateNameEn, ar: job.templateNameAr)}'
                    ' v${job.templateVersionNo ?? '-'}',
              ),
              JobKeyValue(
                label: l10n.jobsAssignedTechnician,
                value: job.assignedTechnicianName ?? l10n.unassigned,
              ),
              JobKeyValue(
                label: l10n.scheduledAt,
                value: formatInstant(context, job.scheduledAt),
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
              if (job.cancelReason != null)
                JobKeyValue(
                  label: l10n.jobsCancelReason,
                  value: job.cancelReason!,
                ),
            ],
          ),
        ),
        SizedBox(height: context.spacing.md),
        Wrap(
          spacing: context.spacing.sm,
          runSpacing: context.spacing.sm,
          children: [
            AppButton(
              label: l10n.jobsApprove,
              onPressed: _busy ? null : () => _open(ApproveIssuePage(jobId: job.id)),
              icon: Icons.verified_outlined,
              variant: AppButtonVariant.tonal,
            ),
            AppButton(
              label: l10n.jobsPublishChecklist,
              onPressed: _busy
                  ? null
                  : () => _open(PublishChecklistPage(jobId: job.id)),
              icon: Icons.playlist_add_check_outlined,
              variant: AppButtonVariant.tonal,
            ),
            AppButton(
              label: l10n.publicLink,
              onPressed: _busy ? null : () => _open(PublicLinkPage(jobId: job.id)),
              icon: Icons.link,
              variant: AppButtonVariant.tonal,
            ),
            AppButton(
              label: l10n.jobsDocumentsTitle,
              onPressed: _busy ? null : () => _open(DocumentsPage(jobId: job.id)),
              icon: Icons.description_outlined,
              variant: AppButtonVariant.tonal,
            ),
            if (job.status != 'CANCELLED' && job.status != 'PUBLISHED')
              AppButton(
                label: job.assignedTechnicianId == null
                    ? l10n.assign
                    : l10n.reassign,
                onPressed: _busy ? null : _assign,
                icon: Icons.person_add_alt_1_outlined,
                variant: AppButtonVariant.text,
              ),
            if (job.status != 'CANCELLED' && job.status != 'PUBLISHED')
              AppButton(
                label: l10n.cancelJob,
                onPressed: _busy ? null : _cancel,
                icon: Icons.cancel_outlined,
                variant: AppButtonVariant.text,
              ),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        SectionHeader(title: l10n.jobsReviewTitle),
        review.when(
          loading: () => const LoadingSkeleton(lines: 3),
          error: (error, _) =>
              Text(l10n.commonLoadFailed, style: context.texts.bodySmall),
          data: (value) => _reviewPanel(context, value),
        ),
        SizedBox(height: context.spacing.lg),
        SectionHeader(title: l10n.jobsAssignmentsTitle),
        assignments.when(
          loading: () => const LoadingSkeleton(lines: 2),
          error: (error, _) =>
              Text(l10n.commonLoadFailed, style: context.texts.bodySmall),
          data: (items) {
            if (items.isEmpty) {
              return Text(l10n.jobsAssignmentsEmpty);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in items) ...[
                  JobPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        JobKeyValue(
                          label: l10n.jobsAssignedTechnician,
                          value: item.technicianId,
                        ),
                        JobKeyValue(
                          label: l10n.assignTechnicianTitle,
                          value: item.assignedBy ?? l10n.commonNotAvailable,
                        ),
                        JobKeyValue(
                          label: l10n.scheduledAt,
                          value: formatInstant(context, item.assignedAt),
                        ),
                        if (item.unassignedAt != null)
                          JobKeyValue(
                            label: l10n.jobsAssignedTechnician,
                            value: formatInstant(
                              context,
                              item.unassignedAt,
                            ),
                          ),
                        if (item.reason != null)
                          JobKeyValue(
                            label: l10n.reason,
                            value: item.reason!,
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.spacing.sm),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _reviewPanel(BuildContext context, JobReview review) {
    final l10n = AppLocalizations.of(context);
    return JobPanel(
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
              _finding(context, finding),
        ],
      ),
    );
  }

  Widget _finding(BuildContext context, ReviewFinding finding) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: context.spacing.sm),
      child: AppCard(
        variant: AppCardVariant.flat,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizedText(
                          context,
                          en: finding.labelEn,
                          ar: finding.labelAr,
                        ),
                        style: context.texts.titleSmall,
                      ),
                      SizedBox(height: context.spacing.xs),
                      Text(
                        finding.stableCode,
                        textDirection: TextDirection.ltr,
                        style: context.texts.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(
                  label: finding.resultCode ?? l10n.commonNotAvailable,
                  tone: _resultTone(finding.resultCode),
                ),
              ],
            ),
            SizedBox(height: context.spacing.sm),
            Wrap(
              spacing: context.spacing.sm,
              runSpacing: context.spacing.sm,
              children: [
                StatusChip(
                  label:
                      '${l10n.jobsEvidencePhotos}: '
                      '${formatNumber(context, finding.evidencePhotos.length)}',
                  tone: StatusTone.neutral,
                  icon: Icons.photo_camera_outlined,
                ),
                StatusChip(
                  label:
                      '${l10n.jobsEvidenceVideos}: '
                      '${formatNumber(context, finding.evidenceVideos.length)}',
                  tone: StatusTone.neutral,
                  icon: Icons.videocam_outlined,
                ),
                StatusChip(
                  label: finding.signaturePresent
                      ? l10n.jobsSignaturePresent
                      : l10n.jobsSignatureMissing,
                  tone: finding.signaturePresent
                      ? StatusTone.success
                      : StatusTone.warning,
                  icon: finding.signaturePresent
                      ? Icons.draw_outlined
                      : Icons.draw_outlined,
                ),
              ],
            ),
            if (finding.issueValues.isNotEmpty) ...[
              SizedBox(height: context.spacing.sm),
              for (final entry in finding.issueValues.entries)
                JobKeyValue(
                  label: entry.key,
                  value: entry.value?.toString() ?? '',
                ),
            ],
            if (finding.completedAt != null)
              JobKeyValue(
                label: l10n.jobsCompletedAt,
                value: formatInstant(context, finding.completedAt),
              ),
          ],
        ),
      ),
    );
  }

  StatusTone _resultTone(String? resultCode) => switch (resultCode) {
    'NO_ISSUE_OBSERVED' => StatusTone.success,
    'DEFECT_FOUND' => StatusTone.danger,
    'ATTENTION_RECOMMENDED' => StatusTone.warning,
    _ => StatusTone.neutral,
  };

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => page),
    );
    if (mounted) {
      ref.invalidate(cleanJobProvider(job.id));
      ref.invalidate(jobReviewProvider(job.id));
      ref.invalidate(jobAssignmentsProvider(job.id));
    }
  }

  Future<void> _assign() async {
    final l10n = AppLocalizations.of(context);
    final staff = await ref.read(staffProvider.future);
    if (!mounted) {
      return;
    }
    final technicians = staff
        .where((member) => member.role == 'TECHNICIAN')
        .toList(growable: false);
    if (technicians.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.noTechnicians)));
      return;
    }
    var selected = technicians.first.userId;
    final reason = TextEditingController();
    final confirmed = await showAppBottomSheet<bool>(
      context,
      child: StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(title: l10n.assignTechnicianTitle),
              for (final technician in technicians)
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    bottom: context.spacing.xs,
                  ),
                  child: AppSelectableText(
                    label: technician.displayName,
                    selected: selected == technician.userId,
                    onTap: () =>
                        setSheetState(() => selected = technician.userId),
                  ),
                ),
              SizedBox(height: context.spacing.sm),
              AppTextField(
                controller: reason,
                label: l10n.jobsAssignmentReason,
              ),
              SizedBox(height: context.spacing.lg),
              AppButton(
                label: l10n.assign,
                onPressed: () => Navigator.of(context).pop(true),
                icon: Icons.person_add_alt_1_outlined,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
    final reasonText = reason.text.trim();
    reason.dispose();
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(adminApiProvider)
          .assignCleanJob(
            job.id,
            selected,
            reasonText.isEmpty ? null : reasonText,
            version: job.version,
          );
      ref.invalidate(cleanJobProvider(job.id));
      ref.invalidate(jobAssignmentsProvider(job.id));
      ref.invalidate(cleanJobCountsProvider);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.commonActionFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _cancel() async {
    final l10n = AppLocalizations.of(context);
    final reason = await showJobReasonSheet(
      context,
      title: l10n.cancelJob,
      label: l10n.jobsCancelReason,
      confirmLabel: l10n.cancelJob,
    );
    if (reason == null || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(adminApiProvider)
          .cancelCleanJob(job.id, reason, version: job.version);
      ref.invalidate(cleanJobProvider(job.id));
      ref.invalidate(cleanJobCountsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.jobCancelled)));
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.commonActionFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

