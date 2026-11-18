import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/job_presentation.dart';
import 'package:workshop_admin_app/src/features/jobs/job_quick_sheet.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/features/jobs/schedule_job_sheet.dart';
import 'package:workshop_admin_app/src/models.dart';

/// Jobs queue: one page header, one search field, one filter row and either a
/// tabular list (wide) or stacked cards (narrow). Counts stay derived from the
/// search-scoped, unfiltered provider snapshot.
class JobsTab extends ConsumerStatefulWidget {
  const JobsTab({super.key});

  @override
  ConsumerState<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends ConsumerState<JobsTab> {
  final _search = TextEditingController();
  String _status = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _key => '${_search.text}\u0001$_status';

  /// Counts key: same search text, unfiltered status.
  String get _countsKey => '${_search.text}\u0001';

  bool get _filtersActive =>
      _status.isNotEmpty || _search.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final gutter = ws.pageGutter(MediaQuery.sizeOf(context).width);
    final jobs = ref.watch(jobsProvider(_key));
    final counts = ref.watch(jobsProvider(_countsKey)).value;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth - 2 * gutter >= jobWideRowMinWidth;
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(jobsProvider(_key)),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  gutter,
                  gutter,
                  gutter,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: WorkshopPageHeader(
                    title: l10n.queueTitle,
                    subtitle: l10n.jobsQueueSubtitle,
                    primaryAction: WorkshopButton(
                      label: l10n.newJob,
                      icon: Icons.add,
                      onPressed: () => _openCreate(context),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  gutter,
                  spacing.lg,
                  gutter,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: WorkshopToolbar(
                    search: WorkshopSearchField(
                      key: const Key('jobs-search'),
                      controller: _search,
                      hint: l10n.jobSearch,
                      semanticLabel: l10n.jobSearch,
                      onChanged: (_) => setState(() {}),
                    ),
                    filters: _filters(l10n, counts),
                  ),
                ),
              ),
              ..._contentSlivers(context, l10n, jobs, counts, wide),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _filters(AppLocalizations l10n, List<WorkshopJob>? counts) {
    Widget chip(String value, String label) => WorkshopFilterChip(
      label: label,
      count: _countFor(counts, value),
      selected: _status == value,
      onTap: () => setState(() => _status = value),
    );
    return [
      chip('', l10n.filterAll),
      chip('IN_PROGRESS', l10n.statusInProgress),
      chip('READY_TO_FINALIZE', l10n.statusReadyToFinalize),
      chip('FINALIZED', l10n.statusFinalized),
    ];
  }

  int? _countFor(List<WorkshopJob>? all, String status) {
    if (all == null) {
      return null;
    }
    if (status.isEmpty) {
      return all.length;
    }
    return all.where((job) => job.status == status).length;
  }

  List<Widget> _contentSlivers(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<List<WorkshopJob>> jobs,
    List<WorkshopJob>? counts,
    bool wide,
  ) {
    final ws = context.ws;
    final spacing = context.spacing;
    final gutter = ws.pageGutter(MediaQuery.sizeOf(context).width);
    final padding = EdgeInsetsDirectional.fromSTEB(
      gutter,
      spacing.lg,
      gutter,
      spacing.lg,
    );
    if (jobs.isLoading) {
      return [
        SliverPadding(
          padding: padding,
          sliver: const SliverToBoxAdapter(
            child: WorkshopSkeleton(card: true, lines: 6),
          ),
        ),
      ];
    }
    if (jobs.hasError) {
      return [
        SliverPadding(
          padding: padding,
          sliver: SliverToBoxAdapter(
            child: WorkshopErrorState(
              title: l10n.error,
              body: l10n.commonLoadFailed,
              retryLabel: l10n.retryAction,
              onRetry: () => ref.invalidate(jobsProvider(_key)),
            ),
          ),
        ),
      ];
    }
    final items = jobs.value ?? const <WorkshopJob>[];
    if (items.isEmpty) {
      final hasJobs = counts != null && counts.isNotEmpty;
      return [
        SliverPadding(
          padding: padding,
          sliver: SliverToBoxAdapter(
            child: WorkshopCard(
              child: WorkshopEmptyState(
                title: _filtersActive || hasJobs
                    ? l10n.jobsEmptyQueueTitle
                    : l10n.jobsEmpty,
                body: _filtersActive || hasJobs
                    ? l10n.jobsEmptyQueueBody
                    : null,
                icon: Icons.work_outline,
                action: _filtersActive || hasJobs
                    ? null
                    : WorkshopButton(
                        label: l10n.newJob,
                        icon: Icons.add,
                        onPressed: () => _openCreate(context),
                      ),
              ),
            ),
          ),
        ),
      ];
    }
    if (wide) {
      return [
        SliverPadding(
          padding: padding,
          sliver: SliverToBoxAdapter(
            child: WorkshopCard(
              padding: EdgeInsetsDirectional.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const JobListHeader(),
                  const WorkshopDivider(),
                  for (var index = 0; index < items.length; index++) ...[
                    if (index > 0) const WorkshopDivider(),
                    JobListRow(
                      key: Key('job-${items[index].id}'),
                      job: items[index],
                      onTap: () => _openJob(items[index]),
                    ),
                  ],
                  const WorkshopDivider(),
                  Padding(
                    key: const Key('jobs-queue-total'),
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: ws.cardPadding,
                      vertical: spacing.md,
                    ),
                    child: Text(
                      '${l10n.queueTotal}: '
                      '${formatNumber(context, items.length)}',
                      style: ws.meta.copyWith(color: ws.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: padding,
        sliver: SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (_, _) => SizedBox(height: spacing.md),
          itemBuilder: (context, index) {
            final job = items[index];
            return JobListRow(
              key: Key('job-${job.id}'),
              job: job,
              onTap: () => _openJob(job),
            );
          },
        ),
      ),
    ];
  }

  Future<void> _openJob(WorkshopJob job) async {
    await showJobQuickSheet(context, job);
    if (mounted) {
      ref.invalidate(jobsProvider(_key));
      ref.invalidate(jobCountsProvider);
    }
  }

  Future<void> _openCreate(BuildContext context) async {
    final created = await ScheduleJobSheet.showScheduleJobSheet(context);
    if (created != null) {
      ref.invalidate(jobsProvider(_key));
      ref.invalidate(jobCountsProvider);
    }
  }
}
