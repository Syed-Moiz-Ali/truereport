import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/jobs/detail/job_detail_assignment.dart';
import 'package:workshop_admin_app/src/features/jobs/detail/job_detail_customer_vehicle.dart';
import 'package:workshop_admin_app/src/features/jobs/detail/job_detail_inspection.dart';
import 'package:workshop_admin_app/src/features/jobs/detail/job_detail_review_publication.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_pills.dart';
import 'package:workshop_admin_app/src/features/jobs/queue/jobs_queue_actions.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_actions.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// Job record: identity, lifecycle rail, content, one pill per allowed action.
///
/// The content regions are the existing `JobDetailBody` blocks; what changed is
/// the page: a document header, the stage rail as the spine, and actions as
/// pills next to the identity instead of a bottom bar. Actions still come from
/// `jobActionsFor` and run through [JobsQueueActions] (assign sheet, cancel
/// reason sheet, review, publish checklist, public link).
class DispatchJobDetail extends ConsumerStatefulWidget {
  const DispatchJobDetail({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<DispatchJobDetail> createState() => _DispatchJobDetailState();
}

class _DispatchJobDetailState extends ConsumerState<DispatchJobDetail> {
  String? _banner;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final jobAsync = ref.watch(cleanJobProvider(widget.jobId));
    final job = jobAsync.value;
    final actions = job == null
        ? null
        : jobActionsFor(status: job.status, consentGranted: job.consentGranted);
    final queueActions = JobsQueueActions(
      context: context,
      ref: ref,
      onRefresh: _refresh,
      onConflict: (message) => setState(() => _banner = message),
    );

    return Scaffold(
      backgroundColor: ws.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: ws.topBarHeight,
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: ws.pageGutter(width),
              ),
              decoration: BoxDecoration(
                color: ws.surface,
                border: BorderDirectional(bottom: BorderSide(color: ws.border)),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
                  child: Row(
                    children: [
                      WorkshopIconButton(
                        icon: Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_forward
                            : Icons.arrow_back,
                        semanticLabel: l10n.commonBack,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          job?.reference ?? l10n.jobsDetailTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ws.bodyStrong.copyWith(color: ws.ink),
                        ),
                      ),
                      if (job != null) JobStatusPill(status: job.status),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: jobAsync.when(
                loading: () =>
                    const Center(child: WorkshopSkeleton(lines: 8, card: true)),
                error: (error, _) => Center(
                  child: WorkshopErrorState(
                    title: l10n.error,
                    body: l10n.commonLoadFailed,
                    retryLabel: l10n.retryAction,
                    onRetry: () => _refresh(),
                  ),
                ),
                data: (value) => SingleChildScrollView(
                  padding: ws.pagePadding(width),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 12),
                          _identity(context, value),
                          const SizedBox(height: 18),
                          JobStageRail(status: value.status),
                          if (actions != null) ...[
                            const SizedBox(height: 14),
                            _actionPills(value, actions, queueActions),
                          ],
                          const SizedBox(height: 16),
                          _body(context, value),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _identity(BuildContext context, CleanJob job) {
    final ws = context.ws;
    final l10n = AppLocalizations.of(context);
    final vehicle = [
      job.vehicleMake,
      job.vehicleModel,
      if (job.vehicleYear != null) '${job.vehicleYear}',
    ].join(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          job.customerName,
          style: ws.pageTitle.copyWith(
            fontSize: MediaQuery.sizeOf(context).width < 520 ? 26 : 32,
            letterSpacing: -0.7,
            color: ws.ink,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(vehicle, style: ws.meta.copyWith(color: ws.muted)),
            if ((job.vehiclePlate ?? '').isNotEmpty)
              Text(job.vehiclePlate!, style: ws.meta.copyWith(color: ws.ink)),
            Text(
              job.assignedTechnicianName ?? l10n.unassigned,
              style: ws.meta.copyWith(color: ws.muted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionPills(
    CleanJob job,
    JobActions actions,
    JobsQueueActions queueActions,
  ) {
    final l10n = AppLocalizations.of(context);
    final pills = <Widget>[];
    // The record must never offer "open job": it would push itself again.
    if (actions.hasPrimary && actions.primary != JobPrimaryAction.openJob) {
      pills.add(
        JobPillButton(
          label: _primaryLabel(l10n, actions.primary),
          icon: _primaryIcon(actions.primary),
          onPressed: () => queueActions.onAction(job, actions.primary),
        ),
      );
    }
    if (actions.canAssign) {
      pills.add(
        JobPillButton(
          label: l10n.jobsAssignTechnician,
          icon: Icons.person_add_alt_1_outlined,
          variant: JobPillVariant.outline,
          onPressed: () => queueActions.assign(job),
        ),
      );
    }
    if (!job.consentGranted &&
        job.status != 'CANCELLED' &&
        job.status != 'PUBLISHED') {
      pills.add(
        JobPillButton(
          label: l10n.consentGranted,
          icon: Icons.verified_user_outlined,
          variant: JobPillVariant.outline,
          onPressed: () async {
            try {
              await ref
                  .read(adminApiProvider)
                  .updateJobConsent(job.id, consentGranted: true);
              _refresh();
            } catch (_) {
              if (mounted) {
                setState(() => _banner = l10n.error);
              }
            }
          },
        ),
      );
    }
    if (actions.canCancel) {
      pills.add(
        JobPillButton(
          label: l10n.cancelJob,
          variant: JobPillVariant.ghost,
          onPressed: () => queueActions.cancel(job),
        ),
      );
    }
    if (pills.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(spacing: 10, runSpacing: 10, children: pills);
  }

  String _primaryLabel(AppLocalizations l10n, JobPrimaryAction primary) =>
      switch (primary) {
        JobPrimaryAction.assign => l10n.jobsAssignTechnician,
        JobPrimaryAction.reviewApprove => l10n.jobsOpenReview,
        JobPrimaryAction.publishChecklist => l10n.jobsOpenPublishChecklist,
        JobPrimaryAction.publicLink => l10n.jobsViewPublicLink,
        _ => l10n.jobsOpenJob,
      };

  IconData _primaryIcon(JobPrimaryAction primary) => switch (primary) {
    JobPrimaryAction.assign => Icons.person_add_alt_1_outlined,
    JobPrimaryAction.reviewApprove => Icons.rate_review_outlined,
    JobPrimaryAction.publishChecklist => Icons.playlist_add_check,
    JobPrimaryAction.publicLink => Icons.link,
    _ => Icons.open_in_new,
  };

  Widget _body(BuildContext context, CleanJob job) {
    final ws = context.ws;
    final banner = _banner;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (banner != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ws.dangerSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(banner, style: ws.meta.copyWith(color: ws.danger)),
          ),
          const SizedBox(height: 14),
        ],
        LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 900;
            final left = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                JobDetailCustomerVehicle(job: job),
                const SizedBox(height: 16),
                JobDetailInspection(job: job),
              ],
            );
            final right = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                JobDetailAssignment(job: job),
                const SizedBox(height: 16),
                JobDetailReviewPublication(job: job),
              ],
            );
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [left, const SizedBox(height: 16), right],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: left),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: right),
              ],
            );
          },
        ),
      ],
    );
  }

  void _refresh() {
    setState(() => _banner = null);
    ref.invalidate(cleanJobProvider(widget.jobId));
    ref.invalidate(jobReviewProvider(widget.jobId));
    ref.invalidate(jobAssignmentsProvider(widget.jobId));
  }
}
