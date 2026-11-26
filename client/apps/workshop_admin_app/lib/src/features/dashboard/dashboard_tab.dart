import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_tokens.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_activity.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_composition.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_customers.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_decisions.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_flow.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_header.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_kpis.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_lifecycle.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_reports.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_staff.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_states.dart';
import 'package:workshop_admin_app/src/features/jobs/job_creation_wizard_page.dart';
import 'package:workshop_admin_app/src/features/jobs/job_detail_page.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// Overview — the workshop's command centre.
///
/// Job KPIs and the decision list are live job state; flow, staff, customers,
/// reports and activity come from the read-only `/workshop/dashboard` insights
/// endpoint, sharing one 7/14/30-day range.
class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({this.onOpenQueue, this.onOpenStaff, super.key});

  final VoidCallback? onOpenQueue;
  final VoidCallback? onOpenStaff;

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  static final String _pendingKey = cleanJobsKey(
    size: 5,
    status: 'PENDING_REVIEW',
  );

  int _days = 14;
  WorkshopDashboard? _lastInsights;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final ws = context.ws;

    final counts = ref.watch(cleanJobCountsProvider);
    final pending = ref.watch(cleanJobsProvider(_pendingKey));
    final statuses = ref.watch(statusesProvider('job')).value;
    final insights = ref.watch(workshopDashboardProvider(_days));
    final latest = insights.value;
    if (latest != null) {
      _lastInsights = latest;
    }
    final data = _lastInsights;

    void openJob(String jobId) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => JobDetailPage(jobId: jobId)),
    );
    void newJob() => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const JobCreationWizardPage()),
    );
    void retryPending() => ref.invalidate(cleanJobsProvider(_pendingKey));
    void retryCounts() => ref.invalidate(cleanJobCountsProvider);
    void retryInsights() => ref.invalidate(workshopDashboardProvider(_days));

    Future<void> refresh() async {
      ref.invalidate(cleanJobsProvider(_pendingKey));
      ref.invalidate(cleanJobCountsProvider);
      ref.invalidate(workshopDashboardProvider(_days));
      try {
        await ref.read(cleanJobCountsProvider.future);
      } catch (_) {
        // The header owns the error surface; pull-to-refresh still settles.
      }
    }

    final snapshot = counts.value;
    final firstPending = pending.value?.items.firstOrNull;
    final empty = snapshot?.total == 0;
    final pendingCount = snapshot?.pendingReview;
    final showDecisions =
        (pendingCount ?? 0) > 0 ||
        (pendingCount == null && (pending.hasError || pending.isLoading));

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final compact = constraints.maxWidth < 820 || textScale >= 1.3;
        final wide = constraints.maxWidth >= 900;
        final gutter = ws.pageGutter(constraints.maxWidth);

        final decisions = DashboardDecisions(
          pending: pending,
          counts: snapshot,
          statuses: statuses,
          onOpenJob: openJob,
          onOpenQueue: widget.onOpenQueue ?? () {},
          onRetry: retryPending,
        );

        return RefreshIndicator(
          color: ws.accent,
          backgroundColor: ws.surface,
          onRefresh: refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  gutter,
                  compact ? 20 : 32,
                  gutter,
                  32,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: DashboardReveal(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DashboardHeader(
                              counts: counts,
                              compact: compact,
                              onNewJob: newJob,
                              onReview: firstPending == null
                                  ? null
                                  : () => openJob(firstPending.id),
                              onRetry: retryCounts,
                            ),
                            SizedBox(height: compact ? 20 : 24),
                            if (empty)
                              DashboardEmptyState(
                                title: t(WorkshopAdminKeys.dashFloorEmpty),
                                body: t(WorkshopAdminKeys.dashFloorEmptyBody),
                                actionLabel: t(WorkshopAdminKeys.newJob),
                                onAction: newJob,
                              )
                            else if (counts.hasError)
                              const SizedBox.shrink()
                            else if (!counts.hasValue)
                              DashboardOverviewSkeleton(compact: compact)
                            else ...[
                              DashboardKpis(
                                counts: snapshot!,
                                compact: compact,
                              ),
                              const SizedBox(height: 16),
                              if (insights.hasError)
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    bottom: 16,
                                  ),
                                  child: DashboardInlineError(
                                    message: t(
                                      WorkshopAdminKeys.commonLoadFailed,
                                    ),
                                    retryLabel: t(
                                      WorkshopAdminKeys.retryAction,
                                    ),
                                    onRetry: retryInsights,
                                  ),
                                ),
                              if (data != null) ...[
                                if (wide) ...[
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 8,
                                        child: DashboardFlowCard(
                                          data: data,
                                          days: _days,
                                          refreshing: insights.isLoading,
                                          onDaysChanged: (days) =>
                                              setState(() => _days = days),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 4,
                                        child: DashboardReportsCard(
                                          reports: data.reports,
                                          onOpenQueue:
                                              widget.onOpenQueue ?? () {},
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 7,
                                        child: showDecisions
                                            ? decisions
                                            : const SizedBox.shrink(),
                                      ),
                                      if (showDecisions)
                                        const SizedBox(width: 16),
                                      Expanded(
                                        flex: showDecisions ? 5 : 12,
                                        child: DashboardComposition(
                                          counts: snapshot,
                                          statuses: statuses,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 6,
                                        child: DashboardStaffCard(
                                          staff: data.staff,
                                          onOpenStaff:
                                              widget.onOpenStaff ?? () {},
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 6,
                                        child: DashboardCustomersCard(
                                          customers: data.customers,
                                          onOpenQueue:
                                              widget.onOpenQueue ?? () {},
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 6,
                                        child: DashboardLifecycle(
                                          counts: snapshot,
                                          statuses: statuses,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 6,
                                        child: DashboardActivityCard(
                                          activity: data.activity,
                                          statuses: statuses,
                                          onOpenJob: openJob,
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  DashboardFlowCard(
                                    data: data,
                                    days: _days,
                                    refreshing: insights.isLoading,
                                    onDaysChanged: (days) =>
                                        setState(() => _days = days),
                                  ),
                                  const SizedBox(height: 16),
                                  DashboardReportsCard(
                                    reports: data.reports,
                                    onOpenQueue: widget.onOpenQueue ?? () {},
                                  ),
                                  const SizedBox(height: 16),
                                  if (showDecisions) ...[
                                    decisions,
                                    const SizedBox(height: 16),
                                  ],
                                  DashboardComposition(
                                    counts: snapshot,
                                    statuses: statuses,
                                  ),
                                  const SizedBox(height: 16),
                                  DashboardStaffCard(
                                    staff: data.staff,
                                    onOpenStaff: widget.onOpenStaff ?? () {},
                                  ),
                                  const SizedBox(height: 16),
                                  DashboardCustomersCard(
                                    customers: data.customers,
                                    onOpenQueue: widget.onOpenQueue ?? () {},
                                  ),
                                  const SizedBox(height: 16),
                                  DashboardLifecycle(
                                    counts: snapshot,
                                    statuses: statuses,
                                  ),
                                  const SizedBox(height: 16),
                                  DashboardActivityCard(
                                    activity: data.activity,
                                    statuses: statuses,
                                    onOpenJob: openJob,
                                  ),
                                ],
                              ] else if (insights.isLoading)
                                DashboardInsightSkeleton(compact: compact),
                              const SizedBox(height: 16),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One-shot settle on first paint: 280 ms fade + 8 px rise.
class DashboardReveal extends StatelessWidget {
  const DashboardReveal({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : DashboardMotion.reveal;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: DashboardMotion.enter,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
