import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/home/workshop_admin_home.dart';
import 'package:workshop_admin_app/src/features/jobs/job_creation_wizard_page.dart';
import 'package:workshop_admin_app/src/features/jobs/job_presentation.dart';
import 'package:workshop_admin_app/src/features/jobs/job_quick_sheet.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/job_counts.dart';
import 'package:workshop_admin_app/src/models.dart';

String formatNumber(BuildContext context, int value) =>
    NumberFormat.decimalPattern(Localizations.localeOf(context).toString())
        .format(value);

/// Overview tab: React SaaS-grade dashboard.
///
/// Layout structure:
/// - Row 1: Greeting "Good afternoon, Layla" (30/700) + humanized date & single
///   primary action [+ New job]. Zero duplicated workshop name.
/// - Row 2: Stat strip — ONE single surface with 5 equal cells, hairline
///   dividers, 40 px tabular numbers, uppercase eyebrow labels, small meta.
/// - Row 3: 8-col "Next up" hero card + 4-col "Pipeline" progress breakdown.
/// - Row 4: "Recent jobs" — ONE clean table surface with hover rows and quiet
///   "View all jobs" link.
/// - Row 5: Quick actions — quiet navigation tiles.
class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final gutter = ws.pageGutter(MediaQuery.sizeOf(context).width);
    final session = ref.watch(authControllerProvider).value;
    final displayName = session?.user.displayName.trim() ?? '';
    final firstName = displayName.isEmpty
        ? ''
        : displayName.split(RegExp(r'\s+')).first;

    final greeting = firstName.isEmpty
        ? l10n.dashboardGreeting
        : '${l10n.dashboardGreeting}, $firstName';
    final pageTitle = session == null ? l10n.dashboardTab : greeting;

    final now = DateTime.now();
    final localeName = Localizations.localeOf(context).toString();
    final todayFormatted = DateFormat.yMMMMEEEEd(localeName).format(now);
    final pageSubtitle = 'Today, $todayFormatted';

    final counts = ref.watch(jobCountsProvider);
    final jobs = ref.watch(jobsProvider(''));

    void openJob(WorkshopJob job) => showJobQuickSheet(context, job);
    void newJob() => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const JobCreationWizardPage()),
    );
    void goTo(int index) =>
        WorkshopNavigationScope.maybeOf(context)?.select(index);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(jobCountsProvider);
        ref.invalidate(jobsProvider(''));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Row 1: Greeting & single primary action
          SliverPadding(
            padding: EdgeInsetsDirectional.fromSTEB(gutter, gutter, gutter, 0),
            sliver: SliverToBoxAdapter(
              child: _PageColumn(
                child: WorkshopPageHeader(
                  title: pageTitle,
                  subtitle: pageSubtitle,
                  primaryAction: WorkshopButton(
                    label: l10n.newJob,
                    icon: Icons.add,
                    onPressed: newJob,
                  ),
                ),
              ),
            ),
          ),

          // Row 2: Stat strip (ONE single surface, 5 equal cells, 40 px numbers)
          SliverPadding(
            padding: EdgeInsetsDirectional.fromSTEB(
              gutter,
              spacing.xl,
              gutter,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _PageColumn(
                child: counts.when(
                  loading: () => const WorkshopSkeleton(card: true, lines: 2),
                  error: (error, _) => WorkshopErrorState(
                    title: l10n.error,
                    body: l10n.commonLoadFailed,
                    retryLabel: l10n.retryAction,
                    onRetry: () => ref.invalidate(jobCountsProvider),
                  ),
                  data: (value) => _MetricStrip(
                    counts: value,
                    onSelectFilter: () => goTo(1),
                  ),
                ),
              ),
            ),
          ),

          // Row 3, 4, 5: Hero + Pipeline, Recent Jobs Table, Quick Actions
          SliverPadding(
            padding: EdgeInsetsDirectional.fromSTEB(
              gutter,
              spacing.xl,
              gutter,
              spacing.xxl,
            ),
            sliver: SliverToBoxAdapter(
              child: _PageColumn(
                child: _DashboardBody(
                  jobs: jobs,
                  counts: counts,
                  onOpenJob: openJob,
                  onNewJob: newJob,
                  onOpenQueue: () => goTo(1),
                  onRetryJobs: () => ref.invalidate(jobsProvider('')),
                  onGoTo: goTo,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Centers content at the workshop max column width (1200 px).
class _PageColumn extends StatelessWidget {
  const _PageColumn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.ws.contentMaxWidth),
        child: child,
      ),
    );
  }
}

