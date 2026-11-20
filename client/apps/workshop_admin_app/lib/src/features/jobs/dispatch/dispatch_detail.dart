import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/features/jobs/detail/job_detail_assignment.dart';
import 'package:workshop_admin_app/src/features/jobs/detail/job_detail_customer_vehicle.dart';
import 'package:workshop_admin_app/src/features/jobs/detail/job_detail_inspection.dart';
import 'package:workshop_admin_app/src/features/jobs/detail/job_detail_review_publication.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_action_buttons.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_action_set.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_pills.dart';
import 'package:workshop_admin_app/src/features/jobs/queue/jobs_queue_actions.dart';
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
    final t = UiStrings.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final jobAsync = ref.watch(cleanJobProvider(widget.jobId));
    final job = jobAsync.value;
    final actions = job == null ? null : effectiveDetailActions(job);
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
                        semanticLabel: t(WorkshopAdminKeys.commonBack),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          job?.reference ??
                              t(WorkshopAdminKeys.jobsDetailTitle),
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
                    title: t(WorkshopAdminKeys.error),
                    body: t(WorkshopAdminKeys.commonLoadFailed),
                    retryLabel: t(WorkshopAdminKeys.retryAction),
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
                          if (actions != null && actions.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            JobActionButtons(
                              actions: actions,
                              consentGranted: value.consentGranted,
                              onGrantConsent: () =>
                                  queueActions.grantConsent(value),
                              onAction: (action) =>
                                  queueActions.onServerAction(value, action),
                            ),
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
    final t = UiStrings.of(context);
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
              job.assignedTechnicianName ?? t(WorkshopAdminKeys.unassigned),
              style: ws.meta.copyWith(color: ws.muted),
            ),
          ],
        ),
      ],
    );
  }

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
