import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/approve_job_page.dart';
import 'package:workshop_admin_app/src/features/jobs/job_documents_page.dart';
import 'package:workshop_admin_app/src/features/jobs/job_presentation.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/features/jobs/public_link_page.dart';
import 'package:workshop_admin_app/src/features/jobs/publish_checklist_page.dart';
import 'package:workshop_admin_app/src/features/reports/report_page.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// Clean job detail: one page title, a status row, a summary card and four
/// grouped sections, with a sticky action bar for the real lifecycle actions.
///
/// All API calls, provider invalidations and sub-page routes are the same as
/// before; only the presentation changed.
class JobDetailPage extends ConsumerStatefulWidget {
  const JobDetailPage({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends ConsumerState<JobDetailPage> {
  bool _busy = false;

  String get _jobId => widget.jobId;

  void _refresh() {
    ref.invalidate(cleanJobProvider(_jobId));
    ref.invalidate(jobReviewProvider(_jobId));
    ref.invalidate(jobAssignmentsProvider(_jobId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final jobAsync = ref.watch(cleanJobProvider(_jobId));
    final job = jobAsync.value;
    final canMutate =
        job != null &&
        job.status != 'CANCELLED' &&
        job.status != 'PUBLISHED' &&
        job.status != 'FINALIZED';
    return Scaffold(
      backgroundColor: ws.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            JobPageTopBar(
              title: l10n.jobsDetailTitle,
              breadcrumbs: [
                l10n.jobsTab,
                if (job != null) job.reference else l10n.jobsDetailTitle,
              ],
              actions: [
                WorkshopIconButton(
                  key: const Key('job-detail-refresh'),
                  icon: Icons.refresh,
                  semanticLabel: l10n.refresh,
                  onPressed: _refresh,
                ),
                _MoreMenuButton(
                  iconOnly: true,
                  onAssign: canMutate && !_busy ? _assign : null,
                  onCancel: canMutate && !_busy ? _cancel : null,
                  onRefresh: _refresh,
                ),
              ],
            ),
            Expanded(
              child: jobAsync.when(
                loading: () => ListView(
                  padding: ws.pagePaddingOf(context),
                  children: [
                    const WorkshopSkeleton(card: true, lines: 6),
                    SizedBox(height: ws.cardPadding),
                    const WorkshopSkeleton(card: true, lines: 4),
                  ],
                ),
                error: (error, _) => SingleChildScrollView(
                  padding: ws.pagePaddingOf(context),
                  child: WorkshopErrorState(
                    title: l10n.error,
                    body: l10n.commonLoadFailed,
                    retryLabel: l10n.retryAction,
                    onRetry: () => ref.invalidate(cleanJobProvider(_jobId)),
                  ),
                ),
                data: (value) => _body(context, value),
              ),
            ),
            if (job != null)
              _ActionBar(
                job: job,
                busy: _busy,
                canMutate: canMutate,
                onOpen: _open,
                onAssign: _assign,
                onCancel: _cancel,
                onRefresh: _refresh,
              ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, CleanJob job) {
    final ws = context.ws;
    final spacing = context.spacing;
    final vehicle = '${job.vehicleMake} ${job.vehicleModel}'.trim();
    return SelectionArea(
      child: ListView(
        padding: ws.pagePaddingOf(context),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  WorkshopPageHeader(
                    title: vehicle.isEmpty ? job.customerName : vehicle,
                    subtitle: '${job.reference} · ${job.customerName}',
                  ),
                  SizedBox(height: spacing.md),
                  _StatusRow(job: job),
                  SizedBox(height: spacing.lg),
                  SizedBox(height: spacing.xl),
                  _SummaryCard(job: job),
                  SizedBox(height: spacing.xxl),
                  _CustomerVehicleSection(job: job),
                  SizedBox(height: spacing.xxl),
                  _InspectionSection(job: job),
                  SizedBox(height: spacing.xxl),
                  _AssignmentSection(jobId: job.id),
                  SizedBox(height: spacing.xxl),
                  _ReviewPublicationSection(job: job),
                  // Breathing room so the sticky action bar never sits flush
                  // against the last card at the end of the scroll.
                  SizedBox(height: spacing.xxxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context)
        .push<void>(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) {
      _refresh();
    }
  }

  Future<void> _assign() async {
    final l10n = AppLocalizations.of(context);
    final job = ref.read(cleanJobProvider(_jobId)).value;
    if (job == null) {
      return;
    }
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
    final job = ref.read(cleanJobProvider(_jobId)).value;
    if (job == null) {
      return;
    }
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

String? _reviewStatusLabel(AppLocalizations l10n, String code) =>
    switch (code) {
      'PENDING_REVIEW' => l10n.jobsStatusPendingReview,
      'APPROVED' => l10n.jobsStatusApproved,
      'REJECTED' => l10n.jobsStatusRejected,
      _ => null,
    };

String _publicationStatusLabel(AppLocalizations l10n, String code) =>
    switch (code) {
      'ACTIVE' => l10n.jobsStatusPublished,
      'REVOKED' => l10n.linkRevoked,
      _ => l10n.notPublished,
    };

WorkshopStatusTone _publicationStatusTone(String code) => switch (code) {
  'ACTIVE' => WorkshopStatusTone.success,
  'REVOKED' => WorkshopStatusTone.danger,
  _ => WorkshopStatusTone.neutral,
};

String _safetyCapLabel(AppLocalizations l10n, CleanJob job) =>
    job.safetyCapApplied
    ? (job.safetyCapReason ?? l10n.jobsSafetyCapApplied)
    : l10n.jobsSafetyCapNotApplied;

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.job});

  final CleanJob job;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final review = _reviewStatusLabel(l10n, job.reviewStatus);
    final publication = _publicationStatusLabel(l10n, job.publicationStatus);
    return Wrap(
      spacing: spacing.sm,
      runSpacing: spacing.sm,
      children: [
        JobStatusBadge(status: job.status),
        if (review != null && job.reviewStatus != job.status)
          WorkshopStatusBadge(
            label: '${l10n.jobsReviewTitle}: $review',
            tone: workshopJobTone(job.reviewStatus),
            icon: Icons.rate_review_outlined,
          ),
        WorkshopStatusBadge(
          label: publication,
          tone: _publicationStatusTone(job.publicationStatus),
          icon: Icons.public_outlined,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.job});

  final CleanJob job;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final vehicle = '${job.vehicleMake} ${job.vehicleModel}'.trim();
    final schedule = formatInstant(context, job.scheduledAt);
    return WorkshopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          WorkshopSectionHeader(title: l10n.jobsSummary),
          SizedBox(height: spacing.lg),
          JobFactGrid(
            facts: [
              JobFact(label: l10n.customerName, value: job.customerName),
              JobFact(
                label: l10n.customerPhone,
                value: job.customerPhone ?? l10n.commonNotAvailable,
                valueDirection: TextDirection.ltr,
              ),
              JobFact(
                label: l10n.vehicle,
                value: vehicle.isEmpty ? l10n.commonNotAvailable : vehicle,
              ),
              JobFact(
                label: l10n.scheduledAt,
                value: schedule.isEmpty ? l10n.commonNotAvailable : schedule,
                valueDirection: TextDirection.ltr,
              ),
              JobFact(
                label: l10n.jobsAssignedTechnician,
                value: job.assignedTechnicianName ?? l10n.unassigned,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerVehicleSection extends StatelessWidget {
  const _CustomerVehicleSection({required this.job});

  final CleanJob job;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final odometer = job.odometerValue == null
        ? l10n.commonNotAvailable
        : '${formatNumber(context, job.odometerValue!)} '
                  '${job.odometerUnit ?? ''}'
              .trim();
    final facts = <Widget>[
      JobFact(
        label: l10n.customerEmail,
        value: job.customerEmail ?? l10n.commonNotAvailable,
        valueDirection: TextDirection.ltr,
      ),
      JobFact(
        label: l10n.vehiclePlate,
        value: job.vehiclePlate ?? l10n.commonNotAvailable,
        valueDirection: TextDirection.ltr,
      ),
      JobFact(
        label: l10n.vehicleVin,
        value: job.vehicleVin ?? l10n.commonNotAvailable,
        valueDirection: TextDirection.ltr,
      ),
      JobFact(
        label: l10n.jobsFieldOdometer,
        value: odometer,
        valueDirection: TextDirection.ltr,
      ),
      JobFact(
        label: l10n.jobsFieldTransmission,
        value: job.transmission ?? l10n.commonNotAvailable,
      ),
      JobFact(
        label: l10n.jobsFieldFuelType,
        value: job.fuelType ?? l10n.commonNotAvailable,
      ),
      if ((job.preferredLanguage ?? '').isNotEmpty)
        JobFact(
          label: l10n.jobsFieldPreferredLanguage,
          value: job.preferredLanguage == 'ar'
              ? l10n.languageArabic
              : l10n.languageEnglish,
        ),
      if (job.cancelReason != null)
        JobFact(label: l10n.jobsCancelReason, value: job.cancelReason!),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopSectionHeader(title: l10n.jobDetailCustomerVehicle),
        SizedBox(height: spacing.sm),
        WorkshopCard(child: JobFactGrid(facts: facts)),
      ],
    );
  }
}

class _InspectionSection extends ConsumerWidget {
  const _InspectionSection({required this.job});

  final CleanJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final review = ref.watch(jobReviewProvider(job.id));
    final template = localizedText(
      context,
      en: job.templateNameEn,
      ar: job.templateNameAr,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopSectionHeader(title: l10n.jobDetailInspection),
        SizedBox(height: spacing.sm),
        WorkshopCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              JobFactGrid(
                facts: [
                  JobFact(
                    label: l10n.template,
                    value: template.isEmpty
                        ? l10n.commonNotAvailable
                        : '$template v${job.templateVersionNo ?? '-'}',
                  ),
                  JobFact(
                    label: l10n.jobsScore,
                    value: formatScore(context, job.score),
                  ),
                  JobFact(
                    label: l10n.jobsGrade,
                    value: job.gradeCode ?? l10n.commonNotAvailable,
                  ),
                  JobFact(
                    label: l10n.safetyCap,
                    value: _safetyCapLabel(l10n, job),
                  ),
                ],
              ),
              SizedBox(height: spacing.lg),
              review.when(
                loading: () => const WorkshopSkeleton(lines: 3),
                error: (error, _) =>
                    WorkshopInlineNote(text: l10n.commonLoadFailed),
                data: (value) => _Findings(review: value),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Findings extends StatelessWidget {
  const _Findings({required this.review});

  final JobReview review;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    if (review.findings.isEmpty) {
      return Text(
        l10n.jobsNoFindings,
        style: ws.meta.copyWith(color: ws.muted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < review.findings.length; index++) ...[
          if (index > 0) const WorkshopDivider(),
          _FindingRow(finding: review.findings[index]),
        ],
      ],
    );
  }
}

class _FindingRow extends StatelessWidget {
  const _FindingRow({required this.finding});

  final ReviewFinding finding;

  WorkshopStatusTone _tone() => switch (finding.resultCode) {
    'NO_ISSUE_OBSERVED' => WorkshopStatusTone.success,
    'DEFECT_FOUND' => WorkshopStatusTone.danger,
    'ATTENTION_RECOMMENDED' => WorkshopStatusTone.warning,
    _ => WorkshopStatusTone.neutral,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      localizedText(
                        context,
                        en: finding.labelEn,
                        ar: finding.labelAr,
                      ),
                      maxLines: 2,
                      style: ws.bodyStrong.copyWith(color: ws.ink),
                    ),
                    SizedBox(height: spacing.xxs),
                    Text(
                      finding.stableCode,
                      textDirection: TextDirection.ltr,
                      style: ws.meta.copyWith(color: ws.muted),
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing.sm),
              Flexible(
                flex: 2,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: WorkshopStatusBadge(
                    label: finding.resultCode ?? l10n.commonNotAvailable,
                    tone: _tone(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sm),
          Wrap(
            spacing: spacing.md,
            runSpacing: spacing.xs,
            children: [
              JobMetaLine(
                icon: Icons.photo_camera_outlined,
                text:
                    '${l10n.jobsEvidencePhotos}: '
                    '${formatNumber(context, finding.evidencePhotos.length)}',
              ),
              JobMetaLine(
                icon: Icons.videocam_outlined,
                text:
                    '${l10n.jobsEvidenceVideos}: '
                    '${formatNumber(context, finding.evidenceVideos.length)}',
              ),
              JobMetaLine(
                icon: Icons.draw_outlined,
                text: finding.signaturePresent
                    ? l10n.jobsSignaturePresent
                    : l10n.jobsSignatureMissing,
              ),
              if (finding.completedAt != null)
                JobMetaLine(
                  icon: Icons.schedule,
                  text: formatInstant(context, finding.completedAt),
                ),
            ],
          ),
          if (finding.issueValues.isNotEmpty) ...[
            SizedBox(height: spacing.sm),
            Wrap(
              spacing: spacing.lg,
              runSpacing: spacing.sm,
              children: [
                for (final entry in finding.issueValues.entries)
                  JobFact(
                    label: entry.key,
                    value: entry.value?.toString() ?? '',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AssignmentSection extends ConsumerWidget {
  const _AssignmentSection({required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final assignments = ref.watch(jobAssignmentsProvider(jobId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopSectionHeader(title: l10n.jobDetailAssignment),
        SizedBox(height: spacing.sm),
        WorkshopCard(
          child: assignments.when(
            loading: () => const WorkshopSkeleton(lines: 2),
            error: (error, _) =>
                WorkshopInlineNote(text: l10n.commonLoadFailed),
            data: (items) {
              if (items.isEmpty) {
                return Text(
                  l10n.jobsAssignmentsEmpty,
                  style: ws.meta.copyWith(color: ws.muted),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    if (index > 0) const WorkshopDivider(),
                    _AssignmentRow(assignment: items[index]),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AssignmentRow extends StatelessWidget {
  const _AssignmentRow({required this.assignment});

  final JobAssignment assignment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: spacing.md),
      child: JobFactGrid(
        facts: [
          JobFact(
            label: l10n.jobsAssignedTechnician,
            value: assignment.technicianId,
            valueDirection: TextDirection.ltr,
          ),
          JobFact(
            label: l10n.assignTechnicianTitle,
            value: assignment.assignedBy ?? l10n.commonNotAvailable,
          ),
          JobFact(
            label: l10n.scheduledAt,
            value: formatInstant(context, assignment.assignedAt).isEmpty
                ? l10n.commonNotAvailable
                : formatInstant(context, assignment.assignedAt),
          ),
          if (assignment.unassignedAt != null)
            JobFact(
              label: l10n.unassigned,
              value: formatInstant(context, assignment.unassignedAt),
            ),
          if (assignment.reason != null)
            JobFact(label: l10n.reason, value: assignment.reason!),
        ],
      ),
    );
  }
}

class _ReviewPublicationSection extends ConsumerWidget {
  const _ReviewPublicationSection({required this.job});

  final CleanJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final review = ref.watch(jobReviewProvider(job.id));
    final reviewLabel = _reviewStatusLabel(l10n, job.reviewStatus);
    final publicationLabel = _publicationStatusLabel(
      l10n,
      job.publicationStatus,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopSectionHeader(title: l10n.jobDetailReviewPublication),
        SizedBox(height: spacing.sm),
        WorkshopCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              JobFactGrid(
                facts: [
                  JobFact(
                    label: l10n.jobsReviewStatus,
                    value: reviewLabel ?? l10n.commonNotAvailable,
                  ),
                  JobFact(
                    label: l10n.jobsPublicationStatus,
                    value: publicationLabel,
                  ),
                  JobFact(
                    label: l10n.jobsAssignedTechnician,
                    value: job.assignedTechnicianName ?? l10n.unassigned,
                  ),
                ],
              ),
              SizedBox(height: spacing.lg),
              review.when(
                loading: () => const WorkshopSkeleton(lines: 2),
                error: (error, _) =>
                    WorkshopInlineNote(text: l10n.commonLoadFailed),
                data: (value) => JobFactGrid(
                  facts: [
                    JobFact(
                      label: l10n.jobsItemsAssessed,
                      value:
                          '${formatNumber(context, value.itemsAssessed)} / '
                          '${formatNumber(context, value.itemsTotal)}',
                    ),
                    JobFact(
                      label: l10n.jobsScorePreview,
                      value: formatScore(context, value.scorePreview),
                    ),
                    JobFact(
                      label: l10n.jobsGradePreview,
                      value: value.gradePreview ?? l10n.commonNotAvailable,
                    ),
                    if (value.safetyCapPreview != null)
                      JobFact(
                        label: l10n.jobsSafetyCapPreview,
                        value: value.safetyCapPreview!,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sticky bottom action bar: contextual primary plus secondary routes and an
/// overflow that keeps the destructive action separated.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.job,
    required this.busy,
    required this.canMutate,
    required this.onOpen,
    required this.onAssign,
    required this.onCancel,
    required this.onRefresh,
  });

  final CleanJob job;
  final bool busy;
  final bool canMutate;
  final ValueChanged<Widget> onOpen;
  final VoidCallback onAssign;
  final VoidCallback onCancel;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final gutter = ws.pageGutter(MediaQuery.sizeOf(context).width);
    final (
      String primaryLabel,
      IconData primaryIcon,
      Widget primaryPage,
    ) = switch (job.status) {
      'PENDING_REVIEW' => (
        l10n.jobsApprove,
        Icons.verified_outlined,
        ApproveIssuePage(jobId: job.id),
      ),
      'PUBLISHED' || 'FINALIZED' => (
        l10n.report,
        Icons.description_outlined,
        ReportPage(jobId: job.id),
      ),
      _ => (
        l10n.jobsPublishChecklist,
        Icons.playlist_add_check_outlined,
        PublishChecklistPage(jobId: job.id),
      ),
    };
    final reassignLabel = job.assignedTechnicianId == null
        ? l10n.assign
        : l10n.reassign;
    final enabled = !busy;
    return Container(
      decoration: BoxDecoration(
        color: ws.surface,
        border: BorderDirectional(top: BorderSide(color: ws.border)),
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: gutter,
        vertical: spacing.md,
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 680;
                final primary = WorkshopButton(
                  label: primaryLabel,
                  icon: primaryIcon,
                  isLoading: busy,
                  expand: compact,
                  onPressed: enabled ? () => onOpen(primaryPage) : null,
                );
                final secondary = <Widget>[
                  WorkshopButton(
                    label: l10n.publicLink,
                    icon: Icons.link,
                    variant: WorkshopButtonVariant.secondary,
                    onPressed: enabled
                        ? () => onOpen(PublicLinkPage(jobId: job.id))
                        : null,
                  ),
                  WorkshopButton(
                    label: l10n.jobsDocumentsTitle,
                    icon: Icons.description_outlined,
                    variant: WorkshopButtonVariant.secondary,
                    onPressed: enabled
                        ? () => onOpen(DocumentsPage(jobId: job.id))
                        : null,
                  ),
                  if (canMutate)
                    WorkshopButton(
                      label: reassignLabel,
                      icon: Icons.person_add_alt_1_outlined,
                      variant: WorkshopButtonVariant.ghost,
                      onPressed: enabled ? onAssign : null,
                    ),
                  _MoreMenuButton(
                    onCancel: canMutate && enabled ? onCancel : null,
                    onRefresh: onRefresh,
                  ),
                ];
                if (compact) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: primary),
                      SizedBox(width: spacing.sm),
                      _MoreMenuButton(
                        onPublicLink: enabled
                            ? () => onOpen(PublicLinkPage(jobId: job.id))
                            : null,
                        onDocuments: enabled
                            ? () => onOpen(DocumentsPage(jobId: job.id))
                            : null,
                        onAssign: canMutate && enabled ? onAssign : null,
                        onCancel: canMutate && enabled ? onCancel : null,
                        onRefresh: onRefresh,
                      ),
                    ],
                  );
                }
                return Wrap(
                  spacing: spacing.sm,
                  runSpacing: spacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [primary, ...secondary],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Token-styled overflow trigger (icon-only in the top bar).
class _MoreMenuButton extends StatelessWidget {
  const _MoreMenuButton({
    required this.onCancel,
    required this.onRefresh,
    this.onAssign,
    this.onPublicLink,
    this.onDocuments,
    this.iconOnly = false,
  });

  final VoidCallback? onAssign;
  final VoidCallback? onPublicLink;
  final VoidCallback? onDocuments;
  final VoidCallback? onCancel;
  final VoidCallback onRefresh;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final radius = BorderRadius.circular(ws.controlRadius);
    final trigger = Container(
      constraints: BoxConstraints(minHeight: ws.touchTarget),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: iconOnly ? 0 : spacing.md,
      ),
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: radius,
        border: Border.all(color: ws.border),
      ),
      child: iconOnly
          ? SizedBox.square(
              dimension: ws.touchTarget,
              child: Icon(Icons.more_horiz, size: 20, color: ws.ink),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.more_horiz, size: 18, color: ws.ink),
                SizedBox(width: spacing.xs),
                Text(
                  l10n.jobDetailMoreActions,
                  style: ws.bodyStrong.copyWith(color: ws.ink),
                ),
              ],
            ),
    );
    return PopupMenuButton<String>(
      tooltip: l10n.jobDetailMoreActions,
      position: PopupMenuPosition.under,
      color: ws.surface,
      onSelected: (value) {
        if (value == 'assign') {
          onAssign?.call();
        } else if (value == 'publicLink') {
          onPublicLink?.call();
        } else if (value == 'documents') {
          onDocuments?.call();
        } else if (value == 'cancel') {
          onCancel?.call();
        } else {
          onRefresh();
        }
      },
      itemBuilder: (context) => [
        if (onPublicLink != null)
          PopupMenuItem<String>(
            value: 'publicLink',
            child: Row(
              children: [
                Icon(Icons.link, size: 18, color: ws.ink),
                SizedBox(width: spacing.sm),
                Text(l10n.publicLink, style: ws.body.copyWith(color: ws.ink)),
              ],
            ),
          ),
        if (onDocuments != null)
          PopupMenuItem<String>(
            value: 'documents',
            child: Row(
              children: [
                Icon(Icons.description_outlined, size: 18, color: ws.ink),
                SizedBox(width: spacing.sm),
                Text(
                  l10n.jobsDocumentsTitle,
                  style: ws.body.copyWith(color: ws.ink),
                ),
              ],
            ),
          ),
        if (onAssign != null)
          PopupMenuItem<String>(
            value: 'assign',
            child: Row(
              children: [
                Icon(Icons.person_add_alt_1_outlined, size: 18, color: ws.ink),
                SizedBox(width: spacing.sm),
                Text(l10n.reassign, style: ws.body.copyWith(color: ws.ink)),
              ],
            ),
          ),
        if (onCancel != null)
          PopupMenuItem<String>(
            value: 'cancel',
            child: Row(
              children: [
                Icon(Icons.cancel_outlined, size: 18, color: ws.danger),
                SizedBox(width: spacing.sm),
                Text(l10n.cancelJob, style: ws.body.copyWith(color: ws.danger)),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'refresh',
          child: Row(
            children: [
              Icon(Icons.refresh, size: 18, color: ws.ink),
              SizedBox(width: spacing.sm),
              Text(l10n.refresh, style: ws.body.copyWith(color: ws.ink)),
            ],
          ),
        ),
      ],
      child: Semantics(
        button: true,
        label: l10n.jobDetailMoreActions,
        child: trigger,
      ),
    );
  }
}