/// Row 2: One single bordered surface with the 5 real counts (40 px tabular numbers).
class _MetricStrip extends StatelessWidget {
  const _MetricStrip({
    required this.counts,
    required this.onSelectFilter,
  });

  final JobCounts counts;
  final VoidCallback onSelectFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return WorkshopMetricStrip(
      items: [
        WorkshopMetric(
          key: const Key('dashboard-stat-active'),
          value: formatNumber(context, counts.active),
          label: l10n.dashboardStatActive,
          onTap: onSelectFilter,
        ),
        WorkshopMetric(
          key: const Key('dashboard-stat-new-scheduled'),
          value: formatNumber(context, counts.newScheduled),
          label: l10n.dashboardStatNewScheduled,
          onTap: onSelectFilter,
        ),
        WorkshopMetric(
          key: const Key('dashboard-stat-in-progress'),
          value: formatNumber(context, counts.inProgress),
          label: l10n.statusInProgress,
          onTap: onSelectFilter,
        ),
        WorkshopMetric(
          key: const Key('dashboard-stat-ready'),
          value: formatNumber(context, counts.readyToFinalize),
          label: l10n.statusReadyToFinalize,
          onTap: onSelectFilter,
        ),
        WorkshopMetric(
          key: const Key('dashboard-stat-finalized-today'),
          value: formatNumber(context, counts.finalizedToday),
          label: l10n.dashboardStatFinalizedToday,
          onTap: onSelectFilter,
        ),
      ],
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.jobs,
    required this.counts,
    required this.onOpenJob,
    required this.onNewJob,
    required this.onOpenQueue,
    required this.onRetryJobs,
    required this.onGoTo,
  });

  final AsyncValue<List<WorkshopJob>> jobs;
  final AsyncValue<JobCounts> counts;
  final ValueChanged<WorkshopJob> onOpenJob;
  final VoidCallback onNewJob;
  final VoidCallback onOpenQueue;
  final VoidCallback onRetryJobs;
  final ValueChanged<int> onGoTo;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _leftColumn(context),
              SizedBox(height: spacing.xxl),
              _rightColumn(context),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _leftColumn(context)),
            SizedBox(width: spacing.xxl),
            Expanded(child: _rightColumn(context)),
          ],
        );
      },
    );
  }

  Widget _leftColumn(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    if (jobs.isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const WorkshopSkeleton(card: true, lines: 4),
          SizedBox(height: spacing.xxl),
          const WorkshopSkeleton(card: true, lines: 4),
        ],
      );
    }
    if (jobs.hasError) {
      return WorkshopErrorState(
        title: l10n.error,
        body: l10n.commonLoadFailed,
        retryLabel: l10n.retryAction,
        onRetry: onRetryJobs,
      );
    }
    final items = jobs.value ?? const <WorkshopJob>[];
    if (items.isEmpty) {
      return WorkshopCard(
        child: WorkshopEmptyState(
          title: l10n.jobsEmpty,
          icon: Icons.work_outline,
          action: WorkshopButton(
            label: l10n.newJob,
            icon: Icons.add,
            onPressed: onNewJob,
          ),
        ),
      );
    }
    final upcoming = _nearestUpcoming(items);
    final recent = items
        .where((job) => job.id != upcoming?.id)
        .take(4)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _UpcomingCard(job: upcoming, onOpen: onOpenJob, onNewJob: onNewJob),
        SizedBox(height: spacing.xxl),
        _RecentJobsCard(
          jobs: recent,
          onOpen: onOpenJob,
          onViewAll: onOpenQueue,
        ),
      ],
    );
  }

  Widget _rightColumn(BuildContext context) {
    return _PipelineAndActions(
      counts: counts,
      onOpenQueue: onOpenQueue,
      onGoTo: onGoTo,
    );
  }
}

/// Soonest scheduled open job (closed/finalized jobs are never "next up").
WorkshopJob? _nearestUpcoming(List<WorkshopJob> jobs) {
  const closed = <String>{'FINALIZED', 'PUBLISHED', 'CANCELLED', 'REJECTED'};
  WorkshopJob? best;
  DateTime? bestAt;
  for (final job in jobs) {
    if (closed.contains(job.status)) {
      continue;
    }
    final at = dubaiWallTime(job.scheduledAt);
    if (at == null) {
      continue;
    }
    if (bestAt == null || at.isBefore(bestAt)) {
      best = job;
      bestAt = at;
    }
  }
  return best;
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({
    required this.job,
    required this.onOpen,
    required this.onNewJob,
  });

  final WorkshopJob? job;
  final ValueChanged<WorkshopJob> onOpen;
  final VoidCallback onNewJob;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final value = job;

    if (value == null) {
      return WorkshopCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            WorkshopSectionHeader(title: l10n.dashboardNextUp),
            SizedBox(height: spacing.md),
            WorkshopEmptyState(
              title: l10n.dashboardNoUpcoming,
              body: l10n.dashboardNoUpcomingBody,
              icon: Icons.event_available_outlined,
            ),
          ],
        ),
      );
    }

    return WorkshopCard(
      padding: EdgeInsetsDirectional.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              ws.cardPadding,
              ws.cardPadding,
              ws.cardPadding,
              spacing.sm,
            ),
            child: WorkshopSectionHeader(title: l10n.dashboardNextUp),
          ),
          const WorkshopDivider(),
          JobListRow(
            key: Key('dashboard-job-${value.id}'),
            job: value,
            embedded: true,
            onTap: () => onOpen(value),
          ),
        ],
      ),
    );
  }
}

class _RecentJobsCard extends StatelessWidget {
  const _RecentJobsCard({
    required this.jobs,
    required this.onOpen,
    required this.onViewAll,
  });

  final List<WorkshopJob> jobs;
  final ValueChanged<WorkshopJob> onOpen;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    return WorkshopCard(
      padding: EdgeInsetsDirectional.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              ws.cardPadding,
              ws.cardPadding,
              ws.cardPadding,
              spacing.sm,
            ),
            child: WorkshopSectionHeader(
              title: l10n.dashboardRecentJobs,
              action: WorkshopButton(
                label: l10n.dashboardViewAll,
                variant: WorkshopButtonVariant.ghost,
                onPressed: onViewAll,
              ),
            ),
          ),
          if (jobs.isEmpty)
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                ws.cardPadding,
                0,
                ws.cardPadding,
                ws.cardPadding,
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: ws.muted),
                  SizedBox(width: spacing.sm),
                  Expanded(
                    child: Text(
                      l10n.dashboardNoRecentJobs,
                      style: ws.meta.copyWith(color: ws.muted),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            for (var index = 0; index < jobs.length; index++) ...[
              if (index > 0) const WorkshopDivider(),
              JobListRow(
                key: Key('dashboard-job-${jobs[index].id}'),
                job: jobs[index],
                embedded: true,
                onTap: () => onOpen(jobs[index]),
              ),
            ],
            SizedBox(height: spacing.sm),
          ],
        ],
      ),
    );
  }
}

class _PipelineAndActions extends StatelessWidget {
  const _PipelineAndActions({
    required this.counts,
    required this.onOpenQueue,
    required this.onGoTo,
  });

  final AsyncValue<JobCounts> counts;
  final VoidCallback onOpenQueue;
  final ValueChanged<int> onGoTo;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _PipelineCard(counts: counts, onTap: onOpenQueue),
        SizedBox(height: spacing.xxl),
        _QuickActionsCard(onGoTo: onGoTo),
      ],
    );
  }
}

/// Stacked count bar plus legend; proportions are the real counts only.
class _PipelineCard extends StatelessWidget {
  const _PipelineCard({required this.counts, required this.onTap});

  final AsyncValue<JobCounts> counts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    return WorkshopCard(
      onTap: onTap,
      semanticLabel: '${l10n.dashboardPipeline}, ${l10n.jobsTab}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          WorkshopSectionHeader(title: l10n.dashboardPipeline),
          SizedBox(height: spacing.lg),
          counts.when(
            loading: () => const WorkshopSkeleton(lines: 2),
            error: (error, _) =>
                WorkshopInlineNote(text: l10n.commonLoadFailed),
            data: (value) => _PipelineBody(counts: value),
          ),
        ],
      ),
    );
  }
}

class _PipelineBody extends StatelessWidget {
  const _PipelineBody({required this.counts});

  final JobCounts counts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final segments = <({int value, Color color, String label})>[
      (
        value: counts.newScheduled,
        color: ws.muted.withValues(alpha: 0.35),
        label: l10n.dashboardStatNewScheduled,
      ),
      (
        value: counts.inProgress,
        color: ws.accent,
        label: l10n.statusInProgress,
      ),
      (
        value: counts.readyToFinalize,
        color: ws.warning,
        label: l10n.statusReadyToFinalize,
      ),
      (
        value: counts.finalizedToday,
        color: ws.success,
        label: l10n.dashboardStatFinalizedToday,
      ),
    ];
    final total = segments.fold<int>(0, (sum, item) => sum + item.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(ws.chipRadius),
          child: SizedBox(
            key: const Key('dashboard-pipeline-bar'),
            height: 8,
            child: total == 0
                ? ColoredBox(color: ws.canvas)
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final segment in segments)
                        if (segment.value > 0)
                          Expanded(
                            flex: segment.value,
                            child: ColoredBox(color: segment.color),
                          ),
                    ],
                  ),
          ),
        ),
        SizedBox(height: spacing.lg),
        Wrap(
          spacing: spacing.lg,
          runSpacing: spacing.sm,
          children: [
            for (final segment in segments)
              _PipelineLegend(
                color: segment.color,
                label: segment.label,
                value: formatNumber(context, segment.value),
              ),
          ],
        ),
      ],
    );
  }
}

class _PipelineLegend extends StatelessWidget {
  const _PipelineLegend({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Semantics(
      label: '$label, $value',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: spacing.sm,
            height: spacing.sm,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: spacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              style: ws.meta.copyWith(color: ws.muted),
            ),
          ),
          SizedBox(width: spacing.sm),
          Text(
            value,
            style: ws.meta.copyWith(color: ws.ink, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({required this.onGoTo});

  final ValueChanged<int> onGoTo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    return WorkshopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          WorkshopSectionHeader(title: l10n.dashQuickActions),
          SizedBox(height: spacing.sm),
          _QuietAction(
            icon: Icons.groups_outlined,
            label: l10n.staffTab,
            onTap: () => onGoTo(2),
          ),
          const WorkshopDivider(),
          _QuietAction(
            icon: Icons.dashboard_customize_outlined,
            label: l10n.templatesTab,
            onTap: () => onGoTo(3),
          ),
          const WorkshopDivider(),
          _QuietAction(
            icon: Icons.assignment_outlined,
            label: l10n.jobsBoardTab,
            onTap: () => onGoTo(4),
          ),
          const WorkshopDivider(),
          _QuietAction(
            icon: Icons.settings_outlined,
            label: l10n.settings,
            onTap: () => onGoTo(5),
          ),
        ],
      ),
    );
  }
}

/// Quiet 44 px navigation row with a visible hover/focus state.
class _QuietAction extends StatelessWidget {
  const _QuietAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          canRequestFocus: true,
          hoverColor: ws.canvas,
          focusColor: ws.accentSoft,
          borderRadius: BorderRadius.circular(ws.chipRadius),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: ws.touchTarget),
            child: Row(
              children: [
                Icon(icon, size: 18, color: ws.muted),
                SizedBox(width: spacing.md),
                Expanded(
                  child: Text(label, style: ws.body.copyWith(color: ws.ink)),
                ),
                Icon(
                  rtl ? Icons.chevron_left : Icons.chevron_right,
                  size: 18,
                  color: ws.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
